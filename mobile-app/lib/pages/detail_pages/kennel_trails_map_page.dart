import 'dart:math' as math;

import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/run_on_phone.dart';
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

  /// Fetching a run that is not on the phone, so it can open.
  final RxBool opening = false.obs;
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

  /// Everything the server sent; [trails] and [places] are these narrowed
  /// by the search bar.
  List<KennelRunTrail> _allTrails = const <KennelRunTrail>[];
  List<KennelRunStart> _allStarts = const <KennelRunStart>[];

  /// The search bar (the Runs page's, same rules: "+" OR, "," AND, "not ").
  final TextEditingController searchController = TextEditingController();
  final RxString searchText = ''.obs;

  /// Where the map opens and the busiest place's run count — worked out
  /// once on load (focusArea compares every pair of places).
  List<latlng.LatLng> focus = const <latlng.LatLng>[];
  int busiest = 1;

  /// Each trail's colour by age (James, 2026-10-16): newest green, round the
  /// colour wheel through blue and purple to red for the oldest. By rank, not
  /// by date, so a kennel with a burst of recent trails still uses the whole
  /// wheel. A trail with no date counts as the oldest.
  Map<HcId, Color> ageColors = const <HcId, Color>{};

  /// The newest and oldest trail dates, for the key.
  DateTime? newestDay;
  DateTime? oldestDay;

  /// Green (120°) at t = 0 to red (360°) at t = 1, the long way round.
  static Color ageColor(double t) => HSLColor.fromAHSL(
    1,
    (120 + 240 * t.clamp(0.0, 1.0)) % 360,
    0.85,
    0.45,
  ).toColor();

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
    searchController.dispose();
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
    // Oldest first, so the newest trails are drawn on top.
    final List<KennelRunTrail> byAge = got.trails.toList()
      ..sort(
        (KennelRunTrail a, KennelRunTrail b) =>
            (a.startLocal ?? DateTime(0)).compareTo(b.startLocal ?? DateTime(0)),
      );
    final int n = byAge.length;
    ageColors = <HcId, Color>{
      for (int i = 0; i < n; i++)
        byAge[i].eventId: ageColor(n <= 1 ? 0 : (n - 1 - i) / (n - 1)),
    };
    final List<DateTime> days = <DateTime>[
      for (final KennelRunTrail t in byAge)
        if (t.startLocal != null) t.startLocal!,
    ];
    oldestDay = days.isEmpty ? null : days.first;
    newestDay = days.isEmpty ? null : days.last;
    _allTrails = byAge;
    _allStarts = got.starts;
    trails.assignAll(byAge);
    places.assignAll(grouped);
    if (searchText.value.trim().isNotEmpty) applySearch(searchText.value);
  }

  static final DateFormat _searchDay = DateFormat('d MMMM yyyy');

  /// What a run is found by: its number, its name and its date.
  static String _searchable(int number, String name, DateTime? day) =>
      '#$number $number $name ${day == null ? '' : _searchDay.format(day)}';

  /// Narrows the trails and the start pins to the runs the text matches.
  /// The colours stay those of the whole set, so a trail keeps its age.
  void applySearch(String text) {
    searchText.value = text;
    final SearchQuery q = SearchQuery(text);
    trails.assignAll(
      q.isEmpty
          ? _allTrails
          : _allTrails.where(
              (KennelRunTrail t) =>
                  q.matches(_searchable(t.eventNumber, t.eventName, t.startLocal)),
            ),
    );
    places.assignAll(
      KennelRunStart.group(
        q.isEmpty
            ? _allStarts
            : _allStarts
                  .where(
                    (KennelRunStart r) => q.matches(
                      _searchable(r.eventNumber, r.eventName, r.startLocal),
                    ),
                  )
                  .toList(),
      ),
    );
    final KennelRunTrail? sel = selected.value;
    if (sel != null && !trails.any((KennelRunTrail t) => t.eventId == sel.eventId)) {
      selected.value = null;
    }
    selectedPlace.value = null;
  }

  void clearSearch() {
    searchController.text = '';
    applySearch('');
  }

  /// Whether the selected trail has a newer / older one to step to.
  bool get hasNewerTrail => _selectedIndex >= 0 && _selectedIndex < trails.length - 1;
  bool get hasOlderTrail => _selectedIndex > 0;

  int get _selectedIndex {
    final KennelRunTrail? sel = selected.value;
    if (sel == null) return -1;
    return trails.indexWhere((KennelRunTrail t) => t.eventId == sel.eventId);
  }

  /// The arrows on the selected trail's card (James, 2026-10-16): step to the
  /// next run in time, newer (+1) or older (-1), and bring it into view.
  /// [trails] is held oldest first.
  void stepTrail(int delta) {
    final int i = _selectedIndex;
    if (i < 0) return;
    final int j = (i + delta).clamp(0, trails.length - 1);
    if (j == i) return;
    selected.value = trails[j];
    final List<latlng.LatLng> pts = <latlng.LatLng>[
      for (final OfficialTrailLane l in trails[j].lanes) ...l.points,
    ];
    if (pts.length > 1) {
      mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: pts,
          // Room at the bottom for the card that covers the map there.
          padding: const EdgeInsets.fromLTRB(40, 40, 40, 200),
        ),
      );
    }
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

  /// Opens a run from the map. Most pins are older runs of a kennel the
  /// hasher may not follow, and the phone holds only ten days of those — so
  /// when the run is not here, fetch just that run (RunOnPhone) and open it.
  /// Before 2026-10-04 this only showed a toast: "nothing happens".
  Future<void> openRun(HcId eventId) async {
    if (opening.value) return;
    try {
      List<RunDetailsAggregate> found = await _lookup(eventId);
      if (isClosed) return;
      if (found.isEmpty) {
        opening.value = true;
        final bool ok = await RunOnPhone.load(eventId);
        if (isClosed) return;
        found = ok ? await _lookup(eventId) : const <RunDetailsAggregate>[];
        if (isClosed) return;
        opening.value = false;
        if (found.isEmpty) {
          hcSnack(
            ok
                ? "That run isn't available any more."
                : "That run couldn't be loaded. Check your connection and try again.",
            error: true,
          );
          return;
        }
      }
      await navigatorKey.currentState?.push<dynamic>(
        MaterialPageRoute<dynamic>(
          builder: (BuildContext context) =>
              RunDetailsPage(futureRun: found.first),
        ),
      );
    } catch (e, s) {
      BootLogger.logError('[KennelTrailsMap.openRun]', e, s);
      if (!isClosed) hcSnack("That run couldn't be opened.", error: true);
    } finally {
      if (!isClosed) opening.value = false;
    }
  }

  Future<List<RunDetailsAggregate>> _lookup(HcId eventId) =>
      QueryRuns.getRunDetailsAggregates(
        true,
        eventId: eventId,
        queryType: EnumRunQueryType.singleRun,
        runsTimeScope: RunsTimeScope.future,
        runsToDisplay: RunsToDisplay.allRuns,
      );
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
          child: Column(
            children: <Widget>[
              _searchBar(c),
              Expanded(child: _map(c, imperial)),
            ],
          ),
        ),
      ),
    );
  }

  /// The Runs page's search bar (James, 2026-10-16): white field, X to
  /// clear, and the count line under it.
  Widget _searchBar(KennelTrailsMapController c) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        color: Colors.white,
        height: 50,
        padding: const EdgeInsets.only(left: 14.0),
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  onTapOutside: (_) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  onChanged: c.applySearch,
                  controller: c.searchController,
                  keyboardType: TextInputType.text,
                  style: ts_footnoteBlack,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    icon: const Icon(FontAwesome.search, color: Colors.black),
                    hintText: 'Search...',
                    hintStyle: ts_searchLabel,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: TextButton(
                  style: TextButton.styleFrom(
                    shape: button_shape,
                    textStyle: TextStyle(color: Colors.grey.shade700),
                    backgroundColor: Colors.white,
                  ),
                  onPressed: c.clearSearch,
                  child: Text(
                    'X',
                    style: ts_headingBlack.copyWith(
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const Divider(height: 1.0, thickness: 1.0, color: Colors.grey),
      Container(
        color: Colors.grey.shade200,
        height: 24.0,
        child: Obx(() {
          final int t = c.trails.length;
          final int r = c.startCount;
          final bool loading = c.loading.value;
          return Align(
            alignment: Alignment.center,
            child: Text(
              loading
                  ? 'Loading trails…'
                  : 'Showing $t ${t == 1 ? 'trail' : 'trails'}, $r ${r == 1 ? 'start' : 'starts'}',
              style: ts_titleSmallCondensedBlack,
            ),
          );
        }),
      ),
      const Divider(height: 1.0, thickness: 1.0, color: Colors.grey),
    ],
  );

  Widget _map(KennelTrailsMapController c, bool imperial) => Obx(() {
            // Every Rx read before any branch (an Obx that can skip its
            // reads throws).
            final bool loading = c.loading.value;
            final bool failed = c.failed.value;
            final bool opening = c.opening.value;
            final List<KennelRunTrail> trails = c.trails.toList();
            final KennelRunTrail? sel = c.selected.value;
            final List<KennelStartPlace> places = c.places.toList();
            final KennelStartPlace? place = c.selectedPlace.value;
            final int placeIdx = c.placeRunIndex.value;
            final bool searching = c.searchText.value.trim().isNotEmpty;
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
                            : searching
                            ? 'No runs match your search.'
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
                    color:
                        (c.ageColors[t.eventId] ??
                                KennelTrailsMapController.ageColor(1))
                            .withValues(
                      alpha: sel == null || sel.eventId == t.eventId
                          ? 0.85
                          : 0.35,
                    ),
                  ),
            ];
            // The selected trail is drawn last, so it sits on top. Moved,
            // not sorted: List.sort is not stable, and the rest must keep
            // their oldest-first order.
            if (sel != null) {
              final List<Polyline<String>> picked = lines
                  .where((Polyline<String> p) => p.hitValue == sel.eventId)
                  .toList();
              lines
                ..removeWhere((Polyline<String> p) => p.hitValue == sel.eventId)
                ..addAll(picked);
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
                    // Start points above the trails, clustered as on the other
                    // maps (James, 2026-10-04): a bubble says how many RUNS
                    // started in that area, and a tap zooms in until it splits
                    // into single places — a pink dot, bigger and deeper the
                    // busier the place. Each pin's key is its place's index,
                    // so the bubble can count runs rather than pins.
                    MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 45,
                        size: const Size(40, 40),
                        markers: <Marker>[
                          for (int i = 0; i < places.length; i++)
                            Marker(
                              key: ValueKey<int>(i),
                              point: places[i].point,
                              width: 30,
                              height: 30,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => c.selectPlace(places[i]),
                                child: Center(
                                  child: _StartPin(
                                    runs: places[i].runs.length,
                                    busiest: busiest,
                                    selected: identical(places[i], place),
                                  ),
                                ),
                              ),
                            ),
                        ],
                        polygonOptions: const PolygonOptions(
                          borderColor: Color(0xFFDB2777),
                          color: Colors.black12,
                          borderStrokeWidth: 2,
                        ),
                        builder: (BuildContext context, List<Marker> markers) {
                          int runs = 0;
                          for (final Marker m in markers) {
                            final Key? k = m.key;
                            if (k is ValueKey<int> && k.value < places.length) {
                              runs += places[k.value].runs.length;
                            }
                          }
                          return _RunCluster(runs: runs);
                        },
                      ),
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
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                '${<String>[if (trails.isNotEmpty) '${trails.length} run ${trails.length == 1 ? 'trail' : 'trails'}', if (places.isNotEmpty) '${c.startCount} runs from ${places.length} ${places.length == 1 ? 'start' : 'starts'}'].join(' · ')}\n'
                                'tap a ${trails.isNotEmpty ? 'trail or ' : ''}start to see its run',
                                style: ts_body,
                                textAlign: TextAlign.center,
                              ),
                              if (trails.length > 1) ...<Widget>[
                                const SizedBox(height: 8),
                                _AgeKey(
                                  newest: c.newestDay,
                                  oldest: c.oldestDay,
                                ),
                              ],
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  IconButton(
                                    tooltip: 'Newer run',
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      color: Colors.white,
                                    ),
                                    onPressed: c.hasNewerTrail
                                        ? () => c.stepTrail(1)
                                        : null,
                                  ),
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          sel.eventName.isNotEmpty
                                              ? sel.eventName
                                              : 'Run ${sel.eventNumber}',
                                          style: ts_titleMediumBold,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
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
                                          style: ts_body.copyWith(
                                            color: Colors.white70,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Older run',
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white,
                                    ),
                                    onPressed: c.hasOlderTrail
                                        ? () => c.stepTrail(-1)
                                        : null,
                                  ),
                                ],
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
                if (opening)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const HcAppCircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              'Loading the run…',
                              style: ts_body,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          });

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

