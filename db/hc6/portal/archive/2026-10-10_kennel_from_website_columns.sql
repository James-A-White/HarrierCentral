-- =====================================================================
-- Run-once (2026-10-10, E12.F1.S10 / E12.F4.S4): storage for a kennel
-- request read from the club's website, and the kennel's social links.
--   EXT.OfficeForms_KennelImport (not synced; its one trigger fires only
--   on UPDATE of KennelFacebookId):
--     LogoUrl          the chosen logo, already copied to our blob storage
--     FoundedOn        'yyyy' | 'yyyy-mm' | 'yyyy-mm-dd' as the site gives it
--     RunDayOfWeek     1 Monday … 7 Sunday (as HC.Kennel.DefaultRunDayOfWeek)
--     RunStartTime     the usual start time
--     RunsPageUrl      the page that lists the club's runs (E3.F6.S3)
--     SocialLinksJson  the links array (E12.F4.S4 shape)
--     SourceJson       where each field came from, for the reviewer
--     RequestSource    'website' when made by New kennel from a website
--   HC.Kennel (synced — every trigger disabled around the ALTER, per the
--   synced-table rule, so no row's updatedAt moves):
--     SocialLinksJson  E12.F4.S4
-- Idempotent. Archived after it ran.
-- =====================================================================
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'LogoUrl') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD LogoUrl NVARCHAR(1000) NULL;
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'FoundedOn') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD FoundedOn NVARCHAR(10) NULL;
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'RunDayOfWeek') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD RunDayOfWeek SMALLINT NULL;
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'RunStartTime') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD RunStartTime TIME(0) NULL;
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'RunsPageUrl') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD RunsPageUrl NVARCHAR(1000) NULL;
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'SocialLinksJson') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD SocialLinksJson NVARCHAR(MAX) NULL;
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'SourceJson') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD SourceJson NVARCHAR(MAX) NULL;
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'RequestSource') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD RequestSource NVARCHAR(20) NULL;

IF COL_LENGTH('HC.Kennel', 'SocialLinksJson') IS NULL
BEGIN
    DISABLE TRIGGER ALL ON HC.Kennel;
    ALTER TABLE HC.Kennel ADD SocialLinksJson NVARCHAR(MAX) NULL;
    ENABLE TRIGGER ALL ON HC.Kennel;
END

COMMIT TRANSACTION;

SELECT COL_LENGTH('EXT.OfficeForms_KennelImport', 'RequestSource') AS requestSourceAdded,
       COL_LENGTH('HC.Kennel', 'SocialLinksJson')                  AS kennelSocialAdded,
       (SELECT COUNT(*) FROM sys.triggers WHERE parent_id = OBJECT_ID('HC.Kennel') AND is_disabled = 1) AS kennelTriggersDisabled;
