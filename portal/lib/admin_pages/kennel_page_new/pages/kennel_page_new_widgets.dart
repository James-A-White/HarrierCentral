/// Kennel Page Form Widgets
///
/// This file contains reusable widget builders for the kennel form.
/// These helper methods create consistent form field widgets that can be
/// used across different tabs in the kennel editing form.

part of '../kennel_page_new_ui.dart';

// ---------------------------------------------------------------------------
// Form Field Builders
// ---------------------------------------------------------------------------

/// Extension providing widget builders for the KennelEditPage.
///
/// These methods create consistent, reusable form widgets that are used
/// across multiple tabs in the kennel editing form.
extension KennelEditWidgetBuilders on KennelEditPage {
  /// Builds an invisible field for validation tracking.
  ///
  /// This is used for fields that need to participate in form validation
  /// but don't have a visible UI element.
  ///
  /// [tabIndex] - The index of the tab containing this field.
  /// [fieldKey] - The unique key for this field in uiControls.
  List<Widget> buildInvisibleField(int tabIndex, String fieldKey) {
    if (controller.uiControls[fieldKey] != null) {
      return [const SizedBox.shrink()];
    }
    return [const SizedBox.shrink()];
  }

  /// Builds a tri-state checkbox field.
  ///
  /// Used for boolean fields that can have three states:
  /// checked, unchecked, or indeterminate.
  ///
  /// [tabIndex] - The index of the tab containing this field.
  /// [fieldKey] - The unique key for this field in uiControls.
  List<Widget> buildCheckboxField(int tabIndex, String fieldKey) {
    final uiControl = controller.uiControls[fieldKey];
    if (uiControl == null) return [const SizedBox.shrink()];

    return [
      TriStateCheckboxField(
        controller: controller,
        uiControl: uiControl,
        onChanged: (_) => controller.checkIfFormIsDirty(),
      ),
      const SizedBox(height: 20),
    ];
  }

  /// Builds an editable text field with optional padding.
  ///
  /// Creates an [EditableOverrideTextField] configured with the
  /// appropriate UI control definition.
  ///
  /// [tabIndex] - The index of the tab containing this field.
  /// [fieldKey] - The unique key for this field in uiControls.
  /// [top], [bottom], [left], [right] - Optional padding values.
  Widget buildTextField(
    int tabIndex,
    String fieldKey, {
    double top = 0.0,
    double bottom = 0.0,
    double left = 0.0,
    double right = 0.0,
  }) {
    final uiControl = controller.uiControls[fieldKey];
    if (uiControl == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
      ),
      child: EditableOverrideTextField(
        controller: controller,
        uiControl: uiControl,
        onChanged: (_) => controller.checkIfFormIsDirty(),
      ),
    );
  }
}
