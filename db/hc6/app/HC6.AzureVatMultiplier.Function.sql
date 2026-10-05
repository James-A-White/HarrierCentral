CREATE OR ALTER FUNCTION [HC6].[AzureVatMultiplier] ()
RETURNS DECIMAL(6,4)
AS
-- =====================================================================
-- Function: HC6.AzureVatMultiplier
-- Description: What Azure's pre-tax cost is multiplied by to give what is
--   actually paid: UK VAT at 20% (James, 2026-10-05: "we pay VAT on our
--   Azure"). Azure Cost Management reports cost WITHOUT tax, and
--   LOG.AzureDailyCost keeps Azure's own figure; the monitor (getUsageData
--   row 12, getCategoryDetail2 category 12) applies this when it shows £.
--   One place, so a rate change is one edit.
-- Author: Harrier Central
-- Created: 2026-10-05
-- =====================================================================
BEGIN
    RETURN 1.20;
END
GO
