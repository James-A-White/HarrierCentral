CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getRunPhotos]

    @publicEventId UNIQUEIDENTIFIER
    -- The run's public-facing UUID (HC.Event.PublicEventId), not the internal id.

AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getRunPhotos
-- Description: Returns Hash-Flash-approved photos (status=2) for a run.
--   Used by the mobile guest gallery and public website. Unauthenticated.
-- Parameters:
--   @publicEventId - HC.Event.PublicEventId (public-facing UUID)
-- Returns:
--   Rowset 0: { EventFound = 1 } — 0 rows when event not found (→ 404)
--   Rowset 1: approved photo rows (may be empty when no approved photos)
--   On validation error: { Success = 0, ErrorMessage }
-- Author:      Harrier Central
-- Created:     2026-05-20
-- Updated:     2026-06-06 — param renamed to @publicEventId, lookup via PublicEventId
-- HC5 Source:  None — new for HC6 KennelPhotos
-- =====================================================================
SET NOCOUNT ON;

IF (@publicEventId IS NULL OR @publicEventId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SELECT 0 AS Success, '@publicEventId is required' AS ErrorMessage;
    RETURN;
END

-- Rowset 0: existence check (0 rows → event not found → shim returns 404)
SELECT TOP 1 1 AS EventFound
FROM HC.Event
WHERE PublicEventId = @publicEventId;

-- Rowset 1: approved photo rows ordered oldest-first for chronological display.
-- NOTE: Latitude and Longitude are intentionally excluded — this is an
-- unauthenticated public endpoint and GPS coordinates must not be exposed (M15 fix).
SELECT
    kp.id           AS photoId,
    kp.BlobUrl,
    kp.Title,
    kp.Description,
    kp.CreatedAt,
    h.DisplayName   AS uploaderDisplayName
FROM HC.KennelPhotos kp
INNER JOIN HC.Event   e ON e.id = kp.EventId AND e.PublicEventId = @publicEventId
INNER JOIN HC.Hasher  h ON h.id = kp.UserId
WHERE kp.Status    >= 3  -- audience model: Public(3) and Cover(5) only
  AND kp.DeletedAt IS NULL
ORDER BY kp.CreatedAt ASC;
