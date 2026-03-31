CREATE OR ALTER PROCEDURE [TSA].[tsa_validateOtp]
    @phoneNumber    NVARCHAR(30),
    @otpHash        NVARCHAR(64)
AS
-- =====================================================================
-- Procedure: TSA.tsa_validateOtp
-- Description: Validates an OTP hash for a phone number. Marks the
--              record as used on success. Called by both registration
--              (new user) and re-authentication (returning user).
--              The caller checks whether a Worker exists for this phone
--              to decide next step.
-- Parameters:
--   @phoneNumber - E.164 phone number
--   @otpHash     - SHA-256 hex hash of the code the user entered
-- Returns: On success — workerId (NULL if not yet registered)
--          On failure — error envelope
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @otpId UNIQUEIDENTIFIER;

    SELECT TOP 1 @otpId = [id]
    FROM [TSA].[OtpCode]
    WHERE  [phoneNumber] = @phoneNumber
      AND  [otpHash]     = @otpHash
      AND  [usedAt]      IS NULL
      AND  [expiresAt]   > SYSDATETIMEOFFSET()
    ORDER BY [createdAt] DESC;

    IF @otpId IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success, 'Invalid or expired code. Please try again.' AS ErrorMessage;
        RETURN;
    END

    -- Mark OTP as used
    UPDATE [TSA].[OtpCode]
    SET    [usedAt] = SYSDATETIMEOFFSET()
    WHERE  [id]     = @otpId;

    -- Check if a worker already exists for this phone (returning user)
    DECLARE @workerId UNIQUEIDENTIFIER;
    SELECT @workerId = [id]
    FROM   [TSA].[Worker]
    WHERE  [phoneNumber] = @phoneNumber
      AND  [status]      = 'Active';

    COMMIT TRANSACTION;

    SELECT 1 AS Success, NULL AS ErrorMessage, @workerId AS workerId;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
