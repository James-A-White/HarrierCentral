import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:web/web.dart' as web;
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
    this.imageValidator,
    this.preserveFormat = false,
    this.imageOverlay,
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

  /// Optional callback to validate image dimensions after decode.
  /// Receives (width, height) in pixels; return an error string to abort, or null to proceed.
  final String? Function(int width, int height)? imageValidator;

  /// When true, the original file bytes are uploaded as-is (preserving format and
  /// transparency) instead of being re-encoded as JPEG.
  final bool preserveFormat;

  /// Optional widget rendered on top of the displayed image (e.g. a short-name text overlay).
  final Widget? imageOverlay;

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

        // bundle:// assets are routed to the droppable placeholder (image display +
        // upload button + drag-drop) rather than the "has valid image" path.
        final bool isBundleAsset = isImageUpload &&
            (uiControl.editedFieldValue?.startsWith('bundle://') ?? false);

        // Check if there's a valid image value (not null and not the '<null>' sentinel)
        final hasValidImage = uiControl.editedFieldValue != null &&
            uiControl.editedFieldValue != '<null>' &&
            !isBundleAsset;

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
            if (placeholderText != null || isBundleAsset)
              _DroppablePlaceholder(
                width: width ?? 200,
                height: height ?? 200,
                placeholderText: placeholderText ?? '',
                allowedExtensions: allowedExtensions ?? defaultExtensions,
                controller: controller,
                uiControl: uiControl,
                recordId: recordId,
                uploading: uploading,
                onUploadComplete: onUploadComplete,
                filenamePrefix: filenamePrefix,
                uploadStatus: uploadStatus,
                imageValidator: imageValidator,
                preserveFormat: preserveFormat,
                bundleUrl: isBundleAsset ? uiControl.editedFieldValue : null,
                imageOverlay: imageOverlay,
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
              imageValidator: imageValidator,
              preserveFormat: preserveFormat,
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
  String? Function(int width, int height)? imageValidator,
  bool preserveFormat = false,
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

  await _processFileBytes(
    fileBytes: List<int>.from(result.files.first.bytes!),
    fileExtension: (result.files.first.extension ?? '').toLowerCase(),
    fileSize: result.files.first.bytes?.length ?? DocumentManagerField._maxUploadBytes,
    controller: controller,
    uiControl: uiControl,
    recordId: recordId,
    uploading: uploading,
    onUploadComplete: onUploadComplete,
    filenamePrefix: filenamePrefix,
    uploadStatus: uploadStatus,
    imageValidator: imageValidator,
    preserveFormat: preserveFormat,
  );
}

