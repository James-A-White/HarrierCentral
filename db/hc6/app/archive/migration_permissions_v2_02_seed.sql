-- =====================================================================
-- RUN-ONCE MIGRATION — Permissions V2, Phase 1b: seed
-- =====================================================================
-- Seeds the grantor catalog + function catalog, then GENERATES the global
-- grant rows by bitwise-decomposing the CURRENT hardcoded masks (from the 26
-- CheckKennelPermission call sites / the KennelFeature enum). This reproduces
-- today's behaviour EXACTLY — the cutover is a no-op.
--
-- Idempotent: catalogs insert-if-absent by key; global grants are rebuilt
-- (delete KennelId IS NULL, re-insert) so re-running refreshes defaults without
-- touching any per-kennel overrides.
--
-- ⚠️  RUN MANUALLY, after 01_tables.sql. Not picked up by deploy_hc6.sh.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- ---------------------------------------------------------------------
-- 1. Grantor catalog (mismanagement roles + app-access flags + bypass)
--    Bits mirror mobile-app/lib/util/constants.dart.
-- ---------------------------------------------------------------------
;WITH grantors(GrantorKey, DisplayName, GrantorType, Bit, SortOrder) AS (
    SELECT * FROM (VALUES
        -- Mismanagement roles (HKM.MismanagementRoles)
        ('isOnMm',           'On Mismanagement',       'mmRole',  0x00000001, 10),
        ('gm',               'GM (Grand Master)',      'mmRole',  0x00000002, 11),
        ('vgm',              'VGM (Vice GM)',          'mmRole',  0x00000004, 12),
        ('ra',               'RA (Religious Advisor)', 'mmRole',  0x00000008, 13),
        ('beerMeister',      'Beer Meister',           'mmRole',  0x00000010, 14),
        ('hashFlash',        'Hash Flash',             'mmRole',  0x00000020, 15),
        ('onSec',            'On Sec',                 'mmRole',  0x00000040, 16),
        ('songMeister',      'Song Meister',           'mmRole',  0x00000080, 17),
        ('trailMaster',      'Trail Master',           'mmRole',  0x00000100, 18),
        ('hareRaiser',       'Hare Raiser',            'mmRole',  0x00000200, 19),
        ('hashCash',         'Hash Cash',              'mmRole',  0x00000400, 20),
        ('scribe',           'Scribe',                 'mmRole',  0x00000800, 21),
        ('webMeister',       'Web Meister',            'mmRole',  0x00001000, 22),
        ('hashHugs',         'Hash Hugs',              'mmRole',  0x00002000, 23),
        ('hashHo',           'Hash Ho',                'mmRole',  0x00004000, 24),
        ('haberdasher',      'Haberdasher',            'mmRole',  0x00008000, 25),
        ('hashSweep',        'Hash Sweep',             'mmRole',  0x00010000, 26),
        ('hashTrash',        'Hash Trash',             'mmRole',  0x00020000, 27),
        ('hashBank',         'Hash Bank',              'mmRole',  0x00040000, 28),
        ('eventMeister',     'Event Meister',          'mmRole',  0x00080000, 29),
        ('communications',   'Communications',         'mmRole',  0x00100000, 30),
        ('other',            'Other',                  'mmRole',  0x00200000, 31),
        ('bashMaster',       'Bash Master',            'mmRole',  0x00400000, 32),
        ('bashMoney',        'Bash Money',             'mmRole',  0x00800000, 33),
        ('translator',       'Translator',             'mmRole',  0x01000000, 34),
        ('socialMediaWhore', 'Social Media',           'mmRole',  0x02000000, 35),
        ('downDownMaster',   'Down Down Master',       'mmRole',  0x04000000, 36),
        -- App-access flags (HKM.AppAccessFlags) — per-hasher overrides
        ('flagAdmin',            'Admin (umbrella)',            'appFlag', 0x00000001, 50),
        ('flagManageKennel',     'Manage kennel settings',      'appFlag', 0x00000002, 51),
        ('flagManageRuns',       'Manage runs',                 'appFlag', 0x00000004, 52),
        ('flagManageHashCash',   'Manage hash cash',            'appFlag', 0x00000008, 53),
        ('flagManageMembers',    'Manage members',              'appFlag', 0x00000010, 54),
        ('flagManageAwards',     'Manage awards',               'appFlag', 0x00000020, 55),
        ('flagManageSongs',      'Manage songs',                'appFlag', 0x00000040, 56),
        ('flagManageWebContent', 'Manage public web content',   'appFlag', 0x00000080, 57),
        ('flagManagePhotos',     'Manage photos',               'appFlag', 0x00000100, 58),
        -- Bypass — grants everything in code, never a matrix cell
        ('superAdmin',       'Super Admin',            'bypass',  0x40000000, 1)
    ) v(GrantorKey, DisplayName, GrantorType, Bit, SortOrder)
)
INSERT HC.PermissionRole (GrantorKey, DisplayName, GrantorType, Bit, SortOrder)
SELECT g.GrantorKey, g.DisplayName, g.GrantorType, g.Bit, g.SortOrder
FROM grantors g
WHERE NOT EXISTS (SELECT 1 FROM HC.PermissionRole r WHERE r.GrantorKey = g.GrantorKey);

