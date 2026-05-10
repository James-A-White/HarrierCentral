CREATE OR ALTER PROCEDURE [HC6].[hcapp_addEditReceipt]

    @deviceId              UNIQUEIDENTIFIER,
    @accessToken           NVARCHAR(1000),
    @receiptId             UNIQUEIDENTIFIER,
    @eventId               UNIQUEIDENTIFIER,
    @receiptShortDesc      NVARCHAR(500),
    @receiptAmount         DECIMAL(12,4),
    @notes                 NVARCHAR(1000),
    @reimbursedBy          UNIQUEIDENTIFIER,
    @reimbursedOn          DATETIMEOFFSET(7),
    @reimbursedAmount      DECIMAL(12,4),
    @reimbursedNotes       NVARCHAR(1000),
    @imageUrl              NVARCHAR(1000),
    @receiptsUpdatedAfter  NVARCHAR(50),
    @removed               SMALLINT

AS
-- =====================================================================
-- Procedure: HC6.hcapp_addEditReceipt
-- Description: Creates or updates an expense receipt for an event.
--   Mode is determined by whether @receiptId already exists in HC.Receipt.
--   Passing @reimbursedBy = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF' clears
--   all reimbursement fields (un-reimburse). Passing a valid @reimbursedBy
--   sets ReimbursedOn to the current timestamp and copies ReceiptAmount
--   to ReimbursedAmount. @removed = -1 means "keep existing".
-- Parameters:
--   @deviceId             - Registered device UUID
--   @accessToken          - Token validated against DeviceSecret
--   @receiptId            - Receipt UUID (NULL or empty = insert)
--   @eventId              - Event the receipt belongs to
--   @receiptShortDesc     - Short description of the expense
--   @receiptAmount        - Amount of the expense
--   @notes                - Optional notes
--   @reimbursedBy         - Hasher who reimbursed; FFFFFFFF...=clear; NULL=keep
--   @reimbursedOn         - Reimbursement date (overridden to GETDATE() if @reimbursedBy set)
--   @reimbursedAmount     - Amount reimbursed (overridden from ReceiptAmount if @reimbursedBy set)
--   @reimbursedNotes      - Notes on the reimbursement
--   @imageUrl             - URL of receipt image (must be ≥ 20 chars to be stored)
--   @receiptsUpdatedAfter - Sync watermark for Receipts
--   @removed              - 1 = removed; -1 / NULL = keep existing
-- Returns:
--   Write SP success envelope (rowset 0): success, errorCode, errorType
--   On success (rowset 1+): syncEventAdminData rowsets
--   On error (rowset 1): standard HC6 error detail
-- Author: Harrier Central
-- Created: 2026-05-10
-- HC5 Source: HC5.hcapp_addEditReceipt
-- Breaking Changes:
--   @reimbursedOn changed NVARCHAR(50) → DATETIMEOFFSET(7) (was CAST in HC5,
--     risking runtime error on malformed strings).
--   TRY/CATCH and transaction added (HC5 had neither).
--   DATALENGTH → LEN for imageUrl length guard.
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

-- Normalise sentinels before auth
IF (@removed       = -1) SET @removed       = NULL;
IF (@reimbursedAmount < 0) SET @reimbursedAmount = NULL;
IF (@reimbursedBy  = '00000000-0000-0000-0000-000000000000') SET @reimbursedBy = NULL;
IF (@receiptAmount < 0) SET @receiptAmount = NULL;
IF (LEN(COALESCE(@reimbursedNotes,''))  = 0) SET @reimbursedNotes  = NULL;
IF (LEN(COALESCE(@notes,''))            = 0) SET @notes            = NULL;
IF (LEN(COALESCE(@receiptShortDesc,'')) = 0) SET @receiptShortDesc = NULL;
IF (LEN(COALESCE(@imageUrl,''))         < 20) SET @imageUrl        = NULL;
IF (@receiptId = '00000000-0000-0000-0000-000000000000') SET @receiptId = NULL;

DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 43,
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

