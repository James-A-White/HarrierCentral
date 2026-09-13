-- =====================================================================
-- Run-once: move the catalogue onto JSON (3.1, 2026-09-13)
--
--   James: "let's be adults and use JSON". Two changes.
--
--   1. PhotoUrls, a '|'-delimited string, becomes a JSON array inside
--      ProductDetailsJson under "photos". A URL can legally contain very
--      nearly any punctuation, so ANY delimiter was a bet; an array is not.
--
--   2. Pricing moves out of PriceCharged / PromotionalCredit / UnitCost /
--      RunCount and into a single PricingJson, so a product can express the
--      pricing model it actually has: one price, member and non-member, a
--      choice of amounts, a price per size, or a deposit and a balance.
--
--   The usual objection to money in JSON is that it cannot be summed. That
--   objection does not apply here, and the distinction matters:
--   NOTHING SUMS THE CATALOGUE. The accounting sums PAYMENTS, and
--   HC.Payment keeps its typed, indexed, DECIMAL amount columns untouched.
--   A product describes how to REACH a price; a payment records the price
--   actually TAKEN. Only the second is arithmetic. It also means a hasher's
--   2024 payment keeps its 2024 price after the kennel repricing, which a
--   join to a live catalogue row could never promise.
--
--   Safe to do now and expensive later: at the time of writing there are 5
--   products, 0 with photos, and 0 payments carrying a ProductId or a
--   ProductVariant. The script refuses to run if that has changed.
--
--   HC.Product has NO UpdatedAt trigger (it mirrors HC.Song), so its ALTERs
--   need no trigger dance. HC.Payment DOES, and its one ALTER is wrapped.
--
--   After running: move this file to db/hc6/app/archive/.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID('HC.Product', 'U') IS NULL
BEGIN
    RAISERROR('HC.Product does not exist. Run 2026-09-13_create_Product.sql first.', 16, 1);
    RETURN;
END

-- Guard: this migration hand-builds PricingJson from four columns. That is
-- only safe while the catalogue is tiny and nothing has been sold against it.
IF EXISTS (SELECT 1 FROM HC.Payment WHERE ProductId IS NOT NULL)
BEGIN
    RAISERROR('Payments already reference products. Rework the migration before running.', 16, 1);
    RETURN;
END

-- ---------------------------------------------------------------------
-- 1. Photos: '|'-delimited column -> "photos" array in ProductDetailsJson
-- ---------------------------------------------------------------------
IF COL_LENGTH('HC.Product', 'PhotoUrls') IS NOT NULL
BEGIN
    UPDATE p
       SET ProductDetailsJson =
           JSON_MODIFY(
               ISNULL(NULLIF(p.ProductDetailsJson, ''), '{}'),
               '$.photos',
               JSON_QUERY(
                   (SELECT '[' + STRING_AGG('"' + STRING_ESCAPE(LTRIM(RTRIM(s.value)), 'json') + '"', ',') + ']'
                      FROM STRING_SPLIT(p.PhotoUrls, '|') s
                     WHERE LTRIM(RTRIM(s.value)) <> '')
               )
           )
      FROM HC.Product p
     WHERE NULLIF(LTRIM(RTRIM(ISNULL(p.PhotoUrls, ''))), '') IS NOT NULL;

    PRINT CONCAT('Photos migrated into ProductDetailsJson: ', @@ROWCOUNT);

    ALTER TABLE HC.Product DROP COLUMN PhotoUrls;
    PRINT 'HC.Product.PhotoUrls dropped';
END
ELSE PRINT 'HC.Product.PhotoUrls already gone';
GO

-- ---------------------------------------------------------------------
-- 2. PricingJson
-- ---------------------------------------------------------------------
IF COL_LENGTH('HC.Product', 'PricingJson') IS NULL
BEGIN
    ALTER TABLE HC.Product ADD PricingJson NVARCHAR(4000) NULL
        CONSTRAINT CK_Product_PricingJson
        CHECK (PricingJson IS NULL OR ISJSON(PricingJson) = 1);
    PRINT 'HC.Product.PricingJson added';
END
ELSE PRINT 'HC.Product.PricingJson already exists';
GO

