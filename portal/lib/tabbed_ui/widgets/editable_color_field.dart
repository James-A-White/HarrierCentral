import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hcportal/imports.dart';

/// A form field that displays a colour swatch + hex value.
/// Tapping opens a colour picker dialog. The value is stored as a CSS hex
/// string (e.g. `#3a7bd5`). Null means "not set / inherit from theme".
class EditableColorField extends StatelessWidget {
  const EditableColorField({
    super.key,
    required this.controller,
    required this.uiControl,
    required this.onChanged,
  });

  final TabUiController controller;
  final UiControlDefinition uiControl;
  final ValueChanged<String?> onChanged;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static Color? parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceAll('#', '').trim().toLowerCase();
    // Accept #RRGGBB (6) or #RRGGBBAA (8) — alpha is stripped since we store RGB only
    final rgb = clean.length == 8 ? clean.substring(0, 6) : clean;
    if (rgb.length != 6) return null;
    final r = int.tryParse(rgb.substring(0, 2), radix: 16);
    final g = int.tryParse(rgb.substring(2, 4), radix: 16);
    final b = int.tryParse(rgb.substring(4, 6), radix: 16);
    if (r == null || g == null || b == null) return null;
    return Color.fromARGB(255, r, g, b);
  }

  static String colorToHex(Color color) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Color picker dialog
  // ---------------------------------------------------------------------------

  Future<void> _showPicker(BuildContext context) async {
    final tc = uiControl.textController;
    final currentHex =
        (tc != null && tc.text.isNotEmpty) ? tc.text : uiControl.editedFieldValue;
    Color picked = parseHex(currentHex) ?? const Color(0xFF2196F3);

    await showDialog<void>(
      context: context,
      builder: (ctx) => _ColorPickerDialog(
        initial: picked,
        label: uiControl.label,
        onApply: (color) {
          final hex = colorToHex(color);
          if (tc != null) tc.text = hex;
          uiControl.editedFieldValue = hex;
          uiControl.updateEditedValue(hex);
          onChanged(hex);
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tc = uiControl.textController;

    return SidebarHoverRegion(
      controller: controller,
      uiControl: uiControl,
      child: GestureDetector(
        onTap: () => _showPicker(context),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: tc != null
              ? ValueListenableBuilder<TextEditingValue>(
                  valueListenable: tc,
                  builder: (_, value, __) => _FieldRow(
                    label: uiControl.label,
                    hexValue: value.text.isNotEmpty ? value.text : null,
                    onClear: () {
                      tc.clear();
                      uiControl.editedFieldValue = null;
                      uiControl.updateEditedValue(null);
                      onChanged(null);
                    },
                  ),
                )
              : _FieldRow(
                  label: uiControl.label,
                  hexValue: uiControl.editedFieldValue,
                  onClear: () {
                    uiControl.editedFieldValue = null;
                    uiControl.updateEditedValue(null);
                    onChanged(null);
                  },
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Field row (swatch + hex text + clear)
// ---------------------------------------------------------------------------

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.hexValue,
    required this.onClear,
  });

  final String label;
  final String? hexValue;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final color = EditableColorField.parseHex(hexValue);

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: bodyStyleBlack,
        floatingLabelStyle: bodyStyleBlack,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      ),
      child: Row(
        children: [
          _ColorSwatch(color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hexValue ?? 'Not set — click to choose',
              style: bodyStyleBlack.copyWith(
                color: hexValue == null ? Colors.grey.shade500 : null,
                fontStyle:
                    hexValue == null ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
          if (hexValue != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.clear,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Colour swatch square
// ---------------------------------------------------------------------------

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
      ),
      child: color == null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: CustomPaint(painter: _UnsetPainter()),
            )
          : null,
    );
  }
}

class _UnsetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.grey.shade100,
    );
    canvas.drawLine(
      Offset(2, size.height - 2),
      Offset(size.width - 2, 2),
      Paint()
        ..color = Colors.grey.shade400
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ---------------------------------------------------------------------------
// Picker dialog (StatefulWidget so the wheel updates live)
// ---------------------------------------------------------------------------

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({
    required this.initial,
    required this.label,
    required this.onApply,
  });

  final Color initial;
  final String label;
  final ValueChanged<Color> onApply;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.label),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SingleChildScrollView(
        child: ColorPicker(
          pickerColor: _picked,
          onColorChanged: (c) => setState(() => _picked = c),
          enableAlpha: false,
          hexInputBar: true,
          portraitOnly: true,
          colorPickerWidth: 280,
          pickerAreaHeightPercent: 0.75,
          displayThumbColor: true,
          paletteType: PaletteType.hsvWithHue,
          labelTypes: const [],
        ),
      ),
      actions: [
        ElevatedButton(
          style: defaultButtonStyle,
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: buttonLabelStyleMedium),
        ),
        ElevatedButton(
          style: defaultButtonStyle,
          onPressed: () {
            widget.onApply(_picked);
            Navigator.of(context).pop();
          },
          child: Text('Apply', style: buttonLabelStyleMedium),
        ),
      ],
    );
  }
}
