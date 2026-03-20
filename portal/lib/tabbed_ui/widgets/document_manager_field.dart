import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:hcportal/imports.dart';
import 'package:hcportal/tabbed_ui/widgets/sidebar_hover_region.dart';
import 'package:image/image.dart' as image;

/// Document/image upload manager that shows current value, preview, remove, and upload actions.
/// Caller supplies controller, control metadata, upload state, and callbacks for remove/complete.
class DocumentManagerField extends StatelessWidget {
  const DocumentManagerField({
    super.key,
    required this.controller,
    required this.uiControl,
    required this.fieldName,
    required this.recordId,
    required this.uploading,
    required this.onUploadComplete,
    required this.onRemoveDocument,
    this.onAfterRemove,
    this.defaultImageAsset,
    this.placeholderText,
    this.filenamePrefix,
    this.height,
    this.width,
    this.expandToFit = false,
    this.allowedExtensions,
    this.uploadStatus,
  });

  final TabUiController controller;
  final UiControlDefinition uiControl;
  final String fieldName;
  final String recordId;
  final RxBool uploading;
  final ValueChanged<String> onUploadComplete;
  final VoidCallback onRemoveDocument;
  final VoidCallback? onAfterRemove;
  final String? defaultImageAsset;
  final String? placeholderText;
  final String? filenamePrefix;
  final double? height;
  final double? width;
  final bool expandToFit;
  final List<String>? allowedExtensions;

  /// Optional reactive string to track upload status ('selecting', 'uploading', or empty)
  final RxString? uploadStatus;

  static const int _maxUploadBytes = 3145728; // 3 MB

