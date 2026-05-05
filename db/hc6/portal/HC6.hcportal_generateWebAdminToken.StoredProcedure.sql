CREATE OR ALTER PROCEDURE [HC6].[hcportal_generateWebAdminToken]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @kennelSlug  NVARCHAR(100)    = NULL
AS
-- =====================================================================
-- Procedure:   HC6.hcportal_generateWebAdminToken
-- Description: Generates a short-lived one-time token that the Flutter
--              portal passes to the Next.js public-web admin UI via URL
--              parameter. The browser redeems the token via
--              publicWeb_redeemAdminToken to create a session cookie.
-- Parameters:  @deviceId    — portal device (auth)
--              @accessToken — device token for this SP name
--              @kennelSlug  — KC.Kennel.KennelUniqueShortName
-- Returns:     { Token NVARCHAR(36) } — one row on success
--              Standard error envelope on failure
-- Author:      Harrier Central
-- Created:     2026-05-05
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
    DECLARE @authError NVARCHAR(255);
    DECLARE @saHasherId UNIQUEIDENTIFIER;
    DECLARE @saCallerType INT;

    EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, NULL,
         @authError OUTPUT, @saHasherId OUTPUT, @saCallerType OUTPUT;

    IF @authError IS NOT NULL
    BEGIN
        SELECT 0 AS Success, @authError AS ErrorMessage;
        RETURN;
    END

    IF @kennelSlug IS NULL OR LEN(@kennelSlug) = 0
    BEGIN
        SELECT 0 AS Success, 'kennelSlug is required.' AS ErrorMessage;
        RETURN;
    END

    DECLARE @KennelId UNIQUEIDENTIFIER;
    SELECT @KennelId = k.id
    FROM   HC.Kennel k
    WHERE  k.KennelUniqueShortName = @kennelSlug
      AND  k.deleted = 0
      AND  k.removed = 0;

    IF @KennelId IS NULL
    BEGIN
        SELECT 0 AS Success, 'Kennel not found.' AS ErrorMessage;
        RETURN;
    END

    -- Require AppAccessFlags bit 0 (portal admin) for the requesting hasher
    DECLARE @HasAdminRights BIT = 0;
    SELECT @HasAdminRights = CASE WHEN (hkm.AppAccessFlags & 0x00000001) <> 0 THEN 1 ELSE 0 END
    FROM   HC.HasherKennelMap hkm
    WHERE  hkm.UserId   = @saHasherId
      AND  hkm.KennelId = @KennelId
      AND  hkm.removed  = 0;

    IF @HasAdminRights = 0
    BEGIN
        SELECT 0 AS Success, 'You do not have admin access to this kennel website.' AS ErrorMessage;
        RETURN;
    END

    -- Purge stale tokens to keep the table small
    DELETE FROM HC.PublicWebAdminToken WHERE ExpiresAt < SYSDATETIMEOFFSET();

    DECLARE @Token UNIQUEIDENTIFIER = NEWID();

    INSERT INTO HC.PublicWebAdminToken (Id, HasherId, KennelSlug, ExpiresAt)
    VALUES (@Token, @saHasherId, @kennelSlug,
            DATEADD(MINUTE, 10, SYSDATETIMEOFFSET()));

    -- Return lowercase UUID — Next.js compares with LOWER()
    SELECT LOWER(CAST(@Token AS NVARCHAR(36))) AS Token;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
