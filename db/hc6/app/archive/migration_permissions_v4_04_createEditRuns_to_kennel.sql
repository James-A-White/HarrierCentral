-- =====================================================================
-- RUN-ONCE MIGRATION — reclassify createEditRuns as a KENNEL-admin function.
-- =====================================================================
-- Adding/editing runs is a kennel-admin activity (managing the kennel's calendar),
-- not per-run admin (attendance/payments on the day). Move createEditRuns from the
-- runAdmin area to kennelTools so it derives kennel-admin entry, groups under
-- "Kennel Tools" in the editor, and drives the kennel detail page's admin section.
--
-- Reconciliation (verified on live data before running): 0 users lose the per-run
-- admin gear (nobody holds createEditRuns as their only runAdmin capability); the
-- kennel detail admin section correctly gains 51 role-based admins; the only 2
-- "losses" are admin-flag users whose section was already empty (no createEditRuns
-- / manageMembers capability).
--
-- Server (CheckAreaEntry) and the compiled JSON pick this up automatically; the app
-- KennelFeature enum's areaKey is updated in the same release.
-- ⚠️  RUN MANUALLY, ONCE. Archived after running. Recompiles the matrix.
-- =====================================================================
SET XACT_ABORT ON;
GO

UPDATE HC.PermissionFunction
SET AreaKey     = 'kennelTools',
    FeatureArea = 'Kennel Tools',
    SortOrder   = 38            -- top of Kennel Tools, above Manage Members (40)
WHERE FunctionKey = 'createEditRuns';
GO

EXEC HC6.nonApi_compilePermissionMatrix;
GO

-- Verify
SELECT FunctionKey, AreaKey, FeatureArea, SortOrder
FROM HC.PermissionFunction WHERE AreaKey IN ('runAdmin','kennelTools')
ORDER BY AreaKey, SortOrder;
GO
