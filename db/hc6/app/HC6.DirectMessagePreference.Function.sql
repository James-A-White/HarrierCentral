CREATE OR ALTER FUNCTION [HC6].[DirectMessagePreference] (@preferences INT)
RETURNS SMALLINT
AS
-- =====================================================================
-- Function: HC6.DirectMessagePreference
-- Description: Who may message this hasher, from HC.Hasher.Preferences
--   bits 0x4000|0x8000 (E9.F1.S18): 0 friends only (the default — every row
--   is 0 today), 1 anyone, 2 nobody. 3 is unused and reads as nobody.
--   Row-at-a-time only: called on the ONE target of a start, never in a
--   WHERE over a big table.
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
BEGIN
    RETURN CASE ((COALESCE(@preferences, 0) / 16384) & 3) WHEN 1 THEN 1 WHEN 0 THEN 0 ELSE 2 END;
END
GO
