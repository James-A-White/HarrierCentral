import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Override Field Controller
// ---------------------------------------------------------------------------

/// Controller for managing override text field state.
///
/// This controller handles the logic for fields that can optionally override
/// a default "lookthrough" value. When the override checkbox is unchecked,
/// the field displays the lookthrough value in a read-only state.
class _OverrideFieldController extends GetxController {
  _OverrideFieldController({
    required this.uiControl,
    required this.onChanged,
  });

  final UiControlDefinition uiControl;
  final ValueChanged<String?> onChanged;

  /// Whether the user has chosen to override the default value.
  late final RxBool isOverrideEnabled;

  /// Tracks the last user-entered value (for restoring after toggle).
  String _lastUserValue = '';

  /// Tracks the last known editedFieldValue to detect external changes (like undo).
  String? _lastKnownEditedValue;

  /// Tracks whether this controller has been initialized.
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    _initializeState();
  }

  /// Initializes the controller state based on the UI control's values.
  void _initializeState() {
    if (_isInitialized) return;
    _isInitialized = true;

    final shouldOverride = _shouldShowAsOverridden();
    isOverrideEnabled = shouldOverride.obs;

    // Store the current edited value as the user's value
    _lastUserValue = uiControl.editedFieldValue ?? '';
    _lastKnownEditedValue = uiControl.editedFieldValue;

    // Set initial display text
    _updateDisplayText();
  }

  /// Checks if external changes (like undo) have occurred and resyncs if needed.
  ///
  /// This is called on each widget build to detect when the underlying
  /// data has changed outside of this controller (e.g., via undo).
  void checkForExternalChanges() {
    final currentEditedValue = uiControl.editedFieldValue;

    // If the edited value changed externally, resync our state
    if (currentEditedValue != _lastKnownEditedValue) {
      _resyncState();
      _lastKnownEditedValue = currentEditedValue;
    }
  }

  /// Resyncs the controller state to match the current UI control values.
  void _resyncState() {
    final shouldOverride = _shouldShowAsOverridden();
    isOverrideEnabled.value = shouldOverride;

    // Update the cached user value from the control
    _lastUserValue = uiControl.editedFieldValue ?? '';

    _updateDisplayText();
  }

  /// Determines if the field should display as overridden.
  ///
  /// A field is considered overridden when:
  /// - The explicit isOverridden flag is set to true, OR
  /// - It has an edited value that differs from the lookthrough value, OR
  /// - It has an original value that differs from the lookthrough value
  bool _shouldShowAsOverridden() {
    // If explicit override flag is set, use it
    if (uiControl.isOverridden != null) {
      return uiControl.isOverridden!;
    }

    // If no lookthrough value, there's nothing to override
    if (uiControl.lookthroughValue == null) {
      return false;
    }

    final edited = uiControl.editedFieldValue;
    final original = uiControl.originalFieldValue;
    final lookthrough = uiControl.lookthroughValue;

    // If edited value exists and differs from lookthrough, it's overridden
    if (edited != null && edited.isNotEmpty && edited != lookthrough) {
      return true;
    }

    // If original value differs from lookthrough, it was previously overridden
    if (original != null && original.isNotEmpty && original != lookthrough) {
      return true;
    }

    return false;
  }

  /// Updates the text controller to show the appropriate value.
  void _updateDisplayText() {
    if (uiControl.textController == null) return;

    if (isOverrideEnabled.value) {
      // Show the user's override value
      final valueToShow = _lastUserValue.isNotEmpty
          ? _lastUserValue
          : (uiControl.editedFieldValue ?? uiControl.originalFieldValue ?? '');
      uiControl.textController!.text = valueToShow;
    } else if (uiControl.lookthroughValue != null) {
      // Show the lookthrough (default) value
      uiControl.textController!.text = uiControl.lookthroughValue!;
    }
  }

  /// Called when the override checkbox is toggled.
  void onOverrideToggled(bool? enabled) {
    final isEnabled = enabled ?? false;
    isOverrideEnabled.value = isEnabled;

    if (isEnabled) {
      // User wants to override - keep the current displayed value editable
      // If no previous user value, use the lookthrough value as starting point
      final valueToUse = _lastUserValue.isNotEmpty
          ? _lastUserValue
          : (uiControl.lookthroughValue ?? '');
      uiControl.textController!.text = valueToUse;
      _lastUserValue = valueToUse; // Track this as the user's value now
      _notifyValueChanged(valueToUse);
    } else {
      // User unchecked override - revert to lookthrough value
      uiControl.textController!.text =
          uiControl.lookthroughValue ?? _lastUserValue;
      _notifyValueChanged(RESET_TO_LOOKTHROUGH_VALUE);
    }

    // Update the tracked value after toggle
    _lastKnownEditedValue = uiControl.editedFieldValue;
  }

  /// Called when user types in the text field.
  void onTextChanged(String value) {
    _lastUserValue = value;
    _notifyValueChanged(value);
    _lastKnownEditedValue = uiControl.editedFieldValue;
  }

  /// Notifies the parent of a value change.
  void _notifyValueChanged(String value) {
    String? valueToSave = value;

    // If the value matches lookthrough, treat as "not overridden"
    if (value == uiControl.lookthroughValue) {
      valueToSave = uiControl.originalFieldValue;
    }

    uiControl.updateEditedValue(valueToSave);
    onChanged(valueToSave);
  }
}

