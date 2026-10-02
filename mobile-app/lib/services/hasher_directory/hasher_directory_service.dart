import 'package:harrier_central/imports.dart';

/// Who may find a hasher in hasher search (E9.F1.S26, James 2026-10-02).
///
/// Held on the server in `HC.Hasher.DirectoryVisibility` and NEVER synced:
/// the app asks for its own value ([HasherDirectoryService.fetchMine]) and
/// nobody else's choice ever reaches this phone. NULL means "not asked yet".
class DirectoryVisibility {
  const DirectoryVisibility._();

  static const int nobody = 0;
  static const int runTogether = 1;
  static const int kennelMembers = 2;
  static const int anyone = 3;

  /// Added to a scope: may also be found by first / last name.
  static const int realNameFlag = 16;

  /// The four choices, in the order the question offers them.
  static const List<int> scopes = <int>[
    anyone,
    runTogether,
    kennelMembers,
    nobody,
  ];

  static int scopeOf(int value) => value & 3;
  static bool realNameOf(int value) => (value & realNameFlag) != 0;

  static int compose(int scope, {required bool realName}) =>
      scope == nobody ? nobody : scope | (realName ? realNameFlag : 0);

  /// The wording James approved on 2026-10-02.
  static String label(int scope) => switch (scope) {
    anyone => 'Anyone on Harrier Central',
    runTogether => "Only hashers I've run with",
    kennelMembers => 'Only members of kennels I belong to',
    _ => "Nobody. I don't want to be found",
  };
}

/// A hasher as search and By Hasher show them: the display name is the
/// hasher's own choice (hash name or real name).
class HasherSummary {
  const HasherSummary({
    required this.publicHasherId,
    required this.displayName,
    this.photo,
    this.homeKennelName,
    this.homeKennelShortName,
    this.homeKennelLogo,
    this.runsTogether = 0,
    this.lastTogether,
    this.firstTogether,
    this.mostlyKennelShortName,
  });

  final HcId publicHasherId;
  final String displayName;
  final String? photo;
  final String? homeKennelName;
  final String? homeKennelShortName;
  final String? homeKennelLogo;
  final int runsTogether;
  final DateTime? lastTogether;

  /// By Hasher only (from 2026-10-02's getCoRunners): the first run together
  /// and the kennel where the two have run together most.
  final DateTime? firstTogether;
  final String? mostlyKennelShortName;

  factory HasherSummary.fromJson(Map<String, dynamic> j) => HasherSummary(
    publicHasherId: HcId('${j['PublicHasherId'] ?? ''}'),
    displayName: _text(j['DisplayName']) ?? 'A hasher',
    photo: _text(j['Photo']),
    homeKennelName: _text(j['HomeKennelName']),
    homeKennelShortName: _text(j['HomeKennelShortName']),
    homeKennelLogo: _text(j['HomeKennelLogo']),
    runsTogether: _int(j['RunsTogether']),
    lastTogether: _date(j['LastTogether']),
    firstTogether: _date(j['FirstTogether']),
    mostlyKennelShortName: _text(j['MostlyKennelShortName']),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'PublicHasherId': publicHasherId,
    'DisplayName': displayName,
    'Photo': photo,
    'HomeKennelName': homeKennelName,
    'HomeKennelShortName': homeKennelShortName,
    'HomeKennelLogo': homeKennelLogo,
    'RunsTogether': runsTogether,
    'LastTogether': lastTogether?.toIso8601String(),
    'FirstTogether': firstTogether?.toIso8601String(),
    'MostlyKennelShortName': mostlyKennelShortName,
  };

  /// What a search box matches on this phone (By Hasher's local filter):
  /// the name shown and the home kennel. Never a real name the hasher has
  /// not chosen to show.
  bool matches(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return displayName.toLowerCase().contains(q) ||
        (homeKennelShortName ?? '').toLowerCase().contains(q) ||
        (homeKennelName ?? '').toLowerCase().contains(q);
  }
}

/// One run both hashers attended, drawn as it comes from the server so the
/// hasher page does not depend on which old runs this phone still holds.
class SharedRun {
  const SharedRun({
    required this.eventId,
    required this.eventNumber,
    required this.eventName,
    required this.startLocal,
    this.kennelShortName,
    this.kennelLogo,
    this.meHare = false,
    this.themHare = false,
  });

  final HcId eventId;
  final int eventNumber;
  final String eventName;

  /// The run's own wall-clock start (EventStartLocal), not converted.
  final DateTime? startLocal;
  final String? kennelShortName;
  final String? kennelLogo;
  final bool meHare;
  final bool themHare;

