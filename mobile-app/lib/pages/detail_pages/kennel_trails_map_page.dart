import 'dart:math' as math;

import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/official_trails/official_trail_service.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlng;

/// A kennel's trail map (E5.F6.S6, James 2026-10-03): every run's OFFICIAL
/// (hare's) trail on one full-screen map — not the pack's tracks. Opened
/// from the kennel page's "Trail map" button; fetched when it opens, never
/// synced. Only runs that have ended (the server's rule). Tap a trail to
/// see which run it was, and open the run from there.
///
/// Also every run's START POINT (James, 2026-10-03), one pin per place:
/// tap a pin to step through the runs that started there.
class KennelTrailsMapController extends GetxController {
  KennelTrailsMapController(this.kennelId);

  final HcId kennelId;
  final MapController mapController = MapController();
  final RxList<KennelRunTrail> trails = <KennelRunTrail>[].obs;
  final RxBool loading = true.obs;
  final RxBool failed = false.obs;
  final Rxn<KennelRunTrail> selected = Rxn<KennelRunTrail>();

  /// Start points, one per place.
  final RxList<KennelStartPlace> places = <KennelStartPlace>[].obs;
  final Rxn<KennelStartPlace> selectedPlace = Rxn<KennelStartPlace>();

  /// Which of the selected place's runs is shown (0 = newest).
  final RxInt placeRunIndex = 0.obs;

  /// Where the map opens and the busiest place's run count — worked out
  /// once on load (focusArea compares every pair of places).
  List<latlng.LatLng> focus = const <latlng.LatLng>[];
  int busiest = 1;

  int get startCount =>
      places.fold<int>(0, (int n, KennelStartPlace p) => n + p.runs.length);

  /// Which trail a tap landed on; the polyline's hitValue is its run's id.
  final LayerHitNotifier<String> trailHits =
      ValueNotifier<LayerHitResult<String>?>(null);

  @override
  void onInit() {
    super.onInit();
    unawaited(load());
  }

  @override
  void onClose() {
    mapController.dispose();
    trailHits.dispose();
    super.onClose();
  }

  Future<void> load() async {
    loading.value = true;
    failed.value = false;
    final KennelTrailMapData? got =
        await OfficialTrailService.fetchKennelTrails(kennelId);
    if (isClosed) return;
    loading.value = false;
    if (got == null) {
      failed.value = true;
      return;
    }
    final List<KennelStartPlace> grouped = KennelRunStart.group(got.starts);
    // Open on where most runs start, not on a box stretched to the furthest
    // pin. A kennel with trails but no positioned starts falls back to them.
    focus = grouped.isNotEmpty
        ? KennelStartPlace.focusArea(grouped)
        : <latlng.LatLng>[
            for (final KennelRunTrail t in got.trails)
              for (final OfficialTrailLane l in t.lanes) ...l.points,
          ];
    busiest = grouped.fold<int>(
      1,
      (int m, KennelStartPlace p) => math.max(m, p.runs.length),
    );
    trails.assignAll(got.trails);
    places.assignAll(grouped);
  }

  void selectPlace(KennelStartPlace p) {
    selected.value = null;
    placeRunIndex.value = 0;
    selectedPlace.value = p;
  }

  void stepPlaceRun(int delta) {
    final KennelStartPlace? p = selectedPlace.value;
    if (p == null) return;
    placeRunIndex.value = (placeRunIndex.value + delta).clamp(
      0,
      p.runs.length - 1,
    );
  }

  void clearSelection() {
    selected.value = null;
    selectedPlace.value = null;
  }

  void onTrailTap() {
    final List<String>? hits = trailHits.value?.hitValues;
    if (hits == null || hits.isEmpty) return;
    selectedPlace.value = null;
    selected.value = trails.firstWhereOrNull(
      (KennelRunTrail t) => t.eventId == HcId(hits.first),
    );
  }

  /// Opens the run when this phone holds it (it normally does for a kennel
  /// the hasher follows; very old runs may have aged out).
  Future<void> openRun(HcId eventId) async {
    final List<dynamic> found = await QueryRuns.getRunDetailsAggregates(
      true,
      eventId: eventId,
      queryType: EnumRunQueryType.singleRun,
      runsTimeScope: RunsTimeScope.future,
      runsToDisplay: RunsToDisplay.allRuns,
    );
    if (isClosed) return;
    if (found.isEmpty) {
      hcSnack("That run's details aren't on this phone.");
      return;
    }
    await navigatorKey.currentState?.push<dynamic>(
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => RunDetailsPage(futureRun: found[0]),
      ),
    );
  }
}

