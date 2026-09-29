CREATE OR ALTER FUNCTION [HC6].[MinBuildForDmPush] ()
RETURNS INT
AS
-- =====================================================================
-- Function: HC6.MinBuildForDmPush
-- Description: The lowest app build that can act on a DIRECT MESSAGE push
--   (ThreadKind 'dm', routed on ThreadId). Lower builds are left out of the
--   audience entirely, as HC6.MinBuildForChatPush does for kennel and room
--   pushes and for the same reason: a notification the app cannot open is
--   worse than none. Set to the build that ships DMs (E9.F1.S7).
--   Fail closed: callers compare TRY_CAST(device.BuildNumber AS INT) >= this.
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
BEGIN
    RETURN 1423;
END
GO
