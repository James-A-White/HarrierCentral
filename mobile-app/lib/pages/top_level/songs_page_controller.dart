import 'package:harrier_central/imports.dart';

class SongsPageController extends GetxController
    with GetSingleTickerProviderStateMixin {
  SongsPageController({this.eventId});

  /// When non-null, the songbook is in interactive mode for this event.
  final String? eventId;

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  final ScrollController listScrollController = ScrollController();
  final ScrollController lyricsScrollController = ScrollController();

  final RxList<SongsModel> allSongs = <SongsModel>[].obs;
  final RxList<SongsModel> filteredSongs = <SongsModel>[].obs;
  final Rxn<SongsModel> selectedSong = Rxn<SongsModel>();
  final RxBool isLoading = true.obs;
  final RxBool isLyricsExpanded = false.obs;

  // Interactive mode state
  final RxBool isListeningMode = false.obs;
  final Rxn<String> listeningFromName = Rxn<String>();
  final RxBool isRsvpdToEvent = false.obs;

  // Bawdy rating filter toggles (all on by default)
  final RxSet<int> activeBawdyFilters = <int>{0, 1, 2, 3}.obs;

  // Ephemeral "sung today" tracking — resets when app closes
  final RxSet<String> sungSongIds = <String>{}.obs;

  void toggleSung(String songId) {
    if (sungSongIds.contains(songId)) {
      sungSongIds.remove(songId);
    } else {
      sungSongIds.add(songId);
    }
  }

  // Animation for lyrics panel expansion
  late AnimationController animController;
  late Animation<double> lyricsExpansion;

  // Audio player for song audio
  AudioPlayer? audioPlayer;

  bool _isDisposed = false;

  // Worker for the SongSessionNotifier ever() subscription. Stored so it is
  // properly disposed when the controller closes, preventing leaked listeners.
  Worker? _songWorker;

  /// Fraction of screen height occupied by the lyrics panel when collapsed.
  static const double collapsedLyricsFraction = 0.33;

  static const Map<int, String> bawdyIcons = <int, String>{
    0: '😇',
    1: '🍺🍺',
    2: '🌶️🌶️🌶️',
    3: '🔥🔥🔥🔥',
  };

  @override
  void onInit() {
    super.onInit();
    animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    lyricsExpansion = CurvedAnimation(
      parent: animController,
      curve: Curves.easeInOut,
    );

    unawaited(loadSongs());

    if (eventId != null) {
      // Register the ever() worker synchronously so no push is missed while
      // _initInteractiveMode is awaiting async operations.
      _songWorker = ever(
        SongSessionNotifier.ensure().pendingSongId,
        (_) => _onIncomingSong(),
      );
      unawaited(_initInteractiveMode());
    }
  }

  Future<void> _initInteractiveMode() async {
    await _checkRsvpStatus();

    // Check if there is already an active song (pull-on-open)
    final CurrentSongResult? current =
        await SongSessionService.getCurrentSong(eventId: eventId!);
    if (current != null && !_isDisposed) {
      // Songs may still be loading — wait for them if needed
      if (allSongs.isEmpty) {
        await Future.doWhile(() async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return allSongs.isEmpty && !_isDisposed;
        }).timeout(const Duration(seconds: 5), onTimeout: () {});
      }
      _applySong(current.songId, current.selectedByName);
    }
  }

  Future<void> _checkRsvpStatus() async {
    try {
      final String userId = normalizeUuid(currentUserId);
      final String eid = normalizeUuid(eventId!);
      final List<Map<String, dynamic>> rows = await database.rawQuery('''
        SELECT ${tableModel.hasherEventMapTableHelper.colRsvpState}
        FROM ${EnumDataTables.hasherEventMap.commonTableName}
        WHERE lower(${tableModel.hasherEventMapTableHelper.colEventId}) = "$eid"
          AND lower(${tableModel.hasherEventMapTableHelper.colUserId}) = "$userId"
          AND ${tableModel.hasherEventMapTableHelper.colRsvpState} >= 2
        LIMIT 1
      ''');
      isRsvpdToEvent.value = rows.isNotEmpty;
    } catch (_) {}
  }

  void _onIncomingSong() {
    if (_isDisposed) return;
    final SongSessionNotifier notifier = SongSessionNotifier.ensure();
    final String? incomingEventId = notifier.pendingEventId.value;
    final String? incomingSongId = notifier.pendingSongId.value;
    final String fromName = notifier.pendingSelectedByName.value ?? 'Someone';

    if (incomingEventId == null || incomingSongId == null) return;
    if (normalizeUuid(incomingEventId) != normalizeUuid(eventId!)) return;

    _applySong(incomingSongId, fromName);
  }

  void _applySong(String songId, String fromName) {
    if (_isDisposed) return;
    final String normalizedId = normalizeUuid(songId);
    final SongsModel? song = allSongs.firstWhereOrNull(
      (SongsModel s) => normalizeUuid(s.songId) == normalizedId,
    );
    if (song == null) return;

    selectSong(song);
    isListeningMode.value = true;
    listeningFromName.value = fromName;

    if (!isLyricsExpanded.value) {
      isLyricsExpanded.value = true;
      unawaited(animController.forward());
    }
    if (lyricsScrollController.hasClients) {
      lyricsScrollController.jumpTo(0);
    }
  }

  void exitListeningMode() {
    isListeningMode.value = false;
    listeningFromName.value = null;
  }

  Future<void> shareNow(BuildContext context) async {
    final SongsModel? song = selectedSong.value;
    if (song == null || eventId == null) return;

    final SelectSongResult? result = await SongSessionService.selectSong(
      eventId: eventId!,
      songId: song.songId,
    );

    if (result != null && context.mounted) {
      final int? count = result.recipientCount;
      final String withWhom = (count != null && count > 0)
          ? 'with $count pack ${count == 1 ? 'member' : 'members'}'
          : 'with the pack';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            'Shared "${song.songName}" $withWhom 🎵',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void onClose() {
    _isDisposed = true;
    _songWorker?.dispose();
    searchController.dispose();
    searchFocusNode.dispose();
    listScrollController.dispose();
    lyricsScrollController.dispose();
    animController.dispose();
    unawaited(audioPlayer?.dispose());
    audioPlayer = null;
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  Future<void> loadSongs() async {
    if (_isDisposed) return;
    try {
      final String tableName = EnumDataTables.songs.commonTableName;
      final List<Map<String, dynamic>> results = await database.rawQuery(
        'SELECT * FROM $tableName WHERE removed = 0 ORDER BY songName ASC',
      );

      allSongs.value = results
          .map(
            (Map<String, dynamic> m) => tableModel.songsTableHelper.fromMap(m),
          )
          .toList()
          .cast<SongsModel>();

      filterResults();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SongsPageController.loadSongs error: $e');
      }
    }

    isLoading.value = false;
  }

  void filterResults() {
    final String query = searchController.text.trim().toLowerCase();

    filteredSongs.value = allSongs.where((SongsModel s) {
      // Bawdy rating filter
      if (!activeBawdyFilters.contains(s.bawdyRating.clamp(0, 3))) {
        return false;
      }
      // Text search
      if (query.isEmpty) return true;
      return s.songName.toLowerCase().contains(query) ||
          (s.tuneOf?.toLowerCase().contains(query) ?? false) ||
          (s.tags?.toLowerCase().contains(query) ?? false) ||
          s.lyrics.toLowerCase().contains(query);
    }).toList();
  }

  void selectSong(SongsModel song) {
    if (_isDisposed) return;
    // Tapping a song to view it also drops the search keyboard.
    searchFocusNode.unfocus();
    unawaited(audioPlayer?.stop());
    unawaited(audioPlayer?.dispose());
    audioPlayer = null;

    selectedSong.value = song;
    // Collapse if expanded when switching songs
    if (isLyricsExpanded.value) {
      isLyricsExpanded.value = false;
      unawaited(animController.reverse());
    }
    // Reset lyrics scroll position
    if (lyricsScrollController.hasClients) {
      lyricsScrollController.jumpTo(0);
    }
  }

  void toggleLyricsExpanded() {
    if (_isDisposed) return;
    isLyricsExpanded.value = !isLyricsExpanded.value;
    if (isLyricsExpanded.value) {
      unawaited(animController.forward());
      // Initialize audio player if song has audio
      final SongsModel? song = selectedSong.value;
      if (song?.audioUrl != null && song!.audioUrl!.isNotEmpty) {
        unawaited(audioPlayer?.dispose());
        audioPlayer = AudioPlayer();
        unawaited(audioPlayer!.setUrl(song.audioUrl!).catchError((_) => null));
      }
    } else {
      unawaited(audioPlayer?.stop());
      unawaited(audioPlayer?.dispose());
      audioPlayer = null;
      unawaited(animController.reverse());
    }
  }

  void toggleBawdyFilter(int rating) {
    if (activeBawdyFilters.contains(rating)) {
      activeBawdyFilters.remove(rating);
    } else {
      activeBawdyFilters.add(rating);
    }
    filterResults();
  }

  void clearSearch() {
    searchController.text = '';
    filterResults();
  }

  void onSearchChanged(String text) {
    filterResults();
  }

  String formatDuration(Duration d) {
    final int minutes = d.inMinutes;
    final int seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
