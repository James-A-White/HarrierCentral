import 'package:harrier_central/imports.dart';

/// Per-device memory, network and battery instrumentation for the session log.
///
/// Writes a `[METRICS]` line into the same harvest stream as errors and
/// `[TRACE]` breadcrumbs, so it is uploaded with the rest of the session on
/// the next boot (see `/hc-debugging`). Gated on the same server-controlled
/// harvest flag, so it costs nothing on devices that are not reporting.
///
/// A line is written at session start, whenever the app goes to the
/// background or comes back, and every [_interval] in between. Separately,
/// a one-row-a-minute ring of the last two hours plus a timestamped-peaks
/// record is persisted on its own and appended to the next boot's upload as
/// `[METRICS:RING]` / `[METRICS:PEAKS]` — see [_ringInterval]. Each line is
/// cumulative for the session, so the LAST line in an uploaded log is that
/// session's summary and the sequence shows the trend. The format is one line
/// of `key=value` pairs, so it greps and splits without a parser:
///
/// ```
/// [2026-09-09T12:00:00.000] [METRICS] why=periodic up=1h02m fg=58m bg=4m
///   rss=143MB peak=201MB pss=n/a avail=1.2GB app_tx=12.3KB app_rx=1.1MB
///   req=41 fail=0 lat_avg=420ms lat_max=8.2s dev_rx=n/a dev_tx=n/a
///   cpu=1m12s cpu%=2.1 db=12.3MB docs=45MB cache=210MB disk_free=41GB
///   loc_track=48m loc_idle=14m batt=87% state=unplugged Δ=-3%
///   drain=2.9%/h chg=n/a lpm=0 therm=nominal
/// ```
///
/// What each source can and cannot say — this is the honest part:
///
/// * **Memory.** `rss`/`peak` are the Dart VM's view of this process (the
///   number that climbs before an iOS jetsam kill). `pss` is Android's
///   proportional set size, the figure Android itself judges the app by; iOS
///   has no equivalent. `avail` is what the OS says is still available to us
///   (`os_proc_available_memory` on iOS, `MemoryInfo.availMem` on Android).
/// * **Network.** `app_tx`/`app_rx`/`req`/`fail` come from [NetworkMeter] and
///   count only the app's own API traffic. `dev_rx`/`dev_tx` are Android's
///   `TrafficStats` for this process since device boot — everything, images
///   included — reported as the delta since the session started. iOS has no
///   per-app counter, so they read `n/a` there.
/// * **CPU.** `cpu` is the process's own user+system time this session and
///   `cpu%` its share of wall time since the previous line. This is the one
///   battery-relevant figure that belongs to the app alone; read it with the
///   location tiers to see what the app was doing to earn it.
/// * **Disk.** `db`/`docs`/`cache` are the app's own footprint and
///   `disk_free` what the volume has left. Sampled at start and every
///   interval, not on lifecycle edges, because the walk is the only
///   non-trivial work here.
/// * **Location.** `loc_*` from [LocationTimeLedger]: cumulative minutes the
///   shared stream spent tracking, paused, boosted for a map, or idle. GPS is
///   the app's dominant battery cost, so this is the denominator for `drain`.
/// * **Battery.** `batt`/`state` are the device battery, not the app's share
///   of it — no platform attributes drain to an app in real time. `Δ` and
///   `drain` are measured over the current UNPLUGGED stretch only (the
///   reference resets whenever the phone is seen charging), and the app is
///   only one of the things draining it. Read them against `fg`/`bg` and the
///   PackTrack breadcrumbs: a high drain while `bg` dominates and location is
///   idle is the finding; a high drain during a tracked run is expected. On
///   Android `chg` is the charge counter delta in mAh, finer than 1% steps.
///   `lpm` is Low Power Mode / Battery Saver and `therm` the thermal state —
///   both change what the OS lets the app do and belong next to the numbers.
class DeviceMetricsService with WidgetsBindingObserver {
  DeviceMetricsService._();

  static const MethodChannel _channel =
      MethodChannel('harrier_central/device_metrics');
  static const Duration _interval = Duration(minutes: 15);

  /// The fine-grained ring: one compact row a minute, the last [_ringRows]
  /// kept, persisted as it fills and appended to the NEXT boot's upload as a
  /// `[METRICS:RING]` block with a `[METRICS:PEAKS]` line. Bounded at ~8 KB
  /// whatever the session did, so it never competes with breadcrumbs for the
  /// log's 100k. Two hours at one-minute resolution is the window before an
  /// out-of-memory kill or a battery collapse that the 15-minute lines miss.
  static const Duration _ringInterval = Duration(minutes: 1);
  static const int _ringRows = 120;
  static const String ringColumns =
      't,cpu%,rss_mb,pss_mb,avail_mb,batt,tier,fg,req,fail,lat_max_ms,rx_kb';

