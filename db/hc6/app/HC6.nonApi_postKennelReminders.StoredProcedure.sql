CREATE OR ALTER PROCEDURE [HC6].[nonApi_postKennelReminders]
    @force        SMALLINT         = 0,     -- 1: post now, whatever the day and hour (tests)
    @onlyKennelId UNIQUEIDENTIFIER = NULL,  -- one kennel only (tests); NULL = every kennel due
    @dryRun       SMALLINT         = 0      -- 1: return what would be posted, write nothing
AS
-- =====================================================================
-- Procedure: HC6.nonApi_postKennelReminders
-- Description: The weekly reminder in each kennel's private Mismanagement
--   chat (E9.F1.S33, James 2026-10-16, from BT-15 "admins don't get any
--   notifications or reminders that there are photos to be approved").
--   Monday 09:00 London (the API timer runs hourly on Mondays; this decides
--   the hour, so British Summer Time needs nothing), one message per kennel
--   that has something waiting, from the Harrier Central system hasher.
--   A kennel with nothing waiting gets nothing: a quiet week sends nothing.
--
--   What is "waiting" (one line each; add a line here, nothing else):
--     - photos to review: HC.KennelPhotos Status 1, with the count and the
--       oldest upload's date, and a link —
--       https://www.hashruns.org/<slug>/review-photos — that the app (1482+)
--       opens on the kennel's Review photos screen; the web explains it.
--
--   Only kennels with at least one Mismanagement member get a post — the
--   thread has nobody to read it otherwise.
--
--   Called by the API's weekly timer (KennelRemindersTimer), which then
--   pushes each NEW message through HC6.nonApi_kennelMessagePush and the
--   shim's kennel-chat push code. Not callable from any client.
-- Parameters: see above.
-- Returns: rowset 0 — one row per kennel due
--   { MessageId, KennelId, KennelShortName, MessageContent, AlreadyPosted }
--   AlreadyPosted 1 = this week's reminder for that kennel was already
--   there (a rerun): the caller must NOT push it again.
-- Author: Harrier Central
-- Created: 2026-10-16
-- HC5 Source: none
-- Breaking Changes: none (new)
-- Idempotency: send-id — the message id is derived from (kennel, ISO week); a rerun finds it and posts nothing
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
-- The Harrier Central system hasher (db/hc6/archive/2026-10-16_system_hashers_and_hctest_roles.sql).
DECLARE @senderId UNIQUEIDENTIFIER = 'A7C0E6F2-5B1D-4C8E-9F3A-0D2B6E4C1A01';
DECLARE @messageType INT = HC6.KennelThreadMessageType(1);

BEGIN TRY
    DECLARE @london DATETIMEOFFSET(7) = SYSDATETIMEOFFSET() AT TIME ZONE 'GMT Standard Time';
    -- DATEPART(weekday) depends on DATEFIRST; the name does not.
    IF (COALESCE(@force, 0) = 0
        AND NOT (DATENAME(WEEKDAY, @london) = 'Monday' AND DATEPART(HOUR, @london) = 9))
    BEGIN
        SELECT CAST(NULL AS UNIQUEIDENTIFIER) AS MessageId, CAST(NULL AS UNIQUEIDENTIFIER) AS KennelId,
               CAST(NULL AS NVARCHAR(25)) AS KennelShortName, CAST(NULL AS NVARCHAR(4000)) AS MessageContent,
               CAST(NULL AS SMALLINT) AS AlreadyPosted
        WHERE 1 = 0;
        RETURN;
    END

    DECLARE @senderPublicId UNIQUEIDENTIFIER =
        (SELECT h.PublicHasherId FROM HC.Hasher h WHERE h.id = @senderId AND h.Removed = 0);
    IF (@senderPublicId IS NULL)
        THROW 51990, 'nonApi_postKennelReminders: the Harrier Central system hasher is missing', 1;

    -- The week this reminder belongs to: ISO week of the London date, with
    -- its ISO year (the Thursday rule), so 29 Dec 2025 is 2026-W01.
    DECLARE @day DATE = CAST(@london AS DATE);
    DECLARE @isoWeek INT = DATEPART(ISO_WEEK, @day);
    DECLARE @isoYear INT = YEAR(DATEADD(DAY, 26 - @isoWeek, @day));
    DECLARE @weekKey NVARCHAR(10) = CONCAT(@isoYear, N'-W', RIGHT(CONCAT(N'0', @isoWeek), 2));

    -- What is waiting, per kennel.
    SELECT k.id AS KennelId, k.PublicKennelId, k.KennelShortName,
           LOWER(k.KennelUniqueShortName) AS Slug,
           p.N AS PhotoCount, p.Oldest AS PhotoOldest
    INTO #due
    FROM HC.Kennel k
    CROSS APPLY (SELECT COUNT(*) AS N, MIN(kp.createdAt) AS Oldest
                 FROM HC.KennelPhotos kp
                 WHERE kp.KennelId = k.id AND kp.Status = 1) p
    WHERE k.Removed = 0
      AND (@onlyKennelId IS NULL OR k.id = @onlyKennelId)
      AND p.N > 0
      AND EXISTS (SELECT 1 FROM HC.HasherKennelMap hkm
                  WHERE hkm.KennelId = k.id AND hkm.removed = 0
                    AND (ISNULL(hkm.MismanagementRoles, 0) <> 0 OR ISNULL(hkm.AppAccessFlags, 0) <> 0));

    SELECT d.*,
           -- A GUID from (kennel, week): the send id. The same week reruns to
           -- the same id, so the existence check below finds it.
           CAST(HASHBYTES('MD5', CONCAT(N'kennel-reminder:', CAST(d.KennelId AS NVARCHAR(40)), N':', @weekKey))
                AS UNIQUEIDENTIFIER) AS MessageId,
           CONCAT(N'Weekly reminder from Harrier Central',
                  NCHAR(10), NCHAR(10),
                  N'📷 ', d.PhotoCount, CASE WHEN d.PhotoCount = 1 THEN N' photo is' ELSE N' photos are' END,
                  N' waiting for review, the oldest since ', FORMAT(d.PhotoOldest, 'd MMM yyyy', 'en-GB'), N'.',
                  NCHAR(10), NCHAR(10),
                  -- A link the app opens on the kennel's Review photos
                  -- screen, tapped in the chat or anywhere else (2026-10-16);
                  -- without the app, the web page says where to go.
                  N'Review them: https://www.hashruns.org/', d.Slug, N'/review-photos') AS MessageContent
    INTO #posts
    FROM #due d;

    IF (COALESCE(@dryRun, 0) = 1)
    BEGIN
        SELECT p.MessageId, p.KennelId, p.KennelShortName, p.MessageContent,
               CAST(CASE WHEN EXISTS (SELECT 1 FROM HC.EventMessage em WHERE em.id = p.MessageId)
                         THEN 1 ELSE 0 END AS SMALLINT) AS AlreadyPosted
        FROM #posts p ORDER BY p.KennelShortName;
        RETURN;
    END

    DECLARE @results TABLE (MessageId UNIQUEIDENTIFIER, KennelId UNIQUEIDENTIFIER,
                            KennelShortName NVARCHAR(25), MessageContent NVARCHAR(4000), AlreadyPosted SMALLINT);

    DECLARE @mid UNIQUEIDENTIFIER, @kid UNIQUEIDENTIFIER, @pkid UNIQUEIDENTIFIER,
            @short NVARCHAR(25), @content NVARCHAR(4000), @already SMALLINT;
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR
        SELECT MessageId, KennelId, PublicKennelId, KennelShortName, MessageContent FROM #posts;
    OPEN c;
    FETCH NEXT FROM c INTO @mid, @kid, @pkid, @short, @content;
    WHILE (@@FETCH_STATUS = 0)
    BEGIN
        -- One kennel per transaction: one kennel's failure leaves the others posted.
        BEGIN TRANSACTION;
        SET @already = CASE WHEN EXISTS (SELECT 1 FROM HC.EventMessage WITH (UPDLOCK, HOLDLOCK)
                                         WHERE id = @mid) THEN 1 ELSE 0 END;
        IF (@already = 0)
            INSERT HC.EventMessage
                (id, KennelId, PublicKennelId, UserId, PublicHasherId, MessageTitle, MessageContent,
                 MessageReleasabilityFlags, MessageKind, MessageType)
            VALUES
                (@mid, @kid, @pkid, @senderId, @senderPublicId, N'', @content, 63, 0, @messageType);
        COMMIT TRANSACTION;
        INSERT @results VALUES (@mid, @kid, @short, @content, @already);
        FETCH NEXT FROM c INTO @mid, @kid, @pkid, @short, @content;
    END
    CLOSE c; DEALLOCATE c;

    INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, Timestamp)
    VALUES ('HC6.nonApi_postKennelReminders', 'Weekly kennel reminders', @weekKey,
            CONCAT('posted=', (SELECT COUNT(*) FROM @results WHERE AlreadyPosted = 0),
                   ' already=', (SELECT COUNT(*) FROM @results WHERE AlreadyPosted = 1)),
            SYSDATETIMEOFFSET());

    SELECT MessageId, KennelId, KennelShortName, MessageContent, AlreadyPosted
    FROM @results ORDER BY KennelShortName;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), 'api timer', 'Unhandled error in nonApi_postKennelReminders',
            ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
GO
