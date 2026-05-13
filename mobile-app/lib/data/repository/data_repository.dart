import 'package:harrier_central/imports.dart';

/// Thin facade over the global tableModel singleton.
/// Long-term goal: all data access goes through this interface so tableModel
/// can be replaced or mocked without touching callers.
///
/// Migration status: facade created 2026-05-13 — call sites still access
/// tableModel directly. Migrate incrementally: when touching a file, prefer
/// DataRepository over tableModel.
class DataRepository {
  DataRepository._();
  static final DataRepository instance = DataRepository._();

  /// The underlying table model. Use typed accessors below in preference to
  /// accessing this directly.
  TableModel get db => tableModel;

  // Add typed accessors here as files are migrated.
  // Example: Future<List<RunEvent>> getUpcomingRuns() => ...
}
