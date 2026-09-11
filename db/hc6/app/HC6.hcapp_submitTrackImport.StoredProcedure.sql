CREATE OR ALTER PROCEDURE [HC6].[hcapp_submitTrackImport]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @jobId       UNIQUEIDENTIFIER,
    @blobUrl     NVARCHAR(1000),
    @fileName    NVARCHAR(250) = NULL,
    @byteSize    BIGINT        = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_submitTrackImport
-- Description: A hasher has uploaded a track file (GPX/TCX/FIT or a whole
--   Strava/Garmin zip) to blob storage and asks for it to be imported as
--   their PackTrack trails (E5.F5.S7). Creates the HC.TrackImport job row;
--   the ProcessTrackImport function does the work in slices the app drives,
--   with a timer backstop. @jobId is minted by GetTrackImportUploadToken so
--   the blob name and the job agree; resubmitting the same id is a no-op.
-- Parameters: @jobId, @blobUrl (the blob just uploaded), @fileName, @byteSize.
-- Returns: rowset 0 — success envelope; rowset 1 — the job id.
-- Author: Harrier Central
-- Created: 2026-09-11
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

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
    @spNumber     = 96,
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

IF (@jobId IS NULL OR @jobId = '00000000-0000-0000-0000-000000000000' OR LEN(ISNULL(@blobUrl, '')) = 0)
BEGIN
    SET @errorCode = 1296; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Missing jobId or blobUrl',
            'hcapp_submitTrackImport needs @jobId and @blobUrl', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing parameter' AS errorTitle,
           'The upload could not be registered. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;
    IF NOT EXISTS (SELECT 1 FROM HC.TrackImport WITH (UPDLOCK, HOLDLOCK) WHERE id = @jobId)
    BEGIN
        INSERT INTO HC.TrackImport (id, HasherId, FileName, BlobUrl, ByteSize)
        VALUES (@jobId, @userId, LEFT(@fileName, 250), @blobUrl, @byteSize);
    END
    COMMIT TRANSACTION;
    SELECT 1 AS success;
    SELECT @jobId AS jobId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorCode = 1996; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END CATCH
GO
