CREATE OR ALTER PROCEDURE [HC6].[publicWeb_resolveKennelsByUuid]
    @PublicKennelIds NVARCHAR(MAX)
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_resolveKennelsByUuid
-- Description: Resolves one or more comma-separated PublicKennelId UUIDs
--              to kennel slugs and optional custom domains. Used by the
--              legacy URL shim to redirect old hashruns.org hash-based
--              URLs (/#/RD?publicKennelIds=...) to the new site.
-- Parameters:  @PublicKennelIds NVARCHAR(MAX) — one or more UUIDs,
--                  comma-separated, e.g.
--                  '934306c8-035a-4af8-b4fa-a593bc28bf36'
--                  '934306c8-...,7a1b2c3d-...'
--              Malformed or unrecognised UUIDs are silently skipped
--              (TRY_CAST returns NULL for invalid values; the INNER JOIN
--              condition then fails to match any row).
-- Returns:     Rowset 0: one row per resolved kennel:
--                { KennelSlug NVARCHAR(100), KennelName NVARCHAR(250),
--                  CustomDomain NVARCHAR(250) | NULL }
--              Zero rows when no UUIDs resolve (kennel not found,
--              deleted, or removed).
-- Author:      Harrier Central
-- Created:     2026-04-27
-- HC5 Source:  None — new for HC6 legacy redirect shim
-- Breaking Changes: None
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    SELECT
        k.KennelUniqueShortName     AS KennelSlug,
        k.KennelName,
        kw.CustomDomain
    FROM       HC.Kennel        k
    LEFT JOIN  HC.KennelWebsite kw  ON kw.KennelId = k.id
    INNER JOIN STRING_SPLIT(@PublicKennelIds, ',') s
                                    ON k.PublicKennelId = TRY_CAST(LTRIM(RTRIM(s.value)) AS UNIQUEIDENTIFIER)
    WHERE k.deleted  = 0
      AND k.removed  = 0;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
