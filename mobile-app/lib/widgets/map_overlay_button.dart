import 'package:harrier_central/imports.dart';

/// A control that floats over the run map.
///
/// Deliberately dark with a light outline rather than the translucent white it
/// used to be: map tiles are mostly pale, so a white chip on a white street
/// vanished. Dark ground + hairline outline holds up over tiles, satellite
/// imagery and the near-black rose canvas alike, which matters because the same
/// buttons sit on all three.
class MapOverlayButton extends StatelessWidget {
  const MapOverlayButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  static const double _size = 42.0;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.88),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}
