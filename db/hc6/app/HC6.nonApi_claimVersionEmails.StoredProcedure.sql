CREATE OR ALTER PROCEDURE [HC6].[nonApi_claimVersionEmails]
    @sendId UNIQUEIDENTIFIER = NULL,
    @take   INT = 10
AS
-- =====================================================================
-- Procedure: HC6.nonApi_claimVersionEmails
-- Description: The API's VersionEmail sender takes the next @take queued
--   rows of a send (E19.F3.S3): Status 0 → 3 (sending) in one statement,
--   skipping rows another sender holds (READPAST), so two senders on the
--   same send — a retried press of Send, a restarted instance — split the
--   rows and never mail one person twice. Returns what the email needs.
-- Parameters: @sendId; @take (1..50).
-- Returns: rowset 0 — { EmailLogId, Email, FirstName, Subject, IsIos,
--   IsAndroid } — IsIos / IsAndroid: the person has an iPhone / Android
--   phone on record (which store buttons the email shows).
-- Author: Harrier Central
-- Created: 2026-10-17
-- HC5 Source: none (new)
-- Breaking Changes: none (new)
-- Idempotency: compare-and-set — a row moves 0 → 3 only from 0; a repeat
--   finds nothing left to claim.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
IF (@take IS NULL OR @take < 1 OR @take > 50) SET @take = 10;
DECLARE @claimed TABLE (id UNIQUEIDENTIFIER, userId UNIQUEIDENTIFIER, subject NVARCHAR(250));
BEGIN TRY
    UPDATE TOP (@take) l
    SET Status = 3
    OUTPUT inserted.id, inserted.UserId, inserted.Subject INTO @claimed
    FROM HC.EmailLog l WITH (UPDLOCK, READPAST, ROWLOCK)
    WHERE l.SendId = @sendId AND l.Status = 0;

    SELECT c.id AS EmailLogId,
           h.Email,
           COALESCE(NULLIF(LTRIM(RTRIM(h.FirstName)), ''), NULLIF(LTRIM(RTRIM(h.HashName)), ''), '') AS FirstName,
           c.subject AS Subject,
           CAST(CASE WHEN EXISTS (SELECT 1 FROM HC.Device d WHERE d.UserId = c.userId AND d.IsMobile = 1
                                  AND d.removed = 0 AND d.OperatingSystem IN ('iOS', 'iPadOS'))
                     THEN 1 ELSE 0 END AS SMALLINT) AS IsIos,
           CAST(CASE WHEN EXISTS (SELECT 1 FROM HC.Device d WHERE d.UserId = c.userId AND d.IsMobile = 1
                                  AND d.removed = 0 AND d.OperatingSystem IS NULL)
                     THEN 1 ELSE 0 END AS SMALLINT) AS IsAndroid
    FROM @claimed c
    JOIN HC.Hasher h ON h.id = c.userId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Unhandled error in nonApi_claimVersionEmails',
            ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
GO
