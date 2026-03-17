import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Editable Image Dropdown Field Widget
// ---------------------------------------------------------------------------

/// A dropdown field widget with image icons and sidebar integration.
///
/// This widget displays dropdown items with leading images (e.g., map pins)
/// and integrates with [UiControlDefinition] for contextual sidebar help.
///
/// The images are loaded from assets based on the dropdown item values,
/// using the pattern: `images/map_pins/{color}/future_run_rsvp_none.png`
///
/// Features:
/// - Image icons for each dropdown item
/// - Sidebar hover integration for contextual help
/// - Reactive value updates via [RxInt]
/// - Automatic dirty state tracking
class EditableImageDropdownField<T extends TabUiController>
    extends StatelessWidget {
  const EditableImageDropdownField({
    super.key,
    required this.controller,
    required this.uiControl,
    required this.value,
    this.width,
    this.imageHeight = 45,
    this.imageWidth = 45,
  });

  /// The parent tab controller for sidebar integration.
  final T controller;

  /// Definition containing field configuration and sidebar data.
  final UiControlDefinition uiControl;

  /// The current selected value (reactive).
  final RxInt value;

  /// Optional fixed width for the dropdown.
  final double? width;

  /// Height of the icon images.
  final double imageHeight;

  /// Width of the icon images.
  final double imageWidth;

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

  /// Builds the dropdown form field with image icons.
  Widget _buildDropdown() {
    final items = uiControl.dropdownItems ?? {};

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
      items: items.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Row(
            children: [
              Image.asset(
                'images/map_pins/${entry.value.toLowerCase()}/future_run_rsvp_none.png',
                width: imageWidth,
                height: imageHeight,
              ),
              const SizedBox(width: 20),
              Text(entry.value, style: bodyStyleBlack),
            ],
          ),
        );
      }).toList(),
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
