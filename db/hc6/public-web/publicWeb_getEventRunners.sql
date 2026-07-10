CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getEventRunners]

    @publicEventId UNIQUEIDENTIFIER,
    -- The run's public-facing UUID (HC.Event.PublicEventId), not the internal id.

    @userIds NVARCHAR(MAX)
    -- Pipe-delimited ('|') list of runner user ids (HC.Hasher.id) taken from the
    -- PackTrack position payload, whose display names we want to resolve.

AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getEventRunners
-- Description: Resolves PackTrack runner ids to public display names for the
--   run map on the public website. Unauthenticated. The ids are already exposed
--   via the public GetPositions endpoint; this only maps them to the hasher's
--   public DisplayName and profile Photo. No email/PII.
--   NOTE: IncludeInGlobalHashDirectory must NOT be used as a filter here (or
--   anywhere) — it belongs to the unimplemented Global Hash Directory feature
--   and is not a privacy/consent flag.
-- Parameters:
--   @publicEventId - HC.Event.PublicEventId (public-facing UUID); used as an
--                    existence guard so an empty name list is not treated as 404.
--   @userIds       - '|'-delimited HC.Hasher.id list.
-- Returns:
--   Rowset 0: { EventFound = 1 } — 0 rows when the event is not found (-> 404)
--   Rowset 1: { userId, displayName, photo } per resolved runner (may be empty)
--   On validation error: { Success = 0, ErrorMessage }
-- Author:      Harrier Central
-- Created:     2026-06-23
-- HC5 Source:  None — new for HC6 public-web PackTrack
-- =====================================================================
SET NOCOUNT ON;

IF (@publicEventId IS NULL OR @publicEventId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SELECT 0 AS Success, '@publicEventId is required' AS ErrorMessage;
    RETURN;
END

-- Rowset 0: existence check (0 rows -> event not found -> shim returns 404)
SELECT TOP 1 1 AS EventFound
FROM HC.Event
WHERE PublicEventId = @publicEventId;

-- Rowset 1: display names for the requested runner ids. ids are lowercased to
-- match the (lowercased) ids the frontend holds from the position payload.
SELECT
    LOWER(CONVERT(NVARCHAR(36), h.id)) AS userId,
    h.DisplayName                       AS displayName,
    h.Photo                             AS photo
FROM HC.Hasher h
WHERE h.id IN (
        SELECT TRY_CONVERT(UNIQUEIDENTIFIER, value)
        FROM STRING_SPLIT(@userIds, '|')
        WHERE TRY_CONVERT(UNIQUEIDENTIFIER, value) IS NOT NULL
    )
  AND h.deleted = 0
  AND ISNULL(h.Removed, 0) = 0;
