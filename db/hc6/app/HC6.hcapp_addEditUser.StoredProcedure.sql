CREATE OR ALTER PROCEDURE [HC6].[hcapp_addEditUser]

    @deviceId              UNIQUEIDENTIFIER = NULL,
    @accessToken           NVARCHAR(1000),
    @hcVersion             NVARCHAR(50),
    @hashersUpdatedAfter   NVARCHAR(50),
    @hasherEventMapUpdatedAfter NVARCHAR(50),
    @hasherKennelMapUpdatedAfter NVARCHAR(50),
    @targetUserId          UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000',
    @email                 NVARCHAR(250)    = NULL,
    @firstName             NVARCHAR(250)    = NULL,
    @lastName              NVARCHAR(250)    = NULL,
    @hashName              NVARCHAR(250)    = NULL,
    @photo                 NVARCHAR(1000)   = NULL,
    @includeInGlobalHashDirectory INT       = NULL,
    @preferences           INT              = NULL,
    @eventId               UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000',
    @kennelId              UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000',
    @historicalTotalRunCount INT            = NULL,
    @historicalHaringCount   INT            = NULL,
    @historicalCountIsEstimate INT          = NULL,
    @followKennelOnAddNewUser  INT          = NULL,
    @latitude              DECIMAL(18,15)   = 0,
    @longitude             DECIMAL(19,15)   = 0,
    @nameDisplayPreference INT              = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_addEditUser
-- Description: Creates or updates a Hasher record. Dual-mode:
--   - New user (@deviceId IS NULL): creates a Hasher without a device
--     record (first-app-launch flow). Returns the new profile directly.
--   - Edit user (@deviceId provided): updates the calling user's own
--     record or a target user's record (admin editing). Token is
--     validated against DeviceSecret + UPPER(@targetUserId). After the
--     write, delegates to the appropriate sync SP.
--   Checks for duplicate email before insert/update.
-- Parameters:
--   @deviceId              - NULL for new-user creation mode
--   @accessToken           - Token validated against DeviceSecret + UPPER(targetUserId)
--   @hcVersion             - App version string
--   @hashersUpdatedAfter   - Sync cursor (passed to child sync SP)
--   @hasherEventMapUpdatedAfter - Sync cursor
--   @hasherKennelMapUpdatedAfter - Sync cursor
--   @targetUserId          - User to create/edit. Null-UUID = insert mode.
--   @email/@firstName/@lastName/@hashName/@photo - Profile fields
--   @includeInGlobalHashDirectory - NULL/-1 = don't update
--   @preferences           - Bitfield. NULL/-1 = don't update
--   @eventId               - When provided, adds new user to this event
--   @kennelId              - When provided, may follow this kennel
--   @historicalTotalRunCount / @historicalHaringCount - NULL/-1 = don't update
--   @historicalCountIsEstimate - Whether historical counts are estimates
--   @followKennelOnAddNewUser - Non-zero = create HasherKennelMap on insert
--   @latitude / @longitude - Used for USA miles detection on new user
--   @nameDisplayPreference - 1=hash name first, 2=real name first. NULL/≤0 = don't update
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   New-user mode success: HasherProfile rowset (rowset 1)
--   Edit mode success: sync SP result sets
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_addEditUser
-- Breaking Changes:
--   @deviceId type NVARCHAR(100) -> UNIQUEIDENTIFIER (NULL when no device).
--   @firstName/@lastName/@hashName widened NVARCHAR(100) -> NVARCHAR(250).
--   @photo widened NVARCHAR(500) -> NVARCHAR(1000).
--   @historicalPackRunCount removed (deprecated Nov 2021, dead parameter).
--   errorType 1 for auth failure (was non-standard 1 in HC5 — unchanged).
--   errorType 10005 for duplicate email is PRESERVED from HC5 -- the app's
--     DB_ERROR_EMAIL_ALREADY_EXISTS constant is 10005 and an errorType is part
--     of the published contract. errorCode 1510 is added alongside it.
--   Duplicate-email check now ignores removed accounts, so someone whose old
--     account was deleted can register the same address again.
--   Success envelope added. TRY/CATCH added.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;

