-- =====================================================================
-- Procedure: HC6.publicWeb_getLeaderboard
-- Description: The app's "Get a Life (Leaderboards)" for one kennel, for a
--   web member (E9.F7.S12): the same rows hcapp_getLeaderboard returns —
--   hashers active in the last year with their total, this-year and
--   rolling-year run and haring counts — plus the home kennel's short name
--   for the app's "Show Kennels" checkbox. Mirrors hcapp_getLeaderboard;
--   the query is copied, not re-derived, so the two screens agree.
-- Parameters: @publicKennelId — the kennel
-- Returns: rowset 0 envelope; rowset 1 leaderboard rows
-- Author: Harrier Central
-- Created: 2026-09-17
-- HC5 Source: HC6.hcapp_getLeaderboard
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getLeaderboard]
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
    @spNumber = 115, @param = NULL,
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
    DECLARE @kennelId UNIQUEIDENTIFIER;
    SELECT @kennelId = k.id FROM HC.Kennel k
    WHERE k.PublicKennelId = @publicKennelId AND k.deleted = 0 AND k.removed = 0;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    ;WITH ActiveUsers AS (
        SELECT hkm.UserId
        FROM HC.HasherKennelMap hkm
        GROUP BY hkm.UserId
        HAVING MAX(hkm.DateOfLastRun) > DATEADD(YEAR, -1, GETDATE())
    )
    SELECT
        h.DisplayName                                                                 AS displayName,
        COALESCE(hkm.HcTotalRunCount, 0) + COALESCE(hkm.HistoricalTotalRunCount, 0) AS totalRunCount,
        COALESCE(hkm.HcHaringCount, 0)   + COALESCE(hkm.HistoricalHaringCount, 0)   AS totalHaringCount,
        COALESCE(hkm.YtdTotalRunCount, 0)                                             AS ytdTotalRunCount,
        COALESCE(hkm.YtdHaringCount, 0)                                               AS ytdHaringCount,
        COALESCE(hkm.RollingYearTotalRunCount, 0)                                     AS rollingYearTotalRunCount,
        COALESCE(hkm.RollingYearHaringCount, 0)                                       AS rollingYearHaringCount,
        CASE WHEN h.HomeKennelId = k.id THEN 1 ELSE 0 END                             AS isHomeKennel,
        hk.KennelShortName                                                            AS homeKennelShortName,
        CASE WHEN hkm.UserId = @userId THEN 1 ELSE 0 END                              AS isMe
    FROM HC.HasherKennelMap hkm
    INNER JOIN ActiveUsers     au ON au.UserId   = hkm.UserId
    INNER JOIN HC.Hasher       h  ON h.id        = hkm.UserId
    INNER JOIN HC.Kennel       k  ON k.id        = hkm.KennelId
    LEFT  JOIN HC.Kennel       hk ON hk.id       = h.HomeKennelId
    WHERE hkm.KennelId = @kennelId
      AND hkm.DateOfLastRun IS NOT NULL
      AND h.id != k.id
      AND h.DisplayName NOT LIKE 'Placeholder user for%'
      AND h.HashName NOT LIKE N'👣 Anonymous%'
      AND k.ExcludeFromLeaderboard = 0
    ORDER BY totalRunCount DESC, h.DisplayName;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getLeaderboard', ERROR_MESSAGE(), @procName, @userId, @deviceId);
    THROW;
END CATCH
GO
