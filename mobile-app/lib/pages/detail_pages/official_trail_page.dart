
import 'package:file_picker/file_picker.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/location_service/tracking_preflight.dart';
import 'package:harrier_central/services/official_trails/official_trail_service.dart';
import 'package:harrier_central/widgets/tracking_preflight_dialog.dart';
import 'package:harrier_central/widgets/official_trail_type_picker.dart';
import 'package:latlong2/latlong.dart' as latlng;

/// A run's official trail, for its hares and kennel admins (E5.F6.S6,
/// James 2026-10-03): scout the trail ahead of the run, upload a file
/// (GPX / TCX / FIT — Strava, Garmin and Fitbit exports), or remove a lane.
/// A runner's PackTrack is promoted from the run's map instead.
///
/// Scouting records on THIS phone only: [LocationService.scoutMode] keeps
/// the points out of the pack's PackTrack, so a pre-run never shows as a
/// runner on the night.
class OfficialTrailController extends GetxController {
  OfficialTrailController(this.run);

  final RunDetailsAggregate run;
  final LocationService _location = LocationService.ensure();

  final Rx<RunOfficialTrail?> trail = Rx<RunOfficialTrail?>(null);
  final RxBool loading = true.obs;
  final RxBool busy = false.obs;
  final RxString status = ''.obs;

  /// When this page started a scout; null when not scouting from here.
  final Rxn<DateTime> scoutStartedAt = Rxn<DateTime>();
  final Rx<Duration> scoutElapsed = Duration.zero.obs;
  Timer? _ticker;

  HcId get eventId => HcId(run.event.eventId);

  List<TrailType> get trailTypes => run.kennel.trailTypes;

  RxDouble get scoutDistanceM => _location.filteredSessionDistanceMeters;

  bool get scouting => _location.scoutMode.value && scoutStartedAt.value != null;

  @override
  void onInit() {
    super.onInit();
    // A scout left running by an earlier visit to this page.
    if (_location.scoutMode.value && _location.joinRunTracking.value &&
        _location.eventId == run.event.eventId) {
      scoutStartedAt.value = DateTime.now();
      _startTicker();
    }
    unawaited(load());
  }

