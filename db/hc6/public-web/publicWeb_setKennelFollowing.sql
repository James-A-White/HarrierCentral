-- =====================================================================
-- Procedure: HC6.publicWeb_setKennelFollowing
-- Description: A web member's follow / home-kennel choice for one kennel —
--   the app's kennel card popup (Always show runs = 1, Never show runs = 2,
--   Show runs within N km = 0, Set / Clear home kennel) — through the app's
--   own hcapp_joinKennel in self mode. The token is signed for
--   hcapp_joinKennel; this wrapper only resolves the public id.
-- Parameters: @publicKennelId; @following 0|1|2 (NULL = keep);
--   @isHomeKennel 1 set / 0 clear (NULL = keep)
-- Returns: hcapp_joinKennel's envelope and rowsets
-- Author: Harrier Central
-- Created: 2026-09-16   v2 2026-09-17 (follow type 0/1/2, home kennel)
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[publicWeb_setKennelFollowing]
    @deviceId       UNIQUEIDENTIFIER,
    @accessToken    NVARCHAR(1000),
    @publicKennelId UNIQUEIDENTIFIER,
    @following      SMALLINT = NULL,
    @isHomeKennel   SMALLINT = NULL
AS
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    DECLARE @kennelId UNIQUEIDENTIFIER, @userId UNIQUEIDENTIFIER;
    SELECT @kennelId = k.id FROM HC.Kennel k
    WHERE k.PublicKennelId = @publicKennelId AND k.deleted = 0 AND k.removed = 0;
    SELECT @userId = d.UserId FROM HC.Device d WHERE d.id = @deviceId AND d.removed = 0;

    IF (@kennelId IS NULL OR @userId IS NULL
        OR (@following IS NOT NULL AND @following NOT IN (0, 1, 2))
        OR (@isHomeKennel IS NOT NULL AND @isHomeKennel NOT IN (0, 1))
        OR (@following IS NULL AND @isHomeKennel IS NULL))
    BEGIN
        DECLARE @errorId UNIQUEIDENTIFIER = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, deviceId)
        VALUES (@errorId, '<web>', 'Kennel not found or bad request',
                'publicKennelId=' + CAST(@publicKennelId AS NVARCHAR(40))
                + ' following=' + COALESCE(CAST(@following AS NVARCHAR(10)), 'null')
                + ' isHomeKennel=' + COALESCE(CAST(@isHomeKennel AS NVARCHAR(10)), 'null'),
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
        @isHomeKennel                = @isHomeKennel,
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
GO
