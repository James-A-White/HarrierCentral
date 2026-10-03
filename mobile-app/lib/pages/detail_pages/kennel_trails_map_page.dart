import 'package:harrier_central/imports.dart';
import 'package:harrier_central/services/official_trails/official_trail_service.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' as latlng;

/// A kennel's trail map (E5.F6.S6, James 2026-10-03): every run's OFFICIAL
/// (hare's) trail on one full-screen map — not the pack's tracks. Opened
/// from the kennel page's "Trail map" button; fetched when it opens, never
/// synced. Only runs that have ended (the server's rule). Tap a trail to
/// see which run it was, and open the run from there.
class KennelTrailsMapController extends GetxController {
  KennelTrailsMapController(this.kennelId);

  final HcId kennelId;
  final MapController mapController = MapController();
  final RxList<KennelRunTrail> trails = <KennelRunTrail>[].obs;
  final RxBool loading = true.obs;
  final RxBool failed = false.obs;
  final Rxn<KennelRunTrail> selected = Rxn<KennelRunTrail>();

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
    final List<KennelRunTrail>? got =
        await OfficialTrailService.fetchKennelTrails(kennelId);
    if (isClosed) return;
    loading.value = false;
    if (got == null) {
      failed.value = true;
      return;
    }
    trails.assignAll(got);
  }

  void onTrailTap() {
    final List<String>? hits = trailHits.value?.hitValues;
    if (hits == null || hits.isEmpty) return;
    selected.value = trails.firstWhereOrNull(
      (KennelRunTrail t) => t.eventId == HcId(hits.first),
    );
  }

  /// Opens the run when this phone holds it (it normally does for a kennel
  /// the hasher follows; very old runs may have aged out).
  Future<void> openRun(KennelRunTrail t) async {
    final List<dynamic> found = await QueryRuns.getRunDetailsAggregates(
      true,
      eventId: t.eventId,
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
            if (loading) {
              return const Center(child: HcAppCircularProgressIndicator());
            }
            if (failed || trails.isEmpty) {
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
            final List<latlng.LatLng> all = <latlng.LatLng>[
              for (final KennelRunTrail t in trails)
                for (final OfficialTrailLane l in t.lanes) ...l.points,
            ];
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
                    child: sel == null
                        ? Text(
                            '${trails.length} run ${trails.length == 1 ? 'trail' : 'trails'} · '
                            'tap a trail to see its run',
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
                                    onPressed: () => unawaited(c.openRun(sel)),
                                    child: const Text(
                                      'Open run',
                                      style: TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => c.selected.value = null,
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
}
