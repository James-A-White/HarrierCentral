CREATE OR ALTER PROCEDURE [TSA].[tsa_validateInviteToken]
    @token NVARCHAR(100)
AS
-- =====================================================================
-- Procedure: TSA.tsa_validateInviteToken
-- Description: Validates a QR registration token. Returns the invite
--              details if valid. Returns error envelope if expired or used.
-- Parameters:
--   @token - The cryptographic token from the QR code URL
-- Returns: invite row (id, firstName, lastName) or error envelope
-- =====================================================================
SET NOCOUNT ON;

DECLARE @invite TABLE (
    id          UNIQUEIDENTIFIER,
    firstName   NVARCHAR(100),
    lastName    NVARCHAR(100),
    expiresAt   DATETIMEOFFSET(7),
    usedAt      DATETIMEOFFSET(7)
);

INSERT INTO @invite
SELECT [id], [firstName], [lastName], [expiresAt], [usedAt]
FROM [TSA].[WorkerInvite]
WHERE [token] = @token;

IF NOT EXISTS (SELECT 1 FROM @invite)
BEGIN
    SELECT 0 AS Success, 'Invalid registration link.' AS ErrorMessage;
    RETURN;
END

IF EXISTS (SELECT 1 FROM @invite WHERE [usedAt] IS NOT NULL)
BEGIN
    SELECT 0 AS Success, 'This registration link has already been used.' AS ErrorMessage;
    RETURN;
END

IF EXISTS (SELECT 1 FROM @invite WHERE [expiresAt] < SYSDATETIMEOFFSET())
BEGIN
    SELECT 0 AS Success, 'This registration link has expired. Please ask your administrator for a new one.' AS ErrorMessage;
    RETURN;
END

SELECT [id], [firstName], [lastName]
FROM @invite;
