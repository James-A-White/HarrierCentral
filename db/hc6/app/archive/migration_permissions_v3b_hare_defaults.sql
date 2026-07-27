-- =====================================================================
-- RUN-ONCE — Hare role default permissions: "Run + money tools"
-- =====================================================================
-- Adds View payment report + Bulk payment to the Hare grantor's GLOBAL grants
-- (on top of the seeded run tools), per the chosen default. The matching callers
-- (hcapp_getPaymentReport, hcapp_processBulkPayment) now pass @isHareOfEvent so
-- this is server-enforced. Recompiles + archives after run.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @hareId INT = (SELECT id FROM HC.PermissionRole WHERE GrantorKey = 'hare');

INSERT HC.RolePermission (GrantorId, FunctionId, KennelId, Allowed)
SELECT @hareId, f.id, NULL, 1
FROM HC.PermissionFunction f
WHERE f.FunctionKey IN ('viewPaymentReport', 'bulkPayment')
  AND NOT EXISTS (
      SELECT 1 FROM HC.RolePermission rp
      WHERE rp.GrantorId = @hareId AND rp.FunctionId = f.id AND rp.KennelId IS NULL);
GO

EXEC HC6.nonApi_compilePermissionMatrix;
GO

SELECT 'Hare defaults: ' + STRING_AGG(f.FunctionKey, ', ')
FROM HC.RolePermission rp
JOIN HC.PermissionRole g ON g.id = rp.GrantorId AND g.GrantorType = 'hare'
JOIN HC.PermissionFunction f ON f.id = rp.FunctionId
WHERE rp.KennelId IS NULL;
GO