/// Validates and uploads file bytes. Shared by file-picker and drag-and-drop paths.
/// Caller sets uploadStatus to 'processing' before calling.
Future<void> _processFileBytes({
  required List<int> fileBytes,
  required String fileExtension,
  required int fileSize,
  required TabUiController controller,
  required UiControlDefinition uiControl,
  required String recordId,
  required RxBool uploading,
  required ValueChanged<String> onUploadComplete,
  String? filenamePrefix,
  RxString? uploadStatus,
  String? Function(int width, int height)? imageValidator,
  bool preserveFormat = false,
}) async {
  if (fileSize >= DocumentManagerField._maxUploadBytes) {
    await Utilities.showAlert(
      'File too large',
      'Please select a file that is smaller than 3Mb',
      'OK',
    );
    uploadStatus?.value = '';
    uploading.value = false;
    return;
  }

  var processedBytes = fileBytes;
  var doProcess = true;

  if (uiControl.controlType == UiControlType.imageUpload &&
      fileExtension != 'jpg' &&
      fileExtension != 'jpeg') {
    if (['png', 'tga', 'gif', 'bmp', 'ico', 'webp', 'psd', 'pvr', 'tif', 'tiff', 'avif']
        .contains(fileExtension)) {
      try {
        final img = image.decodeImage(Uint8List.fromList(processedBytes));
        if (img != null) {
          if (imageValidator != null) {
            final error = imageValidator(img.width, img.height);
            if (error != null) {
              doProcess = false;
              await Utilities.showAlert('Invalid image', error, 'OK');
            }
          }
          if (doProcess && !preserveFormat) {
            processedBytes = image.encodeJpg(img);
          }
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

  if (doProcess && processedBytes.isNotEmpty) {
    uploadStatus?.value = 'uploading';
    final fileName = await ServiceCommon.uploadFile(
      processedBytes,
      recordId,
      uiControl.fileType.name,
      uiControl.controlType,
      filenamePrefix: filenamePrefix,
      filenameExtension: preserveFormat ? fileExtension : null,
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
    this.imageValidator,
    this.preserveFormat = false,
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
  final String? Function(int width, int height)? imageValidator;
  final bool preserveFormat;

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
        imageValidator: imageValidator,
        preserveFormat: preserveFormat,
      ),
      child: Text(
        'Upload ${uiControl.fileType.fullName}',
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}

/// Placeholder drop-target that accepts both taps (file picker) and OS file drops.
class _DroppablePlaceholder extends StatefulWidget {
  const _DroppablePlaceholder({
    required this.width,
    required this.height,
    required this.placeholderText,
    required this.allowedExtensions,
    required this.controller,
    required this.uiControl,
    required this.recordId,
    required this.uploading,
    required this.onUploadComplete,
    this.filenamePrefix,
    this.uploadStatus,
    this.imageValidator,
    this.preserveFormat = false,
    this.bundleUrl,
    this.imageOverlay,
  });

  final double width;
  final double height;
  final String placeholderText;
  final List<String> allowedExtensions;
  final TabUiController controller;
  final UiControlDefinition uiControl;
  final String recordId;
  final RxBool uploading;
  final ValueChanged<String> onUploadComplete;
  final String? filenamePrefix;
  final RxString? uploadStatus;
  final String? Function(int width, int height)? imageValidator;
  final bool preserveFormat;

  /// When set, the placeholder renders the bundle asset image with an optional
  /// overlay instead of the grey upload box. Drag-and-drop and tap-to-upload
  /// still work — this is the display surface when no custom logo exists yet.
  final String? bundleUrl;

  /// Optional widget rendered over the bundle image (e.g. short-name text).
  final Widget? imageOverlay;

  @override
  State<_DroppablePlaceholder> createState() => _DroppablePlaceholderState();
}

class _DroppablePlaceholderState extends State<_DroppablePlaceholder> {
  final _containerKey = GlobalKey();
  bool _isDraggingOver = false;
  late final JSFunction _dragOverJs;
  late final JSFunction _dropJs;
  late final JSFunction _dragLeaveJs;

  @override
  void initState() {
    super.initState();
    _dragOverJs = ((web.Event event) {
      event.preventDefault();
      final e = event as web.DragEvent;
      final over = _isWithinBounds(e.clientX, e.clientY);
      if (over != _isDraggingOver) setState(() => _isDraggingOver = over);
    }).toJS;

    _dropJs = ((web.Event event) {
      event.preventDefault();
      final e = event as web.DragEvent;
      if (_isWithinBounds(e.clientX, e.clientY)) {
        setState(() => _isDraggingOver = false);
        unawaited(_handleDrop(e));
      }
    }).toJS;

    _dragLeaveJs = ((web.Event event) {
      final e = event as web.DragEvent;
      if (_isDraggingOver && !_isWithinBounds(e.clientX, e.clientY)) {
        setState(() => _isDraggingOver = false);
      }
    }).toJS;

    web.window.addEventListener('dragover', _dragOverJs);
    web.window.addEventListener('drop', _dropJs);
    web.window.addEventListener('dragleave', _dragLeaveJs);
  }

  @override
  void dispose() {
    web.window.removeEventListener('dragover', _dragOverJs);
    web.window.removeEventListener('drop', _dropJs);
    web.window.removeEventListener('dragleave', _dragLeaveJs);
    super.dispose();
  }

  bool _isWithinBounds(num x, num y) {
    final renderBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;
    final topLeft = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    return x >= topLeft.dx &&
        x <= topLeft.dx + size.width &&
        y >= topLeft.dy &&
        y <= topLeft.dy + size.height;
  }

  Future<void> _handleDrop(web.DragEvent event) async {
    final files = event.dataTransfer?.files;
    if (files == null || files.length == 0) return;
    final file = files.item(0);
    if (file == null) return;

    final name = file.name;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';

    if (!widget.allowedExtensions.contains(ext)) {
      await Utilities.showAlert(
        'Invalid file type',
        'Please drop a ${widget.allowedExtensions.join(' or ')} file.',
        'OK',
      );
      return;
    }

    widget.uploading.value = true;
    widget.uploadStatus?.value = 'processing';

    final Uint8List bytes;
    try {
      final jsBuffer = await file.arrayBuffer().toDart;
      bytes = jsBuffer.toDart.asUint8List();
    } catch (_) {
      await Utilities.showAlert(
        'File error',
        'There was an unknown error reading the dropped file. Please try again.',
        'OK',
      );
      widget.uploading.value = false;
      widget.uploadStatus?.value = '';
      return;
    }

    await _processFileBytes(
      fileBytes: List<int>.from(bytes),
      fileExtension: ext,
      fileSize: bytes.length,
      controller: widget.controller,
      uiControl: widget.uiControl,
      recordId: widget.recordId,
      uploading: widget.uploading,
      onUploadComplete: widget.onUploadComplete,
      filenamePrefix: widget.filenamePrefix,
      uploadStatus: widget.uploadStatus,
      imageValidator: widget.imageValidator,
      preserveFormat: widget.preserveFormat,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bundle mode: show the bundle asset image with overlay + drag-hover indicator.
    // Tap and drop both trigger the file upload flow.
    if (widget.bundleUrl != null) {
      return GestureDetector(
        onTap: () => _triggerUpload(
          controller: widget.controller,
          uiControl: widget.uiControl,
          recordId: widget.recordId,
          allowedExtensions: widget.allowedExtensions,
          uploading: widget.uploading,
          onUploadComplete: widget.onUploadComplete,
          filenamePrefix: widget.filenamePrefix,
          uploadStatus: widget.uploadStatus,
          imageValidator: widget.imageValidator,
          preserveFormat: widget.preserveFormat,
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SizedBox(
            key: _containerKey,
            width: widget.width,
            height: widget.height,
            child: Stack(
              // alignment: center so the imageOverlay (a naturally-sized child)
              // is vertically and horizontally centered over the logo image.
              alignment: Alignment.center,
              children: [
                // Image fills the full box via Positioned.fill.
                Positioned.fill(
                  child: Image.asset(
                    'images/generic_logos/${widget.bundleUrl!.replaceAll('bundle://', '')}.png'
                        .toLowerCase(),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                    ),
                  ),
                ),
                // imageOverlay is naturally sized and centered by Stack alignment.
                if (widget.imageOverlay != null) widget.imageOverlay!,
                // Drag-hover overlay fills the full box via Positioned.fill.
                Positioned.fill(child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: _isDraggingOver
                        ? Colors.blue.shade50.withValues(alpha: 0.85)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isDraggingOver
                          ? Colors.blue.shade400
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: _isDraggingOver
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.file_download_outlined,
                                size: 64,
                                color: Colors.blue.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Drop to upload',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.blue.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Normal placeholder mode: grey box with icon and text.
    return GestureDetector(
      onTap: () => _triggerUpload(
        controller: widget.controller,
        uiControl: widget.uiControl,
        recordId: widget.recordId,
        allowedExtensions: widget.allowedExtensions,
        uploading: widget.uploading,
        onUploadComplete: widget.onUploadComplete,
        filenamePrefix: widget.filenamePrefix,
        uploadStatus: widget.uploadStatus,
        imageValidator: widget.imageValidator,
        preserveFormat: widget.preserveFormat,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          key: _containerKey,
          duration: const Duration(milliseconds: 150),
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _isDraggingOver ? Colors.blue.shade50 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDraggingOver ? Colors.blue.shade400 : Colors.grey.shade400,
              width: _isDraggingOver ? 3 : 2,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isDraggingOver
                        ? Icons.file_download_outlined
                        : Icons.add_photo_alternate_outlined,
                    size: 64,
                    color: _isDraggingOver
                        ? Colors.blue.shade400
                        : Colors.grey.shade500,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isDraggingOver ? 'Drop to upload' : widget.placeholderText,
                    style: TextStyle(
                      fontSize: 18,
                      color: _isDraggingOver
                          ? Colors.blue.shade600
                          : Colors.grey.shade600,
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
    );
  }
}
