CREATE OR ALTER PROCEDURE [HC6].[publicWeb_createMember]
    @email      NVARCHAR(250),
    @hashName   NVARCHAR(250),
    @firstName  NVARCHAR(250) = NULL,
    @lastName   NVARCHAR(250) = NULL,
    @kennelSlug NVARCHAR(100) = NULL
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_createMember
-- Description: A hasher whose email the kennel never recorded becomes a
--              member by answering the run notice (E9.F7.S3). This is the
--              app's own self-signup — hcapp_addEditUser in new-user mode
--              (no device, creation only) — with the kennel resolved from
--              the slug whose link was tapped, and following it. The email
--              is NOT yet proven at this point: the web then sends the
--              invite code to it and the browser is only provisioned as a
--              device once the code comes back (hcapp_authorizeDevice),
--              exactly as the app's flow. Reachable only through
--              PublicWebAdminApi behind HC_INTERNAL_SECRET.
-- Parameters:  @email, @hashName (required), @firstName, @lastName,
--              @kennelSlug (HC.Kennel.KennelUniqueShortName)
-- Returns:     hcapp_addEditUser's rowsets (0 = envelope, 1 = profile), or
--              this SP's own error envelope for a bad request.
-- Author:      Harrier Central
-- Created:     2026-09-16
-- HC5 Source:  none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    IF (LEN(COALESCE(@email, '')) < 5 OR LEN(COALESCE(@hashName, '')) = 0)
    BEGIN
        SELECT 0 AS success, 1220 AS errorCode, 2 AS errorType;
        SELECT NEWID() AS errorId, 2 AS errorType, 1220 AS errorCode,
               'Missing details' AS errorTitle, 'An email address and a hash name are needed.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM HC.Hasher WHERE Email = @email AND Removed = 0)
    BEGIN
        -- Contractual duplicate-email answer, the same code the app's signup
        -- reads (project_signup_duplicate_email_flow).
        SELECT 0 AS success, 10005 AS errorCode, 2 AS errorType;
        SELECT NEWID() AS errorId, 2 AS errorType, 10005 AS errorCode,
               'Email already registered' AS errorTitle,
               'That email address already has an account — sign in with a code instead.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END

    DECLARE @kennelId UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000';
    IF (@kennelSlug IS NOT NULL)
        SELECT @kennelId = k.id FROM HC.Kennel k
        WHERE LOWER(k.KennelUniqueShortName) = LOWER(@kennelSlug) AND k.deleted = 0;
    SET @kennelId = COALESCE(@kennelId, '00000000-0000-0000-0000-000000000000');

    EXEC HC6.hcapp_addEditUser
        @deviceId                    = NULL,
        @accessToken                 = '',
        @hcVersion                   = '<web>',
        @hashersUpdatedAfter         = '2050-01-01',
        @hasherEventMapUpdatedAfter  = '2050-01-01',
        @hasherKennelMapUpdatedAfter = '2050-01-01',
        @targetUserId                = '00000000-0000-0000-0000-000000000000',
        @email                       = @email,
        @firstName                   = @firstName,
        @lastName                    = @lastName,
        @hashName                    = @hashName,
        @kennelId                    = @kennelId,
        @followKennelOnAddNewUser    = 1;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_createMember', ERROR_MESSAGE(), @procName, NULL);
    SELECT 0 AS success, 1500 AS errorCode, 5 AS errorType;
END CATCH
