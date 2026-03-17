/// Payment Page Controls
///
/// This file defines the UI control configurations for the Payment tab.

part of '../../run_edit_page_controller.dart';

// ---------------------------------------------------------------------------
// Control Initialization Extension
// ---------------------------------------------------------------------------

/// Extension that adds payment control initialization to the controller.
extension PaymentControlsExtension on RunEditPageController {
  /// Formats a price value with the correct number of decimal places.
  ///
  /// Uses the kennel's `defaultDigitsAfterDecimal` setting (defaults to 2).
  /// Returns null if the price is null.
  String? _formatPrice(num? price) {
    if (price == null) return null;
    final digits = this.kennelData.defaultDigitsAfterDecimal;
    return price.toDouble().toStringAsFixed(digits);
  }

  /// Initializes all UI controls for the Payment tab.
  void initPaymentControls() {
    final tabKey = RunTabType.payment.key;
    const tabIndex = 6;

    _registerUseCustomPricesControl(tabKey, tabIndex);
    _registerMemberPriceControl(tabKey, tabIndex);
    _registerNonMemberPriceControl(tabKey, tabIndex);
    _registerUseExtrasPricesControl(tabKey, tabIndex);
    _registerExtrasPriceControl(tabKey, tabIndex);
    _registerExtrasDescriptionControl(tabKey, tabIndex);
    _registerExtrasRsvpRequiredControl(tabKey, tabIndex);
  }

  // ---------------------------------------------------------------------------
  // Individual Control Registration
  // ---------------------------------------------------------------------------

