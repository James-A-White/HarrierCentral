-- RUN-ONCE (executed 2026-07-27) — further Permissions editor regrouping.
-- Awards + Manage Down Downs are surfaced in run admin, so moved into the
-- "Runs, Events, and Hash Cash" gated group. Renamed "Members" -> "Kennel Tools"
-- and moved "Manage kennel settings" into it (under View Kennel Admin Tools).
-- FeatureArea/SortOrder are portal-only (not in the compiled JSON) — no recompile.
UPDATE HC.PermissionFunction SET FeatureArea='Runs, Events, and Hash Cash', SortOrder=29 WHERE FunctionKey='awardList';
UPDATE HC.PermissionFunction SET FeatureArea='Runs, Events, and Hash Cash', SortOrder=30 WHERE FunctionKey='manageDownDowns';
UPDATE HC.PermissionFunction SET FeatureArea='Kennel Tools' WHERE FeatureArea='Members';
UPDATE HC.PermissionFunction SET FeatureArea='Kennel Tools', SortOrder=45 WHERE FunctionKey='manageKennelSettings';
