/// Normalise a UUID string to lowercase.
/// SQL Server returns UNIQUEIDENTIFIER columns as uppercase; this ensures
/// consistent lowercase for all comparisons across the app.
String normalizeUuid(String? uuid) {
  if (uuid == null || uuid.isEmpty) return '';
  return uuid.toLowerCase();
}

/// Extension for quick UUID normalisation on String.
extension UuidStringExtension on String {
  String get asUuid => toLowerCase();
  bool equalsUuid(String other) => toLowerCase() == other.toLowerCase();
}

/// Extension for nullable String UUID normalisation.
extension NullableUuidStringExtension on String? {
  String get asUuid => this?.toLowerCase() ?? '';
  bool equalsUuid(String? other) =>
      (this?.toLowerCase() ?? '') == (other?.toLowerCase() ?? '');
}

/// Returns true if the string is a non-empty, non-zero UUID.
bool isValidUuid(String? uuid) {
  if (uuid == null || uuid.isEmpty) return false;
  // GUID_EMPTY is defined in constants.dart
  if (uuid.toLowerCase() == '00000000-0000-0000-0000-000000000000')
    return false;
  return true;
}
