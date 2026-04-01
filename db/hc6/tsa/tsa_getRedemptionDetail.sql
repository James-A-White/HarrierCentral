CREATE OR ALTER PROCEDURE [TSA].[tsa_getRedemptionDetail]
    @restaurantId UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: TSA.tsa_getRedemptionDetail
-- Description: Returns individual meal redemptions, optionally filtered
--              to a single restaurant. NULL restaurantId = all restaurants
--              (admin view). Only returns redeemed orders.
-- Parameters:
--   @restaurantId - (optional) Filter to a specific restaurant
-- Returns: date, restaurantName, firstName, lastName, mealName, redeemedAt
--          ordered by date DESC, redeemedAt DESC
-- =====================================================================
SET NOCOUNT ON;

SELECT
    CONVERT(VARCHAR(10), o.[date], 120)         AS [date],
    r.[name]                                    AS restaurantName,
    w.[firstName],
    w.[lastName],
    mi.[name]                                   AS mealName,
    CONVERT(VARCHAR(30), o.[redeemedAt], 127)   AS redeemedAt
FROM  [TSA].[Order]      o
JOIN  [TSA].[Worker]     w   ON o.[workerId]     = w.[id]
JOIN  [TSA].[Restaurant] r   ON o.[restaurantId] = r.[id]
JOIN  [TSA].[MenuItem]   mi  ON o.[mealId]       = mi.[id]
WHERE o.[redeemedAt] IS NOT NULL
AND   (@restaurantId IS NULL OR o.[restaurantId] = @restaurantId)
ORDER BY o.[date] DESC, o.[redeemedAt] DESC;
