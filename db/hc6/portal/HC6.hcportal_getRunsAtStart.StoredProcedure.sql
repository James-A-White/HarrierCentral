CREATE OR ALTER PROCEDURE [HC6].[hcportal_getRunsAtStart]

    @deviceId           UNIQUEIDENTIFIER = NULL,
    @accessToken        NVARCHAR(1000)   = NULL,
    @publicKennelId     UNIQUEIDENTIFIER = NULL,
    @publicEventId      UNIQUEIDENTIFIER = NULL,
    @eventStartDatetime DATETIMEOFFSET(7) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getRunsAtStart
-- Description: The portal's half of E3.F1.S8 (run editing parity with
--   hcapp_getRunsAtStart): the kennel's other runs at the same local date
--   and time as a run about to be saved, so the editor can ask "Another
--   run at this time?" before a new run or a changed start is saved. The
--   rule is HC6.RunsAtLocalStart. Missing input or a caller who may not
--   edit the kennel's runs gets an empty list, never an error.
-- Parameters:
--   @deviceId / @accessToken - portal device auth (standard token)
--   @publicKennelId          - the run's kennel
--   @publicEventId           - the run being saved, by its public id (the
--                              one the portal minted for a new run); never
--                              matches itself
--   @eventStartDatetime      - the start exactly as addEditEvent will be
--                              sent it; its local wall clock is compared
-- Returns:
--   rowset 0 — { Success, ErrorMessage } (Success = 0 only on auth failure)
--   rowset 1 — { publicEventId, eventName, eventNumber, isVisible }, one
--              row per run at that time (none = no clash)
-- Author: Harrier Central
-- Created: 2026-10-14
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @authError NVARCHAR(255), @hasherId UNIQUEIDENTIFIER, @callerType INT;

EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, NULL, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

DECLARE @kennelId UNIQUEIDENTIFIER;

BEGIN TRY
    SELECT 1 AS Success, NULL AS ErrorMessage;

    SELECT @kennelId = k.id FROM HC.Kennel k WHERE k.PublicKennelId = @publicKennelId;
    IF (@kennelId IS NULL OR @eventStartDatetime IS NULL)
    BEGIN
        SELECT TOP 0 CAST(NULL AS NVARCHAR(40)) AS publicEventId, CAST(NULL AS NVARCHAR(250)) AS eventName,
               CAST(NULL AS SMALLINT) AS eventNumber, CAST(NULL AS BIT) AS isVisible;
        RETURN;
    END

    -- The run's internal id, at the door; a public id not yet saved
    -- (a new run) resolves to nothing and excludes nothing.
    DECLARE @eventId UNIQUEIDENTIFIER;
    IF (@publicEventId IS NOT NULL)
        SELECT @eventId = e.id FROM HC.Event e
        WHERE e.PublicEventId = @publicEventId AND e.KennelId = @kennelId;

    -- The same gate as hcportal_addEditEvent.
    DECLARE @allowed SMALLINT = 0;
    EXEC HC6.nonApi_portalKennelAccess @hasherId = @hasherId, @callerType = @callerType,
         @kennelId = @kennelId, @flagMask = 0x00000085, @functionKey = 'createEditRuns',
         @platformCap = 'CanEditKennel', @allowed = @allowed OUTPUT;

    SELECT LOWER(CAST(r.publicEventId AS NVARCHAR(40))) AS publicEventId,
           r.eventName,
           r.eventNumber,
           r.isVisible
    FROM HC6.RunsAtLocalStart(@kennelId, CAST(@eventStartDatetime AS DATETIME2(7)), @eventId) r
    WHERE @allowed = 1
    ORDER BY r.eventNumber, r.eventName;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (NEWID(), '<portal>', 'Unhandled error in getRunsAtStart',
            ERROR_MESSAGE(), @procName, @hasherId, @kennelId);
    THROW;
END CATCH
GO
