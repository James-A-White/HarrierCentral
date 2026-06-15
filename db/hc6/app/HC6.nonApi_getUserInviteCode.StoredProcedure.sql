CREATE OR ALTER PROCEDURE [HC6].[nonApi_getUserInviteCode]
    @email NVARCHAR(250)
AS
-- =====================================================================
-- Procedure: HC6.nonApi_getUserInviteCode
-- Description: Looks up or generates a 6-letter invite code for the
--   hasher with the given email address and returns it. The code is
--   stored in HC.Hasher.ResetCode (prefixed 'URC:') and reused if
--   generated within the last 60 minutes to prevent spam.
--   Called only from the EmailInviteCode Azure Function — never from
--   the app or portal.
-- Parameters:
--   @email - Email address of the hasher requesting an invite code.
-- Returns:
--   Single column: inviteCode NVARCHAR — the 6-letter code on success,
--   or a human-readable message if the email was not found.
-- Author: Harrier Central
-- Created: 2026-06-15
-- HC5 Source: HC.nonApi_getUserInviteCode
-- Breaking Changes vs HC5:
--   HC.NUMBER_TO_STR_BASE scalar function inlined — generates 6 random
--   uppercase letters directly using a WHILE loop + NEWID().
--   Hardcoded email override (james@jamesawhite.com → 'NCCARY') removed:
--   testing backdoors must not exist in production SPs.
-- =====================================================================
SET NOCOUNT ON;

DECLARE @ResetCodeLastUpdated DATETIMEOFFSET(7);
SELECT @ResetCodeLastUpdated = ResetCodeLastUpdated FROM HC.Hasher WHERE email = @email;

IF @ResetCodeLastUpdated IS NULL OR ABS(DATEDIFF(minute, @ResetCodeLastUpdated, GETDATE())) > 60
BEGIN
    -- Generate a new unique 6-letter uppercase code.
    -- Codespace = 26^6 ≈ 309 million; collision rate is negligible.
    -- Loop up to 10 times as a safety guard; a new NEWID() each iteration
    -- makes collisions essentially impossible in practice.
    DECLARE @alphabet NCHAR(26) = N'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    DECLARE @code     NCHAR(6);
    DECLARE @stop     SMALLINT = 0;

    WHILE @stop < 10
    BEGIN
        SET @stop += 1;
        SET @code = N'';
        DECLARE @i INT = 1;
        WHILE @i <= 6
        BEGIN
            SET @code += SUBSTRING(@alphabet, ABS(CHECKSUM(NEWID())) % 26 + 1, 1);
            SET @i += 1;
        END

        IF NOT EXISTS (SELECT 1 FROM HC.Hasher WHERE ResetCode = N'URC:' + @code)
        BEGIN
            UPDATE HC.Hasher
            SET    ResetCode            = N'URC:' + @code,
                   ResetCodeLastUpdated = GETDATE()
            WHERE  email = @email;
            SET @stop = 10; -- exit loop
        END
    END
END

DECLARE @inviteCode NVARCHAR(50);
SELECT @inviteCode = ResetCode FROM HC.Hasher WHERE email = @email AND Removed = 0;

SELECT COALESCE(
    REPLACE(@inviteCode, 'URC:', ''),
    'The email address provided was not found in our database. Please try another email address.'
) AS inviteCode;
