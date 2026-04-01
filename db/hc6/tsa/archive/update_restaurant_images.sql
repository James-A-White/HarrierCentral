-- =====================================================================
-- Migration: Set imageUrl for restaurants and menu items
-- Run once, then archive.
-- =====================================================================

DECLARE @base NVARCHAR(200) = 'https://harriercentral.blob.core.windows.net/harrier/';

-- ── Restaurants ───────────────────────────────────────────────────────
UPDATE [TSA].[Restaurant] SET [imageUrl] = @base + 'brooklyn-terminal-grill.jpg' WHERE [name] = 'Brooklyn Terminal Grill';
UPDATE [TSA].[Restaurant] SET [imageUrl] = @base + 'newark-airport-bites.jpg'    WHERE [name] = 'Newark Airport Bites';
UPDATE [TSA].[Restaurant] SET [imageUrl] = @base + 'queens-kitchen-diner.jpg'    WHERE [name] = 'Queens Kitchen Diner';

-- ── Brooklyn Terminal Grill meals ─────────────────────────────────────
UPDATE [TSA].[MenuItem] SET [imageUrl] = @base + 'blt-club-sandwich.jpg' WHERE [name] = 'BLT Club Sandwich';
UPDATE [TSA].[MenuItem] SET [imageUrl] = @base + 'classic-burger.jpg'    WHERE [name] = 'Classic Burger';
UPDATE [TSA].[MenuItem] SET [imageUrl] = @base + 'veggie-wrap.jpg'       WHERE [name] = 'Veggie Wrap';

-- ── Newark Airport Bites meals ────────────────────────────────────────
UPDATE [TSA].[MenuItem] SET [imageUrl] = @base + 'falafel-wrap.jpg'        WHERE [name] = 'Falafel Wrap';
UPDATE [TSA].[MenuItem] SET [imageUrl] = @base + 'grilled-salmon-bowl.jpg' WHERE [name] = 'Grilled Salmon Bowl';
UPDATE [TSA].[MenuItem] SET [imageUrl] = @base + 'rice-and-beans-bowl.jpg' WHERE [name] = 'Rice & Beans Bowl';

-- ── Queens Kitchen Diner meals ────────────────────────────────────────
UPDATE [TSA].[MenuItem] SET [imageUrl] = @base + 'breakfast-platter.jpg'    WHERE [name] = 'Breakfast Platter';
UPDATE [TSA].[MenuItem] SET [imageUrl] = @base + 'grilled-chicken-plate.jpg' WHERE [name] = 'Grilled Chicken Plate';
UPDATE [TSA].[MenuItem] SET [imageUrl] = @base + 'pasta-bolognese.jpg'      WHERE [name] = 'Pasta Bolognese';

-- Verify
SELECT [name], [imageUrl] FROM [TSA].[Restaurant] ORDER BY [name];
SELECT r.[name] AS restaurant, mi.[name] AS meal, mi.[imageUrl]
FROM   [TSA].[MenuItem] mi
JOIN   [TSA].[Restaurant] r ON mi.[restaurantId] = r.[id]
ORDER  BY r.[name], mi.[name];
