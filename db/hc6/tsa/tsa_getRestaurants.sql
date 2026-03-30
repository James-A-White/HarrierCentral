CREATE OR ALTER PROCEDURE [TSA].[tsa_getRestaurants]
AS
-- =====================================================================
-- Procedure: TSA.tsa_getRestaurants
-- Description: Returns all active restaurants for the browse page.
-- Returns: Restaurant rows ordered by name
-- =====================================================================
SET NOCOUNT ON;

SELECT
    [id],
    [name],
    [address],
    [latitude],
    [longitude],
    [cuisineType],
    [serviceTypes],
    [description],
    [imageUrl],
    [dailyQuota]
FROM [TSA].[Restaurant]
WHERE [isActive] = 1
ORDER BY [name];
