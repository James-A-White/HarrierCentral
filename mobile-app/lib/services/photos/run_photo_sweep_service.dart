import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/photos/camera_roll_scan_service.dart';
import 'package:harrier_central/services/photos/scannable_runs_query.dart';
import 'package:photo_manager/photo_manager.dart' hide LatLng;

/// The camera-roll sweep as the pages use it (E6.F2.S5): work out which runs
/// to look at, ask the server what is already up, scan, and upload the ones
/// the hasher ticked.
class RunPhotoSweepService {
  const RunPhotoSweepService();

  static const CameraRollScanService _scanner = CameraRollScanService();

  /// Sweep one run, or a whole kennel's attended runs. Returns the runs that
  /// had at least one eligible photo, newest first.
  Future<List<RunScanResult>> sweep({
    String? kennelId,
    String? eventId,
    void Function(int done, int total)? onProgress,
  }) async {
    final List<ScannableRun> runs = await ScannableRunsQuery.attended(
      kennelId: kennelId,
      eventId: eventId,
    );
    if (runs.isEmpty) return const <RunScanResult>[];

    final Map<String, Set<String>> uploaded = await fetchUploadedAssetIds(
      kennelId: kennelId,
      eventId: eventId,
    );

    return _scanner.scan(
      runs: runs,
      uploadedAssetIds: uploaded,
      onProgress: onProgress,
    );
  }

  /// Ask for the photo library. The app normally bypasses this check because
  /// it only touches its own assets; a sweep reads the whole roll, so it has
  /// to ask properly.
  Future<PermissionState> requestAccess() => _scanner.requestAccess();

  /// What this hasher has already uploaded, as asset ids keyed by run. One
  /// call for the whole kennel, so the overview makes no request per run.
  Future<Map<String, Set<String>>> fetchUploadedAssetIds({
    String? kennelId,
    String? eventId,
  }) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    final String raw = await ServiceCommon.sendHttpPost(() {
      return jsonEncode(<String, dynamic>{
        'queryType': 'getMyPhotoAssetIds',
        'deviceId': deviceId,
        if (kennelId != null && kennelId.isNotEmpty) 'kennelId': kennelId,
        if (eventId != null && eventId.isNotEmpty) 'eventId': eventId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_getMyPhotoAssetIds',
          paramString: deviceSecret,
        ),
      });
    }, noRetries: true);

    // Offline or refused: the sweep still works, it just cannot mark what is
    // already up. Better a sweep that over-offers than no sweep at all.
    if (raw.startsWith(ERROR_PREFIX)) return const <String, Set<String>>{};
    final Map<String, Set<String>> out = <String, Set<String>>{};
    try {
      final List<dynamic> rowsets = jsonDecode(raw) as List<dynamic>;
      if (rowsets.isEmpty) return out;
      for (final dynamic r in rowsets[0] as List<dynamic>) {
        final Map<String, dynamic> row = r as Map<String, dynamic>;
        final String ev = normalizeUuid((row['eventId'] as String?) ?? '');
        final String asset = (row['assetId'] as String?) ?? '';
        if (ev.isEmpty || asset.isEmpty) continue;
        (out[ev] ??= <String>{}).add(asset);
      }
    } catch (e, s) {
      BootLogger.logError('[RunPhotoSweep.fetchUploadedAssetIds]', e, s);
    }
    return out;
  }

  /// Send the ticked photos up for their run. Each takes the normal import
  /// path, so the capture time, the coordinate and the asset id are kept and
  /// a Hash Flash reviews it exactly like any other submission.
  ///
  /// Returns how many went up and how many failed.
  Future<({int sent, int failed})> upload({
    required ScannableRun run,
    required List<PhotoCandidate> chosen,
    void Function(int done, int total)? onProgress,
  }) async {
    int sent = 0;
    int failed = 0;
    int done = 0;
    for (final PhotoCandidate c in chosen) {
      try {
        final File? file = await c.asset.file;
        if (file == null) {
          failed++;
          continue;
        }
        final bool ok = await KennelPhotoService().uploadExistingPhoto(
          imageFile: file,
          eventId: run.eventId,
          kennelId: run.kennelId,
          kennelSlug: run.kennelSlug,
          eventNumber: run.eventNumber,
          latitude: c.lat,
          longitude: c.lng,
          takenAtMs: c.takenUtc.millisecondsSinceEpoch,
          assetId: c.asset.id,
        );
        if (ok) {
          sent++;
        } else {
          failed++;
        }
      } catch (e, s) {
        BootLogger.logError('[RunPhotoSweep.upload] ${c.asset.id}', e, s);
        failed++;
      }
      onProgress?.call(++done, chosen.length);
    }
    return (sent: sent, failed: failed);
  }
}
