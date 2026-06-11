CREATE OR ALTER PROCEDURE [HC6].[hcapp_addEditEvent]

    @deviceId                  UNIQUEIDENTIFIER,
    @accessToken               NVARCHAR(1000),
    @narrowEventsUpdatedAfter  NVARCHAR(50),
    @eventId                   UNIQUEIDENTIFIER    = NULL,
    @kennelId                  UNIQUEIDENTIFIER,
    @startDatetime             DATETIMEOFFSET(7)   = NULL,
    @endDatetime               DATETIMEOFFSET(7)   = NULL,
    @isCountedRun              SMALLINT            = NULL,
    @isVisible                 SMALLINT            = NULL,
    @usersCanEditRunAttendence SMALLINT            = NULL,
    @isPromotedEvent           SMALLINT            = NULL,
    @eventGeographicScope      SMALLINT            = NULL,
    @ThemeRunType              SMALLINT            = NULL,
    @eventName                 NVARCHAR(250)       = NULL,
    @eventDescription          NVARCHAR(4000)      = NULL,
    @locationCity              NVARCHAR(250)       = NULL,
    @locationStreet            NVARCHAR(250)       = NULL,
    @locationPostCode          NVARCHAR(250)       = NULL,
    @locationCountry           NVARCHAR(250)       = NULL,
    @locationRegion            NVARCHAR(250)       = NULL,
    @locationSubRegion         NVARCHAR(250)       = NULL,
    @locationOneLineDesc       NVARCHAR(250)       = NULL,
    @eventFacebookId           NVARCHAR(250)       = NULL,
    @coverPhotoUrl             NVARCHAR(500)       = NULL,
    @deleteEventImage          SMALLINT            = 0,
    @coverPhotoOffsetX         INT                 = NULL,
    @coverPhotoOffsetY         INT                 = NULL,
    @latitude                  DECIMAL(18,15)      = NULL,
    @longitude                 DECIMAL(19,15)      = NULL,
    @fbLatitude                DECIMAL(18,15)      = NULL,
    @fbLongitude               DECIMAL(19,15)      = NULL,
    @eventPriceForMembers      DECIMAL(10,4)       = NULL,
    @eventPriceForNonMembers   DECIMAL(10,4)       = NULL,
    @eventPriceForExtras       DECIMAL(10,4)       = NULL,
    @extrasDescription         NVARCHAR(250)       = NULL,
    @absoluteEventNumber       SMALLINT            = NULL,
    @eventCurrencyType         NVARCHAR(10)        = NULL,
    @useFbLatLon               SMALLINT            = NULL,
    @useFbRunDetails           SMALLINT            = NULL,
    @useFbLocation             SMALLINT            = NULL,
    @useFbImage                SMALLINT            = NULL,
    @deleted                   SMALLINT            = NULL,
    @hasherEventMapUpdatedAfter   NVARCHAR(50)     = NULL,
    @hasherKennelMapUpdatedAfter  NVARCHAR(50)     = NULL,
    @hares                     NVARCHAR(2500)      = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcapp_addEditEvent
