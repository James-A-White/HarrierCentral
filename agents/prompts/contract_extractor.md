You are a SQL contract extractor for the Harrier Central project.

I will paste the source of a stored procedure. Your job is to produce a 
contract JSON file that documents it precisely.

Rules:
- Extract ALL input parameters with types and nullability
- Extract ALL output rowsets with column names, types, and nullability
- Infer descriptions from parameter names and SP logic (ask me if unclear)
- Note any side effects (sends notifications, calls other SPs, etc.)
- Flag any code smells or issues for the HC6 refactor (but don't fix them yet)
- Output ONLY valid JSON matching the contract schema

Contract schema: 

{
  "schema": "HC5",
  "name": "sp_name_here",
  "version": "1.0.0",
  "description": "What this SP does",
  "parameters": [
    {
      "name": "paramName",
      "type": "SQL_TYPE",
      "nullable": true,
      "description": "What this parameter is for"
    }
  ],
  "rowsets": [
    {
      "index": 0,
      "name": "RowsetName",
      "description": "What these rows represent",
      "columns": [
        { "name": "ColumnName", "type": "SQL_TYPE", "nullable": false, "description": "What this column means" }
      ]
    }
  ],
  "sideEffects": [],
  "codeSmells": [],
  "breakingChangeRules": [
    "Never remove a column from any rowset",
    "Never rename a parameter",
    "Never change a parameter type"
  ]
}

Here is the stored procedure:

/****** Object:  StoredProcedure [HC5].[hcportal_addEditEvent2]    Script Date: 3/8/2026 11:54:21 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [HC5].[hcportal_addEditEvent2]

-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
@publicHasherId uniqueidentifier = NULL,
@accessToken nvarchar(1000) = NULL,
@publicKennelId uniqueidentifier = NULL,

-- optional parameters
@absoluteEventNumber smallint = null,
@eventImage nvarchar(500) = null,
@deleted smallint = null,
@eventEndDatetime datetimeoffset(7) = null,
@eventDescription nvarchar(4000) = null,
@eventGeographicScope smallint = null,
@eventName nvarchar(120) = null,
@eventPriceForExtras float = null,
@eventPriceForMembers float = null,
@eventPriceForNonMembers float = null,
@extrasDescription nvarchar(250) = null,
@extrasRsvpRequired smallint = null,
@hares nvarchar(2500) = null,
@integrationEnabled smallint = null,
@isCountedRun smallint = null,
@isPromotedEvent smallint = null,
@isVisible smallint = null,
@hcLatitude decimal(18,15) = null,
@locationCity nvarchar(250) = null,
@locationCountry nvarchar(250) = null,
@locationOneLineDesc nvarchar(250) = null,
@locationPostCode nvarchar(50) = null,
@locationRegion nvarchar(250) = null,
@locationStreet nvarchar(250) = null,
@locationSubRegion nvarchar(250) = null,
@hcLongitude decimal(19,15) = null,
@maximumParticipantsAllowed smallint = null,
@minimumParticipantsRequired smallint = null,
@publicEventId uniqueidentifier = null,
@saveTagsAsKennelDefault smallint = null,
@eventStartDatetime datetimeoffset(7) = null,
@tags1 int = null,
@tags2 int = null,
@tags3 int = null,
@useFbImage smallint = null,
@useFbLatLon smallint = null,
@useFbLocation smallint = null,
@useFbRunDetails smallint = null,
@canEditRunAttendence smallint = null,
@evtDisseminationAudience int = null,
@evtDisseminateAllowWebLinks smallint = null,
@evtDisseminateHashRunsDotOrg smallint = null,
@evtDisseminateOnGlobalGoogleCalendar smallint = null,
@countryId uniqueidentifier = null,

@ipAddress nvarchar(100) = NULL,
@ipGeoDetails nvarchar(2000) = NULL

AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- Auto-rollback on errors

    -- Logging
    INSERT INTO [LOG].[GeneralLog]
           ([LogSource], [Message], [Data], [StrParam1], [Timestamp])
    VALUES
           ('Admin Portal: hcportal_addEditEvent',
            '[HC5].[hcportal_addEditEvent]',
            CAST(COALESCE(@publicEventId,'00000000-0000-0000-0000-000000000000') AS nvarchar(100)),
            'PublicHasherId:' + CAST(@publicHasherId AS nvarchar(100)),
            GETDATE());

    -- ============================================
    -- VALIDATION SECTION (before transaction)
    -- ============================================
    DECLARE @isError smallint = 0;
    DECLARE @isAdmin smallint = 1;
    DECLARE @errorTitle nvarchar(500) = '';
    DECLARE @errorId uniqueidentifier;

    IF (@publicHasherId = '11111111-1111-1111-1111-111111111111') 
    BEGIN
        SET @isAdmin = 0;
    END

    -- Validate publicHasherId
    IF (@publicHasherId IS NULL) OR (DATALENGTH(@publicHasherId) != 16)
    BEGIN
        SET @errorId = NEWID();
        SET @isError = 1;
        SET @errorTitle = 'Null or invalid publicHasherId';
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) 
        VALUES (@errorId, '<unknown>', 'Null or empty publicHasherId', 
                'Null or empty publicHasherId was passed to ' + OBJECT_NAME(@@PROCID), 
                OBJECT_NAME(@@PROCID), @publicHasherId);
        
        SELECT @errorId as errorId,
               CAST(2 AS int) as errorType,
               @errorTitle as errorTitle,
               'Null or empty value was passed as the publicHasherId to ' + OBJECT_NAME(@@PROCID) as errorUserMessage,
               'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage,
               OBJECT_NAME(@@PROCID) as errorProc;
        RETURN;
    END

    -- Validate publicKennelId
    IF (@publicKennelId IS NULL) OR (DATALENGTH(@publicKennelId) != 16)
    BEGIN
        SET @errorId = NEWID();
        SET @errorTitle = 'NULL or invalid publicKennelId';
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, string_1) 
        VALUES (@errorId, 'hcportal', @errorTitle, 
                'An invalid publicKennelId was passed to ' + OBJECT_NAME(@@PROCID), 
                OBJECT_NAME(@@PROCID), @publicHasherId, @accessToken);

        SELECT @errorId as errorId,
               CAST(3 AS int) as errorType,
               @errorTitle as errorTitle,
               'An internal error was encountered in our web page (null or invalid publicKennelId).' as errorUserMessage,
               'Please contact us at connect@harriercentral.com to learn more about how to generate web pages from our system. We are happy to help!' as debugMessage,
               OBJECT_NAME(@@PROCID) as errorProc;
        RETURN;
    END

    -- Validate publicEventId format (if provided)
    IF (@publicEventId IS NOT NULL) AND (DATALENGTH(@publicEventId) != 16)
    BEGIN
        SET @errorId = NEWID();
        SET @errorTitle = 'Invalid publicEventId';
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) 
        VALUES (@errorId, '<unknown>', 'Null or empty publicEventId', 
                'Null or empty publicEventId was passed to ' + OBJECT_NAME(@@PROCID), 
                OBJECT_NAME(@@PROCID), @publicEventId);
        
        SELECT @errorId as errorId,
               CAST(2 AS int) as errorType,
               @errorTitle as errorTitle,
               'Null or empty value was passed as the publicEventId to ' + OBJECT_NAME(@@PROCID) as errorUserMessage,
               'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage,
               OBJECT_NAME(@@PROCID) as errorProc;
        RETURN;
    END

    -- Validate access token
    IF (HC.CHECK_PORTAL_ACCESS_TOKEN(@publicHasherId, OBJECT_NAME(@@PROCID), @accessToken, @publicKennelId) = 0)
    BEGIN
        SET @errorId = NEWID();
        SET @errorTitle = 'Invalid access token';
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, string_1) 
        VALUES (@errorId, '<unknown>', 'Invalid access token', 
                'An invalid access token was passed to ' + OBJECT_NAME(@@PROCID), 
                OBJECT_NAME(@@PROCID), @publicHasherId, @accessToken);

        SELECT @errorId as errorId,
               CAST(3 AS int) as errorType,
               @errorTitle as errorTitle,
               'An invalid access token was passed to ' + OBJECT_NAME(@@PROCID) as errorUserMessage,
               'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage,
               OBJECT_NAME(@@PROCID) as errorProc;
        RETURN;
    END

    -- ============================================
    -- DATA CLEANUP SECTION
    -- ============================================
    
    -- Remove unicode paragraph separators that break JSON parsing
    IF (@eventDescription LIKE '%' + NCHAR(8233) + '%') SET @eventDescription = REPLACE(@eventDescription, NCHAR(8233), '');
    IF (@eventName LIKE '%' + NCHAR(8233) + '%') SET @eventName = REPLACE(@eventName, NCHAR(8233), '');
    IF (@locationOneLineDesc LIKE '%' + NCHAR(8233) + '%') SET @locationOneLineDesc = REPLACE(@locationOneLineDesc, NCHAR(8233), '');
    IF (@hares LIKE '%' + NCHAR(8233) + '%') SET @hares = REPLACE(@hares, NCHAR(8233), '');

    IF (@eventDescription LIKE '%' + NCHAR(8232) + '%') SET @eventDescription = REPLACE(@eventDescription, NCHAR(8232), '');
    IF (@eventName LIKE '%' + NCHAR(8232) + '%') SET @eventName = REPLACE(@eventName, NCHAR(8232), '');
    IF (@locationOneLineDesc LIKE '%' + NCHAR(8232) + '%') SET @locationOneLineDesc = REPLACE(@locationOneLineDesc, NCHAR(8232), '');
    IF (@hares LIKE '%' + NCHAR(8232) + '%') SET @hares = REPLACE(@hares, NCHAR(8232), '');

    -- Normalize special values to NULL
    IF ((@eventStartDatetime IS NOT NULL) AND (@eventStartDatetime <= '1/1/2000')) SET @eventStartDatetime = NULL;
    IF ((@eventEndDatetime IS NOT NULL) AND (@eventEndDatetime <= '1/1/2000')) SET @eventEndDatetime = NULL;
    IF (@isCountedRun = -1) SET @isCountedRun = NULL;
    IF (@isVisible = -1) SET @isVisible = NULL;
    IF (@canEditRunAttendence = -1) SET @canEditRunAttendence = NULL;
    IF (@isPromotedEvent = -1) SET @isPromotedEvent = NULL;
    IF (@eventGeographicScope = -1) SET @eventGeographicScope = NULL;
    IF (DATALENGTH(@eventName) < 2) SET @eventName = NULL;
    IF (DATALENGTH(@eventDescription) < 2) SET @eventDescription = NULL;
    IF (DATALENGTH(@locationCity) < 2) SET @locationCity = NULL;
    IF (DATALENGTH(@locationStreet) < 2) SET @locationStreet = NULL;
    IF (DATALENGTH(@locationPostCode) < 2) SET @locationPostCode = NULL;
    IF (DATALENGTH(@locationSubRegion) < 2) SET @locationSubRegion = NULL;
    IF (DATALENGTH(@locationRegion) < 2) SET @locationRegion = NULL;
    IF (DATALENGTH(@locationCountry) < 2) SET @locationCountry = NULL;
    IF (DATALENGTH(@locationOneLineDesc) < 2) SET @locationOneLineDesc = NULL;
    IF (DATALENGTH(@eventImage) < 5) SET @eventImage = NULL;
    IF (DATALENGTH(@hares) < 4) SET @hares = NULL;
    IF (@hcLatitude = -1) SET @hcLatitude = NULL;
    IF (@hcLongitude = -1) SET @hcLongitude = NULL;
    IF (@useFbLatLon = -1) SET @useFbLatLon = NULL;
    IF (@useFbRunDetails = -1) SET @useFbRunDetails = NULL;
    IF (@useFbLocation = -1) SET @useFbLocation = NULL;
    IF (@useFbImage = -1) SET @useFbImage = NULL;
    IF (@eventPriceForMembers = -1) SET @eventPriceForMembers = NULL;
    IF (@eventPriceForNonMembers = -1) SET @eventPriceForNonMembers = NULL;
    IF (@eventPriceForExtras = -1) SET @eventPriceForExtras = NULL;
    IF (DATALENGTH(@extrasDescription) < 2) SET @extrasDescription = NULL;
    IF (@absoluteEventNumber = -1) SET @absoluteEventNumber = NULL;
    IF (@deleted = -1) SET @deleted = NULL;
    IF (@evtDisseminationAudience = -1) SET @evtDisseminationAudience = NULL;
    IF (@evtDisseminateAllowWebLinks = -1) SET @evtDisseminateAllowWebLinks = NULL;
    IF (@evtDisseminateHashRunsDotOrg = -1) SET @evtDisseminateHashRunsDotOrg = NULL;
    IF (@evtDisseminateOnGlobalGoogleCalendar = -1) SET @evtDisseminateOnGlobalGoogleCalendar = NULL;

    -- ============================================
    -- MAIN TRANSACTION SECTION
    -- ============================================
    
    DECLARE @eventId uniqueidentifier;
    DECLARE @kennelId uniqueidentifier;
    DECLARE @countryIdFromKennel uniqueidentifier;
    DECLARE @resultStr nvarchar(250);
    DECLARE @resultInt int;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Look up kennelId with lock to prevent concurrent modifications
        SELECT @kennelId = id,
               @countryIdFromKennel = CountryId
        FROM HC.Kennel WITH (UPDLOCK, HOLDLOCK)
        WHERE PublicKennelId = @publicKennelId 
          AND @publicKennelId IS NOT NULL;

        IF (@publicKennelId IS NOT NULL) AND (@kennelId IS NULL)
        BEGIN
            ROLLBACK TRANSACTION;
            SET @errorId = NEWID();
            SET @errorTitle = 'No record found with provided @publicKennelId';
            INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) 
            VALUES (@errorId, '<unknown>', 'No record found with provided @publicKennelId', 
                    '@publicKennelId was not found by ' + OBJECT_NAME(@@PROCID), 
                    OBJECT_NAME(@@PROCID), @publicHasherId);
            
            SELECT @errorId as errorId,
                   CAST(2 AS int) as errorType,
                   @errorTitle as errorTitle,
                   '@publicKennelId was not found by ' + OBJECT_NAME(@@PROCID) as errorUserMessage,
                   'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage,
                   OBJECT_NAME(@@PROCID) as errorProc;
            RETURN;
        END

        -- Look up eventId with lock if publicEventId is provided
        IF @publicEventId IS NOT NULL
        BEGIN
            SELECT @eventId = id 
            FROM HC.Event WITH (UPDLOCK, HOLDLOCK)
            WHERE PublicEventId = @publicEventId;

            IF @eventId IS NULL
            BEGIN
                ROLLBACK TRANSACTION;
                SET @errorId = NEWID();
                SET @errorTitle = 'No record found with provided @publicEventId';
                INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) 
                VALUES (@errorId, '<unknown>', 'No record found with provided @publicEventId', 
                        '@publicEventId was not found by ' + OBJECT_NAME(@@PROCID), 
                        OBJECT_NAME(@@PROCID), @publicHasherId);
                
                SELECT @errorId as errorId,
                       CAST(2 AS int) as errorType,
                       @errorTitle as errorTitle,
                       '@publicEventId was not found by ' + OBJECT_NAME(@@PROCID) as errorUserMessage,
                       'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage,
                       OBJECT_NAME(@@PROCID) as errorProc;
                RETURN;
            END
        END

        -- Handle deletion case
        IF ((@deleted IS NOT NULL) AND (@deleted = 1))
        BEGIN
            -- Deletion logic would go here if needed
            -- Currently commented out in original
            COMMIT TRANSACTION;
            SELECT 'Deletion processed' as result, 1 as resultCode;
            RETURN;
        END

        -- ============================================
        -- UPDATE EXISTING EVENT
        -- ============================================
        IF (@eventId IS NOT NULL)
        BEGIN
            UPDATE HC.Event WITH (ROWLOCK)
            SET 
                EventStartDatetime = COALESCE(@eventStartDatetime, EventStartDatetime),
                EventEndDatetime = COALESCE(@eventEndDatetime, EventEndDatetime),
                IsCountedRun = COALESCE(@isCountedRun, IsCountedRun, 0),
                IsVisible = COALESCE(@isVisible, IsVisible, 1),
                CanEditRunAttendence = CASE WHEN @canEditRunAttendence = -2 THEN NULL ELSE COALESCE(@canEditRunAttendence, CanEditRunAttendence) END,
                IsPromotedEvent = COALESCE(@isPromotedEvent, IsPromotedEvent, 0),
                IntegrationEnabled = COALESCE(@integrationEnabled, IntegrationEnabled, 1),
                EventGeographicScope = COALESCE(@eventGeographicScope, EventGeographicScope, 1),
                EventName = COALESCE(@eventName, EventName),
                EventDescription = COALESCE(@eventDescription, EventDescription),
                LocationCity = CASE WHEN @locationCity = '<null>' THEN NULL ELSE COALESCE(@locationCity, LocationCity) END,
                LocationStreet = CASE WHEN @locationStreet = '<null>' THEN NULL ELSE COALESCE(@locationStreet, LocationStreet) END,
                LocationPostCode = CASE WHEN @locationPostCode = '<null>' THEN NULL ELSE COALESCE(@locationPostCode, LocationPostCode) END,
                LocationCountry = CASE WHEN @locationCountry = '<null>' THEN NULL ELSE COALESCE(@locationCountry, LocationCountry) END,
                LocationRegion = CASE WHEN @locationRegion = '<null>' THEN NULL ELSE COALESCE(@locationRegion, LocationRegion) END,
                LocationSubRegion = CASE WHEN @locationSubRegion = '<null>' THEN NULL ELSE COALESCE(@locationSubRegion, LocationSubRegion) END,
                LocationOneLineDesc = CASE WHEN @locationOneLineDesc = '<null>' THEN NULL ELSE COALESCE(@locationOneLineDesc, LocationOneLineDesc) END,
                EventImage = CASE WHEN @eventImage = '<null>' THEN NULL ELSE COALESCE(@eventImage, EventImage) END,
                Latitude = CASE WHEN @hcLatitude = -99.0 THEN NULL ELSE COALESCE(@hcLatitude, Latitude) END,
                Longitude = CASE WHEN @hcLongitude = -999.0 THEN NULL ELSE COALESCE(@hcLongitude, Longitude) END,
                EventGeolocation = CASE 
                    WHEN CASE WHEN @hcLatitude = -99.0 THEN NULL ELSE COALESCE(@hcLatitude, Latitude) END IS NOT NULL THEN
                        geography::Point(
                            CASE WHEN @hcLatitude = -99.0 THEN NULL ELSE COALESCE(@hcLatitude, Latitude) END, 
                            CASE WHEN @hcLongitude = -999.0 THEN NULL ELSE COALESCE(@hcLongitude, Longitude) END, 
                            4326
                        )
                    ELSE NULL
                END,
                EventPriceForMembers = CASE WHEN @eventPriceForMembers = -2 THEN NULL ELSE COALESCE(@eventPriceForMembers, EventPriceForMembers) END,
                EventPriceForNonMembers = CASE WHEN @eventPriceForNonMembers = -2 THEN NULL ELSE COALESCE(@eventPriceForNonMembers, EventPriceForNonMembers) END,
                EventPriceForExtras = CASE WHEN @eventPriceForExtras = -2 THEN NULL ELSE COALESCE(@eventPriceForExtras, EventPriceForExtras) END,
                ExtrasDescription = CASE WHEN @extrasDescription = '<null>' THEN NULL ELSE COALESCE(@extrasDescription, ExtrasDescription) END,
                ExtrasRsvpRequired = COALESCE(@extrasRsvpRequired, ExtrasRsvpRequired, 0),
                AbsoluteEventNumber = CASE WHEN @absoluteEventNumber <= 0 THEN NULL ELSE COALESCE(@absoluteEventNumber, AbsoluteEventNumber) END,
                deleted = COALESCE(@deleted, deleted),
                UseFbLatLon = COALESCE(@useFbLatLon, UseFbLatLon),
                UseFbRunDetails = COALESCE(@useFbRunDetails, UseFbRunDetails),
                UseFbLocation = COALESCE(@useFbLocation, UseFbLocation),
                UseFbImage = COALESCE(@useFbImage, UseFbImage),
                Hares = CASE WHEN @hares = '<null>' THEN NULL ELSE COALESCE(@hares, Hares) END,
                updatedAt = GETDATE(),
                Tags1 = COALESCE(@tags1, Tags1),
                Tags2 = COALESCE(@tags2, Tags2),
                Tags3 = COALESCE(@tags3, Tags3),
                MaximumParticipantsAllowed = CASE WHEN @maximumParticipantsAllowed = -2 THEN NULL ELSE COALESCE(@maximumParticipantsAllowed, MaximumParticipantsAllowed) END,
                MinimumParticipantsRequired = CASE WHEN @minimumParticipantsRequired = -2 THEN NULL ELSE COALESCE(@minimumParticipantsRequired, MinimumParticipantsRequired) END,
                EvtDisseminationAudience = CASE WHEN @evtDisseminationAudience = -2 THEN NULL ELSE COALESCE(@evtDisseminationAudience, EvtDisseminationAudience) END,
                EvtDisseminateAllowWebLinks = CASE WHEN @evtDisseminateAllowWebLinks = 2 THEN NULL ELSE COALESCE(@evtDisseminateAllowWebLinks, EvtDisseminateAllowWebLinks) END,
                EvtDisseminateHashRunsDotOrg = CASE WHEN @evtDisseminateHashRunsDotOrg = -2 THEN NULL ELSE COALESCE(@evtDisseminateHashRunsDotOrg, EvtDisseminateHashRunsDotOrg) END,
                DisseminateOnGlobalGoogleCalendar = CASE WHEN @evtDisseminateOnGlobalGoogleCalendar = -2 THEN NULL ELSE COALESCE(@evtDisseminateOnGlobalGoogleCalendar, DisseminateOnGlobalGoogleCalendar) END,
                EventLastUpdatedSource = 'HC Portal',
                EventLastUpdatedBy = @publicHasherId,
                CountryId = COALESCE(@countryId, CountryId)
            WHERE id = @eventId;

            -- Verify the update succeeded
            IF @@ROWCOUNT = 0
            BEGIN
                ROLLBACK TRANSACTION;
                SET @errorId = NEWID();
                INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) 
                VALUES (@errorId, 'hcportal', 'Concurrent modification detected', 
                        'Event was modified by another user during update', 
                        OBJECT_NAME(@@PROCID), @publicHasherId);
                
                SELECT @errorId as errorId,
                       CAST(4 AS int) as errorType,
                       'Concurrent modification' as errorTitle,
                       'This record was modified by another user. Please refresh and try again.' as errorUserMessage,
                       'Concurrent modification detected' as debugMessage,
                       OBJECT_NAME(@@PROCID) as errorProc;
                RETURN;
            END

            -- Update HEM records if countryId changed
            IF (@countryId IS NOT NULL)
            BEGIN
                UPDATE hem WITH (ROWLOCK)
                SET hem.updatedAt = GETDATE() 
                FROM HC.HasherEventMap hem 
                WHERE hem.EventId = @eventId;
            END

            -- Build result message
            DECLARE @kennelShortNameForAlert nvarchar(100);
            DECLARE @eventNumberForAlert nvarchar(100);

            SELECT @kennelShortNameForAlert = k.KennelShortName,
                   @eventNumberForAlert = CAST(evt.EventNumber AS nvarchar(100)) 
            FROM HC.Event evt 
            INNER JOIN HC.Kennel k ON evt.KennelId = k.id
            WHERE evt.id = @eventId;

            IF (@eventNumberForAlert IS NOT NULL)
            BEGIN
                SET @resultStr = 'Successfully updated ' + @kennelShortNameForAlert + ' run/event #' + @eventNumberForAlert;
            END
            ELSE
            BEGIN
                SET @resultStr = 'Successfully updated ' + @kennelShortNameForAlert + ' run/event';
            END
            SET @resultInt = 1;
        END
        -- ============================================
        -- INSERT NEW EVENT
        -- ============================================
        ELSE
        BEGIN
            -- Generate default event name if needed
            IF (COALESCE(DATALENGTH(@eventName), 0) < 1) 
            BEGIN
                DECLARE @kennelShortName nvarchar(50);
                SELECT @kennelShortName = k.KennelShortName FROM HC.Kennel k WHERE k.id = @kennelId;
                SET @eventName = 'Placeholder event for ' + COALESCE(@kennelShortName, '<no kennel found>');
            END

            IF (DATALENGTH(TRIM(@eventName)) > 0) AND (@kennelId IS NOT NULL) AND (@kennelId <> '00000000-0000-0000-0000-000000000000')
            BEGIN
                -- Handle default start time
                IF ((@eventStartDatetime IS NULL) OR (CAST(@eventStartDatetime AS time) = '00:00:00.0000000'))
                BEGIN
                    DECLARE @defaultStartTime time(7);
                    DECLARE @diffSeconds int;

                    IF (@eventStartDatetime IS NULL)
                    BEGIN
                        SET @eventStartDatetime = DATEADD(day, 3, GETDATE());
                    END

                    SELECT @defaultStartTime = DefaultRunStartTime FROM HC.Kennel WHERE id = @kennelId;

                    IF (@defaultStartTime IS NOT NULL) 
                    BEGIN
                        SELECT @diffSeconds = DATEDIFF(second, '00:00:00', @defaultStartTime);
                        SET @eventStartDatetime = DATEADD(second, @diffSeconds, @eventStartDatetime);
                    END
                END

                SET @eventId = NEWID();
                SET @publicEventId = NEWID();

                INSERT HC.Event WITH (ROWLOCK)
                (
                    id, PublicEventId, KennelId, EventStartDatetime, EventEndDatetime,
                    IsCountedRun, IsVisible, IsPromotedEvent, CanEditRunAttendence,
                    EventGeographicScope, InboundIntegrationId, EventName, EventDescription,
                    LocationCity, LocationStreet, LocationPostCode, LocationCountry,
                    LocationRegion, LocationSubRegion, LocationOneLineDesc, EventImage,
                    Latitude, Longitude, EventGeolocation,
                    EventPriceForMembers, EventPriceForNonMembers, EventPriceForExtras,
                    ExtrasDescription, ExtrasRsvpRequired, IntegrationEnabled, AbsoluteEventNumber,
                    Hares, Tags1, Tags2, Tags3,
                    UseFbImage, UseFbLatLon, UseFbLocation, UseFbRunDetails,
                    MaximumParticipantsAllowed, MinimumParticipantsRequired,
                    EvtDisseminationAudience, EvtDisseminateAllowWebLinks,
                    EvtDisseminateHashRunsDotOrg, DisseminateOnGlobalGoogleCalendar,
                    deleted, updatedAt, EventSource, CountryId
                ) 
                VALUES 
                (
                    @eventId,
                    @publicEventId,
                    @kennelId,
                    CASE WHEN @eventStartDatetime < '1/1/2000' THEN NULL ELSE @eventStartDatetime END,
                    CASE WHEN @eventEndDatetime < '1/1/2000' THEN NULL ELSE @eventEndDatetime END,
                    COALESCE(@isCountedRun, 1),
                    COALESCE(@isVisible, 1),
                    COALESCE(@isPromotedEvent, 0),
                    CASE WHEN @canEditRunAttendence = -2 THEN NULL ELSE @canEditRunAttendence END,
                    COALESCE(@eventGeographicScope, 1),
                    0, -- InboundIntegrationId
                    @eventName,
                    @eventDescription,
                    CASE WHEN @locationCity = '<null>' THEN NULL ELSE @locationCity END,
                    CASE WHEN @locationStreet = '<null>' THEN NULL ELSE @locationStreet END,
                    CASE WHEN @locationPostCode = '<null>' THEN NULL ELSE @locationPostCode END,
                    CASE WHEN @locationCountry = '<null>' THEN NULL ELSE @locationCountry END,
                    CASE WHEN @locationRegion = '<null>' THEN NULL ELSE @locationRegion END,
                    CASE WHEN @locationSubRegion = '<null>' THEN NULL ELSE @locationSubRegion END,
                    CASE WHEN @locationOneLineDesc = '<null>' THEN NULL ELSE @locationOneLineDesc END,
                    CASE WHEN @eventImage = '<null>' THEN NULL ELSE @eventImage END,
                    CASE WHEN @hcLatitude = -99.0 THEN NULL ELSE @hcLatitude END,
                    CASE WHEN @hcLongitude = -999.0 THEN NULL ELSE @hcLongitude END,
                    CASE 
                        WHEN CASE WHEN @hcLatitude = -99.0 THEN NULL ELSE CAST(@hcLatitude AS decimal(18,15)) END IS NOT NULL THEN
                            geography::Point(
                                CASE WHEN @hcLatitude = -99.0 THEN NULL ELSE CAST(@hcLatitude AS decimal(18,15)) END, 
                                CASE WHEN @hcLongitude = -999.0 THEN NULL ELSE CAST(@hcLongitude AS decimal(19,15)) END, 
                                4326
                            )
                        ELSE NULL
                    END,
                    CASE WHEN @eventPriceForMembers = -2 THEN NULL ELSE @eventPriceForMembers END,
                    CASE WHEN @eventPriceForNonMembers = -2 THEN NULL ELSE @eventPriceForNonMembers END,
                    CASE WHEN @eventPriceForExtras = -2 THEN NULL ELSE @eventPriceForExtras END,
                    CASE WHEN DATALENGTH(@extrasDescription) < 2 THEN NULL ELSE @extrasDescription END,
                    COALESCE(@extrasRsvpRequired, 0),
                    COALESCE(@integrationEnabled, 0),
                    CASE WHEN @absoluteEventNumber = -2 THEN NULL ELSE @absoluteEventNumber END,
                    CASE WHEN @hares = '<null>' THEN NULL ELSE @hares END,
                    COALESCE(@tags1, 0),
                    COALESCE(@tags2, 0),
                    COALESCE(@tags3, 0),
                    0, 0, 0, 0, -- Use Fb flags
                    CASE WHEN @maximumParticipantsAllowed = -2 THEN NULL ELSE @maximumParticipantsAllowed END,
                    CASE WHEN @minimumParticipantsRequired = -2 THEN NULL ELSE @minimumParticipantsRequired END,
                    CASE WHEN @evtDisseminationAudience = -2 THEN NULL ELSE @evtDisseminationAudience END,
                    CASE WHEN @evtDisseminateAllowWebLinks = 2 THEN NULL ELSE @evtDisseminateAllowWebLinks END,
                    CASE WHEN @evtDisseminateHashRunsDotOrg = -2 THEN NULL ELSE @evtDisseminateHashRunsDotOrg END,
                    CASE WHEN @evtDisseminateOnGlobalGoogleCalendar = -2 THEN NULL ELSE @evtDisseminateOnGlobalGoogleCalendar END,
                    COALESCE(@deleted, 0),
                    GETDATE(),
                    'HC Portal',
                    COALESCE(@countryId, @countryIdFromKennel)
                );

                SET @resultStr = 'Run added to Harrier Central';
                SET @resultInt = 1;
            END
        END

        -- Save tags as kennel default if requested
        IF (@saveTagsAsKennelDefault = 1)
        BEGIN
            UPDATE HC.Kennel WITH (ROWLOCK)
            SET 
                DefaultRunTags1 = COALESCE(@tags1, DefaultRunTags1),
                DefaultRunTags2 = COALESCE(@tags2, DefaultRunTags2),
                DefaultRunTags3 = COALESCE(@tags3, DefaultRunTags3)
            WHERE id = @kennelId 
              AND (
                  DefaultRunTags1 != COALESCE(@tags1, DefaultRunTags1)
                  OR DefaultRunTags2 != COALESCE(@tags2, DefaultRunTags2)
                  OR DefaultRunTags3 != COALESCE(@tags3, DefaultRunTags3)
              );
        END

        COMMIT TRANSACTION;

        -- Update run numbers (outside transaction for performance)
        EXEC HC.nonApi_updateRunNumbers @eventId = @eventId;

        SELECT @resultStr as result, @resultInt as resultCode, @publicEventId as publicEventId;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @errorId = NEWID();
        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, string_1) 
        VALUES (@errorId, 'hcportal', ERROR_MESSAGE(), 
                'Error in ' + OBJECT_NAME(@@PROCID) + ' at line ' + CAST(ERROR_LINE() AS nvarchar(10)), 
                OBJECT_NAME(@@PROCID), @publicHasherId, 
                'State: ' + CAST(ERROR_STATE() AS nvarchar(10)) + ', Severity: ' + CAST(ERROR_SEVERITY() AS nvarchar(10)));

        SELECT @errorId as errorId,
               CAST(5 AS int) as errorType,
               'Database error' as errorTitle,
               'An unexpected error occurred. Please try again.' as errorUserMessage,
               ERROR_MESSAGE() as debugMessage,
               OBJECT_NAME(@@PROCID) as errorProc;
    END CATCH
END
GO


