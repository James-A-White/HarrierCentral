-- =====================================================================
-- RUN-ONCE: retire the automated MEMBER standing bit's two procedures.
-- James, 2026-10-13: bit 0x0001 of HC.HasherKennelMap.KennelStanding is
-- RETIRED. Nothing read it; membership is MembershipExpirationDate and
-- nothing else. Its four callers were removed in the same change.
--
-- ⚠ ORDER: run this ONLY AFTER the API deploy that removes the sweep step
-- from api/Endpoints/MemberStandingSweep.cs. Until then the live API calls
-- HC6.nonApi_sweepMemberStanding at 03:10 UTC every night, and dropping it
-- first would fail that job (the run-count recompute after it would still
-- be skipped, because both share one try block).
--
-- Leaves the bit's stored values as they are (frozen, unread). Idempotent.
-- After running: move this file to db/hc6/app/archive/.
-- =====================================================================
DROP PROCEDURE IF EXISTS HC6.nonApi_sweepMemberStanding;
DROP PROCEDURE IF EXISTS HC6.nonApi_syncMemberStandingBit;
PRINT 'Dropped HC6.nonApi_sweepMemberStanding and HC6.nonApi_syncMemberStandingBit (if present).';
