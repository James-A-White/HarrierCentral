-- =====================================================================
-- Run-once: HC.KennelPhotos gains TakenAtUtc
--
-- When a photo was TAKEN, as distinct from CreatedAt (when it was uploaded).
-- The two are the same for a photo shot in the app and can be days apart for
-- one imported from the camera roll.
--
-- Why it is needed: a photo's position already lives on this table
-- (Latitude/Longitude, both NOT NULL), but its time exists ONLY as the
-- timestamp of the PHO:: point written into the importer's GPS track. That is
-- what forces a photo to be carried on somebody's track at all, and it is why
-- an imported shot wears the importer's identity, inherits their lane
-- visibility, and surfaces in replay at their moment rather than its own.
-- With a time here, both clients can place a photo from this table alone and
-- stop reading it off a track point.
--
-- Safe to ALTER without the trigger dance: HC.KennelPhotos carries no triggers
-- (verified: sys.triggers has 0 rows for it) and is not a synced table, so
-- nothing re-stamps updatedAt and no client is forced into a re-sync.
--
-- Nullable with no backfill on purpose: for every existing row the true
-- capture time is unknown, and inventing one (CreatedAt) would silently claim
-- a photo was taken at upload time. NULL means "we do not know", and callers
-- fall back to the track point exactly as they do today.
--
-- Author: Harrier Central
-- Created: 2026-09-07
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('HC.KennelPhotos') AND name = 'TakenAtUtc'
)
BEGIN
    ALTER TABLE HC.KennelPhotos ADD TakenAtUtc DATETIME2 NULL;
    PRINT 'HC.KennelPhotos.TakenAtUtc added.';
END
ELSE
BEGIN
    PRINT 'HC.KennelPhotos.TakenAtUtc already present — nothing to do.';
END
