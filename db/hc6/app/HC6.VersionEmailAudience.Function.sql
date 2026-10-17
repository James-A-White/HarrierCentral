CREATE OR ALTER FUNCTION [HC6].[VersionEmailAudience]
(
    @builds NVARCHAR(MAX),
    @days   INT
)
RETURNS TABLE
AS
-- =====================================================================
-- Function: HC6.VersionEmailAudience
-- Description: The people the version email (E19.F3.S3) would reach for
--   these builds, each with whether they WILL be sent it and, if not, why.
--   The ONE rule both hcportal_getVersionEmailRecipients (what the page
--   lists) and hcportal_queueVersionEmail (what is queued) read, so the
--   page can never promise a different list from the one that is sent.
--   Left out entirely: removed / deleted hashers. Listed but not sent:
--     - a generated address (HC6.IsGeneratedEmail — reaches nobody)
--     - the hasher blocked all email from us (EmailBlocked)
--     - the address bounces (EmailStatus 3)
--     - this person was sent a version email (EmailKind 2) in the last
--       30 days, queued or sent (James, 2026-10-17). The 30 days belong
--       to THIS kind of email; HC.EmailLog itself has no repeat rule.
-- Parameters:
--   @builds - '|'-delimited build numbers (e.g. '1040|1041')
--   @days   - last sign-in within this many days (HC6.AppVersionUsers)
-- Returns: { userId, publicHasherId, name, firstName, email, build,
--   version, isIos, isAndroid, lastLogin, lastVersionEmailAt, eligible,
--   reason } — one row per person.
-- Author: Harrier Central
-- Created: 2026-10-17
-- =====================================================================
RETURN
    SELECT u.userId,
           h.PublicHasherId                                     AS publicHasherId,
           h.DisplayName                                        AS name,
           COALESCE(NULLIF(LTRIM(RTRIM(h.FirstName)), ''),
                    NULLIF(LTRIM(RTRIM(h.HashName)), ''), '')   AS firstName,
           h.Email                                              AS email,
           u.build, u.version, u.isIos, u.isAndroid, u.lastLogin,
           sent.lastAt                                          AS lastVersionEmailAt,
           CAST(CASE WHEN g.isGen = 1 OR h.EmailBlocked = 1 OR h.EmailStatus = 3
                       OR sent.lastAt >= DATEADD(DAY, -30, SYSDATETIMEOFFSET())
                     THEN 0 ELSE 1 END AS SMALLINT)             AS eligible,
           CASE WHEN g.isGen = 1          THEN 'Generated address'
                WHEN h.EmailBlocked = 1   THEN 'Blocked all email'
                WHEN h.EmailStatus = 3    THEN 'Email bouncing'
                WHEN sent.lastAt >= DATEADD(DAY, -30, SYSDATETIMEOFFSET())
                                          THEN 'Emailed in the last 30 days'
                ELSE NULL END                                   AS reason
    FROM HC6.AppVersionUsers(@days) u
    JOIN STRING_SPLIT(@builds, '|') b ON TRY_CAST(b.value AS INT) = u.build
    JOIN HC.Hasher h ON h.id = u.userId
    CROSS APPLY (SELECT CAST(HC6.IsGeneratedEmail(h.Email) AS SMALLINT) AS isGen) g
    OUTER APPLY (SELECT MAX(l.DateSent) AS lastAt
                 FROM HC.EmailLog l
                 WHERE l.EmailKind = 2 AND l.UserId = u.userId
                   AND l.Status IN (0, 1, 3)) sent
    WHERE ISNULL(h.Removed, 0) = 0 AND h.deleted = 0;
