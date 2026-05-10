CREATE OR ALTER PROCEDURE [HC6].[hcapp_snoozePromotion]

    @deviceId       UNIQUEIDENTIFIER,
    @accessToken    NVARCHAR(1000),
    @promotionId    UNIQUEIDENTIFIER,
    @snoozeUntilDate DATETIMEOFFSET(7)

AS
-- =====================================================================
-- Procedure: HC6.hcapp_snoozePromotion
-- Description: Records that the calling user has snoozed a promotion
--   until the given date, suppressing the promotion from appearing in
--   the app until that date has passed.
-- Parameters:
--   @deviceId        - Registered device UUID
--   @accessToken     - Token validated against DeviceSecret
--   @promotionId     - Promotion UUID to snooze
--   @snoozeUntilDate - Date until which the promotion is suppressed
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success: no additional rowset
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_snoozePromotion
-- Breaking Changes:
--   Access token now validated (HC5 had the auth check commented out —
--     any device with a valid record could snooze any promotion).
--   @snoozeUntilDate changed DATETIME → DATETIMEOFFSET(7).
--   TRY/CATCH and transaction added (HC5 had neither).
--   Success envelope added.
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
    @spNumber     = 52,
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

BEGIN TRY
    BEGIN TRANSACTION;

        INSERT INTO HC.HasherPromotionMap ([UserId], [PromotionId], [SnoozeUntilDate])
        VALUES (@userId, @promotionId, @snoozeUntilDate);

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1952; SET @errorType = 9; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Unhandled error', ERROR_MESSAGE(), @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH;
