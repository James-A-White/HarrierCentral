CREATE OR ALTER PROCEDURE [TSA].[tsa_createOrder]
    @workerId       UNIQUEIDENTIFIER,
    @restaurantId   UNIQUEIDENTIFIER,
    @mealId         UNIQUEIDENTIFIER
AS
-- =====================================================================
-- Procedure: TSA.tsa_createOrder
-- Description: Creates a meal order for today. If the worker already
--              has an order for today, returns the existing token
--              (idempotent — safe to call multiple times).
-- Parameters:
--   @workerId     - Worker placing the order
--   @restaurantId - Restaurant selected
--   @mealId       - Menu item selected
-- Returns: token (UNIQUEIDENTIFIER), Success (BIT), ErrorMessage
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @today DATE = CAST(GETUTCDATE() AS DATE);
    DECLARE @existingToken UNIQUEIDENTIFIER;

    -- Return existing order if worker already ordered today
    SELECT @existingToken = [token]
    FROM [TSA].[Order]
    WHERE [workerId] = @workerId AND [date] = @today;

    IF @existingToken IS NOT NULL
    BEGIN
        COMMIT TRANSACTION;
        SELECT @existingToken AS token, 1 AS Success, NULL AS ErrorMessage;
        RETURN;
    END

    DECLARE @token UNIQUEIDENTIFIER = NEWID();

    INSERT INTO [TSA].[Order] ([token], [workerId], [restaurantId], [mealId], [date])
    VALUES (@token, @workerId, @restaurantId, @mealId, @today);

    COMMIT TRANSACTION;
    SELECT @token AS token, 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT NULL AS token, 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
