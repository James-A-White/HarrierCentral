CREATE OR ALTER PROCEDURE [HC6].[nonApi_recordInviteEmailed]
    @kennelId   UNIQUEIDENTIFIER = NULL,
    @adminId    UNIQUEIDENTIFIER = NULL,
    @hasherIds  NVARCHAR(MAX)    = NULL,  -- '|'-separated HC.Hasher ids
    -- 2026-10-14 (idempotency audit P3). NULL = the old behaviour: stamp
    -- every id now, unconditionally, and log the send. See the header.
    @mode       NVARCHAR(10)     = NULL,  -- NULL | 'claim' | 'release' | 'log'
    @recentDays INT              = 7,     -- claim: the "invited lately" window
    @claimedAt  DATETIMEOFFSET(7) = NULL, -- release: the stamp the claim wrote
    @previousAt DATETIMEOFFSET(7) = NULL  -- release: the value it replaced
AS
-- =====================================================================
-- Procedure: HC6.nonApi_recordInviteEmailed
-- Idempotency: compare-and-set — 'claim' stamps InviteEmailedAt only where NULL or older than the window, before the send; a failed send releases it.
-- Description: Stamps HC.Hasher.InviteEmailedAt for the hashers an "Email
--   invite codes" send reaches (E2.F2.S6), so the next send skips anyone
--   invited in the last 7 days. Called by the InviteEmails API endpoint.
--   Never touches updatedAt (the Hasher triggers fire only on updatedAt /
--   name / photo / removed), so nothing re-syncs.
--
--   Idempotent writes, "sends something" (2026-10-14, idempotency audit P3):
--   the stamp is the send's record and is taken BEFORE the send, so two
--   overlapping sends (two tabs, two admins) cannot both email one hasher,
--   and a crash between send and stamp cannot re-email on the next press.
--     @mode = 'claim'   compare-and-set, WITH (UPDLOCK, HOLDLOCK): stamps
--                       now ONLY where InviteEmailedAt is NULL or older than
--                       @recentDays days (the API passes its own 7-day
--                       window, so the rule lives in one place). Rowset 1
--                       lists the rows actually claimed; the API sends to
--                       those and no others.
--     @mode = 'release' a send that failed gives its claim back: one id,
--                       InviteEmailedAt reset to @previousAt, and only while
--                       it still holds @claimedAt (nobody re-claimed it).
--     @mode = 'log'     one LOG.GeneralLog row for a round; stamps nothing.
--     @mode = NULL      the pre-2026-10-14 call: stamp all now, log.
-- Returns: rowset 0 { Success, ErrorMessage, stamped }.
--   claim only: rowset 1 { hasherId, previousAt, claimedAt }, one per
--   claimed row.
-- Author: Harrier Central
-- Created: 2026-10-10
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    IF (@hasherIds IS NULL OR LEN(@hasherIds) = 0)
    BEGIN
        SELECT 1 AS Success, NULL AS ErrorMessage, 0 AS stamped;
        IF (@mode = 'claim')
            SELECT CAST(NULL AS UNIQUEIDENTIFIER) AS hasherId,
                   CAST(NULL AS DATETIMEOFFSET(7)) AS previousAt,
                   CAST(NULL AS DATETIMEOFFSET(7)) AS claimedAt
            WHERE 1 = 0;
        RETURN;
    END

    DECLARE @n INT = 0;
    DECLARE @now DATETIMEOFFSET(7) = SYSDATETIMEOFFSET();

    IF (@mode = 'claim')
    BEGIN
        DECLARE @claimed TABLE (hasherId UNIQUEIDENTIFIER, previousAt DATETIMEOFFSET(7), claimedAt DATETIMEOFFSET(7));
        DECLARE @cutoff DATETIMEOFFSET(7) = DATEADD(DAY, -COALESCE(@recentDays, 7), @now);

        BEGIN TRANSACTION;
        UPDATE h SET h.InviteEmailedAt = @now
        OUTPUT inserted.id, deleted.InviteEmailedAt, inserted.InviteEmailedAt
          INTO @claimed (hasherId, previousAt, claimedAt)
        FROM HC.Hasher h WITH (UPDLOCK, HOLDLOCK)
        WHERE h.id IN (SELECT TRY_CAST(LTRIM(RTRIM(value)) AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@hasherIds, '|'))
          AND (h.InviteEmailedAt IS NULL OR h.InviteEmailedAt < @cutoff);
        SET @n = @@ROWCOUNT;
        COMMIT TRANSACTION;

        SELECT 1 AS Success, NULL AS ErrorMessage, @n AS stamped;
        SELECT hasherId, previousAt, claimedAt FROM @claimed;
        RETURN;
    END

    IF (@mode = 'release')
    BEGIN
        -- One id; only a claim still in place is given back.
        BEGIN TRANSACTION;
        UPDATE h SET h.InviteEmailedAt = @previousAt
        FROM HC.Hasher h WITH (UPDLOCK, HOLDLOCK)
        WHERE h.id = TRY_CAST(LTRIM(RTRIM(@hasherIds)) AS UNIQUEIDENTIFIER)
          AND @claimedAt IS NOT NULL
          AND h.InviteEmailedAt = @claimedAt;
        SET @n = @@ROWCOUNT;
        COMMIT TRANSACTION;

        SELECT 1 AS Success, NULL AS ErrorMessage, @n AS stamped;
        RETURN;
    END

    BEGIN TRANSACTION;
    IF (@mode IS NULL)
    BEGIN
        UPDATE h SET h.InviteEmailedAt = @now
        FROM HC.Hasher h
        WHERE h.id IN (SELECT TRY_CAST(LTRIM(RTRIM(value)) AS UNIQUEIDENTIFIER) FROM STRING_SPLIT(@hasherIds, '|'));
        SET @n = @@ROWCOUNT;
    END
    ELSE
        -- 'log': the rows were stamped by their claims; count the list.
        SELECT @n = COUNT(*) FROM STRING_SPLIT(@hasherIds, '|')
        WHERE TRY_CAST(LTRIM(RTRIM(value)) AS UNIQUEIDENTIFIER) IS NOT NULL;

    INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp])
    VALUES ('InviteEmail', 'Invite codes emailed', LOWER(CAST(@kennelId AS NVARCHAR(40))),
            CONCAT('{"admin":"', LOWER(CAST(@adminId AS NVARCHAR(40))), '","sent":', @n, '}'), @now);
    COMMIT TRANSACTION;

    SELECT 1 AS Success, NULL AS ErrorMessage, CASE WHEN @mode IS NULL THEN @n ELSE 0 END AS stamped;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (NEWID(), '<api>', 'Unhandled error in recordInviteEmailed', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), @adminId, @kennelId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage, 0 AS stamped;
END CATCH
