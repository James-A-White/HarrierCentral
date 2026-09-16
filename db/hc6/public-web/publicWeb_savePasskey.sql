CREATE OR ALTER PROCEDURE [HC6].[publicWeb_savePasskey]
    @deviceId     UNIQUEIDENTIFIER,
    @accessToken  NVARCHAR(1000),
    @credentialId NVARCHAR(500),
    @publicKey    NVARCHAR(2000),
    @counter      BIGINT,
    @transports   NVARCHAR(100) = NULL
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_savePasskey
-- Description: Binds a WebAuthn credential to the calling browser's own
--              HC.Device row (E9.F7.S6). The registration ceremony was
--              verified by the Next.js route (@simplewebauthn/server) —
--              SQL cannot check an attestation — so this SP's job is to
--              prove the caller is a signed-in device (token) and store
--              the key against THAT device and no other.
-- Parameters:  @deviceId / @accessToken - the browser's device credentials
--              @credentialId / @publicKey / @counter / @transports - as
--              returned by the verified registration
-- Returns:     Write envelope.
-- Author:      Harrier Central
-- Created:     2026-09-16
-- HC5 Source:  none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;
DECLARE @errorCode INT, @errorType INT, @errorId UNIQUEIDENTIFIER;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 110, @param = NULL,
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
    IF (LEN(COALESCE(@credentialId, '')) = 0 OR LEN(COALESCE(@publicKey, '')) = 0)
    BEGIN
        SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
        VALUES (@errorId, '<web>', 'Passkey missing credential', 'credentialId or publicKey empty', @procName, @userId, @deviceId);
        SELECT 0 AS success, 1210 AS errorCode, 12 AS errorType;
        SELECT @errorId AS errorId, 12 AS errorType, 1210 AS errorCode,
               'Passkey incomplete' AS errorTitle, 'The passkey could not be saved.' AS errorUserMessage, @procName AS errorProc;
        RETURN;
    END

    BEGIN TRANSACTION;
    UPDATE HC.Device
    SET PasskeyCredentialId = @credentialId,
        PasskeyPublicKey    = @publicKey,
        PasskeyCounter      = @counter,
        PasskeyTransports   = @transports
    WHERE id = @deviceId AND UserId = @userId;
    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_savePasskey', ERROR_MESSAGE(), @procName, @userId, @deviceId);
    SELECT 0 AS success, 1500 AS errorCode, 5 AS errorType;
END CATCH
