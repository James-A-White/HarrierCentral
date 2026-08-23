import 'package:exif/exif.dart';
import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:photo_manager/photo_manager.dart';

// Photo review action codes — match hcapp_updatePhotoStatus @action parameter.
// Actions 3–6 are cumulative: each level implies all lower approval levels.
const int photoActionDelete = 1; // hard-delete (inappropriate content)
const int photoActionKeepPrivate = 2; // back to uploader-only (status 0)
const int photoActionMembers = 3; // kennel members only (status 2)
const int photoActionPublic = 4; // everyone: app + public web (status 3)
const int photoActionFeature =
    5; // set Featured flag (kennel home showcase) — status unchanged
const int photoActionMakeEventCover =
    6; // public + run cover photo (status 5, one per run)
const int photoActionUnfeature = 7; // clear Featured flag

/// How far from the run's start a photo may have been taken and still count as
/// part of the run. Generous on purpose — hashes wander, and a point-to-point
/// or a coach trip can cover real ground — but tight enough to exclude a photo
/// from an entirely different day out that happens to fall inside the run's
/// hours.
const double _maxPhotoDistanceMiles = 30.0;

/// How a [KennelPhotoService.captureAndUpload] attempt ended — reported via
/// its `onOutcome` callback. The return value alone can't tell a camera
/// cancel from a queued-offline photo (both return null), and a multi-shot
/// session needs that difference to decide whether to reopen the camera.
enum KennelPhotoCaptureOutcome {
  uploaded,
  queuedOffline,
  discarded,
  cancelledAtCamera,
  failed,
}

class KennelPhotoService {
  /// Orchestrates the full capture → upload → record flow.
  ///
  /// Returns the permanent blob URL on success, or null if the user
  /// cancelled or any step failed (error shown via snackbar).
  Future<String?> captureAndUpload({
    required String eventId,
    required String kennelId,
    required String kennelSlug,
    required int eventNumber,
    // Timestamp for the GPS track marker. Pass the run's scheduled start time
    // for pre-run photos, the last track-point time for post-run photos, or
    // null to use DateTime.now() (the normal during-run behaviour).
    int? markerTimestampMs,
    // Set true to skip placing a PHO marker on the GPS track entirely.
    // Use for photos taken before/after the run, or for charge attachments
    // where a separate marker type already marks the location.
    bool skipMapMarker = false,
    // Reports how the attempt ended (see [KennelPhotoCaptureOutcome]).
    void Function(KennelPhotoCaptureOutcome outcome)? onOutcome,
  }) async {
    // Run folder: "<kennelSlug>-<runNumber>" when there is a run number,
    // otherwise "other". Nested under the kennel slug in blob storage.
    final runFolder = eventNumber > 0 ? '$kennelSlug-$eventNumber' : 'other';

    // 1. Pick from camera at full quality (no compression at capture time).
    //    Compression for blob upload happens separately in step 5.
    //    Simulator uses a bundled placeholder.
    final rawFile = await _pickImage();
    if (rawFile == null) {
      onOutcome?.call(KennelPhotoCaptureOutcome.cancelledAtCamera);
      return null; // user cancelled
    }

    // 2. Show review page: Discard / Edit / Save privately / Save and share.
    //    Edit opens the cropper at full quality; result carries the final file + intent.
    final result = await _showSharePage(rawFile);
    if (result == null) {
      onOutcome?.call(KennelPhotoCaptureOutcome.discarded);
      return null;
    }
    final imageFile = result.file; // full-quality, possibly cropped
    final sharingOverride = result.intent == _PhotoShareIntent.saveAndShare
        ? 1
        : 0;
    final caption = result.caption;

    // 3. Client-side GUID — normalised to lowercase per project UUID rules
    final photoGuid = const Uuid().v4().toLowerCase();

    // 4. Optionally save a full-quality copy to the device camera roll.
    //    The returned assetId lets the app reload this photo locally rather
    //    than fetching the blob. Silent on failure (perm denied, etc.).
    //    hasherPref_cameraRollSaveDisabled uses inverted semantics: bit NOT set
    //    means enabled, so existing users (bit = 0) get camera roll ON by default.
    String? assetId;
    final int prefs = getIntPref(IntPrefsEnum.hasherPreferences) ?? 0;
    if ((prefs & hasherPref_cameraRollSaveDisabled) == 0) {
      // image_picker (and ImageCropper on the Edit path) strip the original
      // EXIF, including GPS. Re-attach the location we already have so the
      // camera-roll copy keeps its lat/long.
      final pos = Get.find<LocationService>().lastKnownPosition.value;
      assetId = await _saveToDeviceLibrary(
        imageFile,
        latitude: pos?.latitude,
        longitude: pos?.longitude,
      );
    }

    // 5. Compress the image for blob upload (quality 70, capped at 1920px).
    //    Camera roll already received the full-quality copy in step 4.
    final uploadFile = await _compressForUpload(imageFile) ?? imageFile;

    // 6. Queue for later if offline — save compressed file to documents dir
    //    and store metadata in GetStorage. The upload completes automatically
    //    the next time the app opens with a network connection.
    if (!Utilities.isConnected()) {
      await _queueForOfflineUpload(
        imageFile: uploadFile,
        photoGuid: photoGuid,
        eventId: eventId,
        kennelId: kennelId,
        kennelSlug: kennelSlug,
        eventNumber: eventNumber,
        sharingOverride: sharingOverride,
        caption: caption,
        assetId: assetId,
      );
      // Stamp the GPS track now at the correct position and time. If the photo
      // upload eventually fails permanently the map resolves the photoId to null
      // and hides the marker — no user-visible damage.
      if (!skipMapMarker) {
        _enqueuePhotoMarker(
          photoId: photoGuid,
          eventId: eventId,
          timestampMs:
              markerTimestampMs ?? DateTime.now().millisecondsSinceEpoch,
        );
      }
      onOutcome?.call(KennelPhotoCaptureOutcome.queuedOffline);
      return null;
    }

    // 7. (online path) Request a short-lived SAS write token from the API
    final tokenResult = await _getUploadToken(
      kennelId: kennelId,
      kennelSlug: kennelSlug,
      runFolder: runFolder,
      photoGuid: photoGuid,
    );
    if (tokenResult == null) {
      onOutcome?.call(KennelPhotoCaptureOutcome.queuedOffline);
      await _queueForOfflineUpload(
        imageFile: uploadFile,
        photoGuid: photoGuid,
        eventId: eventId,
        kennelId: kennelId,
        kennelSlug: kennelSlug,
        eventNumber: eventNumber,
        sharingOverride: sharingOverride,
        caption: caption,
        assetId: assetId,
        isOnlineFailure: true,
      );
      if (!skipMapMarker) {
        _enqueuePhotoMarker(
          photoId: photoGuid,
          eventId: eventId,
          timestampMs:
              markerTimestampMs ?? DateTime.now().millisecondsSinceEpoch,
        );
      }
      return null;
    }

    final sasUrl = tokenResult['sasUrl'];
    final blobUrl = tokenResult['blobUrl'];
    if (sasUrl == null || blobUrl == null) {
      onOutcome?.call(KennelPhotoCaptureOutcome.failed);
      Get.snackbar(
        'Upload failed',
        'Upload token was missing required fields. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: hc_red,
        colorText: Colors.white,
      );
      return null;
    }

    final sasUri = Uri.tryParse(sasUrl);
    if (sasUri == null ||
        sasUri.host != 'harriercentral.blob.core.windows.net') {
      onOutcome?.call(KennelPhotoCaptureOutcome.failed);
      Get.snackbar(
        'Upload failed',
        'Invalid upload token. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: hc_red,
        colorText: Colors.white,
      );
      return null;
    }

    // 7. Upload compressed bytes directly to blob storage via the SAS URL
    final uploaded = await _uploadToBlob(sasUrl: sasUrl, imageFile: uploadFile);
    if (!uploaded) {
      onOutcome?.call(KennelPhotoCaptureOutcome.queuedOffline);
      await _queueForOfflineUpload(
        imageFile: uploadFile,
        photoGuid: photoGuid,
        eventId: eventId,
        kennelId: kennelId,
        kennelSlug: kennelSlug,
        eventNumber: eventNumber,
        sharingOverride: sharingOverride,
        caption: caption,
        assetId: assetId,
        isOnlineFailure: true,
      );
      if (!skipMapMarker) {
        _enqueuePhotoMarker(
          photoId: photoGuid,
          eventId: eventId,
          timestampMs:
              markerTimestampMs ?? DateTime.now().millisecondsSinceEpoch,
        );
      }
      return null;
    }

    // 8. Record the photo in the database
    final recorded = await _addKennelPhoto(
      eventId: eventId,
      kennelId: kennelId,
      photoId: photoGuid,
      blobUrl: blobUrl,
      assetId: assetId,
      perRunSharingOverride: sharingOverride,
      caption: caption,
    );
    if (!recorded) {
      Get.snackbar(
        'Photo saved locally',
        'The photo was uploaded but could not be recorded. '
            'It may not appear on the map.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: hc_red,
        colorText: Colors.white,
      );
      // Still return blobUrl — photo is in storage even if the DB call failed
      onOutcome?.call(KennelPhotoCaptureOutcome.uploaded);
      return blobUrl;
    }

    // 9. Enqueue a PHO marker into the GPS track feed
    if (!skipMapMarker) {
      _enqueuePhotoMarker(
        photoId: photoGuid,
        eventId: eventId,
        timestampMs: markerTimestampMs ?? DateTime.now().millisecondsSinceEpoch,
      );
    }

    onOutcome?.call(KennelPhotoCaptureOutcome.uploaded);
    return blobUrl;
  }

