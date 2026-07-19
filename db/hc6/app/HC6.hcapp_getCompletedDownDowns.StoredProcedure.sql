CREATE OR ALTER PROCEDURE [HC6].[hcapp_getCompletedDownDowns]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @kennelId    UNIQUEIDENTIFIER,
    @eventId     UNIQUEIDENTIFIER

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getCompletedDownDowns
-- Description: Returns all completed (IsDone=true, IsCancelled=false)
--   DownDown charges for a run. Visible to any member of the kennel; a
--   non-member gets EMPTY rowsets (no history), not an error — viewing a run for
--   a kennel you don't belong to is normal, not an error condition.
--   Two rowsets:
--     Rowset 0 — one row per completed DownDown (empty for non-members)
--     Rowset 1 — one row per DownDownHasher for those charges (empty for non-members)
--   Intended for the run detail page history view (non-admin users).
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @kennelId    - Kennel that owns the event
--   @eventId     - Event to fetch completed DownDowns for
-- Returns:
--   On success (rowset 0): DownDown rows (isDone=1) ordered by createdAt
--   On success (rowset 1): DownDownHasher rows for those charges
--   On error  (rowset 0): { success=0, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-06-09
-- HC5 Source: None — new feature
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
    @spNumber     = 58,
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

IF (@kennelId IS NULL OR @kennelId = '00000000-0000-0000-0000-000000000000'
 OR @eventId  IS NULL OR @eventId  = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1234; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Missing parameter',
            '@kennelId and @eventId are both required', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing parameter' AS errorTitle,
           'A required parameter was missing. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Membership: Down Down history is a members-only extra, but viewing a run for
-- a kennel you don't belong to is NORMAL (e.g. browsing another kennel's runs),
-- not an error. So resolve membership to a flag and return NO history (empty
-- rowsets) to non-members below — never an auth error. This keeps the app's
-- global SP-error dialog reserved for genuine failures (bad token, DB error,
-- missing params).
DECLARE @isMember SMALLINT =
    CASE WHEN EXISTS (
        SELECT 1 FROM HC.HasherKennelMap
        WHERE UserId   = @userId
          AND KennelId = @kennelId
          AND removed  = 0
    ) THEN 1 ELSE 0 END;

-- Rowset 0: Completed DownDown charges
SELECT
    dd.id              AS downDownId,
    dd.ChargeText      AS chargeText,
    dd.IsDone          AS isDone,
    dd.IsCancelled     AS isCancelled,
    dd.SongChoice      AS songChoice,
    LOWER(CAST(dd.SongId AS NVARCHAR(40))) AS songId,
    dd.ChargePhotoUrl  AS chargePhotoUrl,
    h.DisplayName      AS createdByDisplayName,
    h.Photo            AS createdByPhoto,
    dd.CreatedAt       AS createdAt
FROM HC.DownDowns dd
INNER JOIN HC.Hasher h ON h.id = dd.CreatedByUserId
WHERE dd.EventId    = @eventId
  AND dd.KennelId   = @kennelId
  AND dd.IsDone     = 1
  AND dd.IsCancelled = 0
  AND @isMember     = 1
ORDER BY dd.CreatedAt ASC;

-- Rowset 1: Charged hashers for the returned DownDowns
SELECT
    ddh.DownDownId AS downDownId,
    ddh.HasherId   AS hasherId,
    h.DisplayName  AS displayName
FROM HC.DownDownHashers ddh
INNER JOIN HC.Hasher h ON h.id = ddh.HasherId
INNER JOIN HC.DownDowns dd ON dd.id = ddh.DownDownId
WHERE dd.EventId    = @eventId
  AND dd.KennelId   = @kennelId
  AND dd.IsDone     = 1
  AND dd.IsCancelled = 0
  AND @isMember     = 1;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in getCompletedDownDowns',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
