CREATE OR ALTER PROCEDURE [HC6].[nonApi_getTrackImportJob]
    @jobId    UNIQUEIDENTIFIER = NULL,
    @hasherId UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.nonApi_getTrackImportJob
-- Description: One track import job as hcapp_getTrackImports returns it,
--   for the API's ProcessTrackImport to send back AFTER a slice of work.
--   That call authenticates once, at its start (hcapp_getTrackImports);
--   re-reading through hcapp_getTrackImports with the same token after a
--   slice of up to 40 s found the token too old ("Invalid access token",
--   Inspector Gorse 2026-10-15/16), and the phone parsed the error envelope
--   as a job ("Null is not a subtype of String"). Internal (API only).
-- Parameters: @jobId; @hasherId (the job's owner, from the authenticated
--   first read — scopes the row exactly as hcapp_getTrackImports does).
-- Returns: rowset 0 — the job row (same columns as hcapp_getTrackImports
--   with @jobId), or no row.
-- Author: Harrier Central
-- Created: 2026-10-17
-- HC5 Source: none (new)
-- Breaking Changes: none (new)
-- Idempotency: read-only — reads only
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    SELECT t.id AS jobId, t.HasherId AS hasherId, t.FileName AS fileName, t.BlobUrl AS blobUrl,
           t.ByteSize AS byteSize, t.Kind AS kind, t.Status AS status,
           t.UploadedAt AS uploadedAt, t.StartedAt AS startedAt, t.ProcessedAt AS processedAt,
           t.NextIndex AS nextIndex, t.ActivityCount AS activityCount,
           t.ImportedCount AS importedCount, t.SkippedCount AS skippedCount, t.HeldCount AS heldCount,
           t.ErrorMessage AS errorMessage, t.ResultJson AS resultJson
    FROM HC.TrackImport t
    WHERE t.id = @jobId AND t.HasherId = @hasherId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Unhandled error in nonApi_getTrackImportJob', ERROR_MESSAGE(), @procName, @hasherId);
    THROW;
END CATCH
GO
