import 'package:hcportal/imports.dart';

/// Per-editor vertical-rail background colours.
///
/// All share the same saturation (0.793) and luminance and only rotate the hue
/// around the wheel, so each editor reads as a distinct colour at the same
/// visual weight. The yellow band (~60°) is avoided — it reads too light at
/// this luminance. Kennel keeps the original blue hue (208°).
///
/// Luminance is held at 0.27 (deepened from the original 0.508) so the white
/// rail labels read clearly against every hue (James' request).
Color _railHue(double hue) =>
    HSLColor.fromAHSL(1, hue, 0.793, 0.27).toColor();

final Color railColorKennelEditor = _railHue(208); // blue
final Color railColorRunEdit = _railHue(140); // green
final Color railColorKennelWebsite = _railHue(182); // teal
final Color railColorApplicationForm = _railHue(275); // violet
final Color railColorEmail = _railHue(340); // crimson
final Color railColorKennelHashers = _railHue(22); // orange
