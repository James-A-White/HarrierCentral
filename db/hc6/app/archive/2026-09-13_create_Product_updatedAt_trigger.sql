-- =====================================================================
-- Run-once: the UpdatedAt trigger on HC.Product (3.1, 2026-09-13)
--
--   HC.Product shipped WITHOUT a trigger, mirroring HC.Song, on the
--   reasoning that its two writers set updatedAt explicitly. James called
--   that out, and he is right: "explicitly" is a promise every future
--   writer has to keep, and the failure mode when one forgets is silent.
--   The row simply never reaches a phone again, because the sync pages on
--   updatedAt. A trigger makes it impossible to forget.
--
--   Same shape as HC.trgUpdateModifiedOnDateForPayment, including the
--   updatedAtBias microsecond offset that keeps a page boundary
--   deterministic when many rows share a timestamp:
--
--     writer did NOT set updatedAt  -> stamp SYSDATETIME() + bias
--     writer DID set updatedAt      -> honour theirs + bias
--
--   The second branch is what lets HC6.hcapp_addEditProduct and
--   HC6.hcportal_addEditProduct keep setting it; the trigger adds the bias
--   rather than fighting them.
--
--   ⚠ FROM NOW ON HC.Product IS A TRIGGERED, SYNCED TABLE. Any future
--   ALTER TABLE ... ADD COLUMN on it must disable this trigger first, run
--   the ALTER, then re-enable — otherwise every row is stamped and the
--   whole catalogue re-syncs to every phone on the planet. That was not
--   true when the table was created, and the create script's header says
--   so; this script is what changes it.
--
--   After running: move this file to db/hc6/app/archive/.
-- =====================================================================
SET NOCOUNT ON;

IF OBJECT_ID('HC.Product', 'U') IS NULL
BEGIN
    RAISERROR('HC.Product does not exist.', 16, 1);
    RETURN;
END
GO

CREATE OR ALTER TRIGGER [HC].[trgUpdateModifiedOnDateForProduct]
   ON HC.Product
   AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT UPDATE(updatedAt)
        BEGIN
            UPDATE tbl SET updatedAt = DATEADD(MICROSECOND, tbl.updatedAtBias, SYSDATETIME())
            FROM HC.Product tbl
            INNER JOIN INSERTED ins ON tbl.id = ins.id
        END
    ELSE
        BEGIN
            UPDATE tbl SET updatedAt = DATEADD(MICROSECOND, tbl.updatedAtBias, CAST(ins.updatedAt AS datetime2))
            FROM HC.Product tbl
            INNER JOIN INSERTED ins ON tbl.id = ins.id
        END
END
GO

PRINT 'HC.trgUpdateModifiedOnDateForProduct created';
GO

-- Prove it fires and that the existing rows were NOT all stamped by the
-- CREATE itself (creating a trigger does not touch rows, but verify rather
-- than assume).
SELECT COUNT(*) AS productsStampedInTheLastMinute
  FROM HC.Product
 WHERE updatedAt > DATEADD(MINUTE, -1, SYSUTCDATETIME());
GO

SELECT name, is_disabled FROM sys.triggers WHERE parent_id = OBJECT_ID('HC.Product');
GO
