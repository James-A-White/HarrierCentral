-- =====================================================================
-- Function: HC6.SocialLinksProblem
-- Description: Checks a kennel's social-links JSON (E12.F4.S4, James
--   2026-10-10) and says what is wrong with it, or NULL when it is fine.
--   Shape: a JSON array, at most 20 entries, each
--     { "platform": one of the list below, "url": https link or null,
--       "handle": text or null, "qrImageUrl": https link or null,
--       "label": text or null, "audience": "public" | "members" }
--   A url must be https and its host must BELONG to its platform, so a
--   kennel page can never carry a disguised link ("Join our WhatsApp"
--   pointing somewhere else). WeChat has no group links: a handle and/or a
--   QR image instead. 'other' takes any https host and needs a label.
--   THE SAME platform → hosts list is in api/Endpoints/KennelFromWebsite.cs
--   (SocialLinks), portal/lib/util/social_links.dart,
--   mobile-app/lib/util/social_links.dart and public-web/lib/social-links.ts.
--   Change all five together.
-- Parameters: @json - the array (NULL or '' = no links, fine)
-- Returns: NVARCHAR(300) — the first problem, or NULL
-- Author: Harrier Central
-- Created: 2026-10-10
-- =====================================================================
CREATE OR ALTER FUNCTION [HC6].[SocialLinksProblem] (@json NVARCHAR(MAX))
RETURNS NVARCHAR(300)
AS
BEGIN
    IF (@json IS NULL OR LEN(@json) = 0) RETURN NULL;
    IF (ISJSON(@json) = 0 OR LEFT(LTRIM(@json), 1) <> '[') RETURN N'Social links must be a JSON array.';
    IF ((SELECT COUNT(*) FROM OPENJSON(@json)) > 20) RETURN N'At most 20 social links.';

    DECLARE @hosts TABLE (platform NVARCHAR(20), host NVARCHAR(60));
    INSERT @hosts VALUES
        (N'facebook', N'facebook.com'), (N'facebook', N'fb.com'), (N'facebook', N'fb.me'),
        (N'instagram', N'instagram.com'),
        (N'whatsapp', N'whatsapp.com'), (N'whatsapp', N'wa.me'),
        (N'signal', N'signal.group'), (N'signal', N'signal.me'),
        (N'telegram', N't.me'), (N'telegram', N'telegram.me'),
        (N'wechat', N'weixin.qq.com'), (N'wechat', N'wechat.com'),
        (N'line', N'line.me'), (N'line', N'lin.ee'),
        (N'kakaotalk', N'kakao.com'),
        (N'zalo', N'zalo.me'),
        (N'viber', N'viber.com'),
        (N'discord', N'discord.gg'), (N'discord', N'discord.com'),
        (N'strava', N'strava.com'), (N'strava', N'strava.app.link'),
        (N'meetup', N'meetup.com'),
        (N'x', N'x.com'), (N'x', N'twitter.com'),
        (N'tiktok', N'tiktok.com'),
        (N'youtube', N'youtube.com'), (N'youtube', N'youtu.be'),
        (N'threads', N'threads.net'), (N'threads', N'threads.com'),
        (N'bluesky', N'bsky.app'),
        (N'reddit', N'reddit.com'),
        (N'mailinglist', N'groups.google.com'), (N'mailinglist', N'groups.io'),
        (N'googlecalendar', N'calendar.google.com');   -- 2026-10-15: share runs via Google Calendar

    DECLARE @problem NVARCHAR(300);
    SELECT TOP 1 @problem = p.problem
    FROM (
        SELECT j.platform, j.url, j.handle, j.qrImageUrl, j.label, j.audience,
               -- the host: between "https://" and the next / ? # or :
               LOWER(LEFT(SUBSTRING(j.url, 9, 500),
                          PATINDEX(N'%[/?#:]%', SUBSTRING(j.url, 9, 500) + N'/') - 1)) AS host,
               CAST(o.[key] AS INT) AS n
        FROM OPENJSON(@json) o
        CROSS APPLY OPENJSON(o.value) WITH (
            platform   NVARCHAR(20)  '$.platform',
            url        NVARCHAR(600) '$.url',
            handle     NVARCHAR(200) '$.handle',
            qrImageUrl NVARCHAR(600) '$.qrImageUrl',
            label      NVARCHAR(100) '$.label',
            audience   NVARCHAR(20)  '$.audience') j
    ) l
    CROSS APPLY (SELECT CASE
        WHEN l.platform IS NULL
          OR (l.platform NOT IN (SELECT platform FROM @hosts) AND l.platform <> N'other')
            THEN N'Unknown platform "' + LEFT(ISNULL(l.platform, N''), 30) + N'".'
        WHEN ISNULL(l.audience, N'public') NOT IN (N'public', N'members')
            THEN N'Audience must be public or members.'
        WHEN l.url IS NULL AND l.platform <> N'wechat'
            THEN N'A ' + l.platform + N' link needs its address.'
        WHEN l.platform = N'wechat' AND l.url IS NULL AND l.handle IS NULL AND l.qrImageUrl IS NULL
            THEN N'WeChat needs an ID or a QR image.'
        WHEN l.url IS NOT NULL AND (l.url NOT LIKE N'https://%' OR LEN(l.url) > 500)
            THEN N'Links must start with https:// (' + LEFT(l.url, 60) + N').'
        WHEN l.qrImageUrl IS NOT NULL AND l.qrImageUrl NOT LIKE N'https://%'
            THEN N'The QR image must be an https link.'
        WHEN l.platform = N'other' AND LEN(ISNULL(l.label, N'')) = 0
            THEN N'An "other" link needs a label.'
        WHEN l.url IS NOT NULL AND l.platform <> N'other' AND NOT EXISTS (
                SELECT 1 FROM @hosts h
                WHERE h.platform = l.platform
                  AND (l.host = h.host OR RIGHT(l.host, LEN(h.host) + 1) = N'.' + h.host))
            THEN N'That ' + l.platform + N' link points to ' + LEFT(l.host, 60) + N', not ' + l.platform + N'.'
        ELSE NULL END AS problem) p
    WHERE p.problem IS NOT NULL
    ORDER BY l.n;
    RETURN @problem;
END
GO
