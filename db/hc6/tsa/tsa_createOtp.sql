CREATE OR ALTER PROCEDURE [TSA].[tsa_createOtp]
    @phoneNumber    NVARCHAR(30),
    @otpHash        NVARCHAR(64)
AS
-- =====================================================================
-- Procedure: TSA.tsa_createOtp
-- Description: Stores a new OTP hash for a phone number. Invalidates
--              any existing unused OTPs for the same number first.
--              The caller (Next.js) generates the 6-digit code, hashes
--              it with SHA-256, and sends the plaintext via Twilio.
-- Parameters:
--   @phoneNumber - E.164 phone number
--   @otpHash     - SHA-256 hex hash of the 6-digit code
-- Returns: Success/ErrorMessage envelope
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Invalidate any existing unused OTPs for this phone
    UPDATE [TSA].[OtpCode]
    SET    [usedAt] = SYSDATETIMEOFFSET()
    WHERE  [phoneNumber] = @phoneNumber
      AND  [usedAt] IS NULL;

    INSERT INTO [TSA].[OtpCode] ([phoneNumber], [otpHash], [expiresAt])
    VALUES (@phoneNumber, @otpHash, DATEADD(MINUTE, 10, SYSDATETIMEOFFSET()));

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
