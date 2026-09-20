CREATE OR ALTER PROCEDURE [HC6].[hcapp_listPasskeys]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_listPasskeys
-- Description: Every passkey registered against the calling hasher
--   (E9.F7.S18). A passkey is a credential on an HC.Device row — there is
--   no separate table — so this is "which of my devices can sign me in
--   without a code", which is the question the screen is really asking.
--
--   The hasher sees what they need to recognise a device and nothing that
--   would help anyone else: a label built from the browser and platform,
--   when it last signed in, and whether it is the device asking. The
--   credential id and public key NEVER leave the server; they identify the
--   credential to an authenticator and are of no use on a settings screen.
--
-- Authorization: @userId comes from the token, never a parameter, and the
--   WHERE clause is scoped to it — a hasher can only ever see their own.
--
-- Returns: rowset 0 — standard success envelope.
--          rowset 1 — one row per passkey (newest sign-in first):
--            DeviceId, Label, Platform, IsThisDevice, LastLogin, IsMobile
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
    @spNumber = 119, @param = NULL,
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

BEGIN TRY
    SELECT 1 AS success, NULL AS errorMessage;

    SELECT
        CAST(d.id AS NVARCHAR(40))                                   AS DeviceId,
        -- "Safari on iPhone", "Chrome on Windows", "Harrier Central on
        -- iPhone" — enough to recognise, nothing to leak.
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
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in listPasskeys',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
