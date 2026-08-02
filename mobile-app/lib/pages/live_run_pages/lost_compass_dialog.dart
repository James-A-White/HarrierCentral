import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:harrier_central/imports.dart';
import 'package:latlong2/latlong.dart' as latlong;

/// "Which way is the trail?" — a compass, not a route.
///
/// Finds the nearest point of the pack's live GPS tracks to the runner's
/// current position and shows an arrow (rotated by the device heading) plus a
/// straight-line distance. Deliberately NOT navigation: there is no path, no
/// route and no promise the direct line is passable — hashers cut through what
/// they like, which is exactly why a bearing beats turn-by-turn here.
///
/// Prefers OTHER runners' tracks (they are the trail). If nobody else is
/// tracking, it falls back to the runner's own earlier track — i.e. "backtrack
/// to where you left it" — and says so.
class LostCompassController extends GetxController {
  LostCompassController({
    required this.eventId,
    this.kennelDistanceUnitsPref = 0,
  });

  final String eventId;

  /// The kennel's own units preference, used when the user's is "auto".
  final int kennelDistanceUnitsPref;

  /// Points recorded within this window are "where I am now", not trail —
  /// excluded when falling back to the runner's own track.
  static const Duration _ownTrackIgnoreWindow = Duration(minutes: 2);

  /// Re-fetch cadence. Tracks move; so does the runner.
  static const Duration _refreshInterval = Duration(seconds: 5);

  /// How far BEFORE a runner's distress mark their track stops being trusted
  /// as trail. Someone typically wanders off-trail for a while before they
  /// admit it and press the button, so cutting exactly at the mark would still
  /// leave their wandering in the candidate set.
  static const Duration _lostLookBack = Duration(minutes: 5);

  /// Inside this, "which way to the trail" stops being a useful question —
  /// you're standing on it, and the bearing to the nearest recorded point is
  /// within your own GPS error anyway. The dialog switches to telling you which
  /// way the trail RUNS and to look around for marks.
  ///
  /// Points are recorded every ~5 m of movement at the default tracking
  /// quality, so being 20 m from the nearest one means being ~20 m off the
  /// line — close enough to see a blob of flour.
  static const double _onTrailRadiusMeters = 20.0;

  /// And this is how far you have to get back OFF it before the dial returns to
  /// pointing you at it. Without the gap, standing near the boundary would flip
  /// the whole dial — icon, colour, headline — on every GPS fix, several times
  /// a second, which reads as a broken screen rather than a close call.
  static const double _offTrailRadiusMeters = 32.0;

  /// How far along the trail to look when working out which way it goes. Short
  /// enough to follow a bend, long enough that a couple of noisy fixes can't
  /// swing the answer.
  static const double _onwardLookAheadMeters = 30.0;

  /// The ONE accuracy gate for every use of a track point in this dialog.
  ///
  /// It used to be two: 15 m when choosing the point the arrow aims at, 25 m
  /// when reporting where that runner had got to. A fix accurate to somewhere
  /// between the two therefore counted as "they are 110 m away" while being
  /// invisible to the arrow, which then aimed at an older, further point — the
  /// dialog said ".11 miles" over an arrow and ".07 miles away" underneath it.
  /// Any new use of a track point must gate on this and nothing else.
  static const double _maxUsableAccuracyMeters = 25.0;

  final RxBool isLoading = true.obs;
  final RxnString errorMessage = RxnString();

  /// Bearing to the nearest trail point, degrees clockwise from true north.
  final RxnDouble bearingToTrail = RxnDouble();
  final RxnDouble distanceMeters = RxnDouble();

  /// Device heading from the magnetometer; null on devices without one (the
  /// arrow then points to the absolute bearing and the UI says so).
  final RxnDouble deviceHeading = RxnDouble();

  /// True when the nearest point came from the runner's own earlier track
  /// because nobody else is tracking — "backtrack" rather than "join the pack".
  final RxBool usingOwnTrack = false.obs;

  /// Display name of the runner whose track is nearest, so the user knows
  /// whose line they're being pointed at.
  final RxnString nearestRunnerName = RxnString();

  /// Number of other runners whose tracks were considered.
  final RxInt contributingRunners = 0.obs;

  /// How many otherwise-eligible runners were skipped because they had marked
  /// themselves lost. Surfaced so "no trail found" is never mysterious.
  final RxInt excludedLostRunners = 0.obs;

  /// Cache of userId → display name, read from the local common DB.
  final Map<String, String> _nameCache = <String, String>{};

  /// Accumulated tracks for the run. The first poll pulls everything; later
  /// polls fetch only what is new (see [_afterTimestampMs]) and append.
  List<UserTrack> _tracks = const <UserTrack>[];
  String? _afterTimestampMs;
  bool _fetching = false;

  /// Runner whose trail the arrow currently points at, so a switch to a nearer
  /// one can be announced rather than silently swinging the needle.
  String? _targetRunnerId;

  /// Set briefly when the arrow retargets to a closer trail.
  final RxnString retargetNotice = RxnString();
  Timer? _retargetNoticeTimer;

  /// The trail point currently being pointed at. Chosen on the slow loop and
  /// held between polls: re-picking it on every GPS fix would make the arrow
  /// and distance jump around as near-equal candidates traded places.
  latlong.LatLng? _targetPoint;

  /// Freshest fix from our own stream; falls back to the shared service value
  /// until the first one arrives.
  Position? _lastPosition;

