CREATE OR ALTER PROCEDURE [HC6].[hcapp_setOfficialTrail]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @eventId     UNIQUEIDENTIFIER = NULL,
    @trailType   SMALLINT         = NULL,   -- 1 Walkers, 2 Short, 3 Normal, 4 Long, 5 Ballbreaker, >= 100 kennel's own
    @points      NVARCHAR(MAX)    = NULL,   -- JSON [[lat,lon,t?],...]; NULL or '' removes this lane
    @distanceM   INT              = NULL,
    @source      NVARCHAR(20)     = NULL,   -- 'scout' | 'promote' | 'file'
    @sourceRef   NVARCHAR(500)    = NULL    -- the promoted runner's public id, or the file name
AS
-- =====================================================================
-- Procedure: HC6.hcapp_setOfficialTrail
-- Description: Sets (or removes) ONE trail-type lane of a run's official
--   trail (E5.F6.S6, James 2026-10-03): a scout's pre-run, a runner's track
--   promoted from the PackTrack map, or an uploaded GPX/TCX/FIT file. Other
--   lanes are kept. Only the run's hares and kennel admins (createEditRuns,
--   hare-scoped — the same gate as editing the run).
--   Points: [lat, lon] or [lat, lon, t], t = ms after the lane's first
--   point (replay aligns that first point to the first pack track's start).
--   A trail-only UPDATE: HC.trgUpdateModifiedOnDateForEvent does not stamp
--   it, so no phone re-downloads the run. Every change is logged.
-- Returns: rowset 0 — standard success envelope; rowset 1 — { OfficialTrailInfo }
--   Errors: 14700 not allowed (13), 14701 bad trail (2), 14702 unhandled (5).
-- Author: Harrier Central
-- Created: 2026-10-03
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 148, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow = @timeWindow OUTPUT, @errorCode = @errorCode OUTPUT,
    @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

DECLARE @kennelId UNIQUEIDENTIFIER = (SELECT KennelId FROM HC.Event WHERE id = @eventId AND deleted = 0);
DECLARE @isHare SMALLINT = CASE WHEN EXISTS (
    SELECT 1 FROM HC.HasherEventMap h
    WHERE h.EventId = @eventId AND h.UserId = @userId AND ISNULL(h.IsHare, 0) <> 0
      AND ISNULL(h.removed, 0) = 0) THEN 1 ELSE 0 END;
DECLARE @allowed SMALLINT = 0;
IF (@kennelId IS NOT NULL)
    EXEC HC6.CheckKennelPermission @userId = @userId, @kennelId = @kennelId,
         @functionKey = 'createEditRuns', @isHareOfEvent = @isHare, @allowed = @allowed OUTPUT;

IF (@allowed = 0)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not allowed to set the official trail',
            CONCAT('event=', COALESCE(CAST(@eventId AS NVARCHAR(40)), 'null')), @procName, @userId);
    SELECT 0 AS success, 14700 AS errorCode, 13 AS errorType;
    SELECT @errorId AS errorId, 13 AS errorType, 14700 AS errorCode, 'Not allowed' AS errorTitle,
           'Only this run''s hares and kennel admins can set its official trail.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

DECLARE @remove BIT = CASE WHEN @points IS NULL OR LEN(@points) = 0 THEN 1 ELSE 0 END;
DECLARE @pointCount INT = 0;
IF (@remove = 0 AND ISJSON(@points) = 1 AND LEFT(LTRIM(@points), 1) = '[')
    SELECT @pointCount = COUNT(*) FROM OPENJSON(@points);

IF (@trailType IS NULL OR @trailType < 1
    OR (@remove = 0 AND (@pointCount < 2 OR LEN(@points) > 4000000)))
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Bad official trail',
            CONCAT('type=', @trailType, ' points=', @pointCount, ' len=', LEN(@points)), @procName, @userId);
    SELECT 0 AS success, 14701 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 14701 AS errorCode, 'Not a trail' AS errorTitle,
           'That trail could not be saved: it needs at least two points.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @gzip VARBINARY(MAX), @infoOld NVARCHAR(MAX);
    SELECT @gzip = OfficialTrailGzip, @infoOld = OfficialTrailInfo
    FROM HC.Event WITH (UPDLOCK, HOLDLOCK) WHERE id = @eventId;
    DECLARE @lanesOld NVARCHAR(MAX) = CAST(DECOMPRESS(@gzip) AS NVARCHAR(MAX));

    -- Every other lane, kept as it is; then this one (unless removed).
    DECLARE @lanes TABLE (seq INT IDENTITY(1,1), v NVARCHAR(MAX));
    IF (ISJSON(@lanesOld) = 1)
        INSERT @lanes (v) SELECT [value] FROM OPENJSON(@lanesOld, '$.lanes')
        WHERE TRY_CAST(JSON_VALUE([value], '$.type') AS INT) <> @trailType;
    IF (@remove = 0)
        INSERT @lanes (v) VALUES (CONCAT(N'{"type":', @trailType, N',"points":', @points, N'}'));

    DECLARE @infos TABLE (seq INT IDENTITY(1,1), v NVARCHAR(MAX));
    IF (ISJSON(@infoOld) = 1)
        INSERT @infos (v) SELECT [value] FROM OPENJSON(@infoOld, '$.lanes')
        WHERE TRY_CAST(JSON_VALUE([value], '$.type') AS INT) <> @trailType;
    IF (@remove = 0)
        INSERT @infos (v)
        SELECT (SELECT @trailType AS [type], @distanceM AS distanceM, @pointCount AS points,
                       @source AS source, @sourceRef AS sourceRef,
                       LOWER(CAST(@userId AS NVARCHAR(40))) AS setBy,
                       FORMAT(SYSUTCDATETIME(), 'yyyy-MM-ddTHH:mm:ssZ') AS setAt
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);

    DECLARE @lanesNew NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), N',') WITHIN GROUP (ORDER BY seq) FROM @lanes);
    DECLARE @infoNew  NVARCHAR(MAX) = (SELECT STRING_AGG(CAST(v AS NVARCHAR(MAX)), N',') WITHIN GROUP (ORDER BY seq) FROM @infos);

    -- Trail columns ONLY: the Event trigger leaves updatedAt alone for this.
    UPDATE HC.Event
       SET OfficialTrailGzip = CASE WHEN @lanesNew IS NULL THEN NULL
                                    ELSE COMPRESS(CONCAT(N'{"lanes":[', @lanesNew, N']}')) END,
           OfficialTrailInfo = CASE WHEN @infoNew IS NULL THEN NULL
                                    ELSE CONCAT(N'{"lanes":[', @infoNew, N']}') END
     WHERE id = @eventId;

    INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp])
    VALUES ('officialTrail', CASE WHEN @remove = 1 THEN 'lane removed' ELSE 'lane set' END,
            CAST(@eventId AS NVARCHAR(40)),
            CONCAT('type=', @trailType, ' points=', @pointCount, ' distanceM=', @distanceM,
                   ' source=', @source, ' ref=', @sourceRef, ' by=', @userId),
            SYSDATETIMEOFFSET());
    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorMessage;
    SELECT OfficialTrailInfo FROM HC.Event WHERE id = @eventId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in setOfficialTrail', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 14702 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 14702 AS errorCode, 'Something went wrong' AS errorTitle,
           'The trail could not be saved. Please try again.' AS errorUserMessage, @procName AS errorProc;
END CATCH
GO
