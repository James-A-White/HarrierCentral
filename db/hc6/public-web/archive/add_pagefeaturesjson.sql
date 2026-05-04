-- Add PageFeaturesJson column to HC.KennelWebsite
-- Run once; archive after execution.
ALTER TABLE HC.KennelWebsite
ADD PageFeaturesJson NVARCHAR(4000) NULL;
