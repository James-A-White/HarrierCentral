CREATE OR ALTER PROCEDURE [HC6].[hcapp_joinEventAsVisitor]

    @deviceId                   UNIQUEIDENTIFIER,
    @accessToken                NVARCHAR(1000),
    @eventId                    UNIQUEIDENTIFIER,
    @displayName                NVARCHAR(250),
    @virginVisitorType          SMALLINT,
    @attendenceState            SMALLINT,
    @email                      NVARCHAR(250),
    @phoneNumber                NVARCHAR(250),
    @hasherEventMapUpdatedAfter NVARCHAR(50),
    @paymentsUpdatedAfter       NVARCHAR(50)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_joinEventAsVisitor
-- Description: Records a non-member attendee (virgin = 1, visitor = 2)
--   against an event. Virgins and visitors share a per-kennel
--   "placeholder" Hasher whose id equals the KennelId; this row is
--   created on demand if it doesn't exist. The HEM row uses DisplayName
--   to distinguish individuals and is idempotent: if a row already
--   exists for that display name and event it is reused.
-- Parameters:
--   @deviceId                   - Registered device UUID
--   @accessToken                - Token validated against DeviceSecret
--   @eventId                    - Event UUID
--   @displayName                - Name of the virgin or visitor
--   @virginVisitorType          - 1 = Virgin, 2 = Visitor
--   @attendenceState            - Attendance state to set
--   @email                      - Optional email for the attendee
--   @phoneNumber                - Optional phone number for the attendee
--   @hasherEventMapUpdatedAfter - Sync watermark for HasherEventMap
--   @paymentsUpdatedAfter       - Sync watermark for Payments
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1): { adHocDataId, hasherEventMapId }
--   On success (rowset 2+): syncEventAdminData rowsets
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_joinEventAsVisitor
-- Breaking Changes:
--   Invalid @virginVisitorType now returns explicit error (HC5 silently
--     returned empty response for types other than 1 or 2).
--   TRY/CATCH and transaction added (HC5 had neither).
--   Success envelope added.
--   Delegation target updated to HC6.hcapp_syncEventAdminData.
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
    @spNumber     = 23,
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

-- ---------------------------------------------------------------
-- Validate parameters
-- ---------------------------------------------------------------
IF (@eventId IS NULL OR @eventId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1223; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null or empty eventId',
            'A null or empty eventId was passed to ' + @procName, @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing event' AS errorTitle, 'An event must be specified.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

IF (@virginVisitorType NOT IN (1, 2))
BEGIN
    SET @errorCode = 1223; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Invalid virginVisitorType',
            'virginVisitorType must be 1 (virgin) or 2 (visitor)', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Invalid attendee type' AS errorTitle,
           'Attendee type must be 1 (virgin) or 2 (visitor).' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

        DECLARE @kennelId UNIQUEIDENTIFIER;

        SELECT @kennelId = e.KennelId
        FROM HC.Event e
        WHERE e.id = @eventId AND e.deleted = 0 AND e.IsVisible <> 0;

        -- Ensure the per-kennel placeholder Hasher exists (id = kennelId)
        IF NOT EXISTS (
            SELECT 1 FROM HC.Hasher h
            INNER JOIN HC.Event e ON h.id = e.KennelId
            WHERE e.id = @eventId AND e.deleted = 0 AND e.IsVisible <> 0
        )
        BEGIN
            INSERT INTO HC.Hasher
                ([id], [FirstName], [LastName], [HashName],
                 [NameDisplayPreference], [Description],
                 [HomeLatitude], [HomeLongitude], [Email])
            SELECT
                k.id,
                'Placeholder', 'User',
                'Placeholder user for visitors / virgins for ' + k.KennelName,
                1,
                'Placeholder user for visitors / virgins for ' + k.KennelName,
                COALESCE(k.Latitude,  0),
                COALESCE(k.Longitude, 0),
                CAST(k.id AS NVARCHAR(50)) + '@harriercentral.com'
            FROM HC.Event e
            INNER JOIN HC.Kennel k ON e.KennelId = k.id
            WHERE e.id = @eventId AND e.deleted = 0 AND e.IsVisible <> 0;
        END

        DECLARE @hasherEventMapId UNIQUEIDENTIFIER;

        -- Look for an existing HEM row for this visitor by display name
        SELECT @hasherEventMapId = hem.id
        FROM HC.HasherEventMap hem
        WHERE hem.EventId = @eventId
          AND hem.DisplayName IS NOT NULL
          AND hem.DisplayName = @displayName;

        IF (@hasherEventMapId IS NULL)
        BEGIN
            SET @hasherEventMapId = NEWID();

            INSERT INTO HC.HasherEventMap
                ([id], [EventId], [KennelId], [UserId],
                 [UserStartEvent], [EventCost],
                 [Rsvp], [RsvpState], [AttendenceState],
                 [VirginVisitorType], [DisplayName], [Email], [PhoneNumber], [updatedAt])
            SELECT
                @hasherEventMapId,
                @eventId,
                e.KennelId,
                e.KennelId,
                GETDATE(),
                e.EventPriceForNonMembers,
                GETDATE(),
                3,
                @attendenceState,
                @virginVisitorType,
                @displayName,
                @email,
                @phoneNumber,
                GETDATE()
            FROM HC.Event e
            WHERE e.id = @eventId AND e.deleted = 0 AND e.IsVisible <> 0;
        END

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

    SELECT
        1                    AS adHocDataId,
        @hasherEventMapId    AS hasherEventMapId;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1923; SET @errorType = 9; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END CATCH;

-- ---------------------------------------------------------------
-- Delegate to syncEventAdminData (outside TRY — runs after commit)
-- ---------------------------------------------------------------
SET @hasherEventMapUpdatedAfter = COALESCE(@hasherEventMapUpdatedAfter, 'ignore');
SET @paymentsUpdatedAfter       = COALESCE(@paymentsUpdatedAfter,       'ignore');

EXEC HC6.hcapp_syncEventAdminData
    @deviceId                    = @deviceId,
    @accessToken                 = @accessToken,
    @eventId                     = @eventId,
    @hashersUpdatedAfter         = 'ignore',
    @hasherEventMapUpdatedAfter  = @hasherEventMapUpdatedAfter,
    @hasherKennelMapUpdatedAfter = 'ignore',
    @narrowEventsUpdatedAfter    = 'ignore',
    @paymentsUpdatedAfter        = @paymentsUpdatedAfter,
    @receiptsUpdatedAfter        = 'ignore',
    @procName                    = @procName,
    @param                       = NULL;
