CREATE OR ALTER PROCEDURE [HC6].[hcapp_getTrackImports]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @jobId       UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getTrackImports
-- Description: A hasher's track-import jobs (E5.F5.S7). With @jobId, that
--   one job in full (result JSON and blob URL included) — only if it is
--   theirs; without, their latest 20 without the JSON. The app polls the
--   single form while a job is processing to show results as they land.
-- Returns: rowset 0 — jobs (see contract).
-- Author: Harrier Central
-- Created: 2026-09-11
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;

DECLARE @procName  NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId   UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);
DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 97,
    @param        = NULL,
    @userId       = @userId       OUTPUT,
    @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow   = @timeWindow   OUTPUT,
    @errorCode    = @errorCode    OUTPUT,
    @errorType    = @errorType    OUTPUT,
    @errorId      = @errorId      OUTPUT,
    @errorTitle   = @errorTitle   OUTPUT,
    @errorMsg     = @errorMsg     OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    IF (@jobId IS NOT NULL)
        SELECT t.id AS jobId, t.HasherId AS hasherId, t.FileName AS fileName, t.BlobUrl AS blobUrl,
               t.ByteSize AS byteSize, t.Kind AS kind, t.Status AS status,
               t.UploadedAt AS uploadedAt, t.StartedAt AS startedAt, t.ProcessedAt AS processedAt,
               t.NextIndex AS nextIndex, t.ActivityCount AS activityCount,
               t.ImportedCount AS importedCount, t.SkippedCount AS skippedCount, t.HeldCount AS heldCount,
               t.ErrorMessage AS errorMessage, t.ResultJson AS resultJson
        FROM HC.TrackImport t
        WHERE t.id = @jobId AND t.HasherId = @userId;
    ELSE
        SELECT TOP (20)
               t.id AS jobId, t.HasherId AS hasherId, t.FileName AS fileName, NULL AS blobUrl,
               t.ByteSize AS byteSize, t.Kind AS kind, t.Status AS status,
               t.UploadedAt AS uploadedAt, t.StartedAt AS startedAt, t.ProcessedAt AS processedAt,
               t.NextIndex AS nextIndex, t.ActivityCount AS activityCount,
               t.ImportedCount AS importedCount, t.SkippedCount AS skippedCount, t.HeldCount AS heldCount,
               t.ErrorMessage AS errorMessage, NULL AS resultJson
        FROM HC.TrackImport t
        WHERE t.HasherId = @userId
        ORDER BY t.UploadedAt DESC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_getTrackImports',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
