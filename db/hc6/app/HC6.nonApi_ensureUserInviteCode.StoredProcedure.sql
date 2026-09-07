CREATE OR ALTER PROCEDURE [HC6].[nonApi_ensureUserInviteCode]
    @userId                   UNIQUEIDENTIFIER,
    @rotateIfOlderThanMinutes INT = NULL
AS
-- =====================================================================
-- Procedure: HC6.nonApi_ensureUserInviteCode
-- Description: Guarantees the hasher holds a COMPLIANT invite code, and
--   optionally rotates it when the current one is older than a given age.
--   Every user is supposed to have a usable code at all times — the app's
--   only account-recovery route is "email me my invite code", so a user
--   without one is locked out of their own account. This SP is the single
--   place that decides what compliant means and mints a replacement.
--
--   Compliant = HC.Hasher.ResetCode matching 'URC:' + exactly six A-Z.
--   Non-compliant covers the cases seen in real data:
--     * the column default '######' (never generated)
--     * NULL or empty
--     * a value with no 'URC:' prefix (legacy rows)
--     * anything not exactly six uppercase letters
--   Previously the code was only regenerated when it was STALE, so a row
--   holding '######' with a recent ResetCodeLastUpdated was handed out
--   as-is — and '######' is six characters, so the caller's length check
--   accepted it and emailed the user a code that could never work.
--
--   Removed accounts are excluded throughout: a deleted account can still
--   hold the address, and stamping a fresh code onto it would both miss the
--   live account and leave a working code pointing at a dead one.
-- Parameters:
--   @userId                   - HC.Hasher.id
--   @rotateIfOlderThanMinutes - NULL (default) = only replace a
--                               non-compliant code. A number also rotates a
--                               compliant code once it is older than that
--                               many minutes (the email path passes 60 as a
--                               spam guard). Pass NULL when the caller must
--                               NOT invalidate a code the user may have just
--                               been sent.
-- Returns: nothing. Read HC.Hasher.ResetCode afterwards.
-- Author: Harrier Central
-- Created: 2026-09-07
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);

BEGIN TRY
    DECLARE @currentCode NVARCHAR(50);
    DECLARE @lastUpdated DATETIMEOFFSET(7);

    SELECT @currentCode = ResetCode,
           @lastUpdated = ResetCodeLastUpdated
    FROM HC.Hasher
    WHERE id = @userId AND Removed = 0;

    -- No live hasher: nothing to do. The caller reports "not found"; this SP
    -- never invents a row.
    IF (@@ROWCOUNT = 0) RETURN;

    -- LIKE with a bracketed range is the whole compliance rule. Collation
    -- could otherwise make [A-Z] match lowercase, so compare the binary form.
    DECLARE @isCompliant SMALLINT =
        CASE WHEN @currentCode COLLATE Latin1_General_BIN
                  LIKE 'URC:[A-Z][A-Z][A-Z][A-Z][A-Z][A-Z]'
             AND LEN(@currentCode) = 10
             THEN 1 ELSE 0 END;

    DECLARE @isStale SMALLINT =
        CASE WHEN @rotateIfOlderThanMinutes IS NOT NULL
              AND (@lastUpdated IS NULL
                   OR ABS(DATEDIFF(minute, @lastUpdated, GETDATE()))
                      > @rotateIfOlderThanMinutes)
             THEN 1 ELSE 0 END;

    IF (@isCompliant = 1 AND @isStale = 0) RETURN;

    -- Generate a new unique 6-letter uppercase code.
    -- Codespace = 26^6 ~ 309 million; collision rate is negligible.
    DECLARE @alphabet NCHAR(26) = N'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    DECLARE @code     NVARCHAR(6);
    DECLARE @attempt  SMALLINT = 0;
    DECLARE @assigned SMALLINT = 0;

    WHILE (@attempt < 10 AND @assigned = 0)
    BEGIN
        SET @attempt += 1;
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
            WHERE  id = @userId AND Removed = 0;
            SET @assigned = 1;
        END
    END

    -- Ten collisions in a 309-million codespace is effectively impossible, so
    -- if it happens something is wrong (a corrupt alphabet, a broken NEWID).
    -- Log it: the user would otherwise be handed the same unusable code again
    -- with nothing recorded anywhere.
    IF (@assigned = 0)
    BEGIN
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (NEWID(), '<unknown>', 'Invite code generation exhausted',
                'Ten consecutive collisions generating an invite code',
                @procName, @userId);
    END
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_ensureUserInviteCode',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH;
