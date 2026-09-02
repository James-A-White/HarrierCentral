/// Runs async actions strictly one at a time, in submission order.
///
/// Exists to serialise the admin sync services' writes into the local DB.
/// The sync upsert (BaseService.bulkUpdateDatabase) is read-then-write: it
/// pre-scans for existing remote ids, then batch-inserts whatever it didn't
/// find. Two overlapping syncs both pre-scan before either commits, both
/// conclude a row is new, and both insert it — and with no unique index on
/// the remote id column, SQLite accepts the duplicate silently. That is how
/// the kennel-members list ends up showing every member twice.
///
/// Serialising (rather than coalescing into the in-flight call) is the
/// correct semantic here: the second caller may target a different kennel or
/// event, so it must still run — it just waits its turn, re-reads the
/// watermarks that the first sync advanced, and becomes a cheap delta.
class AsyncSerializer {
  Future<void> _chain = Future<void>.value();

  /// Queues [action] behind any in-flight or queued actions and returns its
  /// result. An action's error propagates to its own caller but never blocks
  /// the queue — later actions still run.
  Future<T> run<T>(Future<T> Function() action) {
    final Future<T> result = _chain.then((_) => action());
    _chain = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}

/// The single queue every local sync write goes through.
///
/// The per-service serialisers guard each service against ITSELF, but the
/// three domains do not own separate physical tables: SyncEventAdminService
/// writes `_commonTables` with `AppDomainType.user` as well as its own event
/// tables, and all three services write `common_hashers` (hashers exist only
/// in the common domain). Three independent queues therefore never protected
/// a shared table from a different service — a user sync and an event sync
/// could still double-insert the same rows.
///
/// Nesting is safe and deliberate: this is a DIFFERENT instance from the
/// per-service queues, and nothing inside a write calls back out to a
/// service-level action, so there is no cycle to deadlock on.
///
/// SQLite is a single-writer store anyway, so serialising costs little.
final AsyncSerializer localDbSyncWrites = AsyncSerializer();
