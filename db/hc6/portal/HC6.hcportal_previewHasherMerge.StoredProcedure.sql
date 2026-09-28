CREATE OR ALTER PROCEDURE [HC6].[hcportal_previewHasherMerge]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @keepEmail   NVARCHAR(MAX)    = NULL,
    @mergeEmail  NVARCHAR(MAX)    = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcportal_previewHasherMerge
-- Description: The first half of merging two accounts that belong to one
--   person (E12.F6.S1): finds both, and shows what each holds and where they
--   overlap, so the platform admin can see what the merge will do before
--   hcportal_mergeHashers does it. Reads only.
--   Each account is found by its email address, or by its hasher id /
--   PublicHasherId pasted in the same box (an account a kennel admin added
--   often has no email at all). Only live accounts (Removed = 0) are found.
--   Requires an HC.PlatformAdmin row with CanEditKennel.
-- Parameters: @deviceId, @accessToken (auth);
--   @keepEmail  — the account that stays;
--   @mergeEmail — the account whose history moves across and which is then
--                 disabled.
-- Returns:
--   On refusal: rowset 0 — { Success = 0, ErrorMessage }.
--   On success: rowset 0 — two rows, Role 'keep' then 'merge' (see contract);
--               rowset 1 — one row of overlaps between the two.
-- Author: Harrier Central
-- Created: 2026-09-28
-- HC5 Source: none (replaces HC3.utilApi_mergeUsers, which had no preview)
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

SET @keepEmail  = LOWER(TRIM(@keepEmail));
SET @mergeEmail = LOWER(TRIM(@mergeEmail));

DECLARE @keepId UNIQUEIDENTIFIER, @mergeId UNIQUEIDENTIFIER, @keepN INT, @mergeN INT;

-- An id pasted instead of an email finds the account by id or PublicHasherId.
SELECT @keepN = COUNT(*), @keepId = MIN(CAST(h.id AS NVARCHAR(36)))
FROM HC.Hasher h
WHERE h.Removed = 0 AND LEN(COALESCE(@keepEmail, N'')) > 0
  AND (h.Email = @keepEmail
       OR h.id = TRY_CAST(@keepEmail AS UNIQUEIDENTIFIER)
       OR h.PublicHasherId = TRY_CAST(@keepEmail AS UNIQUEIDENTIFIER));
SELECT @mergeN = COUNT(*), @mergeId = MIN(CAST(h.id AS NVARCHAR(36)))
FROM HC.Hasher h
WHERE h.Removed = 0 AND LEN(COALESCE(@mergeEmail, N'')) > 0
  AND (h.Email = @mergeEmail
       OR h.id = TRY_CAST(@mergeEmail AS UNIQUEIDENTIFIER)
       OR h.PublicHasherId = TRY_CAST(@mergeEmail AS UNIQUEIDENTIFIER));

DECLARE @refusal NVARCHAR(500) = CASE
    WHEN LEN(COALESCE(@keepEmail, N'')) = 0 OR LEN(COALESCE(@mergeEmail, N'')) = 0
        THEN 'Enter the email of the account to keep and of the account to merge into it'
    WHEN @keepN = 0  THEN 'No active account has the email ' + @keepEmail
    WHEN @mergeN = 0 THEN 'No active account has the email ' + @mergeEmail
    WHEN @keepN > 1  THEN 'More than one active account has the email ' + @keepEmail + ' — paste its hasher id instead'
    WHEN @mergeN > 1 THEN 'More than one active account has the email ' + @mergeEmail + ' — paste its hasher id instead'
    WHEN @keepId = @mergeId THEN 'Both boxes name the same account'
    ELSE NULL END;

