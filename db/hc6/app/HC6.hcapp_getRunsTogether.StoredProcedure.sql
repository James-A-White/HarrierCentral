CREATE OR ALTER PROCEDURE [HC6].[hcapp_getRunsTogether]
    @deviceId             UNIQUEIDENTIFIER = NULL,
    @accessToken          NVARCHAR(1000)   = NULL,
    @otherPublicHasherId  UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getRunsTogether
-- Description: The hasher page (E10.F1.S5, shared with E9.F1.S26's search
--   results): who they are, a summary, and every run the caller and they
--   both attended (the HC6.CoRunners rule), newest first. Only runs the
--   CALLER attended can appear, so nothing here is new to them. The runs
--   come with what a row needs to be drawn, so the page does not depend on
--   which old runs the phone still holds.
-- Parameters: @otherPublicHasherId — the other hasher's PUBLIC id.
-- Returns: rowset 0 — standard success envelope;
--   rowset 1 — { PublicHasherId, DisplayName, Photo, HomeKennelName,
--     HomeKennelShortName, HomeKennelLogo, RunsTogether, HaredTogether,
--     FirstTogether, LastTogether }  (First/Last = EventStartLocalDate,
--     the run's own calendar date);
--   rowset 2 — { EventId, PublicEventId, EventNumber, EventName,
--     EventStartLocal, KennelShortName, KennelLogo, MeHare, ThemHare,
--     MyRunNumber, MyHareNumber, TrackRunnerCount, PhotoCount,
--     MessageCount, DownDownCount }  (the last six appended 2026-10-02)
--     (EventStartLocal = the run's local wall-clock start)
-- Author: Harrier Central
-- Created: 2026-10-02
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 145, @param = NULL,
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

DECLARE @otherId UNIQUEIDENTIFIER =
    (SELECT h.id FROM HC.Hasher h
     WHERE h.PublicHasherId = @otherPublicHasherId AND h.deleted = 0 AND ISNULL(h.Removed, 0) = 0);

IF (@otherId IS NULL OR @otherId = @userId)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Hasher not found',
            CONCAT('other=', COALESCE(CAST(@otherPublicHasherId AS NVARCHAR(40)), 'null')), @procName, @userId);
    SELECT 0 AS success, 14500 AS errorCode, 3 AS errorType;
    SELECT @errorId AS errorId, 3 AS errorType, 14500 AS errorCode,
           'Not found' AS errorTitle, 'That hasher could not be found.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    -- The same rule as HC6.CoRunners, per run rather than counted.
    -- MyRunNumber / MyHareNumber: "My FILTH run #115 and #63 time haring",
    -- the same sum the kennel run history shows — the running count at this
    -- run plus the pre-app historical count at that kennel.
    CREATE TABLE #runs (EventId UNIQUEIDENTIFIER PRIMARY KEY, MeHare SMALLINT, ThemHare SMALLINT,
                        MyRunNumber INT, MyHareNumber INT);
    INSERT #runs
    SELECT m.EventId,
           CASE WHEN ISNULL(m.IsHare, 0) <> 0 THEN 1 ELSE 0 END,
           CASE WHEN ISNULL(o.IsHare, 0) <> 0 THEN 1 ELSE 0 END,
           ISNULL(m.TotalRunsThisKennel, 0)   + ISNULL(hkm.HistoricalTotalRunCount, 0),
           ISNULL(m.TotalHaringThisKennel, 0) + ISNULL(hkm.HistoricalHaringCount, 0)
    FROM HC.HasherEventMap m
    JOIN HC.HasherEventMap o
      ON o.EventId = m.EventId AND o.UserId = @otherId
     AND o.AttendenceState >= 20 AND ISNULL(o.removed, 0) = 0
    JOIN HC.Event e
      ON e.id = m.EventId AND e.deleted = 0 AND ISNULL(e.removed, 0) = 0 AND e.IsVisible = 1
    OUTER APPLY (SELECT TOP (1) k.HistoricalTotalRunCount, k.HistoricalHaringCount
                 FROM HC.HasherKennelMap k
                 WHERE k.UserId = @userId AND k.KennelId = e.KennelId) hkm
    WHERE m.UserId = @userId AND m.AttendenceState >= 20 AND ISNULL(m.removed, 0) = 0;

    SELECT 1 AS success, NULL AS errorMessage;

    SELECT UPPER(CAST(h.PublicHasherId AS NVARCHAR(40))) AS PublicHasherId,
           h.DisplayName, h.Photo,
           k.KennelName      AS HomeKennelName,
           k.KennelShortName AS HomeKennelShortName,
           k.KennelLogo      AS HomeKennelLogo,
           (SELECT COUNT(*) FROM #runs)                                   AS RunsTogether,
           (SELECT COUNT(*) FROM #runs WHERE MeHare = 1 AND ThemHare = 1) AS HaredTogether,
           (SELECT MIN(e.EventStartLocalDate) FROM #runs r JOIN HC.Event e ON e.id = r.EventId) AS FirstTogether,
           (SELECT MAX(e.EventStartLocalDate) FROM #runs r JOIN HC.Event e ON e.id = r.EventId) AS LastTogether
    FROM HC.Hasher h
    LEFT JOIN HC.Kennel k ON k.id = h.HomeKennelId AND k.deleted = 0
    WHERE h.id = @otherId;

    SELECT LOWER(CAST(e.id AS NVARCHAR(40)))            AS EventId,
           LOWER(CAST(e.PublicEventId AS NVARCHAR(40))) AS PublicEventId,
           e.EventNumber, e.EventName, e.EventStartLocal,
           k.KennelShortName, k.KennelLogo,
           r.MeHare, r.ThemHare,
           r.MyRunNumber, r.MyHareNumber,
           -- The past-run card's activity icons (HC.Event's counts, kept
           -- by HC6.nonApi_refreshEventActivity), so the rows match.
           ISNULL(e.TrackRunnerCount, 0) AS TrackRunnerCount,
           ISNULL(e.PhotoCount, 0)       AS PhotoCount,
           ISNULL(e.MessageCount, 0)     AS MessageCount,
           ISNULL(e.DownDownCount, 0)    AS DownDownCount
    FROM #runs r
    JOIN HC.Event e ON e.id = r.EventId
    LEFT JOIN HC.Kennel k ON k.id = e.KennelId
    ORDER BY e.EventStartDatetimeGmt DESC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in getRunsTogether', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 14501 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 14501 AS errorCode,
           'Something went wrong' AS errorTitle, 'The runs could not be loaded. Please try again.' AS errorUserMessage, @procName AS errorProc;
END CATCH
GO
