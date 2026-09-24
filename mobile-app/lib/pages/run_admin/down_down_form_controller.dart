import 'package:harrier_central/imports.dart';

class SongResult {
  SongResult({required this.songId, required this.songName});
  final String songId;
  final String songName;
}

/// An attendee in the Add Down Down picker.
class AttendeeItem {
  AttendeeItem({required this.hasherId, required this.displayName});
  final String hasherId;
  final String displayName;
  bool selected = false;
}

/// What the Add and Edit Down Down forms share: the charge and song fields,
/// the song search-as-you-type (kennel's songs first, then everyone's), the
/// linked song, and the optional charge photo.
///
/// Until 2026-09-23 each page carried its own copy of the song search in a
/// State; the results are an RxList assigned in one step now, and a search
/// that lands after the page closed is dropped.
abstract class DownDownFormController extends GetxController {
  DownDownFormController({
    required this.kennelId,
    required this.eventId,
    required this.kennelSlug,
    required this.eventNumber,
  });

  final String kennelId;
  final String eventId;
  final String kennelSlug;
  final int eventNumber;

  final RunContentService service = RunContentService();
  late final TextEditingController chargeController;
  late final TextEditingController songController;

  final Rxn<String> linkedSongId = Rxn<String>();
  final RxList<SongResult> songResults = <SongResult>[].obs;
  final RxBool isSaving = false.obs;
  final RxBool isCapturingPhoto = false.obs;
  final Rxn<String> chargePhotoUrl = Rxn<String>();
  bool _suppressNextSongSearch = false;

  /// How many matches the song list shows.
  int get songLimit;

  @override
  void onClose() {
    chargeController.dispose();
    songController.dispose();
    super.onClose();
  }

  /// The song field's onChanged: typing unlinks any picked song and searches.
  void onSongChanged(String value) {
    if (_suppressNextSongSearch) {
      _suppressNextSongSearch = false;
      return;
    }
    linkedSongId.value = null;
    unawaited(searchSongs(value));
  }

  /// A tap on a result: the field takes the name without re-searching.
  void pickSong(SongResult song) {
    _suppressNextSongSearch = true;
    songController.text = song.songName;
    linkedSongId.value = song.songId;
    songResults.clear();
  }

  void unlinkSong({bool clearResults = false}) {
    linkedSongId.value = null;
    if (clearResults) songResults.clear();
  }

  Future<void> searchSongs(String query) async {
    if (query.trim().isEmpty) {
      songResults.clear();
      return;
    }
    final tbl = tableModel.songsTableHelper;
    final songTable = EnumDataTables.songs.commonTableName;
    final pattern = '%${query.trim()}%';

    List<SongResult> parse(List<Map<String, Object?>> rows) => rows
        .map(
          (r) => SongResult(
            songId: r[tbl.colSongId] as String,
            songName: r[tbl.colSongName] as String,
          ),
        )
        .toList();

    final kennelRows = await database.rawQuery(
      '''
      SELECT ${tbl.colSongId}, ${tbl.colSongName}
      FROM $songTable
      WHERE ${tbl.colRemoved} = 0
        AND (${tbl.colAddedByKennelId} = ?
             OR ${tbl.colAutoAddToKennel} > 0)
        AND LOWER(${tbl.colSongName}) LIKE LOWER(?)
      ORDER BY
        CASE WHEN ${tbl.colAddedByKennelId} = ? THEN 0 ELSE 1 END,
        ${tbl.colSongName}
      LIMIT $songLimit
    ''',
      [kennelId, pattern, kennelId],
    );
    if (isClosed) return;
    if (kennelRows.isNotEmpty) {
      songResults.assignAll(parse(kennelRows));
      return;
    }

    final globalRows = await database.rawQuery(
      '''
      SELECT ${tbl.colSongId}, ${tbl.colSongName}
      FROM $songTable
      WHERE ${tbl.colRemoved} = 0
        AND LOWER(${tbl.colSongName}) LIKE LOWER(?)
      ORDER BY ${tbl.colSongName}
      LIMIT $songLimit
    ''',
      [pattern],
    );
    if (isClosed) return;
    songResults.assignAll(parse(globalRows));
  }

