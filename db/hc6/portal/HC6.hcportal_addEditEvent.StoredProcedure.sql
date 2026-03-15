CREATE OR ALTER PROCEDURE [HC6].[hcportal_addEditEvent]

-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
@publicHasherId uniqueidentifier = NULL,
@accessToken nvarchar(1000) = NULL,
@publicKennelId uniqueidentifier = NULL,

-- optional parameters
@absoluteEventNumber smallint = null,
@eventImage nvarchar(500) = null,
@eventEndDatetime datetimeoffset(7) = null,
@eventDescription nvarchar(4000) = null,
@eventGeographicScope smallint = null,
@eventName nvarchar(250) = null,
@eventPriceForExtras decimal(10,4) = null,
@eventPriceForMembers decimal(10,4) = null,
@eventPriceForNonMembers decimal(10,4) = null,
@extrasDescription nvarchar(250) = null,
@extrasRsvpRequired smallint = null,
@hares nvarchar(2500) = null,
@integrationEnabled int = null,
@isCountedRun smallint = null,
@isPromotedEvent smallint = null,
@isVisible smallint = null,
@hcLatitude decimal(18,15) = null,
@locationCity nvarchar(250) = null,
@locationCountry nvarchar(250) = null,
@locationOneLineDesc nvarchar(250) = null,
@locationPostCode nvarchar(250) = null,
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
@countryId uniqueidentifier = null

AS
-- =====================================================================
-- Procedure: HC6.hcportal_addEditEvent
-- Description: Creates a new event or updates an existing event for a
--   kennel. Handles event data (name, description, location, pricing,
--   tags, dissemination settings), optionally saves tags as kennel
--   defaults, and triggers run number recalculation.
-- Parameters: @publicHasherId, @accessToken, @publicKennelId,
--   @publicEventId (NULL=insert, non-NULL=update), plus ~40 optional
--   event fields.
-- Returns: On error: HC6 standard envelope (Success, ErrorMessage).
--   On success: result message, resultCode, publicEventId.
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_addEditEvent2
-- Breaking Changes:
--   Renamed from hcportal_addEditEvent2 to hcportal_addEditEvent.
--   Removed @deleted parameter (use hcportal_deleteEvent instead).
--   Removed @ipAddress and @ipGeoDetails (logging moved to API shim).
--   Removed DeletionResult rowset (stub removed).
--   @eventName widened NVARCHAR(120) -> NVARCHAR(250).
--   @locationPostCode widened NVARCHAR(50) -> NVARCHAR(250).
--   @eventPriceForMembers/NonMembers/Extras changed FLOAT -> DECIMAL(10,4).
--   @integrationEnabled changed SMALLINT -> INT.
--   @hcLatitude "set to NULL" sentinel changed from -99.0 to -999.0.
--   @evtDisseminateAllowWebLinks "set to NULL" sentinel changed from 2 to -2.
--   Validation now short-circuits on first error.
--   HC.nonApi_updateRunNumbers moved inside TRY (was outside transaction).
--   Auth validated via HC6.ValidatePortalAuth helper SP.
--   Removed ErrorLog/GeneralLog inserts (logging moved to API shim).
--   All error returns now use HC6 standard envelope (Success, ErrorMessage).
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- ============================================
-- VALIDATION SECTION (before transaction)
-- ============================================

-- Auth validation
DECLARE @authError NVARCHAR(255);
EXEC HC6.ValidatePortalAuth @publicHasherId, @accessToken, @publicKennelId, @authError OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

-- Validate publicKennelId
IF (@publicKennelId IS NULL)
BEGIN
        SELECT 0 AS Success, 'publicKennelId is required' AS ErrorMessage;
        RETURN;
END

