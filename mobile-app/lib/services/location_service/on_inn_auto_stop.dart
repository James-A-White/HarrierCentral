import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';

/// Watches an active tracking session and prompts "Are you On Inn?" when the
/// runner has been stationary near other runners' On-Inn marks — the signal
/// that the run is over and they forgot to stop tracking
/// (docs/packtrack_auto_stop_plan.md).
///
/// Deliberately NOT inactivity-based on its own: a long drink stop is
/// indistinguishable from being done by motion alone, so the trigger requires
/// BOTH stationary-ness AND proximity to somebody else's terminal On-Inn.
/// The first finisher has no cluster to test against; they stop manually,
/// seeding the anchor for everyone behind them.
///
/// Stationary-ness is inferred from the ABSENCE of position callbacks: the
/// tracking distance filter (5–20 m) means a phone that isn't moving delivers
/// no fixes at all, so "no fix for N minutes" is the stationary signal — the
/// positions themselves never say "not moving".
///
/// If the prompt goes unanswered (phone in a pocket at the pub — exactly the
/// motivating case) tracking auto-stops after a countdown and an On-Inn is
/// placed. If that guess is ever wrong, restarting tracking makes it a
/// mid-track On-Inn, which the read rule ignores — the auto-stop is
/// self-healing by construction.
class OnInnAutoStopMonitor {
  OnInnAutoStopMonitor(this._locationService);

  final LocationService _locationService;

  // ── Tuning ────────────────────────────────────────────────────────────────
  /// No prompting before this much tracking time — a trail is never over in
  /// its first minutes, and the start area is full of parked early stoppers.
  static const Duration _armAfter = Duration(minutes: 20);

  /// No position callback for this long = stationary (see class doc).
  static const Duration _stationaryAfter = Duration(minutes: 5);

  /// Cheap gate cadence.
  static const Duration _tickEvery = Duration(minutes: 1);

  /// Network-check throttle — GetPositions is only polled while the cheap
  /// gates all pass, and never more often than this.
  static const Duration _fetchEvery = Duration(minutes: 3);

  /// How close to another runner's terminal On-Inn counts as "at the On Inn".
  static const double _onInnRadiusMeters = 30.0;

  /// Unanswered-prompt countdown before tracking auto-stops.
  static const Duration _autoStopAfter = Duration(minutes: 5);

  /// "Keep Tracking" suppresses re-prompting for this long.
  static const Duration _suppressAfterKeep = Duration(minutes: 30);

  /// Points within this window after an On-Inn are straggler queued fixes,
  /// not a resume — mirrors the map controllers' read rule.
  static const int _onInnGraceMs = 120 * 1000;

  // ── State ─────────────────────────────────────────────────────────────────
  Timer? _timer;
  DateTime? _startedAt;
  DateTime? _lastFetchAt;
  DateTime? _pendingPromptSince;
  DateTime? _suppressedUntil;
  bool _dialogShowing = false;
  bool _checkInFlight = false;

  /// Wires the monitor to the tracking flag. Call once from
  /// [LocationService.onInit]; the service (and so this worker) lives for the
  /// whole app session, so the Worker handle is deliberately not kept.
  void init() {
    ever<bool>(_locationService.joinRunTracking, (tracking) {
      if (tracking) {
        _start();
      } else {
        _stop();
      }
    });
  }

  void _start() {
    // Resuming from pause re-fires the worker — keep the original start time
    // so a pause never re-arms the 20-minute grace.
    _startedAt ??= DateTime.now();
    _pendingPromptSince = null;
    _timer ??= Timer.periodic(_tickEvery, (_) => unawaited(_tick()));
  }

  void _stop() {
    // Auto-pause also lands here (joinRunTracking false while paused): the
    // countdown and timer stop, but _startedAt survives for the resume.
    _timer?.cancel();
    _timer = null;
    _pendingPromptSince = null;
    if (!_locationService.isPaused.value) _startedAt = null;
    if (_dialogShowing && Get.isDialogOpen == true) {
      Get.back<EndRunChoice>();
    }
  }

  Future<void> _tick() async {
    if (!_locationService.joinRunTracking.value) return;

    // A prompt is pending: drive the countdown, and surface the dialog if the
    // app has come to the foreground since the trigger.
    final pendingSince = _pendingPromptSince;
    if (pendingSince != null) {
      final waited = DateTime.now().difference(pendingSince);
      if (waited >= _autoStopAfter) {
        await _autoStop();
      } else if (_isForeground && !_dialogShowing) {
        unawaited(_showPrompt(_autoStopAfter - waited));
      }
      return;
    }

    // Cheap gates, cheapest first.
    final startedAt = _startedAt;
    if (startedAt == null ||
        DateTime.now().difference(startedAt) < _armAfter) {
      return;
    }
    final suppressedUntil = _suppressedUntil;
    if (suppressedUntil != null && DateTime.now().isBefore(suppressedUntil)) {
      return;
    }
    final ownPos = _locationService.lastKnownPosition.value;
    if (ownPos == null) return;
    final sinceLastFix = DateTime.now().difference(
      _locationService.lastKnownPositionRead.value,
    );
    if (sinceLastFix < _stationaryAfter) return; // still moving

    // Expensive gate: is anyone's terminal On-Inn within radius?
    final lastFetchAt = _lastFetchAt;
    if (lastFetchAt != null &&
        DateTime.now().difference(lastFetchAt) < _fetchEvery) {
      return;
    }
    if (_checkInFlight) return;
    _checkInFlight = true;
    _lastFetchAt = DateTime.now();
    try {
      if (await _nearOtherRunnersOnInn(ownPos)) {
        _pendingPromptSince = DateTime.now();
        BootLogger.logBreadcrumb(
          'PackTrack: On-Inn auto-stop prompt triggered '
          '(stationary ${sinceLastFix.inMinutes}m near On-Inn cluster)',
        );
        if (_isForeground) unawaited(_showPrompt(_autoStopAfter));
      }
    } catch (e) {
      // Best-effort background check: never let it disturb tracking.
      if (kDebugMode) debugPrint('OnInnAutoStopMonitor check failed: $e');
    } finally {
      _checkInFlight = false;
    }
  }

