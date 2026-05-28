import 'package:harrier_central/imports.dart';
import 'package:photo_manager/photo_manager.dart';

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

    // 1. Pick from camera at full quality (no compression at capture time).
    //    Compression for blob upload happens separately in step 5.
    //    Simulator uses a bundled placeholder.
    final rawFile = await _pickImage();
    if (rawFile == null) return null; // user cancelled

    // 2. Show review page: Discard / Edit / Save privately / Save and share.
    //    Edit opens the cropper at full quality; result carries the final file + intent.
    final result = await _showSharePage(rawFile);
    if (result == null) return null;
    final imageFile = result.file; // full-quality, possibly cropped
    final sharingOverride = result.intent == _PhotoShareIntent.saveAndShare ? 1 : 0;
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
      assetId = await _saveToDeviceLibrary(imageFile);
    }

    // 5. Compress the image for blob upload (quality 70, capped at 1920px).
    //    Camera roll already received the full-quality copy in step 4.
    final uploadFile = await _compressForUpload(imageFile) ?? imageFile;

    // 6. Request a short-lived SAS write token from the API
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

    final sasUri = Uri.tryParse(sasUrl as String);
    if (sasUri == null ||
        sasUri.host != 'harriercentral.blob.core.windows.net') {
      Get.snackbar(
        'Upload failed',
        'Invalid upload token. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return null;
    }

    // 7. Upload compressed bytes directly to blob storage via the SAS URL
    final uploaded = await _uploadToBlob(sasUrl: sasUrl, imageFile: uploadFile);
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
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      // Still return blobUrl — photo is in storage even if the DB call failed
      return blobUrl;
    }

    // 9. Enqueue a PHO marker into the GPS track feed
    _enqueuePhotoMarker(photoId: photoGuid);

    return blobUrl;
  }

  // ── Photo capture ────────────────────────────────────────────────────────

  /// Captures at full camera quality — no compression at this stage.
  /// Compression for blob upload happens via [_compressForUpload] later.
  Future<File?> _pickImage() async {
    if (!deviceInfo.isPhysicalDevice) {
      return _simulatorPlaceholder();
    }
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
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
    } catch (e, s) {
      debugPrint('KennelPhotoService: simulator placeholder failed: $e');
      BootLogger.logError('[KennelPhotoService._simulatorPlaceholder]', e, s);
      return null;
    }
  }

  // ── Camera roll save ─────────────────────────────────────────────────────

  /// Saves [imageFile] to the device photo library and returns the asset ID.
  /// Returns null if permission is denied or the save fails.
  Future<String?> _saveToDeviceLibrary(File imageFile) async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) return null;
      final bytes = await imageFile.readAsBytes();
      final entity = await PhotoManager.editor.saveImage(
        bytes,
        filename: 'hc_${DateTime.now().millisecondsSinceEpoch}.jpg',
        desc: '',
      );
      return entity.id;
    } catch (e, s) {
      debugPrint('KennelPhotoService: camera roll save failed: $e');
      BootLogger.logError('[KennelPhotoService._saveToDeviceLibrary] path=${imageFile.path}', e, s);
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
      BootLogger.logError('[KennelPhotoService._compressForUpload] path=${imageFile.path}', e, s);
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
    } catch (e, s) {
      debugPrint('GetPhotoUploadToken exception: $e');
      BootLogger.logError('[KennelPhotoService._getUploadToken] kennelId=$kennelId kennelSlug=$kennelSlug runFolder=$runFolder', e, s);
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

    if (assetId != null && assetId.isNotEmpty) {
      body['assetId'] = assetId;
    }
    if (perRunSharingOverride != null) {
      body['perRunSharingOverride'] = perRunSharingOverride;
    }
    if (caption != null && caption.isNotEmpty) {
      body['description'] = caption;
    }

    final result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(body),
    );

    return !result.startsWith(ERROR_PREFIX);
  }

  // ── GPS track marker ─────────────────────────────────────────────────────

  void _enqueuePhotoMarker({required String photoId}) {
    final locationService = Get.find<LocationService>();
    // Label is the photoId (UUID) only — the map controller resolves the
    // blob URL via hcapp_getRunPhotos so the URL is never stored in the
    // GPS track, preventing unauthenticated blob access from the label alone.
    unawaited(
      locationService.markPoint(HashRunPointTypes.photo, label: photoId),
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
      'accessToken': Utilities.generateToken(
        userId,
        'hcapp_getKennelPendingPhotos',
        paramString: deviceSecret,
      ),
      'kennelId': kennelId,
    };
    if (eventId != null && eventId.isNotEmpty) {
      body['eventId'] = eventId;
    }

    return ServiceCommon.sendHttpPost(() => jsonEncode(body));
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

/// Carries the final file (possibly edited), the user's sharing intent, and optional caption.
class _PhotoShareResult {
  const _PhotoShareResult({required this.file, required this.intent, this.caption});
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
                    TextField(
                      controller: _captionController,
                      maxLines: 3,
                      minLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Add a caption… (optional)',
                        hintStyle: const TextStyle(
                            color: Colors.white38, fontSize: 14),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
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