  factory SharedRun.fromJson(Map<String, dynamic> j) => SharedRun(
    eventId: HcId('${j['EventId'] ?? ''}'),
    eventNumber: _int(j['EventNumber']),
    eventName: _text(j['EventName']) ?? '',
    startLocal: _localDate(j['EventStartLocal']),
    kennelShortName: _text(j['KennelShortName']),
    kennelLogo: _text(j['KennelLogo']),
    meHare: _int(j['MeHare']) != 0,
    themHare: _int(j['ThemHare']) != 0,
  );
}

/// Everything the hasher page shows.
class HasherTogether {
  const HasherTogether({
    required this.hasher,
    required this.runsTogether,
    required this.haredTogether,
    required this.runs,
    this.firstTogether,
    this.lastTogether,
  });

  final HasherSummary hasher;
  final int runsTogether;
  final int haredTogether;
  final DateTime? firstTogether;
  final DateTime? lastTogether;
  final List<SharedRun> runs;
}

/// A search answer: the results, or the server's own reason for refusing
/// ("type at least 2 letters", "you have searched a lot just now").
class HasherSearchOutcome {
  const HasherSearchOutcome.ok(List<HasherSummary> this.results)
    : refusal = null;
  const HasherSearchOutcome.failed([this.refusal]) : results = null;
  final List<HasherSummary>? results;
  final String? refusal;
}

class HasherDirectoryService {
  const HasherDirectoryService._();

  /// The caller's own answer. `known` false when the call failed (ask
  /// nothing then: a dropped call is not "not asked").
  static Future<({bool known, int? value})> fetchMine() async {
    final String? result = await _post('getDirectoryVisibility', silent: true);
    if (result == null) return (known: false, value: null);
    try {
      final List<dynamic> outer = jsonDecode(result) as List<dynamic>;
      if (outer.isEmpty || outer[0] is! List) {
        return (known: false, value: null);
      }
      final List<dynamic> rows = outer[0] as List<dynamic>;
      if (rows.isEmpty) return (known: false, value: null);
      final Object? v = (rows.first as Map)['DirectoryVisibility'];
      return (known: true, value: v == null ? null : _int(v));
    } catch (e, s) {
      BootLogger.logError('[ERROR][DIRECTORY]', 'visibility unreadable: $e', s);
      return (known: false, value: null);
    }
  }

  /// Saves the answer; returns the stored value, or null when it failed.
  static Future<int?> saveMine(int value) async {
    final String? result = await _post(
      'setDirectoryVisibility',
      extra: <String, dynamic>{'visibility': value},
      silent: true,
    );
    if (result == null) return null;
    try {
      final List<dynamic> outer = jsonDecode(result) as List<dynamic>;
      final Map<String, dynamic>? env = outer.isEmpty
          ? null
          : firstRow(outer[0] as List<dynamic>?);
      if (env == null || env['success'] != 1) return null;
      final Map<String, dynamic>? row = outer.length > 1
          ? firstRow(outer[1] as List<dynamic>?)
          : null;
      return row == null ? value : _int(row['DirectoryVisibility']);
    } catch (e, s) {
      BootLogger.logError('[ERROR][DIRECTORY]', 'save unreadable: $e', s);
      return null;
    }
  }

  static Future<HasherSearchOutcome> search(String query) async {
    String? refusal;
    final String? result = await _post(
      'searchHashers',
      extra: <String, dynamic>{'query': query.trim()},
      onRefused: (String? why) => refusal = why,
    );
    if (result == null) return HasherSearchOutcome.failed(refusal);
    try {
      final List<dynamic> outer = jsonDecode(result) as List<dynamic>;
      final Map<String, dynamic>? env = outer.isEmpty
          ? null
          : firstRow(outer[0] as List<dynamic>?);
      if (env == null || env['success'] != 1) {
        return HasherSearchOutcome.failed(refusal);
      }
      return HasherSearchOutcome.ok(
        _summaries(outer.length > 1 ? outer[1] : null),
      );
    } catch (e, s) {
      BootLogger.logError('[ERROR][DIRECTORY]', 'search unreadable: $e', s);
      return HasherSearchOutcome.failed(refusal);
    }
  }

