CREATE OR ALTER PROCEDURE [TSA].[tsa_createReturnSession]
    @workerId UNIQUEIDENTIFIER
AS
-- =====================================================================
-- Procedure: TSA.tsa_createReturnSession
-- Description: Opens a new 90-day session for a returning worker who
--              has lost their session cookie. Called after OTP
--              re-verification on an already-registered phone number.
-- Parameters:
--   @workerId - Worker UUID (returned by tsa_validateOtp)
-- Returns: sessionId, firstName, lastName
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @sessionId  UNIQUEIDENTIFIER = NEWID();
    DECLARE @firstName  NVARCHAR(100);
    DECLARE @lastName   NVARCHAR(100);

    SELECT @firstName = [firstName], @lastName = [lastName]
    FROM   [TSA].[Worker]
    WHERE  [id] = @workerId AND [status] = 'Active';

    IF @firstName IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success, 'Worker account not found or suspended.' AS ErrorMessage;
        RETURN;
    END

    INSERT INTO [TSA].[Session] ([id], [workerId], [expiresAt])
    VALUES (@sessionId, @workerId, DATEADD(DAY, 90, SYSDATETIMEOFFSET()));

    COMMIT TRANSACTION;

    SELECT 1 AS Success, NULL AS ErrorMessage,
           @sessionId AS sessionId, @workerId AS workerId,
           @firstName AS firstName, @lastName AS lastName;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
