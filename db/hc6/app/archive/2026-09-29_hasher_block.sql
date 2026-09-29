-- =====================================================================
-- RUN-ONCE: Block a hasher (E9.F1.S16, James 2026-09-29)
--
-- HC.HasherFriendMap (2019, unused until now) already has the row shape a
-- block needs: directional UserId -> Friend_UserId, unique on the pair, and
-- an Ignore SMALLINT. This adds the two audit columns it never had. It is
-- NOT a synced table and has no updatedAt trigger, so the ALTER stamps
-- nothing and forces no re-sync.
--
-- Idempotent. Run BEFORE the SPs that reference the columns. Archive to
-- db/hc6/app/archive/ after.
-- =====================================================================
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('HC.HasherFriendMap', 'createdAt') IS NULL
    ALTER TABLE HC.HasherFriendMap
        ADD createdAt DATETIMEOFFSET(7) NOT NULL
            CONSTRAINT DF_HasherFriendMap_createdAt DEFAULT (SYSDATETIMEOFFSET());

IF COL_LENGTH('HC.HasherFriendMap', 'updatedAt') IS NULL
    ALTER TABLE HC.HasherFriendMap
        ADD updatedAt DATETIMEOFFSET(7) NOT NULL
            CONSTRAINT DF_HasherFriendMap_updatedAt DEFAULT (SYSDATETIMEOFFSET());

-- Every reader filters on (UserId, Friend_UserId, Ignore); the unique
-- constraint on the pair already gives the seek. Nothing more needed.

COMMIT TRANSACTION;

SELECT COUNT(*) AS rows_, SUM(CAST(Ignore AS INT)) AS blocks FROM HC.HasherFriendMap;
