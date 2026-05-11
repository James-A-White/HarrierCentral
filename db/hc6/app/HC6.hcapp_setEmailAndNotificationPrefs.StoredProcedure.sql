CREATE OR ALTER PROCEDURE [HC6].[hcapp_setEmailAndNotificationPrefs]

    @deviceId                      UNIQUEIDENTIFIER,
    @accessToken                   NVARCHAR(1000),
    @hasherId                      UNIQUEIDENTIFIER,
    @emailPreference               INT             = -1,
    @notificationPreference        INT             = -1,
    @kennelId                      UNIQUEIDENTIFIER = NULL,
    @eventId                       UNIQUEIDENTIFIER = NULL,
    @hasherEventMapUpdatedAfter    NVARCHAR(50),
    @hasherKennelMapUpdatedAfter   NVARCHAR(50)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_setEmailAndNotificationPrefs
-- Description: Sets email alert and/or push notification preferences for
--   a Hasher at either kennel or event scope. When @eventId is provided
--   the preference is event-scoped (HasherEventMap); otherwise it is
--   kennel-scoped (HasherKennelMap). A preference value of -1 means
--   "do not change". A preference value of 0 on an event-scoped row
--   means "inherit from kennel" and is stored as NULL in HasherEventMap.
--   Upserts the relevant map row then delegates to syncUserData.
-- Parameters:
--   @deviceId                    - Registered device UUID
--   @accessToken                 - Token validated against DeviceSecret
--   @hasherId                    - Target Hasher.id (defaults to caller if NULL)
--   @emailPreference             - New email pref; -1 = no change
--   @notificationPreference      - New notification pref; -1 = no change
--   @kennelId                    - Kennel scope (looked up from eventId if NULL)
--   @eventId                     - Event scope (mutually exclusive with kennelId-only)
--   @hasherEventMapUpdatedAfter  - Sync watermark for HasherEventMap
--   @hasherKennelMapUpdatedAfter - Sync watermark for HasherKennelMap
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): { adHocDataId, notificationPreference, emailAlertPreference }
--   On success (rowset 2+): syncUserData rowsets
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_setEmailAndNotificationPrefs
-- Breaking Changes:
--   Transaction added for upsert (HC5 had none).
--   errorType for auth failure corrected to 1 (HC5 used 3 — bug).
--   Delegation target updated to HC6.hcapp_syncUserData.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 14,
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

-- ---------------------------------------------------------------
-- Normalise sentinels and defaults
-- ---------------------------------------------------------------
IF (@hasherId IS NULL OR @hasherId = '00000000-0000-0000-0000-000000000000')
    SET @hasherId = @userId;

IF (@emailPreference          = -1) SET @emailPreference          = NULL;
IF (@notificationPreference   = -1) SET @notificationPreference   = NULL;

IF ((@eventId  IS NULL OR @eventId  = '00000000-0000-0000-0000-000000000000')
AND (@kennelId IS NULL OR @kennelId = '00000000-0000-0000-0000-000000000000'))
BEGIN
    SET @errorCode = 1214; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Missing scope parameter',
            'Both @kennelId and @eventId are null or empty', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing scope parameter' AS errorTitle,
           'Either a kennel or event must be specified.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

IF (@eventId = '00000000-0000-0000-0000-000000000000') SET @eventId = NULL;
IF (@kennelId = '00000000-0000-0000-0000-000000000000') SET @kennelId = NULL;

