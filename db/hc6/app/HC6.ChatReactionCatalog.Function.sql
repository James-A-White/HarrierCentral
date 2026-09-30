CREATE OR ALTER FUNCTION [HC6].[ChatReactionCatalog] ()
RETURNS TABLE
AS
-- =====================================================================
-- Function: HC6.ChatReactionCatalog
-- Description: THE list of emoji a chat message can be reacted to with
--   (E9.F1.S22, James 2026-09-30: "the fixed six for now, we might add
--   more later"). A reaction is STORED by its Code — in this database's
--   collation an emoji compares equal to '', so the glyph can never be a
--   key — and DRAWN by the clients, which hold the same six. Adding a
--   seventh is a row here AND a glyph in each client; a client that does
--   not know a code shows nothing for it rather than a hole.
--   Codes are plain ASCII words so `= @reaction` is a safe comparison.
-- Returns: one row per reaction, in display order.
-- Author: Harrier Central
-- Created: 2026-09-30
-- =====================================================================
RETURN
    SELECT c.Code, c.Emoji, c.SortOrder
    FROM (VALUES
        ('thumbs', N'👍', 10),
        ('heart',  N'❤️', 20),
        ('laugh',  N'😂', 30),
        ('beer',   N'🍺', 40),
        ('run',    N'🏃', 50),
        ('fire',   N'🔥', 60)
    ) AS c (Code, Emoji, SortOrder);
GO
