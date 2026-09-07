CREATE OR ALTER PROCEDURE [HC6].[nonApi_getUserInviteCode]
    @email NVARCHAR(250)
AS
-- =====================================================================
-- Procedure: HC6.nonApi_getUserInviteCode
-- Description: Looks up or generates a 6-letter invite code for the
--   hasher with the given email address and returns it. The code is
--   stored in HC.Hasher.ResetCode (prefixed 'URC:') and reused if
--   generated within the last 60 minutes to prevent spam. Generation and
--   the definition of a compliant code live in
--   HC6.nonApi_ensureUserInviteCode.
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

-- Resolve the live hasher for this address first: everything else keys off the
-- id, and a removed account must never be matched (it can still hold the
-- address, and stamping a fresh code onto it would both miss the live account
-- and leave a working code pointing at a dead one).
DECLARE @userId UNIQUEIDENTIFIER;
SELECT @userId = id FROM HC.Hasher WHERE email = @email AND Removed = 0;

IF (@userId IS NOT NULL)
BEGIN
    -- Guarantee a compliant code before reading it back. Rotation after 60
    -- minutes is the spam guard this SP has always had; the helper also
    -- replaces a code that is present but unusable, which this SP used to hand
    -- straight to the caller whenever the timestamp happened to be recent —
    -- '######' (the column default) being the common case, and six characters
    -- long, so the caller's length check accepted it.
    EXEC HC6.nonApi_ensureUserInviteCode
        @userId                   = @userId,
        @rotateIfOlderThanMinutes = 60;
END

DECLARE @inviteCode NVARCHAR(50);
SELECT @inviteCode = ResetCode FROM HC.Hasher WHERE id = @userId AND Removed = 0;

SELECT COALESCE(
    REPLACE(@inviteCode, 'URC:', ''),
    'The email address provided was not found in our database. Please try another email address.'
) AS inviteCode;
