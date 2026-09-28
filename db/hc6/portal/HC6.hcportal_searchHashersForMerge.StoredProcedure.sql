CREATE OR ALTER PROCEDURE [HC6].[hcportal_searchHashersForMerge]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @searchTerms NVARCHAR(MAX)    = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcportal_searchHashersForMerge
-- Description: Finds the accounts a platform admin may want to merge
--   (E12.F6.S3): every live account whose hash name matches one of the
--   terms, so duplicates are found by the name hashers actually know rather
--   than by email addresses nobody has (James, 2026-09-28). A term may also
--   be an email address or a hasher id / PublicHasherId, for an account
--   whose hash name is blank or misspelt.
--   Hash names match whole, ignoring case and surrounding spaces ("Smartarse"
--   finds "Smartarse " too). Each row carries what tells two records of one
--   person apart: email, kennels followed, when the app was last used, run
--   counts and where the last three runs were.
--   Requires an HC.PlatformAdmin row with CanEditKennel.
-- Parameters: @deviceId, @accessToken (auth);
--   @searchTerms — '|'-delimited hash names / emails / ids (the portal turns
--   the admin's comma-separated list into '|'). At most 20 terms.
-- Returns:
--   On refusal: rowset 0 — { Success = 0, ErrorMessage }.
--   On success: rowset 0 — one row per account, at most 200 (see contract).
-- Author: Harrier Central
-- Created: 2026-09-28
-- HC5 Source: none (new)
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

DECLARE @terms TABLE (Term NVARCHAR(250) PRIMARY KEY);
INSERT @terms (Term)
SELECT DISTINCT TOP 20 LEFT(TRIM(s.value), 250)
FROM STRING_SPLIT(COALESCE(@searchTerms, N''), '|') s
WHERE LEN(TRIM(s.value)) > 0;

IF NOT EXISTS (SELECT 1 FROM @terms)
BEGIN
    SELECT 0 AS Success, 'Enter one or more hash names, separated by commas' AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    ;WITH hits AS (
        SELECT DISTINCT h.id, t.Term
        FROM @terms t
        JOIN HC.Hasher h
          ON h.Removed = 0
         AND (   TRIM(h.HashName) = t.Term
              OR (t.Term LIKE N'%_@_%' AND h.Email = t.Term)
              OR h.id = TRY_CAST(t.Term AS UNIQUEIDENTIFIER)
              OR h.PublicHasherId = TRY_CAST(t.Term AS UNIQUEIDENTIFIER))
    ),
    people AS (
        SELECT id, STRING_AGG(CAST(Term AS NVARCHAR(MAX)), N', ') AS MatchedOn
        FROM hits GROUP BY id
    )
    SELECT TOP 200
        h.id                         AS HasherId,
        h.HashName,
        h.FirstName,
        h.LastName,
        h.Email,
        p.MatchedOn,
        hk.KennelShortName           AS HomeKennel,
        h.createdAt                  AS CreatedAt,
        -- When the app was last used: the newest device sign-in, else the
        -- account's own last-login stamp.
        COALESCE(dv.LastUsed, h.LastLoginDateTime)                      AS LastAppUse,
        COALESCE(dv.SignedInDevices, 0)                                 AS SignedInDevices,
        (SELECT COUNT(*) FROM HC.HasherKennelMap m
          WHERE m.UserId = h.id AND m.removed = 0 AND m.Following = 1)  AS KennelsFollowed,
        (SELECT STRING_AGG(CAST(x.KennelShortName AS NVARCHAR(MAX)), N', ')
           FROM (SELECT TOP 8 k.KennelShortName
                   FROM HC.HasherKennelMap m JOIN HC.Kennel k ON k.id = m.KennelId
                  WHERE m.UserId = h.id AND m.removed = 0 AND m.Following = 1
                  ORDER BY k.KennelShortName) x)                        AS KennelsFollowedList,
        -- AttendenceState >= 20 means attended.
        (SELECT COUNT(*) FROM HC.HasherEventMap e
          WHERE e.UserId = h.id AND e.removed = 0 AND e.AttendenceState >= 20) AS RunsAttended,
        (SELECT COUNT(*) FROM HC.Payment pay
          WHERE pay.UserId = h.id AND pay.CancelledBy_UserId IS NULL)   AS Payments,
        -- The last three runs attended: kennel, date (local), and where.
        (SELECT STRING_AGG(CAST(r.Label AS NVARCHAR(MAX)), N' · ') WITHIN GROUP (ORDER BY r.StartLocal DESC)
           FROM (SELECT TOP 3 ev.EventStartLocal AS StartLocal,
                        k.KennelShortName + N' ' + CONVERT(NVARCHAR(10), ev.EventStartLocal, 23)
                        + COALESCE(N' (' + NULLIF(TRIM(COALESCE(NULLIF(TRIM(ev.LocationCity), N''),
                                                               ev.LocationOneLineDesc)), N'') + N')', N'') AS Label
                   FROM HC.HasherEventMap e
                   JOIN HC.Event ev ON ev.id = e.EventId
                   JOIN HC.Kennel k ON k.id = ev.KennelId
                  WHERE e.UserId = h.id AND e.removed = 0 AND e.AttendenceState >= 20
                  ORDER BY ev.EventStartLocal DESC) r)                  AS RecentRuns,
        CAST(CASE WHEN EXISTS (SELECT 1 FROM HC.PlatformAdmin pa
                               WHERE pa.UserId = h.id AND pa.removed = 0)
                  THEN 1 ELSE 0 END AS SMALLINT)                       AS IsPlatformAdmin
    FROM people p
    JOIN HC.Hasher h ON h.id = p.id
    LEFT JOIN HC.Kennel hk ON hk.id = h.HomeKennelId
    OUTER APPLY (
        SELECT MAX(d.LastLogin) AS LastUsed,
               SUM(CASE WHEN d.SignedOutAt IS NULL AND d.removed = 0 THEN 1 ELSE 0 END) AS SignedInDevices
        FROM HC.Device d WHERE d.UserId = h.id
    ) dv
    ORDER BY TRIM(h.HashName), COALESCE(dv.LastUsed, h.LastLoginDateTime) DESC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_searchHashersForMerge',
            ERROR_MESSAGE(), @procName, @callerId);
    THROW;
END CATCH
GO
