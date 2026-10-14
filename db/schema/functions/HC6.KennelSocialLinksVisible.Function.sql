-- =====================================================================
-- Function: HC6.KennelSocialLinksVisible
-- Description: The part of a kennel's social-links JSON (E12.F4.S4) a
--   viewer may see. Entries with "audience":"members" are chat-group invite
--   links — what spammers harvest — so they go only to the kennel's members
--   and admins; everything else is public. ONE copy of this rule, used by
--   every reader (James, 2026-10-14):
--     publicWeb_getLandingPageData  — @includeMembers = 0 (a public page)
--     hcapp_getKennelSocialLinks    — the app and the signed-in web; the SP
--                                     decides @includeMembers per caller
--   An entry with no audience takes its platform's default, as the portal's
--   SocialLink does: chat groups (whatsapp, signal, telegram, wechat, line,
--   kakaotalk, zalo, viber, discord) are members-only, the rest public. The
--   safe side: a missing flag never exposes an invite link.
-- Parameters: @json           - HC.Kennel.SocialLinksJson (NULL / '' = none)
--             @includeMembers - 1 = also the members-only entries
-- Returns: NVARCHAR(MAX) — a JSON array in the stored order, or NULL when
--   nothing is visible. Each entry is passed through unchanged.
-- Author: Harrier Central
-- Created: 2026-10-14
-- =====================================================================
CREATE OR ALTER FUNCTION [HC6].[KennelSocialLinksVisible] (@json NVARCHAR(MAX), @includeMembers SMALLINT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
    IF (@json IS NULL OR LEN(@json) = 0 OR ISJSON(@json) = 0) RETURN NULL;
    IF (@includeMembers = 1) RETURN @json;

    DECLARE @out NVARCHAR(MAX);
    SELECT @out = N'[' + STRING_AGG(CAST(o.value AS NVARCHAR(MAX)), N',')
                         WITHIN GROUP (ORDER BY CAST(o.[key] AS INT)) + N']'
    FROM OPENJSON(@json) o
    WHERE o.type = 5   -- objects only
      AND COALESCE(JSON_VALUE(o.value, '$.audience'),
                   CASE WHEN JSON_VALUE(o.value, '$.platform') IN
                             (N'whatsapp', N'signal', N'telegram', N'wechat', N'line',
                              N'kakaotalk', N'zalo', N'viber', N'discord')
                        THEN N'members' ELSE N'public' END) <> N'members';
    RETURN @out;   -- NULL when no entry survives (STRING_AGG over no rows)
END
GO
