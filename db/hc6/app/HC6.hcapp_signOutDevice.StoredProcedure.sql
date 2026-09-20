CREATE OR ALTER PROCEDURE [HC6].[hcapp_signOutDevice]
    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @targetDeviceId UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_signOutDevice
-- Description: Cuts one device off this hasher's account (E9.F7.S19) —
--   the act that was missing when only a passkey could be removed, so a
--   lost phone stayed signed in for the life of its cookie.
--
-- HOW REVOCATION WORKS HERE, because it is not obvious:
--   ValidateAppAuth resolves the caller with WHERE d.id = @deviceId and
--   NO removed filter, then validates the token against the row's
--   DeviceSecret. So flipping `removed` revokes nothing, and ROTATING
--   THE SECRET revokes everything — instantly, for that device alone,
--   and the phone cannot re-derive the new one. The new secret is minted
--   exactly as hcapp_authorizeDevice mints it.
--
--   `removed = 1` is set as well, but ONLY so the row can leave the list
--   (see hcapp_listDevices). Do NOT add `AND removed = 0` to
--   ValidateAppAuth to make it mean more: 300 devices already carry it
--   and 46 signed in within 90 days, so that filter would cut off 13
--   active people in a week.
--
--   FcmToken and ApnsToken are cleared too, and that is not tidiness: the
--   push queries filter on the token being present, not on `removed`, so
--   a lost phone would otherwise keep buzzing with this hasher's chats.
--
--   A passkey on the device is deliberately NOT removed. They are two
--   acts with two consequences, and the list keeps showing a signed-out
--   device while it still holds a passkey precisely so the second one can
--   still be done.
--
-- Authorization: @userId comes from the token and the UPDATE is scoped to
--   it, so a hasher can only ever sign out their own devices; a forged
--   @targetDeviceId matches no row and reads as not found.
--
-- Returns: rowset 0 — standard success envelope.
--          rowset 1 — the hasher's devices after the change, same shape
--                     as hcapp_listDevices.
-- Author: Harrier Central
-- Created: 2026-09-20
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 122, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow = @timeWindow OUTPUT, @errorCode = @errorCode OUTPUT,
    @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

-- Pre-flight, OUTSIDE the transaction so there is no rollback to get wrong.
IF (@targetDeviceId IS NULL)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Missing fields',
            'targetDeviceId was not supplied', @procName, @userId);
    SELECT 0 AS success, 1960 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 1960 AS errorCode,
           'Missing fields' AS errorTitle,
           'That device could not be signed out. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @label NVARCHAR(100) =
        (SELECT TOP 1 COALESCE(NULLIF(LTRIM(RTRIM(d.OperatingSystem)), ''), 'Device')
                      + ' on ' + HC6.DevicePlatformName(d.DeviceData)
         FROM HC.Device d
         WHERE d.id = @targetDeviceId AND d.UserId = @userId);

    -- A fresh secret, minted exactly as hcapp_authorizeDevice mints one.
    DECLARE @binaryData VARBINARY(MAX) = CRYPT_GEN_RANDOM(150);
    DECLARE @newSecret  NVARCHAR(150);
    SELECT @newSecret = LEFT(
        UPPER(REPLACE(REPLACE(
            CAST('' AS XML).value('xs:base64Binary(sql:variable("@binaryData"))', 'varchar(max)'),
            '+', ''), '/', '')),
        75);

    UPDATE HC.Device
       SET DeviceSecret = @newSecret,   -- the revocation itself
           FcmToken     = NULL,         -- stop the pushes; they key on this
           ApnsToken    = NULL,
           removed      = 1,            -- list-only meaning (see header)
           updatedAt    = GETDATE()
     WHERE id     = @targetDeviceId
       AND UserId = @userId             -- yours, or nothing
       AND removed = 0;                 -- idempotent: already out is "not found"

    IF (@@ROWCOUNT = 0)
    BEGIN
        SET @errorId = NEWID();
        ROLLBACK TRANSACTION;                     -- FIRST: the log must survive
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Device not found',
                'No signed-in device ' + CAST(@targetDeviceId AS NVARCHAR(40))
                + ' for this hasher', @procName, @userId);
        SELECT 0 AS success, 1961 AS errorCode, 3 AS errorType;
        SELECT @errorId AS errorId, 3 AS errorType, 1961 AS errorCode,
               'Not found' AS errorTitle,
               'That device is already signed out.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END

    -- Cutting a device off is worth an audit trail: it is the act someone
    -- will ask about afterwards, from a phone that can no longer explain
    -- itself.
    INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, Timestamp)
    VALUES ('HC6.hcapp_signOutDevice', 'Device signed out',
            CAST(@userId AS NVARCHAR(40)),
            'device=' + CAST(@targetDeviceId AS NVARCHAR(40))
            + ' label=' + COALESCE(@label, '(unknown)')
            + ' by=' + CAST(@deviceId AS NVARCHAR(40)),
            SYSDATETIMEOFFSET());

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorMessage;

    SELECT
        CAST(d.id AS NVARCHAR(40))                                   AS DeviceId,
        LTRIM(RTRIM(
            COALESCE(NULLIF(LTRIM(RTRIM(d.OperatingSystem)), ''),
                     CASE WHEN d.IsMobile = 1 THEN 'Harrier Central' ELSE 'Browser' END)
            + ' on ' + HC6.DevicePlatformName(d.DeviceData)))        AS Label,
        HC6.DevicePlatformName(d.DeviceData)                         AS Platform,
        CASE WHEN d.id = @deviceId THEN 1 ELSE 0 END                 AS IsThisDevice,
        d.LastLogin                                                  AS LastLogin,
        ISNULL(d.IsMobile, 0)                                        AS IsMobile,
        CASE WHEN d.PasskeyCredentialId IS NOT NULL THEN 1 ELSE 0 END AS HasPasskey,
        CASE WHEN d.removed = 1 THEN 1 ELSE 0 END                    AS IsSignedOut
    FROM HC.Device d
    WHERE d.UserId = @userId
      AND (d.removed = 0 OR d.PasskeyCredentialId IS NOT NULL)
    ORDER BY d.LastLogin DESC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in signOutDevice',
            ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, ERROR_MESSAGE() AS errorMessage;
    SELECT @errorId AS errorId, 5 AS errorType, 1962 AS errorCode,
           'Something went wrong' AS errorTitle,
           'That device could not be signed out. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
