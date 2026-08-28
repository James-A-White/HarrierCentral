import 'package:harrier_central/imports.dart';
import 'package:share_plus/share_plus.dart';

/// The public web links for a run and the share flows built on them. One
/// place for the URL patterns and the message wording so Run Tools, the
/// run-detail map and the full-screen map all share identically.
///
/// Two audiences, two links:
///  * **Interactive map** (`/<slug>/<runNumber>/packtrack`) — a friend on a
///    phone following live or replaying afterwards.
///  * **Trail TV** (`/<slug>/<runNumber>/trail-tv`) — whoever is putting the
///    run on a big screen at the On-Inn.
///
/// Both dedicated routes need a numeric run number and 404 without one, so
/// uncounted runs fall back to the legacy run-detail link for the map (its
/// in-page map still shows the live track) and have no Trail TV link at all.
class RunShareLinks {
  const RunShareLinks(this.run);

  final RunDetailsAggregate run;

  bool get _isCounted => run.event.isCountedRun != 0;

  String get _runBase =>
      '$BASE_HASHRUNS_DOT_ORG_URL${run.kennel.kennelUniqueShortName}'
      '/${run.event.eventNumber}';

  /// Live-tracking / replay page. Never null — uncounted runs get the legacy
  /// run-detail link.
  String get packTrackUrl => _isCounted
      ? '$_runBase/packtrack'
      : '$BASE_HASHRUNS_DOT_ORG_URL#/RID?publicEventId=${run.event.publicEventId}';

  /// Big-screen event wall. Null for uncounted runs (no route exists).
  String? get trailTvUrl => _isCounted ? '$_runBase/trail-tv' : null;

  String get _runName => run.event.eventName.isEmpty
      ? '${run.kennel.kennelShortName} run'
      : run.event.eventName;

  /// OS share sheet with the interactive-map link.
  Future<void> shareMap() async {
    await SharePlus.instance.share(
      ShareParams(
        text:
            "I'm running $_runName with ${run.kennel.kennelShortName} — "
            'follow me live: $packTrackUrl',
        subject: 'Follow my hash live',
      ),
    );
  }

  /// OS share sheet with the Trail TV link. No-op for uncounted runs.
  Future<void> shareTrailTv() async {
    final String? url = trailTvUrl;
    if (url == null) return;
    await SharePlus.instance.share(
      ShareParams(
        text:
            'Put $_runName with ${run.kennel.kennelShortName} on the big '
            'screen — live tracks, photos and the leaderboard: $url',
        subject: 'Trail TV — $_runName',
      ),
    );
  }

  /// Entry point for every share button. Offers the two links in a bottom
  /// sheet; when only the map link exists (uncounted run) it skips the sheet
  /// and goes straight to the OS share sheet.
  Future<void> showShareSheet(BuildContext context) async {
    if (trailTvUrl == null) {
      await shareMap();
      return;
    }
    final _ShareTarget? choice = await showModalBottomSheet<_ShareTarget>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 12),
            Text(
              'Share this run',
              style: ts_titleMedium.copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 4),
            _row(
              context,
              icon: Icons.map_outlined,
              title: 'Interactive map',
              subtitle: 'Follow live or replay on any phone',
              target: _ShareTarget.map,
            ),
            _row(
              context,
              icon: Icons.tv,
              title: 'Trail TV',
              subtitle:
                  'Big-screen event wall — live tracks, photos, leaderboard. '
                  'Cast it at the pub.',
              target: _ShareTarget.trailTv,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    switch (choice) {
      case _ShareTarget.map:
        await shareMap();
      case _ShareTarget.trailTv:
        await shareTrailTv();
      case null:
        break;
    }
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required _ShareTarget target,
  }) {
    return ListTile(
      leading: Icon(icon, color: hc_blue, size: 30),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.black54, fontSize: 14),
      ),
      onTap: () => Navigator.of(context).pop(target),
    );
  }
}

enum _ShareTarget { map, trailTv }
