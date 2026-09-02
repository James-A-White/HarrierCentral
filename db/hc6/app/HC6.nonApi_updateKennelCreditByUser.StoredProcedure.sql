-- =====================================================================
-- Procedure: HC6.nonApi_updateKennelCreditByUser
-- Description: Recalculates the running payment credit balance for a
--              user (optionally scoped to one kennel) and writes it
--              back to HC.Payment.CreditAvailable and
--              HC.HasherKennelMap.KennelCredit.
-- Parameters:
--   @userId   - Hasher to recalculate credit for.
--   @kennelId - Scope to a single kennel.  NULL = all kennels.
-- Returns:    Nothing.  Internal helper called by payment SPs.
-- Author: Harrier Central
-- Created: 2026-06-15
-- HC5 Source: HC.nonApi_updateKennelCreditByUser
-- =====================================================================
CREATE OR ALTER PROCEDURE [HC6].[nonApi_updateKennelCreditByUser]
    @userId   UNIQUEIDENTIFIER,
    @kennelId UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Running balance per payment ordered by event date, plus latest-row
    -- marker (RowNum = 1) used to derive the current kennel balance.
    -- LEFT join, deliberately. This was an INNER join, which silently dropped
    -- any payment without a matching event from the balance ENTIRELY — not
    -- mis-ordered, invisible. Every payment today has an event so nothing was
    -- lost, but credit purchases and promotional grants have no event, and the
    -- cash would have been taken while the credit never appeared.
    ;WITH pays AS (
        SELECT pay.UserId, pay.KennelId, pay.id AS payId, pay.NetPayment, evt.id AS EventId,
               -- Event-less rows take their position from PaidDate. EventStartLocal
               -- is a local wall clock and PaidDate an instant, so mixing them is
               -- approximate — fine for ordering a ledger, and the running TOTAL is
               -- order-independent regardless; only the intermediate
               -- CreditAvailable stamps depend on it.
               COALESCE(evt.EventStartLocal, CAST(pay.PaidDate AS DATETIME2(3))) AS SortDate
        FROM   HC.Payment pay WITH (INDEX ([IX_CreditBalance]))
        LEFT   JOIN HC.Event evt ON evt.id = pay.EventId
        WHERE  pay.isCancelled = 0
          AND  pay.UserId       = @userId
          AND  (@kennelId IS NULL OR pay.KennelId = @kennelId)
    )
    SELECT
        UserId, KennelId, payId, EventId, SortDate,
        -- payId tie-breaks so two rows sharing a date produce a deterministic
        -- running balance; without it the CreditAvailable stamps could differ
        -- between runs for no reason.
        SUM(NetPayment) OVER (
            PARTITION BY UserId, KennelId
            ORDER BY     SortDate, payId
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Balance,
        ROW_NUMBER() OVER (
            PARTITION BY UserId, KennelId
            ORDER BY     SortDate DESC, payId DESC
        ) AS RowNum
    INTO #bal
    FROM pays;

    -- Update the running balance stamped on each payment row
    UPDATE pay
    SET    pay.CreditAvailable = b.Balance,
           pay.updatedAt       = SYSDATETIMEOFFSET()
    FROM   HC.Payment pay
    JOIN   #bal b ON b.payId = pay.id
    WHERE  b.Balance != pay.CreditAvailable
      AND  pay.isCancelled = 0;

    -- Update the current credit balance on HasherKennelMap
    UPDATE hkm
    SET    hkm.KennelCredit = b.Balance,
           hkm.updatedAt    = SYSDATETIMEOFFSET()
    FROM   HC.HasherKennelMap hkm
    JOIN   #bal b ON b.UserId   = hkm.UserId
                 AND b.KennelId = hkm.KennelId
                 AND b.RowNum   = 1
    WHERE  b.Balance != hkm.KennelCredit;

    -- Keep HC.KennelCredit in sync (legacy table; remove when retired)
    UPDATE kc
    SET    kc.currentBalance     = b.Balance,
           -- Keep the previous marker when the newest row has no event: the
           -- column is NOT NULL and this legacy table is slated for removal,
           -- so the balance matters and the marker does not.
           kc.balanceAsOfEventId = COALESCE(b.EventId, kc.balanceAsOfEventId),
           kc.updatedAt          = SYSDATETIMEOFFSET()
    FROM   HC.KennelCredit kc
    JOIN   #bal b ON b.UserId   = kc.userId
                 AND b.KennelId = kc.kennelId
                 AND b.RowNum   = 1
    WHERE  b.Balance != kc.currentBalance
       OR  COALESCE(b.EventId, kc.balanceAsOfEventId) != kc.balanceAsOfEventId;

    INSERT INTO HC.KennelCredit (userId, kennelId, balanceAsOfEventId, currentBalance, updatedAt)
    SELECT b.UserId, b.KennelId, b.EventId, b.Balance, SYSDATETIMEOFFSET()
    FROM   #bal b
    LEFT   JOIN HC.KennelCredit kc ON kc.userId   = b.UserId
                                  AND kc.kennelId  = b.KennelId
    WHERE  kc.id    IS NULL
      AND  b.RowNum  = 1
      AND  b.Balance != 0
      -- balanceAsOfEventId is NOT NULL, so a first-ever payment with no event
      -- cannot seed this legacy row. HasherKennelMap.KennelCredit — the live
      -- balance everything actually reads — is still written above.
      AND  b.EventId IS NOT NULL;

    DROP TABLE #bal;

END
