/// Kennel Hash Cash Page Layout
///
/// This file defines the UI layout for the Kennel Hash Cash tab.
/// It contains the KennelHashCashTabContent widget and related UI components.

part of '../../kennel_page_new_ui.dart';

// ---------------------------------------------------------------------------
// Hash Cash Tab Content Widget
// ---------------------------------------------------------------------------

/// Content widget for the Kennel Hash Cash tab.
///
/// Displays settings organized in categories:
/// - Hash Cash (member and non-member pricing)
/// - Payment Settings (negative credit, self-payment)
class KennelHashCashTabContent extends StatelessWidget {
  const KennelHashCashTabContent({required this.controller, super.key});

  final KennelPageFormController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isMobileScreen =
          controller.screenSize.value == EScreenSize.isMobileScreen;

      return Lockable(
        lockState: controller.tabLocked[KennelTabType.hashCash.index],
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hash Cash Section
              HelperWidgets().categoryLabelWidget('Hash Cash'),
              _buildPricingSection(isMobileScreen),

              // Payment Settings Section
              HelperWidgets().categoryLabelWidget('Payment Settings'),
              _buildPaymentSettingsSection(isMobileScreen),

              // Membership Section
              HelperWidgets().categoryLabelWidget('Membership'),
              _buildMembershipSection(isMobileScreen),

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

  /// Builds the Hash Cash pricing section with member and non-member prices.
  Widget _buildPricingSection(bool isMobileScreen) {
    return RowColumn(
      isRow: !isMobileScreen,
      rowFlexValues: const [1, 1],
      rowLeftPaddingValues: const [0.0, 10.0],
      children: [
        _buildPriceField('${KennelTabType.hashCash.key}_memberPrice'),
        _buildPriceField('${KennelTabType.hashCash.key}_nonMemberPrice'),
      ],
    );
  }

  /// Builds the Payment Settings section with switches.
  Widget _buildPaymentSettingsSection(bool isMobileScreen) {
    return RowColumn(
      isRow: !isMobileScreen,
      rowFlexValues: const [1, 1, 1],
      rowLeftPaddingValues: const [0.0, 10.0, 10.0],
      children: [
        _buildSwitchTile(
          controlKey: '${KennelTabType.hashCash.key}_allowCredit',
          value: controller.allowCredit,
          label: 'Allow credit payments',
        ),
        _buildSwitchTile(
          controlKey: '${KennelTabType.hashCash.key}_allowNegativeCredit',
          value: controller.allowNegativeCredit,
          label: 'Allow negative credit',
        ),
        _buildSwitchTile(
          controlKey: '${KennelTabType.hashCash.key}_allowSelfPayment',
          value: controller.allowSelfPayment,
          label: 'Hasher can mark themselves as paid',
        ),
      ],
    );
  }

  /// Builds the Membership section: renewal mode + fee, plus the fields the
  /// selected mode actually uses (duration for rolling, year dates for fixed).
  Widget _buildMembershipSection(bool isMobileScreen) {
    final tabKey = KennelTabType.hashCash.key;
    final modeControl = controller.uiControls['${tabKey}_membershipRenewalMode'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RowColumn(
          isRow: !isMobileScreen,
          rowFlexValues: const [1, 1],
          rowLeftPaddingValues: const [0.0, 10.0],
          children: [
            if (modeControl != null)
              MouseRegion(
                onEnter: (_) => controller.setSidebarData(
                  '${tabKey}_membershipRenewalMode',
                ),
                onExit: (_) =>
                    controller.setSidebarData('${tabKey}_generic'),
                child: EditableDropdownField(
                  controller: controller,
                  uiControl: modeControl,
                  value: controller.membershipRenewalMode,
                  items: modeControl.dropdownItems ?? {},
                ),
              )
            else
              const SizedBox.shrink(),
            _buildPriceField('${tabKey}_membershipPrice'),
          ],
        ),
        // Mode-specific configuration.
        Obx(() {
          switch (controller.membershipRenewalMode.value) {
            case 2:
              return RowColumn(
                isRow: !isMobileScreen,
                rowFlexValues: const [1, 1],
                rowLeftPaddingValues: const [0.0, 10.0],
                children: [
                  _buildMonthDayField(
                    label: 'Membership year starts',
                    current: controller.editedData.value
                        .membershipPeriodStartDate,
                    onChanged: (int month, int day) {
                      controller.editedData.value = controller.editedData.value
                          .copyWith(
                            // Year is a sentinel — only month/day are used.
                            membershipPeriodStartDate: DateTime(2000, month, day),
                          );
                      controller.checkIfFormIsDirty();
                    },
                  ),
                  _buildMonthDayField(
                    label: 'Membership year ends',
                    current:
                        controller.editedData.value.membershipPeriodEndDate,
                    onChanged: (int month, int day) {
                      controller.editedData.value = controller.editedData.value
                          .copyWith(
                            membershipPeriodEndDate: DateTime(2000, month, day),
                          );
                      controller.checkIfFormIsDirty();
                    },
                  ),
                ],
              );
            case 3:
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'One payment grants membership for life.',
                  style: bodyStyleBlack,
                ),
              );
            default:
              return RowColumn(
                isRow: !isMobileScreen,
                rowFlexValues: const [1, 1],
                rowLeftPaddingValues: const [0.0, 10.0],
                children: [
                  _buildPriceField('${tabKey}_membershipDurationInMonths'),
                  const SizedBox.shrink(),
                ],
              );
          }
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Individual Field Builders
  // ---------------------------------------------------------------------------

  /// Builds a price text field.
  /// Month + day selectors for the fixed-year membership window. The
  /// membership year recurs every year, so only month/day are chosen (no
  /// year). Bound to editedData so undo restores the shown value. The day
  /// list follows the selected month (29 Feb allowed as a recurring anchor).
  Widget _buildMonthDayField({
    required String label,
    required DateTime? current,
    required void Function(int month, int day) onChanged,
  }) {
    final int? month = current?.month;
    final int? day = current?.day;
    // Leap-year reference so February offers 29.
    final int daysInMonth = month == null
        ? 31
        : DateTime(2000, month + 1, 0).day;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: DropdownButton<int>(
              isExpanded: true,
              underline: const SizedBox.shrink(),
              hint: const Text('Month'),
              value: month,
              items: List<DropdownMenuItem<int>>.generate(
                12,
                (int i) => DropdownMenuItem<int>(
                  value: i + 1,
                  child: Text(DateFormat('MMMM').format(DateTime(2000, i + 1))),
                ),
              ),
              onChanged: (int? m) {
                if (m == null) return;
                final int maxDay = DateTime(2000, m + 1, 0).day;
                onChanged(m, (day ?? 1) > maxDay ? maxDay : (day ?? 1));
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButton<int>(
              isExpanded: true,
              underline: const SizedBox.shrink(),
              hint: const Text('Day'),
              value: day != null && day <= daysInMonth ? day : null,
              items: List<DropdownMenuItem<int>>.generate(
                daysInMonth,
                (int i) => DropdownMenuItem<int>(
                  value: i + 1,
                  child: Text('${i + 1}'),
                ),
              ),
              onChanged: month == null
                  ? null
                  : (int? d) {
                      if (d != null) onChanged(month, d);
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceField(String controlKey) {
    final uiControl = controller.uiControls[controlKey];

    if (uiControl == null) return const SizedBox.shrink();

    return MouseRegion(
      onEnter: (_) => controller.setSidebarData(controlKey),
      onExit: (_) =>
          controller.setSidebarData('${KennelTabType.hashCash.key}_generic'),
      child: EditableOverrideTextField(
        controller: controller,
        uiControl: uiControl,
        onChanged: (_) => controller.checkIfFormIsDirty(),
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
          controller.setSidebarData('${KennelTabType.hashCash.key}_generic'),
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
}
