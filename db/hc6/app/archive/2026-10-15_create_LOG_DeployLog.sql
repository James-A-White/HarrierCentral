-- =====================================================================
-- Run-once: LOG.DeployLog — one row per production deploy of any
-- component (2026-10-15). Its GUID key was replaced the same day by an INT
-- IDENTITY (James's choice): 2026-10-15_LOG_DeployLog_int_key.sql.
--
--   James asked for this table by name (2026-10-15), and asked that it be
--   its own table: LOG.GeneralLog is pruned by HC6.nonApi_pruneLogs, and
--   deploy history has to outlive every error it explains.
--
--   Why: provenance. Every SP deploy stamps all HC6 objects with one build
--   (tools/deploy_hc6.sh), but the database only knows the build live NOW.
--   With a row per deploy, any error's time answers "which SP build, API,
--   web, portal and app build were live then" — for HC.ErrorLog,
--   HC.ClientErrorLog and web errors alike, with no client change.
--
--   Written by tools/deploy_hc6.sh (Component 'sp') and by
--   tools/record_deploy.py for the API, web, portal and app deploys (the
--   dance-baby skill runs it after each). Append-only; NEVER pruned. Not
--   synced, so no UpdatedAt trigger.
--
--   After running: move this file to db/hc6/app/archive/ and run
--   python3 tools/schema_dump.py.
-- =====================================================================
SET NOCOUNT ON;

IF OBJECT_ID('LOG.DeployLog', 'U') IS NULL
BEGIN
    CREATE TABLE [LOG].[DeployLog] (
        [id]          UNIQUEIDENTIFIER  NOT NULL
            CONSTRAINT [DF_DeployLog_id] DEFAULT (NEWID())
            CONSTRAINT [PK_DeployLog] PRIMARY KEY CLUSTERED,
        [DeployedAt]  DATETIMEOFFSET(7) NOT NULL
            CONSTRAINT [DF_DeployLog_DeployedAt] DEFAULT (SYSDATETIMEOFFSET()),
        -- sp | api | web | portal | app-ios | app-android
        [Component]   NVARCHAR(20)      NOT NULL,
        -- What that component calls its version: SP build '72',
        -- API '1.0.61+110', web '0.21.76', portal '2.0.87+777', app '3.1.10+1479'.
        [Version]     NVARCHAR(40)      NOT NULL,
        [GitCommit]   NVARCHAR(40)      NULL,
        -- Who received it: 'production', 'private' (James/Tuna/Kilty), 'beta', 'store'.
        [Audience]    NVARCHAR(20)      NULL,
        [Detail]      NVARCHAR(400)     NULL
    );

    CREATE NONCLUSTERED INDEX [IX_DeployLog_Component_DeployedAt]
        ON [LOG].[DeployLog] ([Component], [DeployedAt])
        INCLUDE ([Version], [GitCommit]);

    EXEC sp_addextendedproperty @name = N'MS_Description',
        @value = N'One row per production deploy of any component (sp, api, web, portal, app-ios, app-android), so an error''s time maps to the builds live then. Append-only and NEVER pruned (James, 2026-10-15). Written by tools/deploy_hc6.sh and tools/record_deploy.py.',
        @level0type = N'SCHEMA', @level0name = N'LOG',
        @level1type = N'TABLE',  @level1name = N'DeployLog';
END;
GO

-- Backfill what is known exactly (the history starts here).
IF NOT EXISTS (SELECT 1 FROM LOG.DeployLog)
    INSERT LOG.DeployLog (DeployedAt, Component, Version, GitCommit, Audience, Detail)
    VALUES ('2026-10-15T08:54:18+00:00', 'sp', '72', '31326e43', 'production',
            'backfilled from the HC-DEPLOY stamp: 320 deployed, 0 failed'),
           ('2026-10-14T17:56:59+00:00', 'web', '0.21.74', '1376218c', 'production',
            'backfilled from the App Service deployment log (last of several 0.21.74 deploys)'),
           ('2026-10-15T07:14:59+00:00', 'web', '0.21.75', '8ec87434', 'production',
            'backfilled from the App Service deployment log'),
           ('2026-10-15T08:56:28+00:00', 'web', '0.21.76', '31326e43', 'production',
            'backfilled from the App Service deployment log'),
           ('2026-10-14T22:03:00+00:00', 'api', '1.0.61+110', '83b2917e', 'production',
            'backfilled; time approximate (within minutes)'),
           ('2026-10-15T07:40:00+00:00', 'portal', '2.0.87+777', '8ec87434', 'production',
            'backfilled; time approximate (CI deploy after the master push)'),
           ('2026-10-15T07:57:00+00:00', 'app-ios', '3.1.10+1478', '8ec87434', 'private',
            'backfilled; TestFlight, no group; time approximate');
GO
