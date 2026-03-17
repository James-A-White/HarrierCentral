/// Kennel Other Page Controls
///
/// This file defines the UI control configurations for the Kennel Other tab.
/// It uses an extension on [KennelPageFormController] to keep control
/// initialization organized and separate from the main controller.

part of '../../kennel_page_new_controller.dart';

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds kennel other settings control initialization.
extension KennelOtherControlsExtension on KennelPageFormController {
  /// Initializes all UI controls for the Kennel Other tab.
  ///
  /// This method sets up [UiControlDefinition] instances for each field
  /// on the kennel other tab, including run start time, sharing settings,
  /// integrations, and miscellaneous preferences.
  void initKennelOtherControls() {
    final tabKey = KennelTabType.other.key;
    final tabIndex = KennelTabType.other.index;

    // Run Start settings
    _registerDefaultDayOfWeekControl(tabKey, tabIndex);

    // Sharing settings
    _registerDisseminateHashRunsControl(tabKey, tabIndex);
    _registerDisseminateAllowWebLinksControl(tabKey, tabIndex);

    // Integration settings
    _registerPublishToGoogleCalendarControl(tabKey, tabIndex);
    _registerGoogleCalendarAddressesControl(tabKey, tabIndex);

    // Other settings
    _registerCanEditRunAttendenceControl(tabKey, tabIndex);
    _registerExcludeFromLeaderboardControl(tabKey, tabIndex);
  }

  // ---------------------------------------------------------------------------
  // Run Start Controls
  // ---------------------------------------------------------------------------

  /// Registers the default day of week control (dropdown).
  void _registerDefaultDayOfWeekControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_defaultDayOfWeek';

