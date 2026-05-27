-- =====================================================================
-- Run-once: Add CanEditKennel column to HC.PlatformAdmin and seed
--           existing admin users.
-- After executing, this file has been moved to archive/.
-- =====================================================================

ALTER TABLE [HC].[PlatformAdmin]
ADD [CanEditKennel] SMALLINT NOT NULL
    CONSTRAINT [DF_PlatformAdmin_CanEditKennel] DEFAULT 0;
GO

-- Seed: Opee (James White)
UPDATE HC.PlatformAdmin
SET CanEditKennel = 1
WHERE UserId = (
    SELECT id FROM HC.Hasher
    WHERE PublicHasherId = 'B6BAFD0D-5D2E-41CD-8495-811D551F01D0'
      AND removed = 0
);

-- Seed: Tuna Melt (Melissa)
UPDATE HC.PlatformAdmin
SET CanEditKennel = 1
WHERE UserId = (
    SELECT id FROM HC.Hasher
    WHERE PublicHasherId = '7F413FA4-9291-474E-9E50-94DAA16E5CFC'
      AND removed = 0
);
GO
