-- =====================================================================
-- Run-once script: Create HC.PortalNewsflash and HC.PortalNewsflashRead
-- Created:  2026-04-10
-- Author:   Harrier Central
-- Notes:    After execution, archive to db/hc6/portal/archive/
--           This script is idempotent — it checks existence before
--           creating each object.
-- =====================================================================

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- ── HC.PortalNewsflash ────────────────────────────────────────────────────────

IF NOT EXISTS (
    SELECT 1 FROM sys.tables t
    INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE s.name = 'HC' AND t.name = 'PortalNewsflash'
)
BEGIN
    CREATE TABLE [HC].[PortalNewsflash] (
        [NewsflashId]           UNIQUEIDENTIFIER    NOT NULL
            CONSTRAINT [DF_PortalNewsflash_NewsflashId]      DEFAULT NEWSEQUENTIALID(),
        [Title]                 NVARCHAR(250)       NOT NULL,
        [BodyText]              NVARCHAR(MAX)       NOT NULL,
        [ImageUrl]              NVARCHAR(500)       NULL,
        [StartDate]             DATE                NOT NULL
            CONSTRAINT [DF_PortalNewsflash_StartDate]        DEFAULT CAST(GETUTCDATE() AS DATE),
        [EndDate]               DATE                NULL,
        [KennelId]              UNIQUEIDENTIFIER    NULL,       -- NULL = all kennels; FK → HC.Kennel.id
        [IsDeleted]             BIT                 NOT NULL
            CONSTRAINT [DF_PortalNewsflash_IsDeleted]        DEFAULT 0,
        [CreatedByHasherId]     UNIQUEIDENTIFIER    NOT NULL,   -- FK → HC.Hasher.id
        [CreatedAt]             DATETIME            NOT NULL
            CONSTRAINT [DF_PortalNewsflash_CreatedAt]        DEFAULT GETUTCDATE(),
        [UpdatedAt]             DATETIME            NOT NULL
            CONSTRAINT [DF_PortalNewsflash_UpdatedAt]        DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_PortalNewsflash] PRIMARY KEY CLUSTERED ([NewsflashId] ASC)
            WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
            ON [PRIMARY],

        CONSTRAINT [FK_PortalNewsflash_Kennel] FOREIGN KEY ([KennelId])
            REFERENCES [HC].[Kennel] ([id]),

        CONSTRAINT [FK_PortalNewsflash_CreatedByHasher] FOREIGN KEY ([CreatedByHasherId])
            REFERENCES [HC].[Hasher] ([id])

    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

    PRINT 'Created HC.PortalNewsflash';
END
ELSE
BEGIN
    PRINT 'HC.PortalNewsflash already exists — skipped';
END
GO

-- Index: active newsflash lookup (primary query path for getPendingNewsflashes)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    INNER JOIN sys.tables t ON t.object_id = i.object_id
    INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE s.name = 'HC' AND t.name = 'PortalNewsflash' AND i.name = 'IX_PortalNewsflash_Active'
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PortalNewsflash_Active]
        ON [HC].[PortalNewsflash] ([IsDeleted], [StartDate])
        INCLUDE ([EndDate], [KennelId], [Title])
        WITH (STATISTICS_NORECOMPUTE = OFF, FILLFACTOR = 80)
        ON [PRIMARY];

    PRINT 'Created IX_PortalNewsflash_Active';
END
GO

-- ── HC.PortalNewsflashRead ────────────────────────────────────────────────────

IF NOT EXISTS (
    SELECT 1 FROM sys.tables t
    INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE s.name = 'HC' AND t.name = 'PortalNewsflashRead'
)
BEGIN
    CREATE TABLE [HC].[PortalNewsflashRead] (
        [NewsflashReadId]   UNIQUEIDENTIFIER    NOT NULL
            CONSTRAINT [DF_PortalNewsflashRead_NewsflashReadId] DEFAULT NEWSEQUENTIALID(),
        [NewsflashId]       UNIQUEIDENTIFIER    NOT NULL,   -- FK → HC.PortalNewsflash.NewsflashId
        [HasherId]          UNIQUEIDENTIFIER    NOT NULL,   -- FK → HC.Hasher.id
        [IsDismissed]       BIT                 NOT NULL,   -- 1 = "I've read it"; 0 = snoozed
        [NextShowDate]      DATE                NULL,       -- tomorrow's date when snoozed; NULL when dismissed
        [UpdatedAt]         DATETIME            NOT NULL
            CONSTRAINT [DF_PortalNewsflashRead_UpdatedAt]      DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_PortalNewsflashRead] PRIMARY KEY CLUSTERED ([NewsflashReadId] ASC)
            WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF,
                  FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
            ON [PRIMARY],

        -- One record per user per newsflash — upserted on each interaction
        CONSTRAINT [UQ_PortalNewsflashRead_Newsflash_Hasher] UNIQUE NONCLUSTERED ([NewsflashId], [HasherId])
            WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, FILLFACTOR = 80)
            ON [PRIMARY],

        CONSTRAINT [FK_PortalNewsflashRead_Newsflash] FOREIGN KEY ([NewsflashId])
            REFERENCES [HC].[PortalNewsflash] ([NewsflashId]),

        CONSTRAINT [FK_PortalNewsflashRead_Hasher] FOREIGN KEY ([HasherId])
            REFERENCES [HC].[Hasher] ([id])

    ) ON [PRIMARY];

    PRINT 'Created HC.PortalNewsflashRead';
END
ELSE
BEGIN
    PRINT 'HC.PortalNewsflashRead already exists — skipped';
END
GO

-- Index: pending newsflash lookup per hasher (hot path for getPendingNewsflashes)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes i
    INNER JOIN sys.tables t ON t.object_id = i.object_id
    INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
    WHERE s.name = 'HC' AND t.name = 'PortalNewsflashRead' AND i.name = 'IX_PortalNewsflashRead_Hasher'
)
BEGIN
    CREATE NONCLUSTERED INDEX [IX_PortalNewsflashRead_Hasher]
        ON [HC].[PortalNewsflashRead] ([HasherId], [IsDismissed])
        INCLUDE ([NewsflashId], [NextShowDate])
        WITH (STATISTICS_NORECOMPUTE = OFF, FILLFACTOR = 80)
        ON [PRIMARY];

    PRINT 'Created IX_PortalNewsflashRead_Hasher';
END
GO

PRINT 'Done.';
GO
