import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/widgets/packtrack_trim_overlay.dart';

/// The trim panel shipped with "Stop everyone's tracking" drawn in hc_red on an
/// hc_red button, i.e. an invisible label on a blank red bar, and with its four
/// buttons split across two widget types that render different corner radii and
/// font sizes. These lock both fixes.
void main() {
  final ButtonStyle style = trimButtonStyleForTest();

  T? resolve<T>(WidgetStateProperty<T?>? p) => p?.resolve(<WidgetState>{});

  test('text is never the same colour as the background', () {
    final Color? bg = resolve(style.backgroundColor);
    final Color? fg = resolve(style.foregroundColor);
    expect(bg, isNotNull);
    expect(fg, isNotNull);
    expect(fg, isNot(equals(bg)), reason: 'red on red is a blank button');
    expect(fg, Colors.white, reason: 'CLAUDE.md: white text on red buttons');
  });

  test('the disabled state stays readable too', () {
    final Color? bg = style.backgroundColor?.resolve(<WidgetState>{
      WidgetState.disabled,
    });
    final Color? fg = style.foregroundColor?.resolve(<WidgetState>{
      WidgetState.disabled,
    });
    expect(fg, isNot(equals(bg)));
  });

  test('corner radius matches the app theme, so buttons sit flush', () {
    final OutlinedBorder? shape = resolve(style.shape);
    expect(shape, isA<RoundedRectangleBorder>());
    final BorderRadius r =
        (shape! as RoundedRectangleBorder).borderRadius as BorderRadius;
    expect(r.topLeft.x, 10.0);
  });

  test('font size is the app-wide button size, not a Material default', () {
    final TextStyle? t = resolve(style.textStyle);
    expect(t, isNotNull);
    expect(t!.fontSize, ts_button.fontSize);
    expect(t.fontFamily, ts_button.fontFamily);
  });

  test('every button gets the same minimum height', () {
    expect(resolve(style.minimumSize)?.height, 44.0);
  });
}
