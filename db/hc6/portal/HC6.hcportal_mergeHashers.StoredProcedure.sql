CREATE OR ALTER PROCEDURE [HC6].[hcportal_mergeHashers]
    @deviceId      UNIQUEIDENTIFIER = NULL,
    @accessToken   NVARCHAR(1000)   = NULL,
    @keepHasherId  UNIQUEIDENTIFIER = NULL,
    @mergeHasherId UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcportal_mergeHashers
-- Description: Merges two accounts that belong to one person (E12.F6.S2):
--   everything the MERGE account holds moves to the KEEP account, and the
--   merge account is then disabled. Called with the two ids that
--   hcportal_previewHasherMerge showed the admin.
--
--   Runs (HC.HasherEventMap) and payments (HC.Payment) all move to the kept
--   account — nothing is deleted:
--     * a run only the merge account has: its row's UserId becomes the
--       kept account;
--     * a run BOTH have (same run, same DisplayName — the unique key allows
--       one row): the rows are combined into the kept one (best attendance,
--       RSVP, hare flag, track, notes), the merge row's payments are
--       repointed to it, and the merge row is soft-removed (removed = 1,
--       attendance cleared) so phones purge it;
--     * every payment's UserId becomes the kept account — cancelled ones
--       too, and both payments where both accounts paid for one run (the
--       preview lists those for a refund); the ProcessedBy / ConfirmedBy /
--       CancelledBy columns follow the person as well.
--   Kennel memberships combine the same way (flags OR-ed, historical counts
--   the larger, membership dates widened). Chat badge rows combine per
--   thread. Chat messages, photos, receipts, down downs, songs, products,
--   promotions, track imports and run-organiser links move across.
--   Then run counts and kennel credit are recalculated for the kept account.
--
--   The merge account is disabled as hcapp_gdprDelete disables one:
--   Removed = 1, every device signed out with a new secret (the app wipes
--   itself on its next call) and its push tokens cleared; its sign-in code
--   is cleared. Its email stays on the disabled row for the record.
--   Logs (ErrorLog, PushLog, LaunchAndLogin, ClientErrorLog, portal access)
--   stay with the id that wrote them. The merge is written to
--   LOG.GeneralLog with the counts.
--
--   Replaces HC3.utilApi_mergeUsers, which DELETED the merge account's
--   payment wherever both had paid for a run, deleted every past run either
--   account had not attended, and knew none of the HC6 tables.
--   Requires an HC.PlatformAdmin row with CanEditKennel.
-- Parameters: @deviceId, @accessToken (auth); @keepHasherId, @mergeHasherId.
-- Returns: rowset 0 — { Success, ErrorMessage };
--          rowset 1 (success only) — the counts of what moved.
-- Author: Harrier Central
-- Created: 2026-09-28
-- HC5 Source: none (replaces HC3.utilApi_mergeUsers)
-- Breaking Changes: none (new)
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName   NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @authError  NVARCHAR(255);
DECLARE @callerId   UNIQUEIDENTIFIER;
DECLARE @callerType INT;

EXEC HC6.ValidatePortalAuth
    @deviceId, @accessToken, @procName, NULL,
    @authError OUTPUT, @callerId OUTPUT, @callerType OUTPUT;

IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM HC.PlatformAdmin pa
               WHERE pa.UserId = @callerId AND pa.removed = 0 AND pa.CanEditKennel = 1)
BEGIN
    SELECT 0 AS Success, 'Not authorised: Platform Admin with CanEditKennel required' AS ErrorMessage;
    RETURN;
END

IF (@keepHasherId IS NULL OR @mergeHasherId IS NULL OR @keepHasherId = @mergeHasherId)
BEGIN
    SELECT 0 AS Success, 'Two different accounts are needed' AS ErrorMessage;
    RETURN;
END

