-- RUN-ONCE (executed 2026-07-27) — merge Hash Cash into the Runs & Events group.
-- The 4 Hash Cash tools are only reachable through the run admin screen (gated by
-- View Run Admin Tools / enterRunAdmin), so they belong in the same gated group.
-- Group renamed to "Runs, Events, and Hash Cash". FeatureArea/SortOrder aren't in
-- the compiled JSON, so no recompile is needed.
UPDATE HC.PermissionFunction SET FeatureArea = 'Runs, Events, and Hash Cash'
WHERE FeatureArea IN ('Runs & Events', 'Hash Cash');
UPDATE HC.PermissionFunction SET SortOrder = 25 WHERE FunctionKey = 'viewPaymentReport';
UPDATE HC.PermissionFunction SET SortOrder = 26 WHERE FunctionKey = 'takePayment';
UPDATE HC.PermissionFunction SET SortOrder = 27 WHERE FunctionKey = 'bulkPayment';
UPDATE HC.PermissionFunction SET SortOrder = 28 WHERE FunctionKey = 'manageReceipts';
