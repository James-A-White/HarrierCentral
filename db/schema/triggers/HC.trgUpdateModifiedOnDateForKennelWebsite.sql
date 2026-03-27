-- =====================================================================
-- Trigger:     HC.trgUpdateModifiedOnDateForKennelWebsite
-- Description: Keeps updatedAt current on every INSERT or UPDATE to
--              HC.KennelWebsite, mirroring the pattern used by
--              HC.trgUpdateModifiedOnDateForKennels on HC.Kennel.
--
--              Differences from the Kennel trigger:
--                - No updatedAtBias column — KennelWebsite has no
--                  mobile sync requirement, so timestamps are set
--                  directly with SYSDATETIMEOFFSET().
--                - No integration column exclusions — KennelWebsite
--                  has no background-job fields that should bypass
--                  the updatedAt bump.
--
-- Table:       HC.KennelWebsite
-- Author:      Harrier Central
-- Created:     2026-03-27
-- =====================================================================

DROP TRIGGER IF EXISTS [HC].[trgUpdateModifiedOnDateForKennelWebsite];
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForKennelWebsite]
    ON  [HC].[KennelWebsite]
    AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- If updatedAt was not explicitly set by the caller, auto-stamp it now.
    IF NOT UPDATE(updatedAt)
    BEGIN
        UPDATE tbl
        SET updatedAt = SYSDATETIMEOFFSET()
        FROM HC.KennelWebsite tbl
        INNER JOIN INSERTED ins ON tbl.KennelId = ins.KennelId;
    END

    -- If updatedAt was explicitly set by the caller, use it as-is.
    -- (No bias adjustment needed — unlike HC.Kennel, KennelWebsite
    -- has no updatedAtBias column.)

END
GO