  Future<bool> _nearOtherRunnersOnInn(Position ownPos) async {
    final eventId = _locationService.eventId;
    final ownUserId = _locationService.userId;
    if (eventId == null || eventId.isEmpty) return false;

    final api = GetPositionsApi();
    try {
      final payload = await api.fetchPositions(
        eventId: eventId,
        latestClientTimestampMs: '0000000000000000000',
      );
      for (final user in payload.users) {
        if (ownUserId != null &&
            normalizeUuid(user.id) == normalizeUuid(ownUserId)) {
          continue; // only OTHER runners' On-Inns count
        }
        if (user.positions.isEmpty) continue;
        final lastTs = user.positions.last.timestampMs;
        for (final p in user.positions) {
          if (!_isTerminatorType(p.type)) continue;
          if (lastTs - p.timestampMs > _onInnGraceMs) continue; // mid-track
          final meters = Geolocator.distanceBetween(
            ownPos.latitude,
            ownPos.longitude,
            p.lat,
            p.lng,
          );
          if (meters <= _onInnRadiusMeters) return true;
        }
      }
      return false;
    } finally {
      api.dispose();
    }
  }

  /// True if [type] is an On-Inn terminator — `A=endRun` action marks and the
  /// legacy `OIN` key (same rule as the map controllers and the resume strip).
  bool _isTerminatorType(String? type) {
    if (type == null || type.isEmpty) return false;
    final parts = type.split('::');
    if (parts.any((p) => p.trim() == 'A=endRun')) return true;
    return parts.first.trim() == HashRunPointTypes.onInn.key;
  }

  bool get _isForeground =>
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  Future<void> _showPrompt(Duration remaining) async {
    if (_dialogShowing) return;
    _dialogShowing = true;
    final minutes = remaining.inMinutes < 1 ? 1 : remaining.inMinutes;
    try {
      final choice = await Get.dialog<EndRunChoice>(
        AlertDialog(
          title: Text('Are you On Inn?', style: ts_alertDialogTitle),
          content: Text(
            'Other runners have ended their runs right here, and you '
            "haven't moved for a while. If the run is over, stop tracking "
            'to save your battery.\n\nTracking will stop by itself in '
            'about $minutes minute${minutes == 1 ? '' : 's'}.',
            style: ts_alertDialogBody,
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Get.back(result: EndRunChoice.keepTracking),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text('Keep Tracking', style: ts_button),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: EndRunChoice.stoppedEarly),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade800,
                foregroundColor: Colors.white,
              ),
              child: Text('I stopped early', style: ts_button),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: EndRunChoice.onInn),
              style: ElevatedButton.styleFrom(
                backgroundColor: hc_red,
                foregroundColor: Colors.white,
              ),
              child: Text("I'm On Inn", style: ts_button),
            ),
          ],
        ),
        barrierDismissible: false,
      );
      switch (choice) {
        case EndRunChoice.onInn:
          _pendingPromptSince = null;
          BootLogger.logBreadcrumb('PackTrack: auto-stop prompt → On Inn');
          await _endTracking(markOnInn: true);
        case EndRunChoice.stoppedEarly:
          _pendingPromptSince = null;
          BootLogger.logBreadcrumb(
            'PackTrack: auto-stop prompt → stopped early',
          );
          await _endTracking(markOnInn: false);
        case EndRunChoice.keepTracking:
          _pendingPromptSince = null;
          _suppressedUntil = DateTime.now().add(_suppressAfterKeep);
          BootLogger.logBreadcrumb(
            'PackTrack: auto-stop prompt → keep tracking '
            '(suppressed ${_suppressAfterKeep.inMinutes}m)',
          );
        case null:
          // Dialog dismissed programmatically (auto-stop or tracking ended
          // some other way) — whoever closed it owns the state.
          break;
      }
    } finally {
      _dialogShowing = false;
    }
  }

  Future<void> _autoStop() async {
    _pendingPromptSince = null;
    BootLogger.logBreadcrumb(
      'PackTrack: auto-stop — prompt unanswered, stopping with On Inn',
    );
    if (_dialogShowing && Get.isDialogOpen == true) {
      Get.back<EndRunChoice>();
    }
    // On-Inn is placed on the unanswered path too: stationary at the pack's
    // On-Inn cluster is exactly what the mark means, and a wrong guess heals
    // itself — a later resume demotes it to a mid-track On-Inn that the read
    // rule ignores.
    await _endTracking(markOnInn: true);
  }

  Future<void> _endTracking({required bool markOnInn}) async {
    if (markOnInn && _locationService.joinRunTracking.value) {
      try {
        // Mark FIRST, while the point buffer is still alive; stopTracking's
        // final flush then carries it if the force-flush didn't.
        await _locationService.markPoint(HashRunPointTypes.onInn);
      } catch (_) {
        // Best-effort: a failed one-shot fix must never block the stop.
      }
    }
    await _locationService.stopTracking();
  }
}