  /// When the target point was recorded. The gap between then and now is the
  /// difference between catching the pack and arriving somewhere they left an
  /// hour ago — worth knowing before you commit to walking there.
  int? _targetTimestampMs;

  /// "33 minutes ago" for the held target, or null when there isn't one.
  final RxnString targetAgeLabel = RxnString();

  /// Where the target runner has got to since — their newest usable fix, and
  /// when it was taken. The trail point you're walking to may be half an hour
  /// old while its owner is a kilometre further on; that changes whether it's
  /// worth chasing them or just rejoining the trail.
  latlong.LatLng? _runnerLatestPoint;
  int? _runnerLatestTimestampMs;

  /// e.g. "Tuna Melt was 1.2 km away 3 minutes ago".
  final RxnString runnerNowLabel = RxnString();

  /// The second arrow: the nearest hasher's CURRENT position, as against the
  /// nearest point of anyone's trail.
  ///
  /// These answer different questions and routinely disagree. The trail is
  /// where the pack went; the nearest hasher is a person you could catch. When
  /// someone doubles back, their newest fix can be much closer than any part of
  /// the line they laid — showing only the trail arrow made the dialog look
  /// wrong ("go .11 miles that way" under "they are .07 miles away").
  latlong.LatLng? _hasherPoint;
  int? _hasherTimestampMs;
  String? _hasherUserId;

  final RxnDouble bearingToHasher = RxnDouble();
  final RxnDouble distanceToHasherMeters = RxnDouble();
  final RxnString nearestHasherName = RxnString();
  final RxnString hasherAgeLabel = RxnString();

  /// True once the nearest trail point is inside [_onTrailRadiusMeters]. The
  /// first arrow stops being a "walk this way" instruction at that point and
  /// becomes "you're here, this is where it goes".
  final RxBool onTrail = false.obs;

  /// Bearing the trail runs in from the matched point, or null when the pack
  /// hasn't gone any further yet. Recomputed on the poll, not per GPS fix — it
  /// is a property of the trail, not of where you are standing.
  final RxnDouble trailOnwardBearing = RxnDouble();

  /// True when the nearest hasher is the same person whose trail the first
  /// arrow points at — used to drop the now-duplicated prose line.
  bool get hasherIsTrailOwner =>
      _hasherUserId != null &&
      _targetRunnerId != null &&
      normalizeUuid(_hasherUserId!) == normalizeUuid(_targetRunnerId!);

  /// True once the runner has chosen to tell the pack. Opening the compass
  /// alone announces nothing — most of the time the arrow settles it and there
  /// is no reason to interrupt everyone.
  final RxBool hasAnnounced = false.obs;
  final RxBool isAnnouncing = false.obs;

  /// Which announcement is in flight — true for the all clear, false for the
  /// lost message, null when nothing is. Once both buttons are on screen at the
  /// same time, "Sending…" has to land on the one that was actually pressed.
  final Rxn<bool> announcingAllClear = Rxn<bool>();

  /// When the last poll actually came back with data.
  ///
  /// A failed poll doesn't blank the arrow — cached tracks are still the best
  /// guess and someone lost with no signal needs them. But _recompute clears
  /// errorMessage whenever it finds a target, so the failure left no trace and
  /// a runner walking out of coverage saw a confident arrow aimed at minutes-old
  /// data. [staleSeconds] keeps that visible.
  DateTime? _lastFetchOk;
  final RxnInt staleSeconds = RxnInt();

  /// How far behind the live feed we tolerate before saying so. Two missed
  /// polls — one is just a slow request.
  static const int _staleAfterSeconds = 12;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<CompassEvent>? _compassSub;
  Timer? _refreshTimer;

  static const latlong.Distance _distance = latlong.Distance();

