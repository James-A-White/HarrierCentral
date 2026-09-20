CREATE OR ALTER FUNCTION [HC6].[DevicePlatformName] (@deviceData NVARCHAR(MAX))
RETURNS NVARCHAR(30)
AS
-- =====================================================================
-- Function: HC6.DevicePlatformName
-- Description: The human name of the platform an HC.Device row runs on,
--   read from the user-agent inside its DeviceData JSON (E9.F7.S18).
--   Used to label a passkey on the settings screen: a hasher recognises
--   "Safari on iPhone", not a credential id.
--
--   Deliberately coarse. The point is recognition, not telemetry, and a
--   user agent is a poor source for anything finer. Order matters: iPad
--   and iPhone both say "like Mac OS X", so Macintosh is tested last.
-- Author: Harrier Central
-- Created: 2026-09-20
-- =====================================================================
BEGIN
    DECLARE @ua NVARCHAR(MAX) = LOWER(COALESCE(JSON_VALUE(@deviceData, '$.userAgent'), ''));

    RETURN CASE
        WHEN @ua = ''                          THEN 'this device'
        WHEN CHARINDEX('iphone',    @ua) > 0   THEN 'iPhone'
        WHEN CHARINDEX('ipad',      @ua) > 0   THEN 'iPad'
        WHEN CHARINDEX('android',   @ua) > 0   THEN 'Android'
        WHEN CHARINDEX('windows',   @ua) > 0   THEN 'Windows'
        WHEN CHARINDEX('cros',      @ua) > 0   THEN 'ChromeOS'
        WHEN CHARINDEX('linux',     @ua) > 0   THEN 'Linux'
        WHEN CHARINDEX('macintosh', @ua) > 0
          OR CHARINDEX('mac os',    @ua) > 0   THEN 'Mac'
        ELSE 'this device'
    END;
END
