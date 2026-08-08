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
    _registerAllowCreditControl(tabKey, tabIndex);
    _registerAllowNegativeCreditControl(tabKey, tabIndex);
    _registerAllowSelfPaymentControl(tabKey, tabIndex);

    // Membership (see docs/membership_payments_plan.md)
    _registerMembershipRenewalModeControl(tabKey, tabIndex);
    _registerMembershipPriceControl(tabKey, tabIndex);
    _registerMembershipDurationControl(tabKey, tabIndex);
    _registerMembershipPeriodDateControl(
      tabKey,
      tabIndex,
      fieldName: 'membershipPeriodStartDate',
      title: 'Membership Year Start',
      label: 'Membership year starts (YYYY-MM-DD)',
      help:
          'Fixed-year mode only: the first day of your kennel\'s membership '
          'year. Informational — payments always extend to the end date.',
      original: originalData.membershipPeriodStartDate,
      apply: (DateTime? d) => editedData.value =
          editedData.value.copyWith(membershipPeriodStartDate: d),
    );
    _registerMembershipPeriodDateControl(
      tabKey,
      tabIndex,
      fieldName: 'membershipPeriodEndDate',
      title: 'Membership Year End',
      label: 'Membership year ends (YYYY-MM-DD)',
      help:
          'Fixed-year mode only: the last day of your kennel\'s membership '
          'year. Every membership payment extends to this date, and charging '
          'is refused once it has passed until you update it.',
      original: originalData.membershipPeriodEndDate,
      apply: (DateTime? d) => editedData.value =
          editedData.value.copyWith(membershipPeriodEndDate: d),
    );
  }

  // ---------------------------------------------------------------------------
  // Membership Controls
  // ---------------------------------------------------------------------------

  /// Registers the membership renewal mode dropdown.
  void _registerMembershipRenewalModeControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_membershipRenewalMode';

    membershipRenewalMode.value = originalData.membershipRenewalMode;

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.dropdown,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Membership Renewal',
        FontAwesome5Solid.id_card,
        'How membership payments extend a member\'s expiration date.\n\n'
            'Rolling: each payment adds the membership duration, stacking '
            'on whatever time remains.\n\n'
            'Fixed year: everyone\'s membership runs to the same end date '
            '(set the year below).\n\n'
            'Lifetime: one payment, membership never expires.',
      ),
      editedFieldValue: originalData.membershipRenewalMode.toString(),
      originalFieldValue: originalData.membershipRenewalMode.toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Renewal mode',
      includeOverrideButton: false,
      tabIndex: tabIndex,
      dropdownItems: const {
        1: 'Rolling (adds duration)',
        2: 'Fixed membership year',
        3: 'Lifetime',
      },
      updateEditedValue: (String? value) {
        final intValue = (int.tryParse(value ?? '1') ?? 1).clamp(1, 3);
        membershipRenewalMode.value = intValue;
        editedData.value = editedData.value.copyWith(
          membershipRenewalMode: intValue,
        );
        uiControls[fieldKey]?.editedFieldValue = value;
      },
      onUndo: () {
        membershipRenewalMode.value = originalData.membershipRenewalMode;
      },
    );
  }

  /// Registers the membership price control.
  void _registerMembershipPriceControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_membershipPrice';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Membership Fee',
        FontAwesome5Solid.money_check_alt,
        'The default annual membership fee.\n\n'
            'Pre-filled in the app\'s "Charge membership" dialog; the admin '
            'taking the payment can still adjust it per charge.',
      ),
      editedFieldValue: originalData.membershipPrice.toStringAsFixed(2),
      originalFieldValue: originalData.membershipPrice.toStringAsFixed(2),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Membership fee',
      maxStringLength: 10,
      minStringLength: 1,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      regex: r'^\d+(\.\d{0,2})?$',
      regexErrorString: 'Please enter a valid fee (e.g., 20.00)',
      updateEditedValue: (String? value) {
        final price = double.tryParse(value ?? '0') ?? 0.0;
        editedData.value = editedData.value.copyWith(membershipPrice: price);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  /// Registers the membership duration control (rolling mode).
  void _registerMembershipDurationControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_membershipDurationInMonths';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Membership Duration',
        FontAwesome5Solid.hourglass_half,
        'Rolling mode only: how many months each membership payment adds.\n\n'
            'Typically 12 for an annual membership.',
      ),
      editedFieldValue: originalData.membershipDurationInMonths.toString(),
      originalFieldValue: originalData.membershipDurationInMonths.toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Months per payment',
      maxStringLength: 3,
      minStringLength: 1,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      regex: r'^\d{1,3}$',
      regexErrorString: 'Enter a whole number of months (e.g., 12)',
      updateEditedValue: (String? value) {
        final months = int.tryParse(value ?? '12') ?? 12;
        editedData.value = editedData.value.copyWith(
          membershipDurationInMonths: months,
        );
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  /// Registers a membership-year date control (fixed-year mode).
  void _registerMembershipPeriodDateControl(
    String tabKey,
    int tabIndex, {
    required String fieldName,
    required String title,
    required String label,
    required String help,
    required DateTime? original,
    required void Function(DateTime?) apply,
  }) {
    final fieldKey = '${tabKey}_$fieldName';
    final String originalText = original == null
        ? ''
        : original.toIso8601String().substring(0, 10);

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: SideBarData(title, FontAwesome5Solid.calendar_alt, help),
      editedFieldValue: originalText,
      originalFieldValue: originalText,
      globalKey: GlobalKey<FormFieldState>(),
      label: label,
      maxStringLength: 10,
      minStringLength: 0,
      maxLines: 1,
      allowEmpty: true,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      regex: r'^(\d{4}-\d{2}-\d{2})?$',
      regexErrorString: 'Use YYYY-MM-DD (e.g., 2027-03-31)',
      updateEditedValue: (String? value) {
        apply(DateTime.tryParse(value ?? ''));
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
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
  void _registerAllowCreditControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_allowCredit';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Allow Credit Payments',
        FontAwesome5Solid.credit_card,
        'When enabled, hashers can pay using hash credit and the Credit '
            'option appears on the payment screen.\n\n'
            'Turn this off if your kennel does not use a credit system — the '
            'credit payment option will be hidden.',
      ),
      editedFieldValue: (originalData.allowCredit > 0).toString(),
      originalFieldValue: (originalData.allowCredit > 0).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Allow credit payments',
      includeOverrideButton: false,
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final boolValue = value == 'true';
        allowCredit.value = boolValue;
        editedData.value = editedData.value.copyWith(
          allowCredit: boolValue ? 1 : 0,
        );
        uiControls[fieldKey]?.editedFieldValue = value;
      },
      onUndo: () {
        allowCredit.value = originalData.allowCredit > 0;
      },
    );
  }

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
