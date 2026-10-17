CREATE OR ALTER PROCEDURE [HC6].[hcportal_getAppVersionUsage]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @days        INT              = 90
AS
-- =====================================================================
-- Procedure: HC6.hcportal_getAppVersionUsage
-- Description: HC Admin Tools › Version email (E19.F3.S3, James
--   2026-10-17): every app build people are on now, with how many use it
--   on iPhone and on Android, for the version dropdown. "On now" is
--   HC6.AppVersionUsers: each person once, at the highest build among
--   their phones that signed in within @days. Every build is listed —
--   the database cannot tell a store build from a beta (James's choice).
--   Requires an HC.PlatformAdmin row with CanManageNewsflash (the
--   capability for messaging people).
-- Parameters: @deviceId, @accessToken (auth); @days (1..3650, default 90).
-- Returns:
--   On refusal: rowset 0 — { Success = 0, ErrorMessage }.
--   On success: rowset 0 — { Version, BuildNumber, Users, IosUsers,
--     AndroidUsers }, newest build first.
-- Author: Harrier Central
-- Created: 2026-10-17
-- HC5 Source: none (new)
-- Breaking Changes: none (new)
-- Idempotency: read-only — reads only
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName   NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @authError  NVARCHAR(255);
DECLARE @callerId   UNIQUEIDENTIFIER;
DECLARE @callerType INT;
EXEC HC6.ValidatePortalAuth
    @deviceId, @accessToken, @procName, NULL,
    @authError OUTPUT, @callerId OUTPUT, @callerType OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END
IF NOT EXISTS (SELECT 1 FROM HC.PlatformAdmin pa
               WHERE pa.UserId = @callerId AND pa.removed = 0 AND pa.CanManageNewsflash = 1)
BEGIN
    SELECT 0 AS Success, 'Not authorised: Platform Admin with CanManageNewsflash required' AS ErrorMessage;
    RETURN;
END
IF (@days IS NULL OR @days < 1 OR @days > 3650) SET @days = 90;

BEGIN TRY
    SELECT MAX(u.version)                  AS Version,
           CAST(u.build AS NVARCHAR(25))   AS BuildNumber,
           COUNT(*)                        AS Users,
           SUM(u.isIos)                    AS IosUsers,
           SUM(u.isAndroid)                AS AndroidUsers
    FROM HC6.AppVersionUsers(@days) u
    JOIN HC.Hasher h ON h.id = u.userId
    WHERE ISNULL(h.Removed, 0) = 0 AND h.deleted = 0
    GROUP BY u.build
    ORDER BY u.build DESC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_getAppVersionUsage',
            ERROR_MESSAGE(), @procName, @callerId);
    THROW;
END CATCH
GO