  static DeviceMetricsService? _instance;

  final DateTime _sessionStart = DateTime.now();
  DateTime _stateSince = DateTime.now();
  bool _inForeground = true;
  Duration _fgTotal = Duration.zero;
  Duration _bgTotal = Duration.zero;
  Timer? _timer;
  Timer? _ringTimer;
  bool _sampling = false;

  // Ring state
  final List<String> _ring = <String>[];
  int? _ringCpuMs;
  DateTime? _ringAt;
  final Map<String, _Peak> _peaks = <String, _Peak>{};

  // Baselines for deltas.
  int? _cpuMsAtStart;
  int? _cpuMsAtLastSample;
  DateTime? _lastSampleAt;
  String _diskSummary = 'db=n/a docs=n/a cache=n/a';
  int? _devRxAtStart;
  int? _devTxAtStart;
  double? _battRefLevel; // 0..1, start of the current unplugged stretch
  DateTime? _battRefTime;
  int? _chargeRefUah;

  /// Starts sampling for this session. Safe to call more than once; a no-op
  /// when the harvest flag is off, so nothing runs for ordinary users.
  static void start() {
    if (_instance != null) return;
    if (getBoolPref(BoolPrefsEnum.debugHarvestEnabled) != true) return;
    final DeviceMetricsService s = DeviceMetricsService._();
    _instance = s;
    WidgetsBinding.instance.addObserver(s);
    s._inForeground =
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused;
    s._timer = Timer.periodic(_interval, (_) => s._sample('periodic'));
    s._ringTimer = Timer.periodic(_ringInterval, (_) => s._tick());
    unawaited(s._sample('start'));
  }

  /// Stops sampling (tests, or a harvest flag turned off mid-session). The
  /// next [start] begins a fresh session with fresh baselines.
  static void stop() {
    final DeviceMetricsService? s = _instance;
    if (s == null) return;
    s._timer?.cancel();
    s._ringTimer?.cancel();
    WidgetsBinding.instance.removeObserver(s);
    _instance = null;
  }

  /// One ring row: gauges now, plus what happened since the previous row.
  Future<void> _tick() async {
    try {
      final Map<String, dynamic> n = await _nativeSnapshot();
      final DateTime now = DateTime.now();
      final String t = _hms(now);

      final int? cpuMs = _int(n['cpuTimeMs']);
      String cpuPct = '';
      if (cpuMs != null && _ringCpuMs != null && _ringAt != null) {
        final int wall = now.difference(_ringAt!).inMilliseconds;
        if (wall >= 10000) {
          final double pct = 100 * (cpuMs - _ringCpuMs!) / wall;
          cpuPct = pct.toStringAsFixed(1);
          _peak('cpu%_max', pct, t, high: true, unit: '');
        }
      }
      _ringCpuMs = cpuMs;
      _ringAt = now;

      final int rssMb = _mb(ProcessInfo.currentRss);
      final int? pssMb = _mbOrNull(_int(n['pssBytes']));
      final int? availMb = _mbOrNull(_int(n['availMem']));
      final double? level = _double(n['batteryLevel']);
      final int? batt = (level != null && level >= 0) ? (level * 100).round() : null;
      final List<int> net = NetworkMeter.takeInterval();

      _peak('rss_max', rssMb.toDouble(), t, high: true, unit: 'MB');
      if (pssMb != null) _peak('pss_max', pssMb.toDouble(), t, high: true, unit: 'MB');
      if (availMb != null) _peak('avail_min', availMb.toDouble(), t, high: false, unit: 'MB');
      if (batt != null) _peak('batt_min', batt.toDouble(), t, high: false, unit: '%');
      if (net[2] > 0) _peak('lat_max', net[2].toDouble(), t, high: true, unit: 'ms');

      _ring.add(
        '$t,$cpuPct,$rssMb,${pssMb ?? ''},${availMb ?? ''},${batt ?? ''},'
        '${LocationTimeLedger.current},${_inForeground ? 1 : 0},'
        '${net[0]},${net[1]},${net[2] > 0 ? net[2] : ''},'
        '${(net[3] / 1024).round()}',
      );
      if (_ring.length > _ringRows) _ring.removeAt(0);

      await setStringPref(
        StringPrefsEnum.lastSessionMetricsSeries,
        _seriesBlock(),
      );
    } catch (e) {
      debugPrint('[METRICS] ring tick failed: $e');
    }
  }