IF (@eventId IS NULL OR @eventId = '00000000-0000-0000-0000-000000000000')
BEGIN
    SET @errorCode = 1243; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<unknown>', 'Null or empty eventId', 'eventId is required', @procName, @userId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Missing event' AS errorTitle, 'An event must be specified.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

-- When reimbursedBy is set, override date and amount from the receipt
DECLARE @reimbursedOnDate DATETIMEOFFSET(7) = @reimbursedOn;
DECLARE @clearReimbursement BIT = 0;

IF (@reimbursedBy = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF')
BEGIN
    SET @clearReimbursement = 1;
    SET @reimbursedBy = NULL;
END
ELSE IF (@reimbursedBy IS NOT NULL)
BEGIN
    SET @reimbursedOnDate = GETDATE();
    SELECT @reimbursedAmount = r.ReceiptAmount FROM HC.Receipt r WHERE r.id = @receiptId;
END

IF (@reimbursedOnDate IS NOT NULL AND @reimbursedOnDate < '2000-01-01') SET @reimbursedOnDate = NULL;

BEGIN TRY
    BEGIN TRANSACTION;

        IF (@receiptId IS NOT NULL AND EXISTS (SELECT 1 FROM HC.Receipt r WHERE r.id = @receiptId))
        BEGIN
            -- Update existing receipt
            UPDATE HC.Receipt SET
                ReceiptAmount    = COALESCE(@receiptAmount,    ReceiptAmount),
                ReceiptShortDesc = COALESCE(@receiptShortDesc, ReceiptShortDesc),
                UserId           = @userId,
                ImageUrl         = COALESCE(@imageUrl, ImageUrl),
                removed          = COALESCE(@removed,  removed),
                Notes            = COALESCE(@notes,    Notes),
                ReimbursedBy     = CASE WHEN @clearReimbursement = 1 THEN NULL ELSE COALESCE(@reimbursedBy,     ReimbursedBy)     END,
                ReimbursedOn     = CASE WHEN @clearReimbursement = 1 THEN NULL ELSE COALESCE(@reimbursedOnDate, ReimbursedOn)     END,
                ReimbursedAmount = CASE WHEN @clearReimbursement = 1 THEN NULL ELSE COALESCE(@reimbursedAmount, ReimbursedAmount) END,
                ReimbursedNotes  = CASE WHEN @clearReimbursement = 1 THEN NULL ELSE COALESCE(@reimbursedNotes,  ReimbursedNotes)  END,
                updatedAt        = GETDATE()
            WHERE id = @receiptId;
        END
        ELSE
        BEGIN
            -- Insert new receipt
            IF (@receiptId IS NULL) SET @receiptId = NEWID();

            INSERT HC.Receipt
                ([id], [EventId], [UserId], [ReceiptAmount], [CostCategory],
                 [DateUploaded], [ImageUrl], [ReceiptShortDesc], [Notes],
                 [ReimbursedBy], [ReimbursedOn], [ReimbursedAmount], [ReimbursedNotes],
                 [removed], [updatedAt])
            VALUES
                (@receiptId, @eventId, @userId, @receiptAmount, 0,
                 GETDATE(), @imageUrl, @receiptShortDesc, @notes,
                 @reimbursedBy, @reimbursedOnDate, @reimbursedAmount, @reimbursedNotes,
                 @removed, GETDATE());
        END

    COMMIT TRANSACTION;

    SELECT 1 AS success, NULL AS errorCode, NULL AS errorType;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @errorCode = 1943; SET @errorType = 9; SET @errorId = NEWID();
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
SET @receiptsUpdatedAfter = COALESCE(@receiptsUpdatedAfter, 'ignore');

EXEC HC6.hcapp_syncEventAdminData
    @deviceId                    = @deviceId,
    @accessToken                 = @accessToken,
    @eventId                     = @eventId,
    @hashersUpdatedAfter         = 'ignore',
    @hasherEventMapUpdatedAfter  = 'ignore',
    @hasherKennelMapUpdatedAfter = 'ignore',
    @narrowEventsUpdatedAfter    = 'ignore',
    @paymentsUpdatedAfter        = 'ignore',
    @receiptsUpdatedAfter        = @receiptsUpdatedAfter,
    @procName                    = @procName,
    @param                       = NULL;
