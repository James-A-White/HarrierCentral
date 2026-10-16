CREATE OR ALTER PROCEDURE [HC6].[hcportal_getKennelMessages]
    @deviceId           UNIQUEIDENTIFIER  = NULL,
    @accessToken        NVARCHAR(1000)    = NULL,
    @publicKennelId     UNIQUEIDENTIFIER  = NULL,
    @sinceSequenceCount INT               = NULL,
    @reactionsSince     DATETIMEOFFSET(7) = NULL,
    @kennelThread       SMALLINT          = 0
AS
-- =====================================================================
-- Procedure: HC6.hcportal_getKennelMessages
-- Description: Reads one of a kennel's two chat threads for the portal (E9.F1.S33,
--   James 2026-10-16: "the portal needs to mirror the phone"). The read is
--   HC6.nonApi_getKennelMessages — the same SP the app's
--   hcapp_getKennelMessages reads through — so both read by one set of
--   rules. Rowsets are hcapp_getKennelMessages'; roomId = PublicKennelId.
-- Parameters: @publicKennelId (the token's paramString is '<deviceSecret>:<publicKennelId>'),
--   @sinceSequenceCount, @reactionsSince, @kennelThread (0 general, 1 Mismanagement).
-- Returns: Messages, RemovedMessageIds, ReactionUpdates, ReactionsAsOf; on error
--   the HC6 envelope { Success 0, ErrorMessage }.
-- Author: Harrier Central
-- Created: 2026-10-16
-- HC5 Source: none (new — the portal had no kennel chat; E9.F1.S33)
-- Breaking Changes: none (new)
-- Idempotency: read-only — the bell write sets a state (0 → 1, never toggled)
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @authError NVARCHAR(255);
DECLARE @hasherId UNIQUEIDENTIFIER;
DECLARE @callerType INT;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @hcv NVARCHAR(100) = HC6.DeviceHcVersion(@deviceId);
DECLARE @errorCode INT, @errorType INT, @errorId UNIQUEIDENTIFIER, @eTitle NVARCHAR(200), @eMsg NVARCHAR(500);

EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @publicKennelId,
    @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

DECLARE @kennelId UNIQUEIDENTIFIER;
SELECT @kennelId = k.id FROM HC.Kennel k
WHERE k.PublicKennelId = @publicKennelId AND k.deleted = 0 AND k.removed = 0;
IF (@kennelId IS NULL)
BEGIN
    SELECT 0 AS Success, 'Kennel not found' AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    EXEC HC6.nonApi_getKennelMessages
        @userId = @hasherId, @kennelId = @kennelId, @sinceSequenceCount = @sinceSequenceCount,
        @reactionsSince = @reactionsSince, @kennelThread = @kennelThread,
        @hcVersion = @hcv, @callerProcName = @procName,
        @errorCode = @errorCode OUTPUT, @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
        @errorTitle = @eTitle OUTPUT, @errorUserMessage = @eMsg OUTPUT;
    IF (@errorCode IS NOT NULL)
        SELECT 0 AS Success, @eMsg AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), @hcv, 'Unhandled error in hcportal_getKennelMessages', ERROR_MESSAGE(), @procName, @hasherId);
    THROW;
END CATCH
GO
