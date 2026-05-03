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
        'Banner Image',
        FontAwesome5Solid.image,
        'The hero / header image displayed at the top of your kennel '
            'website.\n\n'
            'Recommended size: 1920×600 px or wider. '
            'Accepted formats: JPG, PNG.',
      ),
      editedFieldValue: editedData.value.bannerImage,
      originalFieldValue: originalData.bannerImage,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Banner image',
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
        'Social Share Image (OG)',
        FontAwesome5Solid.share_alt,
        'Shown when your page is shared on social media or messaging '
            'apps.\n\n'
            'Recommended size: 1200×630 px. Falls back to the banner '
            'image if left empty. Accepted formats: JPG, PNG.',
      ),
      editedFieldValue: editedData.value.ogImageUrl,
      originalFieldValue: originalData.ogImageUrl,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Social share image (OG)',
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
