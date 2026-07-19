CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getEventTrailTypes]

    @eventId UNIQUEIDENTIFIER
    -- The run's INTERNAL id (HC.Event.id) — the same id PackTrack uses to key
    -- positions in Table Storage. NOT PublicEventId. The GetPositions function
    -- already holds the internal id, so it passes that through.

AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getEventTrailTypes
-- Description: Returns the owning kennel's per-kennel PackTrack trail-type
--   config JSON for a given event. Called by the GetPositions function, which
--   bundles it into the position payload on the full fetch only — making the
--   playback payload self-describing so trail-type labels resolve on app and
--   web even when the viewer does not follow the kennel. Unauthenticated read;
--   no PII (config is just labels/emoji a kennel chose).
-- Parameters:
--   @eventId - HC.Event.id (internal event id).
-- Returns:
--   Rowset 0: { trailTypesConfigJson } — single row; NULL when the kennel has
--             no customisation (clients fall back to built-in defaults). 0 rows
--             when the event is not found.
--   On validation error: { Success = 0, ErrorMessage }
-- Author:      Harrier Central
-- Created:     2026-06-26
-- HC5 Source:  None — new for HC6 PackTrack trail types
-- =====================================================================
SET NOCOUNT ON;

IF (@eventId IS NULL OR @eventId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SELECT 0 AS Success, '@eventId is required' AS ErrorMessage;
    RETURN;
END

-- Wrap the body so any runtime error is LOGGED to HC.ErrorLog before it reaches
-- the client, then re-raised (THROW) instead of vanishing as a raw HTTP 500.
BEGIN TRY

SELECT TOP 1
    k.TrailTypesConfigJson AS trailTypesConfigJson
FROM HC.Event e
INNER JOIN HC.Kennel k ON k.id = e.KennelId
WHERE e.id = @eventId;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in getEventTrailTypes',
            ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), NULL);
    THROW;
END CATCH
