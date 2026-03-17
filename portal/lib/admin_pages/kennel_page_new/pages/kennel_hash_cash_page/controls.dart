/// Kennel Hash Cash Page Controls
///
/// This file defines the UI control configurations for the Kennel Hash Cash tab.
/// It uses an extension on [KennelPageFormController] to keep control
/// initialization organized and separate from the main controller.

part of '../../kennel_page_new_controller.dart';

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds kennel hash cash control initialization.
extension KennelHashCashControlsExtension on KennelPageFormController {
  /// Initializes all UI controls for the Kennel Hash Cash tab.
  ///
  /// This method sets up [UiControlDefinition] instances for each field
  /// on the hash cash tab, including pricing and payment settings.
  void initKennelHashCashControls() {
    final tabKey = KennelTabType.hashCash.key;
    final tabIndex = KennelTabType.hashCash.index;

    // Hash Cash pricing
    _registerMemberPriceControl(tabKey, tabIndex);
    _registerNonMemberPriceControl(tabKey, tabIndex);

    // Payment settings
    _registerAllowNegativeCreditControl(tabKey, tabIndex);
    _registerAllowSelfPaymentControl(tabKey, tabIndex);
  }

  // ---------------------------------------------------------------------------
  // Hash Cash Pricing Controls
  // ---------------------------------------------------------------------------

  /// Registers the member price control (text field for double).
  void _registerMemberPriceControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_memberPrice';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Member Price',
        FontAwesome5Solid.money_bill_wave,
        'The default event price for kennel members.\n\n'
            'This is the amount that will be pre-populated when creating '
            'a new run. You can always adjust the price for individual runs.',
      ),
      editedFieldValue:
          originalData.defaultEventPriceForMembers.toStringAsFixed(2),
      originalFieldValue:
          originalData.defaultEventPriceForMembers.toStringAsFixed(2),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Default Event Price for Members',
      maxStringLength: 10,
      minStringLength: 1,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      regex: r'^\d+(\.\d{0,2})?$',
      regexErrorString: 'Please enter a valid price (e.g., 7.50)',
      updateEditedValue: (String? value) {
        final price = double.tryParse(value ?? '0') ?? 0.0;
        defaultEventPriceForMembers.value = price;
        editedData.value = editedData.value.copyWith(
          defaultEventPriceForMembers: price,
        );
        uiControls[fieldKey]?.editedFieldValue = value;
      },
      onUndo: () {
        defaultEventPriceForMembers.value =
            originalData.defaultEventPriceForMembers;
      },
    );
  }

  /// Registers the non-member price control (text field for double).
  void _registerNonMemberPriceControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_nonMemberPrice';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Non-Member Price',
        FontAwesome5Solid.money_bill_wave,
        'The default event price for non-members and visitors.\n\n'
            'This is typically higher than the member price to encourage '
            'membership. You can adjust this for individual runs.',
      ),
      editedFieldValue:
          originalData.defaultEventPriceForNonMembers.toStringAsFixed(2),
      originalFieldValue:
          originalData.defaultEventPriceForNonMembers.toStringAsFixed(2),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Default Event Price for Non-members',
      maxStringLength: 10,
      minStringLength: 1,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      regex: r'^\d+(\.\d{0,2})?$',
      regexErrorString: 'Please enter a valid price (e.g., 9.00)',
      updateEditedValue: (String? value) {
        final price = double.tryParse(value ?? '0') ?? 0.0;
        defaultEventPriceForNonMembers.value = price;
        editedData.value = editedData.value.copyWith(
          defaultEventPriceForNonMembers: price,
        );
        uiControls[fieldKey]?.editedFieldValue = value;
      },
      onUndo: () {
        defaultEventPriceForNonMembers.value =
            originalData.defaultEventPriceForNonMembers;
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Payment Settings Controls
  // ---------------------------------------------------------------------------

  /// Registers the allow negative credit control (switch).
  void _registerAllowNegativeCreditControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_allowNegativeCredit';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Allow Negative Credit',
        FontAwesome5Solid.credit_card,
        'When enabled, hashers can have a negative credit balance.\n\n'
            'This allows them to attend runs even if they haven\'t pre-paid, '
            'with the expectation that they will settle their balance later.',
      ),
      editedFieldValue: (originalData.allowNegativeCredit > 0).toString(),
      originalFieldValue: (originalData.allowNegativeCredit > 0).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Allow negative credit',
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final boolValue = value == 'true';
        allowNegativeCredit.value = boolValue;
        editedData.value = editedData.value.copyWith(
          allowNegativeCredit: boolValue ? 1 : 0,
        );
        uiControls[fieldKey]?.editedFieldValue = value;
      },
      onUndo: () {
        allowNegativeCredit.value = originalData.allowNegativeCredit > 0;
      },
    );
  }

  /// Registers the allow self payment control (switch).
  void _registerAllowSelfPaymentControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_allowSelfPayment';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Self Payment',
        FontAwesome5Solid.hand_holding_usd,
        'When enabled, hashers can mark themselves as paid for a run.\n\n'
            'This is useful for kennels that collect cash at the run and '
            'want hashers to confirm their payment status.',
      ),
      editedFieldValue: (originalData.allowSelfPayment > 0).toString(),
      originalFieldValue: (originalData.allowSelfPayment > 0).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Hasher can mark themselves as paid',
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final boolValue = value == 'true';
        allowSelfPayment.value = boolValue;
        editedData.value = editedData.value.copyWith(
          allowSelfPayment: boolValue ? 1 : 0,
        );
        uiControls[fieldKey]?.editedFieldValue = value;
      },
      onUndo: () {
        allowSelfPayment.value = originalData.allowSelfPayment > 0;
      },
    );
  }
}
