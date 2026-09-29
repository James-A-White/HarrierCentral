import 'package:harrier_central/imports.dart';

/// Uploads one chat photo to the chat-photos container (E9.F1.S11,
/// 2026-09-29) and hands back its blob URL, which the caller then sends as a
/// kind 1 message.
///
/// Two steps, mirroring the run-photo upload in [KennelPhotoService]:
///  1. `GetChatPhotoUploadToken` — authenticated by a standard token for
///     `hcapp_getChatPhotoUploadToken` — returns a 15-minute, write-only SAS
///     for `chat-photos/<yyyy>/<MM>/<userId>-<photoGuid>.jpg`. The user id in
///     that path comes from the token on the server, never from here.
///  2. PUT the JPEG to the SAS URL as a block blob.
///
/// One-shot `post` / `Request` only: a persistent http Client goes bad across
/// an iOS suspend (memory: http-one-shot-clients).
class ChatPhotoService {
  ChatPhotoService._();

  /// Longest edge of a chat photo, and its JPEG quality. A phone camera's
  /// 12 MP original is 3-5 MB; this is a few hundred KB and still sharp on
  /// any phone screen.
  static const int maxEdge = 1600;
  static const int jpegQuality = 75;

  /// Re-encode [original] as a JPEG no larger than [maxEdge] on its longest
  /// side. Null when the phone could not decode it (the caller says so).
  ///
  /// flutter_image_compress's minWidth/minHeight scale DOWN only and keep the
  /// aspect ratio, and the picker has already capped the edge at [maxEdge],
  /// so this is the JPEG conversion (a HEIC or PNG from the library becomes a
  /// .jpg the server accepts) plus a guard against a picker that ignored the
  /// cap.
  ///
  /// NO METADATA LEAVES THE PHONE. A camera photo's EXIF carries where it
  /// was taken (GPS) and on what device; posted into a group chat that is a
  /// hasher's home address for anyone who saves the file. The plugin decodes
  /// to a bitmap and re-encodes, and copies the source's EXIF / GPS / IPTC
  /// into the result ONLY when keepExif is true (iOS: CompressHandler's
  /// dataByCopyingMetadataFromSource; Android: its ExifInterface copy) — so
  /// keepExif: false is what strips it, stated here rather than left to a
  /// default. autoCorrectionAngle applies the EXIF orientation to the
  /// pixels first, so dropping the tag does not turn a portrait sideways.
  /// The web does the same on its side (E9.F1.S11 review, 2026-09-29).
  static Future<Uint8List?> prepareJpeg(XFile original) async {
    try {
      return await FlutterImageCompress.compressWithFile(
        original.path,
        minWidth: maxEdge,
        minHeight: maxEdge,
        quality: jpegQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
        autoCorrectionAngle: true,
      );
    } catch (e, s) {
      BootLogger.logError('[ChatPhotoService.prepareJpeg]', e, s);
      return null;
    }
  }

  /// Upload [jpeg]; returns the public blob URL, or null on any failure
  /// (already logged).
  static Future<String?> upload(Uint8List jpeg) async {
    final String photoGuid = const Uuid().v4();
    final _Sas? sas = await _getUploadToken(photoGuid);
    if (sas == null) return null;
    final bool ok = await _put(sas.sasUrl, jpeg);
    return ok ? sas.blobUrl : null;
  }

  static Future<_Sas?> _getUploadToken(String photoGuid) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    try {
      final Response response = await post(
        Uri.parse(CHAT_PHOTO_UPLOAD_TOKEN_URL),
        headers: <String, String>{'content-type': 'application/json'},
        body: jsonEncode(<String, String>{
          'deviceId': deviceId,
          'accessToken': Utilities.generateToken(
            userId,
            'hcapp_getChatPhotoUploadToken',
            paramString: deviceSecret,
          ),
          'photoGuid': photoGuid,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final String? sasUrl = data['sasUrl'] as String?;
        final String? blobUrl = data['blobUrl'] as String?;
        if (sasUrl == null || blobUrl == null) return null;
        return _Sas(sasUrl, blobUrl);
      }
      BootLogger.logError(
        '[ChatPhotoService._getUploadToken] HTTP ${response.statusCode}',
        response.body,
        null,
      );
    } catch (e, s) {
      BootLogger.logError('[ChatPhotoService._getUploadToken]', e, s);
    }
    return null;
  }

  static Future<bool> _put(String sasUrl, Uint8List jpeg) async {
    try {
      final Request request = Request('PUT', Uri.parse(sasUrl));
      request.headers['content-type'] = 'image/jpeg';
      request.headers['x-ms-blob-type'] = 'BlockBlob';
      request.bodyBytes = jpeg;
      final StreamedResponse response = await request.send().timeout(
        const Duration(seconds: 60),
      );
      if (response.statusCode == 201) return true;
      BootLogger.logError(
        '[ChatPhotoService._put]',
        'HTTP ${response.statusCode}',
        null,
      );
    } catch (e, s) {
      BootLogger.logError('[ChatPhotoService._put]', e, s);
    }
    return false;
  }
}

class _Sas {
  const _Sas(this.sasUrl, this.blobUrl);
  final String sasUrl;
  final String blobUrl;
}
