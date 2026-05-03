part of '../../kennel_website_page_controller.dart';

extension SeoControlsExtension on KennelWebsiteController {
  void initSeoControls() {
    final tabKey = KennelWebsiteTabType.seo.key;
    const tabIndex = 4;

    _registerSeoTitleControl(tabKey, tabIndex);
    _registerSeoDescriptionControl(tabKey, tabIndex);
  }

  void _registerSeoTitleControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteSeoField.seoTitle.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'SEO Title',
        FontAwesome5Solid.search,
        'Appears in browser tabs and search engine results (max 60 '
            'characters).\n\n'
            'Should include your kennel name and location for best results. '
            'Defaults to your kennel name if left empty.',
      ),
      editedFieldValue: editedData.value.seoTitle,
      originalFieldValue: originalData.seoTitle,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Page title (max 60 characters, optional)',
      maxStringLength: 60,
      minStringLength: 0,
      maxLines: 1,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value
            .copyWith(seoTitle: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerSeoDescriptionControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteSeoField.seoDescription.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Meta Description',
        FontAwesome5Solid.file_alt,
        'Shown in search engine result snippets beneath the page title '
            '(max 155 characters).\n\n'
            'Write a short, compelling description that tells searchers '
            'what your kennel is about.',
      ),
      editedFieldValue: editedData.value.seoDescription,
      originalFieldValue: originalData.seoDescription,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Meta description (max 155 characters, optional)',
      maxStringLength: 155,
      minStringLength: 0,
      maxLines: 4,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
            seoDescription: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }
}
