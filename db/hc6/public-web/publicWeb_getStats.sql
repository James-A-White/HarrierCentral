CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getStats]
    @PublicKennelId NVARCHAR(50)
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getStats
-- Description: Returns run statistics for a kennel's public stats page.
--              All hashers with a non-removed relationship to the kennel
--              (removed = 0) are included, regardless of IsMember flag.
--              Display name uses the kennel-specific hash name when set,
--              falling back to the hasher's global hash name, then the
--              computed DisplayName.
--              Returns two rowsets:
--                Rowset 0: { HasherCount INT } — always 1 row when the
--                          kennel is found. Empty (0 rows) → shim returns
--                          404. Prevents false 404 when kennel has no
--                          hashers yet.
--                Rowset 1: hasher stat rows, ordered by
--                          RollingYearRuns DESC, TotalRuns DESC.
-- Parameters:  @PublicKennelId  NVARCHAR(50) — HC.Kennel.PublicKennelId
-- Returns:     Rowset 0: { HasherCount INT }
--              Rowset 1: Rank, DisplayName, TotalRuns, TotalHaring,
--                        YtdRuns, YtdHaring, RollingYearRuns,
--                        RollingYearHaring
--              On validation or runtime error: { Success=0, ErrorMessage }
-- Author:      Harrier Central
-- Created:     2026-03-29
-- HC5 Source:  None — new for HC6 public web
-- Breaking Changes: None
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- ── Input validation ─────────────────────────────────────────────────────

    IF LEN(LTRIM(RTRIM(ISNULL(@PublicKennelId, '')))) = 0
    BEGIN
        SELECT 0 AS Success, 'PublicKennelId is required.' AS ErrorMessage;
        RETURN;
    END;

    -- ── Resolve kennel ───────────────────────────────────────────────────────

    DECLARE @KennelId UNIQUEIDENTIFIER;

    SELECT @KennelId = k.id
    FROM   HC.Kennel k
    WHERE  k.PublicKennelId = CONVERT(UNIQUEIDENTIFIER, @PublicKennelId)
      AND  k.deleted = 0
      AND  k.removed = 0;

    IF @KennelId IS NULL
    BEGIN
        -- Empty Rowset 0 → shim treats as 404 (kennel not found or inactive)
        SELECT TOP 0 CAST(NULL AS INT) AS MemberCount;
        RETURN;
    END;

    -- ── Rowset 0: hasher count ───────────────────────────────────────────────
    -- Always 1 row (COUNT never returns empty), so the shim never mistakes
    -- an empty hasher list for a missing kennel.

    SELECT COUNT(*) AS HasherCount
    FROM   HC.HasherKennelMap hkm
    WHERE  hkm.KennelId = @KennelId
      AND  hkm.removed  = 0;

    -- ── Rowset 1: hasher stats ────────────────────────────────────────────────

    SELECT
        ROW_NUMBER() OVER (
            ORDER BY COALESCE(hkm.RollingYearTotalRunCount, 0) DESC,
                     (hkm.HcTotalRunCount + hkm.HistoricalTotalRunCount) DESC
        ) AS Rank,

        -- Display name: kennel-specific hash name first, then global hash
        -- name, then the computed DisplayName (which handles first/last).
        -- NULLIF strips empty strings so COALESCE skips them.
        COALESCE(
            NULLIF(LTRIM(RTRIM(hkm.KennelHashName)), ''),
            NULLIF(LTRIM(RTRIM(h.HashName)),         ''),
            h.DisplayName
        ) AS DisplayName,

        -- Lifetime totals: HC-tracked runs + pre-HC historical runs
        hkm.HcTotalRunCount + hkm.HistoricalTotalRunCount AS TotalRuns,
        hkm.HcHaringCount   + hkm.HistoricalHaringCount   AS TotalHaring,

        -- Year-to-date (calendar year, maintained by the portal)
        hkm.YtdTotalRunCount AS YtdRuns,
        hkm.YtdHaringCount   AS YtdHaring,

        -- Rolling last-365-days (nullable in older records — default to 0)
        COALESCE(hkm.RollingYearTotalRunCount, 0) AS RollingYearRuns,
        COALESCE(hkm.RollingYearHaringCount,  0)  AS RollingYearHaring

    FROM  HC.HasherKennelMap hkm
    INNER JOIN HC.Hasher h ON h.id = hkm.UserId
    WHERE hkm.KennelId = @KennelId
      AND hkm.removed  = 0
      AND (hkm.HcTotalRunCount + hkm.HistoricalTotalRunCount) > 0
    ORDER BY
        COALESCE(hkm.RollingYearTotalRunCount, 0) DESC,
        (hkm.HcTotalRunCount + hkm.HistoricalTotalRunCount) DESC;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
