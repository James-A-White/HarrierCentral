CREATE OR ALTER FUNCTION [HC6].[IsAppointedHare]
(
    @userId  UNIQUEIDENTIFIER,
    @eventId UNIQUEIDENTIFIER
)
RETURNS SMALLINT
AS
-- =====================================================================
-- Function: HC6.IsAppointedHare
-- Description: 1 when @userId is an APPOINTED hare of @eventId — marked
--   hare by a run or kennel admin (HasherEventMap.HareAppointedBy set) —
--   else 0 (E8.F5.S6, James 2026-10-17). The ONE test every hare-rights
--   check uses (the @isHareOfEvent passed to HC6.CheckKennelPermission):
--   a hasher who marked themselves hare (IsHare = 1, HareAppointedBy NULL)
--   still has the run in their haring history but gets no hare rights.
--   A single-row lookup on the (UserId, EventId) row — fine as a scalar.
-- Parameters: @userId, @eventId (internal ids). NULL either way -> 0.
-- Returns: SMALLINT 1 / 0.
-- Author: Harrier Central
-- Created: 2026-10-17
-- =====================================================================
BEGIN
    IF (@userId IS NULL OR @eventId IS NULL) RETURN 0;
    RETURN CASE WHEN EXISTS (SELECT 1 FROM HC.HasherEventMap hem
                             WHERE hem.UserId = @userId AND hem.EventId = @eventId
                               AND hem.IsHare = 1 AND hem.removed = 0
                               AND hem.HareAppointedBy IS NOT NULL)
                THEN 1 ELSE 0 END;
END
