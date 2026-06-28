-- =====================================================================
-- Procedure: HC6.nonApi_updateRunNumbers
-- Description: Recalculates EventNumber for all counted, visible,
--              non-removed events in a kennel. Events are partitioned
--              by the nearest preceding AbsoluteEventNumber anchor;
--              within each segment, numbers run sequentially from the
--              anchor value (or from 1 when no anchor exists).
-- Parameters:
--   @kennelId - Kennel to recalculate. If NULL or empty GUID,
--               resolved from @eventId.
--   @eventId  - Any event in the target kennel. Used only to resolve
--               @kennelId when not supplied directly.
-- Returns:    Nothing. Internal helper called by portal/app SPs and
--             trgRecalculateRunCounts.
-- Author: Harrier Central
-- Created: 2026-06-10
-- HC5 Source: HC.nonApi_updateRunNumbers
-- Performance: O(N²) correlated subquery replaced with O(N log N)
--              grp-island window function pattern.
-- Breaking Changes: None (identical semantics, faster execution).
-- Fixes vs HC5:
--   - EventStartLocal IS NOT NULL guard: rows without a
--     date (data integrity gap or trigger timing) are excluded rather
--     than silently sorting first (NULLs first in ASC) and stealing
--     run number 1.
--   - deleted = 0 filter added for completeness.
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[nonApi_updateRunNumbers]
    @kennelId   UNIQUEIDENTIFIER = NULL,
    @eventId    UNIQUEIDENTIFIER = '00000000-0000-0000-0000-000000000000'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Resolve kennelId from eventId when not supplied directly
    IF (@kennelId IS NULL OR @kennelId = '00000000-0000-0000-0000-000000000000')
    BEGIN
        SELECT @kennelId = KennelId
        FROM   HC.Event
        WHERE  id = @eventId;
    END

    -- Assign each qualifying event to an island group (grp): a running
    -- count of AbsoluteEventNumber anchors seen so far (ordered by
    -- date, id). Every anchor and every event that follows it (up to
    -- the next anchor) share the same grp value.
    ;WITH numbered AS (
        SELECT
            evt.id                    AS EventId,
            evt.AbsoluteEventNumber,
            evt.EventNumber,
            evt.EventStartLocal,
            SUM(CASE WHEN evt.AbsoluteEventNumber IS NOT NULL THEN 1 ELSE 0 END)
                OVER (
                    ORDER BY evt.EventStartLocal ASC, evt.id ASC
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                )                     AS grp
        FROM   HC.Event evt
        WHERE  evt.KennelId                    = @kennelId
          AND  evt.IsCountedRun                = 1
          AND  evt.IsVisible                   = 1
          AND  evt.removed                     = 0
          AND  evt.deleted                     = 0
          AND  evt.EventStartLocal   IS NOT NULL
    ),
    -- Compute the new EventNumber for every row.
    --   Anchor rows:      keep their AbsoluteEventNumber (COALESCE short-circuits).
    --   Non-anchor rows:  sequential from the segment anchor value;
    --                     segments with no anchor start from 1.
    computed AS (
        SELECT
            n.EventId,
            n.EventNumber,
            COALESCE(
                n.AbsoluteEventNumber,
                CAST(
                    ROW_NUMBER() OVER (
                        PARTITION BY n.grp
                        ORDER BY     n.EventStartLocal ASC, n.EventId ASC
                    ) - 1
                    + COALESCE(
                        MAX(n.AbsoluteEventNumber) OVER (PARTITION BY n.grp),
                        1
                    )
                AS SMALLINT)
            )                         AS NewEventNumber
        FROM   numbered n
    )
    UPDATE evt
    SET    evt.EventNumber = c.NewEventNumber,
           evt.updatedAt   = GETDATE()
    FROM   HC.Event evt
    INNER  JOIN computed c ON c.EventId = evt.id
    WHERE  c.NewEventNumber != evt.EventNumber;

END
