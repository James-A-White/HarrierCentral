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
    ;WITH pays AS (
        SELECT pay.UserId, pay.KennelId, pay.id AS payId, pay.NetPayment, evt.id AS EventId,
               evt.EventStartDatetimeIndexed
        FROM   HC.Payment pay WITH (INDEX ([IX_CreditBalance]))
        JOIN   HC.Event evt ON evt.id = pay.EventId
        WHERE  pay.isCancelled = 0
          AND  pay.UserId       = @userId
          AND  (@kennelId IS NULL OR pay.KennelId = @kennelId)
    )
    SELECT
        UserId, KennelId, payId, EventId, EventStartDatetimeIndexed,
        SUM(NetPayment) OVER (
            PARTITION BY UserId, KennelId
            ORDER BY     EventStartDatetimeIndexed
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Balance,
        ROW_NUMBER() OVER (
            PARTITION BY UserId, KennelId
            ORDER BY     EventStartDatetimeIndexed DESC
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
           kc.balanceAsOfEventId = b.EventId,
           kc.updatedAt          = SYSDATETIMEOFFSET()
    FROM   HC.KennelCredit kc
    JOIN   #bal b ON b.UserId   = kc.userId
                 AND b.KennelId = kc.kennelId
                 AND b.RowNum   = 1
    WHERE  b.Balance     != kc.currentBalance
       OR  b.EventId     != kc.balanceAsOfEventId;

    INSERT INTO HC.KennelCredit (userId, kennelId, balanceAsOfEventId, currentBalance, updatedAt)
    SELECT b.UserId, b.KennelId, b.EventId, b.Balance, SYSDATETIMEOFFSET()
    FROM   #bal b
    LEFT   JOIN HC.KennelCredit kc ON kc.userId   = b.UserId
                                  AND kc.kennelId  = b.KennelId
    WHERE  kc.id    IS NULL
      AND  b.RowNum  = 1
      AND  b.Balance != 0;

    DROP TABLE #bal;

END
