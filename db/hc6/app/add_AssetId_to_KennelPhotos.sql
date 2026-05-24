-- Run-once migration: add AssetId column to HC.KennelPhotos.
-- AssetId holds the device-library identifier returned by photo_manager
-- (iOS PHAsset.localIdentifier, Android MediaStore URI). Nullable because
-- the column is only populated when the user has "save to camera roll" enabled
-- at capture time. Archive this file after running.
ALTER TABLE [HC].[KennelPhotos]
    ADD [AssetId] NVARCHAR(500) NULL;
