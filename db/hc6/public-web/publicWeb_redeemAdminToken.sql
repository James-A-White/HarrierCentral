CREATE OR ALTER PROCEDURE [HC6].[publicWeb_redeemAdminToken]
    @Token NVARCHAR(36) = NULL
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_redeemAdminToken
-- Description: Validates and redeems a one-time admin token generated
--              by hcportal_generateWebAdminToken. Called by the Next.js
--              /api/admin/auth route to exchange the URL token for a
--              session cookie. Tokens expire after 10 minutes and are
--              deleted on first use.
--              Uses a single atomic DELETE...OUTPUT to eliminate the
--              SELECT+DELETE race condition (H14 fix). Two concurrent
--              requests for the same token will only one succeed —
--              the DELETE is the lock.
-- Parameters:  @Token NVARCHAR(36) — UUID token from URL parameter
-- Returns:     Zero rows = invalid/expired token (caller treats as 401)
--              One row { KennelSlug NVARCHAR(100) } = valid token
-- Author:      Harrier Central
-- Created:     2026-05-05
-- Updated:     2026-05-28 — atomic DELETE...OUTPUT to fix race condition (H14)
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    IF @Token IS NULL OR LEN(@Token) = 0
        RETURN; -- Zero rows → caller treats as invalid

    -- Atomic redeem: DELETE and capture the slug in one statement.
    -- If the token is expired or not found, no rows are deleted and
    -- @OutputTable will be empty — caller receives zero rows (→ 401).
    DECLARE @OutputTable TABLE (KennelSlug NVARCHAR(100));

    DELETE FROM HC.PublicWebAdminToken
    OUTPUT deleted.KennelSlug INTO @OutputTable
    WHERE  LOWER(CAST(Id AS NVARCHAR(36))) = LOWER(@Token)
      AND  ExpiresAt > SYSDATETIMEOFFSET();

    SELECT KennelSlug FROM @OutputTable;
    -- Zero rows → expired/not found; one row → valid token, already consumed.

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    -- Return no rows on error — caller treats as invalid token
END CATCH
