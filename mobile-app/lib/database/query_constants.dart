/// Centralised SQL column name and table name constants.
/// Eliminates magic strings scattered across query files.
/// Add new constants here as query files are updated.
///
/// NOTE: The authoritative column name definitions live on the per-table
/// helpers accessed via [tableModel] (e.g.
/// `tableModel.eventsTableHelper.colEventId`). Use those in preference to
/// these string constants wherever a [tableModel] reference is already
/// available. These constants exist for the remaining call sites that use
/// bare SQL strings without a helper reference — principally JOIN conditions,
/// UNION aliases, and aggregate columns inside raw SQL blocks.
///
/// See [tables.dart] for the table helper classes and [EnumDataTables] for
/// the canonical table names.
class QC {
  QC._();

  // ── Common column names used across multiple queries ──────────────────────

  /// Primary integer row id (SQLite rowid alias).
  static const String id = 'id';

  /// Hasher/user event map row id.
  static const String hemId = 'hemId';

  /// Event identifier (UUID stored as TEXT).
  static const String eventId = 'eventId';

  /// Public-facing event identifier (UUID stored as TEXT).
  static const String publicEventId = 'publicEventId';

  /// Kennel identifier (UUID stored as TEXT).
  static const String kennelId = 'kennelId';

  /// User/hasher identifier (UUID stored as TEXT).
  static const String userId = 'userId';

  /// Soft-delete flag — non-zero means the row is removed.
  static const String removed = 'removed';

  /// ISO-8601 timestamp of the last server-side update.
  static const String updatedAt = 'updatedAt';

  /// Visibility flag — 1 means the row is shown to users.
  static const String isVisible = 'isVisible';

  /// Column used to cancel a payment row (nullable — NULL = active payment).
  static const String cancelledBy = 'cancelledBy';

  /// Payment type code (0 = none, 2+ = paid).
  static const String paymentType = 'paymentType';

  /// Hasher attendance state at an event.
  static const String attendenceState = 'attendenceState';

  /// Hasher RSVP state for an event.
  static const String rsvpState = 'rsvpState';

  /// Hasher membership following flag.
  static const String isKennelFollowing = 'isKennelFollowing';

  /// Membership expiration date (ISO-8601 TEXT).
  static const String membershipExpirationDate = 'membershipExpirationDate';
}
