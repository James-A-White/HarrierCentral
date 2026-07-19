CREATE OR ALTER PROCEDURE [HC6].[hcapp_getMyKennelRunTotals]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @kennelId    UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getMyKennelRunTotals
-- Description: Returns the calling user's run and haring totals per
--   kennel. An optional @kennelId filters to a single kennel. A
--   synthetic GRAND TOTAL row (kennelId = null UUID) is appended with
--   the sum across all kennels, allowing the app to display overall
--   and per-kennel totals from one response.
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @kennelId    - Optional kennel filter; NULL = all kennels
-- Returns:
--   Read SP (no success envelope).
--   On success (rowset 0): { KennelId, KennelLogo, KennelName,
--     totalRunsThisKennel, totalPackRunsThisKennel,
--     totalHaringThisKennel, following, KennelShortName }
--     ordered by totalRunsThisKennel DESC, grand total row first (rowNum=0)
--   On error (rowset 0): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_getMyKennelRunTotals
-- Breaking Changes:
--   @kennelId default changed from '00000000-...' to NULL.
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

IF (@kennelId = '00000000-0000-0000-0000-000000000000') SET @kennelId = NULL;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 91,
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

BEGIN TRY

;WITH cte AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY COUNT(CASE WHEN hem.AttendenceState >= 20 THEN 1 END) DESC) AS rowNum,
        evt.KennelId,
        k.KennelLogo,
        k.KennelName,
        COUNT(CASE WHEN hem.AttendenceState >= 20 THEN 1 END)                AS totalRunsThisKennel,
        COUNT(CASE WHEN hem.AttendenceState >= 20 THEN 1 END)
            - COUNT(CASE WHEN hem.IsHare != 0 THEN 1 END)                    AS totalPackRunsThisKennel,
        COUNT(CASE WHEN hem.IsHare != 0 THEN 1 END)                          AS totalHaringThisKennel,
        COALESCE(hkm.Following, 0)                                           AS following,
        k.KennelShortName
    FROM HC.HasherEventMap hem
    INNER JOIN HC.Event evt ON hem.EventId = evt.id
    INNER JOIN HC.Kennel k  ON evt.KennelId = k.id
    LEFT OUTER JOIN HC.HasherKennelMap hkm ON hkm.UserId = @userId AND hkm.KennelId = k.id
    WHERE hem.UserId = @userId
      AND (@kennelId IS NULL OR k.id = @kennelId)
      AND evt.IsCountedRun = 1
      AND evt.IsVisible    = 1
    GROUP BY evt.KennelId, k.KennelLogo, k.KennelName, k.KennelShortName, COALESCE(hkm.Following, 0)
)
SELECT *
INTO #temp
FROM cte
WHERE totalRunsThisKennel > 0;

-- Grand total row
INSERT #temp (rowNum, KennelId, KennelLogo, KennelName,
              totalRunsThisKennel, totalPackRunsThisKennel, totalHaringThisKennel,
              following, KennelShortName)
SELECT
    0,
    '00000000-0000-0000-0000-000000000000',
    '<no logo>',
    'GRAND TOTAL ALL KENNELS',
    SUM(totalRunsThisKennel),
    SUM(totalPackRunsThisKennel),
    SUM(totalHaringThisKennel),
    0,
    'TOTALS'
FROM #temp;

SELECT
    KennelId,
    KennelLogo,
    KennelName,
    totalRunsThisKennel,
    totalPackRunsThisKennel,
    totalHaringThisKennel,
    following,
    KennelShortName
FROM #temp
ORDER BY rowNum;

DROP TABLE #temp;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in getMyKennelRunTotals',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
