CREATE OR ALTER PROCEDURE [HC6].[nonApi_recordRunEmailSent]

    @eventId        UNIQUEIDENTIFIER = NULL,
    @userId         UNIQUEIDENTIFIER = NULL,
    @recipientCount  INT              = NULL,
    @instruction     NVARCHAR(500)    = NULL,
    @saveInstruction SMALLINT         = 0,
    @kind            NVARCHAR(20)     = 'send',   -- send | preview | announcement
    @subject         NVARCHAR(200)    = NULL,
    @auditPath       NVARCHAR(400)    = NULL,     -- blob path of the audit copy (EmailAudit)
    @movedIn         INT              = 0,
    @movedOut        INT              = 0

AS
-- =====================================================================
-- Procedure: HC6.nonApi_recordRunEmailSent
-- Description: Records that a run email went out (E9.F6.S8): bumps
--   HC.Event.EmailSendCount, stamps EmailLastSentAt and
--   EmailLastSentCount. Called by the RunEmail API endpoint after the
--   send was handed to the mail service — internal only, no device auth.
--   The UpdatedAt trigger fires, so the run re-syncs to phones.
--   Every email also gets a LOG.GeneralLog row (LogSource 'RunEmail',
--   Data = JSON: kind, sender, recipients, subject, audit path, overrides)
--   for the audit trail and the Usage Data "Email" row (James, 2026-10-09).
--   @kind 'preview' and 'announcement' log only — no count on the run.
-- Parameters: @eventId, @userId (the sender, for the log), @recipientCount,
--   @instruction + @saveInstruction = 1: store the drafting instruction on
--   HC.Kennel.RunEmailInstruction as the kennel's default (blank clears it).
-- Returns: { Success, ErrorMessage } envelope.
-- Author: Harrier Central
-- Created: 2026-10-09
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    IF (@recipientCount IS NULL) THROW 50000, 'recipientCount is required', 1;
    IF (@kind = 'send' AND @eventId IS NULL) THROW 50000, 'eventId is required for a send', 1;

    IF (@kind = 'send')
    BEGIN
        UPDATE HC.Event
        SET EmailSendCount     = EmailSendCount + 1,
            EmailLastSentAt    = SYSDATETIMEOFFSET(),
            EmailLastSentCount = @recipientCount
        WHERE id = @eventId;

        IF (@saveInstruction = 1)
            UPDATE k SET k.RunEmailInstruction = NULLIF(LTRIM(RTRIM(@instruction)), '')
            FROM HC.Kennel k JOIN HC.Event e ON e.KennelId = k.id
            WHERE e.id = @eventId;
    END

    INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp])
    VALUES ('RunEmail',
            CASE @kind WHEN 'preview' THEN 'Run email preview' WHEN 'announcement' THEN 'Announcement sent' ELSE 'Run email sent' END,
            LOWER(CAST(@eventId AS NVARCHAR(40))),
            (SELECT @kind AS kind,
                    LOWER(CAST(@userId AS NVARCHAR(40))) AS sender,
                    @recipientCount AS recipients,
                    LEFT(@subject, 200) AS subject,
                    @auditPath AS audit,
                    @movedIn AS movedIn, @movedOut AS movedOut
             FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
            SYSDATETIMEOFFSET());

    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId)
    VALUES (NEWID(), '<api>', 'Unhandled error in recordRunEmailSent', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), @userId, @eventId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