  @override
  void onClose() {
    _ticker?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    final RunOfficialTrail? got = await OfficialTrailService.fetchRunTrail(eventId);
    if (isClosed) return;
    loading.value = false;
    trail.value = got;
    if (got == null) status.value = "The trail couldn't be loaded. Check your connection.";
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final DateTime? s = scoutStartedAt.value;
      if (s != null) scoutElapsed.value = DateTime.now().difference(s);
    });
  }

  Future<void> startScout() async {
    if (_location.joinRunTracking.value) {
      hcSnack(
        _location.scoutMode.value
            ? 'A scout is already running.'
            : 'PackTrack is recording a run. Stop it before scouting.',
      );
      return;
    }
    if (!await _preflight()) return;
    if (isClosed) return;
    _location.eventId = run.event.eventId;
    _location.userId = getStringPref(StringPrefsEnum.userId);
    _location.scoutMode.value = true;
    _location.joinRunTracking.value = true;
    scoutStartedAt.value = DateTime.now();
    scoutElapsed.value = Duration.zero;
    _startTicker();
    BootLogger.logBreadcrumb('[Scout] started for ${run.event.eventId}');
  }

  /// Stops the scout; returns the recorded track, or null if it was too short.
  Future<List<TrackPoint>?> _stopScout() async {
    _location.joinRunTracking.value = false;
    _ticker?.cancel();
    final List<TrackPoint> track = _location.sessionTrackSnapshot;
    _location.scoutMode.value = false;
    scoutStartedAt.value = null;
    BootLogger.logBreadcrumb('[Scout] stopped: ${track.length} points');
    return track.length < 2 ? null : track;
  }

  Future<void> discardScout() async {
    await _stopScout();
    hcSnack('Scout discarded.');
  }

  Future<void> finishScout(BuildContext context) async {
    final List<TrackPoint>? track = await _stopScout();
    if (track == null) {
      hcSnack('Not enough of a trail was recorded to save.');
      return;
    }
    final lane = OfficialTrailService.lanePointsFrom(track);
    if (lane.points.length < 2) {
      hcSnack('Not enough of a trail was recorded to save.');
      return;
    }
    if (!context.mounted) return;
    final int? type = await pickOfficialTrailType(
      context,
      types: trailTypes,
      taken: _taken,
      title: 'Make this the official trail for…',
    );
    if (type == null) {
      hcSnack('Scout not saved.');
      return;
    }
    await _save(type, lane.points, lane.distanceM, 'scout', null);
  }

  Future<void> uploadFile(BuildContext context) async {
    if (busy.value) return;
    final FilePickerResult? picked = await FilePicker.pickFiles(type: FileType.any);
    final PlatformFile? file = picked?.files.singleOrNull;
    if (file == null || file.path == null) return;
    busy.value = true;
    status.value = 'Reading ${file.name}…';
    ParsedTrackFile parsed;
    try {
      final List<int> bytes = await File(file.path!).readAsBytes();
      parsed = await OfficialTrailService.parseFile(file.name, bytes);
    } catch (e) {
      if (isClosed) return;
      busy.value = false;
      status.value = e is String ? e : "That file couldn't be read. Please try again.";
      if (e is! String) BootLogger.logError('[OfficialTrail.uploadFile]', e, null);
      return;
    }
    if (isClosed) return;
    busy.value = false;
    status.value = '';
    if (!context.mounted) return;
    final int? type = await pickOfficialTrailType(
      context,
      types: trailTypes,
      taken: _taken,
      title: '${parsed.name} — which trail?',
    );
    if (type == null) return;
    await _save(type, parsed.points, parsed.distanceM, 'file', file.name);
  }

  Future<void> removeLane(int type) async {
    await _save(type, null, null, 'remove', null);
  }

  Set<int> get _taken => <int>{
    for (final OfficialTrailLane l in trail.value?.lanes ?? <OfficialTrailLane>[]) l.type,
  };

  Future<void> _save(
    int type,
    List<List<num>>? points,
    int? distanceM,
    String source,
    String? ref,
  ) async {
    busy.value = true;
    status.value = points == null ? 'Removing…' : 'Saving the trail…';
    final String? refusal = await OfficialTrailService.setLane(
      eventId,
      trailType: type,
      points: points,
      distanceM: distanceM,
      source: source,
      sourceRef: ref,
    );
    if (isClosed) return;
    busy.value = false;
    status.value = refusal ?? '';
    if (refusal == null) {
      hcSnack(points == null ? 'Trail removed.' : 'Official trail saved.');
      await load();
    }
  }

  Future<bool> _preflight() async {
    List<PreflightIssue> found;
    try {
      found = await TrackingPreflight.check();
    } catch (e, s) {
      BootLogger.logError('[OfficialTrail._preflight]', e, s);
      found = const <PreflightIssue>[];
    }
    if (isClosed) return false;
    if (found.isEmpty) return true;
    final BuildContext? ctx = Get.context;
    if (ctx == null) return !found.any((PreflightIssue i) => i.blocking);
    // ignore: use_build_context_synchronously
    final List<PreflightIssue>? left = await showTrackingPreflightDialog(ctx, found);
    return !isClosed && left != null;
  }
}

class OfficialTrailPage extends StatelessWidget {
  const OfficialTrailPage({super.key, required this.run});

  final RunDetailsAggregate run;

  static String _sourceLabel(String? s) => switch (s) {
    'scout' => 'scouted',
    'promote' => "promoted from a runner's PackTrack",
    'file' => 'uploaded file',
    'import' => 'imported',
    _ => '',
  };

