CREATE OR ALTER PROCEDURE [HC6].[publicWeb_setKennelFollowing]
    @deviceId       UNIQUEIDENTIFIER,
    @accessToken    NVARCHAR(1000),
    @publicKennelId UNIQUEIDENTIFIER,
    @following      SMALLINT
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_setKennelFollowing
-- Description: Follow or unfollow a kennel from the web (E9.F7.S9).
--              The app's own hcapp_joinKennel, self-mode: the caller is
--              the target, only @isFollowing is passed, so none of the
--              role/flag paths (which have their own permission checks)
--              are reachable from here. The wrapper maps PublicKennelId
--              and finds the caller from the device row; the inner SP
--              validates the token (generated for 'hcapp_joinKennel').
-- Parameters:  @deviceId / @accessToken, @publicKennelId, @following 0|1
-- Returns:     hcapp_joinKennel's rowsets (0 = envelope), or this SP's
--              error envelope for an unknown kennel.
-- Author:      Harrier Central
-- Created:     2026-09-16
-- HC5 Source:  none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    DECLARE @kennelId UNIQUEIDENTIFIER, @userId UNIQUEIDENTIFIER;
    SELECT @kennelId = k.id FROM HC.Kennel k
    WHERE k.PublicKennelId = @publicKennelId AND k.deleted = 0 AND k.removed = 0;
    SELECT @userId = d.UserId FROM HC.Device d WHERE d.id = @deviceId AND d.removed = 0;

    IF (@kennelId IS NULL OR @userId IS NULL OR @following NOT IN (0, 1))
    BEGIN
        DECLARE @errorId UNIQUEIDENTIFIER = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
        VALUES (@errorId, '<web>', 'Kennel not found or bad request',
                'publicKennelId=' + CAST(@publicKennelId AS NVARCHAR(40)) + ' following=' + CAST(@following AS NVARCHAR(10)),
                @procName, @userId, @deviceId);
        SELECT 0 AS success, 1230 AS errorCode, 12 AS errorType;
        SELECT @errorId AS errorId, 12 AS errorType, 1230 AS errorCode,
               'Kennel not found' AS errorTitle, 'That kennel could not be found.' AS errorUserMessage, @procName AS errorProc;
        RETURN;
    END

    EXEC HC6.hcapp_joinKennel
        @deviceId                    = @deviceId,
        @accessToken                 = @accessToken,
        @kennelId                    = @kennelId,
        @targetUserId                = @userId,
        @isFollowing                 = @following,
        @kennelsUpdatedAfter         = '2050-01-01',
        @hasherKennelMapUpdatedAfter = '2050-01-01',
        @hashersUpdatedAfter         = 'ignore';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_setKennelFollowing', ERROR_MESSAGE(), @procName, NULL, @deviceId);
    SELECT 0 AS success, 1500 AS errorCode, 5 AS errorType;
END CATCH
