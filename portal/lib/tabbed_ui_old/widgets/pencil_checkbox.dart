import 'package:hcportal/imports.dart';

/// A checkbox widget that displays a pencil icon when checked.
///
/// Uses reactive state management via the parent's [RxBool] value.
/// The checkbox animates between an empty checkbox and a pencil icon.
class PencilCheckbox extends StatelessWidget {
  const PencilCheckbox({
    required this.isChecked,
    required this.onChanged,
    super.key,
  });

  /// The current checked state (reactive).
  final bool isChecked;

  /// Callback when the checkbox is toggled.
  final ValueChanged<bool?> onChanged;

  void _toggleCheckbox() {
    onChanged(!isChecked);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleCheckbox,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: isChecked
            ? const Icon(Icons.edit,
                key: ValueKey('pencil'), color: Colors.blue)
            : const Icon(Icons.check_box_outline_blank,
                color: Colors.black, key: ValueKey('checkbox')),
      ),
    );
  }
}
