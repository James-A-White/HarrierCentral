CREATE OR ALTER PROCEDURE [HC6].[nonApi_syncMemberStandingBit]
    @userId   UNIQUEIDENTIFIER,
    @kennelId UNIQUEIDENTIFIER
AS
-- =====================================================================
-- Procedure: HC6.nonApi_syncMemberStandingBit
-- Description: Single maintenance point for the AUTOMATED MEMBER bit
--   (0x0001) of HC.HasherKennelMap.KennelStanding. Sets the bit when the
--   user's membership is current, clears it when lapsed/absent. Never
--   touches the manual bits (ALUMNI 0x0002, TRUSTED 0x0004, ADMIN 0x0100).
--   Called by every SP that writes MembershipExpirationDate, and row-wise
--   equivalent of nonApi_sweepMemberStanding.
-- Parameters: @userId/@kennelId — the HKM row to sync.
-- Returns: none (fire-and-forget maintenance).
-- Author: Harrier Central
-- Created: 2026-07-06
-- HC5 Source: none (new — KennelStanding design of record)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY

UPDATE hkm SET KennelStanding =
    CASE WHEN hkm.MembershipExpirationDate IS NOT NULL
              AND hkm.MembershipExpirationDate >= GETDATE()
         THEN hkm.KennelStanding | 0x0001
         ELSE hkm.KennelStanding & ~1  /* MEMBER bit; int literal — ~varbinary(0x...) is invalid in T-SQL */
    END
FROM HC.HasherKennelMap hkm
WHERE hkm.UserId = @userId AND hkm.KennelId = @kennelId
  AND hkm.KennelStanding <>
    CASE WHEN hkm.MembershipExpirationDate IS NOT NULL
              AND hkm.MembershipExpirationDate >= GETDATE()
         THEN hkm.KennelStanding | 0x0001
         ELSE hkm.KennelStanding & ~1  /* MEMBER bit; int literal — ~varbinary(0x...) is invalid in T-SQL */
    END;  -- no-op when already correct: avoids a pointless updatedAt restamp
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    -- Log THEN re-raise: the caller (a timer-triggered Function, or an
    -- operator) still sees the failure, and now so does the sweep. Until
    -- 2026-09-23 a failure here was a "Failed" tile with no row anywhere.
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in nonApi_syncMemberStandingBit', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), NULL);
    THROW;
END CATCH
