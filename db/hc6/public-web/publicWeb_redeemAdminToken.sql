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
-- Parameters:  @Token NVARCHAR(36) — UUID token from URL parameter
-- Returns:     Zero rows = invalid/expired token (caller treats as 401)
--              One row { KennelSlug NVARCHAR(100) } = valid token
-- Author:      Harrier Central
-- Created:     2026-05-05
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    IF @Token IS NULL OR LEN(@Token) = 0
        RETURN; -- Zero rows → caller treats as invalid

    DECLARE @TokenId    UNIQUEIDENTIFIER;
    DECLARE @KennelSlug NVARCHAR(100);

    SELECT @TokenId    = Id,
           @KennelSlug = KennelSlug
    FROM   HC.PublicWebAdminToken
    WHERE  LOWER(CAST(Id AS NVARCHAR(36))) = LOWER(@Token)
      AND  ExpiresAt > SYSDATETIMEOFFSET();

    IF @TokenId IS NULL
        RETURN; -- Zero rows → expired or not found

    -- One-time use — delete before returning
    DELETE FROM HC.PublicWebAdminToken WHERE Id = @TokenId;

    SELECT @KennelSlug AS KennelSlug;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    -- Return no rows on error — caller treats as invalid token
END CATCH
