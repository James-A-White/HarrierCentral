import 'package:hcportal/imports.dart';

class TextDropdownField<T extends TabUiController> extends StatelessWidget {
  const TextDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.updateValue,
    required this.controller,
    this.focusNode,
    this.width = double.infinity,
  });

  final String label;
  final RxInt value;
  final Map<int, String> items;
  final void Function(int) updateValue;
  final T controller;
  final FocusNode? focusNode;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Focus(
          focusNode: focusNode,
          child: SizedBox(
            width: width,
            child: DropdownButtonFormField<int>(
              value: value.value,
              decoration: InputDecoration(
                labelText: label,
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
                updateValue(newValue);
                controller.checkIfFormIsDirty();
              },
            ),
          ),
        ));
  }
}
