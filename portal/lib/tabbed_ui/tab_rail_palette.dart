import 'package:hcportal/imports.dart';

/// Per-editor vertical-rail background colours.
///
/// All share the saturation and luminance of the kennel-editor blue
/// (`Colors.blue.shade600` ≈ HSL 208°, 79%, 51%) and only rotate the hue around
/// the wheel, so each editor reads as a distinct colour at the same visual
/// weight. The yellow band (~60°) is avoided — it reads too light at this
/// luminance. Kennel keeps the original blue (208°).
Color _railHue(double hue) =>
    HSLColor.fromAHSL(1, hue, 0.793, 0.508).toColor();

final Color railColorRunEdit = _railHue(140); // green
final Color railColorKennelWebsite = _railHue(182); // teal
final Color railColorApplicationForm = _railHue(275); // violet
final Color railColorEmail = _railHue(340); // crimson
final Color railColorKennelHashers = _railHue(22); // orange