  @override
  Widget build(BuildContext context) {
    final bool isImageUpload =
        uiControl.controlType == UiControlType.imageUpload;
    final String documentTypeName = uiControl.fileType.fullName;

    final List<String> defaultExtensions = isImageUpload
        ? [
            'png',
            'tga',
            'gif',
            'bmp',
            'ico',
            'webp',
            'psd',
            'pvr',
            'tif',
            'tiff',
            'jpg',
            'jpeg',
          ]
        : ['pdf'];

    return SidebarHoverRegion(
      controller: controller,
      uiControl: uiControl,
      child: Obx(() {
        // Check upload status for detailed state (if provided)
        final status = uploadStatus?.value ?? '';

        if (status == 'selecting') {
          return SizedBox(
            height: height ?? 200,
            width: width ?? 200,
            child: Center(
              child: Text(
                'Selecting $documentTypeName...',
                style: const TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (status == 'processing') {
          return SizedBox(
            height: height ?? 200,
            width: width ?? 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Processing $documentTypeName...',
                    style: const TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        if (status == 'uploading' || (uploading.value && status.isEmpty)) {
          return SizedBox(
            height: height ?? 200,
            width: width ?? 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Uploading $documentTypeName...',
                    style: const TextStyle(fontSize: 24),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        // Check if there's a valid image value (not null and not the '<null>' sentinel)
        final hasValidImage = uiControl.editedFieldValue != null &&
            uiControl.editedFieldValue != '<null>';

        if (hasValidImage) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (isImageUpload)
                SizedBox(
                  height: height ?? 200,
                  width: width ?? 200,
                  child: HcNetworkImage(
                    uiControl.editedFieldValue!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                    ),
                  ),
                )
              else
                Image.asset(
                  uiControl.fileType.documentPresentAsset,
                  width: width ?? 90,
                  height: height ?? 110,
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: defaultButtonStyle,
                onPressed: () {
                  uploading.value = true;
                  onRemoveDocument();
                  onAfterRemove?.call();
                  uploading.value = false;
                },
                child: Text(
                  'Remove $documentTypeName',
                  style: buttonLabelStyleMedium,
                ),
              ),
            ],
          );
        }

        return Column(
          children: <Widget>[
            if (placeholderText != null)
              GestureDetector(
                onTap: () => _triggerUpload(
                  controller: controller,
                  uiControl: uiControl,
                  recordId: recordId,
                  allowedExtensions: allowedExtensions ?? defaultExtensions,
                  uploading: uploading,
                  onUploadComplete: onUploadComplete,
                  filenamePrefix: filenamePrefix,
                  uploadStatus: uploadStatus,
                ),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: width ?? 200,
                    height: height ?? 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade400,
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 64,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              placeholderText!,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Image.asset(
                defaultImageAsset ?? uiControl.fileType.documentNotPresentAsset,
                width: width ?? 90,
                height: height ?? 110,
              ),
            const SizedBox(height: 20),
            _UploadButton(
              controller: controller,
              uiControl: uiControl,
              fieldName: fieldName,
              recordId: recordId,
              allowedExtensions: allowedExtensions ?? defaultExtensions,
              uploading: uploading,
              onUploadComplete: onUploadComplete,
              filenamePrefix: filenamePrefix,
              uploadStatus: uploadStatus,
            ),
          ],
        );
      }),
    );
  }
}

/// Triggers the file upload process.
/// This is extracted so it can be called from both the placeholder box and the upload button.
Future<void> _triggerUpload({
  required TabUiController controller,
  required UiControlDefinition uiControl,
  required String recordId,
  required List<String> allowedExtensions,
  required RxBool uploading,
  required ValueChanged<String> onUploadComplete,
  String? filenamePrefix,
  RxString? uploadStatus,
}) async {
  // Set to 'selecting' state while file picker is open
  uploadStatus?.value = 'selecting';
  uploading.value = true;

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
  );

  if (result == null) {
    uploadStatus?.value = '';
    uploading.value = false;
    return;
  }

  // Change to 'processing' state once file is selected
  // Allow UI to rebuild before starting synchronous image processing
  uploadStatus?.value = 'processing';
  await Future.delayed(const Duration(milliseconds: 50));

  if (result.files.first.bytes == null) {
    await Utilities.showAlert(
      'File error',
      'There was an unknown error with the file upload. Please try uploading another file.',
      'OK',
    );
    uploadStatus?.value = '';
    uploading.value = false;
    return;
  }

  final fileSize =
      result.files.first.bytes?.length ?? DocumentManagerField._maxUploadBytes;
  if (fileSize >= DocumentManagerField._maxUploadBytes) {
    await Utilities.showAlert(
      'File too large',
      'Please select a file that is smaller than 3Mb',
      'OK',
    );
    result.files.clear();
    uploadStatus?.value = '';
    uploading.value = false;
    return;
  }

  List<int> fileBytes = List<int>.from(result.files.first.bytes!);
  final fileExtension = (result.files.first.extension ?? '').toLowerCase();

  var doProcess = true;
  if (uiControl.controlType == UiControlType.imageUpload &&
      fileExtension != 'jpg' &&
      fileExtension != 'jpeg') {
    if (['png', 'tga', 'gif', 'bmp', 'ico', 'webp', 'psd', 'pvr', 'tif', 'tiff']
        .contains(fileExtension)) {
      try {
        final img = image.decodeImage(Uint8List.fromList(fileBytes));
        if (img != null) {
          fileBytes = image.encodeJpg(img);
        }
      } catch (_) {
        doProcess = false;
        await Utilities.showAlert(
          'Error processing image',
          'Harrier Central is unable to upload "$fileExtension" files. Please select a JPG, PNG, TIFF, BMP or PSD file',
          'OK',
        );
      }
    } else {
      doProcess = false;
      await Utilities.showAlert(
        'Error processing image',
        'Harrier Central is unable to upload "$fileExtension" files. Please select a JPG, PNG, TIFF, BMP or PSD file',
        'OK',
      );
    }
  }

  if (doProcess && fileBytes.isNotEmpty) {
    // Change to 'uploading' state for actual network upload
    uploadStatus?.value = 'uploading';

    final fileName = await ServiceCommon.uploadFile(
      fileBytes,
      recordId,
      uiControl.fileType.name,
      uiControl.controlType,
      filenamePrefix: filenamePrefix,
    );
    if (fileName.isNotEmpty) {
      onUploadComplete(fileName);
    }
  }

  uploadStatus?.value = '';
  uploading.value = false;
  controller.checkIfFormIsDirty();
}

class _UploadButton extends StatelessWidget {
  const _UploadButton({
    required this.controller,
    required this.uiControl,
    required this.fieldName,
    required this.recordId,
    required this.allowedExtensions,
    required this.uploading,
    required this.onUploadComplete,
    this.filenamePrefix,
    this.uploadStatus,
  });

  final TabUiController controller;
  final UiControlDefinition uiControl;
  final String fieldName;
  final String recordId;
  final List<String> allowedExtensions;
  final RxBool uploading;
  final ValueChanged<String> onUploadComplete;
  final String? filenamePrefix;
  final RxString? uploadStatus;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: defaultButtonStyle,
      onPressed: () => _triggerUpload(
        controller: controller,
        uiControl: uiControl,
        recordId: recordId,
        allowedExtensions: allowedExtensions,
        uploading: uploading,
        onUploadComplete: onUploadComplete,
        filenamePrefix: filenamePrefix,
        uploadStatus: uploadStatus,
      ),
      child: Text(
        'Upload ${uiControl.fileType.fullName}',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}
