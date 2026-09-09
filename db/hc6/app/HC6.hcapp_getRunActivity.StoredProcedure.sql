CREATE OR ALTER PROCEDURE [HC6].[hcapp_getRunActivity]
    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @eventIds    NVARCHAR(MAX)
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getRunActivity
-- Description: What a run has to show — for the activity icons on a run
--   card. For each event id in the '|'-delimited @eventIds: whether a
--   PackTrack track exists (HC.EventTrack), how many runners recorded one
--   (HC.EventTrackRunner), how many photos the viewer may see, how many
--   chat messages, how many down-down charges. Read-only,
--   cheap, batched by the app for the cards on screen.
-- Parameters: @deviceId, @accessToken (auth); @eventIds — HC.Event.id
--   values separated by '|', up to a few hundred.
-- Returns: Rowset 0: eventId, hasTrack (0/1), runnerCount, photoCount,
--   messageCount, downDownCount — one row per valid id.
-- Version: 1.1.0 (2026-09-10) — runnerCount added; hasTrack is also 1 when
--   a runner row exists, so the two can never disagree.
-- Author: Harrier Central
-- Created: 2026-09-10
-- HC5 Source: none
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
    @spNumber     = 94,
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
    ;WITH ids AS (
        SELECT DISTINCT TRY_CAST(LTRIM(RTRIM(value)) AS UNIQUEIDENTIFIER) AS eventId
        FROM STRING_SPLIT(ISNULL(@eventIds, ''), '|')
    )
    SELECT
        i.eventId,
        CASE WHEN t.EventId IS NULL AND r.runnerCount IS NULL THEN 0 ELSE 1 END AS hasTrack,
        ISNULL(r.runnerCount, 0) AS runnerCount,
        -- photos the viewer could open: their own at any status, anyone's
        -- at Members or above (the run's own gallery applies the finer
        -- audience rule; this is a "has photos" indicator)
        (SELECT COUNT(*) FROM HC.KennelPhotos kp WITH (NOLOCK)
         WHERE kp.EventId = i.eventId AND kp.DeletedAt IS NULL
           AND (kp.Status >= 2 OR kp.UserId = @userId)) AS photoCount,
        (SELECT COUNT(*) FROM HC.EventMessage m WITH (NOLOCK)
         WHERE m.EventId = i.eventId AND m.Removed = 0) AS messageCount,
        (SELECT COUNT(*) FROM HC.DownDowns d WITH (NOLOCK)
         WHERE d.EventId = i.eventId AND d.IsCancelled = 0) AS downDownCount
    FROM ids i
    LEFT JOIN HC.EventTrack t WITH (NOLOCK) ON t.EventId = i.eventId
    OUTER APPLY (SELECT COUNT(*) AS runnerCount FROM HC.EventTrackRunner tr WITH (NOLOCK)
                 WHERE tr.EventId = i.eventId HAVING COUNT(*) > 0) r
    WHERE i.eventId IS NOT NULL;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_getRunActivity',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
