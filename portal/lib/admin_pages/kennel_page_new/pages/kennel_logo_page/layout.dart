/// Kennel Logo Tab Layout
///
/// UI widget for the kennel logo upload tab.

part of '../../kennel_page_new_ui.dart';

// ---------------------------------------------------------------------------
// Logo Tab Content Widget
// ---------------------------------------------------------------------------

/// Content widget for the Kennel Logo tab.
///
/// Displays an image upload field that allows admins to upload a custom
/// kennel logo, mirroring the Event Image tab in the Run Editor.
class KennelLogoTabContent extends StatelessWidget {
  const KennelLogoTabContent({required this.controller, super.key});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        HelperWidgets().categoryLabelWidget('Kennel Logo'),
        const SizedBox(height: 16),
        Center(child: _buildLogoSection(context)),
      ],
    );
  }

  Widget _buildLogoSection(BuildContext context) {
    final controlKey =
        '${KennelTabType.kennelLogo.key}_logo';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    controller.uploadingState[controlKey] ??= false.obs;
    controller.uploadStatusState[controlKey] ??= ''.obs;

    final screenSize = MediaQuery.of(context).size;
    final availableHeight = screenSize.height - 400;
    final availableWidth = screenSize.width - 100;
    final imageHeight = availableHeight.clamp(150.0, 800.0);
    final imageWidth = availableWidth.clamp(150.0, 1200.0);

    return DocumentManagerField(
      controller: controller,
      uiControl: uiControl,
      fieldName: controlKey,
      recordId: controller.originalData.kennelPublicId.uuid,
      uploading: controller.uploadingState[controlKey]!,
      uploadStatus: controller.uploadStatusState[controlKey],
      height: imageHeight,
      width: imageWidth,
      expandToFit: true,
      allowedExtensions: const ['png', 'avif'],
      preserveFormat: true,
      placeholderText: 'No logo\n\nClick to upload',
      filenamePrefix: '${controller.originalData.kennelUniqueShortName}_',
      imageValidator: (int w, int h) {
        if (w != h) {
          return 'Logo must be square. This image is $w×$h pixels.';
        }
        if (w < 400 || w > 800) {
          return 'Logo must be between 400×400 and 800×800 pixels. '
              'This image is $w×$h pixels.';
        }
        return null;
      },
      onUploadComplete: (String fileName) {
        final fullUrl = BASE_KENNEL_LOGOS_URL + fileName;
        uiControl.editedFieldValue = fullUrl;
        controller.editedData.value = controller.editedData.value.copyWith(
          kennelLogo: fullUrl,
        );
        controller.checkIfFormIsDirty();
      },
      onRemoveDocument: () {
        // Clear the displayed image (null → hasValidImage = false → shows placeholder).
        // Revert the model to the original logo so the form is no longer dirty.
        uiControl.editedFieldValue = null;
        controller.editedData.value = controller.editedData.value.copyWith(
          kennelLogo: controller.originalData.kennelLogo,
        );
      },
      onAfterRemove: () => controller.checkIfFormIsDirty(),
    );
  }
}
