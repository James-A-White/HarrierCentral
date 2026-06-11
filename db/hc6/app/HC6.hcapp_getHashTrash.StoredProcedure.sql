CREATE OR ALTER PROCEDURE [HC6].[hcapp_getHashTrash]

    @deviceId    UNIQUEIDENTIFIER,
    @accessToken NVARCHAR(1000),
    @kennelId    UNIQUEIDENTIFIER,
    @eventId     UNIQUEIDENTIFIER

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getHashTrash
-- Description: Returns the HashTrash article for a run. Published
--   articles (status=1) are returned to any authenticated user.
--   Draft articles (status=0) are returned only to mismanagement roles:
--   Hash Flash (0x20), WebMeister (0x1000), GM (0x02), VGM (0x04),
--   or RA (0x08). If the article does not exist or the caller lacks
--   access to a draft, status=NULL and content=NULL are returned
--   (success=1, no error — callers treat NULL content as "no article").
-- Parameters:
--   @deviceId    - Registered device UUID
--   @accessToken - Token validated against DeviceSecret
--   @kennelId    - Kennel that owns the event
--   @eventId     - Event to fetch HashTrash for
-- Returns:
--   On success (rowset 0): { headline, content, status } — any field
--     may be NULL if no article exists or the caller cannot see a draft
--   On error  (rowset 0): { success=0, errorCode, errorType }
--   On error  (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-06-08
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
    @spNumber     = 54,
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

DECLARE @mmRoleFlags INT = 0;
SELECT @mmRoleFlags = ISNULL(MismanagementRoles, 0)
FROM HC.HasherKennelMap
WHERE UserId = @userId AND KennelId = @kennelId;

-- Mismanagement can see drafts; everyone else only sees published
DECLARE @canSeeDraft SMALLINT = CASE WHEN (@mmRoleFlags & 0x0000102E) <> 0 THEN 1 ELSE 0 END;

SELECT
    e.HashTrashHeadline AS headline,
    CASE
        WHEN e.HashTrashStatus IS NULL                 THEN NULL
        WHEN e.HashTrashStatus = 1                     THEN e.HashTrashContent
        WHEN e.HashTrashStatus = 0 AND @canSeeDraft = 1 THEN e.HashTrashContent
        ELSE NULL
    END AS content,
    CASE
        WHEN e.HashTrashStatus IS NULL                 THEN NULL
        WHEN e.HashTrashStatus = 1                     THEN e.HashTrashStatus
        WHEN e.HashTrashStatus = 0 AND @canSeeDraft = 1 THEN e.HashTrashStatus
        ELSE NULL
    END AS status
FROM HC.Event e
WHERE e.id       = @eventId
  AND e.KennelId = @kennelId
  AND e.deleted  = 0;
