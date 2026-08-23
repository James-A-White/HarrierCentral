import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';
import 'package:harrier_central/pages/live_run_pages/lost_compass_dialog.dart';
import 'package:harrier_central/pages/run_admin/add_down_down_page.dart';
import 'package:harrier_central/widgets/tracking_quality_dialog.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:torch_light/torch_light.dart';

// Trail-mark control tiles. A marker is a glyph or a short text on a yellow
// rounded square (no border), per docs/trail_markers/SPEC.md §4. Glyphs are
// bare monochrome silhouettes tinted to the ink colour (fixed-colour glyphs —
// e.g. Caution — render as-is); text stacks on spaces.
const Color _slotTileYellow = Color(0xFFFCFF04);
const Color _slotTileInk = Color(0xFF2D0000);
const Color _slotTileInvertBg = Color(0xFF2D0000);
const Color _slotTileInvertInk = Color(0xFFFFFDF0);
const double _slotTileSize = 54;

/// A single square trail-mark tile. Shared by the control grid and the tap
/// flash. Renders the same way the map and public-web will.
Widget trailSlotTile(TrailSlot slot, {required double size}) {
  final glyph = slot.glyph;
  final fixed = glyph?.fixed ?? false;
  final invert = slot.invert && !fixed; // fixed glyphs ignore invert
  final bg = invert ? _slotTileInvertBg : _slotTileYellow;
  final ink = invert ? _slotTileInvertInk : _slotTileInk;

  return Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * 0.13),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(size * 0.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: _slotTileContent(slot, glyph, fixed, ink),
  );
}

Widget _slotTileContent(
  TrailSlot slot,
  TrailGlyph? glyph,
  bool fixed,
  Color ink,
) {
  if (slot.kind == 'text') {
    final t = (slot.text ?? '').trim();
    if (t.isEmpty) return const SizedBox.shrink();
    final lines = t.split(' ').where((l) => l.isNotEmpty).toList();
    return FittedBox(
      fit: BoxFit.contain,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in lines)
            Text(
              line,
              style: TextStyle(
                color: ink,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
        ],
      ),
    );
  }
  if (glyph == null) return Icon(Icons.help_outline, color: ink);
  return Image.asset(
    glyph.assetPath,
    fit: BoxFit.contain,
    color: fixed ? null : ink, // mono → tint to ink; fixed → full colour
    colorBlendMode: fixed ? null : BlendMode.srcIn,
    errorBuilder: (_, _, _) => const Icon(Icons.place, color: customRed),
  );
}

class LiveRunGeneralController extends GetxController {
  LiveRunGeneralController({required this.run}) {
    LiveRunService.ensure();
  }

  final RunDetailsAggregate run;
  final LocationService _locationService = Get.find<LocationService>();

  final RxBool isTracking = false.obs;
  final RxBool torchOn = false.obs;
  final RxDouble distanceKm = 0.0.obs;
  final Rx<Duration> elapsed = const Duration().obs;
  final Rx<Position?> lastPosition = Rx<Position?>(null);

  /// The trail lane the runner declares they're running. Rides on the track as
  /// `TRL::<value>`. Defaults to Normal (#3) — always one of the kennel's
  /// visible types since Normal can never be hidden.
  final RxInt selectedTrailValue = TrailType.normalValue.obs;

  /// Visible, ordered trail types for this run's kennel (built-ins merged with
  /// the kennel's customisations). Always includes Normal.
  List<TrailType> get trailTypes => run.kennel.trailTypes;

  // Exposes LocationService.isPaused directly so the UI Obx can observe it.
  RxBool get isPaused => _locationService.isPaused;

  // True once the event is within 5 minutes of starting (or already started).
  late final RxBool canStartTracking;

  DateTime? _trackingStartedAt;
  DateTime? _trackingEndedAt;
  Timer? _elapsedTicker;
  Timer? _preRunTimer;
  Worker? _trackingWorker;
  Worker? _positionWorker;

