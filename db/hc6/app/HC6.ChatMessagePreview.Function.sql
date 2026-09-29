CREATE OR ALTER FUNCTION [HC6].[ChatMessagePreview]
(
    @kind    SMALLINT,
    @content NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
-- =====================================================================
-- Function: HC6.ChatMessagePreview
-- Description: What a chat message SAYS in one line — the push body and
--   HC.PushLog's summary. A photo or a location is stored as a URL
--   (HC6.ChatMessageKindError), and a push reading "https://harriercentral
--   .blob.core..." tells nobody anything. Row-at-a-time, never a filter.
--   (E9.F1.S11/S12, 2026-09-29.)
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
BEGIN
    RETURN CASE @kind
        WHEN 1 THEN N'📷 Photo'
        WHEN 2 THEN N'📍 Location'
        ELSE @content
    END;
END
GO
