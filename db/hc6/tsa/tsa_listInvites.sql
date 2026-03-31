CREATE OR ALTER PROCEDURE [TSA].[tsa_listInvites]
AS
-- =====================================================================
-- Procedure: TSA.tsa_listInvites
-- Description: Returns all invites for the admin dashboard,
--              most recent first. Includes registration status.
-- Returns: All invite rows with computed status column
-- =====================================================================
SET NOCOUNT ON;

SELECT
    i.[id],
    i.[firstName],
    i.[lastName],
    i.[createdByAdmin],
    i.[createdAt],
    i.[expiresAt],
    i.[usedAt],
    CASE
        WHEN i.[usedAt] IS NOT NULL                        THEN 'Registered'
        WHEN i.[expiresAt] < SYSDATETIMEOFFSET()           THEN 'Expired'
        ELSE                                                    'Pending'
    END AS [status]
FROM [TSA].[WorkerInvite] i
ORDER BY i.[createdAt] DESC;
