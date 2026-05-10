CREATE OR ALTER PROCEDURE [HC6].[hcapp_getInviteCode]

    @deviceId     UNIQUEIDENTIFIER,
    @accessToken  NVARCHAR(1000),
    @targetUserId UNIQUEIDENTIFIER

AS
-- =====================================================================
-- Procedure: HC6.hcapp_getInviteCode
-- Description: Returns the invite code (ResetCode) for a target user,
--   provided the target has not yet logged in and the calling user has
--   manage-members permission on the target's home kennel. Used by
--   kennel admins to retrieve or share an invite code with a member
--   who has not yet set up the app.
-- Parameters:
--   @deviceId     - Registered device UUID
--   @accessToken  - Token validated against DeviceSecret
--   @targetUserId - Hasher.id of the user whose invite code is requested
-- Returns:
--   Read SP (no success envelope).
--   On success (rowset 0): single row with inviteCode NVARCHAR(250)
--   On error (rowset 0): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_getInviteCode
-- Breaking Changes:
--   On permission failure, standard HC6 error rowset returned instead of
--     HC5's 'No valid user' string result.
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
    @spNumber     = 12,
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

-- ---------------------------------------------------------------
-- Fetch invite code — conditions must all be met:
--   1. Target user has not yet logged in (LastLoginDateTime IS NULL)
--   2. Target user is not removed
--   3. Calling user has manage-members permission (AppAccessFlags & 0x40000010)
--      on the kennel that is the target's home kennel
-- ---------------------------------------------------------------
DECLARE @inviteCode NVARCHAR(250);

SELECT TOP 1 @inviteCode = h.ResetCode
FROM HC.Hasher h
WHERE h.id = @targetUserId
  AND h.LastLoginDateTime IS NULL
  AND h.Removed = 0
  AND h.HomeKennelId IN (
      SELECT hkm.KennelId
      FROM HC.HasherKennelMap hkm
      WHERE hkm.UserId = @userId
        AND hkm.AppAccessFlags & 1073741840 != 0
  );

IF (@inviteCode IS NULL)
BEGIN
    SET @errorCode = 1312; SET @errorType = 3; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Invite code not available',
            'Target user not found, already logged in, or caller lacks permission',
            @procName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Invite code not available' AS errorTitle,
           'The invite code could not be retrieved. The member may have already '
           + 'logged in, or you may not have permission to view their code.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

SELECT @inviteCode AS inviteCode;
