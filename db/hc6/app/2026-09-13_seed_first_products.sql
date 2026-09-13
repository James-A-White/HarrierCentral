-- =====================================================================
-- Run-once: the first four catalogue entries (3.1, 2026-09-13)
--
--   Two memberships James named, one membership for Brussels at EUR 25,
--   and a shirt for the test kennel to exercise the haberdashery columns.
--
--   Keyed on kennel id, NOT short name. Short names are not unique among
--   live kennels: 33 are duplicated and 'SH3' belongs to ten different
--   clubs, so a seed matched on KennelShortName would write to whichever
--   one came back first.
--
--   Idempotent: fixed ids, and every write is guarded, so a second run
--   changes nothing.
--
--   PREREQUISITE: 2026-09-13_create_Product.sql must have run.
--   After running: move this file to db/hc6/app/archive/.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF OBJECT_ID('HC.Product', 'U') IS NULL
BEGIN
    RAISERROR('HC.Product does not exist. Run 2026-09-13_create_Product.sql first.', 16, 1);
    RETURN;
END

DECLARE @swh3   UNIQUEIDENTIFIER = 'b0bc033b-918b-4c1a-81c9-806283f48e33'; -- Sir Walter's H3, Raleigh
DECLARE @test   UNIQUEIDENTIFIER = 'ef20cb1f-3e47-46d2-902b-5fad69f19f9d'; -- A Harrier Central Testx, London
DECLARE @bmph3  UNIQUEIDENTIFIER = 'd1d51d20-5c09-458a-ad0f-d22a8b5ba019'; -- Brussels Manneke Piss H3

-- Fail loudly rather than seeding products onto the wrong club.
IF (SELECT COUNT(*) FROM HC.Kennel WHERE id IN (@swh3, @test, @bmph3) AND deleted = 0 AND Removed = 0) <> 3
BEGIN
    RAISERROR('One of the three target kennels is missing or removed. Nothing written.', 16, 1);
    RETURN;
END

DECLARE @now DATETIMEOFFSET(7) = SYSDATETIMEOFFSET();

-- ProductType: 2 = membership, 3 = haberdashery (matches HC.Payment.ProductType).
DECLARE @seed TABLE (
    id                UNIQUEIDENTIFIER,
    KennelId          UNIQUEIDENTIFIER,
    ProductType       SMALLINT,
    Name              NVARCHAR(200),
    Description       NVARCHAR(4000),
    PriceCharged      SMALLMONEY,
    PromotionalCredit SMALLMONEY,
    UnitCost          SMALLMONEY,
    ProductDetailsJson NVARCHAR(4000),
    PhotoUrls         NVARCHAR(2000),
    SourceJson        NVARCHAR(4000),
    IsActive          SMALLINT,
    SortOrder         INT
);

INSERT @seed VALUES
-- ---------------------------------------------------------------------
-- 1. Sir Walter's H3 — annual membership.
--
--    ⚠ DRAFT, DELIBERATELY NOT ON SALE (IsActive = 0, price 0).
--    James did not give a price and there is nothing in the data to infer
--    one: Sir Walter's has 3,510 payments and every one is ProductType 1,
--    an event fee. Their run price is 20 for members and 25-30 for guests,
--    which says nothing about what a year costs. Rather than invent a
--    figure and sync it to every phone as a real offer, the row exists and
--    waits. Set the price in the kennel editor and switch IsActive on.
-- ---------------------------------------------------------------------
('adbafce1-396e-4c33-ac42-e0f89b883f91', 'b0bc033b-918b-4c1a-81c9-806283f48e33', 2,
 N'Annual Membership',
 N'Membership of Sir Walter''s H3. Members pay the lower run fee. DRAFT: price not yet set.',
 0, 0, 0, NULL, NULL, NULL, 0, 10),

-- ---------------------------------------------------------------------
-- 2. Test kennel — annual membership, priced at 35 to MATCH the kennel's
--    existing HC.Kennel.MembershipPrice. Two different numbers for the same
--    membership on the same kennel is the one thing worth avoiding here.
--    See the note at the foot of this file.
-- ---------------------------------------------------------------------
('87f619f0-ec16-4057-9b9c-5615b1d4b23d', 'ef20cb1f-3e47-46d2-902b-5fad69f19f9d', 2,
 N'Annual Membership',
 N'Twelve months'' membership. Members pay the member run price.',
 35, 0, 0, NULL, NULL, NULL, 1, 10),

