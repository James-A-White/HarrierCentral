CREATE OR ALTER PROCEDURE [HC6].[nonApi_setTrackNotes]
    @eventId UNIQUEIDENTIFIER,
    @userId  UNIQUEIDENTIFIER,
    @notes   NVARCHAR(4000)
AS
-- =====================================================================
-- Procedure: HC6.nonApi_setTrackNotes
-- Description: Fills a hasher's notes on a run from an imported file's
--   title, description, private note and stats line — when they have none
--   (E3.F4.S5), or when what they have is exactly the start of the new text
--   (2026-09-12: an earlier import's fill being extended by a re-import that
--   now carries the archive's descriptive columns). Called by the
--   track-import processor for every activity that matched a run, whether or
--   not the track itself was imported (a phone-tracked run with a blank note
--   takes the file's words; James, 2026-09-11). A note the hasher wrote, or
--   edited, is never touched: their text is not a prefix of the composed one.
--   Fires the updatedAt trigger, so it syncs.
-- Returns: nothing.
-- Author: Harrier Central
-- Created: 2026-09-11
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @clean NVARCHAR(4000) = NULLIF(LTRIM(RTRIM(@notes)), '');
IF (@clean IS NULL) RETURN;

BEGIN TRY
    UPDATE HC.HasherEventMap
       SET Notes = @clean
     WHERE EventId = @eventId AND UserId = @userId AND removed = 0
       AND (Notes IS NULL OR LTRIM(RTRIM(Notes)) = ''
            OR (LEN(Notes) < LEN(@clean) AND LEFT(@clean, LEN(Notes)) = Notes COLLATE Latin1_General_CS_AS));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_setTrackNotes',
            ERROR_MESSAGE(), @procName, @userId, @eventId);
    THROW;
END CATCH
GO
