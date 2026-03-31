-- =====================================================================
-- Run-once: Seed Portofino Ristorante and menu items
-- Archive this file after running.
-- Note: imageUrl is NULL — upload the image to Azure Blob Storage and
--       run: UPDATE [TSA].[Restaurant] SET imageUrl = '<url>' WHERE name = 'Portofino Ristorante'
-- =====================================================================

DECLARE @r1 UNIQUEIDENTIFIER = NEWID();

INSERT INTO [TSA].[Restaurant]
    ([id], [name], [address], [latitude], [longitude], [cuisineType], [serviceTypes],
     [phone], [description], [imageUrl], [dailyQuota], [isActive])
VALUES
    (@r1, 'Portofino Ristorante',
     'New York, NY',
     NULL, NULL,
     'Italian', 'dine-in,pickup',
     NULL,
     'Superb Italian cuisine. Classic red-sauce dishes, fresh pasta, and a warm neighbourhood feel.',
     NULL, 60, 1);

INSERT INTO [TSA].[MenuItem] ([restaurantId], [name], [description], [dailyQuota], [isAvailable])
VALUES
    (@r1, 'Margherita Pizza',     'Thin-crust pizza with San Marzano tomato, fresh mozzarella, and basil.', 20, 1),
    (@r1, 'Spaghetti Carbonara',  'Spaghetti with guanciale, egg, Pecorino Romano, and black pepper.', 20, 1),
    (@r1, 'Chicken Parmigiana',   'Breaded chicken breast, marinara sauce, and melted mozzarella. Served with pasta.', 15, 1),
    (@r1, 'Eggplant Parmigiana',  'Layered fried eggplant with marinara and mozzarella. Vegetarian.', 10, 1);

PRINT 'Portofino Ristorante seeded.'
