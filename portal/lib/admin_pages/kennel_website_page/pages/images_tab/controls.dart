part of '../../kennel_website_page_controller.dart';

extension ImagesControlsExtension on KennelWebsiteController {
  void initImagesControls() {
    final tabKey = KennelWebsiteTabType.images.key;
    const tabIndex = 2;

    _registerBannerImageControl(tabKey, tabIndex);
    _registerBackgroundImageControl(tabKey, tabIndex);
    _registerOgImageControl(tabKey, tabIndex);
  }

  void _registerBannerImageControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteImagesField.bannerImage.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.imageUpload,
      fileType: DocumentType.kennelWebsiteBanner,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Hero Image',
        FontAwesome5Solid.image,
        'The image displayed at the top of the landing page in the hero '
            'section. When set, it replaces the kennel logo in the hero.\n\n'
            'Use a PNG or AVIF with a transparent background to let the '
            'hero backdrop show through, or a JPG for a solid image.\n\n'
            'This image is also used as the social share preview — if not '
            'set, the Kennel Welcome Image is used instead.\n\n'
            'Recommended size: 800×800 px (square with transparency). '
            'Accepted formats: JPG, PNG, AVIF.',
      ),
      editedFieldValue: editedData.value.bannerImage,
      originalFieldValue: originalData.bannerImage,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Hero image',
      tabIndex: tabIndex,
      allowEmpty: true,
      updateEditedValue: (String? value) {
        if (value != null && value.isNotEmpty) {
          editedData.value =
              editedData.value.copyWith(bannerImage: value);
        }
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerBackgroundImageControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteImagesField.backgroundImage.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.imageUpload,
      fileType: DocumentType.kennelWebsiteBackground,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Background Image',
        FontAwesome5Solid.image,
        'A background image displayed behind the main page content.\n\n'
            'Works best with semi-transparent overlays enabled by your '
            'theme settings. Accepted formats: JPG, PNG.',
      ),
      editedFieldValue: editedData.value.backgroundImage,
      originalFieldValue: originalData.backgroundImage,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Background image',
      tabIndex: tabIndex,
      allowEmpty: true,
      updateEditedValue: (String? value) {
        if (value != null && value.isNotEmpty) {
          editedData.value =
              editedData.value.copyWith(backgroundImage: value);
        }
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerOgImageControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteImagesField.ogImageUrl.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.imageUpload,
      fileType: DocumentType.kennelWebsiteOgImage,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Kennel Welcome Image',
        FontAwesome5Solid.image,
        'The image displayed alongside your welcome text on the kennel '
            'home page.\n\n'
            'This image is also used when your page is shared on social '
            'media or messaging apps (Open Graph). '
            'Recommended size: 1200×630 px. Accepted formats: JPG, PNG.',
      ),
      editedFieldValue: editedData.value.ogImageUrl,
      originalFieldValue: originalData.ogImageUrl,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Kennel welcome image',
      tabIndex: tabIndex,
      allowEmpty: true,
      updateEditedValue: (String? value) {
        if (value != null && value.isNotEmpty) {
          editedData.value =
              editedData.value.copyWith(ogImageUrl: value);
        }
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }
}
