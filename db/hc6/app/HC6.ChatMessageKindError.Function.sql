CREATE OR ALTER FUNCTION [HC6].[ChatMessageKindError]
(
    @kind    SMALLINT,
    @content NVARCHAR(MAX)
)
RETURNS NVARCHAR(200)
AS
-- =====================================================================
-- Function: HC6.ChatMessageKindError
-- Description: Is this chat message's content right for its kind?
--   NULL = valid; otherwise a user-facing reason. Every send SP calls it,
--   so the rule lives once (E9.F1.S11/S12, 2026-09-29).
--
--   Kind 0 text      anything (the send SPs already check blank / length)
--   Kind 1 photo     a JPEG in OUR chat-photos container, nothing after it —
--                    a client cannot post an arbitrary URL as a "photo"
--   Kind 2 location  https://www.google.com/maps/search/?api=1&query=<lat>,<lng>
--                    with lat in [-90, 90] and lng in [-180, 180]
--
--   The content is a URL on purpose: a build that predates MessageKind
--   shows it as a link rather than an empty bubble.
--   See docs/chat_photos_location_delete_plan.md.
-- Author: Harrier Central
-- Created: 2026-09-29
-- =====================================================================
BEGIN
    IF (@kind IS NULL OR @kind = 0) RETURN NULL;

    IF (@kind = 1)
    BEGIN
        DECLARE @photoPrefix NVARCHAR(100) = N'https://harriercentral.blob.core.windows.net/chat-photos/';
        IF (LEN(@content) <= 500
            AND LEFT(@content, LEN(@photoPrefix)) = @photoPrefix
            AND RIGHT(@content, 4) = N'.jpg'
            AND CHARINDEX(N' ', @content) = 0
            AND CHARINDEX(N'?', @content) = 0
            AND CHARINDEX(N'#', @content) = 0
            AND CHARINDEX(N'..', @content) = 0)
            RETURN NULL;
        RETURN N'That photo could not be sent. Please try again.';
    END

    IF (@kind = 2)
    BEGIN
        DECLARE @mapPrefix NVARCHAR(100) = N'https://www.google.com/maps/search/?api=1&query=';
        IF (LEN(@content) > 100 OR LEFT(@content, LEN(@mapPrefix)) <> @mapPrefix)
            RETURN N'That location could not be sent. Please try again.';

        DECLARE @coords NVARCHAR(100) = SUBSTRING(@content, LEN(@mapPrefix) + 1, 100);
        DECLARE @comma  INT = CHARINDEX(N',', @coords);
        IF (@comma = 0) RETURN N'That location could not be sent. Please try again.';

        DECLARE @lat DECIMAL(9, 6) = TRY_CAST(LEFT(@coords, @comma - 1) AS DECIMAL(9, 6));
        DECLARE @lng DECIMAL(9, 6) = TRY_CAST(SUBSTRING(@coords, @comma + 1, 100) AS DECIMAL(9, 6));
        IF (@lat BETWEEN -90 AND 90 AND @lng BETWEEN -180 AND 180) RETURN NULL;
        RETURN N'That location could not be sent. Please try again.';
    END

    RETURN N'That kind of message is not supported.';
END
GO
