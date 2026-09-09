/// Per-device health as returned by `hcportal_getDeviceHealth`.
///
/// The SP extracts three pieces of raw text per session — the last
/// `[METRICS]` line, the `[METRICS:PEAKS]` line and, for the latest session
/// per device, the `[METRICS:RING]` block — and this file parses them. Plain
/// classes rather than Freezed on purpose: the fields are whatever the app
/// wrote, so a new field in the app shows up here with no code change.
class DeviceHealthDevice {
  const DeviceHealthDevice({
    required this.deviceId,
    required this.os,
    required this.hcVersion,
    required this.lastLogin,
    required this.sessions,
    required this.sessionsWithMetrics,
    this.sessionsOnBuild = 0,
  });

  final String deviceId;
  final String os;
  final String hcVersion;
  final DateTime lastLogin;
  final int sessions;
  final int sessionsWithMetrics;

  /// Launches on the build the device runs now.
  final int sessionsOnBuild;

  bool get isIos => os.toLowerCase().contains('ios');

  factory DeviceHealthDevice.fromJson(Map<String, dynamic> j) =>
      DeviceHealthDevice(
        deviceId: (j['deviceId'] as String? ?? '').toLowerCase(),
        os: j['os'] as String? ?? '',
        hcVersion: j['hcVersion'] as String? ?? '',
        lastLogin: DateTime.tryParse(j['lastLogin']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        sessions: (j['sessions'] as num?)?.toInt() ?? 0,
        sessionsWithMetrics: (j['sessionsWithMetrics'] as num?)?.toInt() ?? 0,
        sessionsOnBuild: (j['sessionsOnBuild'] as num?)?.toInt() ?? 0,
      );
}

class DeviceHealthSession {
  DeviceHealthSession({
    required this.sessionStart,
    required this.loggedAt,
    required this.deviceId,
    required this.os,
    required this.hcVersion,
    this.kind = 'session',
    required this.summary,
    this.summaryStart = const <String, String>{},
    required this.peaks,
    required this.ring,
    required this.appError,
    required this.errorLines,
    this.errorText = const <String>[],
  });

  /// When the session began, as the phone wrote it (its local clock, no
  /// zone). Null when the log does not open with a timestamped entry.
  final DateTime? sessionStart;

  /// When the log was uploaded — one launch later.
  final DateTime loggedAt;
  final String deviceId;
  final String os;
  final String hcVersion;

  /// 'session' — an app launch's harvested log — or 'diagnostic', a MetricKit
  /// crash/hang payload that belongs to no particular launch.
  final String kind;
  bool get isDiagnostic => kind == 'diagnostic';

  bool get isIos => os.toLowerCase().contains('ios');
  bool get hasMetrics => summary.isNotEmpty;

  /// key → value from the session's last `[METRICS]` line.
  final Map<String, String> summary;

  /// key → value from the session's first `[METRICS] why=start` line.
  final Map<String, String> summaryStart;

  /// Battery percent at launch and at the last sample, when the phone said.
  int? get battStart => _pct(summaryStart['batt']);
  int? get battEnd => _pct(summary['batt']);
  static int? _pct(String? v) =>
      v == null ? null : int.tryParse(v.replaceAll('%', ''));

  /// key → `value@HH:MM:SS` from the `[METRICS:PEAKS]` line.
  final Map<String, String> peaks;

  /// The one-minute ring, or null when this is not the device's latest session.
  final MetricsRing? ring;
  final String? appError;
  final int errorLines;

  /// The session's [ERROR] lines, in order; empty when there were none.
  final List<String> errorText;

  String v(String key, [String fallback = '—']) {
    final String? s = summary[key];
    return (s == null || s.isEmpty || s == 'n/a') ? fallback : s;
  }

  factory DeviceHealthSession.fromJson(Map<String, dynamic> j) =>
      DeviceHealthSession(
        sessionStart: DateTime.tryParse(j['sessionStart']?.toString() ?? ''),
        loggedAt: DateTime.tryParse(j['loggedAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        deviceId: (j['deviceId'] as String? ?? '').toLowerCase(),
        os: j['os'] as String? ?? '',
        hcVersion: j['hcVersion'] as String? ?? '',
        kind: j['kind'] as String? ?? 'session',
        summary: parseKeyValues(j['summary'] as String?),
        summaryStart: parseKeyValues(j['summaryStart'] as String?),
        peaks: parseKeyValues(j['peaks'] as String?),
        ring: MetricsRing.parse(j['ring'] as String?),
        appError: j['appError'] as String?,
        errorLines: (j['errorLines'] as num?)?.toInt() ?? 0,
        errorText: ((j['errorText'] as String?) ?? '')
            .split('\n')
            .map((String l) => l.trim())
            .where((String l) => l.isNotEmpty)
            .toList(),
      );

  /// `why=start up=1h02m rss=143MB` → {why: start, up: 1h02m, rss: 143MB}.
  /// Tokens without `=` are ignored, so a stray word never breaks a row.
  static Map<String, String> parseKeyValues(String? line) {
    final Map<String, String> out = <String, String>{};
    if (line == null) return out;
    for (final String tok in line.trim().split(RegExp(r'\s+'))) {
      final int eq = tok.indexOf('=');
      if (eq <= 0) continue;
      out[tok.substring(0, eq)] = tok.substring(eq + 1);
    }
    return out;
  }
}

/// The `[METRICS:RING]` block: a header naming the columns, then one CSV row
/// per minute.
class MetricsRing {
  const MetricsRing({required this.columns, required this.rows, required this.everySeconds});

  final List<String> columns;
  final List<List<String>> rows;
  final int everySeconds;

  int col(String name) => columns.indexOf(name);

  /// Numeric series for one column; rows without a value become null.
  List<double?> series(String name) {
    final int i = col(name);
    if (i < 0) return const <double?>[];
    return rows
        .map((List<String> r) => i < r.length ? double.tryParse(r[i]) : null)
        .toList();
  }

  /// One string per row for a text column (e.g. `tier`).
  List<String> labels(String name) {
    final int i = col(name);
    if (i < 0) return const <String>[];
    return rows.map((List<String> r) => i < r.length ? r[i] : '').toList();
  }

  static MetricsRing? parse(String? text) {
    if (text == null || text.isEmpty) return null;
    final List<String> lines = text.split('\n');
    if (lines.isEmpty) return null;
    final Map<String, String> head =
        DeviceHealthSession.parseKeyValues(lines.first);
    final List<String> cols = (head['cols'] ?? '').split(',');
    if (cols.length < 2) return null;
    final List<List<String>> rows = <List<String>>[];
    for (final String l in lines.skip(1)) {
      final String t = l.trim();
      // The block ends where the peaks line's timestamp begins.
      if (t.isEmpty || t.startsWith('[')) continue;
      rows.add(t.split(','));
    }
    return MetricsRing(
      columns: cols,
      rows: rows,
      everySeconds: int.tryParse((head['every'] ?? '60s').replaceAll('s', '')) ?? 60,
    );
  }
}

class DeviceHealth {
  const DeviceHealth({required this.devices, required this.sessions});
  final List<DeviceHealthDevice> devices;
  final List<DeviceHealthSession> sessions;

  static const DeviceHealth empty =
      DeviceHealth(devices: <DeviceHealthDevice>[], sessions: <DeviceHealthSession>[]);
}
