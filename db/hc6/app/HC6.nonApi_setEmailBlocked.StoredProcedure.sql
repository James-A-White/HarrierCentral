CREATE OR ALTER PROCEDURE [HC6].[nonApi_setEmailBlocked]

    @hasherId UNIQUEIDENTIFIER = NULL,
    @blocked  SMALLINT         = 1

AS
-- =====================================================================
-- Procedure: HC6.nonApi_setEmailBlocked
-- Description: The member's "no email from Harrier Central at all"
--   (E19.F4). Set from the email-preferences page reached by the signed
--   link in every list email; it is the member's unsubscribe and is
--   honoured above every preference and every admin override. Blocking
--   also switches every kennel and run email setting off, so nothing is
--   left that could re-enable them by accident. Never touches updatedAt.
-- Returns: { Success, ErrorMessage }
-- Author: Harrier Central
-- Created: 2026-10-09
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    IF (@hasherId IS NULL) THROW 50000, 'hasherId is required', 1;

    BEGIN TRANSACTION;

    UPDATE HC.Hasher
    SET EmailBlocked = CASE WHEN @blocked = 1 THEN 1 ELSE 0 END,
        EmailBlockedAt = CASE WHEN @blocked = 1 THEN SYSDATETIMEOFFSET() ELSE NULL END
    WHERE id = @hasherId AND EmailBlocked <> CASE WHEN @blocked = 1 THEN 1 ELSE 0 END;

    IF (@blocked = 1)
    BEGIN
        UPDATE HC.HasherKennelMap SET KennelEmailAlertPreference = 2
        WHERE UserId = @hasherId AND removed = 0 AND ISNULL(KennelEmailAlertPreference, 0) <> 2;
        UPDATE HC.HasherEventMap SET EventEmailAlertPreference = 2
        WHERE UserId = @hasherId AND EventEmailAlertPreference = 1;
    END

    INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp])
    VALUES ('EmailStatus', CASE WHEN @blocked = 1 THEN 'All emails blocked by member' ELSE 'Email block lifted' END,
            LOWER(CAST(@hasherId AS NVARCHAR(40))), NULL, SYSDATETIMEOFFSET());

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Unhandled error in setEmailBlocked', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), @hasherId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