-- ---------------------------------------------------------------
-- Detect USA for default preferences on new user
-- ---------------------------------------------------------------
DECLARE @useUsaMiles SMALLINT = 0;
IF ((@latitude BETWEEN 24.74 AND 49.35) AND (@longitude BETWEEN -124.78 AND -66.95)) SET @useUsaMiles = 1;
IF ((@latitude BETWEEN 51.21 AND 71.37) AND (@longitude BETWEEN -180   AND -179.15)) SET @useUsaMiles = 1;
IF ((@latitude BETWEEN 51.21 AND 71.37) AND (@longitude BETWEEN 179.78 AND  180   )) SET @useUsaMiles = 1;
IF ((@latitude BETWEEN 18.91 AND 28.40) AND (@longitude BETWEEN -178.33 AND -154.81)) SET @useUsaMiles = 1;

-- Null-UUID normalisation
IF (@targetUserId = '00000000-0000-0000-0000-000000000000') SET @targetUserId = NULL;
IF (@eventId      = '00000000-0000-0000-0000-000000000000') SET @eventId = NULL;
IF (@kennelId     = '00000000-0000-0000-0000-000000000000') SET @kennelId = NULL;

-- Sentinel normalisation
IF (LEN(@firstName) = 0) SET @firstName = NULL;
IF (LEN(@lastName)  = 0) SET @lastName  = NULL;
IF (LEN(@email)     = 0) SET @email     = NULL;
IF (LEN(@hashName)  = 0) SET @hashName  = NULL;
IF (LEN(@photo)     = 0) SET @photo     = NULL;
IF (@historicalTotalRunCount  = -1) SET @historicalTotalRunCount  = NULL;
IF (@historicalHaringCount    = -1) SET @historicalHaringCount    = NULL;
IF (@includeInGlobalHashDirectory = -1) SET @includeInGlobalHashDirectory = NULL;
IF (@preferences                  = -1) SET @preferences = NULL;
IF (@nameDisplayPreference       <= 0)  SET @nameDisplayPreference = NULL;

-- ---------------------------------------------------------------
-- Resolve caller (device mode vs new-user mode)
-- ---------------------------------------------------------------
DECLARE @isNewUserMode SMALLINT = 0;
DECLARE @userId       UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000';
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;
DECLARE @paramString  NVARCHAR(500);

IF (@deviceId IS NOT NULL)
BEGIN
    SELECT @userId = d.UserId, @deviceSecret = d.DeviceSecret, @timeWindow = d.TimeWindow
    FROM HC.Device d WHERE d.id = @deviceId;

    IF (@userId IS NULL OR @userId = '00000000-0000-0000-0000-000000000000')
    BEGIN
        SET @errorCode = 1310; SET @errorType = 13; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
        VALUES (@errorId, @hcVersion, 'Device not registered', 'Device not found', @procName, NULL);
        SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Device not registered' AS errorTitle,
               'The device is not registered. Please re-authorise the app.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END

    -- Token bound to deviceSecret + UPPER(targetUserId)
    SET @paramString = @deviceSecret + UPPER(CAST(COALESCE(@targetUserId, '00000000-0000-0000-0000-000000000000') AS NVARCHAR(50)));

    IF HC.CHECK_ACCESS_TOKEN_V2(@userId, @procName, @accessToken, @paramString, @timeWindow) = 0
    BEGIN
        SET @errorCode = 1110; SET @errorType = 11; SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, string_1)
        VALUES (@errorId, @hcVersion, 'Invalid access token', 'Token failed validation',
                @procName, @userId, CAST(@targetUserId AS NVARCHAR(40)));
        SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
        SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
               'Invalid access token' AS errorTitle,
               'The access token is invalid. Please restart the app.' AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END
END
ELSE
BEGIN
    SET @isNewUserMode = 1;  -- no device = new user creation, no token validation
END