  void _registerUseCustomPricesControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunPaymentField.useCustomPrices.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Use Custom Pricing',
        FontAwesome5Solid.money_bill,
        'Enable this to set custom prices for this run instead of using '
            'the kennel defaults.\n\n'
            'When disabled, the kennel\'s default member and non-member '
            'prices will be used.',
      ),
      editedFieldValue: useCustomPricing.value.toString(),
      originalFieldValue: ((originalData.eventPriceForMembers != null) ||
              (originalData.eventPriceForNonMembers != null))
          .toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Use custom pricing for this run',
      tabIndex: tabIndex,
      updateEditedValue: (dynamic value) {
        if (value is bool) {
          useCustomPricing.value = value;
          uiControls[fieldKey]?.editedFieldValue = value.toString();
        }
      },
    );
  }

  void _registerMemberPriceControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunPaymentField.memberPrice.name}';

    final digits = this.kennelData.defaultDigitsAfterDecimal;
    final isOverridden = originalData.eventPriceForMembers != null;
    final defaultPrice =
        _formatPrice(this.kennelData.defaultEventPriceForMembers);
    final overrideValue = _formatPrice(originalData.eventPriceForMembers);

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.intValue,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Member Price',
        FontAwesome5Solid.user_check,
        'Set the price for kennel members.\n\n'
            'Use the pencil icon to set a custom price for this run, '
            'or use the checkbox to use the kennel default price.',
      ),
      editedFieldValue: overrideValue,
      originalFieldValue: overrideValue,
      lookthroughValue: defaultPrice,
      lookthroughLabel: 'Kennel default member price',
      isOverridden: isOverridden,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Member price',
      maxStringLength: 10,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: true,
      regex: '^\\d+(\\.\\d{1,$digits})?\$',
      regexErrorString:
          'Please enter a valid price with up to $digits decimal places',
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        // Handle reset to lookthrough (kennel default) value
        if (value == RESET_TO_LOOKTHROUGH_VALUE) {
          editedData.value =
              editedData.value.copyWith(eventPriceForMembers: null);
          uiControls[fieldKey]?.editedFieldValue = null;
          uiControls[fieldKey]?.isOverridden = false;
          checkIfFormIsDirty();
          return;
        }

        final price = double.tryParse(value ?? '');
        editedData.value =
            editedData.value.copyWith(eventPriceForMembers: price);
        uiControls[fieldKey]?.editedFieldValue = value;
        uiControls[fieldKey]?.isOverridden = (price != null);
        checkIfFormIsDirty();
      },
    );
  }

  void _registerNonMemberPriceControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunPaymentField.nonMemberPrice.name}';

    final digits = this.kennelData.defaultDigitsAfterDecimal;
    final isOverridden = originalData.eventPriceForNonMembers != null;
    final defaultPrice =
        _formatPrice(this.kennelData.defaultEventPriceForNonMembers);
    final overrideValue = _formatPrice(originalData.eventPriceForNonMembers);

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.intValue,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Non-Member Price',
        FontAwesome5Solid.user,
        'Set the price for non-members.\n\n'
            'Use the pencil icon to set a custom price for this run, '
            'or use the checkbox to use the kennel default price.',
      ),
      editedFieldValue: overrideValue,
      originalFieldValue: overrideValue,
      lookthroughValue: defaultPrice,
      lookthroughLabel: 'Kennel default non-member price',
      isOverridden: isOverridden,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Non-member price',
      maxStringLength: 10,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: true,
      regex: '^\\d+(\\.\\d{1,$digits})?\$',
      regexErrorString:
          'Please enter a valid price with up to $digits decimal places',
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        // Handle reset to lookthrough (kennel default) value
        if (value == RESET_TO_LOOKTHROUGH_VALUE) {
          editedData.value =
              editedData.value.copyWith(eventPriceForNonMembers: null);
          uiControls[fieldKey]?.editedFieldValue = null;
          uiControls[fieldKey]?.isOverridden = false;
          checkIfFormIsDirty();
          return;
        }

        final price = double.tryParse(value ?? '');
        editedData.value =
            editedData.value.copyWith(eventPriceForNonMembers: price);
        uiControls[fieldKey]?.editedFieldValue = value;
        uiControls[fieldKey]?.isOverridden = (price != null);
        checkIfFormIsDirty();
      },
    );
  }

  void _registerUseExtrasPricesControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunPaymentField.useExtrasPrices.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Include Extra Charges',
        FontAwesome5Solid.plus_circle,
        'Enable this if the run includes optional extra charges.\n\n'
            'Examples: dinner after the run, commemorative t-shirt, etc.',
      ),
      editedFieldValue: useExtrasPricing.value.toString(),
      originalFieldValue: (originalData.eventPriceForExtras != null).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'This run includes optional extra charges',
      tabIndex: tabIndex,
      updateEditedValue: (dynamic value) {
        if (value is bool) {
          useExtrasPricing.value = value;
          uiControls[fieldKey]?.editedFieldValue = value.toString();
        }
      },
    );
  }

  void _registerExtrasPriceControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunPaymentField.extrasPrice.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.intValue,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Extras Price',
        FontAwesome5Solid.receipt,
        'Set the price for the optional extras.',
      ),
      editedFieldValue: editedData.value.eventPriceForExtras?.toString(),
      originalFieldValue: originalData.eventPriceForExtras?.toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Extras price',
      maxStringLength: 10,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        final price = double.tryParse(value ?? '');
        editedData.value =
            editedData.value.copyWith(eventPriceForExtras: price);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerExtrasDescriptionControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunPaymentField.extrasDescription.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.string,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Extras Description',
        MaterialCommunityIcons.text_box_outline,
        'Describe what the extras include.\n\n'
            'Example: "Dinner at the pub after the run" or "Event t-shirt"',
      ),
      editedFieldValue: editedData.value.extrasDescription,
      originalFieldValue: originalData.extrasDescription,
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Extras description',
      maxStringLength: 200,
      minStringLength: 0,
      maxLines: 1,
      includeOverrideButton: false,
      textController: textControllers[fieldKey] = TextEditingController(),
      tabIndex: tabIndex,
      updateEditedValue: (String? value) {
        editedData.value = editedData.value.copyWith(extrasDescription: value);
        uiControls[fieldKey]?.editedFieldValue = value;
      },
    );
  }

  void _registerExtrasRsvpRequiredControl(String tabKey, int tabIndex) {
    final fieldKey = '${tabKey}_${RunPaymentField.extrasRsvpRequired.name}';

    uiControls[fieldKey] = UiControlDefinition(
      controlType: UiControlType.checkbox,
      sidebarEntryKey: fieldKey,
      sidebarExitKey: '${tabKey}_generic',
      sidebarData: const SideBarData(
        'Require RSVP for Extras',
        FontAwesome5Solid.hand_paper,
        'When enabled, hashers must RSVP if they want the extras.\n\n'
            'This helps with planning and ordering.',
      ),
      editedFieldValue: (editedData.value.extrasRsvpRequired != 0).toString(),
      originalFieldValue: (originalData.extrasRsvpRequired != 0).toString(),
      globalKey: GlobalKey<FormFieldState>(),
      label: 'Require Hashers to RSVP for extras',
      tabIndex: tabIndex,
      updateEditedValue: (dynamic value) {
        if (value is bool) {
          editedData.value =
              editedData.value.copyWith(extrasRsvpRequired: value ? 1 : 0);
          uiControls[fieldKey]?.editedFieldValue = value.toString();
        }
      },
    );
  }
}
