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
                  _buildMembershipDateField(
                    label: 'Membership year starts',
                    current: controller.editedData.value
                        .membershipPeriodStartDate,
                    onPicked: (DateTime d) {
                      controller.editedData.value = controller.editedData.value
                          .copyWith(membershipPeriodStartDate: d);
                      controller.checkIfFormIsDirty();
                    },
                  ),
                  _buildMembershipDateField(
                    label: 'Membership year ends',
                    current:
                        controller.editedData.value.membershipPeriodEndDate,
                    onPicked: (DateTime d) {
                      controller.editedData.value = controller.editedData.value
                          .copyWith(membershipPeriodEndDate: d);
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
  /// Tappable date field that opens the standard calendar picker. Used for
  /// the fixed-year membership start/end dates. Bound to editedData so an
  /// undo (which rebuilds from originalData) restores the shown value.
  Widget _buildMembershipDateField({
    required String label,
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
  }) {
    final DateFormat fmt = DateFormat('dd MMM yyyy');
    return Builder(
      builder: (BuildContext context) => InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: current ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) onPicked(picked);
        },
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today, size: 16),
          ),
          child: Text(
            current != null ? fmt.format(current) : 'Select…',
            style: TextStyle(
              color: current != null ? null : const Color(0xFF9CA3AF),
            ),
          ),
        ),
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
