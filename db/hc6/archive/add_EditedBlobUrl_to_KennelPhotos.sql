-- Migration: Add EditedBlobUrl to HC.KennelPhotos
-- Run once. Move to archive/ after execution.
--
-- Purpose: Stores the Hash Flash's edited (cropped) version of a photo
-- separately from the original. BlobUrl is never modified.
-- Display logic everywhere: EditedBlobUrl ?? BlobUrl.
-- Re-edits always start from the original BlobUrl.
--
-- HC.KennelPhotos has no UpdatedAt trigger and is not a mobile-synced table,
-- so this ALTER can be run directly with no trigger disable required.

ALTER TABLE [HC].[KennelPhotos]
    ADD [EditedBlobUrl] NVARCHAR(500) NULL;