  /// Everyone the caller has run with, most runs together first. Null when
  /// the call failed. A good answer is cached for the offline view.
  static Future<List<HasherSummary>?> fetchCoRunners() async {
    final String? result = await _post('getCoRunners', silent: true);
    if (result == null) return null;
    try {
      final List<dynamic> outer = jsonDecode(result) as List<dynamic>;
      final List<HasherSummary> list = _summaries(
        outer.isEmpty ? null : outer[0],
      );
      unawaited(
        setStringPref(
          StringPrefsEnum.coRunnersCache,
          jsonEncode(list.map((HasherSummary h) => h.toJson()).toList()),
        ),
      );
      return list;
    } catch (e, s) {
      BootLogger.logError('[ERROR][DIRECTORY]', 'co-runners unreadable: $e', s);
      return null;
    }
  }

  /// The last list fetched, for a phone without a connection.
  static List<HasherSummary> cachedCoRunners() {
    final String? raw = getStringPref(StringPrefsEnum.coRunnersCache);
    if (raw == null || raw.isEmpty) return <HasherSummary>[];
    try {
      return _summaries(jsonDecode(raw));
    } catch (_) {
      return <HasherSummary>[];
    }
  }

  static Future<HasherTogether?> fetchRunsTogether(
    HcId otherPublicHasherId,
  ) async {
    final String? result = await _post(
      'getRunsTogether',
      extra: <String, dynamic>{'otherPublicHasherId': otherPublicHasherId},
      silent: true,
    );
    if (result == null) return null;
    try {
      final List<dynamic> outer = jsonDecode(result) as List<dynamic>;
      final Map<String, dynamic>? env = outer.isEmpty
          ? null
          : firstRow(outer[0] as List<dynamic>?);
      if (env == null || env['success'] != 1 || outer.length < 3) return null;
      final Map<String, dynamic>? head = firstRow(outer[1] as List<dynamic>?);
      if (head == null) return null;
      final List<SharedRun> runs = (outer[2] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(SharedRun.fromJson)
          .toList(growable: false);
      return HasherTogether(
        hasher: HasherSummary.fromJson(head),
        runsTogether: _int(head['RunsTogether']),
        haredTogether: _int(head['HaredTogether']),
        firstTogether: _localDate(head['FirstTogether']),
        lastTogether: _localDate(head['LastTogether']),
        runs: runs,
      );
    } catch (e, s) {
      BootLogger.logError(
        '[ERROR][DIRECTORY]',
        'runs together unreadable: $e',
        s,
      );
      return null;
    }
  }

  // ── plumbing ───────────────────────────────────────────────────────────

  /// One authenticated call to `hcapp_<queryType>`. Null on any failure.
  /// [silent] keeps the generic error dialog away (background reads);
  /// [onRefused] receives the server's own message instead of the dialog.
  static Future<String?> _post(
    String queryType, {
    Map<String, dynamic> extra = const <String, dynamic>{},
    bool silent = false,
    void Function(String? refusal)? onRefused,
  }) async {
    final String userId = currentUserId;
    final String deviceId = getStringPref(StringPrefsEnum.deviceId) ?? '';
    final String deviceSecret =
        getStringPref(StringPrefsEnum.deviceSecret) ?? '';
    if (userId.isEmpty || deviceId.isEmpty || deviceSecret.isEmpty) {
      return null;
    }
    final String result = await ServiceCommon.sendHttpPost(
      () => jsonEncode(<String, dynamic>{
        'queryType': queryType,
        'deviceId': deviceId,
        'accessToken': Utilities.generateToken(
          userId,
          'hcapp_$queryType',
          paramString: deviceSecret,
        ),
        ...extra,
      }),
      errorCallback: (silent || onRefused != null)
          ? (DbErrorModel e) async {
              onRefused?.call(e.errorUserMessage);
              return true;
            }
          : null,
    );
    if (result.startsWith(ERROR_PREFIX)) return null;
    return result;
  }

  static List<HasherSummary> _summaries(Object? rowset) {
    if (rowset is! List) return <HasherSummary>[];
    return rowset
        .whereType<Map<String, dynamic>>()
        .map(HasherSummary.fromJson)
        .where((HasherSummary h) => h.publicHasherId.isValid)
        .toList(growable: false);
  }
}

String? _text(Object? v) {
  final String s = (v ?? '').toString().trim();
  return s.isEmpty ? null : s;
}

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;

DateTime? _date(Object? v) =>
    v == null ? null : DateTime.tryParse(v.toString());

/// A wall-clock value as the run's own clock reads it: the time zone, if
/// any, is dropped rather than converted.
DateTime? _localDate(Object? v) {
  if (v == null) return null;
  final String s = v.toString();
  final RegExpMatch? m = RegExp(
    r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2}))?',
  ).firstMatch(s);
  if (m == null) return null;
  return DateTime(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
    int.tryParse(m.group(4) ?? '') ?? 0,
    int.tryParse(m.group(5) ?? '') ?? 0,
  );
}