-- ---------------------------------------------------------------------
-- 2. Function catalog + their CURRENT masks (source: the 26 call sites /
--    KennelFeature enum). Masks live only in this seed temp; the live tables
--    hold no masks (grants are decomposed rows).
-- ---------------------------------------------------------------------
DECLARE @fn TABLE (
    FunctionKey NVARCHAR(80), DisplayName NVARCHAR(120), FeatureArea NVARCHAR(60),
    HareScoped SMALLINT, SortOrder INT, MmMask INT, FlagMask INT
);
INSERT @fn VALUES
 ('viewPaymentReport',        'View payment report',        'Hash Cash',           0, 10, 0x0004040E, 0x00000008),
 ('takePayment',              'Take payment (check-in)',    'Hash Cash',           1, 11, 0x0004040E, 0x00000008),
 ('bulkPayment',              'Bulk payment',               'Hash Cash',           0, 12, 0x0004040E, 0x00000008),
 ('manageReceipts',           'Manage receipts (expenses)', 'Hash Cash',           1, 13, 0x0004841E, 0x00000008),
 ('createEditRuns',           'Create / edit runs',         'Runs & Events',       1, 20, 0x00080346, 0x00000004),
 ('printQrCodes',             'Print QR codes',             'Runs & Events',       1, 21, 0x00080306, 0x00000004),
 ('manageAttendance',         'Manage attendance',          'Runs & Events',       1, 22, 0x0008014E, 0x00000004),
 ('copyRsvps',                'Copy RSVPs between runs',    'Runs & Events',       0, 23, 0x00080146, 0x00000004),
 ('packTrackTrim',            'PackTrack trim (admin)',     'Runs & Events',       0, 24, 0x00000106, 0x00000004),
 ('enterRunAdmin',            'Enter run admin',            'Runs & Events',       1, 25, 0x0004042E, 0x0000000C),
 ('awardList',                'Award list (drinks)',        'Down Downs & Awards', 0, 30, 0x0000001E, 0x00000020),
 ('manageDownDowns',          'Manage Down Downs',          'Down Downs & Awards', 0, 31, 0x0000001E, 0x00000020),
 ('manageMembers',            'Manage members (roster)',    'Members',             0, 40, 0x00000046, 0x00000010),
 ('viewInviteCodes',          'View invite codes',          'Members',             0, 41, 0x00000046, 0x00000010),
 ('enterKennelAdmin',         'Enter kennel admin',         'Members',             0, 42, 0x0000002E, 0x00000010),
 ('assignAppAccessFlags',     'Assign app-access flags',    'Members',             0, 43, 0x00000000, 0x00000000),
 ('assignMismanagementRoles', 'Assign mismanagement roles', 'Members',             0, 44, 0x00000006, 0x00000000),
 ('reviewPhotos',             'Review / approve photos',    'Photos',              0, 50, 0x0000002E, 0x00000100),
 ('editPhoto',                'Edit photo status / caption','Photos',              0, 51, 0x0000002E, 0x00000100),
 ('batchPhotos',              'Batch / view all photos',    'Photos',              0, 52, 0x0000102E, 0x00000100),
 ('writeHashTrash',           'Write / save Hash Trash',    'Web / Newsletter',    0, 60, 0x00121806, 0x00000080),
 ('viewHashTrashDrafts',      'View Hash Trash drafts',     'Web / Newsletter',    0, 61, 0x00121806, 0x00000080),
 ('manageKennelSettings',     'Manage kennel settings',     'Kennel',              0, 70, 0x00000006, 0x00000002),
 ('manageSongs',              'Manage songs',               'Songs',               0, 80, 0x00000086, 0x00000040);

INSERT HC.PermissionFunction (FunctionKey, DisplayName, FeatureArea, HareScoped, SortOrder)
SELECT f.FunctionKey, f.DisplayName, f.FeatureArea, f.HareScoped, f.SortOrder
FROM @fn f
WHERE NOT EXISTS (SELECT 1 FROM HC.PermissionFunction pf WHERE pf.FunctionKey = f.FunctionKey);

-- ---------------------------------------------------------------------
-- 3. Global grants — decompose each function's masks into grantor rows.
--    A grantor grants a function iff its bit is set in the matching mask.
--    Rebuild global rows only (leave any per-kennel overrides untouched).
-- ---------------------------------------------------------------------
DELETE HC.RolePermission WHERE KennelId IS NULL;

INSERT HC.RolePermission (GrantorId, FunctionId, KennelId, Allowed)
SELECT g.id, pf.id, NULL, 1
FROM @fn f
JOIN HC.PermissionFunction pf ON pf.FunctionKey = f.FunctionKey
JOIN HC.PermissionRole g
  ON ( (g.GrantorType = 'mmRole'  AND (f.MmMask   & g.Bit) <> 0)
    OR (g.GrantorType = 'appFlag' AND (f.FlagMask & g.Bit) <> 0) );

COMMIT TRANSACTION;

-- Sanity check.
SELECT
    (SELECT COUNT(*) FROM HC.PermissionRole)                            AS grantors,
    (SELECT COUNT(*) FROM HC.PermissionFunction)                        AS functions,
    (SELECT COUNT(*) FROM HC.RolePermission WHERE KennelId IS NULL)     AS globalGrants;
GO