  @override
  void onInit() {
    super.onInit();
    _compassSub = FlutterCompass.events?.listen((event) {
      final h = event.heading;
      if (h == null) return;
      final prev = deviceHeading.value;
      // Ignore sub-visible jitter so the arrow doesn't shiver.
      if (prev != null) {
        var diff = (h - prev).abs();
        if (diff > 180.0) diff = 360.0 - diff;
        if (diff < 2.0) return;
      }
      deviceHeading.value = h;
    });
    // Own high-rate position stream for the lifetime of the dialog. The app's
    // shared idle stream only reports every 250m, which is useless here, and a
    // runner who is lost may not be tracking at all. Distance/bearing to the
    // held target cost nothing to recompute — no network, just trigonometry —
    // so the readout moves with each fix rather than once per poll.
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 0, // every fix the OS gives us
          ),
        ).listen(
          (pos) {
            _lastPosition = pos;
            _updateReadout(pos);
          },
          onError: (Object e) {
            if (kDebugMode) debugPrint('[LostCompass] position stream: $e');
          },
        );

    unawaited(refreshBearing());
    _refreshTimer = Timer.periodic(
      _refreshInterval,
      (_) => unawaited(refreshBearing()),
    );
  }

  /// Recomputes bearing and distance to the CURRENTLY HELD target. Cheap and
  /// purely local; safe to run on every GPS fix.
  void _updateReadout(Position me) {
    _refreshStaleness();
    final target = _targetPoint;
    if (target == null) return;
    final from = latlong.LatLng(me.latitude, me.longitude);
    bearingToTrail.value = (_distance.bearing(from, target) + 360) % 360;
    final double metres = _distance.as(latlong.LengthUnit.Meter, from, target);
    distanceMeters.value = metres;
    targetAgeLabel.value = _ageLabel(_targetTimestampMs);
    // Flips as you walk, not once per poll — the moment you step onto the line
    // the dialog should stop telling you to go somewhere. Wider to leave than
    // to enter, so a fix wobbling across the boundary doesn't strobe the dial.
    onTrail.value = onTrail.value
        ? metres <= _offTrailRadiusMeters
        : metres <= _onTrailRadiusMeters;

    // Where that runner is now (as of their last fix) — recomputed here too,
    // so it counts down as you walk rather than sticking until the next poll.
    // Suppressed when the second arrow is already that same person: the arrow
    // says it better than the sentence does.
    final latest = _runnerLatestPoint;
    final name = nearestRunnerName.value;
    if (latest == null || usingOwnTrack.value || hasherIsTrailOwner) {
      runnerNowLabel.value = null;
    } else {
      final away = _distance.as(latlong.LengthUnit.Meter, from, latest);
      final who = (name == null || name.isEmpty) ? 'They' : name;
      runnerNowLabel.value =
          '$who was ${formatDistance(away)} away '
          '${_ageLabel(_runnerLatestTimestampMs) ?? 'just now'}';
    }

    // Second arrow. Same trigonometry, different target — recomputed on every
    // fix for the same reason the first one is.
    final hasher = _hasherPoint;
    if (hasher == null) {
      bearingToHasher.value = null;
      distanceToHasherMeters.value = null;
      hasherAgeLabel.value = null;
    } else {
      bearingToHasher.value = (_distance.bearing(from, hasher) + 360) % 360;
      distanceToHasherMeters.value = _distance.as(
        latlong.LengthUnit.Meter,
        from,
        hasher,
      );
      hasherAgeLabel.value = _ageLabel(_hasherTimestampMs);
    }
  }

  /// Seconds since the last poll that actually returned, or null while the
  /// feed is keeping up.
  void _refreshStaleness() {
    final last = _lastFetchOk;
    if (last == null) {
      staleSeconds.value = null;
      return;
    }
    final int secs = DateTime.now().difference(last).inSeconds;
    staleSeconds.value = secs >= _staleAfterSeconds ? secs : null;
  }

  /// Formats a distance in the user's own units, via the app's shared
  /// formatter so this dialog reads like the rest of the app.
  ///
  /// The units preference is 2 = km, 3 = miles, 0 = auto. Auto defers to the
  /// kennel's own preference — the same rule the runs list uses — which is why
  /// [kennelDistanceUnitsPref] is passed in from the run.
  String formatDistance(double meters) {
    final bool imperial = _useImperial;
    // Utilities.getDistance switches to miles below 3 miles, which at the
    // ranges this dialog deals in reads ".01 miles" — true, and no use to
    // anyone standing on a trail looking for flour. Close in, use paces.
    if (meters < _shortRangeMeters) {
      return imperial
          ? '${(meters * 1.09361).round()} yards'
          : '${meters.round()} meters';
    }
    return Utilities.getDistance(meters, isMetric: !imperial);
  }

  /// Below this, distances are given in metres or yards rather than km/miles.
  static const double _shortRangeMeters = 150.0;

  bool get _useImperial {
    final prefs = getIntPref(IntPrefsEnum.hasherPreferences) ?? 0;
    final userPref = prefs & hasherPref_distanceMeasuredIn;
    return userPref == 3
        ? true
        : userPref == 0
        ? kennelDistanceUnitsPref == 3
        : false;
  }

  /// Records where [userId] has got to: their newest fix good enough to trust.
  void _captureRunnerLatest(String userId) {
    _runnerLatestPoint = null;
    _runnerLatestTimestampMs = null;
    for (final t in _tracks) {
      if (normalizeUuid(t.id) != normalizeUuid(userId)) continue;
      TrackPoint? newest;
      for (final p in t.positions) {
        if (p.acc > _maxUsableAccuracyMeters) continue;
        if (newest == null || p.timestampMs > newest.timestampMs) newest = p;
      }
      if (newest != null) {
        _runnerLatestPoint = latlong.LatLng(newest.lat, newest.lng);
        _runnerLatestTimestampMs = newest.timestampMs;
      }
      return;
    }
  }

  /// How long ago the target point was laid down, in plain words.
  String? _ageLabel(int? timestampMs) {
    if (timestampMs == null) return null;
    final ms = DateTime.now().millisecondsSinceEpoch - timestampMs;
    // Clock skew — say nothing rather than something wrong.
    if (ms < 0) {
      return null;
    }
    final minutes = ms ~/ 60000;
    if (minutes < 1) return 'less than a minute ago';
    if (minutes == 1) return '1 minute ago';
    if (minutes < 60) return '$minutes minutes ago';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (rem == 0) return hours == 1 ? '1 hour ago' : '$hours hours ago';
    return '${hours}h ${rem}m ago';
  }

  @override
  void onClose() {
    unawaited(_positionSub?.cancel());
    unawaited(_compassSub?.cancel());
    _refreshTimer?.cancel();
    _retargetNoticeTimer?.cancel();
    super.onClose();
  }

  /// One tick of the refresh loop: poll the server for the pack's newest
  /// positions, then recompute the bearing from those plus the runner's own
  /// current position. Runs every [_refreshInterval] — someone who is lost gets
  /// live data, and if the pack moves a trail closer, the arrow follows it.
  Future<void> refreshBearing() async {
    final Position? me =
        _lastPosition ?? Get.find<LocationService>().lastKnownPosition.value;
    if (me == null) {
      errorMessage.value =
          'Your location is not available yet. Make sure location is enabled '
          'and try again in a moment.';
      isLoading.value = false;
      return;
    }

    await _fetchTracks();

    // No data yet (first fetch failed) — keep whatever error _fetchTracks set.
    if (_tracks.isEmpty && errorMessage.value != null) {
      isLoading.value = false;
      return;
    }

    _recompute(me);
    isLoading.value = false;
  }

  /// Polls the tracking service and merges the result into [_tracks].
  ///
  /// The first call pulls the whole run; every later call sends the server's
  /// own `latestServerTimestampMs` back as `AfterTimestamp` so only NEW points
  /// come down and are appended. At a 5-second cadence that keeps the data
  /// live without re-downloading every runner's entire history twelve times a
  /// minute — which matters on the phone of someone who is already lost and
  /// burning battery. Guarded so a slow poll can't pile up behind the tick.
  Future<void> _fetchTracks() async {
    if (_fetching) return;
    _fetching = true;
    final api = GetPositionsApi();
    try {
      final bool isFirst = _afterTimestampMs == null;
      final payload = await api.fetchPositions(
        eventId: eventId,
        latestClientTimestampMs: _afterTimestampMs ?? '0000000000000000000',
      );
      if (isFirst) {
        _tracks = payload.users;
      } else {
        _mergeTracks(payload.users);
      }
      // Keep the previous watermark if the server didn't return a new one,
      // otherwise the next poll would re-request the whole run.
      _afterTimestampMs = payload.latestServerTimestampMs ?? _afterTimestampMs;
      _lastFetchOk = DateTime.now();
      errorMessage.value = null;
    } catch (e) {
      errorMessage.value =
          'Could not reach the tracking service. Check your signal and try again.';
      if (kDebugMode) debugPrint('[LostCompass] fetch failed: $e');
    } finally {
      _fetching = false;
      api.dispose();
    }
  }

  /// Appends an incremental payload's points to the tracks already held.
  void _mergeTracks(List<UserTrack> incoming) {
    if (incoming.isEmpty) return;
    final byId = <String, UserTrack>{for (final t in _tracks) t.id: t};
    for (final t in incoming) {
      final existing = byId[t.id];
      byId[t.id] = existing == null
          ? t
          : existing.copyWith(
              positions: <TrackPoint>[...existing.positions, ...t.positions],
            );
    }
    _tracks = byId.values.toList(growable: false);
  }

  /// Recomputes the bearing/distance from cached tracks and [me].
  void _recompute(Position me) {
    final String myUserId = currentUserId;
    final latlong.LatLng myPoint = latlong.LatLng(me.latitude, me.longitude);
    final int nowMs = DateTime.now().millisecondsSinceEpoch;

    // Pass 1: everyone else's tracks — that's the trail. But NOT the track of
    // anyone who has marked themselves lost: their line left the trail, and
    // pointing one lost hasher at another's wandering just makes two lost
    // hashers in the same wrong place. Their pre-lost track is still good
    // trail, so we cut each lost runner's points at their distress mark
    // (minus a look-back) rather than discarding the whole track.
    final others = _tracks
        .where((u) => normalizeUuid(u.id) != normalizeUuid(myUserId))
        .toList(growable: false);
    contributingRunners.value = others.length;

    int excluded = 0;
    final candidates = <({UserTrack track, int? cutoffMs})>[];
    for (final u in others) {
      final int? lostAtMs = _earliestDistressMs(u);
      if (lostAtMs == null) {
        candidates.add((track: u, cutoffMs: null));
      } else {
        excluded++;
        candidates.add((
          track: u,
          cutoffMs: lostAtMs - _lostLookBack.inMilliseconds,
        ));
      }
    }
    excludedLostRunners.value = excluded;

    // Second arrow: the nearest hasher's current position. Anyone who has
    // marked themselves lost is skipped for the same reason their post-mark
    // track is — walking towards another lost hasher just concentrates the
    // problem.
    _resolveNearestHasher(
      others: others.where((u) => _earliestDistressMs(u) == null),
      from: myPoint,
    );

    var best = _nearestAcross(candidates: candidates, from: myPoint);
    var fellBack = false;

    // Pass 2: nobody else usable out there — backtrack along my own earlier
    // track. Recent points are just where I'm standing, so they're cut too.
    if (best == null) {
      final mine = _tracks
          .where((u) => normalizeUuid(u.id) == normalizeUuid(myUserId))
          .map(
            (u) => (
              track: u,
              cutoffMs: nowMs - _ownTrackIgnoreWindow.inMilliseconds,
            ),
          )
          .toList(growable: false);
      best = _nearestAcross(candidates: mine, from: myPoint);
      fellBack = best != null;
    }

    if (best == null) {
      errorMessage.value = contributingRunners.value == 0
          ? 'No live tracks yet for this run, so there is nothing to point '
                'at. Ask in the chat — the pack has been notified.'
          : excluded > 0
          ? 'The only other tracks belong to hashers who are also lost, so '
                'there is no trail to point at. Ask in the chat — the pack '
                'has been notified.'
          : 'Could not read any track positions. Try again in a moment.';
      _targetPoint = null;
      _targetTimestampMs = null;
      _runnerLatestPoint = null;
      _runnerLatestTimestampMs = null;
      bearingToTrail.value = null;
      distanceMeters.value = null;
      onTrail.value = false;
      trailOnwardBearing.value = null;
      nearestRunnerName.value = null;
      targetAgeLabel.value = null;
      runnerNowLabel.value = null;
      // No usable trail point means no usable position from anyone, so the
      // second arrow has nothing to aim at either — don't leave it pointing at
      // whatever it found last time.
      _hasherPoint = null;
      _hasherTimestampMs = null;
      _hasherUserId = null;
      bearingToHasher.value = null;
      distanceToHasherMeters.value = null;
      nearestHasherName.value = null;
      hasherAgeLabel.value = null;
    } else {
      errorMessage.value = null;
      usingOwnTrack.value = fellBack;
      // Latch the chosen point. Bearing and distance are then recomputed
      // against it on every GPS fix (see _updateReadout) rather than only
      // here, so the numbers move as you walk instead of once per poll.
      _targetPoint = best.point;
      _targetTimestampMs = best.timestampMs;
      // Only for someone else's trail. On your OWN track "onward" is the
      // direction you were already going when you got lost, which is the last
      // way you want to be sent — the fallback case shows a bullseye instead.
      trailOnwardBearing.value = fellBack
          ? null
          : _onwardBearing(best.track, best.index);
      _captureRunnerLatest(best.userId);
      final String nearestId = best.userId;
      // Settle who owns the trail BEFORE the readout runs — it asks
      // hasherIsTrailOwner to decide whether the "was N away" line would just
      // repeat the second arrow, and the previous tick's owner is the wrong
      // answer to that question. Keep the old value for the retarget notice.
      final String? previousOwner = _targetRunnerId;
      _targetRunnerId = fellBack ? null : nearestId;
      _updateReadout(me);
      nearestRunnerName.value = null;
      if (!fellBack) {
        final cached = _nameCache[nearestId];
        if (cached != null) {
          nearestRunnerName.value = cached;
        } else {
          // Not cached yet — resolve in the background and fill it in.
          unawaited(
            _displayName(nearestId).then((n) {
              if (n != null) nearestRunnerName.value = n;
            }),
          );
        }
        // The nearest trail is recomputed from scratch every tick, so a track
        // that has come closer simply wins. Announce the switch — the needle
        // swinging to a different trail should never be a silent surprise.
        if (previousOwner != null && previousOwner != nearestId) {
          unawaited(
            _displayName(nearestId).then((n) {
              retargetNotice.value = n == null
                  ? 'Switched to a closer trail'
                  : "Switched to $n's trail — it's closer";
              _retargetNoticeTimer?.cancel();
              _retargetNoticeTimer = Timer(
                const Duration(seconds: 8),
                () => retargetNotice.value = null,
              );
            }),
          );
        }
      }
    }
  }

  /// Picks the nearest hasher by where they are NOW — each runner's newest
  /// usable fix, then the closest of those. Not the same search as the trail
  /// arrow, which considers every point of every track no matter how old.
  void _resolveNearestHasher({
    required Iterable<UserTrack> others,
    required latlong.LatLng from,
  }) {
    latlong.LatLng? bestPoint;
    int? bestTimestampMs;
    String? bestUserId;
    double bestMeters = double.infinity;

    for (final t in others) {
      TrackPoint? newest;
      for (final p in t.positions) {
        if (p.acc > _maxUsableAccuracyMeters) continue;
        if (newest == null || p.timestampMs > newest.timestampMs) newest = p;
      }
      if (newest == null) continue;
      final latlong.LatLng at = latlong.LatLng(newest.lat, newest.lng);
      final double meters = _distance.as(latlong.LengthUnit.Meter, from, at);
      if (meters < bestMeters) {
        bestMeters = meters;
        bestPoint = at;
        bestTimestampMs = newest.timestampMs;
        bestUserId = t.id;
      }
    }

    _hasherPoint = bestPoint;
    _hasherTimestampMs = bestTimestampMs;
    _hasherUserId = bestUserId;

    if (bestUserId == null) {
      nearestHasherName.value = null;
      return;
    }
    final cached = _nameCache[bestUserId];
    if (cached != null) {
      nearestHasherName.value = cached;
    } else {
      final String id = bestUserId;
      unawaited(
        _displayName(id).then((n) {
          // Only apply if that runner is still the nearest when the name lands.
          if (n != null && _hasherUserId == id) nearestHasherName.value = n;
        }),
      );
    }
  }

  /// Timestamp of the runner's earliest distress mark, or null if they have
  /// never called for help. Marks carry `LST::…` / `SOS::…` in the type field.
  int? _earliestDistressMs(UserTrack track) {
    int? earliest;
    for (final p in track.positions) {
      final type = (p.type ?? '').trim();
      if (type.isEmpty) continue;
      final key = type.split('::').first.trim();
      if (key != HashRunPointTypes.lostRunner.key &&
          key != HashRunPointTypes.helpNeeded.key) {
        continue;
      }
      if (earliest == null || p.timestampMs < earliest) {
        earliest = p.timestampMs;
      }
    }
    return earliest;
  }

  /// Nearest position to [from] across [candidates], with the id of the runner
  /// whose track it belongs to. Each candidate's `cutoffMs` (when set) ignores
  /// that runner's points at or after that instant.
  ///
  /// Also hands back the track and the index within it, so [_onwardBearing] can
  /// look at what the pack did NEXT from that point — which is the only useful
  /// thing to say once you are standing on the trail already.
  ({
    latlong.LatLng point,
    String userId,
    int timestampMs,
    UserTrack track,
    int index,
  })?
  _nearestAcross({
    required List<({UserTrack track, int? cutoffMs})> candidates,
    required latlong.LatLng from,
  }) {
    ({
      latlong.LatLng point,
      String userId,
      int timestampMs,
      UserTrack track,
      int index,
    })?
    best;
    double bestMeters = double.infinity;

    for (final candidate in candidates) {
      final cutoff = candidate.cutoffMs;
      final positions = candidate.track.positions;
      for (int i = 0; i < positions.length; i++) {
        final p = positions[i];
        if (cutoff != null && p.timestampMs >= cutoff) continue;
        // Drop wildly inaccurate fixes — pointing at GPS noise is worse than
        // pointing at nothing.
        if (p.acc > _maxUsableAccuracyMeters) continue;
        final latlong.LatLng at = latlong.LatLng(p.lat, p.lng);
        final meters = _distance.as(latlong.LengthUnit.Meter, from, at);
        if (meters < bestMeters) {
          bestMeters = meters;
          best = (
            point: at,
            userId: candidate.track.id,
            timestampMs: p.timestampMs,
            track: candidate.track,
            index: i,
          );
        }
      }
    }
    return best;
  }

  /// Which way the trail carries ON from the matched point — the bearing to the
  /// first later point far enough away that GPS wobble isn't setting the angle.
  ///
  /// Null when the matched point is at or near the end of that track: the pack
  /// hasn't been any further yet, so there is no onward direction to give.
  double? _onwardBearing(UserTrack track, int fromIndex) {
    final positions = track.positions;
    if (fromIndex < 0 || fromIndex >= positions.length) return null;
    final TrackPoint start = positions[fromIndex];
    final latlong.LatLng from = latlong.LatLng(start.lat, start.lng);

    for (int i = fromIndex + 1; i < positions.length; i++) {
      final p = positions[i];
      if (p.acc > _maxUsableAccuracyMeters) continue;
      // Index order should be time order, but the list is built by appending
      // successive delta fetches — check rather than trust, or a mis-ordered
      // batch would point people back the way they came.
      if (p.timestampMs <= start.timestampMs) continue;
      final latlong.LatLng at = latlong.LatLng(p.lat, p.lng);
      if (_distance.as(latlong.LengthUnit.Meter, from, at) >=
          _onwardLookAheadMeters) {
        return (_distance.bearing(from, at) + 360) % 360;
      }
    }
    return null;
  }

  /// Display name for a runner, read from the local common DB (same preference
  /// order the map uses: hash name, then display name, then real name).
  Future<String?> _displayName(String userId) async {
    final cached = _nameCache[userId];
    if (cached != null) return cached;
    try {
      final rows = await QueryUsers.querySingleUser(userId);
      if (rows.isEmpty) return null;
      final r = rows.first;
      String pick(String? v) =>
          (v != null && v.trim().isNotEmpty) ? v.trim() : '';
      final candidates = <String>[
        pick(r[tableModel.hashersTableHelper.colHashName] as String?),
        pick(r[tableModel.hashersTableHelper.colDispName] as String?),
        [
          pick(r[tableModel.hashersTableHelper.colFirstName] as String?),
          pick(r[tableModel.hashersTableHelper.colLastName] as String?),
        ].where((p) => p.isNotEmpty).join(' '),
      ];
      final name = candidates.firstWhere((n) => n.isNotEmpty, orElse: () => '');
      if (name.isEmpty) return null;
      _nameCache[userId] = name;
      return name;
    } catch (e) {
      if (kDebugMode) debugPrint('[LostCompass] name lookup failed: $e');
      return null;
    }
  }

  /// Compass point label ("NE", "SSW") for the absolute bearing — the fallback
  /// readout when the device has no magnetometer.
  /// [of] defaults to the bearing to the nearest trail point, but in the
  /// follow-me state the arrow shows the trail's onward bearing instead — the
  /// footer has to name the same angle the arrow is drawing.
  String compassPointFor(double? of) {
    final b = of ?? bearingToTrail.value;
    if (b == null) return '--';
    const names = <String>[
      'N',
      'NNE',
      'NE',
      'ENE',
      'E',
      'ESE',
      'SE',
      'SSE',
      'S',
      'SSW',
      'SW',
      'WSW',
      'W',
      'WNW',
      'NW',
      'NNW',
    ];
    return names[(((b + 11.25) % 360) ~/ 22.5).toInt()];
  }

  String get distanceLabel {
    final m = distanceMeters.value;
    if (m == null) return '--';
    return formatDistance(m);
  }

  String get hasherDistanceLabel {
    final m = distanceToHasherMeters.value;
    if (m == null) return '--';
    return formatDistance(m);
  }
}