  // ── Photo capture ────────────────────────────────────────────────────────

  /// Captures at full camera quality — no compression at this stage.
  /// Compression for blob upload happens via [_compressForUpload] later.
  Future<File?> _pickImage() async {
    if (!deviceInfo.isPhysicalDevice) {
      return _simulatorPlaceholder();
    }
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    return picked == null ? null : File(picked.path);
  }

  /// Returns a temp File backed by the splash screen JPEG so tests on the
  /// simulator don't need to touch the camera at all.
  Future<File?> _simulatorPlaceholder() async {
    try {
      final data = await rootBundle.load('images/init/splash_screen.jpg');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/hc_simulator_photo.jpg');
      await file.writeAsBytes(data.buffer.asUint8List());
      return file;
    } catch (e, s) {
      debugPrint('KennelPhotoService: simulator placeholder failed: $e');
      BootLogger.logError('[KennelPhotoService._simulatorPlaceholder]', e, s);
      return null;
    }
  }

  // ── Camera roll save ─────────────────────────────────────────────────────

  /// Saves [imageFile] to the device photo library and returns the asset ID.
  /// Returns null if permission is denied or the save fails.
  ///
  /// [latitude]/[longitude] are written into the saved asset's location
  /// metadata (photo_manager sets the GPS EXIF / PHAsset location). image_picker
  /// and ImageCropper strip the camera's original EXIF, so without this the
  /// camera-roll copy would have no location.
  Future<String?> _saveToDeviceLibrary(
    File imageFile, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) return null;
      final bytes = await imageFile.readAsBytes();

      // Only attach coordinates when we have a real fix — skip null and the
      // 0,0 "no fix" sentinel so we never stamp a bogus location. saveImage
      // requires latitude and longitude together or not at all.
      final bool hasCoords =
          latitude != null &&
          longitude != null &&
          !(latitude == 0.0 && longitude == 0.0);

