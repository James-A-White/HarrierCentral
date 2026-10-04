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

BEGIN TRY

-- ---------------------------------------------------------------
-- Fetch invite code — conditions must all be met:
--   1. Target user has not yet signed in anywhere (LastLoginDateTime IS NULL
--      and no HC.Device row — web/portal sign-ins create one without the stamp)
--   2. Target user is not removed
--   3. Calling user has manage-members permission (AppAccessFlags & 0x40000010)
--      on the kennel that is the target's home kennel
-- ---------------------------------------------------------------
DECLARE @inviteCode NVARCHAR(250);

SELECT TOP 1 @inviteCode = h.ResetCode
FROM HC.Hasher h
WHERE h.id = @targetUserId
  AND h.LastLoginDateTime IS NULL
  -- A web or portal sign-in creates an HC.Device row without stamping
  -- LastLoginDateTime; it is a sign-in all the same, and an invite code for
  -- a signed-in account is a takeover (2026-09-23).
  AND NOT EXISTS (SELECT 1 FROM HC.Device d WHERE d.UserId = h.id)
  AND h.Removed = 0
  AND h.HomeKennelId IN (
      SELECT hkm.KennelId
      FROM HC.HasherKennelMap hkm
      WHERE hkm.UserId = @userId
        AND hkm.AppAccessFlags & 1073741840 != 0
  );

IF (@inviteCode IS NULL)
BEGIN
    -- WHICH condition failed, and for whom (2026-10-04: Dark Dick was
    -- refused four times on 2026-10-03 and the log could not say why or for
    -- whom). The message tells the admin the same reason.
    DECLARE @reason NVARCHAR(40) =
        CASE
            WHEN NOT EXISTS (SELECT 1 FROM HC.Hasher h WHERE h.id = @targetUserId AND h.Removed = 0)
                THEN 'not found'
            WHEN EXISTS (SELECT 1 FROM HC.Hasher h WHERE h.id = @targetUserId AND h.LastLoginDateTime IS NOT NULL)
              OR EXISTS (SELECT 1 FROM HC.Device d WHERE d.UserId = @targetUserId)
                THEN 'already signed in'
            ELSE 'not your home kennel' END;
    SET @errorCode = 1312; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Invite code not available',
            CONCAT('Target ', COALESCE(CAST(@targetUserId AS NVARCHAR(40)), 'null'), ': ', @reason,
                   ' (home kennel ', COALESCE((SELECT CAST(HomeKennelId AS NVARCHAR(40)) FROM HC.Hasher WHERE id = @targetUserId), 'none'), ')'),
            @procName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Invite code not available' AS errorTitle,
           CASE @reason
               WHEN 'already signed in' THEN
                   'This member has already signed in on a phone or the web, so their invite code '
                   + 'can no longer be shown. They can sign in again with "Email me a new invite code".'
               WHEN 'not found' THEN
                   'That member could not be found.'
               ELSE
                   'Only an admin of this member''s home kennel can see their invite code.'
           END AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

SELECT @inviteCode AS inviteCode;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_getInviteCode',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
