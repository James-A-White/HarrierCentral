-- Run-once (2026-10-03, James: "For the ones that are obvious please fix them").
-- Runs that carried ANOTHER kennel's start position (found by tools analysis:
-- position > 300 km from the kennel's own start area, and either the kennel's
-- calendar puts the run at home, or another kennel's run with the SAME run
-- number sits at that exact spot). Left alone: MHH3 #2220 (place text is in
-- Barbados), every same-date match (often real joint/travel runs) and the
-- whole-run copies (their names are wrong too: a kennel admin's job).
--   use calendar   -> UseFbLatLon = 1, wrong HC position cleared
--   clear position -> HC position cleared ("no location"), as the app's -2 does
-- EventGeolocation follows the position exactly as hcapp_addEditEvent sets it.
-- Each change logs the old position to LOG.GeneralLog (LogSource 'eventLocationFix').
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @n INT = 0;
-- A3H #2059 (2023-02-26): use calendar; was 37.08061, 127.05106
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = 'add2c9d8-855f-423d-a370-0fcab127e3d1' AND ROUND(Latitude, 5) = 37.08061 AND ROUND(Longitude, 5) = 127.05106 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', 'add2c9d8-855f-423d-a370-0fcab127e3d1', 'A3H #2059 was 37.08061,127.05106', SYSDATETIMEOFFSET()); END
-- CLH3 #2205 (2026-07-31): use calendar; was 57.18995, -2.25284
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = '24af98e1-4e4e-4653-9359-54cffbc3c0b8' AND ROUND(Latitude, 5) = 57.18995 AND ROUND(Longitude, 5) = -2.25284 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', '24af98e1-4e4e-4653-9359-54cffbc3c0b8', 'CLH3 #2205 was 57.18995,-2.25284', SYSDATETIMEOFFSET()); END
-- HanoiH3 #2200 (2025-08-09): clear position; was 57.14018, -2.17259
UPDATE HC.Event SET Latitude = NULL, Longitude = NULL, EventGeolocation = NULL
 WHERE id = 'e444ae99-3313-4f3f-abd5-def76a84c319' AND ROUND(Latitude, 5) = 57.14018 AND ROUND(Longitude, 5) = -2.17259 AND UseFbLatLon = 0;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'clear position: another kennel''s position removed', 'e444ae99-3313-4f3f-abd5-def76a84c319', 'HanoiH3 #2200 was 57.14018,-2.17259', SYSDATETIMEOFFSET()); END
-- HanoiH3-VN #2200 (2025-07-26): clear position; was 57.14019, -2.17259
UPDATE HC.Event SET Latitude = NULL, Longitude = NULL, EventGeolocation = NULL
 WHERE id = '553d2b11-4a52-42b8-813d-6f9dcc25e5fa' AND ROUND(Latitude, 5) = 57.14019 AND ROUND(Longitude, 5) = -2.17259 AND UseFbLatLon = 0;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'clear position: another kennel''s position removed', '553d2b11-4a52-42b8-813d-6f9dcc25e5fa', 'HanoiH3-VN #2200 was 57.14019,-2.17259', SYSDATETIMEOFFSET()); END
-- NCH3 #2059 (2023-07-01): use calendar; was 37.0858, 127.05227
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = '3e903374-e95b-4e12-9ff6-e58b8813273e' AND ROUND(Latitude, 5) = 37.0858 AND ROUND(Longitude, 5) = 127.05227 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', '3e903374-e95b-4e12-9ff6-e58b8813273e', 'NCH3 #2059 was 37.0858,127.05227', SYSDATETIMEOFFSET()); END
-- NPH3 #162 (2024-07-06): use calendar; was 50.59409, -3.45158
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = 'ce4fe47e-31a7-4f7d-98b9-827fe8e4a338' AND ROUND(Latitude, 5) = 50.59409 AND ROUND(Longitude, 5) = -3.45158 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', 'ce4fe47e-31a7-4f7d-98b9-827fe8e4a338', 'NPH3 #162 was 50.59409,-3.45158', SYSDATETIMEOFFSET()); END
-- OH3 #13 (2024-02-16): clear position; was 24.25417, 120.7226
UPDATE HC.Event SET Latitude = NULL, Longitude = NULL, EventGeolocation = NULL
 WHERE id = 'f3e67fea-54c8-4bdc-b530-171e6ec0acf5' AND ROUND(Latitude, 5) = 24.25417 AND ROUND(Longitude, 5) = 120.7226 AND UseFbLatLon = 0;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'clear position: another kennel''s position removed', 'f3e67fea-54c8-4bdc-b530-171e6ec0acf5', 'OH3 #13 was 24.25417,120.7226', SYSDATETIMEOFFSET()); END
