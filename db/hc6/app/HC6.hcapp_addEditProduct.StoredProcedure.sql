CREATE OR ALTER PROCEDURE [HC6].[hcapp_addEditProduct]
    @deviceId          UNIQUEIDENTIFIER,
    @accessToken       NVARCHAR(1000),
    @kennelId          UNIQUEIDENTIFIER,
    @productId         UNIQUEIDENTIFIER = NULL,   -- NULL = create
    @productType       SMALLINT         = 0,
    @name              NVARCHAR(200)    = NULL,
    @description       NVARCHAR(4000)   = NULL,
    -- How this product is priced. One json field so a product can express the
    -- model it actually has. SYNCS.
    @pricingJson       NVARCHAR(4000)   = NULL,
    -- Per-type rules, e.g. {"photos":[…],"sizes":["S","M"]}. SYNCS.
    @productDetailsJson NVARCHAR(4000)  = NULL,
    -- Supplier detail. Does NOT sync — kennel admin data only.
    @sourceJson        NVARCHAR(4000)   = NULL,
    @isActive          SMALLINT         = 1,
    @sortOrder         INT              = 0
AS
-- =====================================================================
-- Procedure: HC6.hcapp_addEditProduct
-- Description: Creates or edits one entry in a kennel's catalogue (3.1) —
--   a run package, a membership, a piece of haberdashery. Holds what the
--   hasher pays, what promotional credit it grants, and what it costs the
--   kennel, so the accounting section has margin as well as takings.
--
--   A product is NEVER deleted by this SP. Taking something off sale is
--   @isActive = 0, which keeps the row syncing so a payment made against it
--   last year still resolves its product. Removing it would delete the row
--   from every phone (the sync deletes on Removed) and break exactly that
--   link (James, 2026-09-13).
--
-- Authorization: the manageProducts feature — GM, VGM, Hash Cash,
--   Haberdasher, or the ManageHashCash flag. A catalogue sets prices, so it
--   is money work and gated as such (see /hc-authorizations).
-- Parameters: @productId NULL creates, otherwise edits that product — which
--   must belong to @kennelId, so one kennel cannot edit another's.
-- Returns: rowset 0 — success envelope only. Rowset 1 — { productId }.
-- Author: Harrier Central
-- Created: 2026-09-13
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName   NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId    UNIQUEIDENTIFIER;
DECLARE @errorCode  INT;
DECLARE @errorType  INT;
DECLARE @errorTitle NVARCHAR(500);
DECLARE @errorMsg   NVARCHAR(MAX);
DECLARE @userId       UNIQUEIDENTIFIER;
DECLARE @deviceSecret NVARCHAR(150);
DECLARE @timeWindow   INT;

EXEC HC6.ValidateAppAuth
    @deviceId     = @deviceId,
    @accessToken  = @accessToken,
    @procName     = @procName,
    @spNumber     = 103,
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

-- Authorization. ValidateAppAuth proved WHO is calling, not what they may do.
DECLARE @allowed SMALLINT;
EXEC HC6.CheckKennelPermission
    @userId = @userId, @kennelId = @kennelId,
    @functionKey = 'manageProducts', @allowed = @allowed OUTPUT;

IF (@allowed = 0)
BEGIN
    SET @errorCode = 1341; SET @errorType = 13; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Not authorised to manage products',
            'Caller does not hold manageProducts for this kennel', @procName, @userId, @kennelId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Not authorised' AS errorTitle,
           'You are not authorised to manage this kennel''s products.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Pre-flight, before any transaction: nothing to roll back, so no chance of
-- rolling back the error log with it.
IF (NULLIF(LTRIM(RTRIM(ISNULL(@name, ''))), '') IS NULL)
BEGIN
    SET @errorCode = 1342; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Product name required',
            'A product must have a name', @procName, @userId, @kennelId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Name needed' AS errorTitle,
           'Give the product a name.' AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

-- Malformed JSON would be caught by the table CHECK, but that surfaces as
-- an unhelpful constraint violation in the CATCH. Say so plainly instead,
-- before any transaction is open.
IF (@productDetailsJson IS NOT NULL AND ISJSON(@productDetailsJson) = 0)
   OR (@pricingJson IS NOT NULL AND ISJSON(@pricingJson) = 0)
   OR (@sourceJson IS NOT NULL AND ISJSON(@sourceJson) = 0)
BEGIN
    SET @errorCode = 1345; SET @errorType = 2; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Malformed product JSON',
            'productDetailsJson or sourceJson is not valid JSON', @procName, @userId, @kennelId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Could not save' AS errorTitle,
           'The product details could not be saved. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

-- Editing something that is not this kennel's is a no, not a silent create.
IF (@productId IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM HC.Product
                    WHERE id = @productId AND KennelId = @kennelId AND Removed = 0))
BEGIN
    SET @errorCode = 1343; SET @errorType = 3; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Product not found',
            CONCAT('productId ', CONVERT(NVARCHAR(36), @productId), ' is not this kennel''s'),
            @procName, @userId, @kennelId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Product not found' AS errorTitle,
           'That product is no longer in your catalogue.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @now DATETIMEOFFSET(7) = SYSDATETIMEOFFSET();

    IF (@productId IS NULL)
    BEGIN
        SET @productId = NEWID();
        INSERT HC.Product (id, KennelId, ProductType, Name, Description,
                           PricingJson, ProductDetailsJson, SourceJson,
                           IsActive, SortOrder, CreatedByUserId, createdAt,
                           updatedAt, updatedAtBias, Removed)
        VALUES (@productId, @kennelId, @productType, LTRIM(RTRIM(@name)), @description,
                @pricingJson, @productDetailsJson, @sourceJson,
                @isActive, @sortOrder, @userId, @now, @now, 0, 0);
    END
    ELSE
    BEGIN
        -- updatedAt is still set explicitly, but it is no longer load-bearing:
        -- HC.trgUpdateModifiedOnDateForProduct stamps it either way and adds
        -- the updatedAtBias offset. Setting it here just means the value in
        -- the row matches the transaction rather than the trigger's clock.
        UPDATE HC.Product
           SET ProductType       = @productType,
               Name              = LTRIM(RTRIM(@name)),
               Description       = @description,
               PricingJson        = @pricingJson,
               ProductDetailsJson = @productDetailsJson,
               SourceJson         = @sourceJson,
               IsActive          = @isActive,
               SortOrder         = @sortOrder,
               updatedAt         = @now
         WHERE id = @productId AND KennelId = @kennelId;
    END

    COMMIT TRANSACTION;
    SELECT 1 AS success;
    SELECT @productId AS productId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorCode = 1344; SET @errorType = 5; SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (@errorId, HC6.DeviceHcVersion(@deviceId), 'Unhandled error in hcapp_addEditProduct',
            ERROR_MESSAGE(), @procName, @userId, @kennelId);
    SELECT 0 AS success, @errorCode AS errorCode, @errorType AS errorType;
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           'Unexpected error' AS errorTitle,
           'An unexpected error occurred. Please try again.' AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END CATCH
GO
