CREATE OR ALTER PROCEDURE [HC6].[hcportal_queueVersionEmail]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @sendId      UNIQUEIDENTIFIER = NULL,
    @builds      NVARCHAR(MAX)    = NULL,
    @days        INT              = 90,
    @subject     NVARCHAR(MAX)    = NULL,
    @test        SMALLINT         = 0
AS
-- =====================================================================
-- Procedure: HC6.hcportal_queueVersionEmail
-- Description: HC Admin Tools › Version email (E19.F3.S3): records who a
--   send goes to, BEFORE anything is sent. Called by the API's
--   VersionEmail route with the portal's own token. One HC.EmailLog row
--   per eligible person (HC6.VersionEmailAudience — exactly what the page
--   listed), EmailKind 2, Status 0 (queued); the API then claims and sends
--   them in the background. @test = 1 queues nothing and returns the
--   caller's own address, for Send test.
--   Requires an HC.PlatformAdmin row with CanManageNewsflash.
-- Parameters: @deviceId, @accessToken (auth); @sendId (minted by the
--   portal once per press of Send, required); @builds ('|'-delimited);
--   @days; @subject (≤ 250); @test.
-- Returns:
--   rowset 0 — { Success, ErrorMessage }.
--   rowset 1 (on success) — { Queued (rows for this send), NewlyQueued
--     (0 on a repeat), Email, FirstName, HashName, Name } — the last four
--     are the CALLER's, for a test.
-- Author: Harrier Central
-- Created: 2026-10-17
-- HC5 Source: none (new)
-- Breaking Changes: none (new)
-- Idempotency: client-id — @sendId is minted by the portal per press of
--   Send; a repeat finds the send's rows (UQ_EmailLog_Send_User) and
--   queues nothing new. An app lock serialises sends, so two different
--   sends at once cannot both pass the 30-day rule for one person.
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
SET @subject = LTRIM(RTRIM(ISNULL(@subject, '')));
IF (@test = 0 AND @sendId IS NULL)
BEGIN
    SELECT 0 AS Success, 'Missing send id' AS ErrorMessage;
    RETURN;
END
IF (LEN(@subject) = 0 OR LEN(@subject) > 250)
BEGIN
    SELECT 0 AS Success, 'The subject must be 1 to 250 characters' AS ErrorMessage;
    RETURN;
END

DECLARE @queued INT = 0, @new INT = 0;
BEGIN TRY
    IF (@test = 0)
    BEGIN
        BEGIN TRANSACTION;
        EXEC sp_getapplock @Resource = 'HC.VersionEmailQueue', @LockMode = 'Exclusive',
                           @LockOwner = 'Transaction', @LockTimeout = 30000;
        IF NOT EXISTS (SELECT 1 FROM HC.EmailLog WITH (UPDLOCK, HOLDLOCK) WHERE SendId = @sendId)
        BEGIN
            INSERT HC.EmailLog (id, EmailTemplaterId, EventId, DateSent, NumberSent, ServerReply,
                                SendId, UserId, EmailKind, Status, Subject, SentByUserId)
            SELECT NEWID(), NULL, NULL, SYSDATETIMEOFFSET(), 1, NULL,
                   @sendId, a.userId, 2, 0, LEFT(@subject, 250), @callerId
            FROM HC6.VersionEmailAudience(ISNULL(@builds, ''), @days) a
            WHERE a.eligible = 1;
            SET @new = @@ROWCOUNT;
        END
        SELECT @queued = COUNT(*) FROM HC.EmailLog WHERE SendId = @sendId;
        COMMIT TRANSACTION;
    END

    SELECT 1 AS Success, NULL AS ErrorMessage;
    SELECT @queued AS Queued, @new AS NewlyQueued,
           h.Email, COALESCE(NULLIF(LTRIM(RTRIM(h.FirstName)), ''), NULLIF(LTRIM(RTRIM(h.HashName)), ''), '') AS FirstName,
           COALESCE(NULLIF(LTRIM(RTRIM(h.HashName)), ''), NULLIF(LTRIM(RTRIM(h.FirstName)), ''), '') AS HashName,
           h.DisplayName AS Name
    FROM HC.Hasher h WHERE h.id = @callerId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_queueVersionEmail',
            ERROR_MESSAGE(), @procName, @callerId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