BEGIN TRY
    BEGIN TRANSACTION;

        -- Resolve @kennelId from @eventId when not supplied
        IF (@kennelId IS NULL AND @eventId IS NOT NULL)
            SELECT @kennelId = evt.KennelId FROM HC.Event evt WHERE evt.id = @eventId;

        -- ---------------------------------------------------------------
        -- Upsert kennel-scoped preferences
        -- ---------------------------------------------------------------
        IF (@eventId IS NULL)
        BEGIN
            DECLARE @hkmId UNIQUEIDENTIFIER;
            SELECT @hkmId = hkm.id
            FROM HC.HasherKennelMap hkm
            WHERE hkm.KennelId = @kennelId AND hkm.UserId = @hasherId;

            IF (@hkmId IS NULL)
            BEGIN
                INSERT INTO HC.HasherKennelMap
                    ([id], [UserId], [KennelId],
                     [KennelNotificationPreference], [KennelEmailAlertPreference], [updatedAt])
                VALUES
                    (NEWID(), @hasherId, @kennelId,
                     COALESCE(@notificationPreference, 0),
                     COALESCE(@emailPreference, 0),
                     GETDATE());
            END
            ELSE
            BEGIN
                UPDATE HC.HasherKennelMap SET
                    KennelEmailAlertPreference    = COALESCE(@emailPreference,       KennelEmailAlertPreference),
                    KennelNotificationPreference  = COALESCE(@notificationPreference, KennelNotificationPreference),
                    updatedAt                     = GETDATE()
                WHERE id = @hkmId;
            END
        END

        -- ---------------------------------------------------------------
        -- Upsert event-scoped preferences
        -- 0 = "inherit from kennel" → stored as NULL in HasherEventMap
        -- ---------------------------------------------------------------
        ELSE
        BEGIN
            DECLARE @hemId UNIQUEIDENTIFIER;
            SELECT @hemId = hem.id
            FROM HC.HasherEventMap hem
            WHERE hem.EventId = @eventId AND hem.UserId = @hasherId;

            IF (@hemId IS NULL)
            BEGIN
                INSERT INTO HC.HasherEventMap
                    ([id], [EventId], [KennelId], [UserId],
                     [EventNotificationPreference], [EventEmailAlertPreference], [updatedAt])
                VALUES
                    (NEWID(), @eventId, @kennelId, @hasherId,
                     CASE WHEN @notificationPreference = 0 THEN NULL ELSE @notificationPreference END,
                     CASE WHEN @emailPreference        = 0 THEN NULL ELSE @emailPreference        END,
                     GETDATE());
            END
            ELSE
            BEGIN
                UPDATE HC.HasherEventMap SET
                    EventEmailAlertPreference   = CASE WHEN @emailPreference        = 0 THEN NULL ELSE COALESCE(@emailPreference,        EventEmailAlertPreference)   END,
                    EventNotificationPreference = CASE WHEN @notificationPreference = 0 THEN NULL ELSE COALESCE(@notificationPreference, EventNotificationPreference) END,
                    updatedAt                   = GETDATE()
                WHERE id = @hemId;
            END
        END

    COMMIT TRANSACTION;

    -- ---------------------------------------------------------------
    -- Read back effective preferences for immediate UI update
    -- ---------------------------------------------------------------
    DECLARE @outNotificationPref INT;
    DECLARE @outEmailPref        INT;

    IF (@eventId IS NOT NULL)
        SELECT
            @outNotificationPref = COALESCE(hem.EventNotificationPreference, hkm.KennelNotificationPreference),
            @outEmailPref        = COALESCE(hem.EventEmailAlertPreference,   hkm.KennelEmailAlertPreference)
        FROM HC.HasherEventMap hem
        INNER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = hem.KennelId AND hkm.UserId = hem.UserId
        WHERE hem.UserId = @hasherId AND hem.EventId = @eventId;
    ELSE
        SELECT
            @outNotificationPref = hkm.KennelNotificationPreference,
            @outEmailPref        = hkm.KennelEmailAlertPreference
        FROM HC.HasherKennelMap hkm
        WHERE hkm.UserId = @hasherId AND hkm.KennelId = @kennelId;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    SELECT
        1                    AS adHocDataId,
        @outNotificationPref AS notificationPreference,
        @outEmailPref        AS emailAlertPreference;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1914; SET @errorType = 19; SET @errorId = NEWID();
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
-- Delegate to syncUserData (outside TRY — runs after commit)
-- ---------------------------------------------------------------
SET @hasherKennelMapUpdatedAfter = COALESCE(@hasherKennelMapUpdatedAfter, 'ignore');
SET @hasherEventMapUpdatedAfter  = COALESCE(@hasherEventMapUpdatedAfter,  'ignore');

EXEC HC6.hcapp_syncUserData
    @deviceId                    = @deviceId,
    @accessToken                 = @accessToken,
    @hashersUpdatedAfter         = 'ignore',
    @hasherEventMapUpdatedAfter  = @hasherEventMapUpdatedAfter,
    @hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
    @narrowEventsUpdatedAfter    = 'ignore',
    @usePaging                   = 0,
    @procName                    = @procName,
    @param                       = NULL;