  Future<void> takeChargePhoto() async {
    isCapturingPhoto.value = true;
    try {
      final url = await KennelPhotoService().captureAndUpload(
        eventId: eventId,
        kennelId: kennelId,
        kennelSlug: kennelSlug,
        eventNumber: eventNumber,
        skipMapMarker: true,
      );
      if (isClosed) return;
      if (url != null) chargePhotoUrl.value = url;
    } finally {
      if (!isClosed) isCapturingPhoto.value = false;
    }
  }

  void removePhoto() => chargePhotoUrl.value = null;
}

/// Add Down Down: who (attendees and people not in the app), the charge, an
/// optional song and photo.
class AddDownDownController extends DownDownFormController {
  AddDownDownController({
    required super.kennelId,
    required super.eventId,
    required this.eventName,
    required super.kennelSlug,
    required super.eventNumber,
  });

  final String eventName;

  static String tagFor(String eventId) => 'add-dd-$eventId';

  @override
  int get songLimit => 10;

  final TextEditingController externalNameController = TextEditingController();

  /// Names of people being charged who are NOT registered HC users.
  final RxList<String> externalNames = <String>[].obs;
  final RxBool isLoading = true.obs;
  final RxList<AttendeeItem> attendees = <AttendeeItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    chargeController = TextEditingController();
    songController = TextEditingController();
    unawaited(loadAttendees());
  }

  @override
  void onClose() {
    externalNameController.dispose();
    super.onClose();
  }

  List<AttendeeItem> get selected =>
      attendees.where((a) => a.selected).toList();

  void toggleAttendee(AttendeeItem attendee, bool value) {
    attendee.selected = value;
    attendees.refresh();
  }

  /// Adds a name unless it is blank or already there (case-insensitive).
  /// Pure, unit-tested; returns whether it was added.
  static bool addName(List<String> names, String raw) {
    final String name = raw.trim();
    if (name.isEmpty) return false;
    final bool exists = names.any((n) => n.toLowerCase() == name.toLowerCase());
    if (!exists) names.add(name);
    return !exists;
  }

  /// Adds the typed (or supplied) name to the external-people list, ignoring
  /// blanks and case-insensitive duplicates, then clears the input.
  void addExternalName([String? value]) {
    final String raw = value ?? externalNameController.text;
    externalNameController.clear();
    final List<String> next = List<String>.of(externalNames);
    if (addName(next, raw)) externalNames.assignAll(next);
  }

  void removeExternalName(String name) => externalNames.remove(name);

  Future<void> loadAttendees() async {
    isLoading.value = true;
    try {
      // Sync the event HEM table first so attendees are available locally.
      // Without this the event_ tables are empty unless run admin was opened
      // first.
      if (Utilities.isConnected()) {
        await tableModel.syncEventAdminService.updateRsvpsFromBackend(eventId);
        if (isClosed) return;
      }

      final query =
          '''
        SELECT
          h.${tableModel.hashersTableHelper.colHasherId} as hasherId,
          coalesce(
            hem.${tableModel.hasherEventMapTableHelper.colDisplayName},
            h.${tableModel.hashersTableHelper.colDispName},
            h.${tableModel.hashersTableHelper.colHashName},
            h.${tableModel.hashersTableHelper.colFirstName} || " " || h.${tableModel.hashersTableHelper.colLastName},
            "<no name>"
          ) as displayName
        FROM ${EnumDataTables.hasherEventMap.eventTableName} hem
        INNER JOIN ${EnumDataTables.hashers.commonTableName} h
          ON hem.${tableModel.hasherEventMapTableHelper.colUserId} = h.${tableModel.hashersTableHelper.colHasherId}
        WHERE hem.${tableModel.hasherEventMapTableHelper.colEventId} = '$eventId'
          AND (
            hem.${tableModel.hasherEventMapTableHelper.colAttendenceState} >= 20
            OR hem.${tableModel.hasherEventMapTableHelper.colRsvpState} = 3
          )
          AND h.${tableModel.hashersTableHelper.colRemoved} = 0
        ORDER BY displayName COLLATE NOCASE
      ''';

      final results = await database.rawQuery(query);
      if (isClosed) return;
      attendees.assignAll(
        results.map(
          (r) => AttendeeItem(
            hasherId: r['hasherId'] as String,
            displayName: r['displayName'] as String? ?? '<no name>',
          ),
        ),
      );
    } catch (e, s) {
      BootLogger.logError('[AddDownDownPage._loadAttendees]', e, s);
    }
    if (isClosed) return;
    isLoading.value = false;
  }

  /// Why the form cannot be sent yet, or null when it can. Pure.
  static String? validationError({
    required int selectedCount,
    required int externalCount,
    required String chargeText,
  }) {
    if (selectedCount == 0 && externalCount == 0) {
      return 'Add at least one person — a hasher or a name';
    }
    if (chargeText.trim().isEmpty) return 'Enter the charge';
    return null;
  }

  Future<void> submit() async {
    // Fold in any name typed but not yet added via the + button.
    if (externalNameController.text.trim().isNotEmpty) addExternalName();

    final String? problem = validationError(
      selectedCount: selected.length,
      externalCount: externalNames.length,
      chargeText: chargeController.text,
    );
    if (problem != null) {
      hcSnack(problem, error: true);
      return;
    }

    isSaving.value = true;
    try {
      final id = await service.addDownDown(
        kennelId: kennelId,
        eventId: eventId,
        hasherIds: selected.map((a) => a.hasherId).toList(),
        chargeText: chargeController.text.trim(),
        externalNames: List<String>.of(externalNames),
        songChoice: songController.text.trim().isEmpty
            ? null
            : songController.text.trim(),
        songId: linkedSongId.value,
        chargePhotoUrl: chargePhotoUrl.value,
      );
      if (isClosed) return;
      if (id != null) {
        // Pop FIRST, then the toast: Get.back() with a GetX snackbar open
        // closes the snackbar and does not pop (see hcPop).
        hcPop();
        hcSnack('Down Down recorded!');
        return;
      }
      hcSnack('Failed to save. Are you a run attendee?', error: true);
    } catch (e, s) {
      BootLogger.logError('[AddDownDown.submit] eventId=$eventId', e, s);
      if (isClosed) return;
      hcSnack('Error saving. Please try again.', error: true);
    }
    if (!isClosed) isSaving.value = false;
  }
}