Future<void> showLostCompassDialog(
  BuildContext context,
  String eventId, {
  int kennelDistanceUnitsPref = 0,
  Future<({bool chatSent, bool markPlaced})> Function()? onAnnounceLost,
  Future<bool> Function()? onAnnounceFound,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => LostCompassDialog(
      eventId: eventId,
      kennelDistanceUnitsPref: kennelDistanceUnitsPref,
      onAnnounceLost: onAnnounceLost,
      onAnnounceFound: onAnnounceFound,
    ),
  );
}

class LostCompassDialog extends StatelessWidget {
  LostCompassDialog({
    super.key,
    required this.eventId,
    int kennelDistanceUnitsPref = 0,
    this.onAnnounceLost,
    this.onAnnounceFound,
  }) : controller = Get.put(
         LostCompassController(
           eventId: eventId,
           kennelDistanceUnitsPref: kennelDistanceUnitsPref,
         ),
         tag: 'lost-compass-$eventId',
       );

  final String eventId;
  final LostCompassController controller;

  /// Announces to the run chat. Null hides the announce button (e.g. if the
  /// dialog is ever opened somewhere with no run context).
  final Future<({bool chatSent, bool markPlaced})> Function()? onAnnounceLost;

  /// Tells the pack the runner is back on trail and clears the distress mark.
  final Future<bool> Function()? onAnnounceFound;

