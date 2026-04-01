CREATE OR ALTER PROCEDURE [TSA].[tsa_getOrderByToken]
    @token UNIQUEIDENTIFIER
AS
-- =====================================================================
-- Procedure: TSA.tsa_getOrderByToken
-- Description: Returns order details for a given QR token. Used by
--              restaurant staff to view and verify a worker's order.
--              Returns 0 rows if token not found.
-- Parameters:
--   @token - The QR code token (UNIQUEIDENTIFIER)
-- Returns: token, restaurantId, firstName, lastName, restaurantName,
--          mealName, date, redeemedAt
-- =====================================================================
SET NOCOUNT ON;

SELECT
    o.[token],
    o.[restaurantId],
    w.[firstName],
    w.[lastName],
    r.[name]                                    AS restaurantName,
    mi.[name]                                   AS mealName,
    CONVERT(VARCHAR(10), o.[date], 120)         AS [date],
    CONVERT(VARCHAR(30), o.[redeemedAt], 127)   AS redeemedAt
FROM  [TSA].[Order]      o
JOIN  [TSA].[Worker]     w   ON o.[workerId]     = w.[id]
JOIN  [TSA].[Restaurant] r   ON o.[restaurantId] = r.[id]
JOIN  [TSA].[MenuItem]   mi  ON o.[mealId]       = mi.[id]
WHERE o.[token] = @token;