-- ---------------------------------------------------------------------
-- 3. Brussels Manneke Piss H3 — EUR 25 membership.
--
--    No discount and no promotional credit: PriceCharged 25, everything
--    else zero. What it buys is priority entrance to events, which is a
--    human arrangement the app does not enforce, so it lives in the
--    description. There is no column that could enforce it and inventing
--    one for a single club's door policy would be the wrong trade.
--
--    25 is euros without anything having to say so: Brussels resolves
--    through City -> Region -> Country to EUR, and the app already reads
--    the symbol that way.
-- ---------------------------------------------------------------------
('d4ed8933-3ff5-4024-9a3e-e32d967d2ef4', 'd1d51d20-5c09-458a-ad0f-d22a8b5ba019', 2,
 N'Annual Membership',
 N'Membership of the Brussels Manneke Piss H3, EUR 25 a year. Membership does not reduce the run fee. It gives members priority entrance to events.',
 25, 0, 0, NULL, NULL, NULL, 1, 10),

-- ---------------------------------------------------------------------
-- 4. Test kennel — a shirt, to exercise ProductDetailsJson, PhotoUrls and
--    SourceJson. Sold at 20 against a 12 unit cost, so the accounting
--    section has a margin to show. Sizes live in the details JSON; the size
--    a hasher actually picks lands on HC.Payment.ProductVariant.
-- ---------------------------------------------------------------------
('b3b779a0-ffdb-43f0-b703-16a16dfe1805', 'ef20cb1f-3e47-46d2-902b-5fad69f19f9d', 3,
 N'Hash Shirt',
 N'Cotton hash shirt with the kennel logo on the chest and the receding hare on the back.',
 20, 0, 12,
 N'{"sizes":["S","M","L","XL","XXL"]}',
 NULL,
 N'{"supplier":"Example Print Co","contact":"Jo Bloggs","phone":"+44 20 7946 0000","email":"orders@example.invalid","minimumOrder":25,"leadTimeDays":14,"notes":"Artwork held on file. Reorder by email quoting HC-SHIRT-01."}',
 1, 20);

INSERT HC.Product (id, KennelId, ProductType, Name, Description,
                   PriceCharged, PromotionalCredit, UnitCost, RunCount,
                   ProductDetailsJson, PhotoUrls, SourceJson,
                   IsActive, SortOrder, CreatedByUserId,
                   createdAt, updatedAt, updatedAtBias, Removed)
SELECT s.id, s.KennelId, s.ProductType, s.Name, s.Description,
       s.PriceCharged, s.PromotionalCredit, s.UnitCost, NULL,
       s.ProductDetailsJson, s.PhotoUrls, s.SourceJson,
       s.IsActive, s.SortOrder, NULL,
       @now, @now, 0, 0
FROM @seed s
WHERE NOT EXISTS (SELECT 1 FROM HC.Product p WHERE p.id = s.id);

PRINT CONCAT('Products inserted: ', @@ROWCOUNT);
GO

-- What is now on the shelf.
SELECT LEFT(k.KennelName, 34)      AS kennel,
       p.ProductType               AS type,
       p.Name                      AS name,
       p.PriceCharged              AS price,
       p.UnitCost                  AS cost,
       ISNULL(JSON_VALUE(p.ProductDetailsJson, '$.sizes[0]'), '-') AS firstSize,
       p.IsActive                  AS onSale
FROM HC.Product p
JOIN HC.Kennel k ON k.id = p.KennelId
WHERE p.Removed = 0
ORDER BY k.KennelName, p.SortOrder, p.Name;
GO

-- =====================================================================
-- CURRENCY — resolved, nothing to add.
--
--   HC.Product needs no currency column. Every one of the 390 live kennels
--   resolves City -> Region -> Country to a CurrencyCode, CurrencySymbol
--   and DigitsAfterDecimal, and the app ALREADY reads it that way:
--   common_queries.dart does COALESCE(kennel.CurrencySymbol,
--   country.CurrencySymbol, '$'). Brussels comes back EUR, Raleigh USD,
--   the test kennel GBP. The symbol carries a '^' marking where the amount
--   goes.
--
--   So a product inherits its currency exactly as an event price already
--   does, with no new column and no backfill.
--
-- =====================================================================
-- ⚠ OPEN: TWO PLACES NOW HOLD A MEMBERSHIP PRICE.
--
--   HC.Kennel.MembershipPrice already exists and is what
--   hcapp_processPayment charges today. A membership row in this catalogue
--   is a second home for the same number, and nothing yet says which wins.
--
--   Nothing breaks on this script — seeding a product does not change what
--   anyone is charged — but 3.1 has to pick one. The suggestion is that the
--   product wins where a kennel has an active membership product, with
--   Kennel.MembershipPrice as the fallback for the 390 kennels that do not.
--
--   Note the two disagree RIGHT NOW for Brussels: the product says 25,
--   HC.Kennel.MembershipPrice says 0. Until processPayment prefers the
--   product, a Brussels membership charge still takes 0. Left alone
--   deliberately: changing a real club's charging config was not asked for.
--
--   The TERM is not affected and is not duplicated. It stays on the kennel
--   (MembershipRenewalMode + MembershipDurationInMonths), where the expiry
--   maths already lives. All 390 live kennels are mode 1, rolling, 12
--   months.
-- =====================================================================
