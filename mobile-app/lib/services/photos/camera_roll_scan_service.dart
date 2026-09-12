import 'dart:math' as math;

import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart';
// photo_manager ships a LatLng of its own; latlong2's is the one the whole
// app measures with, so the package's is reached for by prefix instead.
import 'package:photo_manager/photo_manager.dart' hide LatLng;
import 'package:photo_manager/photo_manager.dart' as pm show LatLng;

/// One run the sweep can look for photos of, with everything the match needs.
class ScannableRun {
  const ScannableRun({
    required this.eventId,
    required this.eventName,
    required this.eventNumber,
    required this.kennelId,
    required this.kennelSlug,
    required this.startUtc,
    this.startLat,
    this.startLng,
    this.trail = const <LatLng>[],
  });

  final String eventId;
  final String eventName;
  final int eventNumber;
  final String kennelId;
  final String kennelSlug;

  /// The run's start as a true instant. Capture times are instants too, so
  /// both sides are on one clock and a hasher who runs abroad and imports
  /// after flying home still matches.
  final DateTime startUtc;

  final double? startLat;
  final double? startLng;

  /// The hasher's own trail for this run, when they tracked it. The whole
  /// point of preferring it: the circle, the beer stop and the On-Inn are all
  /// a long way apart, and only the trail covers them.
  final List<LatLng> trail;

  bool get hasGeofence =>
      trail.isNotEmpty || (startLat != null && startLng != null);
}

/// A photo the sweep believes belongs to a run.
class PhotoCandidate {
  const PhotoCandidate({
    required this.asset,
    required this.takenUtc,
    required this.lat,
    required this.lng,
    required this.alreadyUploaded,
  });

  final AssetEntity asset;
  final DateTime takenUtc;
  final double lat;
  final double lng;

  /// Already sent up for this run — shown as done and not offered again.
  final bool alreadyUploaded;
}

/// What one run's sweep found.
class RunScanResult {
  const RunScanResult({required this.run, required this.candidates});

  final ScannableRun run;
  final List<PhotoCandidate> candidates;

  int get eligible => candidates.length;
  int get added =>
      candidates.where((PhotoCandidate c) => c.alreadyUploaded).length;
  int get pending => eligible - added;
}

/// Finds the photos of a run still sitting in the camera roll (E6.F2.S5).
///
/// James's rules, 2026-09-12: the sweep is **per run and on demand**, never a
/// background trawl. A photo with a time but no location is **discarded, not
/// offered** — a roll full of unrelated pictures is worse than a missed one.
/// Nothing uploads on its own; candidates go to a selector the hasher ticks,
/// carrying the notice that what they send may become publicly viewable.
class CameraRollScanService {
  const CameraRollScanService();

  /// From this long before the run's start…
  static const Duration windowBefore = Duration(minutes: 30);

  /// …to this long after it.
  static const Duration windowAfter = Duration(hours: 6);

  /// How far off the hasher's own trail a photo may be and still count. A
  /// trail is dense, so this only has to cover standing off the path.
  static const double trailRadiusMeters = 300;

  /// Used only where the hasher has no trail for the run: everything is
  /// measured from the start, so it has to reach an On-Inn without sweeping
  /// in the rest of town.
  static const double startRadiusMeters = 2000;

  static const Distance _distance = Distance();

  /// Whether a capture time falls in a run's window. Pure, so the rule is
  /// testable without a photo library.
  static bool withinWindow(DateTime takenUtc, DateTime runStartUtc) {
    if (takenUtc.isBefore(runStartUtc.subtract(windowBefore))) return false;
    if (takenUtc.isAfter(runStartUtc.add(windowAfter))) return false;
    return true;
  }

  /// Whether a coordinate is close enough for this run: near any point of the
  /// hasher's trail, or near the start when there is no trail. False when the
  /// run has neither — a run we cannot place cannot judge.
  static bool withinGeofence(double lat, double lng, ScannableRun run) {
    final LatLng p = LatLng(lat, lng);
    if (run.trail.isNotEmpty) {
      for (final LatLng t in run.trail) {
        if (_distance.as(LengthUnit.Meter, p, t) <= trailRadiusMeters) {
          return true;
        }
      }
      return false;
    }
    final double? la = run.startLat;
    final double? lo = run.startLng;
    if (la == null || lo == null) return false;
    return _distance.as(LengthUnit.Meter, p, LatLng(la, lo)) <=
        startRadiusMeters;
  }

  /// Ask for the library.
  Future<PermissionState> requestAccess() =>
      PhotoManager.requestPermissionExtend();

