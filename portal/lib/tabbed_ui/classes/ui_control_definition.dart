import 'package:hcportal/imports.dart';

class ValidatorResult {
  const ValidatorResult({
    required this.validity,
    required this.controlIsValid,
    this.userFeedback,
  });

  final ControlValidity validity;
  final bool controlIsValid;
  final String? userFeedback;
}

class UiControlDefinition<T> {
  UiControlDefinition({
    required this.controlType,
    required this.sidebarEntryKey,
    required this.editedFieldValue,
    required this.originalFieldValue,
    required this.globalKey,
    required this.label,
    required this.sidebarExitKey,
    required this.updateEditedValue,
    required this.tabIndex,
    this.lookthroughValue,
    this.lookthroughLabel,
    this.isOverridden,
    this.fileType = DocumentType.none,
    this.textController,
    this.includeOverrideButton = false,
    this.maxStringLength = 10000,
    this.minStringLength = 0,
    this.dunsValue,
    this.controlValidity = const ValidatorResult(
        validity: ControlValidity.unknown,
        userFeedback: null,
        controlIsValid: true),
    this.maxLines = 1,
    this.readonly = false,
    this.regex,
    this.regexErrorString,
    this.allowEmpty = false,
    this.sidebarData,
    this.onUndo,
    this.dropdownItems,
    this.onPressed,
    this.buttonIcon,
    this.expandToFillSpace = false,
    this.minHeight,
  });

  final UiControlType controlType;
  final String sidebarEntryKey;
  final String sidebarExitKey;
  final String label;
  final GlobalKey globalKey;
  final DocumentType fileType;
  final bool includeOverrideButton;
  final int tabIndex;
  final int maxLines;
  Function updateEditedValue;
  final String? dunsValue;
  final String? originalFieldValue;
  final String? lookthroughValue;
  final String? lookthroughLabel;
  final int? maxStringLength;
  final int? minStringLength;
  final TextEditingController? textController;
  final bool? readonly;

  /// Explicit flag indicating whether the field value is overriding the lookthrough.
  /// If provided, this takes precedence over value-comparison logic.
  /// - true: Field is explicitly overridden (show as editable)
  /// - false: Field is using the lookthrough/default value
  /// - null: Use default value-comparison logic
  bool? isOverridden;

  String? editedFieldValue;
  ValidatorResult controlValidity;
  String? regex;
  String? regexErrorString;

  /// When true, an empty/blank value is treated as valid regardless of
  /// [minStringLength]. Non-empty values are still validated normally
  /// (length bounds + regex). Useful for optional lat/long fields.
  final bool allowEmpty;

  SideBarData? sidebarData;

  /// Optional callback invoked when undo is called.
  /// Use this for non-text controls (like dropdowns) that need custom undo logic.
  final VoidCallback? onUndo;

  /// Optional items for dropdown controls.
  /// Maps int values to display labels.
  final Map<int, String>? dropdownItems;

  /// Optional callback for button controls.
  /// Invoked when the button is pressed.
  final VoidCallback? onPressed;

  /// Optional icon for button controls.
  final IconData? buttonIcon;

  /// When true, this control will expand to fill any remaining vertical space.
  /// Works in conjunction with [minHeight] to ensure a minimum size.
  final bool expandToFillSpace;

  /// Minimum height constraint for the control when [expandToFillSpace] is true.
  /// The control will not shrink below this height; scrolling takes precedence.
  final double? minHeight;

  // void setDefaultValue()
  // {
  //   editedValue = originalValue;
  //   if (textController != null) {
  //     textController!.text = originalValue ?? '';
  //   }
  // }

  ValidatorResult updateValidity() {
    ControlValidity validity = ControlValidity.unknown;
    String? userFeedback;
    bool controlIsValid = true;

    // For non-text controls (dropdowns, etc.), use editedFieldValue directly
    final String valueToCheck = textController?.text ?? editedFieldValue ?? '';
    final int dataLength = valueToCheck.length;

    // Handle dropdown/selection controls differently
    if (controlType == UiControlType.dropdown ||
        controlType == UiControlType.checkbox) {
      // Dropdown/checkbox is valid if it has a value set
      if (editedFieldValue != null && editedFieldValue!.isNotEmpty) {
        validity = ControlValidity.valid;
      } else {
        // Check if a value is required
        if ((minStringLength ?? 0) > 0) {
          validity = ControlValidity.invalidEmpty;
          controlIsValid = false;
          userFeedback = 'You must select a value for $label.';
        } else {
          validity = ControlValidity.validEmpty;
        }
      }
    } else {
      // Text-based and intValue control validation
      if (dataLength == 0) {
        if (allowEmpty || (minStringLength ?? 0) == 0) {
          validity = ControlValidity.validEmpty;
        } else {
          validity = ControlValidity.invalidEmpty;
          controlIsValid = false;
          userFeedback = 'You must provide a value for $label.';
        }
      } else {
        if ((minStringLength ?? 0) > dataLength) {
          validity = ControlValidity.invalid;
          userFeedback =
              'You must provide a value greater than $minStringLength characters in length';
          controlIsValid = false;
        } else if ((maxStringLength ?? 0) < dataLength) {
          validity = ControlValidity.invalid;
          userFeedback =
              'You must provide a value less than $maxStringLength characters in length';
          controlIsValid = false;
        } else {
          validity = ControlValidity.valid;
        }
      }

      // Check regex if applicable
      if (controlIsValid &&
          regex != null &&
          valueToCheck.isNotEmpty &&
          !valueToCheck.isBlank!) {
        final RegExp regExp = RegExp(regex!);
        if (!regExp.hasMatch(valueToCheck)) {
          controlIsValid = false;
          userFeedback = regexErrorString;
          validity = ControlValidity.invalid;
        }
      }
    }

    controlValidity = ValidatorResult(
      validity: validity,
      userFeedback: userFeedback,
      controlIsValid: controlIsValid,
    );

    return controlValidity;
  }

  void undo() {
    editedFieldValue = originalFieldValue;
    if (textController != null) {
      // If using override button and not overridden, show lookthrough value
      if (includeOverrideButton &&
          lookthroughValue != null &&
          (originalFieldValue == null ||
              originalFieldValue == lookthroughValue ||
              originalFieldValue!.isEmpty)) {
        textController!.text = lookthroughValue!;
      } else {
        textController!.text = originalFieldValue ?? '';
      }
    }

    // Call custom undo callback for non-text controls (e.g., dropdowns)
    onUndo?.call();
  }

  void populateTextEditingControl() {
    if (textController != null) {
      textController!.text = editedFieldValue ?? '';
    }
  }
}
