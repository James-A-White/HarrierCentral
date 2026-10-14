import 'package:harrier_central/imports.dart';

/// State for the run admin's Down Downs page: the charge list, its 15-second
/// poll, and the mark/cancel/undo actions.
///
/// Migrated from a State on 2026-09-23. The poll [Timer] used to live in a
/// State's dispose; it is cancelled in [onClose] now, and every `await` is
/// followed by an `isClosed` check. Confirmation dialogs stay in the page —
/// they need a BuildContext, and asking is UI; doing is here.
class DownDownsController extends GetxController {
  DownDownsController({required this.kennelId, required this.eventId});

  final String kennelId;
  final String eventId;

  static String tagFor(String eventId) => 'downdowns-$eventId';

  final RunContentService _service = RunContentService();

  final RxBool isLoading = true.obs;

  /// The charge whose song is being shared, from the press until the server
  /// answers: its share icon spins and a second press does nothing.
  final RxnString sharingDownDownId = RxnString();

  /// Charges with a done / cancel change on its way to the server. The row
  /// changes at once (optimistically, put back if the server refuses) and a
  /// second tap on it is ignored until the first returns.
  final RxSet<String> busyDownDownIds = <String>{}.obs;

  /// Runs [write] for [dd] once at a time, showing [optimistic] at once and
  /// putting [dd] back when the write fails.
  Future<void> _rowWrite(
    DownDownModel dd,
    DownDownModel optimistic,
    Future<bool> Function() write,
  ) async {
    final String id = dd.downDownId;
    if (busyDownDownIds.contains(id)) return;
    busyDownDownIds.add(id);
    _replace(optimistic);
    bool ok = false;
    try {
      ok = await write();
    } finally {
      if (!isClosed) {
        busyDownDownIds.remove(id);
        if (!ok) _replace(dd);
      }
    }
  }
  final RxList<DownDownModel> downDowns = <DownDownModel>[].obs;
  Timer? _pollTimer;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      // Don't hit the network while the app is backgrounded/inactive. The timer
      // keeps ticking cheaply and resumes polling within 15s once foregrounded.
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return;
      }
      unawaited(silentRefresh());
    });
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    super.onClose();
  }

  /// Display order: pending first, then cancelled, then done; oldest first
  /// within each. Pure, so it is unit-tested.
  static List<DownDownModel> ordered(List<DownDownModel> items) {
    int rank(DownDownModel d) => d.isDone ? 2 : (d.isCancelled ? 1 : 0);
    final List<DownDownModel> out = List<DownDownModel>.of(items);
    out.sort((a, b) {
      final int ra = rank(a);
      final int rb = rank(b);
      if (ra != rb) return ra.compareTo(rb);
      return a.createdAt.compareTo(b.createdAt);
    });
    return out;
  }

  /// The SP returns charges and charged hashers as two rowsets; join them.
  static List<DownDownModel> withHashers(
    ({List<DownDownModel> downDowns, List<DownDownHasherModel> hashers}) result,
  ) {
    for (final dd in result.downDowns) {
      dd.hashers = result.hashers
          .where((h) => h.downDownId == dd.downDownId)
          .toList();
    }
    return result.downDowns;
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final result = await _service.getDownDowns(
        kennelId: kennelId,
        eventId: eventId,
      );
      if (isClosed) return;
      if (result != null) downDowns.assignAll(ordered(withHashers(result)));
    } catch (e, s) {
      BootLogger.logError('[DownDowns.load] eventId=$eventId', e, s);
      if (isClosed) return;
      hcSnack('Failed to load Down Downs', error: true);
    }
    if (isClosed) return;
    isLoading.value = false;
  }

  Future<void> silentRefresh() async {
    try {
      final result = await _service.getDownDowns(
        kennelId: kennelId,
        eventId: eventId,
      );
      if (isClosed) return;
      if (result != null) downDowns.assignAll(ordered(withHashers(result)));
    } catch (_) {
      // Silently ignore — next poll will retry.
    }
  }

  DownDownModel _copyWith(
    DownDownModel dd, {
    bool? isDone,
    bool? isCancelled,
  }) => DownDownModel(
    downDownId: dd.downDownId,
    chargeText: dd.chargeText,
    isDone: isDone ?? dd.isDone,
    isCancelled: isCancelled ?? dd.isCancelled,
    createdByDisplayName: dd.createdByDisplayName,
    createdByPhoto: dd.createdByPhoto,
    createdAt: dd.createdAt,
    songChoice: dd.songChoice,
    songId: dd.songId,
    chargePhotoUrl: dd.chargePhotoUrl,
    hashers: dd.hashers,
    externalNames: dd.externalNames,
  );

  void _replace(DownDownModel updated) {
    final List<DownDownModel> next = List<DownDownModel>.of(downDowns);
    final int i = next.indexWhere((d) => d.downDownId == updated.downDownId);
    if (i >= 0) next[i] = updated;
    downDowns.assignAll(ordered(next));
  }

  Future<void> markDone(DownDownModel dd) => _rowWrite(
    dd,
    _copyWith(dd, isDone: true, isCancelled: false),
    () => _service.markDownDownDone(
      kennelId: kennelId,
      eventId: eventId,
      downDownId: dd.downDownId,
    ),
  );

  Future<void> unmarkDone(DownDownModel dd) => _rowWrite(
    dd,
    _copyWith(dd, isDone: false),
    () => _service.unmarkDownDownDone(
      kennelId: kennelId,
      eventId: eventId,
      downDownId: dd.downDownId,
    ),
  );

  Future<void> cancel(DownDownModel dd) => _rowWrite(
    dd,
    _copyWith(dd, isCancelled: true, isDone: false),
    () => _service.cancelDownDown(
      kennelId: kennelId,
      eventId: eventId,
      downDownId: dd.downDownId,
    ),
  );

  Future<void> uncancel(DownDownModel dd) => _rowWrite(
    dd,
    _copyWith(dd, isCancelled: false),
    () => _service.uncancelDownDown(
      kennelId: kennelId,
      eventId: eventId,
      downDownId: dd.downDownId,
    ),
  );

  Future<void> shareSong(DownDownModel dd) async {
    if (dd.songId == null) return;
    if (sharingDownDownId.value != null) return;
    sharingDownDownId.value = dd.downDownId;
    final SelectSongResult? result;
    try {
      result = await SongSessionService.selectSong(
        eventId: eventId,
        songId: dd.songId!,
      );
    } finally {
      if (!isClosed) sharingDownDownId.value = null;
    }
    if (isClosed) return;
    if (result != null) {
      final count = result.recipientCount;
      final withWhom = (count != null && count > 0)
          ? 'with $count pack ${count == 1 ? 'member' : 'members'}'
          : 'with the pack';
      final title = result.songTitle.isNotEmpty
          ? result.songTitle
          : (dd.songChoice ?? 'song');
      hcSnack('Shared "$title" $withWhom 🎵');
    } else {
      hcSnack('Failed to share song', error: true);
    }
  }
}