-- Build the existing five rows' pricing from the columns about to go.
-- Everything today is a single fixed price, so every row becomes mode
-- "fixed"; the other modes exist for what is created from now on.
-- Zeros are omitted rather than written, so a product with no cost has no
-- unitCost key instead of a misleading "unitCost": 0.
IF COL_LENGTH('HC.Product', 'PriceCharged') IS NOT NULL
BEGIN
    UPDATE HC.Product
       SET PricingJson =
           '{"mode":"fixed","price":' + CONVERT(NVARCHAR(30), CONVERT(DECIMAL(10,2), PriceCharged))
           + CASE WHEN UnitCost <> 0
                  THEN ',"unitCost":' + CONVERT(NVARCHAR(30), CONVERT(DECIMAL(10,2), UnitCost))
                  ELSE '' END
           + CASE WHEN PromotionalCredit <> 0
                  THEN ',"promotionalCredit":' + CONVERT(NVARCHAR(30), CONVERT(DECIMAL(10,2), PromotionalCredit))
                  ELSE '' END
           + CASE WHEN RunCount IS NOT NULL
                  THEN ',"runsIncluded":' + CONVERT(NVARCHAR(30), RunCount)
                  ELSE '' END
           + '}'
     WHERE PricingJson IS NULL;

    PRINT CONCAT('PricingJson built for existing rows: ', @@ROWCOUNT);
END
GO

-- Prove every row parsed before anything is dropped.
IF EXISTS (SELECT 1 FROM HC.Product WHERE PricingJson IS NOT NULL AND ISJSON(PricingJson) = 0)
BEGIN
    RAISERROR('A PricingJson value is not valid JSON. Nothing dropped.', 16, 1);
    RETURN;
END
GO

-- Defaults have to go before their columns can.
DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql = @sql + 'ALTER TABLE HC.Product DROP CONSTRAINT ' + QUOTENAME(dc.name) + ';'
FROM sys.default_constraints dc
JOIN sys.columns c ON c.object_id = dc.parent_object_id AND c.column_id = dc.parent_column_id
WHERE dc.parent_object_id = OBJECT_ID('HC.Product')
  AND c.name IN ('PriceCharged', 'PromotionalCredit', 'UnitCost', 'RunCount');
IF (@sql <> '') EXEC sp_executesql @sql;
GO

IF COL_LENGTH('HC.Product', 'PriceCharged') IS NOT NULL
BEGIN
    ALTER TABLE HC.Product DROP COLUMN PriceCharged, PromotionalCredit, UnitCost, RunCount;
    PRINT 'Priced columns dropped — pricing now lives in PricingJson';
END
ELSE PRINT 'Priced columns already dropped';
GO

-- ---------------------------------------------------------------------
-- 3. HC.Payment.ProductVariant: a bare string becomes JSON
--
--    What the hasher actually chose is not always one value. A shirt is a
--    size; a collection is an amount; a trip may be a size AND a date. JSON
--    holds all three shapes: {"size":"L"} / {"amount":25} / {"size":"L",
--    "date":"2026-11-14"}.
--
--    ⚠ HC.Payment IS SYNCED. Trigger off for the ALTER or all 91,563 rows
--    are stamped and the whole table re-syncs to every phone.
-- ---------------------------------------------------------------------
IF EXISTS (SELECT 1 FROM sys.columns
           WHERE object_id = OBJECT_ID('HC.Payment') AND name = 'ProductVariant'
             AND max_length < 2000)
BEGIN
    DISABLE TRIGGER HC.trgUpdateModifiedOnDateForPayment ON HC.Payment;

    ALTER TABLE HC.Payment ALTER COLUMN ProductVariant NVARCHAR(1000) NULL;

    ENABLE TRIGGER HC.trgUpdateModifiedOnDateForPayment ON HC.Payment;

    PRINT 'HC.Payment.ProductVariant widened to NVARCHAR(1000) for JSON';
END
ELSE PRINT 'HC.Payment.ProductVariant already wide enough';
GO

-- Whatever happened above, the sync trigger must not be left disabled.
IF EXISTS (SELECT 1 FROM sys.triggers
           WHERE name = 'trgUpdateModifiedOnDateForPayment' AND is_disabled = 1)
BEGIN
    ENABLE TRIGGER HC.trgUpdateModifiedOnDateForPayment ON HC.Payment;
    PRINT 'Payment trigger was left disabled — re-enabled.';
END
GO

-- Proof the ALTER stamped nothing: this must come back 0.
SELECT COUNT(*) AS paymentsStampedInTheLastMinute
  FROM HC.Payment
 WHERE updatedAt > DATEADD(MINUTE, -1, SYSUTCDATETIME());
GO

-- What the catalogue looks like now.
SELECT LEFT(k.KennelName, 30) AS kennel,
       p.Name                 AS name,
       p.ProductType          AS type,
       p.PricingJson          AS pricing,
       ISNULL(p.ProductDetailsJson, '') AS details,
       p.IsActive             AS onSale
FROM HC.Product p
JOIN HC.Kennel k ON k.id = p.KennelId
WHERE p.Removed = 0
ORDER BY k.KennelName, p.SortOrder;
GO
