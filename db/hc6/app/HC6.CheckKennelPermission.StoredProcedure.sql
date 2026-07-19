CREATE OR ALTER PROCEDURE [HC6].[CheckKennelPermission]
    @userId          UNIQUEIDENTIFIER,
    @kennelId        UNIQUEIDENTIFIER,
    @requiredMmRoles INT,             -- MismanagementRoles mask: roles that grant this feature
    @requiredAppFlags INT,            -- AppAccessFlags mask: the feature's per-hasher override flag
    @allowed         SMALLINT OUTPUT  -- 1 = allowed, 0 = denied
AS
-- =====================================================================
-- Procedure: HC6.CheckKennelPermission
-- Description: The single authorizer for kennel-scoped features. Returns
--   @allowed = 1 when the user (in this kennel) satisfies the "gate on BOTH"
--   model agreed 2026-07-19:
--       SuperAdmin
--       OR (MismanagementRoles & @requiredMmRoles)  -- their club role grants it
--       OR (AppAccessFlags     & @requiredAppFlags) -- per-hasher override flag
--   Only SuperAdmin (0x40000000) bypasses every feature. IsAdmin (0x01) is an
--   auto-derived umbrella (UI-only) and is NOT folded in — see the note by the
--   check below. (The legacy inline gates used 0x40000081, which also wrongly
--   included 0x80 = ManagePublicWebContent; do not reintroduce that bit either.)
--
--   This does NOT handle run-scoped (Hare) access — a designated hare's
--   per-event grants are checked in the calling SP against HasherEventMap.IsHare
--   for that event, in addition to this call.
--
-- Parameters:
--   @userId / @kennelId  - who + which kennel (the HKM row)
--   @requiredMmRoles     - feature's MismanagementRoles mask (see table below)
--   @requiredAppFlags    - feature's AppAccessFlags override mask
-- Returns: @allowed OUTPUT (SMALLINT 1/0). No rowset.
-- Author: Harrier Central
-- Created: 2026-07-19
--
-- ---------------------------------------------------------------------
-- Canonical feature -> (mmMask, appFlagMask) table (from docs/permissions_matrix.xlsx).
-- Callers pass these literals; keep this table and the app KennelPermission
-- helper in sync with the matrix.
--   Feature                       mmMask      appFlag   run-scoped Hare?
--   View payment report           0x0004040E  0x08      no
--   Take payment (check-in)       0x0004040E  0x08      YES
--   Bulk payment                  0x0004040E  0x08      no
--   Manage receipts               0x0004841E  0x08      YES
--   Create / edit runs            0x00080346  0x04      YES
--   Print QR codes                0x00080306  0x04      YES
--   Manage attendance             0x0008014E  0x04      YES
--   Copy RSVPs                    0x00080146  0x04      no
--   PackTrack trim                0x00000106  0x04      no
--   Award list (drinks)           0x0000001E  0x20      no
--   Manage Down Downs             0x0000001E  0x20      no
--   Manage members                0x00000046  0x10      no
--   View invite codes             0x00000046  0x10      no
--   Assign app-access flags       0x00000000  0x00      no   (super-admin only)
--   Assign mismanagement roles    0x00000006  0x00      no   (GM|VGM + super-admin)
--   Review / approve photos       0x0000002E  0x0100    no
--   Edit photo status/caption     0x0000002E  0x0100    no
--   Batch / view all photos       0x0000102E  0x0100    no
--   Write / save Hash Trash       0x00121806  0x80      no
--   View Hash Trash drafts        0x00121806  0x80      no
--   Manage kennel settings        0x00000006  0x02      no
--   Manage songs                  0x00000086  0x40      no
--   (Post event chat = kennel membership, not a role gate — handled inline.)
-- =====================================================================
SET NOCOUNT ON;

DECLARE @mm INT = 0, @flags INT = 0;

SELECT
    @mm    = ISNULL(MismanagementRoles, 0),
    @flags = ISNULL(AppAccessFlags, 0)
FROM HC.HasherKennelMap
WHERE UserId = @userId AND KennelId = @kennelId AND removed = 0;

SET @allowed =
    CASE WHEN
            (@flags & 0x40000000) <> 0            -- SuperAdmin (the only "everything" bypass)
         OR (@mm    & @requiredMmRoles)  <> 0     -- club role default
         OR (@flags & @requiredAppFlags) <> 0     -- per-hasher override flag
    THEN 1 ELSE 0 END;
-- NOTE: IsAdmin (0x01) is deliberately NOT folded in. It is an auto-derived
-- umbrella bit (set on anyone holding any one functional flag) used only to show
-- admin UI; treating it as "passes everything" would let a single narrow grant
-- (e.g. Manage Songs) unlock every feature. Each feature is gated on its own
-- role/flag; SuperAdmin is the sole all-features bypass.
