-- =====================================================================
-- Run-once: the three terms answers on EXT.OfficeForms_KennelImport
-- (E12.F1.S7, 2026-09-28). The old harriercentral.com form asked three
-- required opt-in questions (tc_1..tc_3) but EXT.ImportNewKennel never
-- stored the answers; the hashruns.org form asks them again and keeps them
-- so a reviewer can read them. Not synced to phones — no trigger concern.
-- Must run BEFORE publicWeb_submitKennelRequest / hcportal_getKennelRequests
-- are deployed (CREATE binds existing-table columns). Idempotent.
-- Lives in archive/ from the start: the deploy script never runs it.
-- =====================================================================
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'TermsAnswers') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD TermsAnswers NVARCHAR(1000) NULL;
GO
SELECT COL_LENGTH('EXT.OfficeForms_KennelImport', 'TermsAnswers') AS TermsAnswersBytes;
