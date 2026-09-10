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
--   Does nothing if a row already exists in any state (including removed —
--   an admin's removal is not undone), or if the hasher or event is gone.
-- Parameters:
--   @eventId - The run.
--   @userId  - The runner.
-- Returns: one row — Inserted (1/0), Reason ('inserted' | 'rowExists' |
--   'noHasher' | 'noEvent').
-- Author: Harrier Central
-- Created: 2026-09-10
-- HC5 Source: none (new) — insert mirrors HC6.hcapp_setEventAttendence
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @kennelId UNIQUEIDENTIFIER;

IF EXISTS (SELECT 1 FROM HC.HasherEventMap WHERE EventId = @eventId AND UserId = @userId)
BEGIN
    SELECT 0 AS Inserted, 'rowExists' AS Reason;
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

    COMMIT TRANSACTION;

    -- Same post-write recompute as a real check-in (outside the transaction,
    -- as hcapp_setEventAttendence does it).
    EXEC HC6.nonApi_updateRunCountsByUser @userId = @userId;

    SELECT 1 AS Inserted, 'inserted' AS Reason;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, eventId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_ensureTrackAttendance',
            ERROR_MESSAGE(), @procName, @userId, @eventId);
    THROW;
END CATCH
GO
