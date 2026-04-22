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

    SELECT k.KennelUniqueShortName AS Slug
    FROM   HC.Kennel        k
    INNER JOIN HC.KennelWebsite kw ON kw.KennelId = k.id
    WHERE  k.deleted = 0
      AND  k.removed = 0
    ORDER BY k.KennelUniqueShortName;
END
