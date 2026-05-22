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

    // 1. Pick from camera (simulator uses a bundled placeholder). No crop yet —
    //    editing is optional and offered on the next screen.
    final rawFile = await _pickImage();
    if (rawFile == null) return null; // user cancelled

    // 2. Show review page: Discard / Edit / Save privately / Save and share.
    //    "Edit" opens the cropper in-place and returns to the same page with
    //    the Edit button hidden. Final result carries the chosen file + intent.
    final result = await _showSharePage(rawFile);
    if (result == null) return null;
    final imageFile = result.file;
    final sharingOverride = result.intent == _PhotoShareIntent.saveAndShare ? 1 : 0;

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

    final sasUrl = tokenResult['sasUrl'];
    final blobUrl = tokenResult['blobUrl'];
    if (sasUrl == null || blobUrl == null) {
      Get.snackbar(
        'Upload failed',
        'Upload token was missing required fields. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return null;
    }

    // 5. Upload bytes directly to blob storage via the SAS URL
    final uploaded = await _uploadToBlob(sasUrl: sasUrl, imageFile: imageFile);
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
    _enqueuePhotoMarker(blobUrl: blobUrl);

    return blobUrl;
  }

  // ── Photo capture ────────────────────────────────────────────────────────

  /// Returns the raw captured file without cropping. Editing is optional and
  /// offered on the review page that follows.
  Future<File?> _pickImage() async {
    if (!deviceInfo.isPhysicalDevice) {
      return _simulatorPlaceholder();
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1920,
      maxHeight: 1920,
    );
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

    final userId = currentUserId;
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

  void _enqueuePhotoMarker({required String blobUrl}) {
    final locationService = Get.find<LocationService>();
    // The label IS the full CDN blob URL returned by the API. Using the
    // authoritative URL avoids any storage-account-name assumption in the
    // map renderer and survives future storage migrations.
    unawaited(
      locationService.markPoint(HashRunPointTypes.photo, label: blobUrl),
    );
  }

  // ── Public query methods (called by Hash Flash screen + map) ─────────────

  Future<String> getKennelPendingPhotos({required String kennelId}) async {
    final userId = currentUserId;
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
    final userId = currentUserId;
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

/// Carries the final file (possibly edited) and the user's sharing intent.
class _PhotoShareResult {
  const _PhotoShareResult({required this.file, required this.intent});
  final File file;
  final _PhotoShareIntent intent;
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

  @override
  void initState() {
    super.initState();
    _currentFile = widget.initialFile;
  }

  Future<void> _onEdit() async {
    setState(() => _isCropping = true);
    final cropped = await ImageCropper().cropImage(
      sourcePath: _currentFile.path,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 70,
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
      backgroundColor: Colors.black,
      body: Stack(
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
                color: Colors.black,
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        color: Colors.white70, fontSize: 12),
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
