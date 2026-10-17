CREATE OR ALTER PROCEDURE [HC6].[nonApi_updateEmailLog]
    @emailLogId UNIQUEIDENTIFIER = NULL,
    @status     SMALLINT         = NULL,
    @reply      NVARCHAR(MAX)    = NULL,
    @sendId     UNIQUEIDENTIFIER = NULL,
    @auditPath  NVARCHAR(400)    = NULL
AS
-- =====================================================================
-- Procedure: HC6.nonApi_updateEmailLog
-- Description: The API records what happened to a per-recipient email
--   (E19.F3.S3): with @emailLogId, that row's Status (1 sent, 2 failed)
--   and the reason in ServerReply; with @sendId and @auditPath, where the
--   send's full text is kept (email-audit container), on all its rows.
-- Parameters: @emailLogId + @status (+ @reply); or @sendId + @auditPath.
-- Returns: nothing.
-- Author: Harrier Central
-- Created: 2026-10-17
-- HC5 Source: none (new)
-- Breaking Changes: none (new)
-- Idempotency: set-state — writes the final state; a repeat writes it again.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    IF (@emailLogId IS NOT NULL AND @status IN (1, 2))
        UPDATE HC.EmailLog
        SET Status = @status,
            ServerReply = CASE WHEN @reply IS NULL THEN ServerReply ELSE LEFT(@reply, 2500) END
        WHERE id = @emailLogId;

    IF (@sendId IS NOT NULL AND @auditPath IS NOT NULL)
        UPDATE HC.EmailLog SET AuditPath = @auditPath WHERE SendId = @sendId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Unhandled error in nonApi_updateEmailLog',
            ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
GO
