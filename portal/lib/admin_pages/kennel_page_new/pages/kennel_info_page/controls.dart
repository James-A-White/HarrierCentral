/// Kennel Info Page Controls
///
/// This file defines the UI control configurations for the Kennel Info tab.
/// It uses an extension on [KennelPageFormController] to keep control
/// initialization organized and separate from the main controller.

part of '../../kennel_page_new_controller.dart';

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds kennel info control initialization to the controller.
extension KennelInfoControlsExtension on KennelPageFormController {
  /// Initializes all UI controls for the Kennel Info tab.
  ///
  /// This method sets up [UiControlDefinition] instances for each field
  /// on the kennel info tab, including validation rules, sidebar help text,
  /// and update callbacks.
  void initKennelInfoControls() {
    final tabKey = KennelTabType.kennelInfo.key;
    const tabIndex = 0;

    _registerKennelNameControl(tabKey, tabIndex);
    _registerKennelShortNameControl(tabKey, tabIndex);
    _registerKennelUniqueShortNameControl(tabKey, tabIndex);
    _registerKennelDescriptionControl(tabKey, tabIndex);
    _registerAdminEmailListControl(tabKey, tabIndex);
    _registerWebsiteUrlControl(tabKey, tabIndex);
  }

  // ---------------------------------------------------------------------------
  // Individual Control Registration
  // ---------------------------------------------------------------------------

  /// Registers the kennel name control.
  void _registerKennelNameControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${KennelInfoField.kennelName.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Kennel Name',
        FontAwesome.pencil_square,
        'The long form of your Kennel\'s name, such as "London Hash House '
            'Harriers", should be between 3 and 50 characters and unique '
            'throughout the world (if possible).',
      ),
      editedFieldValue: editedData.value.kennelName,
      originalFieldValue: originalData.kennelName,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Kennel name',
      maxStringLength: 100,
      minStringLength: 3,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(kennelName: value!);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  /// Registers the kennel short name (abbreviation) control.
  void _registerKennelShortNameControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${KennelInfoField.kennelShortName.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Kennel Abbreviation',
        Entypo.text,
        "Your Kennel's abbreviation should be between 3 and 6 characters "
            "long (although we support up to 9 characters). It should be "
            "unique in your local area, even if there are other Kennels with "
            "similar abbreviations in other parts of the world.",
      ),
      editedFieldValue: editedData.value.kennelShortName,
      originalFieldValue: originalData.kennelShortName,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Kennel abbreviation',
      maxStringLength: 10,
      minStringLength: 3,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(kennelShortName: value!);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  /// Registers the kennel unique short name control.
  void _registerKennelUniqueShortNameControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${KennelInfoField.kennelUniqueShortName.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Kennel Unique Abbreviation',
        Entypo.text,
        "This is a globally unique version of your Kennel's short name. "
            "It must be unique within the Harrier Central data ecosystem "
            "because it is used to form URLs to Web pages specific to your "
            "Kennel.\n\nThe system will automatically generate a unique "
            "abbreviation based on other Kennel unique abbreviations already "
            "in the system. You can override this value if you wish, but "
            "please ensure it remains unique.",
      ),
      editedFieldValue: editedData.value.kennelUniqueShortName,
      originalFieldValue: originalData.kennelUniqueShortName,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Kennel unique abbreviation',
      maxStringLength: 10,
      minStringLength: 3,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value =
            editedData.value.copyWith(kennelUniqueShortName: value!);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  /// Registers the kennel description control.
  void _registerKennelDescriptionControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${KennelInfoField.kennelDescription.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Kennel Description',
        Entypo.text,
        'Please provide a short Kennel description. This should include '
            'what day and time your group normally runs, how much it costs, '
            'and any other relevant information.\n\nMake it fun so visitors '
            'will want to join you!',
      ),
      editedFieldValue: editedData.value.kennelDescription,
      originalFieldValue: originalData.kennelDescription,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Short description',
      maxStringLength: 2000,
      minStringLength: 30,
      maxLines: 10,
      includeOverrideButton: false,
      expandToFillSpace: true,
      minHeight: 300,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(kennelDescription: value!);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  /// Registers the admin email list control.
  void _registerAdminEmailListControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${KennelInfoField.kennelAdminEmailList.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Admin Emails',
        MaterialIcons.contact_mail,
        'Please provide a comma separated list of emails of administrators '
            'of your Kennel.\n\nWe will use this only to contact you to let '
            'you know about changes to the system or if we are experiencing '
            'any issues with Harrier Central.',
      ),
      editedFieldValue: editedData.value.kennelAdminEmailList,
      originalFieldValue: originalData.kennelAdminEmailList,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Kennel admin email list',
      maxStringLength: 500,
      minStringLength: 0,
      readonly: false,
      maxLines: 3,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value =
            editedData.value.copyWith(kennelAdminEmailList: value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  /// Registers the website URL control.
  void _registerWebsiteUrlControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${KennelInfoField.kennelWebsiteUrl.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Website Address',
        MaterialCommunityIcons.web_box,
        'If your Kennel has a website, please provide the URL to it here.\n\n'
            'This will make it easy for Hashers to find your Kennel whether or '
            'not you use Harrier Central to post your runs.',
      ),
      editedFieldValue: editedData.value.kennelWebsiteUrl,
      originalFieldValue: originalData.kennelWebsiteUrl,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Kennel website URL',
      maxStringLength: 100,
      minStringLength: 5,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(kennelWebsiteUrl: value!);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }
}