  /// One dial: circle, arrow, distance, who or what it points at, and how old
  /// that reading is. [compact] shrinks it so two fit side by side.
  Widget _compass({
    required String label,
    required double bearing,
    required double? heading,
    required String distance,
    required Color color,
    required String caption,
    required String? age,
    required bool compact,
    IconData icon = Icons.navigation,
    bool emphasiseRing = false,
  }) {
    // With a compass the arrow is relative to how the phone is held; without
    // one it shows the absolute bearing (paired with the N/NE/… readout).
    final double arrowDegrees = heading == null
        ? bearing
        : (bearing - heading + 360) % 360;
    final double dial = compact ? 116 : 170;
    // Icons.navigation and Icons.double_arrow have different rest angles:
    // navigation points up, double_arrow points right. Bearings are measured
    // from up, so the chevron needs a quarter turn taken off it.
    final double iconOffsetDegrees = icon == Icons.double_arrow ? -90.0 : 0.0;
    // The bullseye is the one glyph that must NOT rotate — it means "here",
    // not "that way".
    final bool rotates = icon != Icons.adjust;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: ts_alertDialogBody.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: dial,
          width: dial,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: emphasiseRing
                      ? Colors.green.shade50
                      : Colors.blueGrey.shade50,
                  border: Border.all(
                    color: emphasiseRing ? color : Colors.blueGrey.shade200,
                    width: emphasiseRing ? 5 : 2,
                  ),
                ),
              ),
              Positioned(
                top: 6,
                child: Text(
                  heading == null ? 'N' : '▲',
                  style: TextStyle(
                    fontSize: compact ? 11 : 14,
                    color: Colors.blueGrey.shade400,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Transform.rotate(
                angle: rotates
                    ? (arrowDegrees + iconOffsetDegrees) * math.pi / 180.0
                    : 0.0,
                child: Icon(icon, size: compact ? 70 : 104, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          distance,
          style: ts_titleCondensedVeryLargeBlack.copyWith(
            fontSize: compact ? 24 : 34,
          ),
        ),
        Text(
          caption,
          style: ts_alertDialogBody.copyWith(
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        if (age != null)
          Text(
            age,
            style: ts_alertDialogBody.copyWith(fontSize: compact ? 11 : 13),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  /// Sends the lost announcement, or the all clear once already announced.
  Future<void> _handleAnnounce(BuildContext context, bool announced) async {
    controller.isAnnouncing.value = true;
    controller.announcingAllClear.value = announced;
    try {
      if (announced) {
        final ok = await onAnnounceFound?.call() ?? false;
        if (ok) controller.hasAnnounced.value = false;
        Get.snackbar(
          ok ? 'Pack told' : 'Not sent',
          ok
              ? "The pack knows you're back on trail, and your lost marker has "
                    'been removed from the map.'
              : 'Could not send — check your connection and try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: ok ? hc_blue : hc_red,
          colorText: Colors.white,
        );
        return;
      }

      final result = await onAnnounceLost?.call();
      final chatSent = result?.chatSent ?? false;
      final markPlaced = result?.markPlaced ?? false;
      if (chatSent || markPlaced) controller.hasAnnounced.value = true;
      Get.snackbar(
        chatSent || markPlaced ? 'Pack notified' : 'Nothing got through',
        chatSent && markPlaced
            ? 'Message sent and your position is marked on the run map.'
            : chatSent
            ? 'Message sent, but your position could not be marked on the map.'
            : markPlaced
            ? 'Your position is marked on the run map, but the chat message '
                  'failed to send.'
            : 'No signal — nothing could be sent. Try again when you have a bar.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: chatSent || markPlaced ? hc_blue : hc_red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      controller.isAnnouncing.value = false;
      controller.announcingAllClear.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Where is the trail?', style: ts_alertDialogTitle),
      content: Obx(() {
        if (controller.isLoading.value) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: HcAppCircularProgressIndicator(key: Key('lost-compass')),
            ),
          );
        }

        final error = controller.errorMessage.value;
        if (error != null) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Text(
                error,
                style: ts_alertDialogBody,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final heading = controller.deviceHeading.value;
        final double? hasherBearing = controller.bearingToHasher.value;
        final bool showHasher = hasherBearing != null;

        // Two targets that answer different questions: where the trail is, and
        // where the nearest person is. They disagree often enough — someone
        // doubling back is nearer than any part of the line they laid — that
        // showing only the first read as a bug.
        // The trail dial has three states. Far off, it points at the nearest
        // trail point. Standing ON the trail that bearing is meaningless — it
        // is inside your own GPS error and swings with every fix — so it
        // becomes either "the trail runs THIS way" (a follow-me chevron along
        // the line) or, when the pack has not gone any further and there is no
        // onward direction to give, a bullseye that says stop and look around.
        final bool onTrail = controller.onTrail.value;
        final double? onward = controller.trailOnwardBearing.value;
        final bool followMe = onTrail && onward != null;
        final bool lookAround = onTrail && onward == null;
        final double? displayBearing = followMe
            ? onward
            : controller.bearingToTrail.value;

        final Widget trailCompass = _compass(
          label: onTrail
              ? (controller.usingOwnTrack.value
                    ? "You're on your own track"
                    : "You're on the trail")
              : controller.usingOwnTrack.value
              ? 'Your track'
              : 'The trail',
          bearing: followMe ? onward : (controller.bearingToTrail.value ?? 0),
          heading: heading,
          // On the trail, the distance to the nearest recorded point is noise
          // dressed up as a number — say what to do instead.
          distance: followMe
              ? 'On trail'
              : lookAround
              ? 'Look around'
              : controller.distanceLabel,
          icon: followMe
              ? Icons.double_arrow
              : lookAround
              ? Icons.adjust
              : Icons.navigation,
          color: onTrail
              ? Colors.green.shade700
              : controller.usingOwnTrack.value
              ? Colors.deepOrange.shade700
              : hc_blue,
          // A thick green ring makes the dial itself the bullseye, rather than
          // needing a second piece of furniture to say the same thing.
          emphasiseRing: onTrail,
          caption: followMe
              ? 'The trail runs this way'
              : lookAround
              ? 'Within ${controller.distanceLabel} — check for marks'
              : controller.usingOwnTrack.value
              ? 'Back to your own earlier track'
              : controller.nearestRunnerName.value != null
              ? "${controller.nearestRunnerName.value}'s trail"
              : "The nearest runner's trail",
          // How old the spot you're heading for is. Catching the pack and
          // reaching where they were an hour ago look identical without it.
          age: controller.targetAgeLabel.value == null
              ? null
              : controller.usingOwnTrack.value
              ? 'you were there ${controller.targetAgeLabel.value}'
              : 'was there ${controller.targetAgeLabel.value}',
          compact: showHasher,
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!showHasher)
              trailCompass
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: trailCompass),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _compass(
                      label: 'Nearest hasher',
                      bearing: hasherBearing,
                      heading: heading,
                      distance: controller.hasherDistanceLabel,
                      color: Colors.green.shade700,
                      caption: controller.nearestHasherName.value ?? 'A hasher',
                      age: controller.hasherAgeLabel.value == null
                          ? null
                          : 'seen ${controller.hasherAgeLabel.value}',
                      compact: true,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            // Where the trail's owner has got to since — only when that isn't
            // already the second arrow.
            if (controller.runnerNowLabel.value != null)
              Text(
                controller.runnerNowLabel.value!,
                style: ts_alertDialogBody.copyWith(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            if (heading == null)
              Text(
                'Bearing ${displayBearing?.round() ?? 0}° '
                '(${controller.compassPointFor(displayBearing)}) '
                '— no compass on this device',
                style: ts_alertDialogBody.copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            if (controller.retargetNotice.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: hc_blue,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    controller.retargetNotice.value!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            // The arrow keeps working on cached tracks when a poll fails, which
            // is right — but silently, which wasn't.
            if (controller.staleSeconds.value != null)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  controller.staleSeconds.value! >= 60
                      ? 'No signal — this is where the pack was '
                            '${controller.staleSeconds.value! ~/ 60} min ago'
                      : 'No signal — positions are '
                            '${controller.staleSeconds.value}s old',
                  style: ts_alertDialogBody.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.deepOrange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (controller.excludedLostRunners.value > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  controller.excludedLostRunners.value == 1
                      ? '1 hasher who is also lost was left out'
                      : '${controller.excludedLostRunners.value} hashers who are also lost were left out',
                  style: ts_alertDialogBody.copyWith(
                    fontSize: 11,
                    color: Colors.deepOrange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Straight-line direction only — not a route. Watch for roads, '
              'water and fences.',
              style: ts_alertDialogBody.copyWith(
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }),
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        if (onAnnounceLost != null)
          Obx(() {
            final announced = controller.hasAnnounced.value;
            final busy = controller.isAnnouncing.value;
            final sendingAllClear = controller.announcingAllClear.value;

            Widget button({
              required bool allClear,
              required IconData icon,
              required String text,
              required Color colour,
            }) {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(icon, size: 20),
                  label: Text(
                    // Only the button that was actually pressed says so.
                    busy && sendingAllClear == allClear ? 'Sending…' : text,
                    style: ts_button,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colour,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: busy
                      ? null
                      : () => unawaited(_handleAnnounce(context, allClear)),
                ),
              );
            }

            // Before announcing there is only one thing to say. Afterwards
            // both stay available: the all clear is what stops people
            // searching, and telling them again re-sends with wherever you
            // have got to since — which is the more useful of the two if you
            // have been moving while waiting.
            if (!announced) {
              return button(
                allClear: false,
                icon: Icons.campaign,
                text: "Tell the pack I'm lost",
                colour: Colors.deepOrange.shade700,
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                button(
                  allClear: true,
                  icon: Icons.check_circle,
                  text: "I've found the trail",
                  colour: Colors.green.shade700,
                ),
                const SizedBox(height: 8),
                button(
                  allClear: false,
                  icon: Icons.campaign,
                  text: 'Tell the pack again',
                  colour: Colors.deepOrange.shade700,
                ),
              ],
            );
          }),
        ElevatedButton(
          onPressed: () {
            Get.delete<LostCompassController>(tag: 'lost-compass-$eventId');
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: hc_red,
            foregroundColor: Colors.white,
          ),
          child: Text('Close', style: ts_button),
        ),
      ],
    );
  }
}
