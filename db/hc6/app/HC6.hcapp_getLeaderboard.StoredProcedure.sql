CREATE OR ALTER PROCEDURE [HC6].[hcapp_getLeaderboard]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @kennelId    UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getLeaderboard
-- Description: Returns run/haring counts per hasher per kennel for
--   display in the leaderboard. Scoped to a single kennel when
--   @kennelId is provided, or across all kennels when NULL.
--   Limited to hashers who ran at least once in the past 12 months.
--   Excludes placeholder users and anonymous hashers.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @kennelId    - Optional kennel filter; NULL = all kennels
-- Returns:
--   Read SP (no success envelope).
--   On success (rowset 0): { displayName, totalRunCount, totalHaringCount,
--     ytdTotalRunCount, ytdHaringCount, rollingYearTotalRunCount,
--     rollingYearHaringCount, kennelId, homeKennelId, hasherId }
--   On error (rowset 0): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_getLeaderboard
-- Breaking Changes:
--   Single-letter column aliases (a–j) replaced with descriptive names
--     (app is being rewritten and single-letter aliases are opaque).
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
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
    @spNumber     = 90,
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
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

-- Only include users who ran at least once in the last 12 months
;WITH ActiveUsers AS (
    SELECT hkm.UserId
    FROM HC.HasherKennelMap hkm
    GROUP BY hkm.UserId
    HAVING MAX(hkm.DateOfLastRun) > DATEADD(YEAR, -1, GETDATE())
)
SELECT
    h.DisplayName                                                           AS displayName,
    COALESCE(hkm.HcTotalRunCount, 0)   + COALESCE(hkm.HistoricalTotalRunCount, 0) AS totalRunCount,
    COALESCE(hkm.HcHaringCount, 0)     + COALESCE(hkm.HistoricalHaringCount, 0)   AS totalHaringCount,
    COALESCE(hkm.YtdTotalRunCount, 0)                                       AS ytdTotalRunCount,
    COALESCE(hkm.YtdHaringCount, 0)                                         AS ytdHaringCount,
    COALESCE(hkm.RollingYearTotalRunCount, 0)                               AS rollingYearTotalRunCount,
    COALESCE(hkm.RollingYearHaringCount, 0)                                 AS rollingYearHaringCount,
    k.id                                                                    AS kennelId,
    h.HomeKennelId                                                          AS homeKennelId,
    hkm.UserId                                                              AS hasherId
FROM HC.HasherKennelMap hkm
INNER JOIN ActiveUsers     au ON au.UserId   = hkm.UserId
INNER JOIN HC.Hasher       h  ON h.id        = hkm.UserId
INNER JOIN HC.Kennel       k  ON k.id        = hkm.KennelId
WHERE (@kennelId IS NULL OR hkm.KennelId = @kennelId)
  AND hkm.DateOfLastRun IS NOT NULL
  AND h.id != k.id
  AND h.DisplayName NOT LIKE 'Placeholder user for%'
  AND h.HashName NOT LIKE N'👣 Anonymous%'
  AND k.ExcludeFromLeaderboard = 0;
