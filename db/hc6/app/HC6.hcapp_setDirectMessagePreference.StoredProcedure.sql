CREATE OR ALTER PROCEDURE [HC6].[hcapp_setDirectMessagePreference]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @preference  SMALLINT         = NULL     -- 0 friends only, 1 anyone, 2 nobody
AS
-- =====================================================================
-- Procedure: HC6.hcapp_setDirectMessagePreference
-- Description: Who may message the caller (E9.F1.S18). Two bits of
--   HC.Hasher.Preferences (0x4000|0x8000), read-modify-written HERE so no
--   other bit is touched — the bitfield is overwritten whole by
--   addEditUser, which is why every writer owns only its own bits
--   (2026-09-27 rule). The row's updatedAt moves through the table's
--   trigger, so the phone gets the value in its next user sync.
-- Returns: rowset 0 — standard success envelope; rowset 1 — { Preference }
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 128, @param = NULL,
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

IF (@preference IS NULL OR @preference NOT IN (0, 1, 2))
BEGIN
    DECLARE @detail NVARCHAR(200) = CONCAT('preference=', COALESCE(CAST(@preference AS NVARCHAR(10)), 'null'));
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Bad preference', @detail, @procName, @userId);
    SELECT 0 AS success, 2000 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 2000 AS errorCode,
           'Bad preference' AS errorTitle, 'That setting could not be saved. Please try again.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    UPDATE HC.Hasher
       -- 49152 = 0xC000: a hex literal is VARBINARY in T-SQL and ~ refuses it.
       SET Preferences = (COALESCE(Preferences, 0) & ~49152) | (@preference * 16384)
     WHERE id = @userId;

    SELECT 1 AS success, NULL AS errorMessage;
    SELECT HC6.DirectMessagePreference(h.Preferences) AS Preference FROM HC.Hasher h WHERE h.id = @userId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in setDirectMessagePreference', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 2001 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 2001 AS errorCode,
           'Something went wrong' AS errorTitle, 'That setting could not be saved. Please try again.' AS errorUserMessage, @procName AS errorProc;
END CATCH
GO
