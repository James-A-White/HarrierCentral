/// Kennel Other Page Layout
///
/// This file defines the UI layout for the Kennel Other tab.
/// It contains the KennelOtherTabContent widget and related UI components.

part of '../../kennel_page_new_ui.dart';

// ---------------------------------------------------------------------------
// Other Tab Content Widget
// ---------------------------------------------------------------------------

/// Content widget for the Kennel Other tab.
///
/// Displays settings organized in categories:
/// - Run Start (default time and day)
/// - Sharing Runs (HashRuns.org, web links)
/// - Integrations (Google Calendar options)
/// - Other (attendance editing, leaderboard exclusion)
class KennelOtherTabContent extends StatelessWidget {
  const KennelOtherTabContent({required this.controller, super.key});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isMobileScreen =
          controller.screenSize.value == EScreenSize.isMobileScreen;

      return Lockable(
        lockState: controller.tabLocked[KennelTabType.other.index],
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Run Start Section
              HelperWidgets().categoryLabelWidget('Run Start'),
              _buildRunStartSection(isMobileScreen),

              // Sharing Runs Section
              HelperWidgets().categoryLabelWidget('Sharing Runs'),
              _buildSharingSection(isMobileScreen),

              // Messaging Section (E9.F6)
              HelperWidgets().categoryLabelWidget('Messaging'),
              _buildMessagingSection(isMobileScreen),

              // Integrations Section
              HelperWidgets().categoryLabelWidget('Integrations'),
              _buildIntegrationsSection(isMobileScreen),

              // Other Section
              HelperWidgets().categoryLabelWidget('Other'),
              _buildOtherSection(isMobileScreen),

              const SizedBox(height: 20),
            ],
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Section Builders
  // ---------------------------------------------------------------------------

