CREATE OR ALTER PROCEDURE [TSA].[tsa_getRedemptionSummary]
    @restaurantId UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: TSA.tsa_getRedemptionSummary
-- Description: Returns meal counts grouped by date and meal, optionally
--              filtered to a single restaurant. NULL = all restaurants
--              (admin view). Only counts redeemed orders.
-- Parameters:
--   @restaurantId - (optional) Filter to a specific restaurant
-- Returns: date, restaurantName, mealName, count
--          ordered by date DESC, restaurantName, count DESC
-- =====================================================================
SET NOCOUNT ON;

SELECT
    CONVERT(VARCHAR(10), o.[date], 120)   AS [date],
    r.[name]                              AS restaurantName,
    mi.[name]                             AS mealName,
    COUNT(*)                              AS [count]
FROM  [TSA].[Order]      o
JOIN  [TSA].[Restaurant] r   ON o.[restaurantId] = r.[id]
JOIN  [TSA].[MenuItem]   mi  ON o.[mealId]       = mi.[id]
WHERE o.[redeemedAt] IS NOT NULL
AND   (@restaurantId IS NULL OR o.[restaurantId] = @restaurantId)
GROUP BY CONVERT(VARCHAR(10), o.[date], 120), r.[name], mi.[name]
ORDER BY [date] DESC, r.[name], COUNT(*) DESC;