/// The trail colours' key: a strip from green (newest) round to red
/// (oldest), with the dates at its ends.
class _AgeKey extends StatelessWidget {
  const _AgeKey({this.newest, this.oldest});
  final DateTime? newest;
  final DateTime? oldest;

  static final DateFormat _month = DateFormat('MMM yyyy');

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Text(
        newest != null ? 'Newest\n${_month.format(newest!)}' : 'Newest',
        style: ts_body.copyWith(color: Colors.white70, fontSize: 12),
        textAlign: TextAlign.center,
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: <Color>[
                for (int i = 0; i <= 8; i++)
                  KennelTrailsMapController.ageColor(i / 8),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        oldest != null ? 'Oldest\n${_month.format(oldest!)}' : 'Oldest',
        style: ts_body.copyWith(color: Colors.white70, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    ],
  );
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

  // Pink (James, 2026-10-03): the first scale started near white, and a
  // one-run start vanished against the pale map. Even the lightest pin is a
  // clear mid pink now, deepening to dark pink at the busiest place.
  static const double _hue = 330;

  @override
  Widget build(BuildContext context) {
    final double t = busiest <= 1
        ? 1
        : (math.log(runs) / math.log(busiest)).clamp(0.0, 1.0);
    final double d = 10 + 16 * t;
    final Color fill = HSLColor.fromAHSL(
      1,
      _hue,
      0.85 + 0.10 * t,
      0.66 - 0.36 * t,
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

/// A cluster of start places: how many runs started in it, on deep pink with
/// a black border, so it reads as the same family as the pins.
class _RunCluster extends StatelessWidget {
  const _RunCluster({required this.runs});
  final int runs;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFBE185D),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.black, width: 1.5),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Colors.black38, blurRadius: 3),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: FittedBox(
        child: Text(
          '$runs',
          style: ts_button.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
