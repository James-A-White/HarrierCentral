CREATE OR ALTER PROCEDURE [TSA].[tsa_redeemOrder]
    @token UNIQUEIDENTIFIER
AS
-- =====================================================================
-- Procedure: TSA.tsa_redeemOrder
-- Description: Marks an order as redeemed. Prevents double redemption
--              and rejects orders that are not for today (UTC).
-- Parameters:
--   @token - The QR code token to redeem
-- Returns: Success (BIT), ErrorMessage
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @orderId        UNIQUEIDENTIFIER;
    DECLARE @redeemedAt     DATETIME2(7);
    DECLARE @orderDate      DATE;

    SELECT  @orderId    = [id],
            @redeemedAt = [redeemedAt],
            @orderDate  = [date]
    FROM    [TSA].[Order]
    WHERE   [token] = @token;

    IF @orderId IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success, 'Order not found.' AS ErrorMessage;
        RETURN;
    END

    IF @redeemedAt IS NOT NULL
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success, 'This order has already been redeemed.' AS ErrorMessage;
        RETURN;
    END

    IF @orderDate <> CAST(GETUTCDATE() AS DATE)
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success, 'This order has expired.' AS ErrorMessage;
        RETURN;
    END

    UPDATE [TSA].[Order]
    SET    [redeemedAt] = GETUTCDATE()
    WHERE  [id] = @orderId;

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