DECLARE @keep UNIQUEIDENTIFIER = @keepHasherId, @merge UNIQUEIDENTIFIER = @mergeHasherId;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Lock both accounts for the whole merge; both must still be live.
    DECLARE @live INT = (SELECT COUNT(*) FROM HC.Hasher WITH (UPDLOCK, HOLDLOCK)
                         WHERE id IN (@keep, @merge) AND Removed = 0);
    IF (@live <> 2)
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success, 'One of the accounts no longer exists or was already merged — preview again' AS ErrorMessage;
        RETURN;
    END

    DECLARE @keepPublicId UNIQUEIDENTIFIER = (SELECT PublicHasherId FROM HC.Hasher WHERE id = @keep);
    DECLARE @n TABLE (Item NVARCHAR(40) PRIMARY KEY, N INT);

    -- ── Runs ───────────────────────────────────────────────────────────
    -- Pair each merge row with the kept row for the same run and name.
    DECLARE @runPairs TABLE (mergeRow UNIQUEIDENTIFIER PRIMARY KEY, keepRow UNIQUEIDENTIFIER);
    INSERT @runPairs (mergeRow, keepRow)
    SELECT m.id, k.id
    FROM HC.HasherEventMap m
    CROSS APPLY (SELECT TOP 1 k.id FROM HC.HasherEventMap k
                 WHERE k.UserId = @keep AND k.EventId = m.EventId
                   AND COALESCE(k.DisplayName, N'') = COALESCE(m.DisplayName, N'')
                 -- A soft-removed kept row still holds the unique key, so it
                 -- is paired too (and revived below); a live one is preferred.
                 ORDER BY k.removed, k.AttendenceState DESC) k
    WHERE m.UserId = @merge AND m.removed = 0;

    -- Combine into the kept row: the stronger answer wins field by field.
    UPDATE k SET
        AttendenceState   = CASE WHEN m.AttendenceState > k.AttendenceState THEN m.AttendenceState ELSE k.AttendenceState END,
        RsvpState         = CASE WHEN COALESCE(k.RsvpState, 0) = 0 THEN m.RsvpState ELSE k.RsvpState END,
        Rsvp              = COALESCE(k.Rsvp, m.Rsvp),
        IsHare            = CASE WHEN m.IsHare = 1 THEN 1 ELSE k.IsHare END,
        UserStartEvent    = COALESCE(k.UserStartEvent, m.UserStartEvent),
        UserEndEvent      = COALESCE(k.UserEndEvent, m.UserEndEvent),
        EventCountOverride = COALESCE(NULLIF(k.EventCountOverride, 0), m.EventCountOverride),
        VirginVisitorType = COALESCE(NULLIF(k.VirginVisitorType, 0), m.VirginVisitorType),
        Pinned            = CASE WHEN m.Pinned = 1 THEN 1 ELSE k.Pinned END,
        Notes             = COALESCE(k.Notes, m.Notes),
        NotesVisibility   = CASE WHEN k.Notes IS NULL THEN m.NotesVisibility ELSE k.NotesVisibility END,
        removed           = 0,
        updatedAt         = SYSDATETIMEOFFSET()
    FROM HC.HasherEventMap k
    JOIN @runPairs p ON p.keepRow = k.id
    JOIN HC.HasherEventMap m ON m.id = p.mergeRow;

    -- The track: take the merge row's whole track when the kept row has none.
    UPDATE k SET
        TrackFirstPointAt = m.TrackFirstPointAt, TrackLastPointAt = m.TrackLastPointAt,
        TrackPointCount = m.TrackPointCount, TrackGzip = m.TrackGzip,
        TrackDistanceM = m.TrackDistanceM, TrackMovingSeconds = m.TrackMovingSeconds,
        TrackElevationGainM = m.TrackElevationGainM,
        TrackStartLat = m.TrackStartLat, TrackStartLng = m.TrackStartLng,
        TrackEndLat = m.TrackEndLat, TrackEndLng = m.TrackEndLng,
        TrackMinLat = m.TrackMinLat, TrackMinLng = m.TrackMinLng,
        TrackMaxLat = m.TrackMaxLat, TrackMaxLng = m.TrackMaxLng,
        TrackGpsSettings = m.TrackGpsSettings
    FROM HC.HasherEventMap k
    JOIN @runPairs p ON p.keepRow = k.id
    JOIN HC.HasherEventMap m ON m.id = p.mergeRow
    WHERE COALESCE(k.TrackPointCount, 0) = 0 AND COALESCE(m.TrackPointCount, 0) > 0;

    -- Payments that pointed at a combined merge row now point at the kept one.
    UPDATE pay SET HasherEventMapId = p.keepRow
    FROM HC.Payment pay
    JOIN @runPairs p ON p.mergeRow = pay.HasherEventMapId;

    -- The combined merge rows are soft-removed: phones purge removed rows,
    -- and with attendance cleared no reader can count them.
    -- TrackPointCount too: the nightly archiver re-archives any row with a
    -- count and no TrackGzip, which would rebuild this dead row.
    UPDATE m SET removed = 1, AttendenceState = 0, RsvpState = 0, IsHare = 0,
                 TrackGzip = NULL, TrackPointCount = NULL, updatedAt = SYSDATETIMEOFFSET()
    FROM HC.HasherEventMap m
    JOIN @runPairs p ON p.mergeRow = m.id;
    INSERT @n VALUES ('runsCombined', @@ROWCOUNT);

    -- Every other run moves across.
    UPDATE HC.HasherEventMap SET UserId = @keep, updatedAt = SYSDATETIMEOFFSET()
    WHERE UserId = @merge AND removed = 0;
    INSERT @n VALUES ('runsMoved', @@ROWCOUNT);

    -- ── Payments: every row follows the person ─────────────────────────
    UPDATE HC.Payment SET UserId = @keep, updatedAt = SYSDATETIMEOFFSET() WHERE UserId = @merge;
    INSERT @n VALUES ('paymentsMoved', @@ROWCOUNT);
    UPDATE HC.Payment SET PaymentProcessedBy_userId = @keep WHERE PaymentProcessedBy_userId = @merge;
    UPDATE HC.Payment SET ConfirmedBy_UserId = @keep WHERE ConfirmedBy_UserId = @merge;
    UPDATE HC.Payment SET CancelledBy_UserId = @keep WHERE CancelledBy_UserId = @merge;
    UPDATE HC.Receipt SET UserId = @keep, updatedAt = SYSDATETIMEOFFSET() WHERE UserId = @merge;
    UPDATE HC.Receipt SET ReimbursedBy = @keep WHERE ReimbursedBy = @merge;

    -- ── Kennel memberships ─────────────────────────────────────────────
    DECLARE @kennelPairs TABLE (mergeRow UNIQUEIDENTIFIER PRIMARY KEY, keepRow UNIQUEIDENTIFIER);
    INSERT @kennelPairs (mergeRow, keepRow)
    SELECT m.id, k.id
    FROM HC.HasherKennelMap m
    JOIN HC.HasherKennelMap k ON k.KennelId = m.KennelId AND k.UserId = @keep
    WHERE m.UserId = @merge;

    UPDATE k SET
        Following              = CASE WHEN m.removed = 0 AND m.Following = 1 THEN 1 ELSE k.Following END,
        IsMember               = CASE WHEN m.removed = 0 AND m.IsMember = 1 THEN 1 ELSE k.IsMember END,
        IsKennelFollowing      = CASE WHEN m.removed = 0 AND m.IsKennelFollowing = 1 THEN 1 ELSE k.IsKennelFollowing END,
        IsHomeKennel           = CASE WHEN m.removed = 0 AND m.IsHomeKennel = 1 THEN 1 ELSE k.IsHomeKennel END,
        MismanagementRoles     = COALESCE(k.MismanagementRoles, 0) | COALESCE(m.MismanagementRoles, 0),
        MismanagementRoleFlags = COALESCE(k.MismanagementRoleFlags, 0) | COALESCE(m.MismanagementRoleFlags, 0),
        HcWebPermissionFlags   = COALESCE(k.HcWebPermissionFlags, 0) | COALESCE(m.HcWebPermissionFlags, 0),
        UserRoleFlags          = COALESCE(k.UserRoleFlags, 0) | COALESCE(m.UserRoleFlags, 0),
        AppAccessFlags         = COALESCE(k.AppAccessFlags, 0) | COALESCE(m.AppAccessFlags, 0),
        -- Historical counts are what a kennel typed in for the years before
        -- Harrier Central; the same person's two records take the larger.
        HistoricalTotalRunCount = CASE WHEN COALESCE(m.HistoricalTotalRunCount, 0) > COALESCE(k.HistoricalTotalRunCount, 0) THEN m.HistoricalTotalRunCount ELSE k.HistoricalTotalRunCount END,
        HistoricalPackRunCount  = CASE WHEN COALESCE(m.HistoricalPackRunCount, 0) > COALESCE(k.HistoricalPackRunCount, 0) THEN m.HistoricalPackRunCount ELSE k.HistoricalPackRunCount END,
        HistoricalHaringCount   = CASE WHEN COALESCE(m.HistoricalHaringCount, 0) > COALESCE(k.HistoricalHaringCount, 0) THEN m.HistoricalHaringCount ELSE k.HistoricalHaringCount END,
        MembershipExpirationDate = CASE WHEN m.MembershipExpirationDate > COALESCE(k.MembershipExpirationDate, '1900-01-01') THEN m.MembershipExpirationDate ELSE k.MembershipExpirationDate END,
        MemberSince            = CASE WHEN m.MemberSince < COALESCE(k.MemberSince, '9999-12-31') THEN m.MemberSince ELSE k.MemberSince END,
        DateOfLastRun          = CASE WHEN m.DateOfLastRun > COALESCE(k.DateOfLastRun, '1900-01-01') THEN m.DateOfLastRun ELSE k.DateOfLastRun END,
        CanEditRunAttendence   = CASE WHEN m.CanEditRunAttendence = 1 THEN 1 ELSE k.CanEditRunAttendence END,
        KennelHashName         = COALESCE(NULLIF(k.KennelHashName, N''), m.KennelHashName),
        KennelUserPhoto        = COALESCE(NULLIF(k.KennelUserPhoto, N''), m.KennelUserPhoto),
        DiscountAmount         = COALESCE(NULLIF(k.DiscountAmount, 0), m.DiscountAmount),
        DiscountPercent        = COALESCE(NULLIF(k.DiscountPercent, 0), m.DiscountPercent),
        DiscountDescription    = COALESCE(NULLIF(k.DiscountDescription, N''), m.DiscountDescription),
        Pinned                 = CASE WHEN m.Pinned = 1 THEN 1 ELSE k.Pinned END,
        removed                = CASE WHEN m.removed = 0 THEN 0 ELSE k.removed END,
        updatedAt              = SYSDATETIMEOFFSET()
    FROM HC.HasherKennelMap k
    JOIN @kennelPairs p ON p.keepRow = k.id
    JOIN HC.HasherKennelMap m ON m.id = p.mergeRow;

    UPDATE m SET removed = 1, Following = 0, IsMember = 0, IsHomeKennel = 0,
                 AppAccessFlags = 0, MismanagementRoleFlags = 0, HcWebPermissionFlags = 0,
                 updatedAt = SYSDATETIMEOFFSET()
    FROM HC.HasherKennelMap m
    JOIN @kennelPairs p ON p.mergeRow = m.id;
    INSERT @n VALUES ('kennelsCombined', @@ROWCOUNT);

    UPDATE HC.HasherKennelMap SET UserId = @keep, updatedAt = SYSDATETIMEOFFSET()
    WHERE UserId = @merge AND id NOT IN (SELECT mergeRow FROM @kennelPairs);
    INSERT @n VALUES ('kennelsMoved', @@ROWCOUNT);

    -- ── Chat ───────────────────────────────────────────────────────────
    UPDATE HC.EventMessage SET UserId = @keep, PublicHasherId = @keepPublicId WHERE UserId = @merge;
    INSERT @n VALUES ('chatMessagesMoved', @@ROWCOUNT);

    DECLARE @badgePairs TABLE (mergeRow UNIQUEIDENTIFIER PRIMARY KEY, keepRow UNIQUEIDENTIFIER);
    INSERT @badgePairs (mergeRow, keepRow)
    SELECT m.id, k.id
    FROM HC.EventMessageBadgeCounts m
    CROSS APPLY (SELECT TOP 1 k.id FROM HC.EventMessageBadgeCounts k
                 WHERE k.UserId = @keep AND k.Removed = 0
                   AND COALESCE(k.MessageType, -1) = COALESCE(m.MessageType, -1)
                   AND COALESCE(k.ThreadId, k.EventId) = COALESCE(m.ThreadId, m.EventId)) k
    WHERE m.UserId = @merge AND m.Removed = 0;

    UPDATE k SET
        LastSequenceCount = CASE WHEN m.LastSequenceCount > COALESCE(k.LastSequenceCount, 0) THEN m.LastSequenceCount ELSE k.LastSequenceCount END,
        LastReadMessageId = CASE WHEN m.LastSequenceCount > COALESCE(k.LastSequenceCount, 0) THEN m.LastReadMessageId ELSE k.LastReadMessageId END,
        LastReadAt        = CASE WHEN m.LastReadAt > COALESCE(k.LastReadAt, '1900-01-01') THEN m.LastReadAt ELSE k.LastReadAt END,
        ParticipationState = COALESCE(k.ParticipationState, m.ParticipationState),
        updatedAt         = SYSDATETIMEOFFSET()
    FROM HC.EventMessageBadgeCounts k
    JOIN @badgePairs p ON p.keepRow = k.id
    JOIN HC.EventMessageBadgeCounts m ON m.id = p.mergeRow;

    UPDATE m SET Removed = 1, updatedAt = SYSDATETIMEOFFSET()
    FROM HC.EventMessageBadgeCounts m JOIN @badgePairs p ON p.mergeRow = m.id;

    UPDATE HC.EventMessageBadgeCounts SET UserId = @keep, updatedAt = SYSDATETIMEOFFSET()
    WHERE UserId = @merge AND Removed = 0;

    -- ── Everything else that names the person ──────────────────────────
    UPDATE HC.KennelPhotos SET UserId = @keep WHERE UserId = @merge;
    INSERT @n VALUES ('photosMoved', @@ROWCOUNT);

    -- Down downs: one row per down down and hasher.
    DELETE m FROM HC.DownDownHashers m
    WHERE m.HasherId = @merge
      AND EXISTS (SELECT 1 FROM HC.DownDownHashers k WHERE k.HasherId = @keep AND k.DownDownId = m.DownDownId);
    UPDATE HC.DownDownHashers SET HasherId = @keep WHERE HasherId = @merge;
    UPDATE HC.DownDowns SET CreatedByUserId = @keep WHERE CreatedByUserId = @merge;

    UPDATE HC.Event SET Organizer_HasherId = @keep WHERE Organizer_HasherId = @merge;
    UPDATE HC.Event SET EventLastUpdatedBy = @keep WHERE EventLastUpdatedBy = @merge;
    UPDATE HC.Song SET AddedBy_UserId = @keep WHERE AddedBy_UserId = @merge;
    UPDATE HC.SongSession SET SelectedByUserId = @keep WHERE SelectedByUserId = @merge;
    UPDATE HC.Product SET CreatedByUserId = @keep WHERE CreatedByUserId = @merge;
    UPDATE HC.Promotion SET UserId = @keep WHERE UserId = @merge;
    DELETE m FROM HC.HasherPromotionMap m
    WHERE m.UserId = @merge
      AND EXISTS (SELECT 1 FROM HC.HasherPromotionMap k WHERE k.UserId = @keep AND k.PromotionId = m.PromotionId);
    UPDATE HC.HasherPromotionMap SET UserId = @keep WHERE UserId = @merge;
    UPDATE HC.TrackImport SET HasherId = @keep WHERE HasherId = @merge;
    UPDATE HC.HasherOwnEvent SET UserId = @keep WHERE UserId = @merge;
    UPDATE HC.PortalNewsflash SET CreatedByHasherId = @keep WHERE CreatedByHasherId = @merge;
    DELETE m FROM HC.PortalNewsflashRead m
    WHERE m.HasherId = @merge
      AND EXISTS (SELECT 1 FROM HC.PortalNewsflashRead k WHERE k.HasherId = @keep AND k.NewsflashId = m.NewsflashId);
    UPDATE HC.PortalNewsflashRead SET HasherId = @keep WHERE HasherId = @merge;
    -- Friends: never a friend of yourself, never twice.
    DELETE FROM HC.HasherFriendMap
    WHERE (UserId = @merge AND (Friend_UserId = @keep
                                OR Friend_UserId IN (SELECT Friend_UserId FROM HC.HasherFriendMap WHERE UserId = @keep)))
       OR (Friend_UserId = @merge AND (UserId = @keep
                                OR UserId IN (SELECT UserId FROM HC.HasherFriendMap WHERE Friend_UserId = @keep)));
    UPDATE HC.HasherFriendMap SET UserId = @keep WHERE UserId = @merge;
    UPDATE HC.HasherFriendMap SET Friend_UserId = @keep WHERE Friend_UserId = @merge;
    -- A platform admin's privileges follow the person when the kept account has none.
    IF NOT EXISTS (SELECT 1 FROM HC.PlatformAdmin WHERE UserId = @keep)
        UPDATE HC.PlatformAdmin SET UserId = @keep, updatedAt = SYSDATETIMEOFFSET() WHERE UserId = @merge;
    ELSE
        UPDATE HC.PlatformAdmin SET removed = 1, updatedAt = SYSDATETIMEOFFSET() WHERE UserId = @merge;
    UPDATE EXT.OfficeForms_KennelImport SET ReviewedBy = @keep WHERE ReviewedBy = @merge;

    -- ── The kept account fills its blanks from the other ───────────────
    UPDATE k SET
        HashName     = COALESCE(NULLIF(k.HashName, N''), m.HashName),
        FirstName    = COALESCE(NULLIF(k.FirstName, N''), m.FirstName),
        LastName     = COALESCE(NULLIF(k.LastName, N''), m.LastName),
        Photo        = COALESCE(NULLIF(k.Photo, N''), m.Photo),
        HomeKennelId = COALESCE(k.HomeKennelId, m.HomeKennelId),
        updatedAt    = SYSDATETIMEOFFSET()
    FROM HC.Hasher k CROSS JOIN HC.Hasher m
    WHERE k.id = @keep AND m.id = @merge;

    -- ── Disable the merged account ─────────────────────────────────────
    -- As hcapp_gdprDelete: a new secret and SignedOutAt on every device (the
    -- app wipes itself on its next call), push tokens cleared, then
    -- Removed = 1 (hcapp_authorizeDevice refuses a removed account).
    DECLARE @devId UNIQUEIDENTIFIER, @binaryData VARBINARY(MAX), @newSecret NVARCHAR(150), @devices INT = 0;
    DECLARE devs CURSOR LOCAL FAST_FORWARD FOR
        SELECT id FROM HC.Device WHERE UserId = @merge;
    OPEN devs;
    FETCH NEXT FROM devs INTO @devId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @binaryData = CRYPT_GEN_RANDOM(150);
        SELECT @newSecret = LEFT(UPPER(REPLACE(REPLACE(
            CAST('' AS XML).value('xs:base64Binary(sql:variable("@binaryData"))', 'varchar(max)'),
            '+', ''), '/', '')), 75);
        UPDATE HC.Device
           SET DeviceSecret = @newSecret,
               SignedOutAt  = COALESCE(SignedOutAt, SYSDATETIMEOFFSET()),
               FcmToken     = NULL,
               ApnsToken    = NULL,
               removed      = 1,
               updatedAt    = GETDATE()
         WHERE id = @devId;
        SET @devices += 1;
        FETCH NEXT FROM devs INTO @devId;
    END
    CLOSE devs;
    DEALLOCATE devs;
    INSERT @n VALUES ('devicesSignedOut', @devices);

    UPDATE HC.KennelCredit SET removed = 1, currentBalance = 0 WHERE userId = @merge;

    UPDATE HC.Hasher SET
        Removed              = 1,
        -- The column default; a trigger may mint a fresh code, which is
        -- harmless: sign-in and invite codes refuse a removed account.
        ResetCode            = N'######',
        ResetCodeLastUpdated = NULL,
        updatedAt            = SYSDATETIMEOFFSET()
    WHERE id = @merge;

    -- ── Recalculate what is derived from runs and payments ─────────────
    EXEC HC6.nonApi_updateRunCountsByUser @userId = @keep;
    EXEC HC6.nonApi_updateKennelCreditByUser @userId = @keep;

    DECLARE @summary NVARCHAR(4000) = (SELECT Item, N FROM @n FOR JSON PATH);
    INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp])
    VALUES (@procName,
            N'Merged hasher ' + CAST(@merge AS NVARCHAR(36)) + N' into ' + CAST(@keep AS NVARCHAR(36)),
            N'by ' + CAST(@callerId AS NVARCHAR(36)),
            @summary, SYSDATETIMEOFFSET());

    COMMIT TRANSACTION;

    SELECT 1 AS Success, NULL AS ErrorMessage;
    SELECT
        MAX(CASE WHEN Item = 'runsMoved' THEN N END)          AS RunsMoved,
        MAX(CASE WHEN Item = 'runsCombined' THEN N END)       AS RunsCombined,
        MAX(CASE WHEN Item = 'paymentsMoved' THEN N END)      AS PaymentsMoved,
        MAX(CASE WHEN Item = 'kennelsMoved' THEN N END)       AS KennelsMoved,
        MAX(CASE WHEN Item = 'kennelsCombined' THEN N END)    AS KennelsCombined,
        MAX(CASE WHEN Item = 'chatMessagesMoved' THEN N END)  AS ChatMessagesMoved,
        MAX(CASE WHEN Item = 'photosMoved' THEN N END)        AS PhotosMoved,
        MAX(CASE WHEN Item = 'devicesSignedOut' THEN N END)   AS DevicesSignedOut
    FROM @n;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_mergeHashers',
            ERROR_MESSAGE(), @procName, @callerId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
