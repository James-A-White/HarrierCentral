import 'package:harrier_central/imports.dart';

class KennelPhotoService {
  /// Orchestrates the full capture → upload → record flow.
  ///
  /// Returns the permanent blob URL on success, or null if the user
  /// cancelled or any step failed (error shown via snackbar).
  Future<String?> captureAndUpload({
    required String eventId,
    required String kennelId,
    int? perRunSharingOverride,
  }) async {
    // 1. Pick and crop from camera
    final imageFile = await _pickAndCrop();
    if (imageFile == null) return null; // user cancelled

    // 2. Client-side GUID — normalised to lowercase per project UUID rules
    final photoGuid = const Uuid().v4().toLowerCase();

    // 3. Request a short-lived SAS write token from the API
    final tokenResult = await _getUploadToken(
      kennelId: kennelId,
      photoGuid: photoGuid,
    );
    if (tokenResult == null) {
      Get.snackbar(
        'Upload failed',
        'Could not get an upload token. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return null;
    }

    // 4. Upload bytes directly to blob storage via the SAS URL
    final uploaded = await _uploadToBlob(
      sasUrl: tokenResult['sasUrl']!,
      imageFile: imageFile,
    );
    if (!uploaded) {
      Get.snackbar(
        'Upload failed',
        'The photo could not be uploaded. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return null;
    }

    final blobUrl = tokenResult['blobUrl']!;

    // 5. Record the photo in the database
    final recorded = await _addKennelPhoto(
      eventId: eventId,
      kennelId: kennelId,
      photoId: photoGuid,
      blobUrl: blobUrl,
      perRunSharingOverride: perRunSharingOverride,
    );
    if (!recorded) {
      Get.snackbar(
        'Photo saved locally',
        'The photo was uploaded but could not be recorded. '
            'It may not appear on the map.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      // Still return blobUrl — photo is in storage even if the DB call failed
      return blobUrl;
    }

    // 6. Enqueue a PHO marker into the GPS track feed
    _enqueuePhotoMarker(photoGuid: photoGuid);

    return blobUrl;
  }

  // ── Photo capture ────────────────────────────────────────────────────────

  Future<File?> _pickAndCrop() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 70,
    );
    if (cropped == null) return null;

    return File(cropped.path);
  }

  // ── SAS token request ────────────────────────────────────────────────────

  Future<Map<String, String>?> _getUploadToken({
    required String kennelId,
    required String photoGuid,
  }) async {
    final userId = getStringPref(StringPrefsEnum.userId)!;
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
          'photoGuid': photoGuid,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'sasUrl': data['sasUrl'] as String,
          'blobUrl': data['blobUrl'] as String,
        };
      }
    } catch (_) {}
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
      final response = await request
          .send()
          .timeout(const Duration(seconds: 60));
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  // ── Database record ──────────────────────────────────────────────────────

  Future<bool> _addKennelPhoto({
    required String eventId,
    required String kennelId,
    required String photoId,
    required String blobUrl,
    int? perRunSharingOverride,
  }) async {
    final locationService = Get.find<LocationService>();
    final pos = locationService.lastKnownPosition.value;

    final userId = getStringPref(StringPrefsEnum.userId)!;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final body = <String, dynamic>{
      'queryType': 'addKennelPhoto',
      'deviceId': deviceId,
      'accessToken': Utilities.generateToken(
        userId,
        'hcapp_addKennelPhoto',
        paramString: deviceSecret,
      ),
      'photoId': photoId,
      'eventId': eventId,
      'kennelId': kennelId,
      'blobUrl': blobUrl,
      'latitude': pos?.latitude ?? 0.0,
      'longitude': pos?.longitude ?? 0.0,
    };

    if (perRunSharingOverride != null) {
      body['perRunSharingOverride'] = perRunSharingOverride;
    }

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(body),
    );

    return !result.startsWith(ERROR_PREFIX);
  }

  // ── GPS track marker ─────────────────────────────────────────────────────

  void _enqueuePhotoMarker({required String photoGuid}) {
    final locationService = Get.find<LocationService>();
    final userId = getStringPref(StringPrefsEnum.userId) ?? '';
    unawaited(
      locationService.markPoint(
        HashRunPointTypes.photo,
        label: '$userId+$photoGuid',
      ),
    );
  }

  // ── Public query methods (called by Hash Flash screen + map) ─────────────

  Future<String> getKennelPendingPhotos({required String kennelId}) async {
    final userId = getStringPref(StringPrefsEnum.userId)!;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    return ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, String>{
        'queryType': 'getKennelPendingPhotos',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_getKennelPendingPhotos',
          paramString: deviceSecret,
        ),
        'kennelId': kennelId,
      }),
    );
  }

  Future<String> getRunPhotos({
    required String eventId,
    String? afterUpdatedAt,
  }) async {
    final userId = getStringPref(StringPrefsEnum.userId)!;
    final deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final deviceSecret = getStringPref(StringPrefsEnum.deviceSecret) ?? '';

    final body = <String, dynamic>{
      'queryType': 'getRunPhotos',
      'deviceId': deviceId,
      'accessToken': Utilities.generateToken(
        userId,
        'hcapp_getRunPhotos',
        paramString: deviceSecret,
      ),
      'eventId': eventId,
    };

    if (afterUpdatedAt != null) {
      body['afterUpdatedAt'] = afterUpdatedAt;
    }

    return ServiceCommon.sendHttpPost(() => jsonEncode(body));
  }

  Future<String> updatePhotoStatus({
    required String photoId,
    required int action,
  }) async {
    final userId = getStringPref(StringPrefsEnum.userId)!;
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
}
