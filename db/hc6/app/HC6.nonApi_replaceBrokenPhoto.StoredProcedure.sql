CREATE OR ALTER PROCEDURE [HC6].[nonApi_replaceBrokenPhoto]
    @url         NVARCHAR(1000),
    @replacement NVARCHAR(1000),
    @httpStatus  INT
AS
-- =====================================================================
-- Procedure: HC6.nonApi_replaceBrokenPhoto
-- Description: A profile photo whose blob no longer exists is replaced with a
--   bundled avatar so the roster stops showing a broken image (E16.F3.S1).
--   Called by the ReportBrokenPhoto Azure Function ONLY AFTER it has itself
--   asked blob storage for the URL and been told 404/410 — a phone's report is
--   never trusted on its own, because a bad connection looks the same to the
--   phone as a missing file, and a hostile client must not be able to wipe
--   somebody else's photo by naming it.
--   The same URL can be somebody's HC.Hasher.Photo and a per-kennel
--   HC.HasherKennelMap.KennelUserPhoto; both are corrected. The kennel photo
--   is cleared rather than replaced — the app falls back to the hasher's own
--   photo when it is NULL. Both tables carry an updatedAt trigger, so the
--   corrected rows re-sync to every client on its next delta.
-- Parameters:
--   @url         - The photo URL the phone could not load and storage says is gone.
--   @replacement - The bundled-avatar URL to put in its place.
--   @httpStatus  - What storage answered (404/410), for the log line.
-- Returns: one row — HasherRows, KennelRows (rows corrected in each table).
-- Author: Harrier Central
-- Created: 2026-09-10
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @hasherRows INT = 0, @kennelRows INT = 0;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE HC.Hasher
       SET Photo = @replacement
     WHERE Photo = @url AND deleted = 0;
    SET @hasherRows = @@ROWCOUNT;

    UPDATE HC.HasherKennelMap
       SET KennelUserPhoto = NULL
     WHERE KennelUserPhoto = @url;
    SET @kennelRows = @@ROWCOUNT;

    INSERT INTO LOG.GeneralLog (LogSource, Message, StrParam1, Data, Timestamp)
    VALUES ('ReportBrokenPhoto',
            CONCAT('Blob ', @httpStatus, ': hasher rows ', @hasherRows, ', kennel rows ', @kennelRows),
            LEFT(@url, 500),
            CONCAT('replacement=', @replacement),
            SYSUTCDATETIME());

    COMMIT TRANSACTION;
    SELECT @hasherRows AS HasherRows, @kennelRows AS KennelRows;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_replaceBrokenPhoto',
            ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
GO
