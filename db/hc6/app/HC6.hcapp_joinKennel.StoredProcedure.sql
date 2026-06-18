CREATE OR ALTER PROCEDURE [HC6].[hcapp_joinKennel]

    @deviceId                    UNIQUEIDENTIFIER,
    @accessToken                 NVARCHAR(1000),
    @kennelId                    UNIQUEIDENTIFIER,
    @targetUserId                UNIQUEIDENTIFIER,
    @isFollowing                 SMALLINT         = NULL,
    @isHomeKennel                SMALLINT         = NULL,
    @notificationState           SMALLINT         = NULL,
    @emailAlertState             SMALLINT         = NULL,
    @monthsToAddToMembership     SMALLINT         = NULL,
    @appAccessFlags              INT              = NULL,
    @mismanagementRoles          INT              = NULL,
    @paymentAmount               DECIMAL(12,6)    = NULL,
    @kennelsUpdatedAfter         NVARCHAR(50),
    @hasherKennelMapUpdatedAfter NVARCHAR(50),
    @hashersUpdatedAfter         NVARCHAR(50)     = 'ignore'

AS
-- =====================================================================
-- Procedure: HC6.hcapp_joinKennel
-- Description: Creates or updates a HasherKennelMap row, managing
--   kennel follow state, home kennel assignment, membership duration,
--   notification preferences, access flags, and mismanagement roles.
--   Supports two modes: the calling user managing their own membership
--   (delegates to syncUserData), or an admin managing another user's
--   membership (delegates to syncKennelAdminData).
--
--   @monthsToAddToMembership sentinels:
--     NULL / 0  = no change
--     9999      = set to permanent (expiry = 2100-01-01)
--    -9999      = revoke membership (expiry = NULL, IsMember = 0)
--    +n         = add n months to expiry (or from today if expired/new)
--
--   @isFollowing = 0 or 2, or @isHomeKennel = 0 clears the home kennel.
--   @isHomeKennel = 1 sets home kennel and implies isFollowing = 1.
--   @appAccessFlags is synced to both AppAccessFlags and HcWebPermissionFlags.
-- Parameters:
--   @deviceId                    - Registered device UUID
--   @accessToken                 - Token validated against DeviceSecret
--   @kennelId                    - Kennel UUID
--   @targetUserId                - Target hasher (may differ from caller for admin ops)
--   @isFollowing                 - 1=follow, 0/2=unfollow; -1=keep
--   @isHomeKennel                - 1=set home, 0=unset; -1=keep
--   @notificationState           - Notification preference; -1=keep
--   @emailAlertState             - Email alert preference; -1=keep
--   @monthsToAddToMembership     - See sentinels above; 0=no change
--   @appAccessFlags              - Permission bitmask; -1=keep
--   @mismanagementRoles          - Role bitmask; -1=keep
--   @kennelsUpdatedAfter         - Sync watermark for Kennels
--   @hasherKennelMapUpdatedAfter - Sync watermark for HasherKennelMap
--   @hashersUpdatedAfter         - Sync watermark for Hashers
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): { adHocDataId, following, kennelNotificationPreference,
--                             kennelEmailAlertPreference, isHomeKennel }
--   On success (rowset 2+): sync SP rowsets
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_joinKennel
-- Breaking Changes:
--   TRY/CATCH and transaction added (HC5 had neither).
--   Success envelope added.
--   Delegation targets updated to HC6 SPs.
--   HC3.vwMmByKennel inlined: logic now expressed as a direct join against
--     HC.HasherKennelMap, HC.Hasher, and DomainValues.MismanagementRoles.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);

-- Normalise sentinels before auth
IF (@isFollowing              = -1) SET @isFollowing              = NULL;
IF (@isHomeKennel             = -1) SET @isHomeKennel             = NULL;
IF (@monthsToAddToMembership  =  0) SET @monthsToAddToMembership  = NULL;
IF (@notificationState        = -1) SET @notificationState        = NULL;
IF (@emailAlertState          = -1) SET @emailAlertState          = NULL;
IF (@appAccessFlags           = -1) SET @appAccessFlags           = NULL;
IF (@mismanagementRoles       = -1) SET @mismanagementRoles       = NULL;
IF (@hashersUpdatedAfter IS NULL)   SET @hashersUpdatedAfter      = 'ignore';

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 50,
    @param        = NULL,
    @userId       = @userId       OUTPUT,
    @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow   = @timeWindow   OUTPUT,
    @errorCode    = @errorCode    OUTPUT,
    @errorType    = @errorType    OUTPUT,
    @errorId      = @errorId      OUTPUT,
    @errorTitle   = @errorTitle   OUTPUT,
    @errorMsg     = @errorMsg     OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

