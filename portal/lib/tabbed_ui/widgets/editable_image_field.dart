import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Editable Image Field Widget
// ---------------------------------------------------------------------------

/// A reusable image upload/preview widget with sidebar integration.
///
/// This widget provides:
/// - Image preview with loading indicator
/// - Remove and Select buttons for image management
/// - Upload progress indication
/// - Sidebar hover integration for contextual help
///
/// Example usage:
/// ```dart
/// EditableImageField(
///   controller: myTabController,
///   uiControl: myUiControlDefinition,
///   imageUrl: controller.editedData.value.eventImage,
///   uploadedImageUrl: controller.uploadedImage,
///   isUploading: controller.uploadingPhoto,
///   onRemove: () => controller.uploadedImage.value = '<null>',
///   onSelect: () => _pickAndUploadImage(),
/// )
/// ```
class EditableImageField<T extends TabUiController> extends StatelessWidget {
  const EditableImageField({
    super.key,
    required this.controller,
    required this.uiControl,
    required this.imageUrl,
    required this.uploadedImageUrl,
    required this.isUploading,
    required this.onRemove,
    required this.onSelect,
    this.imageHeight = 300.0,
    this.showRemoveButton = true,
    this.showSelectButton = true,
    this.removeButtonLabel = 'Remove Image',
    this.selectButtonLabel = 'Select Image',
    this.emptyPlaceholder,
  });

  /// The parent tab controller for sidebar integration.
  final T controller;

  /// Definition containing field configuration and sidebar data.
  final UiControlDefinition uiControl;

  /// The current image URL from the data model (may be null).
  final String? imageUrl;

  /// Reactive uploaded image URL (takes precedence over imageUrl).
  final RxnString uploadedImageUrl;

  /// Whether an image is currently being uploaded.
  final RxBool isUploading;

  /// Callback when the remove button is pressed.
  final VoidCallback onRemove;

  /// Callback when the select button is pressed.
  final VoidCallback onSelect;

  /// Height of the image preview container.
  final double imageHeight;

  /// Whether to show the remove button.
  final bool showRemoveButton;

  /// Whether to show the select button.
  final bool showSelectButton;

  /// Label for the remove button.
  final String removeButtonLabel;

  /// Label for the select button.
  final String selectButtonLabel;

  /// Widget to show when no image is available.
  final Widget? emptyPlaceholder;

  @override
  Widget build(BuildContext context) {
    return SidebarHoverRegion(
      controller: controller,
      uiControl: uiControl,
      child: Obx(() => _buildContent()),
    );
  }

  Widget _buildContent() {
    // Determine which image URL to show
    final displayUrl = uploadedImageUrl.value ?? imageUrl;
    final hasImage =
        displayUrl != null && displayUrl != '<null>' && displayUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image preview or placeholder
        if (hasImage) ...[
          _buildImagePreview(displayUrl),
          const SizedBox(height: 16),
        ] else if (emptyPlaceholder != null) ...[
          emptyPlaceholder!,
          const SizedBox(height: 16),
        ] else ...[
          _buildEmptyState(),
          const SizedBox(height: 16),
        ],

        // Action buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildImagePreview(String url) {
    return Container(
      height: imageHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: isUploading.value
          ? const Center(child: CircularProgressIndicator())
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: HcNetworkImage(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load image',
                          style: bodyStyleBlack.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: imageHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'No image selected',
              style: bodyStyleBlack.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final displayUrl = uploadedImageUrl.value ?? imageUrl;
    final hasImage =
        displayUrl != null && displayUrl != '<null>' && displayUrl.isNotEmpty;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showRemoveButton && hasImage) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: Text(removeButtonLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: isUploading.value ? null : onRemove,
          ),
          const SizedBox(width: 20),
        ],
        if (showSelectButton) ...[
          ElevatedButton.icon(
            icon: const Icon(Icons.upload),
            label: Text(selectButtonLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: isUploading.value ? null : onSelect,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Read-Only Image Preview Widget
// ---------------------------------------------------------------------------

/// A read-only image preview widget for displaying external/integration images.
///
/// Use this when the image cannot be edited (e.g., from an external source).
class ReadOnlyImagePreview extends StatelessWidget {
  const ReadOnlyImagePreview({
    super.key,
    required this.imageUrl,
    this.imageHeight = 300.0,
    this.emptyMessage = 'No image available',
    this.borderRadius = 8.0,
  });

  /// The image URL to display.
  final String? imageUrl;

  /// Height of the image container.
  final double imageHeight;

  /// Message to show when no image is available.
  final String emptyMessage;

  /// Border radius for the image container.
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            emptyMessage,
            style: bodyStyleBlack.copyWith(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Container(
      height: imageHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: HcNetworkImage(
          imageUrl!,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: bodyStyleBlack.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
