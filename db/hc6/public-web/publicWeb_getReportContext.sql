-- =====================================================================
-- Procedure: HC6.publicWeb_getReportContext
-- Description: What the SendRunCountsReport Azure Function needs before a
--   web member can ask for the emailed run-counts report the app's
--   floating action button sends (E9.F7.S17). That endpoint wants the
--   INTERNAL kennel id, the kennel's name, the hasher's display name and
--   the address to send to — none of which the member web session holds,
--   because it only ever carries public ids. Resolving them here keeps it
--   that way: the browser never sees the internal id or the address.
-- Parameters: @publicKennelId — NULL for the all-kennels report, which the
--   function signals with an empty GUID.
-- Returns: rowset 0 envelope; rowset 1 { KennelId, KennelName, UserName,
--   EmailAddress }
-- Author: Harrier Central
-- Created: 2026-09-17
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getReportContext]
    @deviceId       UNIQUEIDENTIFIER,
    @accessToken    NVARCHAR(1000),
    @publicKennelId UNIQUEIDENTIFIER = NULL
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;
DECLARE @errorCode INT, @errorType INT, @errorId UNIQUEIDENTIFIER;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 118, @param = NULL,
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
    DECLARE @kennelId UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000';
    DECLARE @kennelName NVARCHAR(250) = N'All kennels';

    IF (@publicKennelId IS NOT NULL)
        SELECT @kennelId = k.id, @kennelName = k.KennelName
        FROM HC.Kennel k
        WHERE k.PublicKennelId = @publicKennelId AND k.deleted = 0 AND k.removed = 0;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    SELECT
        @kennelId                                   AS KennelId,
        @kennelName                                 AS KennelName,
        h.DisplayName                               AS UserName,
        h.Email                                     AS EmailAddress
    FROM HC.Hasher h
    WHERE h.id = @userId AND h.Removed = 0;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getReportContext', ERROR_MESSAGE(), @procName, @userId, @deviceId);
    THROW;
END CATCH
GO
