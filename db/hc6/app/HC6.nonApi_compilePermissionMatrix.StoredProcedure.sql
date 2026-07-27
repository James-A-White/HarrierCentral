CREATE OR ALTER PROCEDURE [HC6].[nonApi_compilePermissionMatrix]
    @kennelId UNIQUEIDENTIFIER = NULL   -- NULL = recompile global + all kennels with overrides;
                                        -- a value = recompile global + just that kennel's override.
AS
-- =====================================================================
-- Procedure: HC6.nonApi_compilePermissionMatrix
-- Description: Compiles the permission source tables (HC.PermissionFunction /
--   PermissionRole / RolePermission) into the JSON projections the client reads:
--     • Global matrix  → HC.ServerStatus.PermissionMatrixJson (+ bumps the
--       PermissionMatrixUpdatedAt high-water mark).
--     • Per-kennel override → HC.Kennel.PermissionOverrideJson (only for kennels
--       that have override rows; cleared to NULL when a kennel's overrides are gone).
--   Each function compiles to resolved {mmMask, flagMask, hareScoped} so the client
--   does the same bitwise test it does today. The tri-state (grant/revoke/inherit)
--   is resolved here, server-side; the client never sees it.
--   This is the ONLY writer of the projections — the compile-on-save invariant.
-- Parameters: @kennelId — optional; limits the per-kennel recompile to one kennel.
-- Returns: nothing (internal). Raises on error after logging to HC.ErrorLog.
-- Author: Harrier Central
-- Created: 2026-07-27
-- HC5 Source: none (new in HC6, Permissions V2)
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @now DATETIMEOFFSET(7) = SYSDATETIMEOFFSET();

    -- ----- Global matrix → ServerStatus -----
    DECLARE @globalJson NVARCHAR(MAX) =
    (
        SELECT
            1 AS schemaVersion,
            CONVERT(NVARCHAR(40), @now, 127) AS [version],
            (
                SELECT
                    f.FunctionKey AS [key],
                    SUM(CASE WHEN g.GrantorType = 'mmRole'  THEN g.Bit ELSE 0 END) AS mmMask,
                    SUM(CASE WHEN g.GrantorType = 'appFlag' THEN g.Bit ELSE 0 END) AS flagMask,
                    f.HareScoped AS hareScoped
                FROM HC.PermissionFunction f
                LEFT JOIN HC.RolePermission rp
                       ON rp.FunctionId = f.id AND rp.KennelId IS NULL AND rp.Allowed = 1
                LEFT JOIN HC.PermissionRole g ON g.id = rp.GrantorId
                GROUP BY f.id, f.FunctionKey, f.HareScoped, f.SortOrder
                ORDER BY f.SortOrder
                FOR JSON PATH
            ) AS functions
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    UPDATE HC.ServerStatus
    SET PermissionMatrixJson = @globalJson,
        PermissionMatrixUpdatedAt = @now;

    -- ----- Per-kennel overrides → HC.Kennel -----
    -- Effective grant for (grantor, function, kennel):
    --   kennel row Allowed = 1  → granted
    --                       -1  → revoked
    --                        0  → inherit global
    --   no kennel row           → inherit global
    -- A kennel's override JSON lists every function it has any override row for,
    -- with the resolved effective masks (harmless if a function's net effect equals
    -- global — the client just uses the same mask).
    UPDATE kn
    SET PermissionOverrideJson =
    (
        SELECT
            1 AS schemaVersion,
            (
                SELECT
                    f.FunctionKey AS [key],
                    SUM(CASE WHEN g.GrantorType = 'mmRole'  AND e.eff = 1 THEN g.Bit ELSE 0 END) AS mmMask,
                    SUM(CASE WHEN g.GrantorType = 'appFlag' AND e.eff = 1 THEN g.Bit ELSE 0 END) AS flagMask,
                    f.HareScoped AS hareScoped
                FROM (SELECT DISTINCT FunctionId FROM HC.RolePermission WHERE KennelId = kn.id) kf
                JOIN HC.PermissionFunction f ON f.id = kf.FunctionId
                CROSS JOIN HC.PermissionRole g
                LEFT JOIN HC.RolePermission kr
                       ON kr.FunctionId = f.id AND kr.GrantorId = g.id AND kr.KennelId = kn.id
                LEFT JOIN HC.RolePermission gr
                       ON gr.FunctionId = f.id AND gr.GrantorId = g.id AND gr.KennelId IS NULL
                CROSS APPLY (SELECT eff =
                    CASE WHEN kr.Allowed = 1  THEN 1
                         WHEN kr.Allowed = -1 THEN 0
                         WHEN kr.Allowed = 0  THEN COALESCE(gr.Allowed, 0)
                         ELSE COALESCE(gr.Allowed, 0) END) e
                GROUP BY f.id, f.FunctionKey, f.HareScoped, f.SortOrder
                ORDER BY f.SortOrder
                FOR JSON PATH
            ) AS functions
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    )
    FROM HC.Kennel kn
    WHERE (@kennelId IS NULL OR kn.id = @kennelId)
      AND EXISTS (SELECT 1 FROM HC.RolePermission WHERE KennelId = kn.id);

    -- Clear the projection for kennels whose overrides have all been removed.
    UPDATE kn
    SET PermissionOverrideJson = NULL
    FROM HC.Kennel kn
    WHERE (@kennelId IS NULL OR kn.id = @kennelId)
      AND kn.PermissionOverrideJson IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM HC.RolePermission WHERE KennelId = kn.id);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_compilePermissionMatrix',
            ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
GO
