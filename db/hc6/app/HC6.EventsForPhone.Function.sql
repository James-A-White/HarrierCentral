CREATE OR ALTER FUNCTION [HC6].[EventsForPhone] ()
RETURNS TABLE
AS
-- =====================================================================
-- Function: HC6.EventsForPhone
-- Description: Every run in the exact column shape the phone stores in
--   common_events — the projection of hcapp_syncUserData's events rowsets
--   (first column eventId, which is how the app recognises the rowset).
--   Inline, so a caller's WHERE is pushed into the plan. Created
--   2026-10-04 for hcapp_getRunForPhone (open ONE run that is not on the
--   phone, without following its kennel). hcapp_syncUserData still holds
--   its own copies of this list: a column added there must be added here,
--   until those selects are moved onto this function.
-- Author: Harrier Central
-- Created: 2026-10-04
-- =====================================================================
RETURN
    SELECT
        evt.id                                                              AS eventId,
        evt.PublicEventId                                                   AS publicEventId,
        evt.KennelId                                                        AS kennelId,
        evt.IsVisible                                                       AS isVisible,
        evt.IsCountedRun                                                    AS isCountedRun,
        evt.EventGeographicScope                                            AS eventGeographicScope,
        evt.InboundIntegrationId                                            AS eventInboundIntegrationId,
        evt.IsPromotedEvent                                                 AS isPromotedEvent,
        evt.EventNumber                                                     AS eventNumber,
        evt.EventPriceForMembers                                            AS eventPriceForMembers,
        evt.EventPriceForNonMembers                                         AS eventPriceForNonMembers,
        evt.EventPriceForExtras                                             AS eventPriceForExtras,
        evt.ExtrasDescription                                               AS extrasDescription,
        evt.DoTrackHashCash                                                 AS doTrackHashCash,
        evt.EventFacebookId                                                 AS eventFacebookId,
        evt.AbsoluteEventNumber                                             AS absoluteEventNumber,
        evt.CanEditRunAttendence                                            AS canEditRunAttendence,
        evt.TrackRunnerCount                                                AS trackRunnerCount,
        evt.PhotoCount                                                      AS photoCount,
        evt.MessageCount                                                    AS messageCount,
        evt.DownDownCount                                                   AS downDownCount,
        evt.Hares                                                           AS hares,
        evt.EventPaymentScheme                                              AS eventPaymentScheme,
        evt.EventPaymentUrl                                                 AS eventPaymentUrl,
        evt.EventPaymentUrlExpires                                          AS eventPaymentUrlExpires,
        evt.UnconfirmedBankXferCount                                        AS unconfirmedBankXferCount,
        evt.EvtDisseminateAllowWebLinks                                     AS evtDisseminateAllowWebLinks,
        evt.Tags1                                                           AS tags1,
        evt.Tags2                                                           AS tags2,
        evt.Tags3                                                           AS tags3,
        CASE WHEN evt.UseFbImage      = 1 THEN evt.FbEventImage         ELSE evt.EventImage         END AS eventImage,
        evt.EventCoverPhotoUrl                                              AS eventCoverPhotoUrl,
        CASE WHEN evt.UseFbRunDetails = 1 THEN evt.FbEventName          ELSE evt.EventName          END AS eventName,
        CONVERT(DATETIME2, evt.EventStartDatetime) AS eventStartDatetime,
        CONVERT(DATETIME2, evt.EventStartDatetimeGmt) AS eventStartDatetimeGmt,
        CASE WHEN evt.UseFbRunDetails = 1 THEN evt.FbEventDescription   ELSE evt.EventDescription   END AS eventDescription,
        CASE WHEN evt.UseFbRunDetails = 1 THEN evt.FbLocationOneLineDesc ELSE evt.LocationOneLineDesc END AS locationOneLineDesc,
        evt.EventUrl                                                        AS eventUrl,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationPostCode   ELSE evt.LocationPostCode   END AS locationPostCode,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationCity       ELSE evt.LocationCity       END AS locationCity,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationStreet     ELSE evt.LocationStreet     END AS locationStreet,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationCountry    ELSE evt.LocationCountry    END AS locationCountry,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationRegion     ELSE evt.LocationRegion     END AS locationRegion,
        CASE WHEN evt.UseFbLocation   = 1 THEN evt.FbLocationSubRegion  ELSE evt.LocationSubRegion  END AS locationSubRegion,
        evt.removed                                                         AS removed,
        CONVERT(NVARCHAR(50), CAST(evt.updatedAt AS DATETIME2))             AS updatedAt,
        evt.UseFbLocation                                                   AS useFbLocation,
        evt.UseFbLatLon                                                     AS useFbLatLon,
        evt.UseFbRunDetails                                                 AS useFbRunDetails,
        evt.UseFbImage                                                      AS useFbImage,
        evt.Latitude                                                        AS hcLatitude,
        evt.Longitude                                                       AS hcLongitude,
        evt.CountryId                                                       AS countryId,
        COALESCE(evt.w3wLatitude,  evt.FbLatitude)                          AS fbLatitude,
        COALESCE(evt.w3wLongitude, evt.FbLongitude)                         AS fbLongitude
    FROM HC.Event evt;
GO