-- Description: Creates or updates a Hash event. Resolves mode by
--   whether @eventId already exists in HC.Event. Sentinel values
--   control partial-update behaviour (NULL = keep existing,
--   -1 = keep existing for numeric fields, -2 = explicitly clear).
--   String fields use '<remove>' to explicitly clear the value.
--   NCHAR(8232/8233) line-separator characters are stripped from text
--   fields to prevent JSON parse failures in the app. After write,
--   delegates to hcapp_syncUserData so the app receives the updated
--   event.
-- Parameters:
--   @deviceId                  - Registered device UUID
--   @accessToken               - Token validated against DeviceSecret
--   @narrowEventsUpdatedAfter  - Sync watermark for events ('ignore' or timestamp)
--   @eventId                   - NULL = insert; existing = update
--   @kennelId                  - Required on insert
--   @startDatetime / @endDatetime - Event dates
--   @isCountedRun / @isVisible / @isPromotedEvent etc. - Event flags; NULL = keep
--   @eventName                 - Event name; NULL = keep; generated placeholder if empty on insert
--   @eventDescription etc.     - Event detail strings; '<remove>' = explicitly clear
--   @latitude / @longitude     - Location; -1 = keep; -2 = clear
--   @fbLatitude / @fbLongitude - Facebook location fallbacks
--   @eventPriceFor*            - Event prices; -1 = keep; -2 = clear
--   @absoluteEventNumber       - Run number; -1 = keep; 0 = clear
--   @deleted                   - 1 = soft-delete the event; NULL = keep
--   @usersCanEditRunAttendence - -1 = explicitly clear; NULL = keep
--   @hasherEventMapUpdatedAfter / @hasherKennelMapUpdatedAfter - Sync watermarks
--   @hares                     - Comma-separated hare names; '<remove>' = clear
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1+): syncUserData rowsets
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_addEditEvent
-- Breaking Changes:
--   @eventName widened NVARCHAR(120) → NVARCHAR(250) to match column.
--   @locationPostCode widened NVARCHAR(50) → NVARCHAR(250) to match column.
--   @eventPriceFor* changed FLOAT → DECIMAL(10,4) to match column.
--   @deleted stays SMALLINT (maps to BIT column via implicit conversion). Sentinel -1 removed (pass NULL to keep).
--   @narrowEventsUpdatedAfter / @hasherEventMapUpdatedAfter / @hasherKennelMapUpdatedAfter
--     changed DATETIMEOFFSET(7) → NVARCHAR(50) to match sync SP watermark pattern.
--   HC5 INSERT bug fixed: Hares column now receives @hares (was @locationOneLineDesc).
--   HC5 deletion stub removed: @deleted = 1 now actually marks the event deleted via
--     the standard UPDATE path.
--   DATALENGTH → LEN for string length guards.
--   TRY/CATCH and transaction added (HC5 had neither).
--   Success envelope added.
--   HC.nonApi_updateRunNumbers moved inside transaction.
--   Delegation target updated to HC6.hcapp_syncUserData.
--   Cross-kennel guard added: @eventId must belong to @kennelId on UPDATE;
--     an @eventId from a different kennel returns error 1320 rather than
--     silently falling through to INSERT (HC5 bug).
--   @kennelId is now required (no default); missing/zero UUID returns error 1220.
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
    @spNumber     = 20,
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
-- Validate required parameters
-- ---------------------------------------------------------------
IF (@kennelId IS NULL OR @kennelId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1220; SET @errorType = 12; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Missing kennelId',
            '@kennelId is required for hcapp_addEditEvent', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing parameter' AS errorTitle,
           'A required parameter was missing. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Normalise null UUIDs and sentinel values
-- ---------------------------------------------------------------
IF (@eventId  = '00000000-0000-0000-0000-000000000000') SET @eventId  = NULL;

IF (@startDatetime IS NOT NULL AND @startDatetime <= '1901-01-01') SET @startDatetime = NULL;
IF (@endDatetime   IS NOT NULL AND @endDatetime   <= '1901-01-01') SET @endDatetime   = NULL;

IF (@isCountedRun       = -1) SET @isCountedRun       = NULL;
IF (@isVisible          = -1) SET @isVisible           = NULL;
IF (@isPromotedEvent    = -1) SET @isPromotedEvent     = NULL;
IF (@eventGeographicScope = -1) SET @eventGeographicScope = NULL;
IF (@ThemeRunType       = -1) SET @ThemeRunType        = NULL;
IF (@coverPhotoOffsetX  = -1) SET @coverPhotoOffsetX  = NULL;
IF (@coverPhotoOffsetY  = -1) SET @coverPhotoOffsetY  = NULL;
IF (@useFbLatLon        = -1) SET @useFbLatLon         = NULL;
IF (@useFbRunDetails    = -1) SET @useFbRunDetails     = NULL;
IF (@useFbLocation      = -1) SET @useFbLocation       = NULL;
IF (@useFbImage         = -1) SET @useFbImage          = NULL;

-- Lat/lon: -1 = keep (becomes NULL), -2 = explicitly clear (handled inline in CASE)
IF (@latitude   = -1) SET @latitude   = NULL;
IF (@longitude  = -1) SET @longitude  = NULL;
IF (@fbLatitude = -1) SET @fbLatitude = NULL;
IF (@fbLongitude= -1) SET @fbLongitude= NULL;

-- Prices: -1 = keep (becomes NULL), -2 = explicitly clear (handled inline in CASE)
IF (@eventPriceForMembers    = -1) SET @eventPriceForMembers    = NULL;
IF (@eventPriceForNonMembers = -1) SET @eventPriceForNonMembers = NULL;
IF (@eventPriceForExtras     = -1) SET @eventPriceForExtras     = NULL;

-- absoluteEventNumber: -1 = keep (becomes NULL), 0 = explicitly clear
IF (@absoluteEventNumber = -1) SET @absoluteEventNumber = NULL;

-- String short-length guards use LEN (not DATALENGTH)
IF (LEN(@eventName)         < 1) SET @eventName         = NULL;
IF (LEN(@eventDescription)  < 1) SET @eventDescription  = NULL;
IF (LEN(@locationCity)      < 1) SET @locationCity       = NULL;
IF (LEN(@locationStreet)    < 1) SET @locationStreet     = NULL;
IF (LEN(@locationPostCode)  < 1) SET @locationPostCode   = NULL;
IF (LEN(@locationCountry)   < 1) SET @locationCountry    = NULL;
IF (LEN(@locationRegion)    < 1) SET @locationRegion     = NULL;
IF (LEN(@locationSubRegion) < 1) SET @locationSubRegion  = NULL;
IF (LEN(@locationOneLineDesc) < 1) SET @locationOneLineDesc = NULL;
IF (LEN(@eventFacebookId)   < 5) SET @eventFacebookId   = NULL;
IF (LEN(@coverPhotoUrl)     < 5) SET @coverPhotoUrl      = NULL;
IF (LEN(@hares)             < 4) SET @hares              = NULL;
IF (LEN(@eventCurrencyType) < 4) SET @eventCurrencyType  = NULL;
IF (LEN(@extrasDescription) < 1) SET @extrasDescription  = NULL;

-- Strip these Unicode line/paragraph separators which break JSON parsing in the app
IF (@eventDescription  LIKE '%' + NCHAR(8233) + '%') SET @eventDescription  = REPLACE(@eventDescription,  NCHAR(8233), '');
IF (@eventName         LIKE '%' + NCHAR(8233) + '%') SET @eventName         = REPLACE(@eventName,         NCHAR(8233), '');
IF (@locationOneLineDesc LIKE '%' + NCHAR(8233) + '%') SET @locationOneLineDesc = REPLACE(@locationOneLineDesc, NCHAR(8233), '');
IF (@hares             LIKE '%' + NCHAR(8233) + '%') SET @hares             = REPLACE(@hares,             NCHAR(8233), '');
IF (@eventDescription  LIKE '%' + NCHAR(8232) + '%') SET @eventDescription  = REPLACE(@eventDescription,  NCHAR(8232), '');
IF (@eventName         LIKE '%' + NCHAR(8232) + '%') SET @eventName         = REPLACE(@eventName,         NCHAR(8232), '');
IF (@locationOneLineDesc LIKE '%' + NCHAR(8232) + '%') SET @locationOneLineDesc = REPLACE(@locationOneLineDesc, NCHAR(8232), '');
IF (@hares             LIKE '%' + NCHAR(8232) + '%') SET @hares             = REPLACE(@hares,             NCHAR(8232), '');

-- Malformed Facebook event IDs containing 'break' are silently cleared
IF (@eventFacebookId LIKE '%break%') SET @eventFacebookId = '';

-- Guard against cross-kennel writes: if @eventId is non-null and the event
-- exists in the DB but belongs to a different kennel, reject explicitly.
-- Without this, the UPDATE mode detection would fall through to INSERT,
-- which would fail with a PK violation (same @eventId already taken).
IF (@eventId IS NOT NULL
    AND EXISTS     (SELECT 1 FROM HC.Event WHERE id = @eventId)
    AND NOT EXISTS (SELECT 1 FROM HC.Event WHERE id = @eventId AND KennelId = @kennelId))
BEGIN
    SET @errorCode = 1320; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Event not found in kennel',
            'eventId exists but belongs to a different kennel', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Event not found' AS errorTitle,
           'The event could not be found for this club.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

        -- ---------------------------------------------------------------
        -- Determine mode: UPDATE if @eventId exists for this kennel, INSERT otherwise
        -- ---------------------------------------------------------------
        IF (@eventId IS NOT NULL AND EXISTS (SELECT 1 FROM HC.Event e WHERE e.id = @eventId AND e.KennelId = @kennelId))
        BEGIN

            UPDATE HC.Event SET
                EventStartDatetime     = COALESCE(@startDatetime, EventStartDatetime, GETDATE()),
                EventEndDatetime       = COALESCE(@endDatetime, EventEndDatetime),
                IsCountedRun           = COALESCE(@isCountedRun, IsCountedRun, 0),
                IsVisible              = COALESCE(@isVisible, IsVisible),
                CanEditRunAttendence   = CASE WHEN @usersCanEditRunAttendence = -1 THEN NULL ELSE COALESCE(@usersCanEditRunAttendence, CanEditRunAttendence) END,
                IsPromotedEvent        = COALESCE(@isPromotedEvent, IsPromotedEvent),
                EventGeographicScope   = COALESCE(@eventGeographicScope, EventGeographicScope),
                ThemeRunType           = COALESCE(@ThemeRunType, ThemeRunType, 0),
                EventName              = COALESCE(@eventName, EventName),
                EventDescription       = CASE WHEN @eventDescription = '<remove>' THEN NULL ELSE COALESCE(@eventDescription, EventDescription) END,
                LocationCity           = CASE WHEN @locationCity       = '<remove>' THEN NULL ELSE COALESCE(@locationCity, LocationCity) END,
                LocationStreet         = CASE WHEN @locationStreet     = '<remove>' THEN NULL ELSE COALESCE(@locationStreet, LocationStreet) END,
                LocationPostCode       = CASE WHEN @locationPostCode   = '<remove>' THEN NULL ELSE COALESCE(@locationPostCode, LocationPostCode) END,
                LocationCountry        = CASE WHEN @locationCountry    = '<remove>' THEN NULL ELSE COALESCE(@locationCountry, LocationCountry) END,
                LocationRegion         = CASE WHEN @locationRegion     = '<remove>' THEN NULL ELSE COALESCE(@locationRegion, LocationRegion) END,
                LocationSubRegion      = CASE WHEN @locationSubRegion  = '<remove>' THEN NULL ELSE COALESCE(@locationSubRegion, LocationSubRegion) END,
                LocationOneLineDesc    = CASE WHEN @locationOneLineDesc = '<remove>' THEN NULL ELSE COALESCE(@locationOneLineDesc, LocationOneLineDesc) END,
                EventFacebookId        = COALESCE(@eventFacebookId, EventFacebookId),
                EventImage             = CASE WHEN @deleteEventImage = 1 THEN NULL ELSE COALESCE(@coverPhotoUrl, EventImage) END,
                EventImageOffsetX      = COALESCE(@coverPhotoOffsetX, EventImageOffsetX),
                EventImageOffsetY      = COALESCE(@coverPhotoOffsetY, EventImageOffsetY),
                Latitude               = CASE WHEN @latitude   = -2 THEN NULL ELSE COALESCE(@latitude,  Latitude)  END,
                Longitude              = CASE WHEN @longitude  = -2 THEN NULL ELSE COALESCE(@longitude, Longitude) END,
                FbLatitude             = COALESCE(@fbLatitude,  FbLatitude),
                FbLongitude            = COALESCE(@fbLongitude, FbLongitude),
                EventGeolocation       = CASE
                    WHEN COALESCE(@useFbLatLon, UseFbLatLon) = 1 THEN
                        CASE WHEN COALESCE(@fbLatitude, FbLatitude) IS NOT NULL
                            THEN geography::Point(COALESCE(@fbLatitude, FbLatitude), COALESCE(@fbLongitude, FbLongitude), 4326)
                            ELSE NULL END
                    ELSE
                        CASE WHEN CASE WHEN @latitude = -2 THEN NULL ELSE COALESCE(@latitude, Latitude) END IS NOT NULL
                            THEN geography::Point(
                                CASE WHEN @latitude  = -2 THEN NULL ELSE COALESCE(@latitude,  Latitude)  END,
                                CASE WHEN @longitude = -2 THEN NULL ELSE COALESCE(@longitude, Longitude) END,
                                4326)
                            ELSE NULL END
                    END,
                EventPriceForMembers    = CASE WHEN @eventPriceForMembers    = -2 THEN NULL ELSE COALESCE(@eventPriceForMembers,    EventPriceForMembers)    END,
                EventPriceForNonMembers = CASE WHEN @eventPriceForNonMembers = -2 THEN NULL ELSE COALESCE(@eventPriceForNonMembers, EventPriceForNonMembers) END,
                EventPriceForExtras     = CASE WHEN @eventPriceForExtras     = -2 THEN NULL ELSE COALESCE(@eventPriceForExtras,     EventPriceForExtras)     END,
                ExtrasDescription      = CASE WHEN @extrasDescription = '<none>' THEN NULL ELSE COALESCE(@extrasDescription, ExtrasDescription) END,
                AbsoluteEventNumber    = CASE WHEN @absoluteEventNumber = 0 THEN NULL ELSE COALESCE(@absoluteEventNumber, AbsoluteEventNumber) END,
                EventCurrencyType      = COALESCE(@eventCurrencyType, EventCurrencyType),
                deleted                = COALESCE(@deleted, deleted),
                EventSource            = 'HC app',
                UseFbLatLon            = COALESCE(@useFbLatLon,    UseFbLatLon),
                UseFbRunDetails        = COALESCE(@useFbRunDetails, UseFbRunDetails),
                UseFbLocation          = COALESCE(@useFbLocation,   UseFbLocation),
                UseFbImage             = COALESCE(@useFbImage,      UseFbImage),
                Hares                  = CASE WHEN @hares = '<remove>' THEN NULL ELSE COALESCE(@hares, Hares) END,
                updatedAt              = GETDATE()
            WHERE id = @eventId AND KennelId = @kennelId;

        END
        ELSE
        BEGIN
            -- ---------------------------------------------------------------
            -- INSERT mode — generate placeholder name if none supplied
            -- ---------------------------------------------------------------
            IF (LEN(COALESCE(@eventName, '')) = 0)
            BEGIN
                DECLARE @kennelShortName NVARCHAR(50);
                SELECT @kennelShortName = k.KennelShortName FROM HC.Kennel k WHERE k.id = @kennelId;
                SET @eventName = 'Placeholder event for ' + COALESCE(@kennelShortName, '<no kennel found>');
            END

            IF (LEN(TRIM(@eventName)) > 0 AND @startDatetime IS NOT NULL AND @kennelId IS NOT NULL)
            BEGIN
                -- Apply kennel default start time if no time was provided (midnight)
                IF (CAST(@startDatetime AS TIME) = '00:00:00.0000000')
                BEGIN
                    DECLARE @defaultTime TIME(7);
                    DECLARE @diffSeconds INT;
                    SELECT @defaultTime = k.DefaultRunStartTime FROM HC.Kennel k WHERE k.id = @kennelId;
                    IF (@defaultTime IS NOT NULL)
                    BEGIN
                        SELECT @diffSeconds = DATEDIFF(SECOND, '00:00:00', @defaultTime);
                        SET @startDatetime = DATEADD(SECOND, @diffSeconds, @startDatetime);
                    END
                END

                IF (@eventId IS NULL) SET @eventId = NEWID();

                DECLARE @countryId    UNIQUEIDENTIFIER;
                DECLARE @defaultPriceM  DECIMAL(10,4);
                DECLARE @defaultPriceNM DECIMAL(10,4);

                SELECT
                    @defaultPriceM  = k.DefaultEventPriceForMembers,
                    @defaultPriceNM = k.DefaultEventPriceForNonMembers,
                    @countryId      = k.CountryId
                FROM HC.Kennel k WHERE k.id = @kennelId;

                INSERT HC.Event
                    ([id], [KennelId], [EventStartDatetime], [EventEndDatetime],
                     [IsCountedRun], [IsVisible], [IsPromotedEvent], [CanEditRunAttendence],
                     [EventGeographicScope], [InboundIntegrationId], [ThemeRunType],
                     [EventName], [EventDescription],
                     [LocationCity], [LocationStreet], [LocationPostCode],
                     [LocationCountry], [LocationRegion], [LocationSubRegion], [LocationOneLineDesc],
                     [EventFacebookId], [EventImage], [EventImageOffsetX], [EventImageOffsetY],
                     [Latitude], [Longitude], [FbLatitude], [FbLongitude], [EventGeolocation],
                     [EventPriceForMembers], [EventPriceForNonMembers], [EventPriceForExtras],
                     [ExtrasDescription], [AbsoluteEventNumber], [EventCurrencyType],
                     [Hares], [EventSource], [deleted], [updatedAt], [countryId])
                VALUES
                    (@eventId, @kennelId,
                     COALESCE(@startDatetime, GETDATE()), @endDatetime,
                     COALESCE(@isCountedRun, 0),
                     COALESCE(@isVisible, 1),
                     COALESCE(@isPromotedEvent, 0),
                     CASE WHEN @usersCanEditRunAttendence = -1 THEN NULL ELSE @usersCanEditRunAttendence END,
                     COALESCE(@eventGeographicScope, 0),
                     0,
                     COALESCE(@ThemeRunType, 0),
                     @eventName,
                     CASE WHEN @eventDescription  = '<remove>' THEN NULL ELSE @eventDescription  END,
                     CASE WHEN @locationCity       = '<remove>' THEN NULL ELSE @locationCity       END,
                     CASE WHEN @locationStreet     = '<remove>' THEN NULL ELSE @locationStreet     END,
                     CASE WHEN @locationPostCode   = '<remove>' THEN NULL ELSE @locationPostCode   END,
                     CASE WHEN @locationCountry    = '<remove>' THEN NULL ELSE @locationCountry    END,
                     CASE WHEN @locationRegion     = '<remove>' THEN NULL ELSE @locationRegion     END,
                     CASE WHEN @locationSubRegion  = '<remove>' THEN NULL ELSE @locationSubRegion  END,
                     CASE WHEN @locationOneLineDesc = '<remove>' THEN NULL ELSE @locationOneLineDesc END,
                     @eventFacebookId,
                     @coverPhotoUrl,
                     COALESCE(@coverPhotoOffsetX, 0),
                     COALESCE(@coverPhotoOffsetY, 0),
                     CASE WHEN @latitude  = -2 THEN NULL ELSE CAST(@latitude  AS DECIMAL(18,15)) END,
                     CASE WHEN @longitude = -2 THEN NULL ELSE CAST(@longitude AS DECIMAL(19,15)) END,
                     CAST(@fbLatitude  AS DECIMAL(18,15)),
                     CAST(@fbLongitude AS DECIMAL(19,15)),
                     CASE WHEN @useFbLatLon = 1 THEN
                         CASE WHEN CAST(@fbLatitude AS DECIMAL(18,15)) IS NOT NULL
                             THEN geography::Point(CAST(@fbLatitude AS DECIMAL(18,15)), CAST(@fbLongitude AS DECIMAL(18,15)), 4326)
                             ELSE NULL END
                     ELSE
                         CASE WHEN CASE WHEN @latitude = -2 THEN NULL ELSE CAST(@latitude AS DECIMAL(18,15)) END IS NOT NULL
                             THEN geography::Point(
                                 CASE WHEN @latitude  = -2 THEN NULL ELSE CAST(@latitude  AS DECIMAL(18,15)) END,
                                 CASE WHEN @longitude = -2 THEN NULL ELSE CAST(@longitude AS DECIMAL(19,15)) END,
                                 4326)
                             ELSE NULL END
                     END,
                     COALESCE(@eventPriceForMembers,    @defaultPriceM),
                     COALESCE(@eventPriceForNonMembers, @defaultPriceNM),
                     CASE WHEN @eventPriceForExtras = -2 THEN NULL ELSE @eventPriceForExtras END,
                     CASE WHEN @extrasDescription = '<none>' THEN NULL ELSE @extrasDescription END,
                     @absoluteEventNumber,
                     @eventCurrencyType,
                     CASE WHEN @hares = '<remove>' THEN NULL ELSE @hares END,
                     'HC app',
                     COALESCE(@deleted, 0),
                     GETDATE(),
                     @countryId);
            END
        END

        EXEC HC6.nonApi_updateRunNumbers @eventId = @eventId;

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1920; SET @errorType = 19; SET @errorId = NEWID();
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
-- Return the saved eventId as adHocData so the caller can
-- identify the record (rowset 1 — before sync data)
-- ---------------------------------------------------------------
SELECT
    1                                         AS adHocDataId,
    LOWER(CAST(@eventId AS NVARCHAR(40)))     AS eventId;

-- ---------------------------------------------------------------
-- Delegate to syncUserData (outside TRY — runs after commit)
-- ---------------------------------------------------------------
SET @hasherKennelMapUpdatedAfter = COALESCE(@hasherKennelMapUpdatedAfter, 'ignore');
SET @hasherEventMapUpdatedAfter  = COALESCE(@hasherEventMapUpdatedAfter,  'ignore');
SET @narrowEventsUpdatedAfter    = COALESCE(@narrowEventsUpdatedAfter,    'ignore');

EXEC HC6.hcapp_syncUserData
    @deviceId                    = @deviceId,
    @accessToken                 = @accessToken,
    @hashersUpdatedAfter         = 'ignore',
    @hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
    @hasherEventMapUpdatedAfter  = @hasherEventMapUpdatedAfter,
    @narrowEventsUpdatedAfter    = @narrowEventsUpdatedAfter,
    @usePaging                   = 0,
    @procName                    = @procName,
    @param                       = NULL;
