-- =====================================================================
-- Run-once: a kennel's messaging platform and its group invite link
-- (E9.F6, James 2026-09-15).
--
-- ⚠ JAMES RUNS THIS BY HAND. HC.Kennel is synced and carries an UpdatedAt
--   trigger; an ALTER with it enabled stamps every row and every phone
--   re-downloads all 390 kennels. The trigger is disabled and re-enabled in
--   the same batch so a failure cannot leave it off.
--
-- DefaultMessagingPlatform  SMALLINT NOT NULL DEFAULT 1
--     1 WhatsApp · 2 Telegram · 3 Signal · 4 Messenger · 5 WeChat
--   Drives which app the run page's "Post this run" button opens; the
--   others sit behind its chevron. The DEFAULT is WhatsApp for every
--   existing row AND for every new kennel: no insert path names this
--   column, so the default applies to all of them without a code change.
--
-- MessagingGroupInviteUrl   NVARCHAR(500) NULL
--   The group's invite link, for JOINING — "Join the LH3 WhatsApp group" on
--   the kennel page. Deliberately NOT a "post into this group" target: no
--   platform lets an outside app open a specific group with a message
--   (WhatsApp's send?phone= is a person, an invite link opens the join
--   screen, Signal and WeChat have no compose scheme at all), so a field
--   promising that would lie for nearly every kennel. Joining is the one
--   thing an invite link can always do.
--
-- ORDER: run BEFORE deploying the SPs that read these columns.
-- Author: Harrier Central   Created: 2026-09-15
-- =====================================================================
SET XACT_ABORT ON;

IF COL_LENGTH('HC.Kennel', 'DefaultMessagingPlatform') IS NULL
   OR COL_LENGTH('HC.Kennel', 'MessagingGroupInviteUrl') IS NULL
BEGIN
    DISABLE TRIGGER HC.trgUpdateModifiedOnDateForKennels ON HC.Kennel;

    IF COL_LENGTH('HC.Kennel', 'DefaultMessagingPlatform') IS NULL
        ALTER TABLE HC.Kennel
            ADD DefaultMessagingPlatform SMALLINT NOT NULL
                CONSTRAINT DF_Kennel_DefaultMessagingPlatform DEFAULT (1);

    IF COL_LENGTH('HC.Kennel', 'MessagingGroupInviteUrl') IS NULL
        ALTER TABLE HC.Kennel ADD MessagingGroupInviteUrl NVARCHAR(500) NULL;

    ENABLE TRIGGER HC.trgUpdateModifiedOnDateForKennels ON HC.Kennel;
END
GO

SELECT t.name AS TriggerName, t.is_disabled AS IsDisabled_MustBeZero
FROM sys.triggers t WHERE t.name = 'trgUpdateModifiedOnDateForKennels';
GO
