CREATE OR ALTER PROCEDURE [HC6].[hcportal_confirmAuthentication]

-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
@deviceId uniqueidentifier = NULL,
@publicHasherId uniqueidentifier = NULL,
@accessToken nvarchar(1000) = NULL,
@qrCodeData nvarchar(250) = NULL,
@deviceInfo nvarchar(4000) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_confirmAuthentication
-- Description: Confirms a portal authentication request initiated by a
--   QR code scan from the mobile app. The portal (browser) calls this
--   SP after displaying a QR code. If the app has scanned it and
--   inserted a matching WebPortalAuthenticationRequests record, the SP
--   provisions a new HC.Device record with a shared secret and returns
--   the user's profile along with the device credentials (obfuscated
--   as iconDataBase64 and colorPaletteIndex).
-- Parameters: @deviceId, @publicHasherId (service account GUID),
--   @accessToken, @qrCodeData, @deviceInfo
-- Returns: On error: HC6 envelope (Success, ErrorMessage). On success:
--   user profile with obfuscated device credentials. Silent empty
--   return if no matching auth request exists.
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_confirmAuthentication
-- Breaking Changes: Validation now short-circuits on first error
--   (HC5 could return multiple error rowsets). Fixed DATALENGTH to
--   IS NULL for UNIQUEIDENTIFIER checks. Added TRY/CATCH and
--   transaction around Device INSERT.
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog inserts (error logging moved to API shim)
--   - Removed GeneralLog inserts (request logging moved to API shim)
--   - Error rowset shape changed from multi-column HC5 error format
--     to standard HC6 envelope (Success, ErrorMessage)
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    SELECT @deviceId = coalesce(@deviceId, newid())

    -- Auth validation
    DECLARE @authError NVARCHAR(255);
    EXEC HC6.ValidatePortalAuth @publicHasherId, @accessToken, OBJECT_NAME(@@PROCID), @qrCodeData, @authError OUTPUT;
    IF @authError IS NOT NULL
    BEGIN
        SELECT 0 AS Success, @authError AS ErrorMessage;
        RETURN;
    END

    -- Validation: qrCodeData must not be NULL and must be at least 10 chars
    IF (@qrCodeData IS NULL) OR (LEN(@qrCodeData) < 10)
    BEGIN
        SELECT 0 AS Success, 'Null or invalid QR code scan data' AS ErrorMessage;
        RETURN;
    END

    -- Check for matching auth request
    DECLARE @count int = 0

    SELECT @count = COUNT(*) FROM HC.WebPortalAuthenticationRequests w
    WHERE trim(lower(scanData)) = trim(lower(@qrCodeData))

    -- If no matching auth request exists, return silently (no rowset)
    IF (@count = 0)
    BEGIN
        RETURN;
    END

    DECLARE @deviceSecret nvarchar(150), @timeWindow int

    SELECT
            @deviceSecret = d.DeviceSecret,
            @timeWindow = d.TimeWindow
            FROM HC.Device d where d.id = @deviceId

    -- Provision new device if no existing secret
    IF(@deviceSecret IS NULL)
    BEGIN

        DECLARE @hasherId uniqueidentifier
        DECLARE @BinaryData varbinary(max) = crypt_gen_random (150)
        SELECT @deviceSecret = LEFT(REPLACE(REPLACE(cast('' as xml).value('xs:base64Binary(sql:variable("@BinaryData"))', 'varchar(max)'), '+', ''), '/', ''), 75)
        SELECT @timeWindow = cast((rand()*15)+30 as int)

        SELECT
                @hasherId = h.id
                FROM HC.WebPortalAuthenticationRequests w
                INNER JOIN HC.Hasher h on w.hasherId = h.id
                WHERE trim(lower(scanData)) = trim(lower(@qrCodeData))

            IF (@hasherId IS NOT NULL)
            BEGIN
                BEGIN TRANSACTION;

                INSERT INTO [HC].[Device]
                    ([id]
                    , [UserId]
                    , [DeviceSecret]
                    , [TimeWindow]
                    , [DeviceData])
                    VALUES
                    (@deviceId
                    , @hasherId
                    , @deviceSecret
                    , @timeWindow
                    , @deviceInfo
                    )

                COMMIT TRANSACTION;
        END
    END

    -- Return user profile with obfuscated device credentials
    SELECT
        h.PublicHasherId as publicHasherId,
        w.scanData as scanData,
        coalesce(h.FirstName, '') as firstName,
        coalesce(h.LastName, '') as lastName,
        coalesce(h.HashName, '') as hashName,
        coalesce(h.DisplayName, '') as displayName,
        coalesce(h.Photo, '') as photo,
        @deviceSecret as iconDataBase64, -- a bit of security by obscurity here
        @timeWindow as colorPaletteIndex -- more security through obscurity
    FROM HC.WebPortalAuthenticationRequests w
    INNER JOIN HC.Hasher h on w.hasherId = h.id
    WHERE trim(lower(scanData)) = trim(lower(@qrCodeData))

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