IF (@kennelId IS NULL OR @kennelId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1250; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null or empty kennelId', 'kennelId is required', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing kennel' AS errorTitle, 'A kennel must be specified.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

-- isHomeKennel = 1 implies following
IF (@isHomeKennel = 1) SET @isFollowing = 1;

BEGIN TRY
    BEGIN TRANSACTION;

        -- ---------------------------------------------------------------
        -- Clear home kennel when unfollowing or removing home designation
        -- ---------------------------------------------------------------
        IF (@isFollowing = 0 OR @isFollowing = 2 OR @isHomeKennel = 0)
        BEGIN
            IF EXISTS (SELECT 1 FROM HC.Hasher WHERE id = @targetUserId AND HomeKennelId = @kennelId)
            BEGIN
                UPDATE HC.Hasher SET HomeKennelId = NULL, updatedAt = GETDATE()
                WHERE id = @targetUserId AND HomeKennelId = @kennelId;

                UPDATE HC.HasherKennelMap SET IsHomeKennel = 0, updatedAt = GETDATE()
                WHERE UserId = @targetUserId AND KennelId = @kennelId;
            END
        END

        -- ---------------------------------------------------------------
        -- Set home kennel (clear any other home kennel first)
        -- ---------------------------------------------------------------
        IF (@isHomeKennel = 1)
        BEGIN
            UPDATE HC.Hasher SET HomeKennelId = @kennelId, updatedAt = GETDATE()
            WHERE id = @targetUserId;

            UPDATE HC.HasherKennelMap SET IsHomeKennel = 0, updatedAt = GETDATE()
            WHERE UserId = @targetUserId AND IsHomeKennel != 0;
        END

        -- ---------------------------------------------------------------
        -- Upsert HasherKennelMap
        -- ---------------------------------------------------------------
        DECLARE @hkmId              UNIQUEIDENTIFIER;
        DECLARE @isMember           SMALLINT;
        DECLARE @newExpirationDate  DATETIMEOFFSET(7);
        DECLARE @memberSince        DATETIMEOFFSET(7);

        SELECT @hkmId = id FROM HC.HasherKennelMap WHERE UserId = @targetUserId AND KennelId = @kennelId;

        IF (@hkmId IS NULL)
        BEGIN
            SET @isMember = 0;

            IF (@monthsToAddToMembership IS NOT NULL AND @monthsToAddToMembership > 0)
            BEGIN
                SET @isMember          = 1;
                SET @newExpirationDate = DATEADD(MONTH, @monthsToAddToMembership, GETDATE());
                SET @memberSince       = GETDATE();
            END

            SET @hkmId = NEWID();

            INSERT INTO HC.HasherKennelMap
                ([id], [UserId], [KennelId], [Following], [IsMember],
                 [MembershipExpirationDate], [MemberSince], [IsHomeKennel],
                 [AppAccessFlags], [HcWebPermissionFlags], [MismanagementRoles],
                 [KennelNotificationPreference], [KennelEmailAlertPreference], [updatedAt])
            VALUES
                (@hkmId, @targetUserId, @kennelId,
                 COALESCE(@isFollowing, 0), COALESCE(@isMember, 0),
                 @newExpirationDate, @memberSince,
                 COALESCE(@isHomeKennel, 0),
                 COALESCE(@appAccessFlags, 0),
                 COALESCE(@appAccessFlags, 0),
                 COALESCE(@mismanagementRoles, 0),
                 COALESCE(@notificationState, 0),
                 COALESCE(@emailAlertState, 0),
                 GETDATE());
        END
        ELSE
        BEGIN
            UPDATE HC.HasherKennelMap SET
                [Following]                  = COALESCE(@isFollowing, [Following]),
                [IsMember]                   = CASE
                    WHEN @monthsToAddToMembership IS NULL  THEN IsMember
                    WHEN @monthsToAddToMembership = -9999  THEN 0
                    WHEN DATEADD(MONTH, @monthsToAddToMembership, COALESCE(MembershipExpirationDate, GETDATE())) > GETDATE() THEN 1
                    ELSE 0
                    END,
                [IsHomeKennel]               = COALESCE(@isHomeKennel, IsHomeKennel),
                [AppAccessFlags]             = COALESCE(@appAccessFlags, AppAccessFlags),
                [HcWebPermissionFlags]       = COALESCE(@appAccessFlags, HcWebPermissionFlags),
                [MismanagementRoles]         = COALESCE(@mismanagementRoles, MismanagementRoles),
                [KennelNotificationPreference] = COALESCE(@notificationState, KennelNotificationPreference, 0),
                [KennelEmailAlertPreference]   = COALESCE(@emailAlertState,   KennelEmailAlertPreference,   0),
                [MembershipExpirationDate]   = CASE
                    WHEN @monthsToAddToMembership = 9999  THEN '2100-01-01'
                    WHEN @monthsToAddToMembership = -9999 THEN NULL
                    WHEN @monthsToAddToMembership IS NULL  THEN MembershipExpirationDate
                    WHEN (MembershipExpirationDate < GETDATE() OR MembershipExpirationDate IS NULL)
                        THEN DATEADD(MONTH, @monthsToAddToMembership, GETDATE())
                    ELSE DATEADD(MONTH, @monthsToAddToMembership, MembershipExpirationDate)
                    END,
                [MemberSince]                = CASE
                    WHEN MemberSince IS NOT NULL THEN
                        CASE WHEN @monthsToAddToMembership = -9999 THEN NULL ELSE MemberSince END
                    ELSE
                        CASE WHEN @monthsToAddToMembership IS NULL OR @monthsToAddToMembership <= 0 THEN NULL ELSE GETDATE() END
                    END,
                [updatedAt]                  = GETDATE()
            WHERE id = @hkmId;
        END

        -- Update kennel mismanagement team string when roles change
        IF (@mismanagementRoles IS NOT NULL)
        BEGIN
            DECLARE @mmRoles NVARCHAR(4000);
            SELECT @mmRoles = STRING_AGG(mr.RoleName + CHAR(9) + REPLACE(h.DisplayName, '"', '\"'), CHAR(13))
                              WITHIN GROUP (ORDER BY mr.id)
            FROM   HC.HasherKennelMap hkm
            JOIN   HC.Hasher h                        ON h.id            = hkm.UserId
            JOIN   DomainValues.MismanagementRoles mr ON (hkm.MismanagementRoles & mr.BitFlags) != 0
            WHERE  hkm.KennelId = @kennelId
              AND  mr.id        != 1;

            UPDATE HC.Kennel SET
                KennelMismanagementTeam = @mmRoles,
                updatedAt               = GETDATE()
            WHERE id = @kennelId;
        END

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    SELECT
        1                                                                  AS adHocDataId,
        hkm.Following                                                      AS following,
        hkm.KennelNotificationPreference                                   AS kennelNotificationPreference,
        hkm.KennelEmailAlertPreference                                     AS kennelEmailAlertPreference,
        CASE WHEN hkm.KennelId = h.HomeKennelId THEN 1 ELSE 0 END         AS isHomeKennel
    FROM HC.HasherKennelMap hkm
    INNER JOIN HC.Hasher h ON h.id = hkm.UserId
    WHERE hkm.id = @hkmId;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1950; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END CATCH;

-- ---------------------------------------------------------------
-- Delegate to sync SP (outside TRY — runs after commit)
-- ---------------------------------------------------------------
SET @kennelsUpdatedAfter         = COALESCE(@kennelsUpdatedAfter,         'ignore');
SET @hasherKennelMapUpdatedAfter = COALESCE(@hasherKennelMapUpdatedAfter, 'ignore');

IF (@targetUserId IS NULL OR @targetUserId = @userId)
BEGIN
    EXEC HC6.hcapp_syncUserData
        @deviceId                    = @deviceId,
        @accessToken                 = @accessToken,
        @hashersUpdatedAfter         = @hashersUpdatedAfter,
        @kennelsUpdatedAfter         = @kennelsUpdatedAfter,
        @hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
        @hasherEventMapUpdatedAfter  = 'ignore',
        @narrowEventsUpdatedAfter    = 'ignore',
        @usePaging                   = 0,
        @procName                    = @procName,
        @param                       = NULL;
END
ELSE
BEGIN
    EXEC HC6.hcapp_syncKennelAdminData
        @deviceId                    = @deviceId,
        @accessToken                 = @accessToken,
        @kennelId                    = @kennelId,
        @hashersUpdatedAfter         = @hashersUpdatedAfter,
        @kennelsUpdatedAfter         = @kennelsUpdatedAfter,
        @hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
        @procName                    = @procName,
        @param                       = NULL;
END
