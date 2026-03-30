CREATE OR ALTER PROCEDURE [TSA].[tsa_createInvite]
    @firstName      NVARCHAR(100),
    @lastName       NVARCHAR(100),
    @createdByAdmin NVARCHAR(100)
AS
-- =====================================================================
-- Procedure: TSA.tsa_createInvite
-- Description: Creates a worker invitation with a cryptographically
--              random token. Returns the invite record including the
--              token to be embedded in a QR code URL.
-- Parameters:
--   @firstName      - TSA officer first name
--   @lastName       - TSA officer last name
--   @createdByAdmin - Admin username creating the invite
-- Returns: Single row — invite id, token, name, expiry
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    DECLARE @id        UNIQUEIDENTIFIER = NEWID();
    DECLARE @token     NVARCHAR(100)    = CONVERT(NVARCHAR(100), CRYPT_GEN_RANDOM(32), 2);
    DECLARE @expiresAt DATETIMEOFFSET(7) = DATEADD(HOUR, 48, SYSDATETIMEOFFSET());

    INSERT INTO [TSA].[WorkerInvite] ([id], [token], [firstName], [lastName], [createdByAdmin], [expiresAt])
    VALUES (@id, @token, @firstName, @lastName, @createdByAdmin, @expiresAt);

    SELECT
        @id        AS id,
        @token     AS token,
        @firstName AS firstName,
        @lastName  AS lastName,
        @expiresAt AS expiresAt;

END TRY
BEGIN CATCH
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
