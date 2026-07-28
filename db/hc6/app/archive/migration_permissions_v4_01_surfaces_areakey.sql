-- =====================================================================
-- RUN-ONCE MIGRATION — Permissions "derived entry + surfaces", Phase 1
-- =====================================================================
-- Adds two columns to HC.PermissionFunction:
--   * Surfaces SMALLINT  — bitmask: app=1, portal=2, both=3. Which surface(s)
--     a capability exists on. Defaults to 3 (both) so nothing changes on deploy.
--   * AreaKey  NVARCHAR  — STABLE slug for the feature area (runAdmin, kennelTools,
--     photos, web, songs). FeatureArea stays as the renamable DISPLAY label; AreaKey
--     is the functional identity that derived-entry keys off, so renaming the label
--     never breaks gating (which has happened before with FeatureArea string-matching).
--
-- Inert: no behaviour change. Derived entry (CheckAreaEntry) and the removal of the
-- enterRunAdmin/enterKennelAdmin rows come in later phases.
--
-- HC.PermissionFunction is NOT mobile-synced (no UpdatedAt trigger) — ALTER is free.
--
-- ⚠️  RUN MANUALLY, ONCE. Not picked up by deploy_hc6.sh. Archived after running.
-- =====================================================================
SET XACT_ABORT ON;
GO

-- 1. Add the columns (additive; existing rows get Surfaces = 3, AreaKey = NULL).
IF COL_LENGTH('HC.PermissionFunction', 'Surfaces') IS NULL
    ALTER TABLE HC.PermissionFunction
        ADD Surfaces SMALLINT NOT NULL
            CONSTRAINT DF_PermissionFunction_Surfaces DEFAULT (3);
GO

IF COL_LENGTH('HC.PermissionFunction', 'AreaKey') IS NULL
    ALTER TABLE HC.PermissionFunction ADD AreaKey NVARCHAR(40) NULL;
GO

-- 2. Backfill AreaKey from the current FeatureArea display labels.
UPDATE HC.PermissionFunction
SET AreaKey = CASE FeatureArea
        WHEN 'Runs, Events, and Hash Cash' THEN 'runAdmin'
        WHEN 'Kennel Tools'                THEN 'kennelTools'
        WHEN 'Photos'                      THEN 'photos'
        WHEN 'Web / Newsletter'            THEN 'web'
        WHEN 'Songs'                       THEN 'songs'
    END
WHERE AreaKey IS NULL;
GO

-- 3. Enforce AreaKey now that every row is populated (future inserts must set it).
ALTER TABLE HC.PermissionFunction ALTER COLUMN AreaKey NVARCHAR(40) NOT NULL;
GO

-- 4. Covering index for the derived-entry lookup ("all functions in an area on a surface").
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'IX_PermissionFunction_Area'
                 AND object_id = OBJECT_ID('HC.PermissionFunction'))
    CREATE INDEX IX_PermissionFunction_Area
        ON HC.PermissionFunction (AreaKey) INCLUDE (Surfaces, FunctionKey, HareScoped);
GO

-- 5. Sanity check — every function has an AreaKey and a surface.
SELECT AreaKey, Surfaces, COUNT(*) AS Fns
FROM HC.PermissionFunction
GROUP BY AreaKey, Surfaces
ORDER BY AreaKey;
GO
