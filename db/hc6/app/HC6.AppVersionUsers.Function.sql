CREATE OR ALTER FUNCTION [HC6].[AppVersionUsers]
(
    @days INT
)
RETURNS TABLE
AS
-- =====================================================================
-- Function: HC6.AppVersionUsers
-- Description: Which app build each recently active person is on NOW
--   (E19.F3.S3, the version email). A person counts once, under the
--   HIGHEST build among their phones that signed in within @days — so
--   someone with an old 2.x phone in a drawer and a 3.x phone in use is
--   on 3.x and is never told to update. The ONE rule the version list,
--   the recipient list and the send queue all read.
--   Phones only: iOS / iPadOS devices are iPhone, a device with no
--   systemName is Android (the Android payload has none); browser
--   devices (chrome, safari …, incl. the portal) are left out, as are
--   builds that are not a number ('<unknown>').
-- Parameters:
--   @days - last sign-in within this many days
-- Returns: { userId, build, version, isIos, isAndroid, lastLogin } —
--   one row per person; isIos / isAndroid say which kinds of phone they
--   use AT that build (both 1 for someone on both).
-- Author: Harrier Central
-- Created: 2026-10-17
-- =====================================================================
RETURN
    WITH d AS (
        SELECT d.UserId,
               TRY_CAST(d.BuildNumber AS INT) AS build,
               d.Version,
               CASE WHEN d.OperatingSystem IN ('iOS', 'iPadOS') THEN 1 ELSE 0 END AS isIos,
               CASE WHEN d.OperatingSystem IS NULL THEN 1 ELSE 0 END             AS isAndroid,
               d.LastLogin
        FROM HC.Device d
        WHERE d.IsMobile = 1
          AND d.removed = 0
          AND d.UserId IS NOT NULL
          AND d.LastLogin >= DATEADD(DAY, -@days, SYSDATETIMEOFFSET())
          AND (d.OperatingSystem IS NULL OR d.OperatingSystem IN ('iOS', 'iPadOS'))
          AND TRY_CAST(d.BuildNumber AS INT) IS NOT NULL
    ),
    top1 AS (
        SELECT d.*, MAX(d.build) OVER (PARTITION BY d.UserId) AS maxBuild
        FROM d
    )
    SELECT t.UserId           AS userId,
           t.build            AS build,
           MAX(t.Version)     AS version,
           MAX(t.isIos)       AS isIos,
           MAX(t.isAndroid)   AS isAndroid,
           MAX(t.LastLogin)   AS lastLogin
    FROM top1 t
    WHERE t.build = t.maxBuild
    GROUP BY t.UserId, t.build;