      final entity = await PhotoManager.editor.saveImage(
        bytes,
        filename: 'hc_${DateTime.now().millisecondsSinceEpoch}.jpg',
        desc: '',
        latitude: hasCoords ? latitude : null,
        longitude: hasCoords ? longitude : null,
        creationDate: DateTime.now(),
      );
      return entity.id;
    } catch (e, s) {
      debugPrint('KennelPhotoService: camera roll save failed: $e');
      BootLogger.logError(
        '[KennelPhotoService._saveToDeviceLibrary] path=${imageFile.path}',
        e,
        s,
      );
      return null;
    }
  }

  // ── Blob upload compression ──────────────────────────────────────────────

  /// Compresses [imageFile] for blob upload (quality 70, max 1920px on longest edge).
  /// Returns null on failure — callers should fall back to the original file.
  Future<File?> _compressForUpload(File imageFile) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/hc_upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 1920,
        minHeight: 1920,
        format: CompressFormat.jpeg,
      );
      return result == null ? null : File(result.path);
    } catch (e, s) {
      debugPrint('KennelPhotoService: compress failed, using original: $e');
      BootLogger.logError(
        '[KennelPhotoService._compressForUpload] path=${imageFile.path}',
        e,
        s,
      );
      return null;
    }
  }

  // ── SAS token request ────────────────────────────────────────────────────

  Future<Map<String, String>?> _getUploadToken({
    required String kennelId,
    required String kennelSlug,
    required String runFolder,
    required String photoGuid,
  }) async {
    final userId = currentUserId;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    try {
      final response = await post(
        Uri.parse(PHOTO_UPLOAD_TOKEN_URL),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(<String, String>{
          'deviceId': deviceId,
          'accessToken': Utilities.generateToken(
            userId,
            'hcapp_getPhotoUploadToken',
            paramString: deviceSecret,
          ),
          'kennelId': kennelId,
          'kennelSlug': kennelSlug,
          'runFolder': runFolder,
          'photoGuid': photoGuid,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final sasUrl = data['sasUrl'] as String?;
        final blobUrl = data['blobUrl'] as String?;
        if (sasUrl == null || blobUrl == null) return null;
        return {'sasUrl': sasUrl, 'blobUrl': blobUrl};
      }
      debugPrint(
        'GetPhotoUploadToken failed: HTTP ${response.statusCode} — ${response.body}',
      );
      BootLogger.logError(
        '[KennelPhotoService._getUploadToken] HTTP ${response.statusCode}',
        response.body,
        null,
      );
    } catch (e, s) {
      debugPrint('GetPhotoUploadToken exception: $e');
      BootLogger.logError(
        '[KennelPhotoService._getUploadToken] kennelId=$kennelId kennelSlug=$kennelSlug runFolder=$runFolder',
        e,
        s,
      );
    }
    return null;
  }

  // ── Blob upload ──────────────────────────────────────────────────────────

  Future<bool> _uploadToBlob({
    required String sasUrl,
    required File imageFile,
  }) async {
    try {
      final request = Request('PUT', Uri.parse(sasUrl));
      request.headers['content-type'] = 'image/jpeg';
      request.headers['x-ms-blob-type'] = 'BlockBlob';
      request.bodyBytes = await imageFile.readAsBytes();
      final response = await request.send().timeout(
        const Duration(seconds: 60),
      );
      return response.statusCode == 201;
    } catch (e, s) {
      BootLogger.logError('[KennelPhotoService._uploadToBlob]', e, s);
      return false;
    }
  }

  // ── Database record ──────────────────────────────────────────────────────

  Future<bool> _addKennelPhoto({
    required String eventId,
    required String kennelId,
    required String photoId,
    required String blobUrl,
    String? assetId,
    int? perRunSharingOverride,
    String? caption,
    // Explicit coords for queued uploads; falls back to current position
    // for live uploads so existing call sites remain unchanged.
    double? lat,
    double? lng,
  }) async {
    double resolvedLat = lat ?? 0.0;
    double resolvedLng = lng ?? 0.0;
    if (lat == null || lng == null) {
      final pos = Get.find<LocationService>().lastKnownPosition.value;
      resolvedLat = pos?.latitude ?? 0.0;
      resolvedLng = pos?.longitude ?? 0.0;
    }

    final userId = currentUserId;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final body = <String, dynamic>{
      'queryType': 'addKennelPhoto',
      'deviceId': deviceId,
      'photoId': photoId,
      'eventId': eventId,
      'kennelId': kennelId,
      'blobUrl': blobUrl,
      'latitude': resolvedLat,
      'longitude': resolvedLng,
    };

    if (assetId != null && assetId.isNotEmpty) {
      body['assetId'] = assetId;
    }
    if (perRunSharingOverride != null) {
      body['perRunSharingOverride'] = perRunSharingOverride;
    }
    if (caption != null && caption.isNotEmpty) {
      body['description'] = caption;
    }

    final result = await ServiceCommon.sendHttpPost(() {
      // Minted inside the closure: fresh token per attempt (token retry).
      body['accessToken'] = Utilities.generateToken(
        userId,
        'hcapp_addKennelPhoto',
        paramString: deviceSecret,
      );
      return jsonEncode(body);
    });

    return !result.startsWith(ERROR_PREFIX);
  }

  // ── GPS track marker ─────────────────────────────────────────────────────

  /// Opens the phone's own photo picker and imports whichever of the chosen
  /// photos belong to this run.
  ///
  /// A photo qualifies only if its own EXIF carries BOTH a GPS position and a
  /// capture time, and that time falls inside the run. Anything else is
  /// rejected — a photo without a position can't be placed on the track, and
  /// one without a time can't be shown to have been taken on the run at all.
  ///
  /// TIMEZONES. EXIF capture times carry no zone — they are the wall clock of
  /// wherever the photo was taken. So the comparison is done entirely in the
  /// RUN's wall clock: [runStartWall] and [runEndWall] are UTC-flagged
  /// DateTimes carrying the run's local clock digits, and the photo's EXIF
  /// digits are read the same way. Interpreting either against the phone's
  /// CURRENT zone would break for a hasher who runs abroad and imports after
  /// flying home — the window would shift by the zone difference and reject
  /// every photo. [runUtcOffset] converts a wall time back to a true instant
  /// for the GPS marker, which does need a real point in time.
  ///
  /// Returns counts so the caller can tell the user what happened.
  Future<({int imported, int rejected, int failed})> importFromCameraRoll({
    required String eventId,
    required String kennelId,
    required String kennelSlug,
    required int eventNumber,
    required DateTime runStartWall,
    required DateTime runEndWall,
    required Duration runUtcOffset,
    // The run's start location. When known, photos taken further than
    // [_maxPhotoDistanceMiles] from it are rejected: a photo whose EXIF time
    // happens to land in the window but was taken in another county belongs to
    // someone's day off, not this run. Null when the run has no coordinates,
    // in which case the distance check is skipped rather than guessed at.
    double? runStartLat,
    double? runStartLng,
  }) async {
    // Phone clocks drift against GPS time; a little slack at each end beats
    // rejecting a legitimate photo taken moments before the off.
    const slack = Duration(minutes: 20);
    final from = runStartWall.subtract(slack);
    final to = runEndWall.add(slack);

    // requestFullMetadata keeps EXIF (including GPS) on iOS — without it the
    // platform hands back a stripped copy and every photo would be rejected.
    final picked = await ImagePicker().pickMultiImage(
      requestFullMetadata: true,
    );
    if (picked.isEmpty) return (imported: 0, rejected: 0, failed: 0);

    int imported = 0, rejected = 0, failed = 0;

    for (final x in picked) {
      final file = File(x.path);
      final meta = await _readPhotoMetadata(file);
      if (meta == null) {
        rejected++;
        continue;
      }
      if (meta.takenAt.isBefore(from) || meta.takenAt.isAfter(to)) {
        rejected++;
        continue;
      }
      if (runStartLat != null && runStartLng != null) {
        final away = const latlng.Distance().as(
          latlng.LengthUnit.Meter,
          latlng.LatLng(runStartLat, runStartLng),
          latlng.LatLng(meta.lat, meta.lng),
        );
        if (away > _maxPhotoDistanceMiles * MILES_TO_METERS) {
          rejected++;
          continue;
        }
      }
      final ok = await uploadExistingPhoto(
        imageFile: file,
        eventId: eventId,
        kennelId: kennelId,
        kennelSlug: kennelSlug,
        eventNumber: eventNumber,
        latitude: meta.lat,
        longitude: meta.lng,
        // Wall clock back to a true instant for the GPS track.
        takenAtMs: meta.takenAt
            .subtract(runUtcOffset)
            .millisecondsSinceEpoch,
      );
      if (ok) {
        imported++;
      } else {
        failed++;
      }
    }

    return (imported: imported, rejected: rejected, failed: failed);
  }

  /// Reads GPS + capture time from a photo's EXIF. Null when either is absent
  /// — both are required, so there's nothing to salvage from a partial read.
  Future<({double lat, double lng, DateTime takenAt})?> _readPhotoMetadata(
    File file,
  ) async {
    try {
      final tags = await readExifFromBytes(await file.readAsBytes());
      if (tags.isEmpty) return null;

      final lat = _exifCoordinate(
        tags['GPS GPSLatitude'],
        tags['GPS GPSLatitudeRef'],
        negativeRef: 'S',
      );
      final lng = _exifCoordinate(
        tags['GPS GPSLongitude'],
        tags['GPS GPSLongitudeRef'],
        negativeRef: 'W',
      );
      if (lat == null || lng == null) return null;
      if (lat == 0 && lng == 0) return null; // null island — not a real fix

      // EXIF dates are "YYYY:MM:DD HH:MM:SS" — the wall clock where the photo
      // was taken, with NO zone. Parsed with a Z so it stays UTC-flagged and
      // carries those digits verbatim, instead of Dart reinterpreting them in
      // whatever zone the phone happens to be in now. The caller compares it
      // against the run's wall clock.
      final raw = (tags['EXIF DateTimeOriginal'] ?? tags['Image DateTime'])
          ?.printable
          .trim();
      if (raw == null || raw.length < 19) return null;
      final iso =
          '${raw.substring(0, 4)}-${raw.substring(5, 7)}-${raw.substring(8, 10)}'
          'T${raw.substring(11, 19)}Z';
      final takenAt = DateTime.tryParse(iso);
      if (takenAt == null) return null;

      return (lat: lat, lng: lng, takenAt: takenAt);
    } catch (e) {
      if (kDebugMode) debugPrint('[PhotoImport] EXIF read failed: $e');
      return null;
    }
  }

  /// EXIF stores coordinates as degrees/minutes/seconds rationals plus a
  /// hemisphere ref; convert to a signed decimal degree.
  double? _exifCoordinate(
    IfdTag? value,
    IfdTag? ref, {
    required String negativeRef,
  }) {
    final values = value?.values.toList();
    if (values == null || values.length < 3) return null;
    double part(dynamic r) {
      if (r is Ratio) {
        return r.denominator == 0 ? 0.0 : r.numerator / r.denominator;
      }
      return double.tryParse(r.toString()) ?? 0.0;
    }

    final decimal =
        part(values[0]) + part(values[1]) / 60.0 + part(values[2]) / 3600.0;
    final hemisphere = ref?.printable.trim().toUpperCase() ?? '';
    return hemisphere == negativeRef ? -decimal : decimal;
  }

  /// Uploads a photo the user took OUTSIDE the app (camera roll import).
  ///
  /// Unlike [captureAndUpload] there is no camera, no review page and no
  /// camera-roll save — the photo is already on the device. Position and time
  /// come from the photo's own metadata rather than from "now", so both the
  /// database row and the GPS track marker land where and when the picture was
  /// actually taken.
  ///
  /// Enters the normal pending queue, so a Hash Flash approves it exactly like
  /// any in-app photo.
  Future<bool> uploadExistingPhoto({
    required File imageFile,
    required String eventId,
    required String kennelId,
    required String kennelSlug,
    required int eventNumber,
    required double latitude,
    required double longitude,
    required int takenAtMs,
    String? assetId,
  }) async {
    final runFolder = eventNumber > 0 ? '$kennelSlug-$eventNumber' : 'other';
    final photoGuid = const Uuid().v4().toLowerCase();
    final uploadFile = await _compressForUpload(imageFile) ?? imageFile;

    if (!Utilities.isConnected()) {
      await _queueForOfflineUpload(
        imageFile: uploadFile,
        photoGuid: photoGuid,
        eventId: eventId,
        kennelId: kennelId,
        kennelSlug: kennelSlug,
        eventNumber: eventNumber,
        // 1 = submit for review (status 1, pending). Imports are always sent
        // to the Hash Flash — the gallery snackbar tells the user so.
        sharingOverride: 1,
        caption: null,
        assetId: assetId,
      );
      _enqueuePhotoMarker(
        photoId: photoGuid,
        eventId: eventId,
        timestampMs: takenAtMs,
        atLat: latitude,
        atLng: longitude,
      );
      return true; // queued — it will complete on the next connected launch
    }

    final tokenResult = await _getUploadToken(
      kennelId: kennelId,
      kennelSlug: kennelSlug,
      runFolder: runFolder,
      photoGuid: photoGuid,
    );
    final sasUrl = tokenResult?['sasUrl'];
    final blobUrl = tokenResult?['blobUrl'];
    if (sasUrl == null || blobUrl == null) return false;

    final sasUri = Uri.tryParse(sasUrl);
    if (sasUri == null ||
        sasUri.host != 'harriercentral.blob.core.windows.net') {
      return false;
    }

    if (!await _uploadToBlob(sasUrl: sasUrl, imageFile: uploadFile)) {
      return false;
    }

    final recorded = await _addKennelPhoto(
      eventId: eventId,
      kennelId: kennelId,
      photoId: photoGuid,
      blobUrl: blobUrl,
      assetId: assetId,
      // 1 = submit for review (status 1, pending) — NOT approved. 0 would keep
      // the photo private forever and it would never reach the Hash Flash.
      perRunSharingOverride: 1,
      lat: latitude,
      lng: longitude,
    );
    if (!recorded) return false;

    _enqueuePhotoMarker(
      photoId: photoGuid,
      eventId: eventId,
      timestampMs: takenAtMs,
      atLat: latitude,
      atLng: longitude,
    );
    return true;
  }

  void _enqueuePhotoMarker({
    required String photoId,
    required String eventId,
    required int timestampMs,
    // Imported photos mark where the PHOTO was taken, not where the phone is.
    double? atLat,
    double? atLng,
  }) {
    // Label is the photoId (UUID) only — the map controller resolves the
    // blob URL via hcapp_getRunPhotos so the URL is never stored in the
    // GPS track, preventing unauthenticated blob access from the label alone.
    unawaited(
      Get.find<LocationService>().markPointAt(
        pointType: HashRunPointTypes.photo,
        timestampMs: timestampMs,
        overrideEventId: eventId,
        overrideUserId: currentUserId,
        label: photoId,
        atLat: atLat,
        atLng: atLng,
      ),
    );
  }

  // ── Public query methods (called by Hash Flash screen + map) ─────────────

  /// Sends a batch of {photoId, action} pairs in one SP call.
  /// Returns the raw response string for the caller to inspect.
  Future<String> batchUpdatePhotoStatus({
    required String kennelId,
    required List<Map<String, dynamic>> updates,
  }) async {
    final userId = currentUserId;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    return ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'batchUpdatePhotoStatus',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_batchUpdatePhotoStatus',
          paramString: deviceSecret,
        ),
        'kennelId': kennelId,
        'updates': jsonEncode(updates),
      }),
      noRetries: true,
    );
  }

  Future<String> getRunAllPhotos({
    required String kennelId,
    required String eventId,
  }) async {
    final userId = currentUserId;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    return ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, String>{
        'queryType': 'getRunAllPhotos',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_getRunAllPhotos',
          paramString: deviceSecret,
        ),
        'kennelId': kennelId,
        'eventId': eventId,
      }),
    );
  }

  Future<String> getKennelPendingPhotos({
    required String kennelId,
    String? eventId,
  }) async {
    final userId = currentUserId;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final body = <String, String>{
      'queryType': 'getKennelPendingPhotos',
      'deviceId': deviceId,
      'kennelId': kennelId,
    };
    if (eventId != null && eventId.isNotEmpty) {
      body['eventId'] = eventId;
    }

    return ServiceCommon.sendHttpPost(() {
      // Minted inside the closure: fresh token per attempt (token retry).
      body['accessToken'] = Utilities.generateToken(
        userId,
        'hcapp_getKennelPendingPhotos',
        paramString: deviceSecret,
      );
      return jsonEncode(body);
    });
  }

  Future<String> getRunPhotos({
    required String eventId,
    String? afterUpdatedAt,
  }) async {
    final userId = currentUserId;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final body = <String, dynamic>{
      'queryType': 'getRunPhotos',
      'deviceId': deviceId,
      'eventId': eventId,
    };

    if (afterUpdatedAt != null) {
      body['afterUpdatedAt'] = afterUpdatedAt;
    }

    return ServiceCommon.sendHttpPost(() {
      // Minted inside the closure: fresh token per attempt (token retry).
      body['accessToken'] = Utilities.generateToken(
        userId,
        'hcapp_getRunPhotos',
        paramString: deviceSecret,
      );
      return jsonEncode(body);
    });
  }

  /// Returns all visible photos for a run merged into a flat list:
  ///   - Own photos (all statuses, isOwnPhoto = true)
  ///   - Others' approved photos (status >= 2)
  /// Sorted oldest-first for gallery display.
  Future<({bool success, List<RunPhotoModel> photos})> getRunPhotosForGallery({
    required String eventId,
  }) async {
    final raw = await getRunPhotos(eventId: eventId);

    if (raw.startsWith(ERROR_PREFIX)) {
      return (success: false, photos: <RunPhotoModel>[]);
    }

    try {
      final List<dynamic> rowsets = jsonDecode(raw) as List<dynamic>;

      final List<RunPhotoModel> ownPhotos = rowsets.isNotEmpty
          ? (rowsets[0] as List<dynamic>)
                .map(
                  (dynamic r) =>
                      RunPhotoModel.fromOwnJson(r as Map<String, dynamic>),
                )
                .toList()
          : <RunPhotoModel>[];

      final List<RunPhotoModel> otherPhotos = rowsets.length > 1
          ? (rowsets[1] as List<dynamic>)
                .map(
                  (dynamic r) =>
                      RunPhotoModel.fromOthersJson(r as Map<String, dynamic>),
                )
                .toList()
          : <RunPhotoModel>[];

      final List<RunPhotoModel> merged =
          <RunPhotoModel>[...ownPhotos, ...otherPhotos]..sort(
            (RunPhotoModel a, RunPhotoModel b) =>
                a.createdAt.compareTo(b.createdAt),
          );

      return (success: true, photos: merged);
    } catch (_) {
      return (success: false, photos: <RunPhotoModel>[]);
    }
  }

  Future<String> updatePhotoStatus({
    required String photoId,
    required int action,
  }) async {
    final userId = currentUserId;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    return ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'updatePhotoStatus',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_updatePhotoStatus',
          paramString: deviceSecret,
        ),
        'photoId': photoId,
        'action': action,
      }),
    );
  }

  /// Updates (or clears) the caption on a photo. Passing null clears any
  /// existing caption. Only callable by Hash Flash, GM, VGM, or RA.
  Future<String> updatePhotoCaption({
    required String photoId,
    String? description,
  }) async {
    final userId = currentUserId;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final body = <String, dynamic>{
      'queryType': 'updatePhotoCaption',
      'deviceId': deviceId,
      'photoId': photoId,
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }

    return ServiceCommon.sendHttpPost(() {
      // Minted inside the closure: fresh token per attempt (token retry).
      body['accessToken'] = Utilities.generateToken(
        userId,
        'hcapp_updatePhotoCaption',
        paramString: deviceSecret,
      );
      return jsonEncode(body);
    }, noRetries: true);
  }

  // ── Pending photo badge ───────────────────────────────────────────────────

  /// Pending photo counts keyed by lowercase eventId. Static so all instances
  /// share one map — the run list reads this reactively to show the badge.
  static final RxMap<String, int> pendingPhotosByEvent = <String, int>{}.obs;
  static final Set<String> _pendingLoadedKennels = {};
  static final Map<String, Set<String>> _kennelEventIds = {};

  /// Loads the count of status=1 photos per event for [kennelId] and merges
  /// into [pendingPhotosByEvent]. Skips the call when already loaded unless
  /// [force] is true. Pass [force: true] after the Hash Flash submits a
  /// review batch so the badge immediately reflects the new counts.
  Future<void> loadPendingPhotoSummary(
    String kennelId, {
    bool force = false,
  }) async {
    if (!force && _pendingLoadedKennels.contains(kennelId)) return;
    _pendingLoadedKennels.add(kennelId);
    try {
      final result = await getKennelPendingPhotos(kennelId: kennelId);
      if (result.startsWith(ERROR_PREFIX)) return;

      // Clear stale counts for events we previously tracked for this kennel.
      final previous = _kennelEventIds[kennelId] ?? {};
      for (final eid in previous) {
        pendingPhotosByEvent.remove(eid);
      }

      final outer = jsonDecode(result) as List<dynamic>;
      if (outer.isEmpty || outer[0] is! List) {
        _kennelEventIds[kennelId] = {};
        return;
      }

      final rows = outer[0] as List<dynamic>;
      final Map<String, int> counts = {};
      for (final row in rows.whereType<Map<String, dynamic>>()) {
        final eventId = row['EventId']?.toString().toLowerCase() ?? '';
        if (eventId.isNotEmpty) {
          counts[eventId] = (counts[eventId] ?? 0) + 1;
        }
      }
      _kennelEventIds[kennelId] = counts.keys.toSet();
      pendingPhotosByEvent.addAll(counts);
    } catch (e, s) {
      _pendingLoadedKennels.remove(kennelId); // allow retry on error
      BootLogger.logError(
        '[KennelPhotoService.loadPendingPhotoSummary] kennelId=$kennelId',
        e,
        s,
      );
    }
  }

  // ── Hash Flash edit helpers ──────────────────────────────────────────────

  /// Downloads [blobUrl] to a temp file so it can be passed to ImageCropper.
  Future<File?> downloadToTempFile(String blobUrl) async {
    try {
      final response = await get(
        Uri.parse(blobUrl),
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        BootLogger.logError(
          '[KennelPhotoService.downloadToTempFile] HTTP ${response.statusCode}',
          blobUrl,
          null,
        );
        return null;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/hc_edit_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(path);
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } catch (e, s) {
      BootLogger.logError(
        '[KennelPhotoService.downloadToTempFile] url=$blobUrl',
        e,
        s,
      );
      return null;
    }
  }

  /// Compresses [croppedFile] and uploads it as a new blob under the same
  /// kennel/run folder. Returns the permanent blob URL, or null on failure.
  Future<String?> uploadEditedPhoto({
    required File croppedFile,
    required String kennelId,
    required String kennelSlug,
    required String runFolder,
  }) async {
    final photoGuid = const Uuid().v4();
    final uploadFile = await _compressForUpload(croppedFile) ?? croppedFile;
    final tokenResult = await _getUploadToken(
      kennelId: kennelId,
      kennelSlug: kennelSlug,
      runFolder: runFolder,
      photoGuid: photoGuid,
    );
    if (tokenResult == null) return null;
    final sasUrl = tokenResult['sasUrl']!;
    final blobUrl = tokenResult['blobUrl']!;
    final uploaded = await _uploadToBlob(sasUrl: sasUrl, imageFile: uploadFile);
    return uploaded ? blobUrl : null;
  }

  /// Saves [editedBlobUrl] to the DB for [photoId]. Same pattern as
  /// [updatePhotoCaption]. Returns the raw response string.
  Future<String> updateRunPhotoEditedBlob({
    required String photoId,
    required String kennelId,
    required String editedBlobUrl,
  }) async {
    final userId = currentUserId;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    return ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': 'updateRunPhotoEditedBlob',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_updateRunPhotoEditedBlob',
          paramString: deviceSecret,
        ),
        'kennelId': kennelId,
        'photoId': photoId,
        'editedBlobUrl': editedBlobUrl,
      }),
      noRetries: true,
    );
  }

  // ── Offline queue ─────────────────────────────────────────────────────────

  /// Copies [imageFile] to a stable path in the app documents directory and
  /// enqueues the metadata in GetStorage for later upload.
  Future<void> _queueForOfflineUpload({
    required File imageFile,
    required String photoGuid,
    required String eventId,
    required String kennelId,
    required String kennelSlug,
    required int eventNumber,
    required int sharingOverride,
    String? caption,
    String? assetId,
    bool isOnlineFailure = false,
  }) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final queuedPath = '${docsDir.path}/hc_pending_$photoGuid.jpg';
      await imageFile.copy(queuedPath);

      final pos = Get.find<LocationService>().lastKnownPosition.value;

      await KennelPhotoUploadQueue.enqueue(
        PendingPhotoUpload(
          photoId: photoGuid,
          eventId: eventId,
          kennelId: kennelId,
          kennelSlug: kennelSlug,
          eventNumber: eventNumber,
          sharingOverride: sharingOverride,
          filePath: queuedPath,
          lat: pos?.latitude ?? 0.0,
          lng: pos?.longitude ?? 0.0,
          savedAtMs: DateTime.now().millisecondsSinceEpoch,
          caption: caption,
          assetId: assetId,
        ),
      );

      Get.snackbar(
        'Photo queued',
        isOnlineFailure
            ? 'Upload failed — photo saved and will retry automatically.'
            : 'No network connection — photo saved and will upload automatically when connected.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } catch (e, s) {
      BootLogger.logError(
        '[KennelPhotoService._queueForOfflineUpload] photoGuid=$photoGuid',
        e,
        s,
      );
      Get.snackbar(
        'Photo could not be saved',
        isOnlineFailure
            ? 'Upload failed and the photo could not be saved for retry.'
            : 'No network and the local queue failed. The photo has been lost.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: hc_red,
        colorText: Colors.white,
      );
    }
  }

  /// Drains any pending offline uploads. Call on app open when connected.
  /// Processes entries in order, stopping at the first network failure so the
  /// remaining entries stay in the queue for the next attempt.
  Future<void> processPendingQueue() async {
    if (!Utilities.isConnected()) return;

    final entries = KennelPhotoUploadQueue.load();
    if (entries.isEmpty) return;

    final total = entries.length;
    final photoWord = total == 1 ? 'photo' : 'photos';

    Get.snackbar(
      'Uploading queued photos',
      'Uploading $total queued $photoWord…',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.shade700,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );

    debugPrint('[KennelPhotoService] Processing $total pending photo(s)...');

    int uploadedCount = 0;
    bool stoppedEarly = false;

    for (final entry in entries) {
      try {
        final file = File(entry.filePath);
        if (!await file.exists()) {
          // Local file was lost (e.g. app data cleared) — discard the entry.
          await KennelPhotoUploadQueue.remove(entry.photoId);
          continue;
        }

        final runFolder = entry.eventNumber > 0
            ? '${entry.kennelSlug}-${entry.eventNumber}'
            : 'other';

        final tokenResult = await _getUploadToken(
          kennelId: entry.kennelId,
          kennelSlug: entry.kennelSlug,
          runFolder: runFolder,
          photoGuid: entry.photoId,
        );
        if (tokenResult == null) {
          debugPrint(
            '[KennelPhotoService] Queue: token failed for ${entry.photoId} — stopping',
          );
          stoppedEarly = true;
          break;
        }

        final sasUrl = tokenResult['sasUrl']!;
        final blobUrl = tokenResult['blobUrl']!;

        final uploadOk = await _uploadToBlob(sasUrl: sasUrl, imageFile: file);
        if (!uploadOk) {
          debugPrint(
            '[KennelPhotoService] Queue: blob upload failed for ${entry.photoId} — stopping',
          );
          stoppedEarly = true;
          break;
        }

        await _addKennelPhoto(
          eventId: entry.eventId,
          kennelId: entry.kennelId,
          photoId: entry.photoId,
          blobUrl: blobUrl,
          assetId: entry.assetId,
          perRunSharingOverride: entry.sharingOverride,
          caption: entry.caption,
          lat: entry.lat,
          lng: entry.lng,
        );

        await KennelPhotoUploadQueue.remove(entry.photoId);
        await file.delete();

        uploadedCount++;
        debugPrint(
          '[KennelPhotoService] Queue: uploaded ${entry.photoId} ($uploadedCount/$total)',
        );
      } catch (e, s) {
        BootLogger.logError(
          '[KennelPhotoService.processPendingQueue] photoId=${entry.photoId}',
          e,
          s,
        );
        // Unexpected error — skip this entry rather than stopping the whole run.
      }
    }

    // No completion snackbar needed if every entry had already lost its local
    // file — nothing was actually attempted.
    if (uploadedCount == 0 && !stoppedEarly) return;

    if (uploadedCount == total) {
      final uploadedWord = total == 1 ? 'photo' : 'photos';
      Get.snackbar(
        'Photos uploaded',
        '$total $uploadedWord uploaded successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } else if (uploadedCount > 0) {
      Get.snackbar(
        'Photos partially uploaded',
        '$uploadedCount of $total $photoWord uploaded — will retry the rest next time.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } else {
      Get.snackbar(
        'Upload failed',
        'Could not upload queued $photoWord — will retry next time.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  // ── Share intent page ────────────────────────────────────────────────────

  Future<_PhotoShareResult?> _showSharePage(File imageFile) async {
    return Get.to<_PhotoShareResult>(
      () => _PhotoSharePage(initialFile: imageFile),
      transition: Transition.downToUp,
      duration: const Duration(milliseconds: 280),
    );
  }
}

// ── Supporting types ─────────────────────────────────────────────────────────

enum _PhotoShareIntent { savePrivate, saveAndShare }

/// Carries the final file (possibly edited), the user's sharing intent, and optional caption.
class _PhotoShareResult {
  const _PhotoShareResult({
    required this.file,
    required this.intent,
    this.caption,
  });
  final File file;
  final _PhotoShareIntent intent;
  final String? caption;
}

// ── Photo review + intent page ───────────────────────────────────────────────

class _PhotoSharePage extends StatefulWidget {
  const _PhotoSharePage({required this.initialFile});
  final File initialFile;

  @override
  State<_PhotoSharePage> createState() => _PhotoSharePageState();
}

class _PhotoSharePageState extends State<_PhotoSharePage> {
  late File _currentFile;
  bool _canEdit = true;
  bool _isCropping = false;
  final TextEditingController _captionController = TextEditingController();
  int _wordCount = 0;

  static int _countWords(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).length;
  }

  // Returns caption trimmed to 200 words, or null if empty.
  String? _captionText() {
    final t = _captionController.text.trim();
    if (t.isEmpty) return null;
    if (_wordCount <= 200) return t;
    return t.split(RegExp(r'\s+')).take(200).join(' ');
  }

  @override
  void initState() {
    super.initState();
    _currentFile = widget.initialFile;
    _captionController.addListener(() {
      final count = _countWords(_captionController.text);
      if (count != _wordCount) setState(() => _wordCount = count);
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _onEdit() async {
    setState(() => _isCropping = true);
    // Crop at full quality — compression for blob upload happens later.
    final cropped = await ImageCropper().cropImage(
      sourcePath: _currentFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      // Aspect-ratio picker sheet renders empty on iOS 26 (TOCropViewController
      // predates Liquid Glass) — hidden until the plugin catches up.
      uiSettings: [IOSUiSettings(aspectRatioPickerButtonHidden: true)],
    );
    if (cropped != null) {
      setState(() {
        _currentFile = File(cropped.path);
        _canEdit = false; // Edit offered once only
      });
    }
    setState(() => _isCropping = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: Backgrounds.defaultHcBackground(),
        child: Stack(
          children: [
            Column(
              children: [
                // Photo fills all available space above the button panel
                Expanded(
                  child: Image.file(
                    _currentFile,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),

                // Fixed button panel — safe-area padded, never overflows
                Container(
                  color: Colors.black.withValues(alpha: 0.75),
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    top: 12,
                    bottom: MediaQuery.of(context).padding.bottom + 12,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _captionController,
                        maxLines: 3,
                        minLines: 1,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add a caption… (optional)',
                          hintStyle: const TextStyle(
                            color: Colors.white38,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$_wordCount / 200 words',
                          style: TextStyle(
                            color: _wordCount > 200
                                ? Colors.redAccent
                                : Colors.white38,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _IntentButton(
                        icon: Icons.delete_outline,
                        label: 'Discard',
                        subtitle: 'Remove the photo',
                        color: hc_red,
                        onTap: () => Get.back<_PhotoShareResult>(),
                      ),
                      if (_canEdit) ...[
                        const SizedBox(height: 8),
                        _IntentButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          subtitle: 'Crop or adjust the photo',
                          color: Colors.blueGrey.shade600,
                          onTap: _onEdit,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _IntentButton(
                        icon: Icons.lock_outline,
                        label: 'Save privately',
                        subtitle: 'Visible only to you',
                        color: Colors.grey.shade700,
                        onTap: () => Get.back(
                          result: _PhotoShareResult(
                            file: _currentFile,
                            intent: _PhotoShareIntent.savePrivate,
                            caption: _captionText(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _IntentButton(
                        icon: Icons.share_outlined,
                        label: 'Save and share',
                        subtitle: 'Forwards to Hash Flash for review',
                        color: Colors.green.shade700,
                        onTap: () => Get.back(
                          result: _PhotoShareResult(
                            file: _currentFile,
                            intent: _PhotoShareIntent.saveAndShare,
                            caption: _captionText(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Cropping overlay — prevents tapping buttons while cropper is active
            if (_isCropping)
              const Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IntentButton extends StatelessWidget {
  const _IntentButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: ts_button.copyWith(fontSize: 15)),
                  Text(
                    subtitle,
                    style: ts_bodySmall.copyWith(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.white60),
          ],
        ),
      ),
    );
  }
}
