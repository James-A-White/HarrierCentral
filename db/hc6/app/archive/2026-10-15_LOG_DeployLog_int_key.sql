-- =====================================================================
-- Run-once: LOG.DeployLog keyed by INT IDENTITY instead of a GUID
-- (James, 2026-10-15: internal only, appended by one deploy at a time, so
-- a plain integer key is fine — and it orders rows by insertion like the
-- other LOG tables). Rebuilds the table, keeping every row. Also corrects
-- build 71's commit (the backfill wrote HEAD; the stamp said 65dfeb24).
-- Documented exception in .claude/skills/hc-primary-keys/SKILL.md.
-- After running: archive, then python3 tools/schema_dump.py.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('LOG.DeployLog') AND name = 'id'
           AND system_type_id = TYPE_ID('uniqueidentifier'))
BEGIN
    BEGIN TRANSACTION;

    SELECT DeployedAt, Component, Version, GitCommit, Audience, Detail
    INTO #keep FROM LOG.DeployLog;

    DROP TABLE LOG.DeployLog;

    CREATE TABLE [LOG].[DeployLog] (
        [id]          INT IDENTITY(1,1) NOT NULL
            CONSTRAINT [PK_DeployLog] PRIMARY KEY CLUSTERED,
        [DeployedAt]  DATETIMEOFFSET(7) NOT NULL
            CONSTRAINT [DF_DeployLog_DeployedAt] DEFAULT (SYSDATETIMEOFFSET()),
        [Component]   NVARCHAR(20)      NOT NULL,
        [Version]     NVARCHAR(40)      NOT NULL,
        [GitCommit]   NVARCHAR(40)      NULL,
        [Audience]    NVARCHAR(20)      NULL,
        [Detail]      NVARCHAR(400)     NULL
    );
    CREATE NONCLUSTERED INDEX [IX_DeployLog_Component_DeployedAt]
        ON [LOG].[DeployLog] ([Component], [DeployedAt])
        INCLUDE ([Version], [GitCommit]);

    INSERT LOG.DeployLog (DeployedAt, Component, Version, GitCommit, Audience, Detail)
    SELECT DeployedAt, Component, Version,
           CASE WHEN Component = 'sp' AND Version = '71' THEN '65dfeb24' ELSE GitCommit END,
           Audience, Detail
    FROM #keep ORDER BY DeployedAt;

    COMMIT TRANSACTION;

    EXEC sp_addextendedproperty @name = N'MS_Description',
        @value = N'One row per production deploy of any component (sp, api, web, portal, app-ios, app-android), so an error''s time maps to the builds live then. Append-only and NEVER pruned (James, 2026-10-15). INT IDENTITY key by James''s choice (internal, one writer). Written by tools/deploy_hc6.sh and tools/record_deploy.py.',
        @level0type = N'SCHEMA', @level0name = N'LOG',
        @level1type = N'TABLE',  @level1name = N'DeployLog';
END;
GO
