CREATE OR ALTER PROCEDURE [HC6].[nonApi_setEmailDeliveryStatus]

    @email     NVARCHAR(250) = NULL,
    @acsStatus NVARCHAR(40)  = NULL

AS
-- =====================================================================
-- Procedure: HC6.nonApi_setEmailDeliveryStatus
-- Description: Applies one Azure Communication Services delivery report to
--   the hasher with that address (E19.F4, 2026-10-09). The status describes
--   the ADDRESS, so the row is found by HC.Hasher.Email (unique index).
--     Delivered                 -> OK, soft-bounce count 0
--     Bounced / Suppressed      -> Bounced (hard)
--     Failed / Quarantined /
--     FilteredSpam              -> soft bounce: count + 1; 3 in a row -> Suspect
--     anything else             -> ignored
--   Writes ONLY when something changes, and never touches updatedAt, so a
--   large send does not re-sync anybody. There is no spam-complaint event
--   from ACS; "blocked" is the member's own act (nonApi_setEmailBlocked).
-- Returns: { Success, ErrorMessage, hasherId, oldStatus, newStatus }
-- Author: Harrier Central
-- Created: 2026-10-09
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    IF (@email IS NULL OR @acsStatus IS NULL)
        THROW 50000, 'email and acsStatus are required', 1;

    DECLARE @hasherId UNIQUEIDENTIFIER, @status SMALLINT, @soft SMALLINT;
    SELECT TOP 1 @hasherId = h.id, @status = h.EmailStatus, @soft = h.EmailSoftBounceCount
    FROM HC.Hasher h
    WHERE h.Email = @email AND ISNULL(h.Removed, 0) = 0 AND h.deleted = 0
    ORDER BY h.updatedAt DESC;

    IF (@hasherId IS NULL)
    BEGIN
        SELECT 1 AS Success, NULL AS ErrorMessage, NULL AS hasherId, NULL AS oldStatus, NULL AS newStatus;
        RETURN;
    END

    DECLARE @newStatus SMALLINT = @status, @newSoft SMALLINT = @soft;
    IF (@acsStatus = 'Delivered')
    BEGIN
        SET @newStatus = 1; SET @newSoft = 0;
    END
    ELSE IF (@acsStatus IN ('Bounced', 'Suppressed'))
    BEGIN
        SET @newStatus = 3;
    END
    ELSE IF (@acsStatus IN ('Failed', 'Quarantined', 'FilteredSpam'))
    BEGIN
        SET @newSoft = CASE WHEN @soft >= 32000 THEN @soft ELSE @soft + 1 END;
        IF (@newSoft >= 3 AND @newStatus <> 3) SET @newStatus = 2;
    END

    IF (@newStatus <> @status OR @newSoft <> @soft)
        UPDATE HC.Hasher
        SET EmailStatus          = @newStatus,
            EmailSoftBounceCount = @newSoft,
            EmailStatusChangedAt = CASE WHEN @newStatus <> @status THEN SYSDATETIMEOFFSET() ELSE EmailStatusChangedAt END
        WHERE id = @hasherId;

    SELECT 1 AS Success, NULL AS ErrorMessage, LOWER(CAST(@hasherId AS NVARCHAR(40))) AS hasherId, @status AS oldStatus, @newStatus AS newStatus;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Unhandled error in setEmailDeliveryStatus', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), NULL);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage, NULL AS hasherId, NULL AS oldStatus, NULL AS newStatus;
END CATCH
