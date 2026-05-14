import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hcportal/imports.dart';

/// A form field that displays a colour swatch + hex value.
/// Tapping opens a colour picker dialog. The value is stored as a CSS hex
/// string — 6-digit `#RRGGBB` when [enableAlpha] is false, 8-digit
/// `#RRGGBBAA` when true. Null means "not set / inherit from theme".
class EditableColorField extends StatelessWidget {
  const EditableColorField({
    super.key,
    required this.controller,
    required this.uiControl,
    required this.onChanged,
    this.enableAlpha = false,
  });

  final TabUiController controller;
  final UiControlDefinition uiControl;
  final ValueChanged<String?> onChanged;

  /// When true the colour picker shows an alpha slider and the stored value
  /// uses 8-digit hex (#RRGGBBAA). Use for surface / overlay colours where
  /// opacity is meaningful. Leave false for text and brand colours.
  final bool enableAlpha;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Parses a 6- or 8-digit CSS hex string into a [Color].
  /// Alpha is preserved for 8-digit values.
  static Color? parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final clean = hex.replaceAll('#', '').trim().toLowerCase();
    if (clean.length == 8) {
      final r = int.tryParse(clean.substring(0, 2), radix: 16);
      final g = int.tryParse(clean.substring(2, 4), radix: 16);
      final b = int.tryParse(clean.substring(4, 6), radix: 16);
      final a = int.tryParse(clean.substring(6, 8), radix: 16);
      if (r == null || g == null || b == null || a == null) return null;
      return Color.fromARGB(a, r, g, b);
    }
    if (clean.length == 6) {
      final r = int.tryParse(clean.substring(0, 2), radix: 16);
      final g = int.tryParse(clean.substring(2, 4), radix: 16);
      final b = int.tryParse(clean.substring(4, 6), radix: 16);
      if (r == null || g == null || b == null) return null;
      return Color.fromARGB(255, r, g, b);
    }
    return null;
  }

  static String colorToHex(Color color, {bool includeAlpha = false}) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    final hex = '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
    if (!includeAlpha) return hex;
    final a = (color.a * 255).round();
    return '$hex${a.toRadixString(16).padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------------------
  // Color picker dialog
  // ---------------------------------------------------------------------------

  void _clearValue(TextEditingController? tc) {
    if (tc != null) tc.clear();
    uiControl.editedFieldValue = null;
    uiControl.updateEditedValue(null);
    onChanged(null);
  }

  Future<void> _showPicker(BuildContext context) async {
    final tc = uiControl.textController;
    final currentHex =
        (tc != null && tc.text.isNotEmpty) ? tc.text : uiControl.editedFieldValue;
    final Color initial = parseHex(currentHex) ?? const Color(0xFF2196F3);

    await showDialog<void>(
      context: context,
      builder: (ctx) => _ColorPickerDialog(
        initial: initial,
        label: uiControl.label,
        enableAlpha: enableAlpha,
        onApply: (color) {
          final hex = colorToHex(color, includeAlpha: enableAlpha);
          if (tc != null) tc.text = hex;
          uiControl.editedFieldValue = hex;
          uiControl.updateEditedValue(hex);
          onChanged(hex);
        },
        onUseDefault: () => _clearValue(tc),
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
                  builder: (_, value, _) => _FieldRow(
                    label: uiControl.label,
                    hexValue: value.text.isNotEmpty ? value.text : null,
                    onClear: () => _clearValue(tc),
                  ),
                )
              : _FieldRow(
                  label: uiControl.label,
                  hexValue: uiControl.editedFieldValue,
                  onClear: () => _clearValue(null),
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
// Colour swatch square — checkered background reveals transparency
// ---------------------------------------------------------------------------

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({this.color});
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
      ),
      child: color == null
          ? CustomPaint(painter: _UnsetPainter())
          : Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: _CheckerPainter()),
                ColoredBox(color: color!),
              ],
            ),
    );
  }
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cell = 6.0;
    final paint = Paint();
    var row = 0;
    for (var y = 0.0; y < size.height; y += cell, row++) {
      var col = 0;
      for (var x = 0.0; x < size.width; x += cell, col++) {
        paint.color =
            (row + col).isEven ? Colors.white : Colors.grey.shade300;
        canvas.drawRect(Rect.fromLTWH(x, y, cell, cell), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
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
    required this.enableAlpha,
    required this.onApply,
    required this.onUseDefault,
  });

  final Color initial;
  final String label;
  final bool enableAlpha;
  final ValueChanged<Color> onApply;
  final VoidCallback onUseDefault;

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
          enableAlpha: widget.enableAlpha,
          hexInputBar: true,
          portraitOnly: true,
          colorPickerWidth: 280,
          pickerAreaHeightPercent: 0.75,
          displayThumbColor: true,
          paletteType: PaletteType.hsvWithHue,
          labelTypes: const [],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>(
              (states) => states.contains(WidgetState.disabled)
                  ? Colors.grey
                  : Colors.blueGrey.shade400,
            ),
            foregroundColor:
                WidgetStateProperty.all<Color>(Colors.white),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
          onPressed: () {
            widget.onUseDefault();
            Navigator.of(context).pop();
          },
          child: Text('Use default', style: buttonLabelStyleMedium),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              style: defaultButtonStyle,
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: buttonLabelStyleMedium),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: defaultButtonStyle,
              onPressed: () {
                widget.onApply(_picked);
                Navigator.of(context).pop();
              },
              child: Text('Apply', style: buttonLabelStyleMedium),
            ),
          ],
        ),
      ],
    );
  }
}
