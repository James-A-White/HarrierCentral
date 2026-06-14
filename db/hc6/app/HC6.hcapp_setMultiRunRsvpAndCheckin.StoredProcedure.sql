CREATE OR ALTER PROCEDURE [HC6].[hcapp_setMultiRunRsvpAndCheckin]

    @deviceId                    UNIQUEIDENTIFIER,
    @accessToken                 NVARCHAR(1000),
    @checkInEventIds             NVARCHAR(MAX),    -- pipe-delimited event UUIDs to check in to
    @rsvpNoEventIds              NVARCHAR(MAX),    -- pipe-delimited event UUIDs to RSVP No
    @hasherId                    UNIQUEIDENTIFIER,
    @hasherEventMapUpdatedAfter  NVARCHAR(50),
    @hasherKennelMapUpdatedAfter NVARCHAR(50)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_setMultiRunRsvpAndCheckin
-- Description: Processes the multi-run check-in dialog result in a single
--   transaction. For each event in @checkInEventIds, upserts the
--   HasherEventMap row with AttendenceState=20 and RsvpState=3 (at hash,
--   RSVP yes). For each event in @rsvpNoEventIds, upserts the HEM row
--   with RsvpState=1 (not coming) — guarded so an existing check-in is
--   never downgraded. Both lists are pipe-delimited UUIDs.
-- Parameters:
--   @deviceId                    - Registered device UUID
--   @accessToken                 - Token validated against DeviceSecret
--   @checkInEventIds             - Pipe-delimited event UUIDs to check in to
--   @rsvpNoEventIds              - Pipe-delimited event UUIDs to RSVP No
--   @hasherId                    - Target hasher (caller if NULL)
--   @hasherEventMapUpdatedAfter  - Sync watermark for HasherEventMap
--   @hasherKennelMapUpdatedAfter - Sync watermark for HasherKennelMap
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): { adHocDataId } — minimal confirmation
--   On success (rowset 2+): syncUserData rowsets (common domain)
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-06-14
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId  UNIQUEIDENTIFIER;
DECLARE @errorCode INT;
DECLARE @errorType INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 93,
    @param        = NULL,
    @userId       = @userId       OUTPUT,
    @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow   = @timeWindow   OUTPUT,
    @errorCode    = @errorCode    OUTPUT,
    @errorType    = @errorType    OUTPUT,
    @errorId      = @errorId      OUTPUT,
    @errorTitle   = @errorTitle   OUTPUT,
    @errorMsg     = @errorMsg     OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

IF (@hasherId IS NULL) SET @hasherId = @userId;

BEGIN TRY
    BEGIN TRANSACTION;

        -- Check-in events: upsert with AttendenceState=20, RsvpState=3.
        -- Guard: never downgrade a row already at AttendenceState >= 20.
        IF (@checkInEventIds IS NOT NULL AND LEN(TRIM(@checkInEventIds)) > 0)
        BEGIN
            MERGE HC.HasherEventMap AS target
            USING (
                SELECT CAST(TRIM(s.value) AS UNIQUEIDENTIFIER) AS eventId, e.KennelId
                FROM STRING_SPLIT(@checkInEventIds, '|') s
                INNER JOIN HC.Event e ON e.id = CAST(TRIM(s.value) AS UNIQUEIDENTIFIER)
                WHERE LEN(TRIM(s.value)) > 0
            ) AS src
            ON target.EventId = src.eventId AND target.UserId = @hasherId
            WHEN MATCHED AND target.AttendenceState < 20 THEN
                UPDATE SET
                    AttendenceState = 20,
                    RsvpState       = 3,
                    updatedAt       = GETDATE()
            WHEN NOT MATCHED THEN
                INSERT ([id], [EventId], [KennelId], [UserId],
                        [AttendenceState], [RsvpState], [IsHare], [VirginVisitorType], [updatedAt])
                VALUES (NEWID(), src.eventId, src.KennelId, @hasherId,
                        20, 3, 0, 0, GETDATE());
        END

        -- RSVP-No events: upsert with RsvpState=1.
        -- Guard: never touch a row where the hasher is already checked in.
        IF (@rsvpNoEventIds IS NOT NULL AND LEN(TRIM(@rsvpNoEventIds)) > 0)
        BEGIN
            MERGE HC.HasherEventMap AS target
            USING (
                SELECT CAST(TRIM(s.value) AS UNIQUEIDENTIFIER) AS eventId, e.KennelId
                FROM STRING_SPLIT(@rsvpNoEventIds, '|') s
                INNER JOIN HC.Event e ON e.id = CAST(TRIM(s.value) AS UNIQUEIDENTIFIER)
                WHERE LEN(TRIM(s.value)) > 0
            ) AS src
            ON target.EventId = src.eventId AND target.UserId = @hasherId
            WHEN MATCHED AND target.AttendenceState < 20 THEN
                UPDATE SET
                    RsvpState = 1,
                    updatedAt = GETDATE()
            WHEN NOT MATCHED THEN
                INSERT ([id], [EventId], [KennelId], [UserId],
                        [AttendenceState], [RsvpState], [IsHare], [VirginVisitorType], [updatedAt])
                VALUES (NEWID(), src.eventId, src.KennelId, @hasherId,
                        0, 1, 0, 0, GETDATE());
        END

    COMMIT TRANSACTION;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1993; SET @errorType = 19; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END CATCH;

-- Post-write: update run counts for check-in events
IF (@checkInEventIds IS NOT NULL AND LEN(TRIM(@checkInEventIds)) > 0)
    EXEC HC.nonApi_updateRunCountsByUser @userId = @hasherId;

SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

SELECT 1 AS adHocDataId;

-- ---------------------------------------------------------------
-- Delegate to syncUserData (common domain) so RSVP and attendance
-- changes replicate back to the device immediately.
-- ---------------------------------------------------------------
SET @hasherKennelMapUpdatedAfter = COALESCE(@hasherKennelMapUpdatedAfter, 'ignore');
SET @hasherEventMapUpdatedAfter  = COALESCE(@hasherEventMapUpdatedAfter,  'ignore');

EXEC HC6.hcapp_syncUserData
    @deviceId                    = @deviceId,
    @accessToken                 = @accessToken,
    @hashersUpdatedAfter         = 'ignore',
    @hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
    @hasherEventMapUpdatedAfter  = @hasherEventMapUpdatedAfter,
    @narrowEventsUpdatedAfter    = 'ignore',
    @usePaging                   = 0,
    @procName                    = @procName,
    @param                       = NULL;
