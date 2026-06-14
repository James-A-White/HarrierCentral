-- =====================================================================
-- Procedure: HC6.util_fixAllRunNumbers
-- Description: Recalculates EventNumber for every qualifying event
--              across all kennels in a single pass. Applies the same
--              island-group logic as nonApi_updateRunNumbers but
--              partitioned by KennelId, so each kennel's numbering is
--              independent. Intended as a maintenance sweep to fix any
--              EventNumber = 0 or stale-number inconsistencies left by
--              trigger timing gaps or bulk data operations.
-- Parameters:  None.
-- Returns:
--   Rowset 0 — Per-kennel summary of events corrected (only kennels
--              with at least one change are included).
--   Rowset 1 — Total event count corrected across all kennels.
-- Author: Harrier Central
-- Created: 2026-06-14
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[util_fixAllRunNumbers]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        CREATE TABLE #Updated (
            EventId     UNIQUEIDENTIFIER NOT NULL,
            KennelId    UNIQUEIDENTIFIER NOT NULL,
            OldNumber   SMALLINT         NOT NULL,
            NewNumber   SMALLINT         NOT NULL
        );

        -- Assign each qualifying event to an island group (grp) within
        -- its kennel: a running count of AbsoluteEventNumber anchors seen
        -- so far (ordered by date, id). Partitioned by KennelId so each
        -- kennel's sequence is independent.
        ;WITH numbered AS (
            SELECT
                evt.id                          AS EventId,
                evt.KennelId,
                evt.AbsoluteEventNumber,
                evt.EventNumber,
                evt.EventStartDatetimeIndexed,
                SUM(CASE WHEN evt.AbsoluteEventNumber IS NOT NULL THEN 1 ELSE 0 END)
                    OVER (
                        PARTITION BY evt.KennelId
                        ORDER BY     evt.EventStartDatetimeIndexed ASC, evt.id ASC
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                    )                           AS grp
            FROM   HC.Event evt
            WHERE  evt.IsCountedRun              = 1
              AND  evt.IsVisible                 = 1
              AND  evt.removed                   = 0
              AND  evt.deleted                   = 0
              AND  evt.EventStartDatetimeIndexed IS NOT NULL
        ),
        -- Compute the correct EventNumber for every row.
        --   Anchor rows:     keep their AbsoluteEventNumber directly.
        --   Non-anchor rows: sequential from the segment anchor value;
        --                    segments with no anchor start from 1.
        computed AS (
            SELECT
                n.EventId,
                n.KennelId,
                n.EventNumber,
                COALESCE(
                    n.AbsoluteEventNumber,
                    CAST(
                        ROW_NUMBER() OVER (
                            PARTITION BY n.KennelId, n.grp
                            ORDER BY     n.EventStartDatetimeIndexed ASC, n.EventId ASC
                        ) - 1
                        + COALESCE(
                            MAX(n.AbsoluteEventNumber) OVER (PARTITION BY n.KennelId, n.grp),
                            1
                        )
                    AS SMALLINT)
                )                               AS NewEventNumber
            FROM   numbered n
        )
        UPDATE evt
        SET    evt.EventNumber = c.NewEventNumber,
               evt.updatedAt  = CONVERT(datetimeoffset(7), SYSDATETIMEOFFSET(), 0)
        OUTPUT inserted.id,
               inserted.KennelId,
               deleted.EventNumber,
               inserted.EventNumber
        INTO   #Updated (EventId, KennelId, OldNumber, NewNumber)
        FROM   HC.Event evt
        INNER  JOIN computed c ON c.EventId = evt.id
        WHERE  c.NewEventNumber != evt.EventNumber;

        COMMIT TRANSACTION;

        -- Rowset 0: per-kennel breakdown
        SELECT
            k.KennelName,
            COUNT(*)         AS EventsFixed,
            MIN(u.OldNumber) AS OldMin,
            MAX(u.OldNumber) AS OldMax,
            MIN(u.NewNumber) AS NewMin,
            MAX(u.NewNumber) AS NewMax
        FROM   #Updated u
        JOIN   HC.Kennel k ON k.id = u.KennelId
        GROUP  BY u.KennelId, k.KennelName
        ORDER  BY k.KennelName;

        -- Rowset 1: totals
        SELECT COUNT(*) AS TotalEventsFixed FROM #Updated;

        DROP TABLE #Updated;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH

END
