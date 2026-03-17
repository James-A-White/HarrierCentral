import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Editable Dropdown Field Widget
// ---------------------------------------------------------------------------

/// A dropdown field widget with sidebar integration.
///
/// This widget wraps a dropdown selector with [UiControlDefinition] support,
/// enabling contextual help in the sidebar when the user hovers or focuses
/// on the field.
///
/// Features:
/// - Sidebar hover integration for contextual help
/// - Reactive value updates via [RxInt]
/// - Automatic dirty state tracking
class EditableDropdownField<T extends TabUiController> extends StatelessWidget {
  const EditableDropdownField({
    super.key,
    required this.controller,
    required this.uiControl,
    required this.value,
    required this.items,
    this.width,
  });

  /// The parent tab controller for sidebar integration.
  final T controller;

  /// Definition containing field configuration and sidebar data.
  final UiControlDefinition uiControl;

  /// The current selected value (reactive).
  final RxInt value;

  /// Map of value to display label for dropdown items.
  final Map<int, String> items;

  /// Optional fixed width for the dropdown.
  final double? width;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _showSidebarHelp(),
      onExit: (_) => _hideSidebarHelp(),
      child: Focus(
        onFocusChange: (hasFocus) {
          if (hasFocus) {
            _showSidebarHelp();
          } else {
            _hideSidebarHelp();
          }
        },
        child: SizedBox(
          width: width ?? double.infinity,
          child: Obx(() => _buildDropdown()),
        ),
      ),
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

  /// Builds the dropdown form field.
  Widget _buildDropdown() {
    return DropdownButtonFormField<int>(
      key: uiControl.globalKey,
      value: value.value,
      decoration: InputDecoration(
        labelText: uiControl.label,
        labelStyle: bodyStyleBlack,
        floatingLabelStyle: bodyStyleBlack,
        hintStyle: formHintStyle,
        helperStyle: bodyStyleBlack,
      ),
      items: [
        for (final entry in items.entries)
          DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value, style: bodyStyleBlack),
          ),
      ],
      onChanged: (newValue) {
        if (newValue == null) return;
        value.value = newValue;
        uiControl.editedFieldValue = newValue.toString();
        uiControl.updateEditedValue(newValue.toString());
        controller.checkIfFormIsDirty();
      },
    );
  }
}
