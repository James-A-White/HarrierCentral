import 'package:harrier_central/imports.dart';

/// State for [RunPhotoGallery]: the photo list, its load/refresh/import
/// sequence, and the photographer lookup for the full-screen viewer.
///
/// Migrated from a State on 2026-09-23. Every `await` is followed by an
/// `isClosed` check, which is what the old `mounted` checks were for; the
/// list is an [RxList] assigned in one step so no repaint can be forgotten.
class RunPhotoGalleryController extends GetxController {
  RunPhotoGalleryController({
    required this.loader,
    required this.eventName,
    required this.run,
  });

  /// Fetches the photo list — called on first build, pull-to-refresh, and
  /// after an import lands. Owned by the host tab, which knows which SP.
  final Future<({bool success, List<RunPhotoModel> photos})> Function() loader;
  final String eventName;

  /// The run these photos belong to. Null on the guest path (no aggregate),
  /// which is also why the guest gallery has no import button.
  final RunDetailsAggregate? run;

  /// One gallery per run; the guest path has no run id, so its name serves.
  static String tagFor(RunDetailsAggregate? run, String eventName) =>
      'photos-${run?.event.eventId ?? eventName}';

  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxBool isImporting = false.obs;
  final RxList<RunPhotoModel> photos = <RunPhotoModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  /// First load and explicit retry: shows the spinner.
  Future<void> load() async {
    isLoading.value = true;
    hasError.value = false;
    final result = await loader();
    if (isClosed) return;
    photos.assignAll(result.photos);
    hasError.value = !result.success;
    isLoading.value = false;
  }

  /// Pull-to-refresh: no spinner, and a failure only becomes an error state
  /// when there is nothing on screen to keep.
  Future<void> pullToRefresh() async {
    final result = await loader();
    if (isClosed) return;
    if (result.success) {
      photos.assignAll(result.photos);
      hasError.value = false;
    } else if (photos.isEmpty) {
      hasError.value = true;
    }
  }

  /// Imports photos the user took on their own camera during this run.
  ///
  /// The run has no end time of its own, so the end of the window is the last
  /// GPS point anyone recorded for it — with a conservative fallback when
  /// nobody tracked at all.
  ///
  /// The window is built in the RUN's wall clock, not the phone's. A photo's
  /// EXIF time is the wall clock where it was taken, so comparing it against a
  /// window derived from the phone's current zone breaks the moment someone
  /// runs abroad and imports after flying home. The run's own UTC offset comes
  /// free: it's the gap between the event's local time and its true instant.
  Future<void> importFromCameraRoll() async {
    final run = this.run;
    if (run == null || isImporting.value) return;
    isImporting.value = true;

    // Wall-clock digits of the run's start, held UTC-flagged so arithmetic
    // never drags in the device zone.
    final DateTime localStart = run.event.eventStartDatetime;
    final DateTime startWall = DateTime.utc(
      localStart.year,
      localStart.month,
      localStart.day,
      localStart.hour,
      localStart.minute,
      localStart.second,
    );
    final Duration runOffset = startWall.difference(
      run.event.eventStartDatetimeGmt.toUtc(),
    );

    DateTime endWall = startWall.add(const Duration(hours: 6)); // untracked

    final api = GetPositionsApi();
    try {
      final payload = await api.fetchPositions(
        eventId: run.event.eventId,
        latestClientTimestampMs: '0000000000000000000',
      );
      int newest = 0;
      for (final u in payload.users) {
        for (final p in u.positions) {
          if (p.timestampMs > newest) newest = p.timestampMs;
        }
      }
      if (newest > 0) {
        // Track points are true instants; shift into the run's wall clock.
        final lastWall = DateTime.fromMillisecondsSinceEpoch(
          newest,
          isUtc: true,
        ).add(runOffset);
        if (lastWall.isAfter(startWall)) endWall = lastWall;
      }
    } catch (_) {
      // Keep the fallback window — a failed lookup shouldn't block importing.
    } finally {
      api.dispose();
    }

    final result = await KennelPhotoService().importFromCameraRoll(
      eventId: run.event.eventId,
      kennelId: run.kennel.kennelId,
      kennelSlug: run.kennel.kennelUniqueShortName,
      eventNumber: run.event.eventNumber,
      runStartWall: startWall,
      runEndWall: endWall,
      runUtcOffset: runOffset,
      runStartLat: run.extensions.evtLat ?? run.event.hcLatitude,
      runStartLng: run.extensions.evtLon ?? run.event.hcLongitude,
    );

    if (isClosed) return;
    isImporting.value = false;

    if (result.imported == 0 && result.rejected == 0 && result.failed == 0) {
      return; // picker cancelled — say nothing
    }

    final parts = <String>[];
    if (result.imported > 0) {
      parts.add('${result.imported} sent to the Hash Flash for review');
    }
    if (result.rejected > 0) {
      parts.add(
        '${result.rejected} skipped — no location, or not taken at this run',
      );
    }
    if (result.failed > 0) {
      parts.add('${result.failed} could not be uploaded');
    }

    try {
      Get.snackbar(
        result.imported > 0 ? 'Photos added' : 'No photos added',
        parts.join('. '),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: result.imported > 0 ? hc_blue : hc_red,
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
      );
    } catch (e, s) {
      BootLogger.logError('[RunPhotoGallery.import] snackbar', e, s);
    }

    if (result.imported > 0) await load();
  }

  /// Resolves photographer name + avatar for every distinct uploader in the
  /// current photo set, keyed by normalised userId. Cached per uploader so N
  /// photos = at most N distinct reads.
  Future<Map<String, ({String name, String photo})>>
  resolvePhotographers() async {
    final result = <String, ({String name, String photo})>{};
    final currentUserId = normalizeUuid(
      getStringPref(StringPrefsEnum.userId) ?? '',
    );
    for (final p in List<RunPhotoModel>.of(photos)) {
      final uid = normalizeUuid(p.userId ?? '');
      if (uid.isEmpty || result.containsKey(uid)) continue;

      // Name: others carry uploaderDisplayName from the SP; own photos use the
      // signed-in user's stored display name.
      var name = p.uploaderDisplayName ?? '';
      if (name.isEmpty && uid == currentUserId) {
        name = getStringPref(StringPrefsEnum.displayName) ?? '';
      }

      // Avatar: the raw colPhoto value (may be http or bundle://) — resolved for
      // display via avatarImageProvider in the viewer.
      var photo = '';
      final rows = await QueryUsers.querySingleUser(uid);
      if (rows.isNotEmpty) {
        photo =
            (rows.first[tableModel.hashersTableHelper.colPhoto] as String?) ??
            '';
      }

      result[uid] = (name: name, photo: photo);
    }
    return result;
  }
}