IF (@refusal IS NOT NULL)
BEGIN
    SELECT 0 AS Success, @refusal AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    -- ── rowset 0: the two accounts ─────────────────────────────────────
    SELECT
        a.Role,
        h.id                                  AS HasherId,
        h.PublicHasherId,
        h.HashName,
        h.FirstName,
        h.LastName,
        h.Email,
        hk.KennelName                         AS HomeKennelName,
        h.createdAt                           AS CreatedAt,
        h.LastLoginDateTime,
        (SELECT COUNT(*) FROM HC.Device d
          WHERE d.UserId = h.id AND d.SignedOutAt IS NULL)                         AS SignedInDevices,
        (SELECT COUNT(*) FROM HC.HasherKennelMap m
          WHERE m.UserId = h.id AND m.removed = 0 AND m.Following = 1)            AS KennelsFollowed,
        (SELECT COUNT(*) FROM HC.HasherKennelMap m
          WHERE m.UserId = h.id AND m.removed = 0 AND m.IsMember = 1)             AS KennelsMember,
        (SELECT COUNT(*) FROM HC.HasherKennelMap m
          WHERE m.UserId = h.id AND m.removed = 0 AND (m.AppAccessFlags & 1) <> 0) AS KennelsAdmin,
        -- AttendenceState >= 20 means attended (at the hash).
        (SELECT COUNT(*) FROM HC.HasherEventMap e
          WHERE e.UserId = h.id AND e.removed = 0 AND e.AttendenceState >= 20)    AS RunsAttended,
        (SELECT COUNT(*) FROM HC.HasherEventMap e
          WHERE e.UserId = h.id AND e.removed = 0 AND e.AttendenceState >= 20 AND e.IsHare = 1) AS RunsHared,
        (SELECT COUNT(*) FROM HC.HasherEventMap e
          WHERE e.UserId = h.id AND e.removed = 0)                                  AS RunRows,
        (SELECT MAX(ev.EventStartLocal) FROM HC.HasherEventMap e
           JOIN HC.Event ev ON ev.id = e.EventId
          WHERE e.UserId = h.id AND e.removed = 0 AND e.AttendenceState >= 20)    AS LastRunLocal,
        (SELECT COUNT(*) FROM HC.HasherEventMap e
          WHERE e.UserId = h.id AND e.removed = 0 AND e.TrackPointCount > 0)      AS Tracks,
        (SELECT COUNT(*) FROM HC.Payment p
          WHERE p.UserId = h.id AND p.CancelledBy_UserId IS NULL)                  AS Payments,
        (SELECT COALESCE(SUM(p.NetPayment), 0) FROM HC.Payment p
          WHERE p.UserId = h.id AND p.CancelledBy_UserId IS NULL)                  AS PaymentsTotal,
        (SELECT COALESCE(SUM(kc.currentBalance), 0) FROM HC.KennelCredit kc
          WHERE kc.userId = h.id AND kc.removed = 0)                               AS CreditTotal,
        (SELECT COUNT(*) FROM HC.EventMessage em WHERE em.UserId = h.id)          AS ChatMessages,
        (SELECT COUNT(*) FROM HC.KennelPhotos kp WHERE kp.UserId = h.id)          AS Photos,
        CAST(CASE WHEN EXISTS (SELECT 1 FROM HC.PlatformAdmin pa
                               WHERE pa.UserId = h.id AND pa.removed = 0)
                  THEN 1 ELSE 0 END AS SMALLINT)                                  AS IsPlatformAdmin
    FROM (VALUES (1, 'keep', @keepId), (2, 'merge', @mergeId)) a(ord, Role, id)
    JOIN HC.Hasher h ON h.id = a.id
    LEFT JOIN HC.Kennel hk ON hk.id = h.HomeKennelId
    ORDER BY a.ord;

    -- ── rowset 1: where they overlap ───────────────────────────────────
    -- A run both accounts have a row for is combined into one; a run both
    -- PAID for keeps both payments (money is never deleted) and is listed
    -- so the kennel can refund one.
    SELECT
        (SELECT COUNT(*) FROM HC.HasherEventMap k
           JOIN HC.HasherEventMap m ON m.EventId = k.EventId
                AND COALESCE(m.DisplayName, N'') = COALESCE(k.DisplayName, N'')
          WHERE k.UserId = @keepId AND m.UserId = @mergeId
            AND k.removed = 0 AND m.removed = 0)                                  AS SharedRuns,
        (SELECT COUNT(*) FROM HC.HasherEventMap k
           JOIN HC.HasherEventMap m ON m.EventId = k.EventId
                AND COALESCE(m.DisplayName, N'') = COALESCE(k.DisplayName, N'')
          WHERE k.UserId = @keepId AND m.UserId = @mergeId
            AND k.removed = 0 AND m.removed = 0
            AND k.AttendenceState >= 20 AND m.AttendenceState >= 20)             AS SharedRunsBothAttended,
        (SELECT COUNT(*) FROM HC.HasherKennelMap k
           JOIN HC.HasherKennelMap m ON m.KennelId = k.KennelId
          WHERE k.UserId = @keepId AND m.UserId = @mergeId
            AND k.removed = 0 AND m.removed = 0)                                  AS SharedKennels,
        (SELECT COUNT(DISTINCT pk.EventId) FROM HC.Payment pk
           JOIN HC.Payment pm ON pm.EventId = pk.EventId
          WHERE pk.UserId = @keepId AND pm.UserId = @mergeId
            AND pk.EventId IS NOT NULL
            AND pk.CancelledBy_UserId IS NULL AND pm.CancelledBy_UserId IS NULL
            AND pk.NetPayment <> 0 AND pm.NetPayment <> 0)                        AS RunsBothPaid,
        (SELECT STRING_AGG(CAST(x.Label AS NVARCHAR(MAX)), N' · ')
           FROM (SELECT DISTINCT TOP 10 kn.KennelShortName + N' ' + CONVERT(NVARCHAR(10), ev.EventStartLocal, 23) AS Label
                   FROM HC.Payment pk
                   JOIN HC.Payment pm ON pm.EventId = pk.EventId
                   JOIN HC.Event ev ON ev.id = pk.EventId
                   JOIN HC.Kennel kn ON kn.id = ev.KennelId
                  WHERE pk.UserId = @keepId AND pm.UserId = @mergeId
                    AND pk.CancelledBy_UserId IS NULL AND pm.CancelledBy_UserId IS NULL
                    AND pk.NetPayment <> 0 AND pm.NetPayment <> 0) x)             AS RunsBothPaidList,
        -- What the kept account holds AFTER the merge (the portal's Result
        -- column, James 2026-09-28). A run both accounts have under the same
        -- name becomes one row with the stronger attendance and either's
        -- hare flag; a kennel both have becomes one with the flags OR-ed —
        -- the same rules hcportal_mergeHashers applies.
        (SELECT COUNT(*) FROM (
            SELECT MAX(e.AttendenceState) AS Att
            FROM HC.HasherEventMap e
            WHERE e.UserId IN (@keepId, @mergeId) AND e.removed = 0
            GROUP BY e.EventId, COALESCE(e.DisplayName, N'')) r
          WHERE r.Att >= 20)                                                      AS AfterRunsAttended,
        (SELECT COUNT(*) FROM (
            SELECT MAX(e.AttendenceState) AS Att, MAX(CAST(e.IsHare AS INT)) AS Hare
            FROM HC.HasherEventMap e
            WHERE e.UserId IN (@keepId, @mergeId) AND e.removed = 0
            GROUP BY e.EventId, COALESCE(e.DisplayName, N'')) r
          WHERE r.Att >= 20 AND r.Hare = 1)                                       AS AfterRunsHared,
        (SELECT COUNT(*) FROM (
            SELECT MAX(CAST(m.Following AS INT)) AS F
            FROM HC.HasherKennelMap m
            WHERE m.UserId IN (@keepId, @mergeId) AND m.removed = 0
            GROUP BY m.KennelId) x WHERE x.F = 1)                                 AS AfterKennelsFollowed,
        (SELECT COUNT(*) FROM (
            SELECT MAX(CAST(m.IsMember AS INT)) AS M
            FROM HC.HasherKennelMap m
            WHERE m.UserId IN (@keepId, @mergeId) AND m.removed = 0
            GROUP BY m.KennelId) x WHERE x.M = 1)                                 AS AfterKennelsMember,
        (SELECT COUNT(*) FROM (
            SELECT MAX(COALESCE(m.AppAccessFlags, 0) & 1) AS A
            FROM HC.HasherKennelMap m
            WHERE m.UserId IN (@keepId, @mergeId) AND m.removed = 0
            GROUP BY m.KennelId) x WHERE x.A = 1)                                 AS AfterKennelsAdmin;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_previewHasherMerge',
            ERROR_MESSAGE(), @procName, @callerId);
    THROW;
END CATCH
GO
