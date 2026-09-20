CREATE OR ALTER PROCEDURE [HC6].[hcapp_deletePasskey]
    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @targetDeviceId UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_deletePasskey
-- Description: Removes one passkey from the calling hasher's account
--   (E9.F7.S18) by clearing the four credential columns on that
--   HC.Device row. The DEVICE ROW SURVIVES: it still holds the device
--   secret that signs this hasher's API calls, so deleting the passkey
--   must not sign the browser out — it only takes away the one-tap
--   sign-in. Removing the device itself is a different act with a
--   different consequence, and is not this SP.
--
--   A passkey that has been revoked here is refused at sign-in by
--   publicWeb_getPasskey finding no row, which the web route reports as
--   "That passkey isn't registered here."
--
-- Authorization: @userId comes from the token and the UPDATE is scoped to
--   it, so a hasher can only ever delete their own — a forged
--   @targetDeviceId belonging to someone else matches no row and is
--   reported as not found, revealing nothing about whose it was.
--
--   A standard token (the device secret) is used rather than a compound
--   one. The compound form binds a token to a target and is for acts
--   against someone else or against money; here the only reachable target
--   is the caller's own credential, so the extra binding would add a
--   failure mode without removing a risk.
--
-- Returns: rowset 0 — standard success envelope.
--          rowset 1 — the hasher's REMAINING passkeys, same shape as
--                     hcapp_listPasskeys, so the screen can repaint from
--                     the reply instead of asking again.
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
    @spNumber = 120, @param = NULL,
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
    SELECT 0 AS success, 1950 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 1950 AS errorCode,
           'Missing fields' AS errorTitle,
           'That passkey could not be removed. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @label NVARCHAR(100) =
        (SELECT TOP 1 COALESCE(NULLIF(LTRIM(RTRIM(d.OperatingSystem)), ''), 'Device')
                      + ' on ' + HC6.DevicePlatformName(d.DeviceData)
         FROM HC.Device d
         WHERE d.id = @targetDeviceId AND d.UserId = @userId AND d.removed = 0);

    UPDATE HC.Device
       SET PasskeyCredentialId = NULL,
           PasskeyPublicKey    = NULL,
           PasskeyCounter      = NULL,
           PasskeyTransports   = NULL,
           updatedAt           = GETDATE()
     WHERE id                  = @targetDeviceId
       AND UserId              = @userId          -- yours, or nothing
       AND removed             = 0
       AND PasskeyCredentialId IS NOT NULL;       -- idempotent: already gone is "not found"

    IF (@@ROWCOUNT = 0)
    BEGIN
        SET @errorId = NEWID();
        ROLLBACK TRANSACTION;                     -- FIRST: the log must survive
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Passkey not found',
                'No passkey on device ' + CAST(@targetDeviceId AS NVARCHAR(40))
                + ' for this hasher', @procName, @userId);
        SELECT 0 AS success, 1951 AS errorCode, 3 AS errorType;
        SELECT @errorId AS errorId, 3 AS errorType, 1951 AS errorCode,
               'Not found' AS errorTitle,
               'That passkey is not on your account any more.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END

    -- Revoking a credential is worth an audit trail: it is the one act here
    -- that takes access away, and "when did that stop working" is the
    -- question it will be asked about.
    INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, Timestamp)
    VALUES ('HC6.hcapp_deletePasskey', 'Passkey removed',
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
        ISNULL(d.IsMobile, 0)                                        AS IsMobile
    FROM HC.Device d
    WHERE d.UserId = @userId
      AND d.removed = 0
      AND d.PasskeyCredentialId IS NOT NULL
    ORDER BY d.LastLogin DESC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in deletePasskey',
            ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, ERROR_MESSAGE() AS errorMessage;
    SELECT @errorId AS errorId, 5 AS errorType, 1952 AS errorCode,
           'Something went wrong' AS errorTitle,
           'That passkey could not be removed. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
