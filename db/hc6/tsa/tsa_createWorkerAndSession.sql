CREATE OR ALTER PROCEDURE [TSA].[tsa_createWorkerAndSession]
    @inviteId           UNIQUEIDENTIFIER,
    @phoneNumber        NVARCHAR(30),
    @termsAcceptedAt    DATETIMEOFFSET(7)
AS
-- =====================================================================
-- Procedure: TSA.tsa_createWorkerAndSession
-- Description: Creates a Worker record from a validated invite and
--              opens a 90-day session. Called after OTP verification
--              for first-time registration only.
-- Parameters:
--   @inviteId        - The invite UUID from the QR code
--   @phoneNumber     - E.164 phone number (already OTP-verified)
--   @termsAcceptedAt - Timestamp the user accepted T&Cs
-- Returns: sessionId on success; error envelope on failure
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Validate invite is still usable
    DECLARE @firstName  NVARCHAR(100);
    DECLARE @lastName   NVARCHAR(100);

    SELECT @firstName = [firstName], @lastName = [lastName]
    FROM   [TSA].[WorkerInvite]
    WHERE  [id]         = @inviteId
      AND  [usedAt]     IS NULL
      AND  [expiresAt]  > SYSDATETIMEOFFSET();

    IF @firstName IS NULL
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success, 'Invite is no longer valid.' AS ErrorMessage;
        RETURN;
    END

    DECLARE @workerId   UNIQUEIDENTIFIER = NEWID();
    DECLARE @sessionId  UNIQUEIDENTIFIER = NEWID();

    INSERT INTO [TSA].[Worker] ([id], [inviteId], [firstName], [lastName], [phoneNumber], [termsAcceptedAt])
    VALUES (@workerId, @inviteId, @firstName, @lastName, @phoneNumber, @termsAcceptedAt);

    INSERT INTO [TSA].[Session] ([id], [workerId], [expiresAt])
    VALUES (@sessionId, @workerId, DATEADD(DAY, 90, SYSDATETIMEOFFSET()));

    -- Mark invite as used
    UPDATE [TSA].[WorkerInvite]
    SET    [usedAt] = SYSDATETIMEOFFSET()
    WHERE  [id]     = @inviteId;

    COMMIT TRANSACTION;

    SELECT 1 AS Success, NULL AS ErrorMessage, @sessionId AS sessionId,
           @workerId AS workerId, @firstName AS firstName, @lastName AS lastName;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
