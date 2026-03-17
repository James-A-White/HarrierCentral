import 'package:hcportal/imports.dart';

class HexColor extends Color {
  HexColor(String hexColor) : super(_getColorFromHex(hexColor));

  static Color darken(Color color, [double amount = .1]) {
    assert(
      amount >= 0 && amount <= 1,
      'Amount of color darkening must be between zero and one.',
    );

    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  static Color lighten(Color color, [double amount = .1]) {
    assert(
      amount >= 0 && amount <= 1,
      'Amount of color lightning must be between zero and one.',
    );

    final hsl = HSLColor.fromColor(color);
    final hslLight =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));

    return hslLight.toColor();
  }

  static int _getColorFromHex(String hexColor) {
    var hc = hexColor.replaceAll('#', '').toUpperCase();
    if (hc.length == 6) {
      hc = 'FF$hc';
    }
    return int.parse(hc, radix: 16);
  }
}
