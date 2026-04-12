-- =====================================================================
-- Run-once migration: remove LogoUrl and FaviconUrl from HC.KennelWebsite
--
-- Reason: these columns duplicated HC.Kennel.KennelLogo and
--         HC.Kennel.KennelFavicon. All SPs now read directly from
--         HC.Kennel so the website row is no longer a source of truth
--         for logo/favicon URLs.
--
-- BEFORE RUNNING: verify that no kennel has a diverged value in
--   KennelWebsite.LogoUrl vs HC.Kennel.KennelLogo. Run this check:
--
--   SELECT kw.KennelId, k.KennelLogo, kw.LogoUrl
--   FROM HC.KennelWebsite kw
--   JOIN HC.Kennel k ON k.id = kw.KennelId
--   WHERE kw.LogoUrl IS NOT NULL
--     AND kw.LogoUrl <> k.KennelLogo;
--
-- If any rows are returned, reconcile before dropping the column.
--
-- Archive this script after running (move to archive/ subdirectory).
-- =====================================================================

ALTER TABLE [HC].[KennelWebsite] DROP COLUMN [LogoUrl];
ALTER TABLE [HC].[KennelWebsite] DROP COLUMN [FaviconUrl];
