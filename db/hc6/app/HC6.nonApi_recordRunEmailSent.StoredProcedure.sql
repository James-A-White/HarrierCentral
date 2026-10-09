CREATE OR ALTER PROCEDURE [HC6].[nonApi_recordRunEmailSent]

    @eventId        UNIQUEIDENTIFIER = NULL,
    @userId         UNIQUEIDENTIFIER = NULL,
    @recipientCount  INT              = NULL,
    @instruction     NVARCHAR(500)    = NULL,
    @saveInstruction SMALLINT         = 0

AS
-- =====================================================================
-- Procedure: HC6.nonApi_recordRunEmailSent
-- Description: Records that a run email went out (E9.F6.S8): bumps
--   HC.Event.EmailSendCount, stamps EmailLastSentAt and
--   EmailLastSentCount. Called by the RunEmail API endpoint after the
--   send was handed to the mail service — internal only, no device auth.
--   The UpdatedAt trigger fires, so the run re-syncs to phones.
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
    IF (@eventId IS NULL OR @recipientCount IS NULL)
        THROW 50000, 'eventId and recipientCount are required', 1;

    UPDATE HC.Event
    SET EmailSendCount     = EmailSendCount + 1,
        EmailLastSentAt    = SYSDATETIMEOFFSET(),
        EmailLastSentCount = @recipientCount
    WHERE id = @eventId;

    IF (@saveInstruction = 1)
        UPDATE k SET k.RunEmailInstruction = NULLIF(LTRIM(RTRIM(@instruction)), '')
        FROM HC.Kennel k JOIN HC.Event e ON e.KennelId = k.id
        WHERE e.id = @eventId;

    INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp])
    VALUES ('RunEmail', 'Run email sent', LOWER(CAST(@eventId AS NVARCHAR(40))),
            'sender ' + LOWER(CAST(ISNULL(@userId, '00000000-0000-0000-0000-000000000000') AS NVARCHAR(40)))
            + ', recipients ' + CAST(@recipientCount AS NVARCHAR(10)), SYSDATETIMEOFFSET());

    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId)
    VALUES (NEWID(), '<api>', 'Unhandled error in recordRunEmailSent', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), @userId, @eventId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
