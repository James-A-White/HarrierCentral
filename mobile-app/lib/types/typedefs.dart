typedef PublicHasherId = Guid;
typedef EventId = Guid;

class Guid {
  /// The stored GUID, guaranteed uppercase.
  final String value;

  /// Normalizing constructor: upper-cases on creation.
  Guid(String raw) : value = raw.toUpperCase();

  /// Optional: named constructor for clarity.
  factory Guid.fromString(String raw) => Guid(raw);

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Guid && other.value.toUpperCase() == value;

  @override
  int get hashCode => value.hashCode;
}
