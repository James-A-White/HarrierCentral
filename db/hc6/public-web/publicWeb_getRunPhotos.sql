CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getRunPhotos]

    @eventId UNIQUEIDENTIFIER

AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getRunPhotos
-- Description: Returns public photos (status=2) for a given run.
--   Used by the public website run detail page to display approved
--   photos. Unauthenticated — returns only Hash Flash-approved photos.
-- Parameters:
--   @eventId - The run to fetch public photos for
-- Returns:
--   Rowset 0: { TotalPhotos INT } — 0 rows when event not found (→ 404)
--   Rowset 1: public photo rows (may be empty when no approved photos)
--   On error: { Success=0, ErrorMessage }
-- Author:      Harrier Central
-- Created:     2026-05-20
-- HC5 Source:  None — new for HC6 KennelPhotos
-- =====================================================================
SET NOCOUNT ON;

IF (@eventId IS NULL OR @eventId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SELECT 0 AS Success, '@eventId is required' AS ErrorMessage;
    RETURN;
END

-- Rowset 0: total count (0 rows → event not found → shim returns 404)
SELECT COUNT(*) AS TotalPhotos
FROM HC.KennelPhotos kp
INNER JOIN HC.Event e ON e.id = kp.EventId
WHERE kp.EventId = @eventId
  AND kp.Status  = 2
  AND e.id IS NOT NULL;

-- Rowset 1: public photo rows
SELECT
    kp.id           AS photoId,
    kp.BlobUrl,
    kp.Latitude,
    kp.Longitude,
    kp.Title,
    kp.Description,
    kp.CreatedAt,
    h.DisplayName   AS uploaderDisplayName
FROM HC.KennelPhotos kp
INNER JOIN HC.Hasher h ON h.id = kp.UserId
WHERE kp.EventId = @eventId
  AND kp.Status  = 2
ORDER BY kp.CreatedAt ASC;
