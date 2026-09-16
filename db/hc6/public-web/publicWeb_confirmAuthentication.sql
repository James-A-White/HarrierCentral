CREATE OR ALTER PROCEDURE [HC6].[publicWeb_confirmAuthentication]
    @newDeviceId UNIQUEIDENTIFIER = NULL,
    @qrCodeData  NVARCHAR(250)    = NULL,
    @deviceInfo  NVARCHAR(4000)   = NULL
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_confirmAuthentication
-- Description: The public web's half of the QR sign-in (E9.F7.S7). The
--              page shows https://www.hashruns.org/login/UWP:<authCode>;
--              the phone's camera opens the app, which calls
--              hcapp_authenticateWebPortal and writes the
--              HC.WebPortalAuthenticationRequests row. The page polls
--              this SP until that row exists, at which point the browser
--              is provisioned as an HC.Device (IsMobile = 0) bound to the
--              hasher who scanned, and the credentials are returned for
--              the member cookie. Single-use and 5-minute TTL, exactly as
--              hcportal_confirmAuthentication — this IS that SP minus the
--              portal's service-account auth, because the caller is the
--              Next.js server behind HC_INTERNAL_SECRET, not a browser.
--              The scanData match is the proof: it is a random UUID the
--              page chose, and the only way a row with it exists is that a
--              registered phone signed it.
-- Parameters:  @newDeviceId - the id the browser will use as its device id
--              @qrCodeData  - 'UWP:' + authCode, as encoded in the QR
--              @deviceInfo  - JSON, e.g. {"browserName":"Safari","userAgent":"…"}
-- Returns:     No rows while unscanned (caller keeps polling).
--              One row once scanned: deviceId, deviceSecret, timeWindow,
--              hasherId, publicHasherId, hashName, displayName, photo.
-- Author:      Harrier Central
-- Created:     2026-09-16
-- HC5 Source:  none (portal flow: HC6.hcportal_confirmAuthentication)
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    IF (@newDeviceId IS NULL) OR (@qrCodeData IS NULL) OR (LEN(@qrCodeData) < 10)
        RETURN; -- nothing to confirm; the caller treats no rows as "not yet"

    DECLARE @ttlSeconds INT = 300;
    DECLARE @hasherId UNIQUEIDENTIFIER;

    SELECT TOP 1 @hasherId = w.hasherId
    FROM HC.WebPortalAuthenticationRequests w
    INNER JOIN HC.Hasher h ON h.id = w.hasherId AND h.Removed = 0
    WHERE TRIM(LOWER(w.scanData)) = TRIM(LOWER(@qrCodeData))
      AND ISNULL(w.Removed, 0) = 0
      AND w.updatedAt > DATEADD(SECOND, -@ttlSeconds, SYSDATETIMEOFFSET());

    IF (@hasherId IS NULL) RETURN;

    DECLARE @deviceSecret NVARCHAR(150), @timeWindow INT;
    SELECT @deviceSecret = d.DeviceSecret, @timeWindow = d.TimeWindow
    FROM HC.Device d WHERE d.id = @newDeviceId;

    BEGIN TRANSACTION;

    IF (@deviceSecret IS NULL)
    BEGIN
        -- Same recipe as hcapp_authorizeDevice: 75 uppercase base64 chars
        -- from 150 random bytes, and a per-device token window of 30–44 s.
        DECLARE @binaryData VARBINARY(MAX) = CRYPT_GEN_RANDOM(150);
        SELECT @deviceSecret = LEFT(REPLACE(REPLACE(
            CAST('' AS XML).value('xs:base64Binary(sql:variable("@binaryData"))', 'varchar(max)'),
            '+', ''), '/', ''), 75);
        SELECT @timeWindow = CAST((RAND() * 15) + 30 AS INT);

        INSERT INTO HC.Device ([id], [UserId], [DeviceSecret], [TimeWindow], [DeviceData], [IsMobile])
        VALUES (@newDeviceId, @hasherId, @deviceSecret, @timeWindow, COALESCE(@deviceInfo, ''), 0);
    END

    -- Single-use: consume the request so the code cannot be replayed.
    UPDATE HC.WebPortalAuthenticationRequests
    SET Removed = 1
    WHERE TRIM(LOWER(scanData)) = TRIM(LOWER(@qrCodeData));

    COMMIT TRANSACTION;

    SELECT
        @newDeviceId               AS deviceId,
        @deviceSecret              AS deviceSecret,
        @timeWindow                AS timeWindow,
        h.id                       AS hasherId,
        h.PublicHasherId           AS publicHasherId,
        COALESCE(h.HashName, '')   AS hashName,
        COALESCE(h.DisplayName, '') AS displayName,
        COALESCE(h.Photo, '')      AS photo
    FROM HC.Hasher h
    WHERE h.id = @hasherId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_confirmAuthentication',
            ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
