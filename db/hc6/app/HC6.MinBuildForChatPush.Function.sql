CREATE OR ALTER FUNCTION [HC6].[MinBuildForChatPush] ()
RETURNS INT
AS
-- =====================================================================
-- Function: HC6.MinBuildForChatPush
-- Description: The lowest app build that may be sent a KENNEL or ROOM chat
--   push. Lower builds are excluded from the audience entirely.
--
--   WHY A GATE AT ALL: these two thread kinds are the first pushes that
--   carry no event. A build that predates the routing added in 3.0.44+1385
--   shows the notification but cannot act on a tap, because its handler
--   looks up a run by EventId and there is not one. Rather than send a
--   notification that goes nowhere, we do not send it (James, 2026-09-18:
--   "anyone with a build number lower than the current one will not get a
--   push notification because the app cannot handle it").
--
--   THIS IS THE ONLY PLACE THE NUMBER LIVES. Raise it when a future build
--   changes what a chat push may contain, and redeploy this one function —
--   both send SPs read it, so they cannot drift apart.
--
--   FAIL CLOSED: HC.Device.BuildNumber is NVARCHAR and holds '<unknown>'
--   on a real slice of devices, so callers compare with
--   TRY_CAST(device.BuildNumber AS INT) >= HC6.MinBuildForChatPush().
--   A build that will not parse yields NULL, the comparison is UNKNOWN,
--   and the device is left out. Not knowing what a device runs is not a
--   reason to push to it.
--
--   NOT APPLIED TO RUN CHAT. hcapp_sendEventMessage is deliberately
--   ungated: run chat routes on EventId and has worked on every build
--   ever shipped, and 353 of the live devices are still on 2.1.2 (build
--   1040), the App Store release. Gating it would silence the one chat
--   notification that currently works, for most of the user base.
--
-- Returns: INT — the minimum build number.
-- Author: Harrier Central
-- Created: 2026-09-18
-- HC5 Source: none (new)
-- =====================================================================
BEGIN
    RETURN 1385;
END
GO
