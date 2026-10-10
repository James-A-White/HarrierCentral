CREATE OR ALTER PROCEDURE [HC6].[nonApi_runEmailContext]

    @eventId           UNIQUEIDENTIFIER = NULL,
    @userId            UNIQUEIDENTIFIER = NULL,
    @includeRecipients SMALLINT         = 0,
    @callerMaySeeEmails SMALLINT        = 0

AS
-- =====================================================================
-- Procedure: HC6.nonApi_runEmailContext
-- Description: The ONE place the run-email send list and context are
--   built (E9.F6.S9). Called by hcapp_getRunEmailContext (app device
--   auth) and hcportal_getRunEmailContext (portal auth) after each has
--   authenticated the caller and checked they may edit runs for the
--   kennel — so the rule cannot drift between the two clients.
--
--   Who gets it (James, 2026-10-09, evening — replaces the morning's
--   "kennel setting must be ON" rule): an OPT-IN and no OPT-OUT.
--     Opt-ins:  a current MEMBER of the kennel (MembershipExpirationDate in
--               the future), a FOLLOWER (HasherKennelMap.Following = 1), an
--               RSVP of Yes/Maybe to THIS run (visitors with no kennel row
--               included), or email explicitly switched ON for the run or
--               the kennel. "Never chose a setting" (0) is NOT a no.
--     Opt-outs: run emails OFF (EventEmailAlertPreference 2) beats
--               everything; kennel emails OFF (KennelEmailAlertPreference 2)
--               beats every opt-in except run ON (1). Blocked all email
--               (HC.Hasher.EmailBlocked) is the member's unsubscribe and
--               beats every preference and every admin override. A bouncing
--               address (EmailStatus 3) and no/invalid address are never
--               sent to. Removed accounts never. The sender IS included when
--               they qualify.
--   Rows carry a reasonCode so the clients label and badge without their own
--   logic — gets it: 1 on for this run, 2 on for the kennel, 9 member,
--   10 follower, 11 RSVP'd; does not: 3 run emails off, 4 kennel emails off,
--   5 not a member, follower or RSVP, 6 no email address, 7 blocked all
--   emails, 8 email bouncing. canMove = 1 when an admin may override for one
--   send (never for 6, 7, 8).
-- Parameters: @eventId, @userId (the sender), @includeRecipients:
--   0 = context only; 1 = + recipients; 2 = + recipients AND the kennel
--   members who will NOT get it, with the reason (the audience page).
-- Returns:
--   rowset 0 — the run + kennel + sender (see hcapp_getRunEmailContext)
--   rowset 1 — emailSendCount, emailLastSentAt, emailLastSentCount,
--              recipientCount
--   rowset 2 — (when @includeRecipients >= 1) hasherId, email,
--              displayName — the name as the check-in list shows it:
--              the kennel hash name, else the hasher's display name
--   rowset 3 — (when @includeRecipients = 2) displayName, reason
-- Author: Harrier Central
-- Created: 2026-10-09
-- =====================================================================
SET NOCOUNT ON;

DECLARE @kennelId UNIQUEIDENTIFIER = (SELECT e.KennelId FROM HC.Event e WHERE e.id = @eventId);

-- Everyone with a stake in the run once, classified: every live row for the
-- kennel (members, followers, lapsed) plus anyone with an RSVP row for this
-- run, kennel row or not. @members is the audience page; @recipients is the
-- subset the email goes to.
DECLARE @members TABLE (
    hasherId UNIQUEIDENTIFIER PRIMARY KEY, email NVARCHAR(250), hashName NVARCHAR(500), mortalName NVARCHAR(500),
    photo NVARCHAR(1000), emailStatus SMALLINT, reasonCode SMALLINT, willGet SMALLINT, canMove SMALLINT);
INSERT @members (hasherId, email, hashName, mortalName, photo, emailStatus, reasonCode, willGet, canMove)
SELECT h.id, h.Email,
       COALESCE(NULLIF(hkm.KennelHashName, ''), h.DisplayName),
       LTRIM(RTRIM(COALESCE(h.FirstName, '') + ' ' + COALESCE(h.LastName, ''))),
       COALESCE(NULLIF(hkm.KennelUserPhoto, ''), h.Photo),
       h.EmailStatus,
       x.reasonCode,
       CASE WHEN x.reasonCode IN (1, 2, 9, 10, 11) THEN 1 ELSE 0 END,
       CASE WHEN x.reasonCode IN (6, 7, 8) THEN 0 ELSE 1 END
