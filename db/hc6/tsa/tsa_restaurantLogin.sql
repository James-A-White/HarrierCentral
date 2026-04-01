CREATE OR ALTER PROCEDURE [TSA].[tsa_restaurantLogin]
    @password NVARCHAR(100)
AS
-- =====================================================================
-- Procedure: TSA.tsa_restaurantLogin
-- Description: Validates a restaurant portal passphrase and returns the
--              matching restaurant's id and name. Returns 0 rows on
--              no match. Passwords are plain-text shared passphrases
--              (low-stakes internal tool).
-- Parameters:
--   @password - The passphrase entered on the login page
-- Returns: restaurantId (UNIQUEIDENTIFIER), restaurantName (NVARCHAR)
--          0 rows if no match or restaurant is inactive.
-- =====================================================================
SET NOCOUNT ON;

SELECT TOP 1
    [id]   AS restaurantId,
    [name] AS restaurantName
FROM  [TSA].[Restaurant]
WHERE [portalPassword] = @password
AND   [isActive] = 1;
