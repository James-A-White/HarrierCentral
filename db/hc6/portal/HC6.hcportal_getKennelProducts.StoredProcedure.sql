CREATE OR ALTER PROCEDURE [HC6].[hcportal_getKennelProducts]

    -- required parameters
    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @publicKennelId UNIQUEIDENTIFIER = NULL,
    -- 0 = everything the kennel has ever listed, 1 = only what is on sale
    @activeOnly     SMALLINT         = 0

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getKennelProducts
-- Description: One kennel's product catalogue for the portal's Products
--              view: run packages, memberships, haberdashery. Returns
--              inactive items too by default, because the portal is where
--              something gets taken off sale and put back on.
--
--              Unlike the app's copy of this data, this rowset INCLUDES
--              SourceJson — the supplier's name and phone. That is the
--              point of the portal view: it is the admin surface, and the
--              supplier detail is deliberately kept off hashers' phones.
--
-- Authorization: the manageProducts feature, via HC6.CheckKennelPermission
--              — GM, VGM, Hash Cash, Haberdasher, or the ManageHashCash
--              flag. ValidatePortalAuth proves WHO is calling, not what
--              they may do, so the explicit gate is required.
-- Parameters: @deviceId, @accessToken (auth)
--             @publicKennelId (routing)
--             @activeOnly (0 = all, 1 = on sale only)
-- Returns: Rowset of products, or the standard error envelope
-- Author: Harrier Central
-- Created: 2026-09-13
-- HC5 Source: none (new)
-- Breaking Changes: none
--
-- ⚠ DEPLOY ORDER. This SP reads HC.Payment.ProductId in the unitsSold
--   subquery. HC.Payment EXISTS, so SQL Server binds that column AT CREATE
--   TIME and CREATE fails with "Invalid column name 'ProductId'" until
--   2026-09-13_create_Product.sql has run. Deferred name resolution only
--   covers a MISSING TABLE (which is why the HC.Product references here
--   and in hcapp_syncUserData are fine), never a missing column on a table
--   that exists.
--
--   tools/deploy_hc6.sh runs sqlcmd with -b and exits on the first failure,
--   and portal SPs deploy BEFORE app SPs. So while this file sits here and
--   the column is missing, EVERY deploy aborts, including deploys of
--   unrelated work. Run the schema script first.
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @hasherId UNIQUEIDENTIFIER;

-- Validation: publicKennelId
IF @publicKennelId IS NULL
BEGIN
    SELECT 0 AS Success, 'Null or invalid publicKennelId' AS ErrorMessage;
    RETURN;
END

-- Auth validation
DECLARE @authError NVARCHAR(255);
DECLARE @callerType INT;
EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @publicKennelId,
     @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

DECLARE @kennelId UNIQUEIDENTIFIER;
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

BEGIN TRY

    SELECT
        p.id                 AS productId,
        @publicKennelId      AS publicKennelId,
        p.ProductType        AS productType,
        p.Name               AS name,
        p.Description        AS description,
        -- Pricing is one json field: a product may be one price, a member
        -- and non-member price, a choice of amounts, a price per size, or a
        -- deposit and a balance. Margin is no longer computed here — there
        -- is not always a single price to subtract a cost from, so the
        -- client derives it from the mode.
        p.PricingJson        AS pricingJson,
        p.ProductDetailsJson AS productDetailsJson,
        p.SourceJson         AS sourceJson,
        p.IsActive           AS isActive,
        p.SortOrder          AS sortOrder,
        -- How many have been sold. Drives the warning on the edit form:
        -- something that has sold is taken off sale, never removed.
        (SELECT COUNT(*) FROM HC.Payment pay
          WHERE pay.ProductId = p.id AND pay.removed = 0) AS unitsSold,
        p.createdAt          AS createdAt,
        p.updatedAt          AS updatedAt
    FROM HC.Product p
    WHERE p.KennelId = @kennelId
      AND p.Removed = 0
      AND (@activeOnly = 0 OR p.IsActive = 1)
    ORDER BY p.IsActive DESC, p.SortOrder ASC, p.Name ASC;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_getKennelProducts',
            ERROR_MESSAGE(), @procName, @hasherId, @kennelId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
