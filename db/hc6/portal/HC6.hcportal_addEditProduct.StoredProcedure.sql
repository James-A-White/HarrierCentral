CREATE OR ALTER PROCEDURE [HC6].[hcportal_addEditProduct]

    -- required parameters
    @deviceId            UNIQUEIDENTIFIER = NULL,
    @accessToken         NVARCHAR(1000)   = NULL,
    @publicKennelId      UNIQUEIDENTIFIER = NULL,

    -- NULL = create, otherwise edit that product
    @productId           UNIQUEIDENTIFIER = NULL,
    @productType         SMALLINT         = 0,
    @name                NVARCHAR(200)    = NULL,
    @description         NVARCHAR(4000)   = NULL,
    -- How this product is priced, as one json field. Syncs to phones.
    @pricingJson         NVARCHAR(4000)   = NULL,
    -- Per-type rules, e.g. {"photos":[…],"sizes":["S","M"]}. Syncs to phones.
    @productDetailsJson  NVARCHAR(4000)   = NULL,
    -- Supplier detail. Never syncs to phones.
    @sourceJson          NVARCHAR(4000)   = NULL,
    @isActive            SMALLINT         = 1,
    @sortOrder           INT              = 0

AS
-- =====================================================================
-- Procedure: HC6.hcportal_addEditProduct
-- Description: Creates or edits one entry in a kennel's catalogue from the
--              portal's Products view. The portal twin of
--              HC6.hcapp_addEditProduct — same table, same rules, portal
--              auth instead of device auth.
--
--              A PRODUCT IS NEVER DELETED BY THIS SP. Taking something off
--              sale is @isActive = 0, which keeps the row syncing so a
--              payment made against it last year still resolves its
--              product. Removing it would delete the row from every phone
--              and break exactly that link.
--
-- Authorization: the manageProducts feature, via HC6.CheckKennelPermission.
-- Parameters: @productId NULL creates, otherwise edits that product — which
--              must belong to @publicKennelId's kennel, so one kennel
--              cannot edit another's.
-- Returns: Rowset 0 — success envelope. Rowset 1 — { productId }.
-- Author: Harrier Central
-- Created: 2026-09-13
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================

-- Emoji-safe blank test. The database collates SQL_Latin1_General_CP1_CI_AS,
-- in which a surrogate pair has NO sort weight, so N'<emoji>' = '' is TRUE
-- and NULLIF(LTRIM(RTRIM(x)), '') threw away any value made only of emoji.
-- LEN() counts code units, so emoji survive while a string of spaces still
-- measures 0. (2026-09-19, after a room message of one wave was refused.)

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @hasherId UNIQUEIDENTIFIER;
DECLARE @kennelId UNIQUEIDENTIFIER;

IF @publicKennelId IS NULL
BEGIN
    SELECT 0 AS Success, 'Null or invalid publicKennelId' AS ErrorMessage;
    RETURN;
END

DECLARE @authError NVARCHAR(255);
DECLARE @callerType INT;
EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @publicKennelId,
     @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

SELECT @kennelId = id FROM HC.Kennel WHERE PublicKennelId = @publicKennelId;

IF @kennelId IS NULL
BEGIN
    SELECT 0 AS Success, 'Kennel not found' AS ErrorMessage;
    RETURN;
END

-- Authorization. Identity is not permission.
DECLARE @allowed SMALLINT;
EXEC HC6.CheckKennelPermission
    @userId = @hasherId, @kennelId = @kennelId,
    @functionKey = 'manageProducts', @allowed = @allowed OUTPUT;

IF (@allowed = 0)
BEGIN
    SELECT 0 AS Success, 'You are not authorised to manage this kennel''s products.' AS ErrorMessage;
    RETURN;
END

-- Pre-flight, all before BEGIN TRANSACTION so there is no rollback that
-- could erase an error log written beside it.
IF (LEN(COALESCE(@name, N'')) = 0)
BEGIN
    SELECT 0 AS Success, 'Give the product a name.' AS ErrorMessage;
    RETURN;
END

IF (@productDetailsJson IS NOT NULL AND ISJSON(@productDetailsJson) = 0)
   OR (@pricingJson IS NOT NULL AND ISJSON(@pricingJson) = 0)
   OR (@sourceJson IS NOT NULL AND ISJSON(@sourceJson) = 0)
BEGIN
    SELECT 0 AS Success, 'The product details could not be saved. Please try again.' AS ErrorMessage;
    RETURN;
END

-- Editing something that is not this kennel's is a no, not a silent create.
IF (@productId IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM HC.Product
                    WHERE id = @productId AND KennelId = @kennelId AND Removed = 0))
BEGIN
    SELECT 0 AS Success, 'That product is no longer in your catalogue.' AS ErrorMessage;
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
                @isActive, @sortOrder, @hasherId, @now, @now, 0, 0);
    END
    ELSE
    BEGIN
        -- updatedAt is still set explicitly, but it is no longer load-bearing:
        -- HC.trgUpdateModifiedOnDateForProduct stamps it either way and adds
        -- the updatedAtBias offset. Setting it here just means the value in
        -- the row matches the transaction rather than the trigger's clock.
        UPDATE HC.Product
           SET ProductType        = @productType,
               Name               = LTRIM(RTRIM(@name)),
               Description        = @description,
               PricingJson        = @pricingJson,
               ProductDetailsJson = @productDetailsJson,
               SourceJson         = @sourceJson,
               IsActive           = @isActive,
               SortOrder          = @sortOrder,
               updatedAt          = @now
         WHERE id = @productId AND KennelId = @kennelId;
    END

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;
    SELECT @productId AS productId;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_addEditProduct',
            ERROR_MESSAGE(), @procName, @hasherId, @kennelId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
