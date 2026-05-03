-- =====================================================================
-- Run-once migration: add HC6 style token columns to HC.KennelWebsite
--
-- TextMutedColor     — label / secondary text colour (#RRGGBBAA)
-- CardBackgroundColor — card / panel surface colour (#RRGGBBAA)
--
-- BodyTextColor and TitleTextColor already exist (HC5 legacy columns).
-- This migration activates them as first-class HC6 style tokens with
-- no schema change — they are simply used from here on.
-- =====================================================================

ALTER TABLE [HC].[KennelWebsite]
    ADD [TextMutedColor]      NVARCHAR(9) NULL,
        [CardBackgroundColor] NVARCHAR(9) NULL;
GO
