CREATE OR ALTER PROCEDURE [HC6].[nonApi_setTrackNotes]
    @eventId UNIQUEIDENTIFIER,
    @userId  UNIQUEIDENTIFIER,
    @notes   NVARCHAR(4000)
AS
-- =====================================================================
-- Procedure: HC6.nonApi_setTrackNotes
-- Description: Fills a hasher's notes on a run from an imported file's
--   title and description — ONLY when they have none (E3.F4.S5). Called
--   by the track-import processor for every activity that matched a run,
--   whether or not the track itself was imported (a phone-tracked run with a
--   blank note takes the file's words; James, 2026-09-11). A note the hasher
--   wrote is never touched. Fires the updatedAt trigger, so it syncs.
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
       AND (Notes IS NULL OR LTRIM(RTRIM(Notes)) = '');
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_setTrackNotes',
            ERROR_MESSAGE(), @procName, @userId, @eventId);
    THROW;
END CATCH
GO