-- Validate publicEventId format (if provided)
IF (@publicEventId IS NOT NULL) AND (TRY_CAST(@publicEventId AS uniqueidentifier) IS NULL)
BEGIN
        SELECT 0 AS Success, 'Invalid publicEventId format' AS ErrorMessage;
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
IF (LEN(@eventName) < 1) SET @eventName = NULL;
IF (LEN(@eventDescription) < 1) SET @eventDescription = NULL;
IF (LEN(@locationCity) < 1) SET @locationCity = NULL;
IF (LEN(@locationStreet) < 1) SET @locationStreet = NULL;
IF (LEN(@locationPostCode) < 1) SET @locationPostCode = NULL;
IF (LEN(@locationSubRegion) < 1) SET @locationSubRegion = NULL;
IF (LEN(@locationRegion) < 1) SET @locationRegion = NULL;
IF (LEN(@locationCountry) < 1) SET @locationCountry = NULL;
IF (LEN(@locationOneLineDesc) < 1) SET @locationOneLineDesc = NULL;
IF (LEN(@eventImage) < 3) SET @eventImage = NULL;
IF (LEN(@hares) < 2) SET @hares = NULL;
IF (@hcLatitude = -1) SET @hcLatitude = NULL;
IF (@hcLongitude = -1) SET @hcLongitude = NULL;
IF (@useFbLatLon = -1) SET @useFbLatLon = NULL;
IF (@useFbRunDetails = -1) SET @useFbRunDetails = NULL;
IF (@useFbLocation = -1) SET @useFbLocation = NULL;
IF (@useFbImage = -1) SET @useFbImage = NULL;
IF (@eventPriceForMembers = -1) SET @eventPriceForMembers = NULL;
IF (@eventPriceForNonMembers = -1) SET @eventPriceForNonMembers = NULL;
IF (@eventPriceForExtras = -1) SET @eventPriceForExtras = NULL;
IF (LEN(@extrasDescription) < 1) SET @extrasDescription = NULL;
IF (@absoluteEventNumber = -1) SET @absoluteEventNumber = NULL;
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
                SELECT 0 AS Success, 'Kennel not found' AS ErrorMessage;
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
                        SELECT 0 AS Success, 'Event not found' AS ErrorMessage;
                        RETURN;
                END
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
                        Latitude = CASE WHEN @hcLatitude = -999.0 THEN NULL ELSE COALESCE(@hcLatitude, Latitude) END,
                        Longitude = CASE WHEN @hcLongitude = -999.0 THEN NULL ELSE COALESCE(@hcLongitude, Longitude) END,
                        EventGeolocation = CASE
                                WHEN CASE WHEN @hcLatitude = -999.0 THEN NULL ELSE COALESCE(@hcLatitude, Latitude) END IS NOT NULL THEN
                                        geography::Point(
                                                CASE WHEN @hcLatitude = -999.0 THEN NULL ELSE COALESCE(@hcLatitude, Latitude) END,
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
                        EvtDisseminateAllowWebLinks = CASE WHEN @evtDisseminateAllowWebLinks = -2 THEN NULL ELSE COALESCE(@evtDisseminateAllowWebLinks, EvtDisseminateAllowWebLinks) END,
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
                        SELECT 0 AS Success, 'Concurrent modification detected - please refresh and try again' AS ErrorMessage;
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
                IF (COALESCE(LEN(@eventName), 0) < 1)
                BEGIN
                        DECLARE @kennelShortName nvarchar(50);
                        SELECT @kennelShortName = k.KennelShortName FROM HC.Kennel k WHERE k.id = @kennelId;
                        SET @eventName = 'Placeholder event for ' + COALESCE(@kennelShortName, '<no kennel found>');
                END

                IF (LEN(TRIM(@eventName)) > 0) AND (@kennelId IS NOT NULL) AND (@kennelId <> '00000000-0000-0000-0000-000000000000')
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
                                CASE WHEN @hcLatitude = -999.0 THEN NULL ELSE @hcLatitude END,
                                CASE WHEN @hcLongitude = -999.0 THEN NULL ELSE @hcLongitude END,
                                CASE
                                        WHEN CASE WHEN @hcLatitude = -999.0 THEN NULL ELSE CAST(@hcLatitude AS decimal(18,15)) END IS NOT NULL THEN
                                                geography::Point(
                                                        CASE WHEN @hcLatitude = -999.0 THEN NULL ELSE CAST(@hcLatitude AS decimal(18,15)) END,
                                                        CASE WHEN @hcLongitude = -999.0 THEN NULL ELSE CAST(@hcLongitude AS decimal(19,15)) END,
                                                        4326
                                                )
                                        ELSE NULL
                                END,
                                CASE WHEN @eventPriceForMembers = -2 THEN NULL ELSE @eventPriceForMembers END,
                                CASE WHEN @eventPriceForNonMembers = -2 THEN NULL ELSE @eventPriceForNonMembers END,
                                CASE WHEN @eventPriceForExtras = -2 THEN NULL ELSE @eventPriceForExtras END,
                                CASE WHEN LEN(@extrasDescription) < 1 THEN NULL ELSE @extrasDescription END,
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
                                CASE WHEN @evtDisseminateAllowWebLinks = -2 THEN NULL ELSE @evtDisseminateAllowWebLinks END,
                                CASE WHEN @evtDisseminateHashRunsDotOrg = -2 THEN NULL ELSE @evtDisseminateHashRunsDotOrg END,
                                CASE WHEN @evtDisseminateOnGlobalGoogleCalendar = -2 THEN NULL ELSE @evtDisseminateOnGlobalGoogleCalendar END,
                                0, -- deleted defaults to 0
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

        -- Update run numbers (now inside transaction for consistency)
        EXEC HC.nonApi_updateRunNumbers @eventId = @eventId;

        COMMIT TRANSACTION;

        SELECT @resultStr as result, @resultInt as resultCode, @publicEventId as publicEventId;

END TRY
BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
