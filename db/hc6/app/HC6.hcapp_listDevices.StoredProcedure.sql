CREATE OR ALTER PROCEDURE [HC6].[hcapp_listDevices]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_listDevices
-- Description: Everything that can get into this hasher's account
--   (E9.F7.S19) — every device, with whether it holds a passkey and
--   whether it has been signed out.
--
--   Supersedes hcapp_listPasskeys for new clients. That SP stays deployed
--   and unchanged because builds 1390 and 1391 are already on testers'
--   phones calling it; it simply shows a subset of this.
--
--   EVERYTHING is listed, with no "active in the last N days" rule
--   (James, 2026-09-20) — a hasher looking for the phone they lost must
--   not have to wonder whether it aged out. A row leaves the list only
--   when the device is BOTH signed out AND holds no passkey, which is the
--   point at which it can no longer reach the account by any route:
--
--       WHERE d.removed = 0 OR d.PasskeyCredentialId IS NOT NULL
--
--   So a signed-out device that still holds a passkey stays visible until
--   that passkey is removed, and then disappears.
--
-- Authorization: @userId comes from the token, never a parameter, and the
--   WHERE clause is scoped to it.
--
-- Returns: rowset 0 — standard success envelope.
--          rowset 1 — one row per device, most recent sign-in first:
--            DeviceId, Label, Platform, IsThisDevice, LastLogin,
--            IsMobile, HasPasskey, IsSignedOut
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
    @spNumber = 121, @param = NULL,
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
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in listDevices',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