  @override
  Widget build(BuildContext context) {
    final bool imperial = Utilities.prefersImperial(
      kennelDistanceUnitsPref: run.extensions.distanceUnitsPref,
    );
    return GetBuilder<OfficialTrailController>(
      init: OfficialTrailController(run),
      global: false,
      dispose: (GetBuilderState<OfficialTrailController> s) => s.controller?.onDelete(),
      builder: (OfficialTrailController c) => AppScaffold(
        appBar: AppBar(
          backgroundColor: themeAppBarBackground,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => hcPop<void>(),
            tooltip: 'Back',
          ),
          title: Text('Official trail', style: ts_appBarTitle),
          centerTitle: true,
        ),
        body: DecoratedBox(
          decoration: Backgrounds.defaultHcBackground(),
          child: Obx(() {
            // Read every Rx before any branch.
            final bool loading = c.loading.value;
            final bool busy = c.busy.value;
            final String status = c.status.value;
            final RunOfficialTrail? trail = c.trail.value;
            final DateTime? scoutStart = c.scoutStartedAt.value;
            final Duration elapsed = c.scoutElapsed.value;
            final double scoutM = c.scoutDistanceM.value;
            final bool scouting = scoutStart != null;
            final List<OfficialTrailLane> lanes = trail?.lanes ?? <OfficialTrailLane>[];
            final List<latlng.LatLng> all = <latlng.LatLng>[
              for (final OfficialTrailLane l in lanes) ...l.points,
            ];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(
                  '${run.kennel.kennelShortName} #${run.event.eventNumber}',
                  style: ts_titleMediumBold,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  "The hare's trail, saved with the run. Runners see it once the "
                  "run has ended; a lost runner sees it from the I'm Lost compass.",
                  style: ts_body.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (loading)
                  const Center(child: HcAppCircularProgressIndicator())
                else ...<Widget>[
                  if (all.length >= 2)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 240,
                        child: FlutterMap(
                          key: ValueKey<int>(all.length),
                          options: MapOptions(
                            initialCameraFit: CameraFit.coordinates(
                              coordinates: all,
                              padding: const EdgeInsets.all(24),
                            ),
                          ),
                          children: <Widget>[
                            TileLayer(
                              urlTemplate:
                                  'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                              subdomains: const <String>['mt0', 'mt1', 'mt2', 'mt3'],
                            ),
                            PolylineLayer(
                              polylines: <Polyline>[
                                for (final OfficialTrailLane l in lanes)
                                  Polyline(
                                    points: l.points,
                                    strokeWidth: 4,
                                    color: OfficialTrailLane.colorOf(l.type),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (lanes.isEmpty)
                    Text(
                      'No official trail yet.',
                      style: ts_body,
                      textAlign: TextAlign.center,
                    ),
                  for (final OfficialTrailLane l in lanes)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: OfficialTrailLane.colorOf(l.type),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              <String>[
                                _laneName(l.type),
                                if (l.distanceM != null && l.distanceM! > 0)
                                  formatDistance(l.distanceM!.toDouble(), imperial: imperial),
                                if (_sourceLabel(l.source).isNotEmpty) _sourceLabel(l.source),
                                if (!l.timed) 'untimed',
                              ].join(' · '),
                              style: ts_body,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove',
                            icon: const Icon(Icons.delete_outline, color: Colors.white70),
                            onPressed: busy || scouting
                                ? null
                                : () => unawaited(_confirmRemove(context, c, l.type)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (scouting) ...<Widget>[
                    Text(
                      'Scouting · ${formatDistance(scoutM, imperial: imperial)} · '
                      '${_hms(elapsed)}',
                      style: ts_titleMediumBold,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recording on this phone only — it is not shown on PackTrack. '
                      'Keep the app open or in your pocket; stop at the end of the trail.',
                      style: ts_body.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: <Widget>[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.flag, color: Colors.white),
                          label: const Text(
                            'Finish and save',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          onPressed: () => unawaited(c.finishScout(context)),
                        ),
                        OutlinedButton(
                          onPressed: () => unawaited(_confirmDiscard(context, c)),
                          child: const Text(
                            'Discard',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ] else ...<Widget>[
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.hiking, color: Colors.white),
                        label: const Text(
                          'Scout this trail',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        onPressed: busy ? null : () => unawaited(c.startScout()),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Walk or run the trail ahead of the run and save it as the official trail.',
                      style: ts_body.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.upload_file, color: Colors.white),
                        label: const Text(
                          'Upload a GPX, TCX or FIT file',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        onPressed: busy ? null : () => unawaited(c.uploadFile(context)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Export the activity from Strava, Garmin Connect or Fitbit and pick the file here.',
                      style: ts_body.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "To use a runner's PackTrack instead, open the run's map, "
                      "select the runner and tap Make official trail.",
                      style: ts_body.copyWith(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
                if (busy) ...<Widget>[
                  const SizedBox(height: 16),
                  const Center(child: HcAppCircularProgressIndicator()),
                ],
                if (status.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(status, style: ts_body, textAlign: TextAlign.center),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }

  String _laneName(int type) {
    final TrailType? t = run.kennel.trailTypes.firstWhereOrNull(
      (TrailType x) => x.value == type,
    );
    return t != null ? '${t.emoji} ${t.label}' : OfficialTrailLane.labelOf(type);
  }

  static String _hms(Duration d) {
    final String m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final String s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  Future<void> _confirmRemove(BuildContext context, OfficialTrailController c, int type) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Remove this trail?', style: ts_alertDialogTitle, textAlign: TextAlign.center),
        content: Text(
          'The ${_laneName(type)} official trail will be removed from the run.',
          style: ts_alertDialogBody,
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', textAlign: TextAlign.center),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    if (ok == true) await c.removeLane(type);
  }

  Future<void> _confirmDiscard(BuildContext context, OfficialTrailController c) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Discard this scout?', style: ts_alertDialogTitle, textAlign: TextAlign.center),
        content: Text(
          'What has been recorded so far will be thrown away.',
          style: ts_alertDialogBody,
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          TextButton(
            style: TextButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep scouting', textAlign: TextAlign.center),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard', style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
    if (ok == true) await c.discardScout();
  }
}
