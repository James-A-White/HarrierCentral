CREATE OR ALTER PROCEDURE [HC6].[hcapp_setDirectoryVisibility]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @visibility  SMALLINT         = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_setDirectoryVisibility
-- Description: Records who may find the caller in hasher search
--   (E9.F1.S26) — the answer to the once-only question, or a change made in
--   Settings. Writes HC.Hasher.DirectoryVisibility ALONE and never
--   updatedAt: the column is not synced, so changing it must not make
--   every phone re-download this hasher (James, 2026-10-02). No Hasher
--   trigger stamps the row for this column (checked 2026-10-02).
-- Parameters: @visibility — 0 nobody, 1 people I have run with, 2 members
--   of a kennel I belong to, 3 anyone; + 16 = may also be found by real
--   name. The real-name flag is dropped with 0: nobody means nobody.
-- Returns: rowset 0 — standard success envelope; rowset 1 — { DirectoryVisibility }
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
    @spNumber = 142, @param = NULL,
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

-- Only the scope (low two bits) and the real-name flag (16) are meaningful.
IF (@visibility IS NULL OR @visibility < 0 OR (@visibility & ~19) <> 0)
BEGIN
    DECLARE @detail NVARCHAR(200) = CONCAT('visibility=', COALESCE(CAST(@visibility AS NVARCHAR(10)), 'null'));
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Bad directory visibility', @detail, @procName, @userId);
    SELECT 0 AS success, 14200 AS errorCode, 2 AS errorType;
    SELECT @errorId AS errorId, 2 AS errorType, 14200 AS errorCode,
           'Bad setting' AS errorTitle, 'That setting could not be saved. Please try again.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

IF ((@visibility & 3) = 0) SET @visibility = 0;   -- nobody: the real-name flag means nothing

BEGIN TRY
    UPDATE HC.Hasher SET DirectoryVisibility = @visibility WHERE id = @userId;

    SELECT 1 AS success, NULL AS errorMessage;
    SELECT h.DirectoryVisibility FROM HC.Hasher h WHERE h.id = @userId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in setDirectoryVisibility', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, 14201 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 14201 AS errorCode,
           'Something went wrong' AS errorTitle, 'That setting could not be saved. Please try again.' AS errorUserMessage, @procName AS errorProc;
END CATCH
GO
