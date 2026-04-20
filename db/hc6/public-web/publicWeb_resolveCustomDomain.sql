CREATE OR ALTER PROCEDURE [HC6].[publicWeb_resolveCustomDomain]
    @CustomDomain NVARCHAR(253)
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_resolveCustomDomain
-- Description: Resolves a custom domain (e.g. www.decisionhall.com) to
--              the kennel slug that should handle requests for it.
--              Called by the Next.js middleware on every request from an
--              unrecognised hostname; result is cached in-process.
-- Parameters:  @CustomDomain NVARCHAR(253) — hostname without port,
--                  e.g. 'www.decisionhall.com' or 'decisionhall.com'
-- Returns:     Rowset 0: { KennelSlug NVARCHAR(100) } — one row when
--                        found; zero rows (→ 404 from shim) when no
--                        kennel owns this domain or the kennel is
--                        disabled/deleted.
-- Author:      Harrier Central
-- Created:     2026-04-20
-- HC5 Source:  None — new for HC6 custom domain routing
-- Breaking Changes: None
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    SELECT k.KennelUniqueShortName AS KennelSlug
    FROM   HC.KennelWebsite kw
    JOIN   HC.Kennel        k  ON k.id = kw.KennelId
    WHERE  kw.CustomDomain = @CustomDomain
      AND  kw.Enabled      = 1
      AND  k.deleted       = 0
      AND  k.removed       = 0;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
