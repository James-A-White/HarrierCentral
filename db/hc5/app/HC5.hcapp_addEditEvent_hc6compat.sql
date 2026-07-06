CREATE OR ALTER PROCEDURE [HC5].[hcapp_addEditEvent]

    @deviceId                  UNIQUEIDENTIFIER,
    @accessToken               NVARCHAR(1000),
    @narrowEventsUpdatedAfter  NVARCHAR(50),
    @eventId                   UNIQUEIDENTIFIER    = NULL,
    @kennelId                  UNIQUEIDENTIFIER    = NULL,
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
-- Procedure: HC5.hcapp_addEditEvent  (HC6 logic, HC5-compatible response)
-- Description: HC6 write logic deployed to HC5 schema. Returns HC5-format
--   rowsets (no success envelope, no adHocData) so old app clients can
--   parse the response. Delegates sync to HC5.hcapp_syncUserData.
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
    SELECT @errorId AS errorId, @errorType AS errorType,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage,
           NULL AS debugMessage, @procName AS errorProc;
    RETURN;
END

-- ---------------------------------------------------------------
-- Derive kennelId from event if not supplied (old app omits it on Other tab)
-- ---------------------------------------------------------------
IF (@kennelId IS NULL OR @kennelId = '00000000-0000-0000-0000-000000000000')
BEGIN
    IF (@eventId IS NOT NULL AND @eventId != '00000000-0000-0000-0000-000000000000')
        SELECT @kennelId = KennelId FROM HC.Event WHERE id = @eventId;
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
    SELECT @errorId AS errorId, @errorType AS errorType,
           'Missing parameter' AS errorTitle,
           'A required parameter was missing. Please try again.' AS errorUserMessage,
           NULL AS debugMessage, @procName AS errorProc;
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

IF (@latitude   = -1) SET @latitude   = NULL;
IF (@longitude  = -1) SET @longitude  = NULL;
IF (@fbLatitude = -1) SET @fbLatitude = NULL;
IF (@fbLongitude= -1) SET @fbLongitude= NULL;

IF (@eventPriceForMembers    = -1) SET @eventPriceForMembers    = NULL;
IF (@eventPriceForNonMembers = -1) SET @eventPriceForNonMembers = NULL;
IF (@eventPriceForExtras     = -1) SET @eventPriceForExtras     = NULL;

IF (@absoluteEventNumber = -1) SET @absoluteEventNumber = NULL;

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

IF (@eventDescription  LIKE '%' + NCHAR(8233) + '%') SET @eventDescription  = REPLACE(@eventDescription,  NCHAR(8233), '');
IF (@eventName         LIKE '%' + NCHAR(8233) + '%') SET @eventName         = REPLACE(@eventName,         NCHAR(8233), '');
IF (@locationOneLineDesc LIKE '%' + NCHAR(8233) + '%') SET @locationOneLineDesc = REPLACE(@locationOneLineDesc, NCHAR(8233), '');
IF (@hares             LIKE '%' + NCHAR(8233) + '%') SET @hares             = REPLACE(@hares,             NCHAR(8233), '');
IF (@eventDescription  LIKE '%' + NCHAR(8232) + '%') SET @eventDescription  = REPLACE(@eventDescription,  NCHAR(8232), '');
IF (@eventName         LIKE '%' + NCHAR(8232) + '%') SET @eventName         = REPLACE(@eventName,         NCHAR(8232), '');
IF (@locationOneLineDesc LIKE '%' + NCHAR(8232) + '%') SET @locationOneLineDesc = REPLACE(@locationOneLineDesc, NCHAR(8232), '');
IF (@hares             LIKE '%' + NCHAR(8232) + '%') SET @hares             = REPLACE(@hares,             NCHAR(8232), '');

IF (@eventFacebookId LIKE '%break%') SET @eventFacebookId = '';

IF (@eventId IS NOT NULL
    AND EXISTS     (SELECT 1 FROM HC.Event WHERE id = @eventId)
    AND NOT EXISTS (SELECT 1 FROM HC.Event WHERE id = @eventId AND KennelId = @kennelId))
BEGIN
    SET @errorCode = 1320; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Event not found in kennel',
            'eventId exists but belongs to a different kennel', @procName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType,
           'Event not found' AS errorTitle,
           'The event could not be found for this club.' AS errorUserMessage,
           NULL AS debugMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

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
            IF (LEN(COALESCE(@eventName, '')) = 0)
            BEGIN
                DECLARE @kennelShortName NVARCHAR(50);
                SELECT @kennelShortName = k.KennelShortName FROM HC.Kennel k WHERE k.id = @kennelId;
                SET @eventName = 'Placeholder event for ' + COALESCE(@kennelShortName, '<no kennel found>');
            END

            IF (LEN(TRIM(@eventName)) > 0 AND @startDatetime IS NOT NULL AND @kennelId IS NOT NULL)
            BEGIN
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

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1920; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT @errorId AS errorId, @errorType AS errorType,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           NULL AS debugMessage, @procName AS errorProc;
    RETURN;
END CATCH;

-- ---------------------------------------------------------------
-- Delegate to HC5.hcapp_syncUserData (outside TRY — runs after commit)
-- ---------------------------------------------------------------
SET @hasherKennelMapUpdatedAfter = COALESCE(@hasherKennelMapUpdatedAfter, 'ignore');
SET @hasherEventMapUpdatedAfter  = COALESCE(@hasherEventMapUpdatedAfter,  'ignore');
SET @narrowEventsUpdatedAfter    = COALESCE(@narrowEventsUpdatedAfter,    'ignore');

EXEC HC5.hcapp_syncUserData
    @deviceId                    = @deviceId,
    @accessToken                 = @accessToken,
    @hashersUpdatedAfter         = 'ignore',
    @citiesUpdatedAfter          = 'ignore',
    @regionsUpdatedAfter         = 'ignore',
    @countriesUpdatedAfter       = 'ignore',
    @kennelsUpdatedAfter         = 'ignore',
    @hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
    @hasherEventMapUpdatedAfter  = @hasherEventMapUpdatedAfter,
    @narrowEventsUpdatedAfter    = @narrowEventsUpdatedAfter,
    @procName                    = @procName,
    @param                       = NULL;