    // Extract day of week from defaultRunStartTime milliseconds
    var dayOfWeek = originalData.defaultRunStartTime.millisecond ~/ 100;
    if (dayOfWeek == 0) dayOfWeek = 1;

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.dropdown,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Default Day of Week',
        FontAwesome5Solid.calendar_day,
        'Select the default day of the week when your kennel typically runs.\n\n'
            'This will be pre-selected when creating new runs.',
      ),
      editedFieldValue: dayOfWeek.toString(),
      originalFieldValue: dayOfWeek.toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Default day',
      includeOverrideButton: false,
      tabIndex: tabIndex,
      dropdownItems: const {
        1: 'Monday',
        2: 'Tuesday',
        3: 'Wednesday',
        4: 'Thursday',
        5: 'Friday',
        6: 'Saturday',
        7: 'Sunday',
      },
      updateEditedValue: (String? value) {
        final intValue = int.tryParse(value ?? '1') ?? 1;
        final currentTime = editedData.value.defaultRunStartTime;
        final newRunStartTime = DateTime(
          1900,
          1,
          1,
          currentTime.hour,
          currentTime.minute,
          0,
          intValue * 100,
        );
        defaultRunStartTime.value = newRunStartTime;
        editedData.value = editedData.value.copyWith(
          defaultRunStartTime: newRunStartTime,
        );
        uiControls[fieldKey]?.editedFieldValue = value;
      },
      onUndo: () {
        defaultRunStartTime.value = originalData.defaultRunStartTime;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Sharing Controls
  // ---------------------------------------------------------------------------

  /// Registers the disseminate on HashRuns.org control (switch).
  void _registerDisseminateHashRunsControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_disseminateHashRuns';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Show on HashRuns.org',
        FontAwesome5Solid.globe,
        'When enabled, your runs will be visible on HashRuns.org, a public '
            'directory of Hash House Harrier runs.\n\n'
            'This helps visitors from other kennels find your runs.',
      ),
      editedFieldValue: (originalData.disseminateHashRunsDotOrg > 0).toString(),
      originalFieldValue:
          (originalData.disseminateHashRunsDotOrg > 0).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Show runs on Hashruns.org',
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final boolValue = value == 'true';
        disseminateHashRunsDotOrg.value = boolValue;
        editedData.value = editedData.value.copyWith(
          disseminateHashRunsDotOrg: boolValue ? 5 : 0,
        );
        uiControls[fieldKey]?.editedFieldValue = value;
      },
      onUndo: () {
        disseminateHashRunsDotOrg.value =
            originalData.disseminateHashRunsDotOrg > 0;
      },
    );
  }

  /// Registers the allow web links control (switch).
  void _registerDisseminateAllowWebLinksControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_disseminateAllowWebLinks';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Enable Copy Web Link',
        FontAwesome5Solid.link,
        'When enabled, users can copy a public web link to share your runs '
            'with others who may not have the app.\n\n'
            'This is useful for promoting runs on social media.',
      ),
      editedFieldValue: (originalData.disseminateAllowWebLinks > 0).toString(),
      originalFieldValue:
          (originalData.disseminateAllowWebLinks > 0).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Enable copy web link',
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final boolValue = value == 'true';
        disseminateAllowWebLinks.value = boolValue;
        editedData.value = editedData.value.copyWith(
          disseminateAllowWebLinks: boolValue ? 1 : 0,
        );
        uiControls[fieldKey]?.editedFieldValue = value;
      },
      onUndo: () {
        disseminateAllowWebLinks.value =
            originalData.disseminateAllowWebLinks > 0;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Integration Controls
  // ---------------------------------------------------------------------------

  /// Registers the publish to Google Calendars control (switch).
  void _registerPublishToGoogleCalendarControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_publishToGoogleCalendar';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Publish to Google Calendars',
        FontAwesome5Brands.google,
        'When enabled, your runs will be automatically published to the '
            'Google Calendar IDs you specify below.\n\n'
            'This is useful for kennels that maintain their own shared '
            'Google Calendar.',
      ),
      editedFieldValue:
          ((originalData.publishToGoogleCalendar ?? 0) > 0).toString(),
      originalFieldValue:
          ((originalData.publishToGoogleCalendar ?? 0) > 0).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Publish To Google Calendars',
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final boolValue = value == 'true';
        publishToGoogleCalendar.value = boolValue;
        editedData.value = editedData.value.copyWith(
          publishToGoogleCalendar: boolValue ? 1 : 0,
        );
        uiControls[fieldKey]?.editedFieldValue = value;
      },
      onUndo: () {
        publishToGoogleCalendar.value =
            (originalData.publishToGoogleCalendar ?? 0) > 0;
      },
    );
  }

  /// Registers the Google Calendar addresses control (text field).
  void _registerGoogleCalendarAddressesControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_googleCalendarAddresses';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Google Calendar IDs',
        FontAwesome5Solid.calendar_plus,
        'Enter the Google Calendar IDs (email addresses) where your runs '
            'should be published.\n\n'
            'Multiple IDs can be separated by commas. Each ID is typically '
            'the email address associated with the Google Calendar.',
      ),
      editedFieldValue: editedData.value.publishToGoogleCalendarAddresses ?? '',
      originalFieldValue: originalData.publishToGoogleCalendarAddresses ?? '',
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Google Calendar IDs',
      maxStringLength: 500,
      minStringLength: 0,
      maxLines: 3,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(
          publishToGoogleCalendarAddresses: value,
        );
        uiControls[fieldKey]?.editedFieldValue = value;

        // Validate addresses
        if (value != null &&
            ((value.isNotEmpty && value.length < 12) || value.length > 500)) {
          googleCalendarAddressesValid.value = false;
        } else {
          googleCalendarAddressesValid.value = true;
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Other Controls
  // ---------------------------------------------------------------------------

  /// Registers the can edit run attendance control (switch).
  void _registerCanEditRunAttendenceControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_canEditRunAttendence';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'User Edit Attendance',
        FontAwesome5Solid.user_edit,
        'When enabled, users can edit their own attendance records for runs.\n\n'
            'This is useful for kennels that allow hashers to mark themselves '
            'as attended after the fact.',
      ),
      editedFieldValue: (originalData.canEditRunAttendence > 0).toString(),
      originalFieldValue: (originalData.canEditRunAttendence > 0).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'User can edit run attendance',
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final boolValue = value == 'true';
        canEditRunAttendence.value = boolValue;
        editedData.value = editedData.value.copyWith(
          canEditRunAttendence: boolValue ? 1 : 0,
        );
        uiControls[fieldKey]?.editedFieldValue = value;
      },
      onUndo: () {
        canEditRunAttendence.value = originalData.canEditRunAttendence > 0;
      },
    );
  }

  /// Registers the exclude from leaderboard control (switch).
  void _registerExcludeFromLeaderboardControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_excludeFromLeaderboard';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Exclude from Leaderboard',
        FontAwesome5Solid.trophy,
        'When enabled, this kennel will be excluded from the global '
            'leaderboard rankings.\n\n'
            'Some kennels prefer not to participate in leaderboard comparisons.',
      ),
      editedFieldValue: (originalData.excludeFromLeaderboard > 0).toString(),
      originalFieldValue: (originalData.excludeFromLeaderboard > 0).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Exclude from Leaderboard',
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final boolValue = value == 'true';
        excludeFromLeaderboard.value = boolValue;
        editedData.value = editedData.value.copyWith(
          excludeFromLeaderboard: boolValue ? 1 : 0,
        );
        uiControls[fieldKey]?.editedFieldValue = value;
      },
      onUndo: () {
        excludeFromLeaderboard.value = originalData.excludeFromLeaderboard > 0;
      },
    );
  }
}
