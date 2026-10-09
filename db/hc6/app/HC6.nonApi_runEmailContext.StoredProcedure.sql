CREATE OR ALTER PROCEDURE [HC6].[nonApi_runEmailContext]

    @eventId           UNIQUEIDENTIFIER = NULL,
    @userId            UNIQUEIDENTIFIER = NULL,
    @includeRecipients SMALLINT         = 0

AS
-- =====================================================================
-- Procedure: HC6.nonApi_runEmailContext
-- Description: The ONE place the run-email send list and context are
--   built (E9.F6.S9). Called by hcapp_getRunEmailContext (app device
--   auth) and hcportal_getRunEmailContext (portal auth) after each has
--   authenticated the caller and checked they may edit runs for the
--   kennel — so the rule cannot drift between the two clients.
--
--   The send list follows the app's email-alert dialog EXACTLY
--   (James, 2026-10-09; EnumEmailAlertState 0 = use kennel setting,
--   1 = on, 2 = off):
--     run setting 1            -> send, whatever the kennel says
--     run setting 2            -> never
--     run setting 0 or no row  -> kennel setting 1 sends; 0 or 2 does not
--   Removed accounts and accounts without an email never. The sender IS
--   included when they qualify.
-- Parameters: @eventId, @userId (the sender), @includeRecipients
-- Returns:
--   rowset 0 — the run + kennel + sender (see hcapp_getRunEmailContext)
--   rowset 1 — emailSendCount, emailLastSentAt, emailLastSentCount,
--              recipientCount
--   rowset 2 — (only when @includeRecipients = 1) hasherId, email,
--              displayName
-- Author: Harrier Central
-- Created: 2026-10-09
-- =====================================================================
SET NOCOUNT ON;

DECLARE @kennelId UNIQUEIDENTIFIER = (SELECT e.KennelId FROM HC.Event e WHERE e.id = @eventId);

DECLARE @recipients TABLE (hasherId UNIQUEIDENTIFIER PRIMARY KEY, email NVARCHAR(250), displayName NVARCHAR(500));
INSERT @recipients (hasherId, email, displayName)
SELECT h.id, h.Email, h.DisplayName
FROM HC.HasherKennelMap hkm
JOIN HC.Hasher h ON h.id = hkm.UserId
LEFT JOIN HC.HasherEventMap hem ON hem.EventId = @eventId AND hem.UserId = hkm.UserId
WHERE hkm.KennelId = @kennelId
  AND hkm.removed = 0
  AND ISNULL(h.Removed, 0) = 0
  AND h.deleted = 0
  AND h.Email LIKE '%_@_%.__%'
  AND (   ISNULL(hem.EventEmailAlertPreference, 0) = 1
       OR (ISNULL(hem.EventEmailAlertPreference, 0) = 0 AND hkm.KennelEmailAlertPreference = 1));

-- rowset 0: the run
SELECT
    LOWER(CAST(e.id AS NVARCHAR(40)))            AS eventId,
    e.EventNumber                                AS eventNumber,
    e.EventName                                  AS eventName,
    e.IsCountedRun                               AS isCountedRun,
    LOWER(CAST(e.PublicEventId AS NVARCHAR(40))) AS publicEventId,
    e.EventStartLocal                            AS startLocal,
    e.Hares                                      AS hares,
    e.LocationOneLineDesc                        AS venue,
    e.SyncLocationStreet                         AS street,
    e.SyncLocationCity                           AS city,
    e.SyncLocationPostCode                       AS postCode,
    e.SyncDescription                            AS description,
    COALESCE(e.EventPriceForMembers,    k.DefaultEventPriceForMembers)    AS priceMembers,
    COALESCE(e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers) AS priceNonMembers,
    k.CurrencySymbol                             AS currencySymbol,
    LOWER(CAST(k.id AS NVARCHAR(40)))            AS kennelId,
    k.KennelName                                 AS kennelName,
    k.KennelShortName                            AS kennelShortName,
    k.KennelUniqueShortName                      AS kennelSlug,
    k.KennelLogo                                 AS kennelLogo,
    s.DisplayName                                AS senderName,
    k.RunEmailInstruction                        AS instruction
FROM HC.Event e
JOIN HC.Kennel k ON k.id = e.KennelId
JOIN HC.Hasher s ON s.id = @userId
WHERE e.id = @eventId;

-- rowset 1: history and reach
SELECT
    e.EmailSendCount                     AS emailSendCount,
    e.EmailLastSentAt                    AS emailLastSentAt,
    e.EmailLastSentCount                 AS emailLastSentCount,
    (SELECT COUNT(*) FROM @recipients)   AS recipientCount
FROM HC.Event e
WHERE e.id = @eventId;

-- rowset 2: who
IF (@includeRecipients = 1)
    SELECT LOWER(CAST(hasherId AS NVARCHAR(40))) AS hasherId, email, displayName
    FROM @recipients
    ORDER BY displayName;
