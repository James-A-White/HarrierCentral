-- =====================================================================
-- Procedure: HC6.publicWeb_getKennelArt
-- Description: The app's "Run art gallery" for one kennel, for a web
--   member (E9.F7.S12): every run of the kennel that has an event image,
--   newest first — what QueryKennels.queryKennelGallery reads from the
--   phone's synced events.
-- Parameters: @publicKennelId — the kennel
-- Returns: rowset 0 envelope; rowset 1 one row per run with an image
-- Author: Harrier Central
-- Created: 2026-09-17
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getKennelArt]
    @deviceId       UNIQUEIDENTIFIER,
    @accessToken    NVARCHAR(1000),
    @publicKennelId UNIQUEIDENTIFIER
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;
DECLARE @errorCode INT, @errorType INT, @errorId UNIQUEIDENTIFIER;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 116, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT, @timeWindow = @timeWindow OUTPUT,
    @errorCode = @errorCode OUTPUT, @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;
IF (@errorCode IS NOT NULL)
BEGIN
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    SELECT
        e.PublicEventId,
        e.EventNumber,
        e.EventName,
        e.EventImage,
        CAST(e.EventStartDatetime AS datetime2(7))  AS EventStartDatetime,
        e.EventStartDatetimeGmt,
        k.KennelUniqueShortName                     AS KennelSlug
    FROM HC.Event e
    INNER JOIN HC.Kennel k ON k.id = e.KennelId
    WHERE k.PublicKennelId = @publicKennelId
      AND e.IsVisible = 1 AND e.deleted = 0 AND e.removed = 0
      AND e.EventImage IS NOT NULL AND LEN(e.EventImage) > 0
    ORDER BY e.EventStartDatetimeGmt DESC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getKennelArt', ERROR_MESSAGE(), @procName, @userId, @deviceId);
    THROW;
END CATCH
GO
