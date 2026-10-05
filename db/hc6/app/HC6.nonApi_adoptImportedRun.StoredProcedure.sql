CREATE OR ALTER PROCEDURE [HC6].[nonApi_adoptImportedRun]
    @eventId UNIQUEIDENTIFIER = NULL,
    @adopted SMALLINT = 0 OUTPUT       -- 1 = the run was an AI runs-page import and is now Harrier Central's
AS
-- =====================================================================
-- Procedure: HC6.nonApi_adoptImportedRun
-- Description: A run imported from a kennel's runs page by AI
--   (InboundIntegrationId 6) that somebody edits in a Harrier Central
--   editor becomes a Harrier Central run, and the AI stops updating it
--   (James, 2026-10-05). Called by hcportal_addEditEvent and
--   hcapp_addEditEvent BEFORE they apply the edit, inside their
--   transaction:
--     1. whatever the run was SHOWING from the import (the Fb* mirror
--        while a UseFb* flag is on) is copied into its own columns, so the
--        edit starts from what the editor displayed and nothing visible is
--        lost;
--     2. InboundIntegrationId -> 0 and every UseFb* flag -> 0.
--   The caller re-clears the UseFb* flags after its own UPDATE (an editor
--   may send them back as 1). nonApi_importRunsPageRuns refreshes only
--   rows still on integration 6, so its later reads report this run
--   "already in Harrier Central" and leave it alone. EventFacebookId
--   ('runspage:<n>') is kept as a record of where it came from.
-- Returns: nothing (@adopted).
-- Author: Harrier Central
-- Created: 2026-10-05
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

SET @adopted = 0;
BEGIN TRY
    UPDATE HC.Event WITH (ROWLOCK) SET
        EventName           = CASE WHEN UseFbRunDetails = 1 THEN COALESCE(FbEventName, EventName) ELSE EventName END,
        EventDescription    = CASE WHEN UseFbRunDetails = 1 THEN COALESCE(FbEventDescription, EventDescription) ELSE EventDescription END,
        LocationOneLineDesc = CASE WHEN UseFbRunDetails = 1 THEN COALESCE(FbLocationOneLineDesc, LocationOneLineDesc) ELSE LocationOneLineDesc END,
        LocationStreet      = CASE WHEN UseFbLocation = 1 THEN COALESCE(FbLocationStreet, LocationStreet) ELSE LocationStreet END,
        LocationCity        = CASE WHEN UseFbLocation = 1 THEN COALESCE(FbLocationCity, LocationCity) ELSE LocationCity END,
        LocationPostCode    = CASE WHEN UseFbLocation = 1 THEN COALESCE(FbLocationPostCode, LocationPostCode) ELSE LocationPostCode END,
        LocationSubRegion   = CASE WHEN UseFbLocation = 1 THEN COALESCE(FbLocationSubRegion, LocationSubRegion) ELSE LocationSubRegion END,
        LocationRegion      = CASE WHEN UseFbLocation = 1 THEN COALESCE(FbLocationRegion, LocationRegion) ELSE LocationRegion END,
        LocationCountry     = CASE WHEN UseFbLocation = 1 THEN COALESCE(FbLocationCountry, LocationCountry) ELSE LocationCountry END,
        Latitude            = CASE WHEN UseFbLatLon = 1 AND FbLatitude IS NOT NULL THEN FbLatitude ELSE Latitude END,
        Longitude           = CASE WHEN UseFbLatLon = 1 AND FbLatitude IS NOT NULL THEN FbLongitude ELSE Longitude END,
        EventImage          = CASE WHEN UseFbImage = 1 THEN COALESCE(FbEventImage, EventImage) ELSE EventImage END,
        InboundIntegrationId = 0,
        UseFbRunDetails = 0, UseFbLocation = 0, UseFbLatLon = 0, UseFbImage = 0
    WHERE id = @eventId AND InboundIntegrationId = 6;
    IF @@ROWCOUNT = 1 SET @adopted = 1;
END TRY
BEGIN CATCH
    -- Inside the caller's transaction: let the caller roll back and log.
    THROW;
END CATCH
GO