  /// Builds the Run Start section with time picker and day dropdown.
  Widget _buildRunStartSection(bool isMobileScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RowColumn(
          isRow: !isMobileScreen,
          rowFlexValues: const [1, 1],
          rowLeftPaddingValues: const [0.0, 10.0],
          children: [
            _buildDefaultRunStartTimeTile(),
            _buildDefaultDayDropdown(isMobileScreen),
          ],
        ),
        const SizedBox(height: 10),
        _buildPackOffDropdown(isMobileScreen),
      ],
    );
  }

  /// Minutes offered for the kennel's default pack-off (E3.F1.S6).
  static const List<int> _packOffChoices = [5, 10, 15, 20, 30, 45, 60, 90, 120];

  /// Builds the default pack-off dropdown (E3.F1.S6): "At the gather" or
  /// "N minutes after the gather". -1 stands for null (at the gather).
  Widget _buildPackOffDropdown(bool isMobileScreen) {
    final controlKey = '${KennelTabType.other.key}_packOffMinutes';
    final uiControl = controller.uiControls[controlKey];
    if (uiControl == null) return const SizedBox.shrink();

    return MouseRegion(
      onEnter: (_) => controller.setSidebarData(controlKey),
      onExit: (_) =>
          controller.setSidebarData('${KennelTabType.other.key}_generic'),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: isMobileScreen ? double.infinity : 300,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Pack off',
              helperText: 'Default for every run; a run can set its own.',
              border: OutlineInputBorder(),
            ),
            child: Obx(() {
              final current = controller.packOffMinutes.value ?? -1;
              // The saved value, even when it is not one of the choices
              // (another client, or 0 = at the gather), so it shows as is.
              final values = <int>{-1, ..._packOffChoices, current}.toList()
                ..sort();
              return DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: current,
                  isDense: true,
                  isExpanded: true,
                  items: [
                    for (final v in values)
                      DropdownMenuItem(
                        value: v,
                        child: Text(
                          v < 0
                              ? 'At the gather'
                              : v == 0
                              ? 'At the gather (0 minutes)'
                              : '$v minutes after the gather',
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    uiControl.updateEditedValue(value.toString());
                    controller.checkIfFormIsDirty();
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  /// Builds the Sharing section with switches.
  Widget _buildSharingSection(bool isMobileScreen) {
    return RowColumn(
      isRow: !isMobileScreen,
      rowFlexValues: const [1, 1],
      rowLeftPaddingValues: const [0.0, 10.0],
      children: [
        _buildSwitchTile(
          controlKey: '${KennelTabType.other.key}_disseminateHashRuns',
          value: controller.disseminateHashRunsDotOrg,
          label: 'Show runs on Hashruns.org',
        ),
        _buildSwitchTile(
          controlKey: '${KennelTabType.other.key}_disseminateAllowWebLinks',
          value: controller.disseminateAllowWebLinks,
          label: 'Enable copy web link',
        ),
      ],
    );
  }

  /// Builds the Messaging section: the kennel's app, and its group invite
  /// link (E9.F6).
  Widget _buildMessagingSection(bool isMobileScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMessagingPlatformDropdown(isMobileScreen),
        const SizedBox(height: 10),
        _buildGroupInviteUrlField(),
      ],
    );
  }

  Widget _buildMessagingPlatformDropdown(bool isMobileScreen) {
    final controlKey = '${KennelTabType.other.key}_messagingPlatform';
    final uiControl = controller.uiControls[controlKey];
    if (uiControl == null) return const SizedBox.shrink();

    return MouseRegion(
      onEnter: (_) => controller.setSidebarData(controlKey),
      onExit: (_) =>
          controller.setSidebarData('${KennelTabType.other.key}_generic'),
      child: SizedBox(
        width: isMobileScreen ? double.infinity : 300,
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Messaging app',
            border: OutlineInputBorder(),
          ),
          child: Obx(
            () => DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: controller.messagingPlatform.value.clamp(1, 5),
                isDense: true,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('WhatsApp')),
                  DropdownMenuItem(value: 2, child: Text('Telegram')),
                  DropdownMenuItem(value: 3, child: Text('Signal')),
                  DropdownMenuItem(value: 4, child: Text('Facebook Messenger')),
                  DropdownMenuItem(value: 5, child: Text('WeChat')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  uiControl.updateEditedValue(value.toString());
                  controller.checkIfFormIsDirty();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupInviteUrlField() {
    final controlKey = '${KennelTabType.other.key}_messagingGroupInviteUrl';
    final uiControl = controller.uiControls[controlKey];
    if (uiControl == null) return const SizedBox.shrink();

    return MouseRegion(
      onEnter: (_) => controller.setSidebarData(controlKey),
      onExit: (_) =>
          controller.setSidebarData('${KennelTabType.other.key}_generic'),
      child: EditableOverrideTextField(
        controller: controller,
        uiControl: uiControl,
        onChanged: (_) => controller.checkIfFormIsDirty(),
      ),
    );
  }

  /// Builds the Integrations section with calendar options.
  Widget _buildIntegrationsSection(bool isMobileScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RowColumn(
          isRow: !isMobileScreen,
          rowFlexValues: const [1, 1],
          rowLeftPaddingValues: const [0.0, 10.0],
          children: [
            _buildSwitchTile(
              controlKey: '${KennelTabType.other.key}_publishToGoogleCalendar',
              value: controller.publishToGoogleCalendar,
              label: 'Publish To Google Calendars',
            ),
            const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 10),
        _buildGoogleCalendarAddressesField(),
        _googleCalendarPublishHelp(),
      ],
    );
  }

  /// With publishing on, how to give Harrier Central permission to change
  /// the calendar. Without it Google refuses every run (Big Lik H3, 13 Oct
  /// 2026; E3.F6.S7). Selectable so the address can be copied.
  Widget _googleCalendarPublishHelp() => Obx(() {
    final bool on = controller.publishToGoogleCalendar.value;
    if (!on) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          border: Border.all(color: Colors.amber.shade700),
          borderRadius: BorderRadius.circular(6),
        ),
        child: SelectableText(
          kGoogleCalendarPublishHelp,
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
      ),
    );
  });

  /// Builds the Other section with miscellaneous switches.
  Widget _buildOtherSection(bool isMobileScreen) {
    return RowColumn(
      isRow: !isMobileScreen,
      rowFlexValues: const [1, 1],
      rowLeftPaddingValues: const [0.0, 10.0],
      children: [
        _buildSwitchTile(
          controlKey: '${KennelTabType.other.key}_canEditRunAttendence',
          value: controller.canEditRunAttendence,
          label: 'User can edit run attendance',
        ),
        _buildSwitchTile(
          controlKey: '${KennelTabType.other.key}_excludeFromLeaderboard',
          value: controller.excludeFromLeaderboard,
          label: 'Exclude from Leaderboard',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Individual Field Builders
  // ---------------------------------------------------------------------------

  /// Builds the default run start time picker tile.
  Widget _buildDefaultRunStartTimeTile() {
    return MouseRegion(
      onEnter: (_) => controller.setSidebarData(
        '${KennelTabType.other.key}_defaultRunStartTime',
      ),
      onExit: (_) =>
          controller.setSidebarData('${KennelTabType.other.key}_generic'),
      child: ListTile(
        title: Text('Default Run Start Time', style: bodyStyleBlackSmall),
        subtitle: Obx(
          () => Text(
            DateFormat.jm().format(controller.defaultRunStartTime.value),
            style: bodyStyleBlack,
          ),
        ),
        onTap: () => _showTimePicker(),
      ),
    );
  }

  /// Shows the time picker dialog and updates the run start time.
  Future<void> _showTimePicker() async {
    final initialTime = TimeOfDay(
      hour: controller.defaultRunStartTime.value.hour,
      minute: controller.defaultRunStartTime.value.minute,
    );

    final pickedTime = await showTimePicker(
      context: Get.context!,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      // Pure time-of-day — the default weekday now lives in its own field
      // (defaultRunDayOfWeek), no longer encoded in the milliseconds.
      final newRunStartTime = DateTime(
        1900,
        1,
        1,
        pickedTime.hour,
        pickedTime.minute,
      );

      controller.defaultRunStartTime.value = newRunStartTime;
      controller.editedData.value = controller.editedData.value.copyWith(
        defaultRunStartTime: newRunStartTime,
      );
      controller.checkIfFormIsDirty();
    }
  }

  /// Builds the default day of week dropdown.
  Widget _buildDefaultDayDropdown(bool isMobileScreen) {
    final controlKey = '${KennelTabType.other.key}_defaultDayOfWeek';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    // Real field — the fractional-seconds encoding is retired.
    final dayOfWeek = Rx<int>(
      controller.editedData.value.defaultRunDayOfWeek.clamp(1, 7),
    );

    return MouseRegion(
      onEnter: (_) => controller.setSidebarData(controlKey),
      onExit: (_) =>
          controller.setSidebarData('${KennelTabType.other.key}_generic'),
      child: SizedBox(
        width: isMobileScreen ? double.infinity : 300,
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Default day',
            border: OutlineInputBorder(),
          ),
          child: Obx(
            () => DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: dayOfWeek.value,
                isDense: true,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Monday')),
                  DropdownMenuItem(value: 2, child: Text('Tuesday')),
                  DropdownMenuItem(value: 3, child: Text('Wednesday')),
                  DropdownMenuItem(value: 4, child: Text('Thursday')),
                  DropdownMenuItem(value: 5, child: Text('Friday')),
                  DropdownMenuItem(value: 6, child: Text('Saturday')),
                  DropdownMenuItem(value: 7, child: Text('Sunday')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  dayOfWeek.value = value;
                  uiControl.updateEditedValue(value.toString());
                  controller.checkIfFormIsDirty();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a switch list tile for boolean settings.
  Widget _buildSwitchTile({
    required String controlKey,
    required RxBool value,
    required String label,
  }) {
    final uiControl = controller.uiControls[controlKey];

    return MouseRegion(
      onEnter: (_) => controller.setSidebarData(controlKey),
      onExit: (_) =>
          controller.setSidebarData('${KennelTabType.other.key}_generic'),
      child: Obx(
        () => SwitchListTile(
          title: Text(label, style: bodyStyleBlack),
          value: value.value,
          onChanged: (newValue) {
            value.value = newValue;
            uiControl?.updateEditedValue(newValue.toString());
            controller.checkIfFormIsDirty();
          },
        ),
      ),
    );
  }

  /// Builds the Google Calendar addresses text field.
  Widget _buildGoogleCalendarAddressesField() {
    final controlKey = '${KennelTabType.other.key}_googleCalendarAddresses';
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    return MouseRegion(
      onEnter: (_) => controller.setSidebarData(controlKey),
      onExit: (_) =>
          controller.setSidebarData('${KennelTabType.other.key}_generic'),
      child: EditableOverrideTextField(
        controller: controller,
        uiControl: uiControl,
        onChanged: (_) => controller.checkIfFormIsDirty(),
      ),
    );
  }
}
