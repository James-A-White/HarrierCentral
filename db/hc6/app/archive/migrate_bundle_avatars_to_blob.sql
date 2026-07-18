-- =====================================================================
-- RUN-ONCE MIGRATION — bundle://avatar-* → Azure Blob URL
-- Ran: 2026-07-18
--
-- Converts legacy HC.Hasher.Photo values of the form `bundle://avatar-N`
-- (and `bundle://avatar-null`) to the mirrored public blob URL, so BOTH the
-- app and the public web can render them as ordinary http images. The images
-- were uploaded to the `profile-photos` container (public blob access).
--
-- Scope: all bundle://avatar-* values are numeric (avatar-0..50) or avatar-null,
-- all mapping to a `.jpg`. No avatar-virgin/avatar-visitor (.png) are stored.
--
-- NOTE: HC.Hasher has an updatedAt trigger, so this UPDATE bumps updatedAt on
-- every affected row and those hashers re-replicate to all mobile clients. That
-- is INTENDED here — clients must receive the new Photo value. (This is the
-- opposite of the ALTER TABLE ADD COLUMN case, where the bump is suppressed.)
--
-- Run-once: archive after execution (do not leave alongside deployable SPs).
-- =====================================================================
SET NOCOUNT ON;

UPDATE HC.Hasher
SET Photo = 'https://harriercentral.blob.core.windows.net/profile-photos/'
          + LOWER(SUBSTRING(Photo, 10, 200)) + '.jpg'
WHERE Photo LIKE 'bundle://avatar-%';

SELECT @@ROWCOUNT AS RowsMigrated;
