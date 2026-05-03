part of '../../kennel_website_page_controller.dart';

extension ContentControlsExtension on KennelWebsiteController {
  void initContentControls() {
    final tabKey = KennelWebsiteTabType.content.key;
    const tabIndex = 3;

    _registerTitleTextControl(tabKey, tabIndex);
    _registerTaglineControl(tabKey, tabIndex);
    _registerWelcomeTextControl(tabKey, tabIndex);
  }

  void _registerTitleTextControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteContentField.titleText.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Hero Title',
        MaterialCommunityIcons.format_header_1,
        'Custom display name shown in the hero section of your website, '
            'distinct from the kennel\'s registered name.\n\n'
            'Leave empty to use the kennel name.',
      ),
      editedFieldValue: editedData.value.titleText,
      originalFieldValue: originalData.titleText,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Hero title (optional)',
      maxStringLength: 500,
      minStringLength: 0,
      maxLines: 1,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value
            .copyWith(titleText: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerTaglineControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteContentField.tagline.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Tagline',
        MaterialCommunityIcons.format_quote_open,
        'A short strapline shown beneath the kennel name in the hero '
            'section (max 250 characters).\n\n'
            'Example: "On–On every Tuesday at 6:30pm"',
      ),
      editedFieldValue: editedData.value.tagline,
      originalFieldValue: originalData.tagline,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Tagline (optional)',
      maxStringLength: 250,
      minStringLength: 0,
      maxLines: 2,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value
            .copyWith(tagline: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerWelcomeTextControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteContentField.welcomeText.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Welcome Text',
        MaterialCommunityIcons.text_long,
        'Homepage introduction / welcome message shown to visitors.\n\n'
            'Tell people what your kennel is about, when you run, '
            'and how to get involved. Max 4000 characters.',
      ),
      editedFieldValue: editedData.value.welcomeText,
      originalFieldValue: originalData.welcomeText,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Welcome text (optional)',
      maxStringLength: 4000,
      minStringLength: 0,
      maxLines: 12,
      allowEmpty: true,
      expandToFillSpace: true,
      minHeight: 200,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value
            .copyWith(welcomeText: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }
}
