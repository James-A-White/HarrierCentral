-- =====================================================================
-- Procedure: HC6.publicWeb_getKennels
-- Description: Returns the slug for every active kennel that has a
--              public website configured. Used by the sitemap index to
--              generate per-kennel sitemap references.
-- Parameters: None
-- Returns:    Rowset 0 — one row per kennel: Slug
-- Author: Harrier Central
-- Created: 2026-04-22
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getKennels]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Wrap the body so any runtime error is LOGGED to HC.ErrorLog before it reaches
    -- the client, then re-raised (THROW) instead of vanishing as a raw HTTP 500.
    BEGIN TRY

    SELECT k.KennelUniqueShortName AS Slug
    FROM   HC.Kennel        k
    INNER JOIN HC.KennelWebsite kw ON kw.KennelId = k.id
    WHERE  k.deleted = 0
      AND  k.removed = 0
    ORDER BY k.KennelUniqueShortName;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (NEWID(), '<unknown>', 'Unhandled error in getKennels',
                ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), NULL);
        THROW;
    END CATCH
END
