-- =====================================================================
-- Procedure: HC6.publicWeb_issuePasskeyInviteCode
-- Description: The app's first-install sign-in with a web passkey
--   (E9.F7.S13): after the web has verified the passkey's assertion, the
--   hasher behind that credential gets a fresh invite code — the same
--   HC6.nonApi_ensureUserInviteCode the emailed code comes from — which
--   the app feeds to its own hcapp_authorizeDevice URC path. Guarded by
--   the internal secret on PublicWebAdminApi; never called before the
--   signature has been checked.
-- Parameters: @credentialId — the passkey's credential id (base64url)
-- Returns: rowset 0 envelope; rowset 1 { inviteCode }
-- Author: Harrier Central
-- Created: 2026-09-17
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_issuePasskeyInviteCode]
    @credentialId NVARCHAR(1000)
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    DECLARE @userId UNIQUEIDENTIFIER;
    SELECT TOP 1 @userId = d.UserId
    FROM HC.Device d
    WHERE d.PasskeyCredentialId = @credentialId AND d.removed = 0;

    IF (@userId IS NULL)
    BEGIN
        DECLARE @errorId UNIQUEIDENTIFIER = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, '<web>', 'Passkey not found', 'credentialId=' + LEFT(@credentialId, 60), @procName, NULL);
        SELECT 0 AS success, 1230 AS errorCode, 12 AS errorType;
        SELECT @errorId AS errorId, 12 AS errorType, 1230 AS errorCode,
               'Passkey not found' AS errorTitle, 'That passkey is not registered.' AS errorUserMessage, @procName AS errorProc;
        RETURN;
    END

    EXEC HC6.nonApi_ensureUserInviteCode @userId = @userId, @rotateIfOlderThanMinutes = 60;

    DECLARE @inviteCode NVARCHAR(50);
    SELECT @inviteCode = ResetCode FROM HC.Hasher WHERE id = @userId AND Removed = 0;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
    SELECT @inviteCode AS inviteCode;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_issuePasskeyInviteCode', ERROR_MESSAGE(), @procName, NULL);
    SELECT 0 AS success, 1500 AS errorCode, 5 AS errorType;
END CATCH
GO
