import 'package:harrier_central/imports.dart';

/// One runner's row on the list canvas, resolved for drawing.
class RunnerListEntry {
  const RunnerListEntry({
    required this.userId,
    required this.name,
    required this.color,
    required this.distanceMeters,
    required this.metersFromOrigin,
    required this.isSelf,
    required this.isLost,
  });

  final String userId;
  final String name;

  /// The runner's track colour — same per-runner palette as the map trails
  /// and the rose blips.
  final Color color;

  /// Trail distance covered at the playhead.
  final double distanceMeters;

  /// Straight-line separation from the list's origin — the focused runner,
  /// not necessarily the viewer. Null when there is nothing to measure from.
  final double? metersFromOrigin;

  final bool isSelf;

  /// This hasher has called for help / marked themselves lost.
  final bool isLost;
}

/// The list canvas: the pack as a sortable leaderboard. Third rendering of the
/// same replay alongside the map and the rose — it shares their timeline and
/// filters, so rows reorder live as the playhead scrubs.
class RunnerListCanvas extends StatelessWidget {
  const RunnerListCanvas({
    super.key,
    required this.entries,
    required this.selectedRunnerId,
    required this.sortByProximity,
    required this.originAvailable,
    required this.originLabel,
    required this.onSortChanged,
    required this.onTapRunner,
  });

  final List<RunnerListEntry> entries;
  final String? selectedRunnerId;
  final bool sortByProximity;

  /// Whether the sort has an origin to measure from. Without one the pill
  /// still shows (so the option is discoverable) but explains itself instead
  /// of silently sorting by nothing.
  final bool originAvailable;

  /// Who every row is measured FROM — 'you' when the viewer is the origin,
  /// otherwise the selected runner's name. Shown once as a caption above the
  /// list rather than repeated beside every distance. Separations follow the
  /// selection, so this has to as well, or the numbers silently change meaning
  /// when somebody is selected.
  ///
  /// The viewer's own row is still identifiable: the name column renders the
  /// runner's name followed by `(you)`.
  final String originLabel;

  final void Function(bool sortByProximity) onSortChanged;
  final void Function(String userId) onTapRunner;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _sortPill(
              label: 'Longest trail',
              icon: Icons.route,
              selected: !sortByProximity,
              onTap: () => onSortChanged(false),
            ),
            const SizedBox(width: 8),
            // NOT "Closest to me": rows are measured from the focused
            // runner, so with Tuna Melt selected this sorts by closest to
            // Tuna. The origin is named once in the caption below rather
            // than in the pill, where a long hash name would not fit.
            _sortPill(
              label: 'Closest Hashers',
              icon: Icons.near_me,
              selected: sortByProximity,
              onTap: () {
                if (!originAvailable) {
                  Get.snackbar(
                    'Closest Hashers',
                    'No position to measure from yet — sorting stays by trail distance until one lands.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
                onSortChanged(true);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Said once here rather than on all N rows. Repeating "from Pussy
        // Printer" beside every distance crowded the row and buried the
        // number, which is the part people actually read.
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'Distances shown are from $originLabel',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.yellow.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              // Sits straight on the jungle now that the canvas scrim is
              // gone, and yellow-on-leaves needs the separation.
              shadows: const <Shadow>[
                Shadow(blurRadius: 4, color: Colors.black),
                Shadow(blurRadius: 8, color: Colors.black),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            // Generous bottom padding so the last rows can scroll clear of the
            // playback panel anchored over the canvas's lower edge.
            padding: const EdgeInsets.only(bottom: 250),
            itemCount: entries.length,
            itemBuilder: (context, i) => _row(entries[i], rank: i + 1),
          ),
        ),
      ],
    );
  }

  Widget _sortPill({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    // Same visual language as MapViewSwitch: white = the one you're in.
    return Material(
      color: selected ? Colors.white : Colors.black.withValues(alpha: 0.62),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: selected ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0.0 : 0.7),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(RunnerListEntry e, {required int rank}) {
    final bool selected = e.userId == selectedRunnerId;
    // Each row carries its own dark underlay. The canvas used to be covered by
    // a single scrim instead, which darkened the whole jungle and made the
    // background visibly change when you switched between radar and list — the
    // background is supposed to be the one constant across the three views.
    // Selection now reads as a white outline (the same "white = the one you're
    // in" language as the view switch and the sort pills) rather than a lighter
    // fill, which would have cost contrast under the white text.
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.black.withValues(alpha: selected ? 0.72 : 0.55),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onTapRunner(e.userId),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: selected ? 0.9 : 0.0),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 24,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // The runner's dot — same colour as their trail on the map and
                // their blip on the radar, white-ringed like both.
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: e.color,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 1.6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.isSelf ? '${e.name} (you)' : e.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: selected || e.isSelf
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (e.isLost)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text('🆘', style: TextStyle(fontSize: 14)),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      _trailDistanceLabel(e.distanceMeters),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      e.metersFromOrigin == null
                          ? '—'
                          : _separationLabel(e.metersFromOrigin!),
                      style: TextStyle(
                        color: Colors.yellow.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Trail distance in both units, matching the playback panel's readout
  /// (e.g. "3.19 mi / 5.13 km").
  String _trailDistanceLabel(double meters) {
    final miles = meters * METERS_TO_MILES;
    final km = meters / 1000.0;
    final mi = miles >= 10
        ? miles.toStringAsFixed(1)
        : miles.toStringAsFixed(2);
    final k = km >= 10 ? km.toStringAsFixed(1) : km.toStringAsFixed(2);
    return '$mi mi / $k km';
  }

  /// Short separation label, matching the rose's ("140m", "1.2km").
  String _separationLabel(double m) =>
      m < 1000 ? '${m.round()}m' : '${(m / 1000).toStringAsFixed(1)}km';
}
