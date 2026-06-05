CREATE OR ALTER PROCEDURE [HC6].[hcapp_findHashersByHashName]

    @accessToken  NVARCHAR(1000),
    @searchTerm   NVARCHAR(250),
    @lat          FLOAT = NULL,
    @lon          FLOAT = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_findHashersByHashName
-- Description: Pre-login account discovery. Searches for active hashers
--   by hash name and returns each matched hasher with their kennel(s)
--   and run counts, so a new user can identify their existing account
--   and request an invite code email.
--   Uses the same global shared token as hcapp_authorizeDevice — no
--   device record is required.
--   Distance filter: if @lat and @lon are provided, only kennels whose
--   home city is within 500 miles (804,672 m) are returned. Pass NULL
--   for both to disable the distance filter.
-- Parameters:
--   @accessToken  - Global shared token (validated against null UUID)
--   @searchTerm   - Hash name or last name to search (min 2 chars)
--   @lat          - Device latitude for distance filter (optional)
--   @lon          - Device longitude for distance filter (optional)
-- Returns:
--   Rowset 0: success envelope { success, errorCode, errorType }
--   Rowset 1 (success): { publicHasherId, displayName, hashName, photo,
--                          kennelId, kennelName, runCount } — one row
--                        per hasher+kennel; empty set if no matches
--   Rowset 1 (error): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-06-04
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName   NVARCHAR(128)    = OBJECT_NAME(@@PROCID);
DECLARE @errorId    UNIQUEIDENTIFIER;
DECLARE @errorCode  INT;
DECLARE @errorType  INT;
DECLARE @nullUserId UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000';

-- Global shared token — same mechanism as hcapp_authorizeDevice
IF HC.CHECK_ACCESS_TOKEN_V2(@nullUserId, @procName,
                            COALESCE(@accessToken, 'error'), NULL, 30) = 0
BEGIN
    SET @errorCode = 1312; SET @errorType = 11; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Invalid access token',
            'Global access token failed validation', @procName, @nullUserId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Invalid access token' AS errorTitle,
           'The access token is invalid. Please reinstall the app.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

IF (LEN(COALESCE(@searchTerm, '')) < 2)
BEGIN
    SET @errorCode = 1313; SET @errorType = 2; SET @errorId = NEWID();
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Search term too short' AS errorTitle,
           'Please enter at least 2 characters to search.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Build geography point for optional 500-mile distance filter.
-- STDistance returns metres for WGS84 (SRID 4326); 500 miles = 804,672 m.
DECLARE @searchPoint GEOGRAPHY = NULL;
IF (@lat IS NOT NULL AND @lon IS NOT NULL)
    SET @searchPoint = geography::Point(@lat, @lon, 4326);

SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

SELECT
    LOWER(CAST(h.PublicHasherId AS NVARCHAR(40))) AS publicHasherId,
    h.DisplayName                                  AS displayName,
    COALESCE(h.HashName, '')                       AS hashName,
    COALESCE(h.Photo, '')                          AS photo,
    LOWER(CAST(k.id AS NVARCHAR(40)))              AS kennelId,
    k.KennelName                                   AS kennelName,
    hkm.HcTotalRunCount                            AS runCount
FROM HC.Hasher h
INNER JOIN HC.HasherKennelMap hkm ON hkm.UserId   = h.id
INNER JOIN HC.Kennel k             ON k.id         = hkm.KennelId
INNER JOIN HC.City c               ON c.id         = k.CityId
WHERE h.Removed             = 0
  AND hkm.HcTotalRunCount   > 0
  AND (
       h.HashName    LIKE '%' + @searchTerm + '%'
    OR h.LastName    LIKE '%' + @searchTerm + '%'
  )
  AND (
       @searchPoint IS NULL
    OR c.CityGeolocation IS NULL
    OR c.CityGeolocation.STDistance(@searchPoint) <= 804672
  )
ORDER BY h.PublicHasherId, hkm.HcTotalRunCount DESC;
