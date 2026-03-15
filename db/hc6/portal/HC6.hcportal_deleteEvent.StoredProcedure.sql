CREATE OR ALTER PROCEDURE [HC6].[hcportal_deleteEvent]

-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
@publicHasherId uniqueidentifier = NULL,
@accessToken nvarchar(1000) = NULL,
@publicEventId uniqueidentifier = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_deleteEvent
-- Description: Soft-deletes an event by setting its 'removed' flag to 1,
--   but only if no hashers have been checked in (AttendenceState >= 20).
--   Validates user authentication and event existence before deletion.
-- Parameters: @publicHasherId, @accessToken, @publicEventId
-- Returns: On error: standard HC6 error envelope. On success: single-row
--   Result message confirming deletion or explaining why it was blocked.
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_deleteEvent
-- Breaking Changes:
--   @publicEventId changed from NVARCHAR(250) to UNIQUEIDENTIFIER.
--   Removed @ipAddress and @ipGeoDetails parameters.
--   Validation now short-circuits on first error (HC5 could return
--   multiple error rowsets). Added XACT_ABORT, TRY/CATCH, and
--   transaction around UPDATE. Added @@ROWCOUNT check after UPDATE.
--   Auth validated via HC6.ValidatePortalAuth helper SP
--   Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   Removed ErrorLog inserts (error logging moved to API shim)
--   Removed GeneralLog inserts (request logging moved to API shim)
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

-- Auth validation
DECLARE @authError NVARCHAR(255);
EXEC HC6.ValidatePortalAuth @publicHasherId, @accessToken, OBJECT_NAME(@@PROCID), @publicEventId, @authError OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

-- Validate publicEventId
IF (@publicEventId IS NULL)
BEGIN
    SELECT 0 AS Success, 'Null or invalid publicEventId' AS ErrorMessage;
    RETURN;
END

    DECLARE @eventId uniqueidentifier;
    SELECT @eventId = id FROM HC.Event WHERE PublicEventId = @publicEventId;

    IF (@eventId IS NULL)
    BEGIN
        SELECT 0 AS Success, 'No record found with provided publicEventId' AS ErrorMessage;
        RETURN;
    END

    DECLARE @countAtHash int;

    SELECT @countAtHash = COUNT(*) FROM HC.HasherEventMap
    WHERE EventId = @eventId
    AND AttendenceState >= 20;

    IF (@countAtHash = 0)
    BEGIN
        BEGIN TRANSACTION;

        UPDATE HC.Event
            SET updatedAt = GETDATE(),
                removed = 1
        WHERE id = @eventId;

        IF @@ROWCOUNT = 0
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'Event not found or already removed' AS Result;
            RETURN;
        END

        COMMIT TRANSACTION;

        SELECT 'This run has been successfully removed' AS Result;
    END
    ELSE
    BEGIN
        IF (@countAtHash = 1)
        BEGIN
            SELECT 'Cannot delete this run because 1 Hasher has been checked in to the run.' AS Result;
        END
        ELSE
        BEGIN
            SELECT 'Cannot delete this run because ' + CAST(@countAtHash AS nvarchar(20)) + ' Hashers have been checked in to the run.' AS Result;
        END
    END

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
