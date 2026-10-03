CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getOfficialTrail]
    @publicEventId UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.publicWeb_getOfficialTrail
-- Description: A run's official (hare's) trail for the public run page
--   (E5.F6.S6, James 2026-10-03): one lane per trail type, drawn as THE
--   trail, its length shown as the run's distance, downloadable as GPX.
--   Hidden until the run has ENDED — start + 4 hours (On Inn detection is
--   app-side, later) — so a trail is never public while it is being run;
--   during the run only a lost runner's own app sees it (I'm-lost flow).
-- Parameters: @publicEventId - HC.Event.PublicEventId
-- Returns:
--   Rowset 0: { EventFound, Available, OfficialTrailInfo }
--             Available 0 = none set, or not yet public.
--   Rowset 1: { OfficialTrail } — the trail JSON
--             {"lanes":[{"type":3,"points":[[lat,lon],...]}]}; only when
--             Available = 1.
-- Author: Harrier Central
-- Created: 2026-10-03
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    DECLARE @found INT = 0, @available INT = 0, @info NVARCHAR(MAX), @trail VARBINARY(MAX);
    SELECT @found = 1,
           @available = CASE WHEN e.OfficialTrailGzip IS NOT NULL
                              AND DATEADD(HOUR, 4, e.EventStartDatetimeGmt) <= SYSDATETIMEOFFSET()
                             THEN 1 ELSE 0 END,
           @info  = e.OfficialTrailInfo,
           @trail = e.OfficialTrailGzip
    FROM HC.Event e
    WHERE e.PublicEventId = @publicEventId AND e.deleted = 0 AND ISNULL(e.removed, 0) = 0 AND e.IsVisible = 1;

    SELECT @found AS EventFound, @available AS Available,
           CASE WHEN @available = 1 THEN @info END AS OfficialTrailInfo;
    IF (@available = 1)
        SELECT CAST(DECOMPRESS(@trail) AS NVARCHAR(MAX)) AS OfficialTrail;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in getOfficialTrail', ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
GO