  /// The block appended to the next upload: header, rows, peaks.
  String _seriesBlock() {
    final StringBuffer b = StringBuffer();
    b.write('[${_sessionStart.toIso8601String()}] [METRICS:RING] ');
    b.write('rows=${_ring.length} every=${_ringInterval.inSeconds}s cols=$ringColumns');
    for (final String row in _ring) {
      b.write('\n');
      b.write(row);
    }
    b.write('\n[${DateTime.now().toIso8601String()}] [METRICS:PEAKS]');
    for (final MapEntry<String, _Peak> e in _peaks.entries) {
      b.write(' ${e.key}=${e.value}');
    }
    return b.toString();
  }

  void _peak(String key, double value, String at,
      {required bool high, required String unit}) {
    final _Peak? cur = _peaks[key];
    if (cur == null || (high ? value > cur.value : value < cur.value)) {
      _peaks[key] = _Peak(value, at, unit);
    }
  }

  static String _hms(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}:'
      '${d.second.toString().padLeft(2, '0')}';
  static int _mb(int bytes) => (bytes / (1024 * 1024)).round();
  static int? _mbOrNull(int? bytes) =>
      (bytes == null || bytes < 0) ? null : _mb(bytes);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_inForeground) {
          _rollTime();
          _inForeground = true;
          unawaited(_sample('resumed'));
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (_inForeground) {
          _rollTime();
          _inForeground = false;
          unawaited(_sample('paused'));
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Transitional; the paused/resumed edge is the one that matters.
        break;
    }
  }

  /// Folds the time since the last state change into the fg/bg totals.
  void _rollTime() {
    final DateTime now = DateTime.now();
    final Duration span = now.difference(_stateSince);
    if (_inForeground) {
      _fgTotal += span;
    } else {
      _bgTotal += span;
    }
    _stateSince = now;
  }

  Future<void> _sample(String why) async {
    if (_sampling) return;
    _sampling = true;
    try {
      _rollTime();
      final Map<String, dynamic> n = await _nativeSnapshot();
      // The directory walk is the only sample work that is not O(1); keep it
      // off the background/foreground edges so those stay instant.
      if (why == 'start' || why == 'periodic') {
        _diskSummary = await _measureDisk();
      }
      BootLogger.logMetrics('why=$why ${_compose(n)}');
    } catch (e) {
      // Instrumentation must never become the error it is measuring.
      debugPrint('[METRICS] sample failed: $e');
    } finally {
      _sampling = false;
    }
  }

  Future<Map<String, dynamic>> _nativeSnapshot() async {
    try {
      final dynamic raw = await _channel
          .invokeMethod<dynamic>('snapshot')
          .timeout(const Duration(seconds: 3));
      if (raw is Map) return Map<String, dynamic>.from(raw);
    } catch (_) {
      // Channel absent (older native build, tests) — Dart-side figures only.
    }
    return const <String, dynamic>{};
  }

  String _compose(Map<String, dynamic> n) {
    final DateTime now = DateTime.now();
    final StringBuffer b = StringBuffer();

    // Time
    b.write('up=${_fmtDur(now.difference(_sessionStart))} ');
    b.write('fg=${_fmtDur(_fgTotal)} bg=${_fmtDur(_bgTotal)} ');

    // CPU — the app's own consumption: session total, and the share of wall
    // time over the last interval (can exceed 100% on several cores)
    final int? cpuMs = _int(n['cpuTimeMs']);
    if (cpuMs != null && cpuMs >= 0) {
      _cpuMsAtStart ??= cpuMs;
      b.write('cpu=${_fmtDur(Duration(milliseconds: cpuMs - _cpuMsAtStart!))} ');
      final int? prev = _cpuMsAtLastSample;
      final DateTime? prevAt = _lastSampleAt;
      if (prev != null && prevAt != null) {
        final int wallMs = now.difference(prevAt).inMilliseconds;
        b.write(
          wallMs >= 10000
              ? 'cpu%=${(100 * (cpuMs - prev) / wallMs).toStringAsFixed(1)} '
              : 'cpu%=n/a ',
        );
      } else {
        b.write('cpu%=n/a ');
      }
      _cpuMsAtLastSample = cpuMs;
    } else {
      b.write('cpu=n/a cpu%=n/a ');
    }
    _lastSampleAt = now;

    // Memory
    b.write('${BootLogger.memInfo()} ');
    b.write('pss=${_bytes(n['pssBytes'])} avail=${_bytes(n['availMem'])} ');

    // Disk — our footprint, and what is left on the volume
    b.write('$_diskSummary disk_free=${_bytes(n['diskFree'])} ');

    // Location stream cost tiers this session
    b.write('${LocationTimeLedger.summary()} ');

    // Network — app layer, then the device's view of the process (Android)
    b.write('${NetworkMeter.summary()} ');
    final int? devRx = _int(n['uidRx']);
    final int? devTx = _int(n['uidTx']);
    if (devRx != null && devRx >= 0 && devTx != null && devTx >= 0) {
      _devRxAtStart ??= devRx;
      _devTxAtStart ??= devTx;
      b.write('dev_rx=${NetworkMeter.formatBytes(devRx - _devRxAtStart!)} ');
      b.write('dev_tx=${NetworkMeter.formatBytes(devTx - _devTxAtStart!)} ');
    } else {
      b.write('dev_rx=n/a dev_tx=n/a ');
    }

    // Battery
    final double? level = _double(n['batteryLevel']);
    final String state = (n['batteryState'] as String?) ?? 'unknown';
    final int? chargeUah = _int(n['chargeCounterUah']);
    if (level != null && level >= 0) {
      b.write('batt=${(level * 100).round()}% state=$state ');
      final bool unplugged = state == 'unplugged';
      if (!unplugged || _battRefLevel == null) {
        // Charging, or first reading: (re)start the unplugged reference here.
        _battRefLevel = level;
        _battRefTime = now;
        _chargeRefUah = chargeUah;
      }
      if (unplugged && _battRefTime != null && _battRefTime != now) {
        final double delta = (level - _battRefLevel!) * 100;
        final double hours =
            now.difference(_battRefTime!).inSeconds / 3600.0;
        b.write('Δ=${delta.toStringAsFixed(0)}% ');
        b.write(
          hours >= 0.1
              ? 'drain=${(-delta / hours).toStringAsFixed(1)}%/h '
              : 'drain=n/a ',
        );
        if (chargeUah != null && chargeUah > 0 && _chargeRefUah != null) {
          b.write(
            'chg=${((chargeUah - _chargeRefUah!) / 1000).toStringAsFixed(0)}mAh ',
          );
        } else {
          b.write('chg=n/a ');
        }
      } else {
        b.write('Δ=n/a drain=n/a chg=n/a ');
      }
    } else {
      b.write('batt=n/a state=$state Δ=n/a drain=n/a chg=n/a ');
    }

    // Power context
    b.write('lpm=${n['lowPower'] == true ? 1 : 0} ');
    b.write('therm=${(n['thermal'] as String?) ?? 'n/a'}');
    return b.toString();
  }

  /// `db=12.3MB docs=45MB cache=210MB` — the local database, the documents
  /// directory it lives in (everything the app persists), and the temp/cache
  /// directory (image cache, compression scratch). Walks are bounded so a
  /// pathological cache cannot stall a sample.
  Future<String> _measureDisk() async {
    try {
      final Directory docs = await getApplicationDocumentsDirectory();
      final Directory cache = await getTemporaryDirectory();
      final File db = File('${docs.path}/$DB_NAME');
      final int dbBytes = await db.exists() ? await db.length() : -1;
      return 'db=${NetworkMeter.formatBytes(dbBytes)} '
          'docs=${NetworkMeter.formatBytes(await _dirSize(docs))} '
          'cache=${NetworkMeter.formatBytes(await _dirSize(cache))}';
    } catch (_) {
      return 'db=n/a docs=n/a cache=n/a';
    }
  }

  static const int _maxWalkEntries = 20000;

  static Future<int> _dirSize(Directory dir) async {
    if (!await dir.exists()) return -1;
    int total = 0;
    int seen = 0;
    try {
      await for (final FileSystemEntity e
          in dir.list(recursive: true, followLinks: false)) {
        if (++seen > _maxWalkEntries) break;
        if (e is File) {
          try {
            total += await e.length();
          } catch (_) {}
        }
      }
    } catch (_) {
      return total > 0 ? total : -1;
    }
    return total;
  }

  static String _bytes(dynamic v) {
    final int? i = _int(v);
    return i == null ? 'n/a' : NetworkMeter.formatBytes(i);
  }

  static int? _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : null);
  static double? _double(dynamic v) => v is num ? v.toDouble() : null;

  static String _fmtDur(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes % 60;
    final int s = d.inSeconds % 60;
    if (h > 0) return '${h}h${m.toString().padLeft(2, '0')}m';
    if (m > 0) return '${m}m${s.toString().padLeft(2, '0')}s';
    return '${s}s';
  }
}

/// A timestamped extreme for the `[METRICS:PEAKS]` line, e.g. `380MB@14:32:10`.
class _Peak {
  const _Peak(this.value, this.at, this.unit);
  final double value;
  final String at;
  final String unit;

  @override
  String toString() {
    final String v = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return '$v$unit@$at';
  }
}
