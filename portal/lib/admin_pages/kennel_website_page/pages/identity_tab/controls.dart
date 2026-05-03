part of '../../kennel_website_page_controller.dart';

extension IdentityControlsExtension on KennelWebsiteController {
  void initIdentityControls() {
    final tabKey = KennelWebsiteTabType.identity.key;
    const tabIndex = 0;

    _registerEnabledControl(tabKey, tabIndex);
    _registerUrlShortcodeControl(tabKey, tabIndex);
    _registerCustomDomainControl(tabKey, tabIndex);
  }

  void _registerEnabledControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteIdentityField.enabled.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Website Enabled',
        MaterialCommunityIcons.web_check,
        'Toggle your kennel website on or off.\n\n'
            'When disabled, visitors will not be able to view your '
            'public website even if they have the URL.',
      ),
      editedFieldValue:
          editedData.value.enabled ? 'true' : 'false',
      originalFieldValue:
          originalData.enabled ? 'true' : 'false',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Website enabled',
      tabIndex: tabIndex,
      allowEmpty: true,
      updateEditedValue: (String? value) {
        final isEnabled = value == 'true';
        editedData.value =
            editedData.value.copyWith(enabled: isEnabled);
        uiControls[fieldKey]?.editedFieldValue =
            isEnabled ? 'true' : 'false';
      },
    );
  }

  void _registerUrlShortcodeControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteIdentityField.urlShortcode.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'URL Shortcode',
        MaterialCommunityIcons.link,
        'The short name used in the URL path for your kennel website '
            '(e.g. "lh3" → hashruns.org/lh3).\n\n'
            'This is separate from the kennel\'s unique short name and '
            'can be omitted if you use the default path.',
      ),
      editedFieldValue: editedData.value.urlShortcode,
      originalFieldValue: originalData.urlShortcode,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'URL shortcode',
      maxStringLength: 50,
      minStringLength: 0,
      maxLines: 1,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value
            .copyWith(urlShortcode: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerCustomDomainControl(String tabKey, int tabIndex) {
    final fieldKey =
        '${tabKey}_${KennelWebsiteIdentityField.customDomain.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Custom Domain',
        MaterialCommunityIcons.domain,
        'If your kennel has its own domain name (e.g. "lh3.com"), '
            'enter it here.\n\n'
            'Leave empty to use the default hashruns.org/shortcode URL. '
            'You must configure DNS to point your domain to Harrier Central '
            'before enabling this.',
      ),
      editedFieldValue: editedData.value.customDomain,
      originalFieldValue: originalData.customDomain,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Custom domain (optional)',
      maxStringLength: 250,
      minStringLength: 0,
      maxLines: 1,
      allowEmpty: true,
      textController:
          textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
            customDomain: value?.isEmpty == true ? null : value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }
}
