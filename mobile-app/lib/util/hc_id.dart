/// A Harrier Central id (a GUID), always lowercase (James, 2026-09-27).
///
/// SQL Server writes a UNIQUEIDENTIFIER in UPPERCASE whenever SQL itself turns
/// it into text — push payloads built in SQL, `CAST(id AS NVARCHAR)` columns —
/// while the API's JSON writer and the phone's database use lowercase. Both
/// `==` in Dart and `=` in SQLite are case-sensitive, so an id that crossed
/// from one to the other silently matched nothing: the PackTrack map lost
/// "you", and chat pushes opened no chat (both 2026-09-27).
///
/// The only constructor lowercases, so two [HcId]s compare correctly with a
/// plain `==` and interpolate safely into SQL. It is an extension type: at
/// runtime it IS the String, with no wrapper object, and `implements String`
/// lets it go anywhere a String does — so code migrates one call at a time.
/// What it adds is the compile-time rule: a function that takes an [HcId]
/// cannot be handed a raw payload string.
extension type const HcId._(String value) implements String {
  /// Normalises [raw]: trims and lowercases. Null becomes [HcId.empty].
  factory HcId(String? raw) => HcId._((raw ?? '').trim().toLowerCase());

  /// Null for a null, empty or all-zero id — for payload fields that may be
  /// absent.
  static HcId? tryParse(Object? raw) {
    if (raw == null) return null;
    final HcId id = HcId(raw.toString());
    return id.isValid ? id : null;
  }

  static const HcId empty = HcId._('');

  bool get isValid =>
      value.isNotEmpty && value != '00000000-0000-0000-0000-000000000000';
}

/// True if [s] has the shape of a GUID (36 characters, dashes at 8/13/18/23).
/// Cheap on purpose: it runs over every string value of every synced row.
bool looksLikeGuid(String s) =>
    s.length == 36 &&
    s.codeUnitAt(8) == 0x2D &&
    s.codeUnitAt(13) == 0x2D &&
    s.codeUnitAt(18) == 0x2D &&
    s.codeUnitAt(23) == 0x2D;

/// Lowercases every GUID-shaped string inside decoded JSON (maps and lists,
/// any depth), in place, and returns [json]. Applied where replies enter the
/// app — the sync writer, push payloads — so nothing uppercase reaches the
/// phone's database or its comparisons.
dynamic lowerGuidsInPlace(dynamic json) {
  if (json is Map) {
    for (final dynamic key in json.keys.toList()) {
      final dynamic v = json[key];
      if (v is String) {
        if (looksLikeGuid(v)) json[key] = v.toLowerCase();
      } else if (v is Map || v is List) {
        lowerGuidsInPlace(v);
      }
    }
  } else if (json is List) {
    for (int i = 0; i < json.length; i++) {
      final dynamic v = json[i];
      if (v is String) {
        if (looksLikeGuid(v)) json[i] = v.toLowerCase();
      } else if (v is Map || v is List) {
        lowerGuidsInPlace(v);
      }
    }
  }
  return json;
}
