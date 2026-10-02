CREATE OR ALTER PROCEDURE [HC6].[hcapp_searchHashers]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @query       NVARCHAR(MAX)    = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_searchHashers
-- Description: Hasher search from Chats (E9.F1.S26, decided with James
--   2026-10-02). The FOUND hasher's choice (HC.Hasher.DirectoryVisibility)
--   is the only gate:
--     3 anyone                 — any signed-in hasher finds them
--     1 people I have run with — only if HC6.CoRunners says so
--     2 kennel members         — only a member (IsMember = 1, not a
--                                follower) of a kennel they are a member of
--     0 / NULL                 — never found
--   Matches the hash name and the home kennel's name / short name; the
--   first name, last name and "first last" only when they also chose
--   +16 (real name), so nobody's real name is linked to their hash name
--   without their say. A block either way hides them. Results show the
--   hasher's own display-name choice (HC.Hasher.DisplayName).
--   Guards against scraping: 2..60 characters, at most 50 results, and a
--   per-hasher limit of 30 searches a minute / 400 a day, counted in
--   LOG.GeneralLog (LogSource 'hasherSearch', Message = the user id; the
--   search text is not logged).
-- Returns: rowset 0 — standard success envelope;
--   rowset 1 — { PublicHasherId, DisplayName, Photo, HomeKennelName,
--   HomeKennelShortName, HomeKennelLogo, RunsTogether }
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
    @spNumber = 143, @param = NULL,
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

DECLARE @q NVARCHAR(MAX) = LTRIM(RTRIM(COALESCE(@query, N'')));
DECLARE @me NVARCHAR(50) = CAST(@userId AS NVARCHAR(50));
DECLARE @refusal NVARCHAR(200) = NULL;

IF (LEN(@q) < 2 OR LEN(@q) > 60)
    SET @refusal = N'Type at least 2 letters of a name.';
ELSE IF ((SELECT COUNT(*) FROM LOG.GeneralLog
          WHERE LogSource = 'hasherSearch' AND Message = @me
            AND [Timestamp] > DATEADD(MINUTE, -1, SYSDATETIMEOFFSET())) >= 30
      OR (SELECT COUNT(*) FROM LOG.GeneralLog
          WHERE LogSource = 'hasherSearch' AND Message = @me
            AND [Timestamp] > DATEADD(DAY, -1, SYSDATETIMEOFFSET())) >= 400)
    SET @refusal = N'You have searched a lot just now. Please wait a minute and try again.';

IF (@refusal IS NOT NULL)
BEGIN
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Hasher search refused',
            CONCAT(@refusal, N' len=', LEN(@q)), @procName, @userId);
    SELECT 0 AS success, 14300 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 14300 AS errorCode,
           'Search' AS errorTitle, @refusal AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    INSERT LOG.GeneralLog (LogSource, Message, [Timestamp])
    VALUES ('hasherSearch', @me, SYSDATETIMEOFFSET());

    -- LIKE wildcards in what was typed are literal characters.
    DECLARE @pattern NVARCHAR(MAX) =
        N'%' + REPLACE(REPLACE(REPLACE(@q, N'[', N'[[]'), N'%', N'[%]'), N'_', N'[_]') + N'%';
    DECLARE @prefix NVARCHAR(MAX) = SUBSTRING(@pattern, 2, LEN(@pattern));

    -- The searcher's co-runners and kennels, once.
    CREATE TABLE #co (UserId UNIQUEIDENTIFIER PRIMARY KEY, RunsTogether INT);
    INSERT #co SELECT UserId, RunsTogether FROM HC6.CoRunners(@userId);

    CREATE TABLE #myKennels (KennelId UNIQUEIDENTIFIER PRIMARY KEY);
    INSERT #myKennels SELECT DISTINCT KennelId FROM HC.HasherKennelMap
    WHERE UserId = @userId AND IsMember = 1;

    CREATE TABLE #found (PublicHasherId NVARCHAR(40), DisplayName NVARCHAR(600), Photo NVARCHAR(MAX),
                         HomeKennelName NVARCHAR(500), HomeKennelShortName NVARCHAR(250),
                         HomeKennelLogo NVARCHAR(MAX), RunsTogether INT, SortKey INT IDENTITY(1,1));

    INSERT #found (PublicHasherId, DisplayName, Photo, HomeKennelName, HomeKennelShortName, HomeKennelLogo, RunsTogether)
    SELECT TOP (50)
           UPPER(CAST(h.PublicHasherId AS NVARCHAR(40))) AS PublicHasherId,
           h.DisplayName                                 AS DisplayName,
           h.Photo                                       AS Photo,
           k.KennelName                                  AS HomeKennelName,
           k.KennelShortName                             AS HomeKennelShortName,
           k.KennelLogo                                  AS HomeKennelLogo,
           COALESCE(co.RunsTogether, 0)                  AS RunsTogether
    FROM HC.Hasher h
    LEFT JOIN HC.Kennel k ON k.id = h.HomeKennelId AND k.deleted = 0
    LEFT JOIN #co co ON co.UserId = h.id
    WHERE h.deleted = 0
      AND ISNULL(h.Removed, 0) = 0
      AND h.id <> @userId
      AND (h.DirectoryVisibility & 3) <> 0          -- NULL and 0 are never found
      AND (   (h.DirectoryVisibility & 3) = 3
           OR ((h.DirectoryVisibility & 3) = 1 AND co.UserId IS NOT NULL)
           OR ((h.DirectoryVisibility & 3) = 2 AND EXISTS (
                   SELECT 1 FROM HC.HasherKennelMap theirs
                   JOIN #myKennels mk ON mk.KennelId = theirs.KennelId
                   WHERE theirs.UserId = h.id AND theirs.IsMember = 1)))
      AND (   h.HashName LIKE @pattern
           OR k.KennelName LIKE @pattern
           OR k.KennelShortName LIKE @pattern
           OR ((h.DirectoryVisibility & 16) <> 0 AND (
                   h.FirstName LIKE @pattern
                OR h.LastName LIKE @pattern
                OR CONCAT(LTRIM(RTRIM(h.FirstName)), N' ', LTRIM(RTRIM(h.LastName))) LIKE @pattern)))
      AND NOT EXISTS (SELECT 1 FROM HC.HasherFriendMap b
                      WHERE b.Ignore = 1
                        AND ((b.UserId = @userId AND b.Friend_UserId = h.id)
                          OR (b.UserId = h.id AND b.Friend_UserId = @userId)))
    ORDER BY
        -- a name that STARTS with what was typed first, then people you know
        CASE WHEN h.HashName LIKE @prefix
               OR ((h.DirectoryVisibility & 16) <> 0 AND (h.FirstName LIKE @prefix OR h.LastName LIKE @prefix))
             THEN 0 ELSE 1 END,
        COALESCE(co.RunsTogether, 0) DESC,
        h.DisplayName;

    -- The envelope only once the results exist, so a failure above can never
    -- follow a success row.
    SELECT 1 AS success, NULL AS errorMessage;
    SELECT PublicHasherId, DisplayName, Photo, HomeKennelName, HomeKennelShortName, HomeKennelLogo, RunsTogether
    FROM #found ORDER BY SortKey;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in searchHashers', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 14301 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 14301 AS errorCode,
           'Something went wrong' AS errorTitle, 'The search could not be run. Please try again.' AS errorUserMessage, @procName AS errorProc;
END CATCH
GO
