CREATE OR ALTER PROCEDURE [HC6].[nonApi_getPendingTrackImports]
    @staleMinutes INT = 15
AS
-- =====================================================================
-- Procedure: HC6.nonApi_getPendingTrackImports
-- Description: The timer backstop's worklist (E5.F5.S7): import jobs the
--   phone never finished driving — uploaded and never started, or started
--   (a slice claimed it) more than @staleMinutes ago and still not done.
--   Oldest first.
-- Returns: rowset 0 — jobId, hasherId, blobUrl, fileName, cursor, resultJson.
-- Author: Harrier Central
-- Created: 2026-09-11
-- =====================================================================
SET NOCOUNT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);

BEGIN TRY
    SELECT t.id AS jobId, t.HasherId AS hasherId, t.BlobUrl AS blobUrl, t.FileName AS fileName,
           t.NextIndex AS nextIndex, t.ResultJson AS resultJson
    FROM HC.TrackImport t
    WHERE t.Status IN (0, 1)
      AND (t.StartedAt IS NULL OR t.StartedAt < DATEADD(MINUTE, -@staleMinutes, SYSUTCDATETIME()))
    ORDER BY t.UploadedAt ASC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_getPendingTrackImports',
            ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
GO
