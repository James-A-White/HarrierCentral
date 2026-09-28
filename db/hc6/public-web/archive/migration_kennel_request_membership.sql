-- =====================================================================
-- Run-once: membership on EXT.OfficeForms_KennelImport (E12.F1.S7,
-- 2026-09-28). The hashruns.org form asks whether the kennel has a
-- membership, its fee and its type; approval copies them to
-- HC.Kennel.MembershipPrice / MembershipRenewalMode.
--   MembershipRenewalMode NULL = no membership; 1 rolling (annual),
--   2 fixed membership year, 3 lifetime — HC.Kennel's own codes.
-- Not synced to phones. Must run BEFORE publicWeb_submitKennelRequest,
-- hcportal_getKennelRequests and hcportal_approveKennelRequest deploy.
-- Idempotent. Lives in archive/ from the start: never run by the deploy.
-- =====================================================================
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'MembershipFee') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD MembershipFee NVARCHAR(50) NULL;
IF COL_LENGTH('EXT.OfficeForms_KennelImport', 'MembershipRenewalMode') IS NULL
    ALTER TABLE EXT.OfficeForms_KennelImport ADD MembershipRenewalMode SMALLINT NULL;
GO
SELECT COL_LENGTH('EXT.OfficeForms_KennelImport', 'MembershipFee') AS MembershipFeeBytes,
       COL_LENGTH('EXT.OfficeForms_KennelImport', 'MembershipRenewalMode') AS ModeBytes;
