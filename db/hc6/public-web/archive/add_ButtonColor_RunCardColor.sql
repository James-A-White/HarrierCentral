-- =====================================================================
-- Migration: Add button and run-card colour columns to HC.KennelWebsite
-- Run once — move to archive/ after executing
-- =====================================================================

ALTER TABLE [HC].[KennelWebsite]
    ADD [ButtonPrimaryColor]   NVARCHAR(9) NULL,
        [ButtonCancelColor]    NVARCHAR(9) NULL,
        [ButtonSecondaryColor] NVARCHAR(9) NULL,
        [RunCardColor]         NVARCHAR(9) NULL;
GO