FROM (
    SELECT hkm.UserId FROM HC.HasherKennelMap hkm WHERE hkm.KennelId = @kennelId AND hkm.removed = 0
    UNION
    SELECT hem.UserId FROM HC.HasherEventMap hem WHERE hem.EventId = @eventId
) p
JOIN HC.Hasher h ON h.id = p.UserId
LEFT JOIN HC.HasherKennelMap hkm ON hkm.KennelId = @kennelId AND hkm.UserId = p.UserId AND hkm.removed = 0
LEFT JOIN HC.HasherEventMap hem ON hem.EventId = @eventId AND hem.UserId = p.UserId
CROSS APPLY (SELECT CASE
        WHEN h.EmailBlocked = 1                                          THEN 7
        WHEN h.Email NOT LIKE '%_@_%.__%'
          OR HC6.IsGeneratedEmail(h.Email) = 1                           THEN 6   -- no address, or one we made up
        WHEN h.EmailStatus = 3                                           THEN 8
        WHEN ISNULL(hem.EventEmailAlertPreference, 0) = 2                THEN 3   -- run OFF beats everything
        WHEN ISNULL(hem.EventEmailAlertPreference, 0) = 1                THEN 1   -- run ON beats kennel OFF
        WHEN ISNULL(hkm.KennelEmailAlertPreference, 0) = 2               THEN 4   -- kennel OFF beats the opt-ins
        WHEN hkm.KennelEmailAlertPreference = 1                          THEN 2
        WHEN hkm.MembershipExpirationDate > SYSDATETIMEOFFSET()          THEN 9   -- member
        WHEN hkm.Following = 1                                           THEN 10  -- follower
        WHEN hem.RsvpState IN (2, 3)                                     THEN 11  -- RSVP'd Yes/Maybe to this run
        ELSE 5 END AS reasonCode) x
WHERE ISNULL(h.Removed, 0) = 0
  AND h.deleted = 0;

DECLARE @recipients TABLE (hasherId UNIQUEIDENTIFIER PRIMARY KEY, email NVARCHAR(250), displayName NVARCHAR(500));
INSERT @recipients (hasherId, email, displayName)
SELECT hasherId, email, hashName FROM @members WHERE willGet = 1;

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
    e.EventImage                                 AS eventImage,
    COALESCE(e.EventPriceForMembers,    k.DefaultEventPriceForMembers)    AS priceMembers,
    COALESCE(e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers) AS priceNonMembers,
    k.CurrencySymbol                             AS currencySymbol,
    LOWER(CAST(k.id AS NVARCHAR(40)))            AS kennelId,
    k.KennelName                                 AS kennelName,
    k.KennelShortName                            AS kennelShortName,
    k.KennelUniqueShortName                      AS kennelSlug,
    k.KennelLogo                                 AS kennelLogo,
    LOWER(CAST(s.id AS NVARCHAR(40)))            AS senderId,
    s.DisplayName                                AS senderName,
    s.Email                                      AS senderEmail,
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
    (SELECT COUNT(*) FROM @recipients)   AS recipientCount,
    -- Addresses are shown on the audience page only to a kennel admin / hare
    -- raiser, never to a hare who may edit just this run (James, 2026-10-10).
    ISNULL(@callerMaySeeEmails, 0)       AS callerMaySeeEmails
FROM HC.Event e
WHERE e.id = @eventId;

-- rowset 2: who will get it (the send list)
IF (@includeRecipients >= 1)
    SELECT LOWER(CAST(hasherId AS NVARCHAR(40))) AS hasherId, email, hashName AS displayName,
           hashName, mortalName, photo, emailStatus, reasonCode, canMove
    FROM @members WHERE willGet = 1
    ORDER BY LOWER(hashName);

-- rowset 3: who will NOT, and why
IF (@includeRecipients = 2)
    SELECT LOWER(CAST(hasherId AS NVARCHAR(40))) AS hasherId, email, hashName AS displayName,
           hashName, mortalName, photo, emailStatus, reasonCode, canMove
    FROM @members WHERE willGet = 0
    ORDER BY LOWER(hashName);
