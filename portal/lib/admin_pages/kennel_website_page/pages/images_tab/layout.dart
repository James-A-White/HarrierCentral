part of '../../kennel_website_page_ui.dart';

class _ImagesTabContent extends StatelessWidget {
  const _ImagesTabContent({required this.controller});

  final KennelWebsiteController controller;

  @override
  Widget build(BuildContext context) {
    final tabKey = KennelWebsiteTabType.images.key;

    final bannerKey = '${tabKey}_${KennelWebsiteImagesField.bannerImage.name}';
    final bgKey =
        '${tabKey}_${KennelWebsiteImagesField.backgroundImage.name}';
    final ogKey = '${tabKey}_${KennelWebsiteImagesField.ogImageUrl.name}';

    final bannerCtrl = controller.uiControls[bannerKey];
    final bgCtrl = controller.uiControls[bgKey];
    final ogCtrl = controller.uiControls[ogKey];

    if (bannerCtrl == null) return const SizedBox.shrink();

    for (final key in [bannerKey, bgKey, ogKey]) {
      controller.uploadingState[key] ??= false.obs;
      controller.uploadStatusState[key] ??= ''.obs;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HelperWidgets().categoryLabelWidget('Banner Image'),
        const SizedBox(height: 12),
        DocumentManagerField(
          controller: controller,
          uiControl: bannerCtrl,
          fieldName: bannerKey,
          recordId: controller.publicKennelId,
          uploading: controller.uploadingState[bannerKey]!,
          uploadStatus: controller.uploadStatusState[bannerKey],
          placeholderText: 'No banner image\n\nClick to upload',
          height: 200,
          width: 400,
          expandToFit: true,
          onUploadComplete: (String fileName) {
            final fullUrl = BASE_KENNEL_WEBSITE_IMAGES_URL + fileName;
            bannerCtrl.editedFieldValue = fullUrl;
            controller.editedData.value =
                controller.editedData.value.copyWith(bannerImage: fullUrl);
            controller.checkIfFormIsDirty();
          },
          onRemoveDocument: () {
            bannerCtrl.editedFieldValue = null;
            controller.editedData.value =
                controller.editedData.value.copyWith(bannerImage: null);
          },
          onAfterRemove: () => controller.checkIfFormIsDirty(),
        ),
        const SizedBox(height: 32),
        HelperWidgets().categoryLabelWidget('Background Image'),
        const SizedBox(height: 12),
        if (bgCtrl != null)
          DocumentManagerField(
            controller: controller,
            uiControl: bgCtrl,
            fieldName: bgKey,
            recordId: controller.publicKennelId,
            uploading: controller.uploadingState[bgKey]!,
            uploadStatus: controller.uploadStatusState[bgKey],
            placeholderText: 'No background image\n\nClick to upload',
            height: 200,
            width: 400,
            expandToFit: true,
            onUploadComplete: (String fileName) {
              final fullUrl = BASE_KENNEL_WEBSITE_IMAGES_URL + fileName;
              bgCtrl.editedFieldValue = fullUrl;
              controller.editedData.value =
                  controller.editedData.value.copyWith(backgroundImage: fullUrl);
              controller.checkIfFormIsDirty();
            },
            onRemoveDocument: () {
              bgCtrl.editedFieldValue = null;
              controller.editedData.value =
                  controller.editedData.value.copyWith(backgroundImage: null);
            },
            onAfterRemove: () => controller.checkIfFormIsDirty(),
          ),
        const SizedBox(height: 32),
        HelperWidgets().categoryLabelWidget('Social Share Image (OG)'),
        const SizedBox(height: 12),
        if (ogCtrl != null)
          DocumentManagerField(
            controller: controller,
            uiControl: ogCtrl,
            fieldName: ogKey,
            recordId: controller.publicKennelId,
            uploading: controller.uploadingState[ogKey]!,
            uploadStatus: controller.uploadStatusState[ogKey],
            placeholderText:
                'No social share image\n\nClick to upload\n(falls back to banner)',
            height: 180,
            width: 360,
            expandToFit: true,
            onUploadComplete: (String fileName) {
              final fullUrl = BASE_KENNEL_WEBSITE_IMAGES_URL + fileName;
              ogCtrl.editedFieldValue = fullUrl;
              controller.editedData.value =
                  controller.editedData.value.copyWith(ogImageUrl: fullUrl);
              controller.checkIfFormIsDirty();
            },
            onRemoveDocument: () {
              ogCtrl.editedFieldValue = null;
              controller.editedData.value =
                  controller.editedData.value.copyWith(ogImageUrl: null);
            },
            onAfterRemove: () => controller.checkIfFormIsDirty(),
          ),
      ],
    );
  }
}
