CREATE OR ALTER PROCEDURE [HC6].[nonApi_updateTrackImport]
    @id            UNIQUEIDENTIFIER,
    @status        SMALLINT,
    @kind          SMALLINT      = NULL,
    @nextIndex     INT           = NULL,
    @activityCount INT           = NULL,
    @importedCount INT           = NULL,
    @skippedCount  INT           = NULL,
    @heldCount     INT           = NULL,
    @resultJson    NVARCHAR(MAX) = NULL,
    @errorMessage  NVARCHAR(2500) = NULL
AS
-- =====================================================================
-- Procedure: HC6.nonApi_updateTrackImport
-- Description: The import processor's progress write (E5.F5.S7): after
--   each slice, and on completion or failure. NULL leaves a column as it
--   is. Status 1 (processing) stamps StartedAt; 2 (done) and 3 (failed)
--   stamp ProcessedAt. Called by ProcessTrackImport / the nightly backstop.
-- Returns: nothing.
-- Author: Harrier Central
-- Created: 2026-09-11
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);

BEGIN TRY
    UPDATE HC.TrackImport
       SET Status        = @status,
           Kind          = ISNULL(@kind, Kind),
           NextIndex     = ISNULL(@nextIndex, NextIndex),
           ActivityCount = ISNULL(@activityCount, ActivityCount),
           ImportedCount = ISNULL(@importedCount, ImportedCount),
           SkippedCount  = ISNULL(@skippedCount, SkippedCount),
           HeldCount     = ISNULL(@heldCount, HeldCount),
           ResultJson    = ISNULL(@resultJson, ResultJson),
           ErrorMessage  = ISNULL(@errorMessage, ErrorMessage),
           StartedAt     = CASE WHEN @status = 1 THEN SYSUTCDATETIME() ELSE StartedAt END,
           ProcessedAt   = CASE WHEN @status IN (2, 3) THEN SYSUTCDATETIME() ELSE ProcessedAt END
     WHERE id = @id;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_updateTrackImport',
            ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
GO