// ---------------------------------------------------------------------------
// Editable Override Text Field Widget
// ---------------------------------------------------------------------------

/// A text field widget with optional override functionality.
///
/// When [UiControlDefinition.includeOverrideButton] is true, this widget
/// displays a checkbox that allows the user to override a default
/// "lookthrough" value. When unchecked, the field shows the lookthrough
/// value in a read-only, dimmed state.
///
/// Features:
/// - Sidebar hover integration for contextual help
/// - Override toggle with visual feedback
/// - Automatic validation
/// - Support for multi-line text
class EditableOverrideTextField extends StatelessWidget {
  const EditableOverrideTextField({
    super.key,
    required this.controller,
    required this.uiControl,
    required this.onChanged,
    this.expandToFill = false,
  });

  /// The parent tab controller for sidebar integration.
  final TabUiController controller;

  /// Definition containing field configuration and state.
  final UiControlDefinition uiControl;

  /// Callback when the field value changes.
  final ValueChanged<String?> onChanged;

  /// When true, the text field expands to fill available vertical space.
  final bool expandToFill;

  @override
  Widget build(BuildContext context) {
    // Use a unique tag based on the global key to ensure proper controller reuse
    final controllerTag = 'override_${uiControl.globalKey.hashCode}';

    // Get or create the field controller
    final fieldController = Get.put(
      _OverrideFieldController(uiControl: uiControl, onChanged: onChanged),
      tag: controllerTag,
    );

    // Check if the underlying data changed (e.g., via undo) and resync if needed
    fieldController.checkForExternalChanges();

    return MouseRegion(
      onEnter: (_) => _showSidebarHelp(),
      onExit: (_) => _hideSidebarHelp(),
      child: Obx(() => _buildFieldRow(fieldController)),
    );
  }

  /// Shows contextual help in the sidebar.
  void _showSidebarHelp() {
    controller.setSidebarData(
      uiControl.sidebarEntryKey,
      sidebarData: uiControl.sidebarData,
    );
  }

  /// Hides the sidebar help.
  void _hideSidebarHelp() {
    controller.setSidebarData(uiControl.sidebarExitKey);
  }

  /// Builds the main field row with optional override checkbox.
  Widget _buildFieldRow(_OverrideFieldController fieldController) {
    final isEditable = fieldController.isOverrideEnabled.value ||
        !uiControl.includeOverrideButton;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Override checkbox (if enabled)
        if (uiControl.includeOverrideButton) ...[
          PencilCheckbox(
            isChecked: fieldController.isOverrideEnabled.value,
            onChanged: fieldController.onOverrideToggled,
          ),
          const SizedBox(width: 20),
        ],

        // Show static text when not overriding, or text field when editing
        Expanded(
          child: isEditable
              ? _buildTextField(fieldController, isEditable)
              : _buildLookthroughDisplay(),
        ),
      ],
    );
  }

  /// Builds a static display showing the lookthrough (default) value.
  Widget _buildLookthroughDisplay() {
    final label = uiControl.lookthroughLabel ?? uiControl.label;
    final value = uiControl.lookthroughValue ?? '';

    // If there's no meaningful value, show just the label (e.g., "Run number
    // auto-assigned on save" rather than "...on save: ")
    final displayText = value.isEmpty ? label : '$label: $value';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        displayText,
        style: bodyStyleBlack.copyWith(
          color: Colors.grey.shade700,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  /// Builds the text form field.
  Widget _buildTextField(
    _OverrideFieldController fieldController,
    bool isEditable,
  ) {
    return TextFormField(
      key: uiControl.globalKey,
      controller: uiControl.textController,
      readOnly: _isReadOnly(isEditable),
      autovalidateMode: AutovalidateMode.always,
      onChanged: fieldController.onTextChanged,
      validator: (_) => uiControl.updateValidity().userFeedback,
      maxLines: expandToFill ? null : uiControl.maxLines,
      expands: expandToFill,
      textAlignVertical: expandToFill ? TextAlignVertical.top : null,
      style: _getTextStyle(isEditable),
      decoration: _buildDecoration(),
    );
  }

  /// Determines if the field should be read-only.
  bool _isReadOnly(bool isEditable) {
    if (uiControl.includeOverrideButton) {
      return !isEditable;
    }
    return uiControl.readonly ?? false;
  }

  /// Gets the text style based on edit state.
  TextStyle _getTextStyle(bool isEditable) {
    final isReadOnly = uiControl.readonly ?? false;

    return bodyStyleBlack.copyWith(
      fontWeight:
          isEditable && !isReadOnly ? FontWeight.bold : FontWeight.normal,
      color: isReadOnly ? Colors.grey : null,
    );
  }

  /// Builds the input decoration for the text field.
  InputDecoration _buildDecoration() {
    final useOutlineBorder = expandToFill || uiControl.maxLines != 1;
    return InputDecoration(
      labelStyle: formHintStyle,
      hintStyle: formHintStyle,
      labelText: uiControl.label,
      hintText: uiControl.label,
      errorStyle: errorSmallRed,
      helperText: ' ',
      helperStyle: errorSmallRed,
      floatingLabelStyle: bodyStyleBlack,
      alignLabelWithHint: expandToFill,
      border: useOutlineBorder
          ? const OutlineInputBorder()
          : const UnderlineInputBorder(),
    );
  }
}
