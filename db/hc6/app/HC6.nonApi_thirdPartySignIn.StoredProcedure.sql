CREATE OR ALTER PROCEDURE [HC6].[nonApi_thirdPartySignIn]
    @provider        NVARCHAR(20)  = NULL,
    @providerUserId  NVARCHAR(255) = NULL,
    @email           NVARCHAR(250) = NULL,
    @emailVerified   SMALLINT      = 0,
    @firstName       NVARCHAR(250) = NULL,
    @lastName        NVARCHAR(250) = NULL,
    @hcVersion       NVARCHAR(50)  = NULL
AS
-- =====================================================================
-- Procedure: HC6.nonApi_thirdPartySignIn
-- Description: Sign in with Apple / Google, the verified rebuild (E1.F1.S8,
--   James 2026-10-17). Called ONLY by the API's ThirdPartySignIn endpoint
--   AFTER it has verified the provider's signed identity token (signature,
--   issuer, audience, expiry, nonce): @provider, @providerUserId and
--   @email/@emailVerified come from inside that token, never from the
--   phone. Finds the hasher —
--     1. already linked to this provider id (ThirdPartyLoginType/UserId);
--     2. else the live hasher whose email is the provider's VERIFIED email
--        (proof of the mailbox, as strong as the emailed code), linking it;
--     3. else a new hasher (names from the app: Apple sends them only on
--        the first authorisation; email the provider's, or a generated one).
--   Returns the hasher's reset code; the app then signs the phone in with
--   it through hcapp_authorizeDevice, exactly as with an emailed code.
--   A removed / deleted account is refused.
-- Parameters: as above. @provider 'apple' | 'google'.
-- Returns: rowset 0 — { Success, ErrorMessage }; rowset 1 (on success) —
--   { ResetCode, IsNewAccount, Linked }.
-- Author: Harrier Central
-- Created: 2026-10-17
-- HC5 Source: none (new; replaces the refused hcapp_processThirdPartyLogin)
-- Breaking Changes: none (new)
-- Idempotency: locked-upsert — an app lock on provider + id serialises a
--   repeat; the second finds the hasher the first created or linked.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);

SET @provider = LOWER(LTRIM(RTRIM(ISNULL(@provider, ''))));
SET @providerUserId = LTRIM(RTRIM(ISNULL(@providerUserId, '')));
SET @email = NULLIF(LOWER(LTRIM(RTRIM(ISNULL(@email, '')))), '');
IF (@provider NOT IN ('apple', 'google') OR LEN(@providerUserId) = 0)
BEGIN
    SELECT 0 AS Success, 'Missing provider identity' AS ErrorMessage;
    RETURN;
END

DECLARE @hasherId UNIQUEIDENTIFIER, @isNew SMALLINT = 0, @linked SMALLINT = 0;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @lock NVARCHAR(255) = LEFT(CONCAT('HC.ThirdPartySignIn:', @provider, ':', @providerUserId), 255);
    EXEC sp_getapplock @Resource = @lock, @LockMode = 'Exclusive', @LockOwner = 'Transaction', @LockTimeout = 15000;

    -- 1. Already linked to this provider id.
    SELECT TOP 1 @hasherId = h.id
    FROM HC.Hasher h WITH (UPDLOCK, HOLDLOCK)
    WHERE h.ThirdPartyLoginType = @provider AND h.ThirdPartyUserId = @providerUserId
    ORDER BY h.LastLoginDateTime DESC;

    -- 2. The live hasher with this VERIFIED email: link it.
    IF (@hasherId IS NULL AND @emailVerified = 1 AND @email IS NOT NULL AND HC6.IsGeneratedEmail(@email) = 0)
    BEGIN
        SELECT TOP 1 @hasherId = h.id
        FROM HC.Hasher h WITH (UPDLOCK, HOLDLOCK)
        WHERE h.Email = @email AND ISNULL(h.Removed, 0) = 0 AND h.deleted = 0
        ORDER BY h.LastLoginDateTime DESC, h.createdAt ASC;
        IF (@hasherId IS NOT NULL)
        BEGIN
            UPDATE HC.Hasher
            SET ThirdPartyLoginType = @provider, ThirdPartyUserId = @providerUserId,
                ThirdPartyEmail = @email, updatedAt = GETDATE()
            WHERE id = @hasherId;
            SET @linked = 1;
        END
    END

    -- 3. A new hasher. The reset code comes from the insert trigger
    -- (trgGenerateQrCode), as for every other new hasher.
    IF (@hasherId IS NULL)
    BEGIN
        SET @hasherId = NEWID();
        DECLARE @accountEmail NVARCHAR(250) =
            CASE WHEN @email IS NOT NULL AND NOT EXISTS (SELECT 1 FROM HC.Hasher x WHERE x.Email = @email)
                 THEN @email
                 ELSE LOWER(CAST(@hasherId AS NVARCHAR(40))) + '@harriercentral.com' END;
        INSERT HC.Hasher (id, FirstName, LastName, Email, HashName, Photo,
                          NameDisplayPreference, IncludeInGlobalHashDirectory, Preferences,
                          ThirdPartyLoginType, ThirdPartyUserId, ThirdPartyEmail, updatedAt)
        VALUES (@hasherId, LEFT(ISNULL(@firstName, ''), 250), LEFT(ISNULL(@lastName, ''), 250),
                @accountEmail, '', '', 2, 0, 14,
                @provider, @providerUserId, @email, GETDATE());
        INSERT HC.LaunchAndLogin (HcVersion, UserId, UserName)
        VALUES (LEFT(ISNULL(@hcVersion, '<unknown>'), 50), @hasherId,
                '+' + COALESCE(NULLIF(LTRIM(RTRIM(CONCAT(@firstName, ' ', @lastName))), ''), '<no name>') + '+');
        SET @isNew = 1;
    END

    IF EXISTS (SELECT 1 FROM HC.Hasher WHERE id = @hasherId AND (ISNULL(Removed, 0) = 1 OR deleted = 1))
    BEGIN
        ROLLBACK TRANSACTION;
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (NEWID(), LEFT(ISNULL(@hcVersion, '<api>'), 50), 'Third-party sign-in to a removed account',
                CONCAT('provider=', @provider), @procName, @hasherId);
        SELECT 0 AS Success, 'This account has been removed. Please contact your kennel.' AS ErrorMessage;
        RETURN;
    END

    COMMIT TRANSACTION;

    SELECT 1 AS Success, NULL AS ErrorMessage;
    SELECT h.ResetCode AS ResetCode, @isNew AS IsNewAccount, @linked AS Linked
    FROM HC.Hasher h WHERE h.id = @hasherId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), LEFT(ISNULL(@hcVersion, '<api>'), 50), 'Unhandled error in nonApi_thirdPartySignIn',
            ERROR_MESSAGE(), @procName, @hasherId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
