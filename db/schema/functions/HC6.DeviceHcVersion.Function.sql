-- =====================================================================
-- Function: HC6.DeviceHcVersion
-- Description: The app version a device is running, as 'X.Y.Z+build'
--   (e.g. '3.0.12+1327'), for stamping HC.ErrorLog.HcVersion at the
--   moment an error is written. HC.Device.Version/BuildNumber are set
--   by hcapp_approveLogin on every boot, so at error time they describe
--   the build that made the failing call. Portal devices report the
--   portal version (e.g. '2.0.67+702'). Returns '<unknown device>' when
--   the device row does not exist (first-contact auth failures).
-- Parameters: @deviceId - HC.Device.id
-- Returns: NVARCHAR(60)
-- Author: Harrier Central
-- Created: 2026-09-09
-- =====================================================================
CREATE OR ALTER FUNCTION [HC6].[DeviceHcVersion] (@deviceId UNIQUEIDENTIFIER)
RETURNS NVARCHAR(60)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @v NVARCHAR(60);
    SELECT @v = d.Version + '+' + d.BuildNumber
    FROM HC.Device d
    WHERE d.id = @deviceId;
    RETURN COALESCE(@v, '<unknown device>');
END
GO
