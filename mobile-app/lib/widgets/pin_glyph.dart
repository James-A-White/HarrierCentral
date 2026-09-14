import 'package:harrier_central/imports.dart';

/// A pin that reads as pinned or NOT pinned at a glance.
///
/// Flutter ships no slashed-pin icon, and `push_pin_outlined` is too close to
/// the filled one to tell apart on a busy background — on the jungle it just
/// looks like a fainter pin (James, 2026-09-15). So the unpinned state draws
/// the outline pin with a diagonal bar across it, the way a muted speaker or a
/// blocked signal reads.
///
/// Shows STATE, not the action: a solid pin means "this is pinned". The
/// tooltip on the button says what tapping will do.
class PinGlyph extends StatelessWidget {
  const PinGlyph({
    required this.pinned,
    this.size = 24,
    this.color,
    super.key,
  });

  final bool pinned;
  final double size;

  /// Defaults to white when pinned and a dimmer white when not, which is what
  /// the jungle background needs. Pass a colour on a light surface.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color c = color ?? (pinned ? Colors.white : Colors.white70);
    if (pinned) {
      return Icon(Icons.push_pin, size: size, color: c);
    }
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Icon(Icons.push_pin_outlined, size: size, color: c),
          // Two bars: the darker one underneath reads as a gap punched through
          // the pin, so the slash does not merge into the outline it crosses.
          Transform.rotate(
            angle: -0.785398, // -45°
            child: Container(
              width: size * 0.92,
              height: size * 0.20,
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),
          Transform.rotate(
            angle: -0.785398,
            child: Container(width: size * 0.92, height: size * 0.10, color: c),
          ),
        ],
      ),
    );
  }
}
