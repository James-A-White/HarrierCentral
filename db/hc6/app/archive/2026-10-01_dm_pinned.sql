-- =====================================================================
-- Run-once: a DM conversation can be pinned in the Chats list (James,
-- 2026-10-01). One column on HC.HasherFriendMap — each hasher's row for the
-- thread, so each side's pin is their own. HasherFriendMap is not synced to
-- phones and has no triggers (checked 2026-10-01), so no trigger dance.
-- Executed 2026-10-01; archived at once.
-- =====================================================================
ALTER TABLE HC.HasherFriendMap ADD Pinned SMALLINT NOT NULL
    CONSTRAINT DF_HasherFriendMap_Pinned DEFAULT 0;
GO