  @override
  void onInit() {
    super.onInit();
    isTracking.value = _locationService.joinRunTracking.value;
    lastPosition.value = _locationService.lastKnownPosition.value;

    canStartTracking = _checkCanStart().obs;
    if (!canStartTracking.value) {
      _preRunTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        if (_checkCanStart()) {
          canStartTracking.value = true;
          _preRunTimer?.cancel();
          _preRunTimer = null;
        }
      });
    }

    _trackingWorker = ever<bool>(
      _locationService.joinRunTracking,
      _handleTrackingToggle,
    );
    _positionWorker = ever<Position?>(
      _locationService.lastKnownPosition,
      _handlePosition,
    );

    if (isTracking.value) {
      _trackingStartedAt ??= DateTime.now();
      _startElapsedTicker();
    }
  }

  @override
  void onReady() {
    super.onReady();
    if (getIntPref(IntPrefsEnum.trackingQuality) == null) {
      final ctx = Get.context;
      if (ctx != null) showTrackingQualityDialog(ctx);
    }
  }

  @override
  void onClose() {
    _preRunTimer?.cancel();
    _trackingWorker?.dispose();
    _positionWorker?.dispose();
    _stopElapsedTicker();
    // Never leave the torch burning after the page goes away.
    if (torchOn.value) unawaited(TorchLight.disableTorch());
    super.onClose();
  }

  /// Toggles the phone's torch. Reports failure rather than silently doing
  /// nothing (no flash unit, or the camera is held by another app).
  Future<void> toggleTorch() async {
    try {
      if (torchOn.value) {
        await TorchLight.disableTorch();
        torchOn.value = false;
      } else {
        await TorchLight.enableTorch();
        torchOn.value = true;
      }
    } catch (_) {
      torchOn.value = false;
      Get.snackbar(
        'Torch unavailable',
        'This device would not turn its light on — another app may be using '
            'the camera.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: hc_red,
        colorText: Colors.white,
      );
    }
  }

  /// Opens the OS share sheet with the full-screen PackTrack page for this run
  /// — the live map, no app needed. The dedicated /packtrack route requires a
  /// numeric run number (it 404s otherwise), so uncounted runs, which have
  /// none, fall back to the legacy run-detail link; its in-page map still
  /// shows the live track.
  Future<void> shareRun() async {
    final String url = run.event.isCountedRun != 0
        ? '$BASE_HASHRUNS_DOT_ORG_URL${run.kennel.kennelUniqueShortName}/${run.event.eventNumber}/packtrack'
        : '$BASE_HASHRUNS_DOT_ORG_URL#/RID?publicEventId=${run.event.publicEventId}';
    final String name = run.event.eventName.isEmpty
        ? '${run.kennel.kennelShortName} run'
        : run.event.eventName;
    await SharePlus.instance.share(
      ShareParams(
        text:
            "I'm running $name with ${run.kennel.kennelShortName} — "
            'follow me live: $url',
        subject: 'Follow my hash live',
      ),
    );
  }

  bool _checkCanStart() {
    return DateTime.now().toUtc().isAfter(
      run.event.eventStartDatetimeGmt.toUtc().subtract(
        const Duration(minutes: 5),
      ),
    );
  }

  // Local-time label shown on the disabled start button.
  String get trackingOpensAt {
    final opensAt = run.event.eventStartDatetimeGmt.toLocal().subtract(
      const Duration(minutes: 5),
    );
    return DateFormat('h:mm a').format(opensAt);
  }

  Future<void> toggleTracking() async {
    final newValue = !_locationService.joinRunTracking.value;
    _locationService.eventId = run.event.eventId;
    _locationService.userId = getStringPref(StringPrefsEnum.userId);

    if (!newValue) {
      _locationService.joinRunTracking.value = false;
      _stopElapsedTicker();
      return;
    }

    // Starting. Default to a fresh session…
    _preRunTimer?.cancel();
    _preRunTimer = null;
    _trackingStartedAt = DateTime.now();
    distanceKm.value = 0.0;
    elapsed.value = Duration.zero;

    // …but if the server already holds a track for this runner+event (the app
    // was closed or tracking stopped mid-run), continue it: seed the distance
    // and elapsed clock from the stored track so the HUD doesn't reset to zero,
    // and strip any On-Inn terminator so the resumed points render as one line.
    await _resumeExistingTrackIfAny();

    _locationService.joinRunTracking.value = newValue;

    // Tag the (new or continued) track with the declared lane so playback can
    // label/filter it. Fire-and-forget — joinRunTracking is true so it buffers.
    unawaited(_locationService.declareTrailType(selectedTrailValue.value));
  }

  /// Detects an already-stored track for this runner on this event and, if
  /// present, continues it instead of starting from scratch. Reads the stored
  /// points once, seeds [LocationService.seedSessionTrack] so live distance
  /// carries on, re-bases the elapsed clock on the earliest point, and deletes
  /// any terminator marks so the continuation draws as a single track.
  ///
  /// Entirely best-effort: any failure (offline, endpoint not yet deployed,
  /// parse error) is swallowed and the run simply starts fresh — never blocks
  /// the user from tracking.
  Future<void> _resumeExistingTrackIfAny() async {
    final userId = _locationService.userId;
    final eventId = _locationService.eventId;
    if (userId == null ||
        userId.isEmpty ||
        eventId == null ||
        eventId.isEmpty) {
      return;
    }

    final api = GetPositionsApi();
    try {
      final payload = await api.fetchPositions(
        eventId: eventId,
        latestClientTimestampMs: '0000000000000000000',
        userId: userId,
      );
      final mine = payload.users.firstWhereOrNull(
        (u) => normalizeUuid(u.id) == normalizeUuid(userId),
      );
      final positions = mine?.positions ?? const <TrackPoint>[];
      if (positions.isEmpty) return; // genuinely fresh run — nothing to resume

      // Seed live distance from the stored track (recomputed with the same
      // filter the map uses) so the HUD continues rather than restarting at 0.
      _locationService.seedSessionTrack(positions);
      distanceKm.value =
          _locationService.filteredSessionDistanceMeters.value / 1000.0;

      // Re-base the elapsed clock on the earliest stored point.
      final firstTs = positions
          .map((p) => p.timestampMs)
          .reduce((a, b) => a < b ? a : b);
      _trackingStartedAt = DateTime.fromMillisecondsSinceEpoch(firstTs);
      elapsed.value = DateTime.now().difference(_trackingStartedAt!);

      // Strip any terminator(s) so the resumed portion isn't cut off. OIN (On
      // Inn) stops the drawn polyline at the first occurrence, so a stale one
      // from before the stop would hide everything after it.
      await _stripTrackTerminators(eventId, userId, positions);
    } catch (e) {
      if (kDebugMode) debugPrint('[LiveRun] resume-existing-track failed: $e');
    } finally {
      api.dispose();
    }
  }

  /// Deletes any On-Inn terminator points from the stored track so a resumed
  /// run renders continuously. Identifies terminators locally (same rule the
  /// map uses) and asks the server to remove exactly those points by timestamp.
  Future<void> _stripTrackTerminators(
    String eventId,
    String userId,
    List<TrackPoint> positions,
  ) async {
    final terminatorTsMs = positions
        .where((p) => _isTerminatorType(p.type))
        .map((p) => p.timestampMs)
        .toList(growable: false);
    if (terminatorTsMs.isEmpty) return;

    final api = DeletePositionsApi();
    try {
      await api.deletePoints(
        eventId: eventId,
        userId: userId,
        timestampsMs: terminatorTsMs,
      );
    } finally {
      api.dispose();
    }
  }

  /// True if [type] is an On-Inn terminator (the only mark that stops the drawn
  /// track). Compares the key directly rather than via [HashRunPointTypes.fromKey],
  /// which throws on non-enum keys (e.g. new-style `I-NNN.png` slot icons).
  bool _isTerminatorType(String? type) {
    if (type == null || type.isEmpty) return false;
    final parts = type.split('::');
    // New marks declare termination via the endRun action…
    if (parts.any((p) => p.trim() == 'A=endRun')) return true;
    // …legacy marks are the On-Inn enum key.
    return parts.first.trim() == HashRunPointTypes.onInn.key;
  }

  /// Sets the runner's declared trail lane. If tracking is already underway,
  /// re-declares immediately (last declaration wins) so the change is recorded.
  void selectTrailType(int value) {
    if (selectedTrailValue.value == value) return;
    selectedTrailValue.value = value;
    if (isTracking.value) {
      unawaited(_locationService.declareTrailType(value));
    }
  }

  Future<void> pauseTracking() async {
    await _locationService.pauseTracking();
    _stopElapsedTicker();
  }

  void resumeTracking() {
    _locationService.resumeTracking();
    // _handleTrackingToggle fires when joinRunTracking becomes true,
    // restarting the elapsed ticker.
  }

  void stopTracking() {
    _trackingEndedAt = DateTime.now();
    unawaited(_locationService.stopTracking());
    _stopElapsedTicker();
  }

  /// Ends the run from the "Are you On Inn?" dialog. With [markOnInn] the
  /// stop is recorded as an On-Inn terminator first (one-shot fix, force-
  /// flushed while the buffer is still alive) so the drawn track ends with
  /// the icon; "I stopped early" leaves no mark — the trail just ends, so an
  /// early bailer never shows an On-Inn in the middle of nowhere
  /// (docs/packtrack_auto_stop_plan.md).
  Future<void> endRun({required bool markOnInn}) async {
    if (markOnInn) {
      try {
        await _locationService.markPoint(HashRunPointTypes.onInn);
      } catch (_) {
        // Best-effort: a failed one-shot fix must never block the stop.
      }
    }
    stopTracking();
  }

  // Same-slot cooldown + pending-mark state (butt-dial/double-tap guard:
  // two Whichy Ways landed 6s apart on the 2026-08-16 walking test).
  static const Duration _slotCooldown = Duration(seconds: 8);
  final Map<String, DateTime> _lastSlotMarkAt = {};
  Future<PendingSlotMark>? _pendingCapture;

  /// True when [slot] was marked within the last [_slotCooldown] — the tap is
  /// swallowed silently (a legitimate second identical mark that close
  /// together doesn't exist; a deliberate mistake is what Undo is for).
  /// Different slots are never blocked.
  bool slotCooldownActive(TrailSlot slot) {
    final last = _lastSlotMarkAt[slot.trackType()];
    return last != null && DateTime.now().difference(last) < _slotCooldown;
  }

  /// Deferred-commit mark, step 1: capture position + timestamp at the moment
  /// of the tap. Nothing is queued or uploaded yet — the flash card's outcome
  /// decides: dismissal (timeout / tap-away) → [commitPendingMark]; Undo →
  /// [discardPendingMark]. Undo therefore never needs a server delete.
  void captureSlotMark(TrailSlot slot, {String? label}) {
    _lastSlotMarkAt[slot.trackType()] = DateTime.now();
    _pendingCapture = _locationService.captureSlotMark(slot, label: label);
  }

  /// Deferred-commit mark, step 2a: the card was dismissed without Undo —
  /// queue the captured point on the track buffer and flush. Awaits the
  /// capture first (the one-shot GPS fix may still be resolving when the card
  /// times out).
  Future<void> commitPendingMark() async {
    final pending = _pendingCapture;
    _pendingCapture = null;
    if (pending == null) return;
    try {
      final mark = await pending;
      await _locationService.commitSlotMark(mark);
    } catch (_) {
      // GPS fix failed — there is no position to record. Nothing was shown as
      // recorded beyond the flash card, so fail silently.
    }
  }

  /// Deferred-commit mark, step 2b: Undo — drop the captured point. It was
  /// never queued, so there is nothing to remove locally or remotely.
  void discardPendingMark() {
    _pendingCapture = null;
  }

  /// Returns the timestamp (epoch ms) that should be stamped on the GPS track
  /// marker for a photo taken right now.
  ///
  /// - Before tracking starts: the run's scheduled start time, so the marker
  ///   sits at the beginning of the timeline.
  /// - During / paused: current time (normal behaviour).
  /// - After tracking ends: the moment tracking stopped, so the marker sits
  ///   at the end of the timeline.
  int get _photoMarkerTimestampMs {
    if (isTracking.value || isPaused.value) {
      return DateTime.now().millisecondsSinceEpoch;
    }
    if (_trackingEndedAt != null) {
      return _trackingEndedAt!.millisecondsSinceEpoch;
    }
    // Pre-run: anchor to the scheduled start so the photo lands at t=0.
    return run.event.eventStartDatetimeGmt.millisecondsSinceEpoch;
  }

  Future<void> takePhoto() async {
    final blobUrl = await KennelPhotoService().captureAndUpload(
      eventId: run.event.eventId,
      kennelId: run.kennel.kennelId,
      kennelSlug: run.kennel.kennelUniqueShortName,
      eventNumber: run.event.eventNumber,
      markerTimestampMs: _photoMarkerTimestampMs,
      skipMapMarker: _trackingStartedAt == null || _trackingEndedAt != null,
    );
    if (blobUrl != null) {
      Get.snackbar(
        'Photo saved',
        'Your photo has been added to the run.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: hc_blue,
      );
    }
  }

  /// Multi Photo cap. Multiple shots should be a deliberate choice, not the
  /// default — an uncapped loop drowns the Hash Flash in near-duplicates.
  static const int _multiPhotoLimit = 6;

  /// Multi Photo: reopens the camera after each saved shot so a trail
  /// photographer can shoot a burst without renavigating. Each photo still
  /// passes the normal review page (Discard / Edit / Save) — the loop only
  /// removes the between-shots navigation. Ends when the camera is
  /// cancelled, a step fails, or [_multiPhotoLimit] photos are taken.
  Future<void> takePhotoSession() async {
    int taken = 0;
    var stop = false;
    while (!stop && taken < _multiPhotoLimit) {
      var outcome = KennelPhotoCaptureOutcome.failed;
      await KennelPhotoService().captureAndUpload(
        eventId: run.event.eventId,
        kennelId: run.kennel.kennelId,
        kennelSlug: run.kennel.kennelUniqueShortName,
        eventNumber: run.event.eventNumber,
        markerTimestampMs: _photoMarkerTimestampMs,
        skipMapMarker: _trackingStartedAt == null || _trackingEndedAt != null,
        onOutcome: (o) => outcome = o,
      );
      if (outcome == KennelPhotoCaptureOutcome.uploaded ||
          outcome == KennelPhotoCaptureOutcome.queuedOffline) {
        taken++;
      } else if (outcome != KennelPhotoCaptureOutcome.discarded) {
        // cancelledAtCamera or failed — end the session. A discarded photo
        // just reopens the camera (they binned one shot, not the session).
        stop = true;
      }
    }
    if (taken == 0) return;
    final bool hitLimit = taken >= _multiPhotoLimit;
    Get.snackbar(
      hitLimit ? "That's plenty!" : 'Photos added',
      hitLimit
          ? '$_multiPhotoLimit photos added to the run — the Hash Flash '
                'thanks you 🍺'
          : '$taken photo${taken == 1 ? '' : 's'} added to the run.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: hc_blue,
      colorText: Colors.white,
    );
  }

  /// Stamps a DDN (gavel) GPS marker at the current location if tracking is
  /// active. Called by the Make a Charge button before navigating to the form.
  Future<void> markChargeLocation() async {
    if (isTracking.value || isPaused.value) {
      await _locationService.markPoint(HashRunPointTypes.downDown);
    }
  }

  /// Timestamps of EVERY distress mark this session dropped.
  ///
  /// A list, not a single value: the compass now offers "Tell the pack again"
  /// alongside the all clear, so a runner who has moved can drop a fresh mark
  /// where they are now. Holding only the latest would strand every earlier
  /// LOST badge on the live map permanently — the all clear would tidy up one
  /// and leave the rest sending sweepers to places the runner left long ago.
  final List<int> _distressMarkMs = <int>[];

  /// Tells the pack the runner is back on trail, and removes the distress mark
  /// from the live map so nobody keeps searching. The chat message is the
  /// permanent record; the map should only show what is still true.
  Future<bool> sendFoundTrailMessage() async {
    final String name =
        getStringPref(StringPrefsEnum.displayName) ?? 'A hasher';
    final Position? pos = lastPosition.value;
    final String where = pos == null
        ? ''
        : ' Location: https://maps.google.com/?q='
              '${pos.latitude.toStringAsFixed(5)},'
              '${pos.longitude.toStringAsFixed(5)}';

    // Clear the marks first so the map is right even if the message fails.
    if (_distressMarkMs.isNotEmpty) {
      final api = DeletePositionsApi();
      try {
        await api.deletePoints(
          eventId: run.event.eventId,
          userId: currentUserId,
          timestampsMs: List<int>.of(_distressMarkMs),
        );
        _distressMarkMs.clear();
      } catch (e) {
        if (kDebugMode) debugPrint('[LiveRun] clear distress marks failed: $e');
      } finally {
        api.dispose();
      }
    }

    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    final String messageId = const Uuid().v4();

    final String result = await ServiceCommon.sendHttpPost(() {
      return jsonEncode(<String, dynamic>{
        'queryType': 'sendEventMessage',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_sendEventMessage',
          paramString: deviceSecret,
        ),
        'eventId': run.event.eventId,
        'messageId': messageId,
        'messageContent': '✅ BACK ON TRAIL — $name has found the trail.$where',
        'messageReleasabilityFlags': kChatReleasabilityAssistance,
      });
    });
    return !result.startsWith(ERROR_PREFIX);
  }

  /// Broadcasts an assistance request into the run chat — a normal event chat
  /// message, so the pack is push-notified per their notification prefs — with
  /// the runner's current location as a maps link. When tracking, also drops a
  /// labelled mark on the live track so the pack map shows where the call came
  /// from. The two go out in parallel; the result reports each separately so
  /// the user is told exactly what got through.
  Future<({bool chatSent, bool markPlaced})> sendAssistanceMessage({
    required bool urgent,
  }) async {
    final String name =
        getStringPref(StringPrefsEnum.displayName) ?? 'A hasher';
    final Position? pos = lastPosition.value;
    final String where = pos == null
        ? '(location unavailable)'
        : 'https://maps.google.com/?q=${pos.latitude.toStringAsFixed(5)},${pos.longitude.toStringAsFixed(5)}';
    final String text = urgent
        ? '🆘 HELP NEEDED — $name needs assistance on trail! Location: $where'
        : "🧭 I'M LOST — $name has lost the trail. Location: $where";

    // Drop a distress mark so the call shows on EVERY PackTrack user's map.
    // markPointAt (not markPoint) because it stands up its own buffer when
    // needed — someone who never started tracking, or already pressed End Run,
    // is exactly the person most likely to be lost, and they must still appear.
    // immediate: true sends it out of band, so it never waits behind the live
    // track's in-flight batch. Started BEFORE the chat POST and awaited after,
    // so GPS acquisition overlaps the chat round-trip instead of delaying it.
    // Remembered so "I've found the trail" can clear it: a LOST badge left
    // sitting on the live map after the runner is fine sends the sweepers
    // looking for someone who is already back with the pack.
    final int markMs = DateTime.now().millisecondsSinceEpoch;

    // Replace-within-window: a re-announce moments after the last one (double
    // press, dialog closed and reopened — two identical LST marks landed 21s
    // apart on Trail #2058, 2026-08-16) must MOVE the marker, not add a
    // second. "Tell the pack again" after real time/movement still adds a
    // fresh mark. Best-effort: a failed delete just leaves the old badge for
    // the all clear to collect.
    if (_distressMarkMs.isNotEmpty &&
        markMs - _distressMarkMs.last < 2 * 60 * 1000) {
      final int stale = _distressMarkMs.removeLast();
      final api = DeletePositionsApi();
      try {
        await api.deletePoints(
          eventId: run.event.eventId,
          userId: currentUserId,
          timestampsMs: [stale],
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[LiveRun] replace stale distress mark failed: $e');
        }
      } finally {
        api.dispose();
      }
    }
    _distressMarkMs.add(markMs);

    final Future<bool> markFuture = _locationService.markPointAt(
      pointType: urgent
          ? HashRunPointTypes.helpNeeded
          : HashRunPointTypes.lostRunner,
      timestampMs: markMs,
      overrideEventId: run.event.eventId,
      overrideUserId: currentUserId,
      label: '$name · ${DateFormat('h:mm a').format(DateTime.now())}',
      immediate: true,
    );

    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    final String messageId = const Uuid().v4();

    final String result = await ServiceCommon.sendHttpPost(() {
      // Minted inside the closure: fresh token per attempt (token retry).
      return jsonEncode(<String, dynamic>{
        'queryType': 'sendEventMessage',
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_sendEventMessage',
          paramString: deviceSecret,
        ),
        'eventId': run.event.eventId,
        'messageId': messageId,
        'messageContent': text,
        'messageReleasabilityFlags': kChatReleasabilityAssistance,
      });
    });
    return (
      chatSent: !result.startsWith(ERROR_PREFIX),
      markPlaced: await markFuture,
    );
  }

  void _handleTrackingToggle(bool value) {
    isTracking.value = value;
    if (value) {
      _trackingStartedAt ??= DateTime.now();
      _startElapsedTicker();
    } else {
      _stopElapsedTicker();
      _pushWatchState();
    }
  }

  /// Immediate-commit mark from the Apple Watch companion. Wrist taps are
  /// deliberate — no flash card, no Undo — so the mark goes straight to the
  /// track buffer. Deliberately bypasses [_pendingCapture] so a flash card
  /// open on the phone at the same moment keeps its own pending mark.
  /// Shares the same-slot cooldown with phone taps.
  Future<bool> markFromWatch(TrailSlot slot) async {
    if (!isTracking.value) return false;
    if (slotCooldownActive(slot)) return false;
    _lastSlotMarkAt[slot.trackType()] = DateTime.now();
    try {
      final mark = await _locationService.captureSlotMark(slot);
      await _locationService.commitSlotMark(mark);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Mirrors the session onto the paired Apple Watch. Rides the 1-second
  /// elapsed ticker while tracking; the stop path sends the final
  /// tracking-false broadcast that returns the wrist to its idle screen.
  void _pushWatchState() {
    if (!Get.isRegistered<WatchBridgeService>()) return;
    unawaited(WatchBridgeService.to.pushState(
      tracking: isTracking.value,
      paused: isPaused.value,
      distanceKm: isTracking.value ? distanceKm.value : null,
      elapsedSec: elapsed.value.inSeconds,
      eventName: run.event.eventName,
      powerSaver: (getIntPref(IntPrefsEnum.trackingQuality) ?? 2) == 0,
    ));
  }

  void _handlePosition(Position? position) {
    lastPosition.value = position;
    if (!isTracking.value || position == null) return;
    distanceKm.value =
        _locationService.filteredSessionDistanceMeters.value / 1000.0;
    _trackingStartedAt ??= DateTime.now();
    _updateElapsed();
  }

  void _startElapsedTicker() {
    _elapsedTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed();
      _pushWatchState();
    });
    _updateElapsed();
    _pushWatchState();
  }

  void _stopElapsedTicker() {
    _elapsedTicker?.cancel();
    _elapsedTicker = null;
  }

  void _updateElapsed() {
    final started = _trackingStartedAt;
    if (started == null) return;
    elapsed.value = DateTime.now().difference(started);
  }

  String formattedElapsed() {
    final totalSeconds = elapsed.value.inSeconds;
    final hours = (totalSeconds ~/ 3600).toString().padLeft(1, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

class LiveRunGeneralPage extends StatelessWidget {
  LiveRunGeneralPage({super.key, required this.run})
    : controller = Get.put(
        LiveRunGeneralController(run: run),
        tag: 'live-run-general-${run.event.eventId}',
      );

  final RunDetailsAggregate run;
  final LiveRunGeneralController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Backgrounds.defaultHcBackground(),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                // Scrollable so the tool stack degrades gracefully on short
                // screens instead of throwing a RenderFlex overflow.
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopButtons(context),
                      _buildTrailTypePicker(context),
                      const SizedBox(height: 12),
                      _buildStatsRow(),
                      const SizedBox(height: 12),
                      // _buildActionsRow(context),
                      // const SizedBox(height: 12),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMarkerGrid(context),
                            _buildActionButtons(context),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAssistRow(context),
                      const SizedBox(height: 8),
                      _buildUtilityRow(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopButtons(BuildContext context) {
    return Obx(() {
      final tracking = controller.isTracking.value;

      final buttonShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      );
      const buttonPadding = EdgeInsets.symmetric(vertical: 3);

      final paused = controller.isPaused.value;

      if (!tracking && !paused) {
        // Not running — full-width start button. Disabled until 5 min before start.
        final canStart = controller.canStartTracking.value;
        return SizedBox(
          height: 45,
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow, size: 20),
            label: Text(
              canStart
                  ? 'Start Run Tracking'
                  : 'Tracking available at ${controller.trackingOpensAt}',
              style: ts_button.copyWith(fontSize: canStart ? 18 : 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              disabledBackgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white60,
              padding: buttonPadding,
              shape: buttonShape,
            ),
            onPressed: canStart ? controller.toggleTracking : null,
          ),
        );
      }

      // Tracking or paused — left button toggles Auto Pause / Resume,
      // right button ends the run.
      final leftButton = paused
          ? ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow, size: 20, color: Colors.white),
              label: Text('Resume', style: ts_button.copyWith(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: buttonPadding,
                shape: buttonShape,
              ),
              onPressed: controller.resumeTracking,
            )
          : ElevatedButton.icon(
              icon: const Icon(Icons.pause, size: 20, color: Colors.white),
              label: Text(
                'Auto Pause',
                style: ts_button.copyWith(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: buttonPadding,
                shape: buttonShape,
              ),
              onPressed: () => unawaited(controller.pauseTracking()),
            );

      return SizedBox(
        height: 45,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: leftButton),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hc_red,
                  foregroundColor: Colors.white,
                  padding: buttonPadding,
                  shape: buttonShape,
                ),
                onPressed: () async {
                  final choice = await showDialog<EndRunChoice>(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => AlertDialog(
                      title: Text('Are you On Inn?', style: ts_alertDialogTitle),
                      content: Text(
                        '"I\'m On Inn" marks the end of the trail on the map. '
                        'If you stopped before the end, choose "I stopped '
                        'early" — no mark is placed. Either way your data is '
                        'saved, and if you restart tracking later the run '
                        'continues from where it left off.',
                        style: ts_alertDialogBody,
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(EndRunChoice.keepTracking),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade600,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Keep Tracking', style: ts_button),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(EndRunChoice.stoppedEarly),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('I stopped early', style: ts_button),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.of(context).pop(EndRunChoice.onInn),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hc_red,
                            foregroundColor: Colors.white,
                          ),
                          child: Text("I'm On Inn", style: ts_button),
                        ),
                      ],
                    ),
                  );
                  if (choice == EndRunChoice.onInn) {
                    await controller.endRun(markOnInn: true);
                  } else if (choice == EndRunChoice.stoppedEarly) {
                    await controller.endRun(markOnInn: false);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'images/live_run_trail_markers/oninn.png',
                      height: 26,
                      width: 26,
                    ),
                    const SizedBox(width: 6),
                    Text('End Run', style: ts_button.copyWith(fontSize: 18)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildActionButtons(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The photo tile is split: single shot on top, Multi Photo
            // (camera reopens after each save, capped at 6) below.
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hc_blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                      ),
                      onPressed: () => unawaited(controller.takePhoto()),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_alt, size: 24),
                          const SizedBox(height: 2),
                          Text(
                            'Take Photo',
                            textAlign: TextAlign.center,
                            style: ts_button.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hc_blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                        ),
                      ),
                      onPressed: () =>
                          unawaited(controller.takePhotoSession()),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Two stacked cameras = burst.
                          SizedBox(
                            width: 32,
                            height: 26,
                            child: Stack(
                              children: const [
                                Positioned(
                                  left: 0,
                                  top: 0,
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 19,
                                    color: Colors.white70,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Icon(Icons.camera_alt, size: 19),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Multi Photo',
                            textAlign: TextAlign.center,
                            style: ts_button.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await controller.markChargeLocation();
                  if (!context.mounted) return;
                  await Get.to(
                    () => AddDownDownPage(
                      kennelId: controller.run.kennel.kennelId,
                      eventId: controller.run.event.eventId,
                      eventName: controller.run.event.eventName,
                      kennelSlug: controller.run.kennel.kennelUniqueShortName,
                      eventNumber: controller.run.event.eventNumber,
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(MaterialCommunityIcons.gavel, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Make a\nCharge',
                      textAlign: TextAlign.center,
                      style: ts_button.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            label: 'Dist (in km)',
            valueBuilder: () {
              final dist = controller.distanceKm.value;
              if (dist <= 0) return '--';
              // Power Saver's 20m sampling systematically under-reads distance
              // (15-20% on a twisty trail — CH3 2026-08-18 analysis), so mark
              // the number as approximate rather than let it read as exact.
              final powerSaver =
                  (getIntPref(IntPrefsEnum.trackingQuality) ?? 2) == 0;
              return '${powerSaver ? '~' : ''}${dist.toStringAsFixed(2)}';
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            label: 'Time',
            valueBuilder: controller.formattedElapsed,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String label,
    required String Function() valueBuilder,
  }) {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.lightBlueAccent.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AutoSizeText(
              label,
              style: ts_titleDarkRedLarge,
              maxLines: 1,
              minFontSize: 12,
            ),
            const SizedBox(height: 6),
            AutoSizeText(
              valueBuilder(),
              style: ts_titleCondensedVeryLargeBlack.copyWith(fontSize: 42),
              maxLines: 1,
              maxFontSize: 42,
              minFontSize: 20,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTrailTypePicker(BuildContext context) {
    final types = controller.trailTypes;
    // Nothing to choose when the kennel exposes a single lane (e.g. only
    // Normal): the default declaration still fires on start; just no picker.
    if (types.length <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Your trail',
            style: ts_button.copyWith(color: Colors.yellow, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Obx(() {
            final selected = controller.selectedTrailValue.value;
            // Full-width so WrapAlignment.center centres each row on the SCREEN,
            // not just within the block. Without this the picker shrink-wraps to
            // the widest row and the start-aligned parent Column pins it left.
            return SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in types)
                    _trailTypeChip(t, isSelected: t.value == selected),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _trailTypeChip(TrailType type, {required bool isSelected}) {
    return InkWell(
      onTap: () => controller.selectTrailType(type.value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? hc_blue : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type.emoji.isNotEmpty) ...[
              Text(type.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
            ],
            Text(
              type.label,
              style: ts_button.copyWith(
                fontSize: 14,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerGrid(BuildContext context) {
    final slots = run.kennel.trailSlots;

    const int perRow = 4;
    final rows = <Widget>[];
    for (var i = 0; i < slots.length; i += perRow) {
      final slice = slots.skip(i).take(perRow).toList(growable: false);
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              for (var j = 0; j < slice.length; j++) ...[
                _buildSlotButton(context, slice[j]),
                if (j != slice.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mark your trail map',
              style: ts_button.copyWith(color: Colors.yellow),
              textAlign: TextAlign.center,
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => showTrackingQualityDialog(context),
              child: const Icon(Icons.power, color: Colors.yellow, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...rows,
      ],
    );
  }

  Widget _buildSlotButton(BuildContext context, TrailSlot slot) {
    return Obx(() {
      // Marks attach a GPS point to the live track, so they're only usable
      // during an active (or paused) run. Keep the buttons visible always, but
      // dim + disable them until tracking starts.
      final active = controller.isTracking.value || controller.isPaused.value;
      return Opacity(
        opacity: active ? 1.0 : 0.4,
        child: InkWell(
          onTap: active ? () => unawaited(_handleSlotTap(context, slot)) : null,
          borderRadius: BorderRadius.circular(_slotTileSize * 0.2),
          child: trailSlotTile(slot, size: _slotTileSize),
        ),
      );
    });
  }

  /// Handles a trail-mark tap: prompts for a label if the slot needs one,
  /// flashes the confirmation, and records the mark. (On Inn is no longer a
  /// slot — ending the run is the End Run button's job.)
  Future<void> _handleSlotTap(BuildContext context, TrailSlot slot) async {
    // Double-tap / pocket-tap guard: an identical mark within seconds of the
    // last one is never deliberate — swallow it before any popup or flash.
    if (controller.slotCooldownActive(slot)) return;

    String? label;

    if (slot.parsedAction == TrailSlotAction.addText) {
      final popup = GetPointLabelPopup(
        title: 'Add Note',
        hintText: slot.name,
        confirmButtonText: 'Save',
        iconData: Icons.label_outline,
      );

      final dialogResult = await showDialog<Map<String, String>>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => popup,
      );

      final trimmed = dialogResult?['label']?.trim() ?? '';
      if (trimmed.isEmpty) return;
      label = trimmed;
    }

    if (!context.mounted) return;
    // Capture NOW (position + timestamp of the tap); the card's outcome
    // decides whether it is committed to the track or discarded.
    controller.captureSlotMark(slot, label: label);
    await _showSlotFlash(
      context,
      slot,
      label,
      onUndo: controller.discardPendingMark,
      onCommit: () => unawaited(controller.commitPendingMark()),
    );
  }

  /// "I'm Lost" / "Send Help" — pack-assist broadcasts. Replaced the old
  /// cramped chat strip (2026-08-01); the full Chat tab is one tap away on
  /// the bottom nav.
  Widget _buildAssistRow(BuildContext context) {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return SizedBox(
      height: 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.explore_off, size: 22),
              label: Text("I'm Lost", style: ts_button.copyWith(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange.shade700,
                foregroundColor: Colors.white,
                shape: buttonShape,
              ),
              onPressed: () =>
                  unawaited(_confirmAndSendAssist(context, urgent: false)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sos, size: 22),
              label: Text('Send Help', style: ts_button.copyWith(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: hc_red,
                foregroundColor: Colors.white,
                shape: buttonShape,
              ),
              onPressed: () =>
                  unawaited(_confirmAndSendAssist(context, urgent: true)),
            ),
          ),
        ],
      ),
    );
  }

  /// Torch + share-my-run. Utility tools, not trail actions — always enabled,
  /// including before tracking starts.
  Widget _buildUtilityRow() {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return SizedBox(
      height: 52,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Obx(() {
              final on = controller.torchOn.value;
              return ElevatedButton.icon(
                icon: Icon(
                  on ? Icons.flashlight_on : Icons.flashlight_off,
                  size: 22,
                ),
                label: Text(
                  on ? 'Light On' : 'Flashlight',
                  style: ts_button.copyWith(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: on ? Colors.amber.shade600 : Colors.blueGrey,
                  foregroundColor: on ? Colors.black87 : Colors.white,
                  shape: buttonShape,
                ),
                onPressed: () => unawaited(controller.toggleTorch()),
              );
            }),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.ios_share, size: 22),
              label: Text(
                'Share My Run',
                style: ts_button.copyWith(fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: hc_blue,
                foregroundColor: Colors.white,
                shape: buttonShape,
              ),
              onPressed: () => unawaited(controller.shareRun()),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndSendAssist(
    BuildContext context, {
    required bool urgent,
  }) async {
    // "I'm Lost" is a question before it's an announcement. Open the compass
    // straight away and let the runner decide whether to tell anyone — most of
    // the time the arrow answers it and nobody needs troubling. Send Help is
    // the opposite: it exists to notify, so it still confirms and sends.
    if (!urgent) {
      await showLostCompassDialog(
        context,
        run.event.eventId,
        kennelDistanceUnitsPref: run.extensions.distanceUnitsPref,
        onAnnounceLost: () => controller.sendAssistanceMessage(urgent: false),
        onAnnounceFound: controller.sendFoundTrailMessage,
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(
          urgent ? 'Send Help Request?' : "Tell the pack you're lost?",
          style: ts_alertDialogTitle,
        ),
        content: Text(
          urgent
              ? 'This sends an urgent request for assistance to the run chat, '
                    'including your current location. The pack will be notified.'
              : "This posts a message to the run chat letting the pack know "
                    "you've lost the trail, including your current location.",
          style: ts_alertDialogBody,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade600,
              foregroundColor: Colors.white,
            ),
            child: Text('Cancel', style: ts_button),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: urgent ? hc_red : Colors.deepOrange.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(urgent ? 'Send Help' : "I'm Lost", style: ts_button),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await controller.sendAssistanceMessage(urgent: urgent);
    final bool anySent = result.chatSent || result.markPlaced;
    Get.snackbar(
      anySent ? 'Pack notified' : 'Nothing got through',
      result.chatSent && result.markPlaced
          ? 'Message sent and your position is marked on the run map.'
          : result.chatSent
          ? 'Message sent, but your position could not be marked on the map.'
          : result.markPlaced
          ? 'Your position is marked on the run map, but the chat message '
                'failed to send.'
          : 'No signal — nothing could be sent. Try again when you have a bar.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: anySent ? hc_blue : hc_red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }
}

// ---------------------------------------------------------------------------
// Slot flash overlay — shown immediately on tap, dismissed after 8 s or tap.
// Carries the Undo button, and decides the pending mark's fate: any dismissal
// without Undo (timeout, tap-away, navigation) fires onCommit exactly once;
// Undo fires onUndo instead and the mark is never recorded.
// ---------------------------------------------------------------------------

Future<void> _showSlotFlash(
  BuildContext context,
  TrailSlot slot,
  String? label, {
  VoidCallback? onUndo,
  VoidCallback? onCommit,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (_) => _SlotFlashDialog(
      slot: slot,
      label: label,
      onUndo: onUndo,
      onCommit: onCommit,
    ),
  );
}

class _SlotFlashDialog extends StatefulWidget {
  const _SlotFlashDialog({
    required this.slot,
    this.label,
    this.onUndo,
    this.onCommit,
  });
  final TrailSlot slot;
  final String? label;
  final VoidCallback? onUndo;
  final VoidCallback? onCommit;

  @override
  _SlotFlashDialogState createState() => _SlotFlashDialogState();
}

class _SlotFlashDialogState extends State<_SlotFlashDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);
    _opacity = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
    // Matches the undo window (_slotCooldown) — the popup IS the undo surface.
    _timer = Timer(const Duration(seconds: 8), _dismiss);
  }

  // The mark's fate is settled exactly once, whichever way the card goes away
  // (Undo, tap-away, timeout, or the route being torn down): dispose() is the
  // commit safety net, so even an unexpected dismissal records the mark unless
  // Undo was pressed.
  bool _settled = false;

  void _undo() {
    if (!_settled) {
      _settled = true;
      widget.onUndo?.call();
    }
    _dismiss();
  }

  void _settleCommit() {
    if (_settled) return;
    _settled = true;
    widget.onCommit?.call();
  }

  @override
  void dispose() {
    _settleCommit();
    _animCtrl.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    _settleCommit();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismiss,
      behavior: HitTestBehavior.opaque,
      child: FadeTransition(
        opacity: _opacity,
        child: Center(
          child: ScaleTransition(
            scale: _scale,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 36,
                  horizontal: 40,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    trailSlotTile(widget.slot, size: 160),
                    const SizedBox(height: 16),
                    Text(
                      widget.slot.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    if (widget.label?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.label!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          decoration: TextDecoration.none,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (widget.onUndo != null) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(160, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.undo, size: 20),
                        label: const Text(
                          'Undo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _undo,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Tap to dismiss',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
