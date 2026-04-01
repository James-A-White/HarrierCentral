CREATE OR ALTER PROCEDURE [TSA].[tsa_loginByPhone]
    @phoneNumber NVARCHAR(30)
AS
-- =====================================================================
-- Procedure: TSA.tsa_loginByPhone
-- Description: Temporary bypass for OTP-less login. Looks up an active
--              worker by phone number and opens a 90-day session.
--              ONLY USE WHILE SMS INFRASTRUCTURE IS UNAVAILABLE.
--              Replace the caller with tsa_validateOtp + tsa_createReturnSession
--              once Twilio is provisioned.
-- Parameters:
--   @phoneNumber - Worker phone number in E.164 format
-- Returns: Success (BIT), ErrorMessage, sessionId, workerId,
--          firstName, lastName
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @workerId   UNIQUEIDENTIFIER;
    DECLARE @firstName  NVARCHAR(100);
    DECLARE @lastName   NVARCHAR(100);
    DECLARE @sessionId  UNIQUEIDENTIFIER = NEWID();

    SELECT  @workerId  = [id],
            @firstName = [firstName],
            @lastName  = [lastName]
    FROM    [TSA].[Worker]
    WHERE   [phoneNumber] = @phoneNumber
    AND     [status] = 'Active';

    IF @workerId IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success, 'No active account found for that phone number.' AS ErrorMessage,
               NULL AS sessionId, NULL AS workerId, NULL AS firstName, NULL AS lastName;
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
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage,
           NULL AS sessionId, NULL AS workerId, NULL AS firstName, NULL AS lastName;
END CATCH
