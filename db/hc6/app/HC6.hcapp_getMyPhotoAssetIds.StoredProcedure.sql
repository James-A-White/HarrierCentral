CREATE OR ALTER PROCEDURE [HC6].[hcapp_getMyPhotoAssetIds]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @kennelId    UNIQUEIDENTIFIER = NULL,
    @eventId     UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getMyPhotoAssetIds
-- Description: The camera-roll asset ids of photos this hasher has already
--   uploaded (E6.F2.S5). The sweep uses it to say "14 eligible, 6 already
--   added" and to stop offering a photo that is already on the run.
--   Scoped to the CALLER's own photos only — an asset id is a handle into
--   somebody's private photo library and belongs to nobody else.
--   One call covers a whole kennel, so the kennel-level view does not make
--   a request per run.
-- Parameters:
--   @kennelId - optional, narrow to one kennel
--   @eventId  - optional, narrow to one run
-- Returns: rowset 0 — { eventId, assetId } per uploaded photo that has one.
-- Author: Harrier Central
-- Created: 2026-09-12
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;

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
    @spNumber     = 102,
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
    SELECT kp.EventId AS eventId,
           kp.AssetId AS assetId
      FROM HC.KennelPhotos kp
     WHERE kp.UserId = @userId
       AND kp.DeletedAt IS NULL
       AND kp.AssetId IS NOT NULL
       AND LEN(kp.AssetId) > 0
       AND (@kennelId IS NULL OR kp.KennelId = @kennelId)
       AND (@eventId  IS NULL OR kp.EventId  = @eventId);
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_getMyPhotoAssetIds',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