  /// Sweep the roll for [runs]. One library query spanning every run's window,
  /// then time first and location second: resolving a coordinate costs a
  /// platform call each, so only photos that already matched on time pay it.
  ///
  /// [uploadedAssetIds] is what this hasher has already sent up, keyed by
  /// event id, so the result can say "14 eligible, 6 already added".
  Future<List<RunScanResult>> scan({
    required List<ScannableRun> runs,
    Map<String, Set<String>> uploadedAssetIds = const <String, Set<String>>{},
    void Function(int done, int total)? onProgress,
  }) async {
    final List<ScannableRun> usable = runs
        .where((ScannableRun r) => r.hasGeofence)
        .toList(growable: false);
    if (usable.isEmpty) return const <RunScanResult>[];

    DateTime from = usable.first.startUtc.subtract(windowBefore);
    DateTime to = usable.first.startUtc.add(windowAfter);
    for (final ScannableRun r in usable) {
      final DateTime a = r.startUtc.subtract(windowBefore);
      final DateTime b = r.startUtc.add(windowAfter);
      if (a.isBefore(from)) from = a;
      if (b.isAfter(to)) to = b;
    }

    final List<AssetEntity> assets = await _assetsBetween(from, to);

    // Bucket on time first — cheap, the entity already carries its date.
    final Map<String, List<AssetEntity>> byRun = <String, List<AssetEntity>>{};
    for (final AssetEntity a in assets) {
      final DateTime taken = a.createDateTime.toUtc();
      for (final ScannableRun r in usable) {
        if (withinWindow(taken, r.startUtc)) {
          (byRun[r.eventId] ??= <AssetEntity>[]).add(a);
        }
      }
    }

    final List<RunScanResult> out = <RunScanResult>[];
    int done = 0;
    for (final ScannableRun r in usable) {
      final List<AssetEntity> timed = byRun[r.eventId] ?? const <AssetEntity>[];
      final Set<String> already =
          uploadedAssetIds[r.eventId] ?? const <String>{};
      final List<PhotoCandidate> hits = <PhotoCandidate>[];
      for (final AssetEntity a in timed) {
        final LatLng? at = await _coordinateOf(a);
        // No location means discarded, not offered (James, 2026-09-12).
        if (at == null) continue;
        if (!withinGeofence(at.latitude, at.longitude, r)) continue;
        hits.add(
          PhotoCandidate(
            asset: a,
            takenUtc: a.createDateTime.toUtc(),
            lat: at.latitude,
            lng: at.longitude,
            alreadyUploaded: already.contains(a.id),
          ),
        );
      }
      hits.sort(
        (PhotoCandidate x, PhotoCandidate y) =>
            x.takenUtc.compareTo(y.takenUtc),
      );
      if (hits.isNotEmpty) {
        out.add(RunScanResult(run: r, candidates: hits));
      }
      onProgress?.call(++done, usable.length);
    }
    out.sort(
      (RunScanResult a, RunScanResult b) =>
          b.run.startUtc.compareTo(a.run.startUtc),
    );
    return out;
  }

  Future<List<AssetEntity>> _assetsBetween(DateTime from, DateTime to) async {
    final FilterOptionGroup filter = FilterOptionGroup(
      imageOption: const FilterOption(needTitle: false),
      createTimeCond: DateTimeCond(min: from.toLocal(), max: to.toLocal()),
      orders: const <OrderOption>[
        OrderOption(type: OrderOptionType.createDate, asc: true),
      ],
    );
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
      filterOption: filter,
    );
    if (paths.isEmpty) return const <AssetEntity>[];
    final AssetPathEntity all = paths.first;
    final int count = await all.assetCountAsync;
    if (count <= 0) return const <AssetEntity>[];
    final List<AssetEntity> out = <AssetEntity>[];
    // Paged: a wide sweep over a long history can be thousands of rows, and
    // one unbounded fetch is what makes a gallery app stutter.
    const int page = 500;
    for (int start = 0; start < count; start += page) {
      out.addAll(
        await all.getAssetListRange(
          start: start,
          end: math.min(start + page, count),
        ),
      );
    }
    return out;
  }

  /// The asset's coordinate. The entity's own fields are filled on Android and
  /// often zero on iOS, where the location lives behind an async call.
  Future<LatLng?> _coordinateOf(AssetEntity a) async {
    double lat = a.latitude ?? 0;
    double lng = a.longitude ?? 0;
    if (lat == 0 && lng == 0) {
      try {
        final pm.LatLng? ll = await a.latlngAsync();
        lat = ll?.latitude ?? 0;
        lng = ll?.longitude ?? 0;
      } catch (e, s) {
        BootLogger.logError('[CameraRollScan._coordinateOf] ${a.id}', e, s);
        return null;
      }
    }
    // Null island is a stripped coordinate, not a real fix in the Atlantic.
    if (lat == 0 && lng == 0) return null;
    return LatLng(lat, lng);
  }
}
