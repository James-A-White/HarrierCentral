CREATE OR ALTER PROCEDURE [HC6].[nonApi_ensureTrackAttendance]
    @eventId UNIQUEIDENTIFIER,
    @userId  UNIQUEIDENTIFIER
AS
-- =====================================================================
-- Procedure: HC6.nonApi_ensureTrackAttendance
-- Description: A runner who has a PackTrack trail on a run was there, so
--   they get an attendance row if they have none (James, 2026-09-10: every
--   runner who has a track has an attendance row). Called by the nightly
--   track archive (TrackArchiver) when it finds points in a run's partition
--   for a hasher with no HC.HasherEventMap row — the tracks recorded before
--   the app started checking the tracker in as tracking begins.
--   The row is written exactly as hcapp_setEventAttendence writes a fresh
--   At Hash check-in (AttendenceState 20, RSVP Yes, not hare, not
--   virgin/visitor) and the hasher's run counts are recomputed the same way,
--   so the archive's attendance row is indistinguishable from a real one.
--   A row that exists below At Hash (an RSVP, a No) is raised to At Hash /
--   RSVP Yes, as a check-in would. A removed row is left alone (an admin's
--   removal is not undone); a missing hasher or event does nothing.
--   2026-09-11: also used by the track-import processor for every imported
--   activity, so an import on a run you RSVPed to counts.
-- Parameters:
--   @eventId - The run.
--   @userId  - The runner.
-- Returns: one row — Inserted (1 created, 0 otherwise), Reason ('inserted' |
--   'raised' | 'rowExists' | 'noHasher' | 'noEvent').
-- Author: Harrier Central
-- Created: 2026-09-10
-- HC5 Source: none (new) — insert mirrors HC6.hcapp_setEventAttendence
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @kennelId UNIQUEIDENTIFIER;

DECLARE @existingState SMALLINT = (SELECT TOP (1) AttendenceState FROM HC.HasherEventMap
                                    WHERE EventId = @eventId AND UserId = @userId AND removed = 0
                                    ORDER BY AttendenceState DESC);
IF (@existingState IS NOT NULL AND @existingState >= 20)
BEGIN
    SELECT 0 AS Inserted, 'rowExists' AS Reason;
    RETURN;
END
IF EXISTS (SELECT 1 FROM HC.HasherEventMap WHERE EventId = @eventId AND UserId = @userId AND removed = 1)
   AND @existingState IS NULL
BEGIN
    SELECT 0 AS Inserted, 'rowExists' AS Reason;   -- an admin removed them; not undone here
    RETURN;
END
IF NOT EXISTS (SELECT 1 FROM HC.Hasher WHERE id = @userId AND deleted = 0)
BEGIN
    SELECT 0 AS Inserted, 'noHasher' AS Reason;
    RETURN;
END
SELECT @kennelId = KennelId FROM HC.Event WHERE id = @eventId AND deleted = 0;
IF (@kennelId IS NULL)
BEGIN
    SELECT 0 AS Inserted, 'noEvent' AS Reason;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    -- Same shape as the fresh-check-in INSERT in hcapp_setEventAttendence.
    -- The existence check above is repeated under a lock so two archive
    -- passes cannot both insert (IX_HasherEventMap_EventId is unique).
    IF NOT EXISTS (SELECT 1 FROM HC.HasherEventMap WITH (UPDLOCK, HOLDLOCK)
                    WHERE EventId = @eventId AND UserId = @userId)
    BEGIN
        INSERT INTO HC.HasherEventMap
            ([id], [EventId], [KennelId], [UserId],
             [AttendenceState], [RsvpState], [IsHare], [VirginVisitorType], [updatedAt])
        VALUES
            (NEWID(), @eventId, @kennelId, @userId,
             20, 3, 0, 0, GETDATE());
    END
    ELSE
    BEGIN
        -- RSVPed (or checked in below At Hash) and has a track: they ran.
        -- Same transition hcapp_setEventAttendence makes for a check-in.
        UPDATE HC.HasherEventMap
           SET AttendenceState = 20, RsvpState = 3, updatedAt = GETDATE()
         WHERE EventId = @eventId AND UserId = @userId AND removed = 0 AND AttendenceState < 20;
    END

    COMMIT TRANSACTION;

    -- Same post-write recompute as a real check-in (outside the transaction,
    -- as hcapp_setEventAttendence does it).
    EXEC HC6.nonApi_updateRunCountsByUser @userId = @userId;

    SELECT CASE WHEN @existingState IS NULL THEN 1 ELSE 0 END AS Inserted,
           CASE WHEN @existingState IS NULL THEN 'inserted' ELSE 'raised' END AS Reason;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_ensureTrackAttendance',
            ERROR_MESSAGE(), @procName, @userId, @eventId);
    THROW;
END CATCH
GO
