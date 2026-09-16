CREATE OR ALTER PROCEDURE [HC6].[publicWeb_recordPasskeyLogin]
    @credentialId NVARCHAR(500),
    @counter      BIGINT
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_recordPasskeyLogin
-- Description: After a passkey assertion verified in the Next.js route:
--              stores the new signature counter (a counter that does not
--              advance is the clone signal, and the route refuses it) and
--              stamps the device's LastLogin plus a LaunchAndLogin row so
--              the Usage Data dashboard sees web sign-ins like any other.
--              Reachable only through PublicWebAdminApi behind
--              HC_INTERNAL_SECRET.
-- Parameters:  @credentialId, @counter
-- Returns:     Write envelope.
-- Author:      Harrier Central
-- Created:     2026-09-16
-- HC5 Source:  none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    DECLARE @userId UNIQUEIDENTIFIER, @hasherName NVARCHAR(250);
    SELECT @userId = d.UserId, @hasherName = COALESCE(h.DisplayName, h.HashName, '')
    FROM HC.Device d INNER JOIN HC.Hasher h ON h.id = d.UserId
    WHERE d.PasskeyCredentialId = @credentialId;

    IF (@userId IS NULL)
    BEGIN
        SELECT 0 AS success, 1211 AS errorCode, 12 AS errorType;
        RETURN;
    END

    BEGIN TRANSACTION;
    UPDATE HC.Device
    SET PasskeyCounter = @counter, LastLogin = SYSDATETIMEOFFSET()
    WHERE PasskeyCredentialId = @credentialId;
    INSERT HC.LaunchAndLogin (HcVersion, UserId, UserName)
    VALUES ('<web>', @userId, '~' + @hasherName + '~');
    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_recordPasskeyLogin', ERROR_MESSAGE(), @procName, NULL);
    SELECT 0 AS success, 1500 AS errorCode, 5 AS errorType;
END CATCH