-- BFMH3 #137 (2025-05-12): use calendar; was 50.11414, 8.42394
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = '04ec8946-a07b-4aa7-81e7-626a2db1f440' AND ROUND(Latitude, 5) = 50.11414 AND ROUND(Longitude, 5) = 8.42394 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', '04ec8946-a07b-4aa7-81e7-626a2db1f440', 'BFMH3 #137 was 50.11414,8.42394', SYSDATETIMEOFFSET()); END
-- BH3-DE #2024 (2024-10-31): use calendar; was 37.23818, -8.17271
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = '53b813c5-31ac-4c6b-ba66-c0d1a06bcc81' AND ROUND(Latitude, 5) = 37.23818 AND ROUND(Longitude, 5) = -8.17271 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', '53b813c5-31ac-4c6b-ba66-c0d1a06bcc81', 'BH3-DE #2024 was 37.23818,-8.17271', SYSDATETIMEOFFSET()); END
-- BH3-DE #2265 (2025-01-05): use calendar; was 37.12892, -7.64796
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = 'ca7b83cc-5585-4ff7-8013-fe08f0afa4f4' AND ROUND(Latitude, 5) = 37.12892 AND ROUND(Longitude, 5) = -7.64796 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', 'ca7b83cc-5585-4ff7-8013-fe08f0afa4f4', 'BH3-DE #2265 was 37.12892,-7.64796', SYSDATETIMEOFFSET()); END
-- Humpin #1736 (2024-07-21): use calendar; was 13.17144, -59.5791
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = 'e2ec68fc-20f3-4807-bbdd-3e8ebed35723' AND ROUND(Latitude, 5) = 13.17144 AND ROUND(Longitude, 5) = -59.5791 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', 'e2ec68fc-20f3-4807-bbdd-3e8ebed35723', 'Humpin #1736 was 13.17144,-59.5791', SYSDATETIMEOFFSET()); END
-- LJH3 #57 (2025-04-21): use calendar; was 8.48657, -13.26186
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = '9817c7cd-8b0c-4d37-92a7-a16abf38c0f9' AND ROUND(Latitude, 5) = 8.48657 AND ROUND(Longitude, 5) = -13.26186 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', '9817c7cd-8b0c-4d37-92a7-a16abf38c0f9', 'LJH3 #57 was 8.48657,-13.26186', SYSDATETIMEOFFSET()); END
-- LJH3 #22 (2025-08-25): use calendar; was 45.64558, 4.81317
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = '27bed3e7-6896-405f-b2df-90c06ae654a4' AND ROUND(Latitude, 5) = 45.64558 AND ROUND(Longitude, 5) = 4.81317 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', '27bed3e7-6896-405f-b2df-90c06ae654a4', 'LJH3 #22 was 45.64558,4.81317', SYSDATETIMEOFFSET()); END
-- NCH3 #2112 (2024-07-06): use calendar; was 35.72773, 139.71441
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = '5fa1d222-b7e3-4f0b-a8be-8e64e92d6aa0' AND ROUND(Latitude, 5) = 35.72773 AND ROUND(Longitude, 5) = 139.71441 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', '5fa1d222-b7e3-4f0b-a8be-8e64e92d6aa0', 'NCH3 #2112 was 35.72773,139.71441', SYSDATETIMEOFFSET()); END
-- NCH3 #2129 (2024-11-02): use calendar; was 13.12814, -59.50339
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = 'a79b397d-23b1-477a-b7a1-27bdd37c20d8' AND ROUND(Latitude, 5) = 13.12814 AND ROUND(Longitude, 5) = -59.50339 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', 'a79b397d-23b1-477a-b7a1-27bdd37c20d8', 'NCH3 #2129 was 13.12814,-59.50339', SYSDATETIMEOFFSET()); END
-- NCH3 #2131 (2024-11-16): use calendar; was 50.09225, 8.23929
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = 'bb500452-591c-4c2a-a989-b98f958e3a00' AND ROUND(Latitude, 5) = 50.09225 AND ROUND(Longitude, 5) = 8.23929 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', 'bb500452-591c-4c2a-a989-b98f958e3a00', 'NCH3 #2131 was 50.09225,8.23929', SYSDATETIMEOFFSET()); END
-- NH3 #2394 (2022-04-13): use calendar; was -35.00948, 138.63624
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = 'ce442e3c-f6f7-4d57-9fd9-1270ac8f78b9' AND ROUND(Latitude, 5) = -35.00948 AND ROUND(Longitude, 5) = 138.63624 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', 'ce442e3c-f6f7-4d57-9fd9-1270ac8f78b9', 'NH3 #2394 was -35.00948,138.63624', SYSDATETIMEOFFSET()); END
-- SDH3 #2258 (2025-05-04): use calendar; was 35.78973, 139.27128
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = '5f1b62e2-7066-41fb-97c7-405a2ec13500' AND ROUND(Latitude, 5) = 35.78973 AND ROUND(Longitude, 5) = 139.27128 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', '5f1b62e2-7066-41fb-97c7-405a2ec13500', 'SDH3 #2258 was 35.78973,139.27128', SYSDATETIMEOFFSET()); END
-- SDH3 #532 (2025-09-26): use calendar; was 52.3858, 10.75043
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = 'f74b0a0a-403d-417a-b402-2b5e69273a8b' AND ROUND(Latitude, 5) = 52.3858 AND ROUND(Longitude, 5) = 10.75043 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', 'f74b0a0a-403d-417a-b402-2b5e69273a8b', 'SDH3 #532 was 52.3858,10.75043', SYSDATETIMEOFFSET()); END
-- SWH3 #1619 (2023-01-28): use calendar; was 41.75556, -72.66368
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = '4385eb0b-f5b3-4d47-bfb9-65b45982c42b' AND ROUND(Latitude, 5) = 41.75556 AND ROUND(Longitude, 5) = -72.66368 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', '4385eb0b-f5b3-4d47-bfb9-65b45982c42b', 'SWH3 #1619 was 41.75556,-72.66368', SYSDATETIMEOFFSET()); END
-- SWH3 #1652 (2023-09-09): use calendar; was 19.34345, -99.15169
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = '3fccb7ac-fbe6-4a19-a7d4-adcca208321f' AND ROUND(Latitude, 5) = 19.34345 AND ROUND(Longitude, 5) = -99.15169 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', '3fccb7ac-fbe6-4a19-a7d4-adcca208321f', 'SWH3 #1652 was 19.34345,-99.15169', SYSDATETIMEOFFSET()); END
-- TNTH3 #1966 (2023-03-08): use calendar; was 52.34371, 4.85028
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = '850c8be6-817a-4d21-9d72-212066d222cc' AND ROUND(Latitude, 5) = 52.34371 AND ROUND(Longitude, 5) = 4.85028 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', '850c8be6-817a-4d21-9d72-212066d222cc', 'TNTH3 #1966 was 52.34371,4.85028', SYSDATETIMEOFFSET()); END
-- TwH3 #2514 (2023-08-13): use calendar; was 37.20685, 127.03329
UPDATE HC.Event SET UseFbLatLon = 1, Latitude = NULL, Longitude = NULL, EventGeolocation = CASE WHEN FbLatitude IS NOT NULL THEN geography::Point(FbLatitude, FbLongitude, 4326) END
 WHERE id = '91ec0a63-ef27-4d48-b7f1-6cec2eb2f2ce' AND ROUND(Latitude, 5) = 37.20685 AND ROUND(Longitude, 5) = 127.03329 AND FbLatitude IS NOT NULL;
IF @@ROWCOUNT = 1 BEGIN SET @n += 1;
  INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp]) VALUES ('eventLocationFix', 'use calendar: another kennel''s position removed', '91ec0a63-ef27-4d48-b7f1-6cec2eb2f2ce', 'TwH3 #2514 was 37.20685,127.03329', SYSDATETIMEOFFSET()); END
IF @n <> 23 BEGIN ROLLBACK TRANSACTION; THROW 50000, 'expected 23 rows: nothing changed', 1; END
COMMIT TRANSACTION;
SELECT @n AS fixed;
