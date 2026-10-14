CREATE OR ALTER PROCEDURE [HC6].[nonApi_logBetaCase]
    @event              NVARCHAR(20)     = NULL,
    @reporterPublicId   UNIQUEIDENTIFIER = NULL,
    @lastSequence       INT              = NULL,
    @data               NVARCHAR(MAX)    = NULL
AS
-- =====================================================================
-- Procedure: HC6.nonApi_logBetaCase
-- Description: The cloud Beta Testers assistant's memory (E18.F9.S3,
--   James 2026-10-14). A case is a conversation with one tester; the room's
--   messages ARE the case, so all that has to be remembered is where each
--   tester's case ended, and which messages needed no reply:
--     event 'closed' — the case was closed (proposal emailed to James); the
--                      tester's next message after @lastSequence starts a
--                      new case.
--     event 'seen'   — the assistant read up to @lastSequence and judged no
--                      reply was needed (thanks, chatter), so it is not
--                      asked again.
--   One row in LOG.GeneralLog (LogSource 'beta-room'), no new table
--   (James's rule). Message = event, StrParam1 = the tester's PUBLIC id,
--   Data = 'seq=<n>' plus up to 3,900 characters of the case summary.
--   Called by the API only (BetaRoomAssistant), never by a client.
-- Parameters: @event 'closed' | 'seen'; @reporterPublicId; @lastSequence;
--   @data optional summary (trimmed to fit).
-- Returns: nothing.
-- Author: Harrier Central
-- Created: 2026-10-14
-- Idempotency: log-only — a repeated row says the same thing twice; the
--   reader takes the MAX sequence per tester.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF (@event NOT IN (N'closed', N'seen') OR @reporterPublicId IS NULL OR @lastSequence IS NULL)
    RETURN;
BEGIN TRY
    INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data)
    VALUES (N'beta-room', @event, LOWER(CAST(@reporterPublicId AS NVARCHAR(40))),
            LEFT(N'seq=' + CAST(@lastSequence AS NVARCHAR(12))
                 + CASE WHEN @data IS NULL THEN N'' ELSE N' ' + @data END, 4000));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Unhandled error in nonApi_logBetaCase', ERROR_MESSAGE(),
            OBJECT_NAME(@@PROCID), NULL);
    THROW;
END CATCH
GO