class KennelTrailsMapPage extends StatelessWidget {
  const KennelTrailsMapPage({
    super.key,
    required this.kennelId,
    required this.kennelShortName,
    this.fallbackCenter,
  });

  final HcId kennelId;
  final String kennelShortName;

  /// Where to centre when the kennel has no trails yet (its city).
  final latlng.LatLng? fallbackCenter;

  static final DateFormat _day = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final bool imperial = Utilities.prefersImperial();
    return GetBuilder<KennelTrailsMapController>(
      init: KennelTrailsMapController(kennelId),
      global: false,
      dispose: (GetBuilderState<KennelTrailsMapController> s) =>
          s.controller?.onDelete(),
      builder: (KennelTrailsMapController c) => AppScaffold(
        appBar: AppBar(
          backgroundColor: themeAppBarBackground,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => hcPop<void>(),
            tooltip: 'Back',
          ),
          title: Text('$kennelShortName trails', style: ts_appBarTitle),
          centerTitle: true,
        ),
        body: DecoratedBox(
          decoration: Backgrounds.defaultHcBackground(),
          child: Obx(() {
            final bool loading = c.loading.value;
            final bool failed = c.failed.value;
            final List<KennelRunTrail> trails = c.trails.toList();
            final KennelRunTrail? sel = c.selected.value;
            final List<KennelStartPlace> places = c.places.toList();
            final KennelStartPlace? place = c.selectedPlace.value;
            final int placeIdx = c.placeRunIndex.value;
            if (loading) {
              return const Center(child: HcAppCircularProgressIndicator());
            }
            if (failed || (trails.isEmpty && places.isEmpty)) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        failed
                            ? "The trails couldn't be loaded. Check your connection and try again."
                            : "$kennelShortName doesn't have any run trails yet. "
                                  "A run's trail appears here once its hare's trail "
                                  'is saved with the run.',
                        style: ts_body,
                        textAlign: TextAlign.center,
                      ),
                      if (failed) ...<Widget>[
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => unawaited(c.load()),
                          child: const Text(
                            'Try again',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
            final List<latlng.LatLng> all = c.focus;
            final int busiest = c.busiest;
            final List<Polyline<String>> lines = <Polyline<String>>[
              for (final KennelRunTrail t in trails)
                for (final OfficialTrailLane l in t.lanes)
                  Polyline<String>(
                    points: l.points,
                    hitValue: t.eventId,
                    strokeWidth: sel?.eventId == t.eventId ? 6 : 3,
                    color: OfficialTrailLane.colorOf(l.type).withValues(
                      alpha: sel == null || sel.eventId == t.eventId
                          ? 0.85
                          : 0.35,
                    ),
                  ),
            ];
            // The selected trail is drawn last, so it sits on top.
            if (sel != null) {
              lines.sort(
                (Polyline<String> a, Polyline<String> b) =>
                    (a.hitValue == sel.eventId ? 1 : 0).compareTo(
                      b.hitValue == sel.eventId ? 1 : 0,
                    ),
              );
            }
            return Stack(
              children: <Widget>[
                FlutterMap(
                  mapController: c.mapController,
                  options: MapOptions(
                    initialCameraFit: all.isNotEmpty
                        ? CameraFit.coordinates(
                            coordinates: all,
                            padding: const EdgeInsets.all(40),
                          )
                        : null,
                    initialCenter:
                        fallbackCenter ?? const latlng.LatLng(51.5, -0.1),
                    initialZoom: 12,
                    minZoom: 3,
                    maxZoom: 19,
                  ),
                  children: <Widget>[
                    TileLayer(
                      urlTemplate:
                          'http://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                      subdomains: const <String>['mt0', 'mt1', 'mt2', 'mt3'],
                    ),
                    GestureDetector(
                      onTap: c.onTrailTap,
                      child: PolylineLayer<String>(
                        hitNotifier: c.trailHits,
                        polylines: lines,
                      ),
                    ),
                    // Start points above the trails, one pin per place;
                    // the busier the place, the bigger the pin.
                    MarkerLayer(
                      markers: <Marker>[
                        for (final KennelStartPlace p in places)
                          Marker(
                            point: p.point,
                            width: 30,
                            height: 30,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => c.selectPlace(p),
                              child: Center(
                                child: _StartPin(
                                  runs: p.runs.length,
                                  busiest: busiest,
                                  selected: identical(p, place),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: place != null
                        ? _placeCard(c, place, placeIdx)
                        : sel == null
                        ? Text(
                            '${<String>[if (trails.isNotEmpty) '${trails.length} run ${trails.length == 1 ? 'trail' : 'trails'}', if (places.isNotEmpty) '${c.startCount} runs from ${places.length} ${places.length == 1 ? 'start' : 'starts'}'].join(' · ')}\n'
                            'tap a ${trails.isNotEmpty ? 'trail or ' : ''}start to see its run',
                            style: ts_body,
                            textAlign: TextAlign.center,
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                sel.eventName.isNotEmpty
                                    ? sel.eventName
                                    : 'Run ${sel.eventNumber}',
                                style: ts_titleMediumBold,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                <String>[
                                  if (sel.startLocal != null)
                                    _day.format(sel.startLocal!),
                                  if (sel.distanceM != null)
                                    formatDistance(
                                      sel.distanceM!.toDouble(),
                                      imperial: imperial,
                                    ),
                                ].join(' · '),
                                style: ts_body.copyWith(color: Colors.white70),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 12,
                                children: <Widget>[
                                  ElevatedButton(
                                    onPressed: () =>
                                        unawaited(c.openRun(sel.eventId)),
                                    child: const Text(
                                      'Open run',
                                      style: TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: c.clearSelection,
                                    child: const Text(
                                      'Close',
                                      style: TextStyle(color: Colors.white70),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// The selected start point: which run (stepping through every run that
  /// started there), and a way into it.
  Widget _placeCard(KennelTrailsMapController c, KennelStartPlace p, int i) {
    final KennelRunStart r = p.runs[i.clamp(0, p.runs.length - 1)];
    final int n = p.runs.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          n == 1 ? '1 run started here' : '$n runs started here',
          style: ts_body.copyWith(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        Row(
          children: <Widget>[
            if (n > 1)
              IconButton(
                tooltip: 'Newer run',
                icon: const Icon(Icons.chevron_left, color: Colors.white),
                onPressed: i > 0 ? () => c.stepPlaceRun(-1) : null,
              ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    r.eventName.isNotEmpty
                        ? r.eventName
                        : 'Run ${r.eventNumber}',
                    style: ts_titleMediumBold,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    <String>[
                      if (r.eventNumber > 0) '#${r.eventNumber}',
                      if (r.startLocal != null) _day.format(r.startLocal!),
                      if (n > 1) '${i + 1} of $n',
                    ].join(' · '),
                    style: ts_body.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (n > 1)
              IconButton(
                tooltip: 'Older run',
                icon: const Icon(Icons.chevron_right, color: Colors.white),
                onPressed: i < n - 1 ? () => c.stepPlaceRun(1) : null,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: <Widget>[
            ElevatedButton(
              onPressed: () => unawaited(c.openRun(r.eventId)),
              child: const Text(
                'Open run',
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            TextButton(
              onPressed: c.clearSelection,
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A start-point pin (James, 2026-10-03): a coloured dot with a black
/// border; the more runs that started there, the bigger the dot and the
/// deeper its colour — scaled against the kennel's busiest place on a log
/// curve, so one place used 200 times does not flatten every other pin.
/// Selected: a thicker border with a white halo.
class _StartPin extends StatelessWidget {
  const _StartPin({
    required this.runs,
    required this.busiest,
    required this.selected,
  });
  final int runs;
  final int busiest;
  final bool selected;

  static const double _hue = 217; // blue: clear of the trail colours

  @override
  Widget build(BuildContext context) {
    final double t = busiest <= 1
        ? 1
        : (math.log(runs) / math.log(busiest)).clamp(0.0, 1.0);
    final double d = 10 + 16 * t;
    final Color fill = HSLColor.fromAHSL(
      1,
      _hue,
      0.30 + 0.65 * t,
      0.80 - 0.40 * t,
    ).toColor();
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: selected ? 3 : 1.5),
        boxShadow: <BoxShadow>[
          if (selected)
            const BoxShadow(color: Colors.white, spreadRadius: 3)
          else
            const BoxShadow(color: Colors.black38, blurRadius: 2),
        ],
      ),
    );
  }
}
