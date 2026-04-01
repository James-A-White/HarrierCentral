-- =====================================================================
-- Migration: Add portalPassword column to TSA.Restaurant
-- Run once, then archive this file.
-- =====================================================================

ALTER TABLE [TSA].[Restaurant]
ADD [portalPassword] NVARCHAR(100) NULL;
GO

-- Set Portofino's password
UPDATE [TSA].[Restaurant]
SET    [portalPassword] = 'portofino'
WHERE  [name] = 'Portofino Ristorante';
GO
