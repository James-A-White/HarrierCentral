-- Run-once (James, 2026-10-04: "read through all of the Chichester run
-- descriptions … find which ones were special events and flag them").
-- 282 runs shortlisted by keyword, every write-up read in full; 101 judged
-- special: 97 Special local event (2), 4 Regional event (3). Sets
-- HC.Event.EventGeographicScope (what the app's Events filter reads); an
-- ordinary edit, so the runs re-sync to phones. Each change is logged.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @kennelId UNIQUEIDENTIFIER = '1acfb597-f2e5-4c2b-bb81-138676fc0c42';
DECLARE @f TABLE (EventNumber INT PRIMARY KEY, Scope SMALLINT, Why NVARCHAR(200));
INSERT @f VALUES
    (100, 2, N'100th run milestone'),
    (200, 2, N'200th run milestone'),
    (250, 2, N'250th run milestone'),
    (300, 2, N'300th run milestone'),
    (400, 2, N'400th run milestone'),
    (500, 2, N'500th run milestone'),
    (527, 2, N'Easter Day; hares in rabbit ears'),
    (545, 2, N'Christmas run in Xmas attire'),
    (546, 2, N'New Year run: hasher of the year, new JMs'),
    (555, 2, N'555th run on 05-05-05'),
    (559, 2, N'Midsummer hash barbecue and raffle'),
    (572, 2, N'Christmas run: mulled wine, mince pies'),
    (580, 2, N'Easter Hash: egg hunt'),
    (585, 2, N'Midsummer Hash barbecue'),
    (597, 2, N'Christmas run, Xmas spread'),
    (598, 2, N'2007 Hangover Hash'),
    (600, 2, N'600th run: T-shirt, banquet, cake'),
    (611, 2, N'Summer party, BBQ, raffle'),
    (623, 2, N'annual pre-xmas trail'),
    (624, 2, N'annual Hangover Hash'),
    (642, 2, N'25th Anniversary run'),
    (649, 2, N'Christmas run, festive wear'),
    (650, 2, N'New Year run: hasher of the year'),
    (657, 2, N'Easter Sunday run, Easter eggs'),
    (662, 2, N'summer BBQ hash'),
    (676, 2, N'hangover hash, awards, new JMs'),
    (688, 2, N'Summer BBQ bash at village hall'),
    (694, 2, N'joint run with Hursley H3'),
    (700, 2, N'700th run feast'),
    (702, 2, N'New Year hash: new JMs'),
    (710, 2, N'Easter Sunday egg prizes'),
    (714, 2, N'barbecue banquet and raffle'),
    (727, 2, N'Christmas run: tinsel, Santa hats'),
    (728, 2, N'New Year''s Day hangover rituals'),
    (736, 2, N'joint run with Portsmouth HHH'),
    (739, 2, N'Summer BBQ at Forestside village hall'),
    (753, 2, N'Hangover hash with feast'),
    (766, 2, N'BBQ party at Pancsi''s home: "grub and raffle prizes", "personing the BBQ"'),
    (770, 2, N'Run from Canman''s home, refreshments for his "eighty first birthday"'),
    (777, 2, N'Run 777: "celebration cake", "a great feast was assembled"'),
    (778, 2, N'Christmas run: festive hats, Santas, "festive meal for nearly forty", carol quiz'),
    (779, 2, N'New Year Hangover hash: Hasher of the Year, new JMs elected'),
    (791, 2, N'BBQ party at JM''s home with raffle, "unforgettable day"'),
    (798, 3, N'Multi-kennel BBQ hash hosted by Hursley HHH, three RAs'),
    (800, 2, N'800th run milestone: new shirts, celebration lunch at The Spur'),
    (804, 2, N'Christmas run: Santa hats, carols, "festive hashing", feast'),
    (809, 2, N'St David''s Day Welsh-themed hash, leeks hidden at checks'),
    (825, 2, N'WEMSFEST festival hash with leaflet and online publicity'),
    (831, 2, N'Christmas hash: sherry, mince pies, carols, "last Hash of the year"'),
    (832, 2, N'Hangover Hash with Hasher of the Year and "a sort of AGM"'),
    (835, 2, N'Valentine''s-themed A to B hash, love hearts on falsies'),
    (838, 3, N'"Gathering of the clans": six kennels, campers, Friday pub crawl'),
    (839, 2, N'Easter Sunday: coloured-stick hunt rewarded with Easter chocolate'),
    (845, 2, N'BBQ hash with "party mode", traditional raffle'),
    (856, 2, N'Halloween theme: skulls, skeletons, severed hand planted on trail'),
    (860, 2, N'New Year''s Day hash, review of year, new JMs announced'),
    (862, 2, N'Chinese New Year theme: Chinese hats, fortune cookies'),
    (863, 2, N'Valentine''s theme: red hearts on falsies, roses and chocolates'),
    (872, 2, N'"Our annual BBQ" at Two Ferrets Fighting''s place'),
    (874, 2, N'Joint run with IOW Hash and Haslemere, down-downs, games'),
    (880, 2, N'Joint hash with Surrey H3 (their run 2217)'),
    (881, 2, N'"Chichester hash joined forces with" Hursley HHH, joint run'),
    (882, 2, N'Memorial: "unveiling of a commemorative bench", minute''s silence'),
    (884, 2, N'Christmas lunch hash at golf club: crackers, paper hats'),
    (885, 2, N'Christmas run: festive dress, Santas, Christmas pudding costume'),
    (886, 2, N'Hangover hash: annual accounts, Hasher of the Year, new JMs'),
    (892, 2, N'Easter Sunday ribbon hunt for chocolate eggs'),
    (900, 2, N'900th run: BBQ party, raffle, commemorative shirts'),
    (904, 2, N'"Very first Red Dress Run for Chichester HHH"'),
    (908, 2, N'Armistice centenary: silence, "a poppy at almost every Check"'),
    (910, 2, N'Christmas lunch hash: seating plan, crackers, trimmings lunch'),
    (911, 2, N'Christmas run: JMs'' carols, Christmas pudding costume, free feast'),
    (937, 2, N'Christmas run: Santa hats, tinsel, pudding costume, prizes, feast'),
    (938, 2, N'New Year gathering: Hasher of the Year, new JMs, raffle'),
    (973, 2, N'Last hash of 2021: Christmas costumes, ribbon prizes'),
    (974, 2, N'New Year Hangover Hash, JM handover, Hasher of the Year'),
    (977, 2, N'Valentine''s-themed run, prize tokens'),
    (987, 2, N'annual BBQ run at Church Farm, raffle'),
    (990, 2, N'Canman''s ninetieth birthday celebration, cake'),
    (998, 2, N'Christmas run: sodden Santas, tinsel dog'),
    (1000, 2, N'1000th run: t-shirts, history talk, new JMs'),
    (1006, 2, N'Easter run: lollipops exchanged for Easter eggs'),
    (1007, 2, N'St George''s day run in celebratory garb'),
    (1008, 2, N'Joint run with Haslemere H3; coronation party food'),
    (1014, 2, N'Summer barbecue with raffle'),
    (1020, 2, N'Joint run with Isle of Wight Hash, as pirates'),
    (1025, 2, N'New Year run: Hasher of the Year, new Hash Masters'),
    (1028, 2, N'Red dress run'),
    (1030, 2, N'St Patrick''s day themed run'),
    (1038, 2, N'midsummer Hash in a hired village hall'),
    (1042, 2, N'gathering of four local clans, joint run'),
    (1049, 2, N'Christmas run, Santa lookalike award'),
    (1050, 2, N'New Year Hangover Hash'),
    (1071, 2, N'Halloween run: witches and skeletons'),
    (1076, 2, N'New Year hangover hash: garden party, outgoing JM'),
    (1081, 3, N'IOW weekend hosted by Worthy Winchester and IOW HHH'),
    (1088, 3, N'Travelled to the Deepcut Midsummer Hash'),
    (1090, 2, N'Camping weekend at Steyning, fancy dress pub crawl'),
    (1092, 2, N'Pirate Hash and BBQ'),
    (1093, 2, N'Joint run with Haslemere H4'),
    (1095, 2, N'Invade West London Away Weekend');
BEGIN TRANSACTION;
UPDATE e SET EventGeographicScope = f.Scope
FROM HC.Event e JOIN @f f ON f.EventNumber = e.EventNumber
WHERE e.KennelId = @kennelId AND e.deleted = 0 AND e.EventGeographicScope = 1;
DECLARE @n INT = @@ROWCOUNT;
INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp])
SELECT 'eventScopeFlag', CONCAT('Chichester run ', f.EventNumber, ' flagged scope ', f.Scope), CAST(e.id AS NVARCHAR(40)), f.Why, SYSDATETIMEOFFSET()
FROM @f f JOIN HC.Event e ON e.EventNumber = f.EventNumber AND e.KennelId = @kennelId AND e.deleted = 0;
IF @n <> 101 BEGIN ROLLBACK TRANSACTION; THROW 50000, 'unexpected row count: nothing changed', 1; END
COMMIT TRANSACTION;
SELECT @n AS flagged;
SELECT EventGeographicScope, COUNT(*) n FROM HC.Event WHERE KennelId = @kennelId AND deleted = 0 GROUP BY EventGeographicScope;
