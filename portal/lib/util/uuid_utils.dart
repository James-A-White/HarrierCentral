/// UUID normalisation utilities for Harrier Central.
library;
///
/// ## Why this exists
///
/// SQL Server returns UNIQUEIDENTIFIER columns as uppercase strings
/// (e.g. "A5F3-..."). The Dart `uuid` package normalises to lowercase
/// via `UuidValue.fromString()`. Plain `String` model fields that hold
/// UUIDs receive no such normalisation — they carry whatever case the
/// JSON contains.
///
/// Comparing a lowercase `UuidValue.uuid` against an uppercase plain-String
/// field with `==` silently returns false. This file provides a single
/// normalisation point so that UUID strings are always comparable.
///
/// ## Usage
///
/// ```dart
/// // Top-level function — safe with nulls:
/// final id = normalizeUuid(json['someId'] as String?);
///
/// // Extension — concise at call sites:
/// if (k.publicKennelId.asUuid == other.publicKennelId.asUuid) { ... }
/// ```
///
/// ## Where to apply
///
/// - Always normalise before comparing two UUID strings from different sources.
/// - Normalise UUID parameters received into query/service functions before
///   using them in API calls or map lookups.
/// - When adding a new UUID `String` field to a Freezed model, normalise in
///   the `.g.dart` `fromJson` method (or switch to `@UuidConverter()` +
///   `UuidValue` to get automatic normalisation).

/// Normalises a UUID string to lowercase for safe comparison and storage.
///
/// Returns an empty string if [uuid] is null or blank (rather than throwing),
/// so callers can use a simple `.isEmpty` guard instead of null checks.
String normalizeUuid(String? uuid) {
  if (uuid == null || uuid.isEmpty) return '';
  return uuid.toLowerCase();
}

/// Convenience extension so normalisation reads naturally at call sites.
extension UuidStringExtension on String {
  /// Returns this UUID string normalised to lowercase.
  ///
  /// Equivalent to `normalizeUuid(this)` but does not handle null.
  String get asUuid => toLowerCase();
}
