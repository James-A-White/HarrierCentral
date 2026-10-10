CREATE OR ALTER PROCEDURE [HC6].[nonApi_recordInviteEmailed]
    @kennelId  UNIQUEIDENTIFIER = NULL,
    @adminId   UNIQUEIDENTIFIER = NULL,
    @hasherIds NVARCHAR(MAX)    = NULL   -- '|'-separated HC.Hasher ids that were sent to
AS
-- =====================================================================
-- Procedure: HC6.nonApi_recordInviteEmailed
-- Description: Stamps HC.Hasher.InviteEmailedAt for the hashers an "Email
--   invite codes" send reached (E2.F2.S6), so the next send skips anyone
--   invited in the last 7 days. Called by the InviteEmails API endpoint
--   after the emails are handed to ACS. Never touches updatedAt (the
--   Hasher triggers fire only on updatedAt / name / photo / removed), so
--   nothing re-syncs. One LOG.GeneralLog row per send.
-- Returns: { Success, ErrorMessage, stamped }
-- Author: Harrier Central
-- Created: 2026-10-10
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    IF (@hasherIds IS NULL OR LEN(@hasherIds) = 0)
    BEGIN
        SELECT 1 AS Success, NULL AS ErrorMessage, 0 AS stamped;
        RETURN;
    END

    BEGIN TRANSACTION;
    UPDATE h SET h.InviteEmailedAt = SYSDATETIMEOFFSET()
    FROM HC.Hasher h
    WHERE h.id IN (SELECT TRY_CAST(LTRIM(RTRIM(value)) AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@hasherIds, '|'));
    DECLARE @n INT = @@ROWCOUNT;

    INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp])
    VALUES ('InviteEmail', 'Invite codes emailed', LOWER(CAST(@kennelId AS NVARCHAR(40))),
            CONCAT('{"admin":"', LOWER(CAST(@adminId AS NVARCHAR(40))), '","sent":', @n, '}'), SYSDATETIMEOFFSET());
    COMMIT TRANSACTION;

    SELECT 1 AS Success, NULL AS ErrorMessage, @n AS stamped;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (NEWID(), '<api>', 'Unhandled error in recordInviteEmailed', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), @adminId, @kennelId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage, 0 AS stamped;
END CATCH
