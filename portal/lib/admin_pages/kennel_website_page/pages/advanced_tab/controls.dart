part of '../../kennel_website_page_controller.dart';

extension AdvancedControlsExtension on KennelWebsiteController {
  void initAdvancedControls() {
    final tabKey = KennelWebsiteTabType.advanced.key;
    const tabIndex = 6;

    _registerMismanagementDescriptionControl(tabKey, tabIndex);
    _registerMismanagementJsonControl(tabKey, tabIndex);
    _registerExtraMenusJsonControl(tabKey, tabIndex);
    _registerContactDetailsJsonControl(tabKey, tabIndex);
  }

  void _registerMismanagementDescriptionControl(
      String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteAdvancedField.mismanagementDescription.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Mis-management Description',
        FontAwesome5Solid.users,
        'Introductory text shown on the mis-management / committee page '
            'of your website.\n\n'
            'Describe your committee structure or just have fun with it.',
      ),
      editedFieldValue: editedData.value.mismanagementDescription,
      originalFieldValue: originalData.mismanagementDescription,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Mis-management page description (optional)',
      maxStringLength: 4000,
      minStringLength: 0,
      maxLines: 8,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
            mismanagementDescription:
                value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerMismanagementJsonControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteAdvancedField.mismanagementJson.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Committee JSON',
        FontAwesome5Solid.code,
        'JSON array of committee member objects for the mis-management '
            'page.\n\nEach entry can include name, role, and contact '
            'details. Leave empty to hide the committee section.',
      ),
      editedFieldValue: editedData.value.mismanagementJson,
      originalFieldValue: originalData.mismanagementJson,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Committee JSON (optional)',
      maxStringLength: 4000,
      minStringLength: 0,
      maxLines: 10,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
            mismanagementJson: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerExtraMenusJsonControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteAdvancedField.extraMenusJson.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Extra Navigation Menus',
        FontAwesome5Solid.bars,
        'JSON array of extra navigation menu items to add to the '
            'website header.\n\nEach entry should include a label and URL. '
            'Leave empty to use the default navigation.',
      ),
      editedFieldValue: editedData.value.extraMenusJson,
      originalFieldValue: originalData.extraMenusJson,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Extra menus JSON (optional)',
      maxStringLength: 4000,
      minStringLength: 0,
      maxLines: 10,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
            extraMenusJson: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerContactDetailsJsonControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteAdvancedField.contactDetailsJson.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Contact Details',
        FontAwesome5Solid.address_card,
        'JSON object with contact details shown on the website contact '
            'section.\n\nCan include email addresses, phone numbers, '
            'and social media links.',
      ),
      editedFieldValue: editedData.value.contactDetailsJson,
      originalFieldValue: originalData.contactDetailsJson,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Contact details JSON (optional)',
      maxStringLength: 4000,
      minStringLength: 0,
      maxLines: 10,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
            contactDetailsJson: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }
}
