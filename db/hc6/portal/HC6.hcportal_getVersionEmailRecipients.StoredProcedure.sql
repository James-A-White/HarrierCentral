CREATE OR ALTER PROCEDURE [HC6].[hcportal_getVersionEmailRecipients]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @builds      NVARCHAR(MAX)    = NULL,
    @days        INT              = 90,
    @sendId      UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcportal_getVersionEmailRecipients
-- Description: HC Admin Tools › Version email (E19.F3.S3): who the email
--   would reach for the chosen build(s), and who is listed but will not
--   be sent it, with why (HC6.VersionEmailAudience — the same rule the
--   send queue reads). With @sendId, also how that send is going, for the
--   page's progress line while it sends.
--   Requires an HC.PlatformAdmin row with CanManageNewsflash.
-- Parameters: @deviceId, @accessToken (auth); @builds ('|'-delimited
--   build numbers); @days (1..3650, default 90); @sendId (optional).
-- Returns:
--   On refusal: rowset 0 — { Success = 0, ErrorMessage }.
--   On success: rowset 0 — one row per person { PublicHasherId, Name,
--     FirstName, Email, IsGeneratedEmail, Version, BuildNumber, IsIos,
--     IsAndroid, LastLogin, LastVersionEmailAt, Eligible, Reason },
--     eligible first; rowset 1 — { Queued, Sending, Sent, Failed } for
--     @sendId (all 0 without one).
--   Public ids only: a browser never holds an internal hasher id.
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
SET @builds = ISNULL(@builds, '');

BEGIN TRY
    SELECT a.publicHasherId                AS PublicHasherId,
           a.name                          AS Name,
           a.firstName                     AS FirstName,
           a.email                         AS Email,
           CAST(HC6.IsGeneratedEmail(a.email) AS SMALLINT) AS IsGeneratedEmail,
           a.version                       AS Version,
           CAST(a.build AS NVARCHAR(25))   AS BuildNumber,
           a.isIos                         AS IsIos,
           a.isAndroid                     AS IsAndroid,
           a.lastLogin                     AS LastLogin,
           a.lastVersionEmailAt            AS LastVersionEmailAt,
           a.eligible                      AS Eligible,
           a.reason                        AS Reason
    FROM HC6.VersionEmailAudience(@builds, @days) a
    ORDER BY a.eligible DESC, a.name;

    SELECT ISNULL(SUM(CASE WHEN l.Status = 0 THEN 1 ELSE 0 END), 0) AS Queued,
           ISNULL(SUM(CASE WHEN l.Status = 3 THEN 1 ELSE 0 END), 0) AS Sending,
           ISNULL(SUM(CASE WHEN l.Status = 1 THEN 1 ELSE 0 END), 0) AS Sent,
           ISNULL(SUM(CASE WHEN l.Status = 2 THEN 1 ELSE 0 END), 0) AS Failed
    FROM HC.EmailLog l
    WHERE @sendId IS NOT NULL AND l.SendId = @sendId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_getVersionEmailRecipients',
            ERROR_MESSAGE(), @procName, @callerId);
    THROW;
END CATCH
GO
