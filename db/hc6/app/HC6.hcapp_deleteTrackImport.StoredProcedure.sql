CREATE OR ALTER PROCEDURE [HC6].[hcapp_deleteTrackImport]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @jobId       UNIQUEIDENTIFIER
AS
-- =====================================================================
-- Procedure: HC6.hcapp_deleteTrackImport
-- Description: Clears one of the caller's own uploads off their Import
--   Tracks list (E5.F5.S8). The row is stamped DeletedAt, not removed: it
--   holds the BlobUrl and the archives are kept on purpose for historic-run
--   discovery, so a hard DELETE would orphan the blob. A job that is still
--   processing is refused — the slice loop and the nightly backstop both
--   read the row. Tracks already imported from it are NOT touched: they
--   belong to the runs now, not to the upload.
-- Parameters: @jobId — the upload to clear. Must belong to the caller.
-- Returns: rowset 0 — success envelope only. Rowset 1 — {jobId}.
-- Author: Harrier Central
-- Created: 2026-09-12
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName   NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId    UNIQUEIDENTIFIER;
DECLARE @errorCode  INT;
DECLARE @errorType  INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);
DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 101,
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

-- Pre-flight, before any transaction: nothing to roll back, nothing to
-- get wrong about the order of the rollback and the log.
DECLARE @status SMALLINT;
SELECT @status = Status
  FROM HC.TrackImport
 WHERE id = @jobId AND HasherId = @userId AND DeletedAt IS NULL;

IF (@status IS NULL)
BEGIN
    SET @errorCode = 1011; SET @errorType = 3; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Upload not found',
            CONCAT('jobId ', CONVERT(NVARCHAR(36), @jobId), ' is not this hasher''s, or is already cleared.'),
            @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Upload not found' AS errorTitle,
           'That upload is no longer in your list.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

IF (@status = 1)
BEGIN
    SET @errorCode = 1012; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Upload still processing',
            CONCAT('jobId ', CONVERT(NVARCHAR(36), @jobId), ' is mid-import.'), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Still importing' AS errorTitle,
           'This upload is still being imported. Wait for it to finish, then clear it.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE HC.TrackImport
       SET DeletedAt = SYSUTCDATETIME()
     WHERE id = @jobId AND HasherId = @userId AND DeletedAt IS NULL;
    COMMIT TRANSACTION;
    SELECT 1 AS success;
    SELECT @jobId AS jobId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorCode = 1013; SET @errorType = 5; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_deleteTrackImport',
            ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END CATCH
GO
