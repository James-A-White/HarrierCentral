-- =====================================================================
-- Trigger:     HC.TR_Kennel_AfterInsert_CreateKennelWebsite
-- Description: Creates a stub HC.KennelWebsite row whenever a new
--              Kennel is inserted, so the 1:1 relationship is
--              pre-populated with safe defaults. The website is
--              disabled (Enabled = 0) and unconfigured (all content
--              and theming columns NULL) until a portal admin sets
--              it up. Handles multi-row inserts correctly.
-- Table:       HC.Kennel
-- Author:      Harrier Central
-- Created:     2026-03-27
-- =====================================================================

DROP TRIGGER IF EXISTS [HC].[TR_Kennel_AfterInsert_CreateKennelWebsite];
GO

CREATE TRIGGER [HC].[TR_Kennel_AfterInsert_CreateKennelWebsite]
ON [HC].[Kennel]
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Insert one stub KennelWebsite row per inserted Kennel.
    -- Defaults (Enabled = 0, ThemeMode = 'dark', ScrollBlur = 0)
    -- are applied by the column DEFAULT constraints.
    -- All content and theming columns remain NULL until configured.
    INSERT INTO [HC].[KennelWebsite] ([KennelId])
    SELECT [id]
    FROM inserted;
END
GO
