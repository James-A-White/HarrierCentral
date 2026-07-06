CREATE OR ALTER PROCEDURE [HC6].[nonApi_sweepMemberStanding]
    @graceDays INT = 0
AS
-- =====================================================================
-- Procedure: HC6.nonApi_sweepMemberStanding
-- Description: Daily sweep for the AUTOMATED MEMBER bit (0x0001) of
--   HC.HasherKennelMap.KennelStanding. Clears the bit where membership
--   lapsed more than @graceDays ago; sets it where membership is current
--   (catches backdated fixes). Manual bits (ALUMNI/TRUSTED/ADMIN) are
--   never touched — lapsed members granted standing keep content access.
--   Scheduled by the API shim's timer trigger (automation consolidation
--   point). updatedAt restamps only on rows actually changed — desired,
--   so access changes replicate to clients.
-- Parameters: @graceDays — keep MEMBER for N days past expiration (default 0).
-- Returns: rowset 0: { rowsChanged }
-- Author: Harrier Central
-- Created: 2026-07-06
-- HC5 Source: none (new — KennelStanding design of record)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @cutoff DATETIMEOFFSET(7) = DATEADD(DAY, -@graceDays, GETDATE());

UPDATE hkm SET KennelStanding =
    CASE WHEN hkm.MembershipExpirationDate IS NOT NULL
              AND hkm.MembershipExpirationDate >= @cutoff
         THEN hkm.KennelStanding | 0x0001
         ELSE hkm.KennelStanding & ~0x0001
    END
FROM HC.HasherKennelMap hkm
WHERE hkm.KennelStanding <>
    CASE WHEN hkm.MembershipExpirationDate IS NOT NULL
              AND hkm.MembershipExpirationDate >= @cutoff
         THEN hkm.KennelStanding | 0x0001
         ELSE hkm.KennelStanding & ~0x0001
    END;

SELECT @@ROWCOUNT AS rowsChanged;
