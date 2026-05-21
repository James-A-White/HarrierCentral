import 'package:harrier_central/imports.dart';

// Photo review action codes — match hcapp_updatePhotoStatus @action parameter.
// Actions 3–6 are cumulative: each level implies all lower approval levels.
const int photoActionDelete          = 1; // hard-delete (inappropriate content)
const int photoActionKeepPrivate     = 2; // back to uploader-only (status 0)
const int photoActionShare           = 3; // visible to all HC users on run maps (status 2)
const int photoActionAddToGallery    = 4; // + appears in run photo gallery (status 3)
const int photoActionAddToHomeGallery = 5; // + appears on kennel home page (status 4)
const int photoActionMakeEventCover  = 6; // + set as run cover photo (status 5)

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
  }) async {
    // Run folder: "<kennelSlug>-<runNumber>" when there is a run number,
    // otherwise "other". Nested under the kennel slug in blob storage.
    final runFolder = eventNumber > 0 ? '$kennelSlug-$eventNumber' : 'other';

    // 1. Pick and crop from camera (or simulator placeholder)
    final imageFile = await _pickAndCrop();
    if (imageFile == null) return null; // user cancelled or cropper dismissed

    // 2. Ask the user what to do with the cropped photo.
    //    Dismiss / Discard → abort. Save privately → 0. Save & Share → 1.
    final intent = await _showShareSheet(imageFile);
    if (intent == null || intent == _PhotoShareIntent.discard) return null;
    final sharingOverride = intent == _PhotoShareIntent.saveAndShare ? 1 : 0;

    // 3. Client-side GUID — normalised to lowercase per project UUID rules
    final photoGuid = const Uuid().v4().toLowerCase();

    // 4. Request a short-lived SAS write token from the API
    final tokenResult = await _getUploadToken(
      kennelId: kennelId,
      kennelSlug: kennelSlug,
      runFolder: runFolder,
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

    // 5. Upload bytes directly to blob storage via the SAS URL
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

    // 6. Record the photo in the database
    final recorded = await _addKennelPhoto(
      eventId: eventId,
      kennelId: kennelId,
      photoId: photoGuid,
      blobUrl: blobUrl,
      perRunSharingOverride: sharingOverride,
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

    // 7. Enqueue a PHO marker into the GPS track feed
    _enqueuePhotoMarker(runFolder: runFolder, photoGuid: photoGuid);

    return blobUrl;
  }

  // ── Photo capture ────────────────────────────────────────────────────────

  Future<File?> _pickAndCrop() async {
    // Resolve source: camera on a real device, bundled placeholder on simulator.
    final File? source;
    if (!deviceInfo.isPhysicalDevice) {
      source = await _simulatorPlaceholder();
    } else {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      source = picked == null ? null : File(picked.path);
    }
    if (source == null) return null;

    // Both paths go through the image editor.
    final cropped = await ImageCropper().cropImage(
      sourcePath: source.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 70,
    );
    if (cropped == null) return null;

    return File(cropped.path);
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
    } catch (e) {
      debugPrint('KennelPhotoService: simulator placeholder failed: $e');
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
          'kennelSlug': kennelSlug,
          'runFolder': runFolder,
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
      debugPrint(
        'GetPhotoUploadToken failed: HTTP ${response.statusCode} — ${response.body}',
      );
    } catch (e) {
      debugPrint('GetPhotoUploadToken exception: $e');
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

  void _enqueuePhotoMarker({
    required String runFolder,
    required String photoGuid,
  }) {
    final locationService = Get.find<LocationService>();
    final userId = getStringPref(StringPrefsEnum.userId) ?? '';
    // Label encodes the run folder and the full blob filename so the map
    // renderer can locate the photo without a cache lookup.
    // Format: "<runFolder>/<userId>-<photoGuid>.jpg"
    // e.g.  "shhh-456/a3f1c9...-9d2e3b....jpg"
    unawaited(
      locationService.markPoint(
        HashRunPointTypes.photo,
        label: '$runFolder/$userId-$photoGuid.jpg',
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

  // ── Share intent sheet ───────────────────────────────────────────────────

  Future<_PhotoShareIntent?> _showShareSheet(File imageFile) {
    return Get.bottomSheet<_PhotoShareIntent>(
      _ShareSheet(imageFile: imageFile),
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
    );
  }
}

// ── Share intent enum ────────────────────────────────────────────────────────

enum _PhotoShareIntent { discard, savePrivate, saveAndShare }

// ── Bottom sheet widget ───────────────────────────────────────────────────────

class _ShareSheet extends StatelessWidget {
  const _ShareSheet({required this.imageFile});

  final File imageFile;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 6),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Photo preview
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: Image.file(
                imageFile,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                'What would you like to do with this photo?',
                style: ts_bodySmall.copyWith(
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Discard
            _SheetButton(
              icon: Icons.delete_outline,
              label: 'Discard',
              subtitle: 'Remove the photo',
              color: hc_red,
              onTap: () => Get.back(result: _PhotoShareIntent.discard),
            ),

            // Save privately
            _SheetButton(
              icon: Icons.lock_outline,
              label: 'Save privately',
              subtitle: 'Visible only to you',
              color: Colors.grey.shade600,
              onTap: () => Get.back(result: _PhotoShareIntent.savePrivate),
            ),

            // Save & share
            _SheetButton(
              icon: Icons.share_outlined,
              label: 'Save and share',
              subtitle: 'Forwards to Hash Flash for review',
              color: Colors.green.shade700,
              onTap: () => Get.back(result: _PhotoShareIntent.saveAndShare),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onTap,
          child: Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: ts_button.copyWith(fontSize: 15)),
                    Text(subtitle,
                        style: ts_bodySmall.copyWith(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 20, color: Colors.white60),
            ],
          ),
        ),
      ),
    );
  }
}
