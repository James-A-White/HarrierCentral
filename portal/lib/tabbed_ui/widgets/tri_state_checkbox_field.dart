import 'package:hcportal/imports.dart';
import 'package:hcportal/tabbed_ui/widgets/sidebar_hover_region.dart';

/// Tri-state checkbox field with sidebar hover and validity updates.
class TriStateCheckboxField extends StatelessWidget {
  const TriStateCheckboxField({
    super.key,
    required this.controller,
    required this.uiControl,
    required this.onChanged,
  });

  final TabUiController controller;
  final UiControlDefinition uiControl;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SidebarHoverRegion(
      controller: controller,
      uiControl: uiControl,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          TriStateCheckbox(
            tristate: true,
            initialValue: uiControl.editedFieldValue == null
                ? null
                : uiControl.editedFieldValue == '1'
                    ? true
                    : false,
            onChanged: (value) {
              final String? encoded = value == null
                  ? null
                  : value
                      ? '1'
                      : '0';
              uiControl.updateEditedValue(encoded);
              onChanged(encoded);
            },
          ),
          Text(uiControl.label, style: bodyStyleBlack),
        ],
      ),
    );
  }
}
