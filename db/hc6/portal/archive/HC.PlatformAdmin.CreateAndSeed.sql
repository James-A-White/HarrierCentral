-- =====================================================================
-- Run-once: Create HC.PlatformAdmin table and seed initial admin users.
-- After executing, move this file to archive/.
-- =====================================================================

CREATE TABLE [HC].[PlatformAdmin] (
    [id]                  UNIQUEIDENTIFIER  NOT NULL CONSTRAINT [DF_PlatformAdmin_id]                  DEFAULT NEWID(),
    [UserId]              UNIQUEIDENTIFIER  NOT NULL,
    [CanViewMonitor]      SMALLINT          NOT NULL CONSTRAINT [DF_PlatformAdmin_CanViewMonitor]      DEFAULT 0,
    [CanManageNewsflash]  SMALLINT          NOT NULL CONSTRAINT [DF_PlatformAdmin_CanManageNewsflash]  DEFAULT 0,
    [createdAt]           DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_PlatformAdmin_createdAt]           DEFAULT SYSDATETIMEOFFSET(),
    [updatedAt]           DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_PlatformAdmin_updatedAt]           DEFAULT SYSDATETIMEOFFSET(),
    [removed]             BIT               NOT NULL CONSTRAINT [DF_PlatformAdmin_removed]             DEFAULT 0,
    CONSTRAINT [PK_PlatformAdmin] PRIMARY KEY CLUSTERED ([id] ASC)
);
GO

CREATE UNIQUE INDEX [UX_PlatformAdmin_UserId] ON [HC].[PlatformAdmin] ([UserId]);
GO

-- Seed: Opee (James White)
INSERT INTO HC.PlatformAdmin (UserId, CanViewMonitor, CanManageNewsflash)
SELECT h.id, 1, 1
FROM HC.Hasher h
WHERE h.PublicHasherId = 'B6BAFD0D-5D2E-41CD-8495-811D551F01D0'
  AND h.removed = 0;

-- Seed: Tuna Melt (Melissa)
INSERT INTO HC.PlatformAdmin (UserId, CanViewMonitor, CanManageNewsflash)
SELECT h.id, 1, 1
FROM HC.Hasher h
WHERE h.PublicHasherId = '7F413FA4-9291-474E-9E50-94DAA16E5CFC'
  AND h.removed = 0;
GO
