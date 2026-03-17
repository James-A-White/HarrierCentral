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
    return RowColumn(
      isRow: !isMobileScreen,
      rowFlexValues: const [1, 1],
      rowLeftPaddingValues: const [0.0, 10.0],
      children: [
        _buildDefaultRunStartTimeTile(),
        _buildDefaultDayDropdown(isMobileScreen),
      ],
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
      ],
    );
  }

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
      final newRunStartTime = DateTime(
        1900,
        1,
        1,
        pickedTime.hour,
        pickedTime.minute,
        0,
        controller.defaultRunStartTime.value.millisecond,
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

    // Extract day of week from defaultRunStartTime milliseconds
    final dayOfWeek = Rx<int>(
      (controller.defaultRunStartTime.value.millisecond ~/ 100).clamp(1, 7),
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
