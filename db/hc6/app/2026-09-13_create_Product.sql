-- =====================================================================
-- Run-once: HC.Product — the kennel's catalogue (3.1, 2026-09-13)
--
--   James asked for this table by name. A product type on the payment row
--   says WHAT KIND of thing was sold; it cannot say that the Brussels
--   11-run package costs 70 and grants 7 of promotional credit, because
--   that is per kennel and changes over time. Recording those numbers only
--   on the payment would capture what happened but never what is on sale,
--   so a kennel could not offer a package without an admin retyping the
--   figures every time. A catalogue is a table.
--
--   SYNCED GLOBALLY — every kennel's products reach every phone, the same
--   way HC.Song and HC.Kennel already do (James, 2026-09-13). Two reasons:
--   the data is small (393 kennels, a handful of products each), and it
--   avoids a broken link. Syncing only followed kennels would mean
--   unfollowing a kennel orphaned the products behind that hasher's own
--   past payments.
--
--   ⚠ A SOLD PRODUCT IS NEVER REMOVED. The sync DELETES a local row when
--   the server marks it Removed, so retiring a haberdashery item would
--   make it vanish from every phone and break exactly the link the global
--   scope was chosen to protect — the same failure, one layer down. Taking
--   something off sale is IsActive = 0: the row keeps syncing, the shop
--   stops offering it, and last year's payment still resolves its product.
--   Removed stays for a product created in error and never sold.
--
--   After running: move this file to db/hc6/app/archive/.
-- =====================================================================
SET NOCOUNT ON;

IF OBJECT_ID('HC.Product', 'U') IS NULL
BEGIN
    CREATE TABLE [HC].[Product] (
        [id]                UNIQUEIDENTIFIER NOT NULL
            CONSTRAINT [PK_Product] PRIMARY KEY CLUSTERED,
        [KennelId]          UNIQUEIDENTIFIER NOT NULL,

        -- Matches HC.Payment.ProductType so a payment and its product agree
        -- on what kind of thing changed hands. 1 event, 2 membership,
        -- 3 haberdashery, and from 3.1: 4 run package, 5 away weekend.
        [ProductType]       SMALLINT         NOT NULL
            CONSTRAINT [DF_Product_ProductType] DEFAULT (0),

        [Name]              NVARCHAR(200)    NOT NULL,
        [Description]       NVARCHAR(1000)   NULL,

        -- What the hasher pays.
        [PriceCharged]      SMALLMONEY       NOT NULL
            CONSTRAINT [DF_Product_PriceCharged] DEFAULT (0),

        -- Credit granted on purchase, over and above the cash. A package is
        -- "pay 70, get 7": PriceCharged 70, PromotionalCredit 7. Zero for an
        -- ordinary sale. smallmoney to match HC.Payment's four amount
        -- columns, which this has to add up with.
        [PromotionalCredit] SMALLMONEY       NOT NULL
            CONSTRAINT [DF_Product_PromotionalCredit] DEFAULT (0),

        -- What it costs the kennel to supply. Zero for a run; a real figure
        -- for a shirt. Price minus cost is the margin the accounting
        -- section will want, and nothing else records it.
        [UnitCost]          SMALLMONEY       NOT NULL
            CONSTRAINT [DF_Product_UnitCost] DEFAULT (0),

        -- How many runs a package is worth, for a run package. NULL for
        -- anything that is not counted in runs.
        [RunCount]          SMALLINT         NULL,

        -- On sale or not. NOT the same as Removed — see the header.
        [IsActive]          SMALLINT         NOT NULL
            CONSTRAINT [DF_Product_IsActive] DEFAULT (1),

        [SortOrder]         INT              NOT NULL
            CONSTRAINT [DF_Product_SortOrder] DEFAULT (0),

        [CreatedByUserId]   UNIQUEIDENTIFIER NULL,
        [createdAt]         DATETIMEOFFSET(7) NOT NULL
            CONSTRAINT [DF_Product_createdAt] DEFAULT (SYSDATETIMEOFFSET()),

        -- Sync bookkeeping, mirroring HC.Song: the writers set updatedAt
        -- explicitly (this table has no trigger), and updatedAtBias keeps a
        -- page boundary deterministic when many rows share a timestamp.
        [updatedAt]         DATETIMEOFFSET(7) NOT NULL
            CONSTRAINT [DF_Product_updatedAt] DEFAULT (SYSDATETIMEOFFSET()),
        [updatedAtBias]     INT              NOT NULL
            CONSTRAINT [DF_Product_updatedAtBias] DEFAULT (0),
        [Removed]           SMALLINT         NOT NULL
            CONSTRAINT [DF_Product_Removed] DEFAULT (0)
    );

    -- The sync reads by updatedAt; the shop reads a kennel's active items.
    CREATE NONCLUSTERED INDEX [IX_Product_UpdatedAt]
        ON [HC].[Product] ([updatedAt]) INCLUDE ([id]);
    CREATE NONCLUSTERED INDEX [IX_Product_Kennel_Active]
        ON [HC].[Product] ([KennelId], [IsActive])
        INCLUDE ([ProductType], [SortOrder]) WHERE [Removed] = 0;

    PRINT 'HC.Product created';
END
ELSE PRINT 'HC.Product already exists';
GO

-- The payment points at what was sold. Nullable: every one of the 91,540
-- payments that exist predates the catalogue, and an ordinary run fee may
-- never have a product behind it.
--
-- ⚠ HC.Payment IS SYNCED. Disable its UpdatedAt trigger for the ALTER or
-- every row is stamped and the whole table re-syncs to every phone.
IF COL_LENGTH('HC.Payment', 'ProductId') IS NULL
BEGIN
    DISABLE TRIGGER [HC].[trgUpdateModifiedOnDateForPayment] ON [HC].[Payment];

    ALTER TABLE [HC].[Payment] ADD [ProductId] UNIQUEIDENTIFIER NULL;

    ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForPayment] ON [HC].[Payment];

    PRINT 'HC.Payment.ProductId added';
END
ELSE PRINT 'HC.Payment.ProductId already exists';
GO

-- Whatever happened above, the sync trigger must not be left disabled.
IF EXISTS (SELECT 1 FROM sys.triggers
           WHERE name = 'trgUpdateModifiedOnDateForPayment' AND is_disabled = 1)
BEGIN
    ENABLE TRIGGER [HC].[trgUpdateModifiedOnDateForPayment] ON [HC].[Payment];
    PRINT 'Payment trigger was left disabled — re-enabled.';
END
GO

-- Proof the ALTER stamped nothing: this must come back 0.
SELECT COUNT(*) AS paymentsStampedInTheLastMinute
  FROM HC.Payment
 WHERE updatedAt > DATEADD(MINUTE, -1, SYSUTCDATETIME());
GO
