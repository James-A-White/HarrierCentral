CREATE OR ALTER PROCEDURE [HC6].[hcportal_getKennelRequests]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @status      SMALLINT         = 1
AS
-- =====================================================================
-- Procedure: HC6.hcportal_getKennelRequests
-- Description: The kennel request review queue (E12.F1.S5). Lists the
--   requests in EXT.OfficeForms_KennelImport with one RequestStatus, newest
--   first, with the location resolved to names and two warnings worked out
--   for the reviewer:
--     * SimilarKennels — live kennels whose short name or name matches the
--       request (anywhere, the same short name in the same country first),
--       so a duplicate or a re-submission is visible before approving;
--     * ExistingHashName — the account that already holds the requester's
--       email, which approval will make the kennel's admin instead of
--       creating a new one.
--   Replaces EXT.vwOfficeForms_KennelImport as read by the HC3W web app.
--   Requires an HC.PlatformAdmin row with CanEditKennel.
-- Parameters: @deviceId, @accessToken (auth);
--   @status — 0 awaiting email · 1 new · 2 approved · 3 rejected · 4 spam ·
--             5 duplicate. The closed statuses return the newest 200 only.
-- Returns:
--   On auth failure: rowset 0 — { Success = 0, ErrorMessage }.
--   On success: rowset 0 — the requests (one row each, see contract);
--               rowset 1 — { RequestStatus, RequestCount } for every status,
--               for the page's filter chips.
-- Author: Harrier Central
-- Created: 2026-09-28
-- HC5 Source: none (replaces EXT.vwOfficeForms_KennelImport, HC3W)
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

BEGIN TRY
    SELECT TOP (CASE WHEN @status IN (0, 1) THEN 1000 ELSE 200 END)
        ki.KennelImportId,
        ki.RequestStatus,
        ki.SubmittedOn,
        ki.ConfirmedAt,
        ki.FirstName,
        ki.LastName,
        ki.HashName,
        ki.EmailAddress,
        ki.KennelName,
        ki.KennelShortName,
        ki.KennelDescription,
        ki.KennelUrl,
        ki.KennelFacebookUrl,
        ki.Country,
        ki.Region,
        ki.City,
        ki.CountryId,
        ki.RegionId,
        ki.CityId,
        co.CountryName,
        re.RegionName,
        ci.CityName,
        ki.HashCash,
        ki.NonMemberPrice,
        ki.NumberOfRunsPerMonth,
        ki.NumberOfHashersPerRun,
        ki.nextRunNumber            AS NextRunNumber,
        ki.HowDidYouLearnAboutHc,
        ki.comments                 AS Comments,
        ki.TermsAnswers,
        ki.SubmitIp,
        ki.ReviewNote,
        ki.ReviewedAt,
        rv.HashName                 AS ReviewedByHashName,
        ki.KennelId,
        kn.KennelUniqueShortName    AS ApprovedKennelSlug,
        ex.id                       AS ExistingHasherId,
        ex.HashName                 AS ExistingHashName,
        sim.SimilarKennels
    FROM EXT.OfficeForms_KennelImport ki
    LEFT JOIN HC.Country co ON co.id = ki.CountryId
    LEFT JOIN HC.Region  re ON re.id = ki.RegionId
    LEFT JOIN HC.City    ci ON ci.id = ki.CityId
    LEFT JOIN HC.Hasher  rv ON rv.id = ki.ReviewedBy
    LEFT JOIN HC.Kennel  kn ON kn.id = ki.KennelId
    OUTER APPLY (
        SELECT TOP 1 h.id, h.HashName
        FROM HC.Hasher h
        WHERE h.Email = ki.EmailAddress AND h.Removed = 0
    ) ex
    OUTER APPLY (
        -- Only worked out for the open queue: a closed request's warning
        -- would name the very kennel it created.
        SELECT STRING_AGG(CAST(s.Label AS NVARCHAR(MAX)), N' · ') AS SimilarKennels
        FROM (
            SELECT TOP 5 k.KennelName + N' (' + k.KennelUniqueShortName + N')' AS Label
            FROM HC.Kennel k
            WHERE ki.RequestStatus IN (0, 1)
              AND k.deleted = 0 AND k.removed = 0
              AND (k.KennelShortName = ki.KennelShortName
                   OR k.KennelUniqueShortName = ki.KennelShortName
                   OR k.KennelName = ki.KennelName)
            ORDER BY CASE WHEN k.CountryId = ki.CountryId THEN 0 ELSE 1 END, k.KennelName
        ) s
    ) sim
    WHERE ki.RequestStatus = @status
    ORDER BY ki.SubmittedOn DESC;

    SELECT RequestStatus, COUNT(*) AS RequestCount
    FROM EXT.OfficeForms_KennelImport
    GROUP BY RequestStatus
    ORDER BY RequestStatus;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_getKennelRequests',
            ERROR_MESSAGE(), @procName, @callerId);
    THROW;
END CATCH
GO
