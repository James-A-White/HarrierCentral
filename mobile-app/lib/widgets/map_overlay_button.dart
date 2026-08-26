import 'package:harrier_central/imports.dart';

/// A control that floats over the run map.
///
/// Deliberately dark with a light outline rather than the translucent white it
/// used to be: map tiles are mostly pale, so a white chip on a white street
/// vanished. Dark ground + hairline outline holds up over tiles, satellite
/// imagery and the near-black rose canvas alike, which matters because the same
/// buttons sit on all three.
/// Map / Radar / List switch for the run map.
///
/// A segmented control rather than a toggle icon: it names every view and
/// highlights the one you're in, so "which view am I looking at" and "how do I
/// get back" are answered by the same control without decoding an icon. The
/// previous icon-only toggle sat among identically-styled overlay buttons with
/// nothing marking it as the way out.
class MapViewSwitch extends StatelessWidget {
  const MapViewSwitch({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final PackTrackCanvas selected;
  final void Function(PackTrackCanvas canvas) onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(9),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.88),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _segment(
              label: 'Map',
              icon: Icons.map,
              selected: selected == PackTrackCanvas.map,
              onTap: () => onSelect(PackTrackCanvas.map),
            ),
            _segment(
              label: 'Radar',
              icon: Icons.radar,
              selected: selected == PackTrackCanvas.rose,
              onTap: () => onSelect(PackTrackCanvas.rose),
            ),
            _segment(
              label: 'List',
              icon: Icons.format_list_numbered,
              selected: selected == PackTrackCanvas.list,
              onTap: () => onSelect(PackTrackCanvas.list),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: selected ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 17, color: selected ? Colors.black : Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.black : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
