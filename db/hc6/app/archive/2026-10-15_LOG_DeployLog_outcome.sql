-- =====================================================================
-- Run-once: LOG.DeployLog.Outcome / OutcomeAt (James, 2026-10-15).
--   An outcome is written AFTER the fact: what an AI task found and what
--   came of it, or what became of a deploy (rolled back, fixed the bug,
--   caused one). Detail says what was done; Outcome says how it turned out.
--   Set with: python3 tools/record_deploy.py --outcome <id> "<text>".
--   Not a synced table: a plain ALTER. After running: archive, then
--   python3 tools/schema_dump.py.
-- =====================================================================
SET NOCOUNT ON;
IF COL_LENGTH('LOG.DeployLog', 'Outcome') IS NULL
    ALTER TABLE LOG.DeployLog ADD
        [Outcome]   NVARCHAR(2000)    NULL,
        [OutcomeAt] DATETIMEOFFSET(7) NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE major_id = OBJECT_ID('LOG.DeployLog')
               AND minor_id = COLUMNPROPERTY(OBJECT_ID('LOG.DeployLog'), 'Outcome', 'ColumnId'))
BEGIN
    EXEC sp_addextendedproperty @name = N'MS_Description',
        @value = N'Written after the fact: what an AI task found and what came of it, or what became of a deploy (rolled back, fixed, caused a bug). Detail = what was done; Outcome = how it turned out (James, 2026-10-15).',
        @level0type = N'SCHEMA', @level0name = N'LOG', @level1type = N'TABLE', @level1name = N'DeployLog',
        @level2type = N'COLUMN', @level2name = N'Outcome';
    EXEC sp_addextendedproperty @name = N'MS_Description',
        @value = N'When Outcome was last written.',
        @level0type = N'SCHEMA', @level0name = N'LOG', @level1type = N'TABLE', @level1name = N'DeployLog',
        @level2type = N'COLUMN', @level2name = N'OutcomeAt';
END;
GO
