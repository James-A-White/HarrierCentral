-- RUN-ONCE (executed 2026-07-27) — move the "View … Admin Tools" entry gates to
-- the top of their sections in the Permissions editor. SortOrder is not in the
-- compiled JSON, so no recompile is needed; the portal reads order live.
UPDATE HC.PermissionFunction SET SortOrder = 19 WHERE FunctionKey = 'enterRunAdmin';
UPDATE HC.PermissionFunction SET SortOrder = 39 WHERE FunctionKey = 'enterKennelAdmin';
