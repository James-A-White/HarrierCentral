import 'package:hcportal/imports.dart';

/// A stateful widget that encapsulates a Flutter [Checkbox].
/// Optionally supports tri-state behavior (true, false, or null).
class TriStateCheckbox extends StatefulWidget {
  const TriStateCheckbox({
    super.key,
    this.initialValue = false,
    this.tristate = false,
    this.onChanged,
  });

  /// The initial checkbox value (true, false, or null).
  final bool? initialValue;

  /// Whether the checkbox should allow an indeterminate (null) state.
  final bool tristate;

  /// Called when the checkbox value changes.
  final ValueChanged<bool?>? onChanged;

  @override
  TriStateCheckboxState createState() => TriStateCheckboxState();
}

class TriStateCheckboxState extends State<TriStateCheckbox> {
  bool? _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      tristate: widget.tristate,
      value: _currentValue,
      onChanged: (bool? newValue) {
        setState(() {
          _currentValue = newValue ?? false;
        });

        // If an external callback is provided, call it with the new value.
        widget.onChanged?.call(newValue ?? false);
      },
    );
  }
}
