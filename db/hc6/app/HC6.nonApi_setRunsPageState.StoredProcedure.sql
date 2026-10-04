CREATE OR ALTER PROCEDURE [HC6].[nonApi_setRunsPageState]
    @kennelId UNIQUEIDENTIFIER = NULL,
    @hash     CHAR(64)         = NULL,   -- the page fingerprint to remember; NULL = keep
    @changed  SMALLINT         = 0,      -- 1 = the page changed and was read by the model
    @status   NVARCHAR(MAX)    = NULL    -- one line for the portal; NULL = keep
AS
-- =====================================================================
-- Procedure: HC6.nonApi_setRunsPageState
-- Description: The runs-page importer's bookkeeping for one kennel
--   (2026-10-04): when it last looked, the page fingerprint it imported,
--   when the page last changed, and what it found. The API stores the hash
--   only after a successful import, so a failed read is retried next time.
--   Touches RunsPageCheckedAt, which trgUpdateModifiedOnDateForKennels
--   treats as bookkeeping: no updatedAt stamp, so no phone re-syncs the
--   kennel four times a day.
-- Returns: nothing.
-- Author: Harrier Central
-- Created: 2026-10-04
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    UPDATE HC.Kennel
       SET RunsPageCheckedAt = SYSUTCDATETIME(),
           RunsPageHash      = COALESCE(@hash, RunsPageHash),
           RunsPageChangedAt = CASE WHEN @changed = 1 THEN SYSUTCDATETIME() ELSE RunsPageChangedAt END,
           RunsPageStatus    = CASE WHEN @status IS NULL THEN RunsPageStatus ELSE LEFT(@status, 500) END
     WHERE id = @kennelId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Unhandled error in setRunsPageState', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), NULL);
    THROW;
END CATCH
GO
