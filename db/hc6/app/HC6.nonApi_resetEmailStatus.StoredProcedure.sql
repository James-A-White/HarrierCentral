CREATE OR ALTER PROCEDURE [HC6].[nonApi_resetEmailStatus]

    @hasherId UNIQUEIDENTIFIER = NULL,
    @reason   NVARCHAR(100)    = NULL

AS
-- =====================================================================
-- Procedure: HC6.nonApi_resetEmailStatus
-- Description: Email status back to Unknown with a zero soft-bounce count
--   (E19.F4). Called when a hasher's email ADDRESS changes (the status
--   described the old one) and when an admin clears a bounce after asking
--   for a new address. Never touches updatedAt. No-op when already Unknown.
-- Returns: { Success, ErrorMessage }
-- Author: Harrier Central
-- Created: 2026-10-09
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    IF (@hasherId IS NULL) THROW 50000, 'hasherId is required', 1;

    UPDATE HC.Hasher
    SET EmailStatus = 0, EmailSoftBounceCount = 0, EmailStatusChangedAt = SYSDATETIMEOFFSET()
    WHERE id = @hasherId AND (EmailStatus <> 0 OR EmailSoftBounceCount <> 0);

    IF (@@ROWCOUNT > 0 AND @reason IS NOT NULL)
        INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp])
        VALUES ('EmailStatus', 'Email status reset', LOWER(CAST(@hasherId AS NVARCHAR(40))), @reason, SYSDATETIMEOFFSET());

    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in resetEmailStatus', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), @hasherId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