BEGIN TRY
    BEGIN TRANSACTION;

        -- Validate target user exists (edit mode, specific target)
        IF (@targetUserId IS NOT NULL AND @isNewUserMode = 0)
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM HC.Hasher WHERE id = @targetUserId)
            BEGIN
                ROLLBACK TRANSACTION;
                SET @errorCode = 1310; SET @errorType = 13; SET @errorId = NEWID();
                INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, string_1)
                VALUES (@errorId, @hcVersion, 'User not found',
                        'Target userId not found in HC.Hasher.', @procName, @userId,
                        CAST(@targetUserId AS NVARCHAR(40)));
                SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
                SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
                       'User not found' AS errorTitle,
                       'The user provided was not found. They may have been deleted.' AS errorUserMessage,
                       @procName AS errorProc;
                RETURN;
            END
        END

        -- Duplicate email check
        IF (@email IS NOT NULL)
        BEGIN
            IF EXISTS (
                SELECT 1 FROM HC.Hasher h
                WHERE h.Email = TRIM(@email)
                  AND h.id <> COALESCE(@targetUserId, '00000000-0000-0000-0000-000000000000')
                  AND h.Removed = 0
            )
            BEGIN
                ROLLBACK TRANSACTION;
                -- errorType MUST stay 10005: it is what the mobile app's
                -- DB_ERROR_EMAIL_ALREADY_EXISTS tests for to trigger the
                -- "we have emailed you an invite code" flow. Changing it
                -- silently disables that recovery path.
                SET @errorCode = 1510; SET @errorType = 10005; SET @errorId = NEWID();
                INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, string_1)
                VALUES (@errorId, @hcVersion, 'Duplicate email',
                        'A user already exists with this email address.', @procName, @userId, @email);
                SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
                SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
                       'Email address already exists' AS errorTitle,
                       'A user already exists with this email address. We can email an invite code so you can sign in to that account.' AS errorUserMessage,
                       @procName AS errorProc;
                RETURN;
            END
        END

        -- ---------------------------------------------------------------
        -- Insert or update
        -- ---------------------------------------------------------------
        IF (@targetUserId IS NULL)
        BEGIN
            -- INSERT — new user
            SET @targetUserId = NEWID();

            INSERT [HC].[Hasher]
                ([id], [FirstName], [LastName], [Email], [HashName], [Photo],
                 [NameDisplayPreference], [IncludeInGlobalHashDirectory], [Preferences],
                 [HomeLatitude], [HomeLongitude], [HomeKennelId], [updatedAt])
            VALUES
                (@targetUserId,
                 COALESCE(@firstName, ''), COALESCE(@lastName, ''),
                 COALESCE(@email, ''), COALESCE(@hashName, ''), COALESCE(@photo, ''),
                 CASE WHEN @nameDisplayPreference IS NULL
                      THEN CASE WHEN LEN(COALESCE(@hashName, '')) > 0 THEN 1 ELSE 2 END
                      ELSE @nameDisplayPreference END,
                 COALESCE(@includeInGlobalHashDirectory, 0),
                 COALESCE(@preferences, 14 + @useUsaMiles),
                 @latitude, @longitude,
                 @kennelId,
                 GETDATE());

            INSERT HC.LaunchAndLogin (HcVersion, UserId, UserName)
            VALUES (@hcVersion, @targetUserId,
                    '+' + COALESCE(@hashName, @firstName + ' ' + @lastName, '<no name>') + '+');

            -- Add to event if provided
            IF (@eventId IS NOT NULL)
            BEGIN
                DECLARE @kid1 UNIQUEIDENTIFIER;
                SELECT @kid1 = KennelId FROM HC.Event WHERE id = @eventId;
                INSERT INTO HC.HasherEventMap
                    (UserId, EventId, KennelId, RsvpState, AttendenceState, UserStartEvent, Rsvp, updatedAt)
                VALUES
                    (@targetUserId, @eventId, @kid1, 3, 0, GETDATE(), GETDATE(), GETDATE());
            END

            -- Follow kennel if requested
            IF (@kennelId IS NOT NULL
                AND @followKennelOnAddNewUser IS NOT NULL
                AND @followKennelOnAddNewUser != 0
                AND NOT EXISTS (SELECT 1 FROM HC.HasherKennelMap WHERE KennelId = @kennelId AND UserId = @targetUserId))
            BEGIN
                INSERT INTO [HC].[HasherKennelMap]
                    ([UserId], [KennelId], [Following], [IsMember], [IsHomeKennel],
                     [MismanagementRoleFlags], [UserRoleFlags], [AppAccessFlags],
                     [HistoricalTotalRunCount], [HistoricalHaringCount], [HistoricalCountIsEstimate],
                     [CurrentPackRunCount], [CurrentHaringCount], [MemberSince], [removed], [updatedAt])
                VALUES
                    (@targetUserId, @kennelId, 1, 0, 0, 0, 0, 0,
                     COALESCE(@historicalTotalRunCount, 0), COALESCE(@historicalHaringCount, 0),
                     COALESCE(@historicalCountIsEstimate, 0),
                     CASE WHEN @eventId IS NOT NULL THEN 1 ELSE 0 END, 0,
                     GETDATE(), 0, GETDATE());
            END
        END
        ELSE
        BEGIN
            -- UPDATE — edit existing user
            UPDATE HC.Hasher
            SET FirstName                    = COALESCE(@firstName, FirstName),
                LastName                     = COALESCE(@lastName,  LastName),
                Email                        = COALESCE(@email,     Email),
                HashName                     = COALESCE(@hashName,  HashName),
                Photo                        = COALESCE(@photo,     Photo),
                IncludeInGlobalHashDirectory = COALESCE(@includeInGlobalHashDirectory, IncludeInGlobalHashDirectory),
                Preferences                  = COALESCE(@preferences, Preferences),
                NameDisplayPreference        = COALESCE(@nameDisplayPreference, NameDisplayPreference),
                updatedAt                    = GETDATE()
            WHERE id = @targetUserId;

            -- Update historical run counts if provided
            IF (@kennelId IS NOT NULL
                AND (@historicalHaringCount IS NOT NULL OR @historicalTotalRunCount IS NOT NULL))
            BEGIN
                UPDATE HC.HasherKennelMap
                SET HistoricalHaringCount     = COALESCE(@historicalHaringCount, HistoricalHaringCount),
                    HistoricalTotalRunCount    = COALESCE(@historicalTotalRunCount, HistoricalTotalRunCount),
                    HistoricalCountIsEstimate  = COALESCE(@historicalCountIsEstimate, HistoricalCountIsEstimate)
                WHERE UserId = @targetUserId AND KennelId = @kennelId;
            END
        END

    COMMIT TRANSACTION;

    -- ---------------------------------------------------------------
    -- Result
    -- ---------------------------------------------------------------
    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    IF (@isNewUserMode = 1 OR @userId = '00000000-0000-0000-0000-000000000000')
    BEGIN
        -- Return profile directly in new-user mode
        SELECT
            h.id                          AS hasherId,
            COALESCE(h.FirstName,  '')    AS firstName,
            COALESCE(h.LastName,   '')    AS lastName,
            COALESCE(h.DisplayName,'')    AS dispName,
            COALESCE(h.HashName,   '')    AS hashName,
            COALESCE(h.Photo,      '')    AS photo,
            COALESCE(h.NameDisplayPreference, 0) AS dispPref,
            h.SupportCode                 AS supportCode,
            h.ResetCode                   AS resetCode,
            COALESCE(h.QR_code,    '')    AS qrCode,
            CAST(COALESCE(h.Preferences, 14 + @useUsaMiles) AS NVARCHAR(20)) AS preferences,
            h.updatedAt                   AS updatedAt,
            COALESCE(h.Removed, 0)        AS removed
        FROM HC.Hasher h WHERE h.id = @targetUserId;
    END
    ELSE IF (@eventId IS NOT NULL)
    BEGIN
        DECLARE @procName10 NVARCHAR(128) = @procName;
        EXEC HC6.hcapp_syncEventAdminData
            @deviceId = @deviceId, @accessToken = @accessToken, @eventId = @eventId,
            @hashersUpdatedAfter = @hashersUpdatedAfter,
            @hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter,
            @hasherKennelMapUpdatedAfter = 'ignore',
            @narrowEventsUpdatedAfter = 'ignore',
            @paymentsUpdatedAfter = 'ignore', @receiptsUpdatedAfter = 'ignore',
            @procName = @procName10, @param = @paramString;
    END
    ELSE IF (@kennelId IS NOT NULL)
    BEGIN
        EXEC HC6.hcapp_syncKennelAdminData
            @deviceId = @deviceId, @accessToken = @accessToken, @kennelId = @kennelId,
            @hashersUpdatedAfter = @hashersUpdatedAfter,
            @hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
            @procName = @procName, @param = @paramString;
    END
    ELSE
    BEGIN
        EXEC HC6.hcapp_syncUserData
            @deviceId = @deviceId, @accessToken = @accessToken,
            @hashersUpdatedAfter = @hashersUpdatedAfter,
            @hasherEventMapUpdatedAfter = 'ignore',
            @hasherKennelMapUpdatedAfter = 'ignore',
            @narrowEventsUpdatedAfter = 'ignore',
            @procName = @procName, @param = @paramString;
    END

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1910; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, @hcVersion, 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH;
