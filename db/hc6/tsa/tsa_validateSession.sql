CREATE OR ALTER PROCEDURE [TSA].[tsa_validateSession]
    @sessionId UNIQUEIDENTIFIER
AS
-- =====================================================================
-- Procedure: TSA.tsa_validateSession
-- Description: Validates a session cookie value. Updates lastSeenAt
--              on success (sliding window). Returns worker identity.
-- Parameters:
--   @sessionId - Session UUID from the httpOnly cookie
-- Returns: workerId, firstName, lastName or empty rowset (invalid/expired)
-- =====================================================================
SET NOCOUNT ON;

UPDATE [TSA].[Session]
SET    [lastSeenAt] = SYSDATETIMEOFFSET()
WHERE  [id]        = @sessionId
  AND  [expiresAt] > SYSDATETIMEOFFSET();

IF @@ROWCOUNT = 0
    RETURN; -- empty rowset → caller treats as unauthenticated

SELECT w.[id] AS workerId, w.[firstName], w.[lastName], w.[status]
FROM   [TSA].[Session] s
JOIN   [TSA].[Worker]  w ON w.[id] = s.[workerId]
WHERE  s.[id] = @sessionId
  AND  w.[status] = 'Active';