/// Edit Down Down: the charge, song and photo of an existing charge.
class EditDownDownController extends DownDownFormController {
  EditDownDownController({
    required super.kennelId,
    required super.eventId,
    required super.kennelSlug,
    required super.eventNumber,
    required this.downDown,
  });

  final DownDownModel downDown;

  static String tagFor(String downDownId) => 'edit-dd-$downDownId';

  @override
  int get songLimit => 30;

  @override
  void onInit() {
    super.onInit();
    chargeController = TextEditingController(text: downDown.chargeText);
    songController = TextEditingController(text: downDown.songChoice ?? '');
    linkedSongId.value = downDown.songId;
    chargePhotoUrl.value = downDown.chargePhotoUrl;
  }

  Future<void> save() async {
    final chargeText = chargeController.text.trim();
    if (chargeText.isEmpty) {
      hcSnack('Charge text is required', error: true);
      return;
    }

    isSaving.value = true;

    final songText = songController.text.trim();
    final String? newPhoto = chargePhotoUrl.value != downDown.chargePhotoUrl
        ? chargePhotoUrl.value
        : null;

    final ok = await service.updateDownDown(
      kennelId: kennelId,
      eventId: eventId,
      downDownId: downDown.downDownId,
      chargeText: chargeText,
      songChoice: songText.isEmpty ? null : songText,
      songId: linkedSongId.value,
      chargePhotoUrl: newPhoto,
    );
    if (isClosed) return;
    if (ok) {
      hcPop(result: true);
      return;
    }
    isSaving.value = false;
    hcSnack('Failed to update. Please try again.', error: true);
  }
}
