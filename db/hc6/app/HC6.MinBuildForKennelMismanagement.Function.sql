CREATE OR ALTER FUNCTION [HC6].[MinBuildForKennelMismanagement] ()
RETURNS INT
AS
-- =====================================================================
-- Function: HC6.MinBuildForKennelMismanagement
-- Description: The lowest app build that knows a kennel has a second,
--   private Mismanagement thread (E9.F1.S33, 2026-10-16). Below it the app
--   identifies a kennel thread by the kennel alone, so a Mismanagement row
--   in the chat list would show as a second copy of the general chat and
--   open it, and a Mismanagement push would open the general chat. Lower
--   builds are therefore sent neither the list row nor the push.
--   Fail closed: callers compare TRY_CAST(device.BuildNumber AS INT) >= this.
--   The portal and the web are not builds and are not gated by this.
-- Author: Harrier Central
-- Created: 2026-10-16
-- =====================================================================
BEGIN
    RETURN 1481;
END
GO
