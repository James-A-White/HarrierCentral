import 'package:harrier_central/imports.dart';
import 'package:photo_manager/photo_manager.dart';

/// Saves a Harrier Central photo to the phone's camera roll (James,
/// 2026-09-27: "a download button anywhere there's an individual photo").
///
/// Reads the image through the shared image cache, so a photo already on
/// screen is not downloaded again. Location and capture time are written into
/// the saved asset when known, so it lands in the right place in the camera
/// roll rather than at "today".
///
/// Permission: iOS asks for photo-library access (add-only is enough). Android
/// asks for nothing — the app writes only its own images, which scoped
/// storage allows without a permission, and main.dart tells photo_manager to
/// skip its check (Play rejected a build that asked for broad media access).
class PhotoDownload {
  PhotoDownload._();

  static bool _busy = false;

  static Future<void> saveToCameraRoll(
    String url, {
    double? latitude,
    double? longitude,
    DateTime? takenAt,
  }) async {
    if (_busy || url.trim().isEmpty) return;
    _busy = true;
    try {
      if (Platform.isIOS) {
        final PermissionState permission =
            await PhotoManager.requestPermissionExtend(
              requestOption: const PermissionRequestOption(
                iosAccessLevel: IosAccessLevel.addOnly,
              ),
            );
        if (!permission.hasAccess) {
          showHcSnackbar(
            'Harrier Central needs permission to add photos. You can allow it '
            'in Settings.',
            isError: true,
          );
          return;
        }
      }

      final File file = await DefaultCacheManager().getSingleFile(url);
      final bytes = await file.readAsBytes();
      final bool hasCoords =
          latitude != null &&
          longitude != null &&
          !(latitude == 0.0 && longitude == 0.0);
      await PhotoManager.editor.saveImage(
        bytes,
        filename: 'harrier_central_${DateTime.now().millisecondsSinceEpoch}.jpg',
        desc: '',
        latitude: hasCoords ? latitude : null,
        longitude: hasCoords ? longitude : null,
        creationDate: takenAt?.toLocal() ?? DateTime.now(),
      );
      showHcSnackbar('Saved to your photos.');
    } catch (e, s) {
      BootLogger.logError('[PhotoDownload.saveToCameraRoll] url=$url', e, s);
      showHcSnackbar(
        "Couldn't save that photo — please try again.",
        isError: true,
      );
    } finally {
      _busy = false;
    }
  }
}
