CREATE OR ALTER PROCEDURE [TSA].[tsa_getMenuItems]
    @restaurantId UNIQUEIDENTIFIER
AS
-- =====================================================================
-- Procedure: TSA.tsa_getMenuItems
-- Description: Returns menu items for a given restaurant.
-- Parameters:
--   @restaurantId - Restaurant UUID
-- Returns: MenuItem rows for that restaurant
-- =====================================================================
SET NOCOUNT ON;

SELECT
    [id],
    [restaurantId],
    [name],
    [description],
    [imageUrl],
    [dailyQuota],
    [isAvailable]
FROM [TSA].[MenuItem]
WHERE [restaurantId] = @restaurantId
ORDER BY [name];
