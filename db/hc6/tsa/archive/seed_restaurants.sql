-- =====================================================================
-- Run-once: Seed restaurant and menu item data
-- Prototype seed — 3 restaurants near JFK, LGA, and EWR
-- =====================================================================

DECLARE @r1 UNIQUEIDENTIFIER = NEWID();
DECLARE @r2 UNIQUEIDENTIFIER = NEWID();
DECLARE @r3 UNIQUEIDENTIFIER = NEWID();

INSERT INTO [TSA].[Restaurant]
    ([id], [name], [address], [latitude], [longitude], [cuisineType], [serviceTypes],
     [phone], [description], [dailyQuota], [isActive])
VALUES
    (@r1, 'Brooklyn Terminal Grill',
     '156-10 Rockaway Blvd, Jamaica, NY 11434',
     40.657900, -73.789200,
     'American', 'pickup,dine-in',
     '+17185550101',
     'Family-owned grill just minutes from JFK. Hot meals made fresh all day.',
     60, 1),

    (@r2, 'Queens Kitchen Diner',
     '82-11 Ditmars Blvd, East Elmhurst, NY 11369',
     40.761200, -73.862900,
     'American Diner', 'pickup,delivery,dine-in',
     '+17185550202',
     'Classic New York diner near LaGuardia. Serving breakfast, lunch, and dinner.',
     80, 1),

    (@r3, 'Newark Airport Bites',
     '120 Haynes Ave, Newark, NJ 07114',
     40.703700, -74.172500,
     'Mixed', 'pickup',
     '+19735550303',
     'Quick, hearty meals near EWR. Built for workers on the go.',
     50, 1);

-- Menu items for Brooklyn Terminal Grill
INSERT INTO [TSA].[MenuItem] ([restaurantId], [name], [description], [dailyQuota], [isAvailable])
VALUES
    (@r1, 'Classic Burger', 'Half-pound beef patty, lettuce, tomato, onion, house sauce on a brioche bun. Served with fries.', 25, 1),
    (@r1, 'BLT Club Sandwich', 'Triple-decker with bacon, lettuce, tomato, and mayo on toasted white bread. Served with chips.', 20, 1),
    (@r1, 'Veggie Wrap', 'Grilled peppers, hummus, spinach, cucumber, and feta in a whole wheat wrap.', 15, 1);

-- Menu items for Queens Kitchen Diner
INSERT INTO [TSA].[MenuItem] ([restaurantId], [name], [description], [dailyQuota], [isAvailable])
VALUES
    (@r2, 'Grilled Chicken Plate', 'Seasoned grilled chicken breast with mashed potatoes and seasonal vegetables.', 30, 1),
    (@r2, 'Pasta Bolognese', 'House-made meat sauce over penne pasta with garlic bread.', 25, 1),
    (@r2, 'Breakfast Platter', 'Two eggs any style, bacon or sausage, home fries, and toast. Served all day.', 25, 1);

-- Menu items for Newark Airport Bites
INSERT INTO [TSA].[MenuItem] ([restaurantId], [name], [description], [dailyQuota], [isAvailable])
VALUES
    (@r3, 'Falafel Wrap', 'Crispy falafel, tahini, pickled vegetables, and hot sauce in a warm pita.', 20, 1),
    (@r3, 'Grilled Salmon Bowl', 'Atlantic salmon fillet over jasmine rice with steamed broccoli and lemon butter.', 15, 1),
    (@r3, 'Rice & Beans Bowl', 'Slow-cooked red beans over white rice with fried plantain and hot sauce.', 20, 1);

PRINT 'Seed data inserted: 3 restaurants, 9 menu items.'
