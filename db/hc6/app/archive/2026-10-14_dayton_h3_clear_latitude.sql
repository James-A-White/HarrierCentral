-- Run-once (2026-10-14): clear DH3's latitude 999 — HC5's "clear" sentinel the
-- portal kept sending, stored by HC6 as a real latitude. With Longitude NULL
-- the kennel had no position; NULL in both falls back to the city (Dayton).
-- The only kennel with an out-of-range coordinate (checked 2026-10-14).
SET NOCOUNT ON;
UPDATE HC.Kennel SET Latitude = NULL, Longitude = NULL
WHERE id = '332cc8ad-39e4-4151-b3d8-28eaa7717e1f' AND Latitude = 999;
SELECT @@ROWCOUNT AS rowsUpdated;
SELECT COUNT(*) AS kennelsOutOfRange FROM HC.Kennel WHERE ABS(Latitude) > 90 OR ABS(Longitude) > 180;
