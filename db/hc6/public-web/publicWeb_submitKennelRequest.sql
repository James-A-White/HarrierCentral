CREATE OR ALTER PROCEDURE [HC6].[publicWeb_submitKennelRequest]
    @firstName         NVARCHAR(MAX)    = NULL,
    @lastName          NVARCHAR(MAX)    = NULL,
    @hashName          NVARCHAR(MAX)    = NULL,
    @email             NVARCHAR(MAX)    = NULL,
    @kennelName        NVARCHAR(MAX)    = NULL,
    @kennelShortName   NVARCHAR(MAX)    = NULL,
    @kennelDescription NVARCHAR(MAX)    = NULL,
    @kennelUrl         NVARCHAR(MAX)    = NULL,
    @kennelFacebookUrl NVARCHAR(MAX)    = NULL,
    @countryId         UNIQUEIDENTIFIER = NULL,
    @regionId          UNIQUEIDENTIFIER = NULL,
    @cityId            UNIQUEIDENTIFIER = NULL,
    @cityText          NVARCHAR(MAX)    = NULL,
    @runsPerMonth      NVARCHAR(MAX)    = NULL,
    @hashersPerRun     NVARCHAR(MAX)    = NULL,
    @hashCash          NVARCHAR(MAX)    = NULL,
    @nextRunNumber     NVARCHAR(MAX)    = NULL,
    @howDidYouLearn    NVARCHAR(MAX)    = NULL,
    @comments          NVARCHAR(MAX)    = NULL,
    @submitIp          NVARCHAR(MAX)    = NULL,
    -- The three required opt-in questions of the old harriercentral.com form
    -- (tc_1..tc_3), asked again and now kept (2026-09-28): the answer text.
    @terms1            NVARCHAR(MAX)    = NULL,
    @terms2            NVARCHAR(MAX)    = NULL,
    @terms3            NVARCHAR(MAX)    = NULL
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_submitKennelRequest
-- Description: The hashruns.org/add-kennel form (E12.F1.S7). Stores a
--              request to add a kennel as RequestStatus 0 (awaiting email)
--              with a six-digit confirmation code; the request reaches the
--              review queue only when the code comes back
--              (publicWeb_confirmKennelRequest). The code is emailed by the
--              API (PublicWebAdminApi side effect), which strips it from
--              the reply — so it never reaches the web server's response,
--              let alone the browser.
--              Replaces EXT.ImportNewKennel, which took the whole form as
--              one NVARCHAR(4000) JSON string (two of its fields could
--              each be 4000 long — silent truncation) and guessed the
--              location with a cursor and LIKE.
--              Guards, in order: required fields and widths (LEN against
--              the column, never a silent cut); the location must exist
--              and agree; five requests per IP a day; the same email and
--              short name within 30 days is the same request, and gets its
--              code again instead of a second row.
--              Reachable only through PublicWebAdminApi behind
--              HC_INTERNAL_SECRET (the Next.js server route adds the
--              honeypot, time-to-submit and per-IP limits in front).
-- Parameters:  the form's fields, including the three required opt-in
--              answers (@terms1..3, kept in TermsAnswers); the location is picked from the
--              database (@countryId, @regionId, @cityId) or, when the city
--              is not listed, @cityText for the reviewer to resolve.
-- Returns:     rowset 0 — { success, errorCode, errorType };
--              rowset 1 — on error: { errorId, errorType, errorCode,
--                errorTitle, errorUserMessage, errorProc };
--                on success: { requestId, email, firstName, kennelName,
--                confirmCode, alreadySubmitted }. confirmCode is removed
--                by the API after the email is sent.
-- Author:      Harrier Central
-- Created:     2026-09-28
-- HC5 Source:  none (replaces EXT.ImportNewKennel + EXT.ProcessKennelImports)
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);

SET @firstName         = TRIM(@firstName);
SET @lastName          = TRIM(@lastName);
SET @hashName          = NULLIF(TRIM(@hashName), N'');
SET @email             = LOWER(TRIM(@email));
SET @kennelName        = TRIM(@kennelName);
SET @kennelShortName   = UPPER(TRIM(@kennelShortName));
SET @kennelDescription = TRIM(@kennelDescription);
SET @kennelUrl         = NULLIF(TRIM(@kennelUrl), N'');
SET @kennelFacebookUrl = NULLIF(TRIM(@kennelFacebookUrl), N'');
SET @cityText          = NULLIF(TRIM(@cityText), N'');
SET @runsPerMonth      = NULLIF(TRIM(@runsPerMonth), N'');
SET @hashersPerRun     = NULLIF(TRIM(@hashersPerRun), N'');
SET @hashCash          = NULLIF(TRIM(@hashCash), N'');
SET @nextRunNumber     = NULLIF(TRIM(@nextRunNumber), N'');
SET @howDidYouLearn    = NULLIF(TRIM(@howDidYouLearn), N'');
SET @comments          = NULLIF(TRIM(@comments), N'');
SET @submitIp          = LEFT(NULLIF(TRIM(@submitIp), N''), 64);
SET @terms1            = NULLIF(TRIM(@terms1), N'');
SET @terms2            = NULLIF(TRIM(@terms2), N'');
SET @terms3            = NULLIF(TRIM(@terms3), N'');

-- ── Validation (before any transaction: nothing to roll back) ──────────
DECLARE @errorCode INT, @message NVARCHAR(500);
SELECT @errorCode = v.code, @message = v.msg
FROM (SELECT TOP 1 code, msg FROM (VALUES
    (1, 1710, CASE WHEN LEN(COALESCE(@firstName, N'')) = 0 OR LEN(COALESCE(@lastName, N'')) = 0
                   THEN N'Please give your first and last name.' END),
    (2, 1711, CASE WHEN LEN(@firstName) > 250 OR LEN(@lastName) > 250 OR LEN(@hashName) > 250
                   THEN N'Names may be at most 250 characters.' END),
    (3, 1712, CASE WHEN LEN(COALESCE(@email, N'')) = 0 OR LEN(@email) > 250
                        OR @email NOT LIKE N'%_@_%._%' OR @email LIKE N'% %'
                   THEN N'Please give a valid email address — we send a code to it.' END),
    (4, 1713, CASE WHEN LEN(COALESCE(@kennelName, N'')) = 0 OR LEN(@kennelName) > 250
                   THEN N'Please give the kennel''s name (at most 250 characters).' END),
    (5, 1714, CASE WHEN LEN(COALESCE(@kennelShortName, N'')) = 0 OR LEN(@kennelShortName) > 20
                        OR @kennelShortName COLLATE Latin1_General_BIN LIKE N'%[^A-Z0-9]%'
                   THEN N'The short name is letters and digits only, up to 20 — for example LH3. It becomes your web address.' END),
    (6, 1715, CASE WHEN LEN(COALESCE(@kennelDescription, N'')) = 0 OR LEN(@kennelDescription) > 4000
                   THEN N'Please describe the kennel (at most 4000 characters).' END),
    (7, 1716, CASE WHEN LEN(@kennelUrl) > 250 OR LEN(@kennelFacebookUrl) > 250
                   THEN N'Links may be at most 250 characters.' END),
    (8, 1717, CASE WHEN @countryId IS NULL OR NOT EXISTS (SELECT 1 FROM HC.Country c WHERE c.id = @countryId)
                   THEN N'Please choose the country.' END),
    (9, 1718, CASE WHEN @regionId IS NOT NULL AND NOT EXISTS
                        (SELECT 1 FROM HC.Region r WHERE r.id = @regionId AND r.CountryId = @countryId)
                   THEN N'That region is not in the chosen country.' END),
    (10, 1719, CASE WHEN @cityId IS NOT NULL AND NOT EXISTS
                        (SELECT 1 FROM HC.City c WHERE c.id = @cityId AND c.RegionId = @regionId)
                   THEN N'That city is not in the chosen region.' END),
    (11, 1720, CASE WHEN @cityId IS NULL AND (LEN(COALESCE(@cityText, N'')) = 0 OR LEN(@cityText) > 50)
                   THEN N'Please choose the city, or type it if it is not listed (at most 50 characters).' END),
    (12, 1721, CASE WHEN LEN(@runsPerMonth) > 50 OR LEN(@hashersPerRun) > 50 OR LEN(@hashCash) > 50
                        OR LEN(@nextRunNumber) > 250
                   THEN N'One of the answers is too long.' END),
    (13, 1722, CASE WHEN LEN(@howDidYouLearn) > 4000 OR LEN(@comments) > 4000
                   THEN N'Comments may be at most 4000 characters.' END),
    (14, 1724, CASE WHEN @terms1 IS NULL OR @terms2 IS NULL OR @terms3 IS NULL
                   THEN N'Please answer the three questions at the end of the form.' END),
    (15, 1725, CASE WHEN LEN(@terms1) > 300 OR LEN(@terms2) > 300 OR LEN(@terms3) > 300
                   THEN N'One of the answers is too long.' END)
) AS c(ord, code, msg) WHERE msg IS NOT NULL ORDER BY ord) v;

IF (@errorCode IS NULL
    AND @submitIp IS NOT NULL
    AND (SELECT COUNT(*) FROM EXT.OfficeForms_KennelImport ki
         WHERE ki.SubmitIp = @submitIp AND ki.SubmittedOn > DATEADD(day, -1, GETDATE())) >= 5)
    SELECT @errorCode = 1723,
           @message = N'Too many requests from your network today. Please try again tomorrow.';

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT 0 AS success, @errorCode AS errorCode, 2 AS errorType;
    SELECT NEWID() AS errorId, 2 AS errorType, @errorCode AS errorCode,
           N'Please check the form' AS errorTitle, @message AS errorUserMessage,
           @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @code NVARCHAR(10) =
        RIGHT(N'000000' + CAST(ABS(CHECKSUM(NEWID())) % 1000000 AS NVARCHAR(7)), 6);

    -- The same person asking for the same kennel again (a lost email, a
    -- double submit) is the same request: a fresh code on the open row.
    DECLARE @requestId UNIQUEIDENTIFIER, @existingStatus SMALLINT;
    SELECT TOP 1 @requestId = ki.KennelImportId, @existingStatus = ki.RequestStatus
    FROM EXT.OfficeForms_KennelImport ki WITH (UPDLOCK, HOLDLOCK)
    WHERE ki.EmailAddress = @email
      AND ki.KennelShortName = @kennelShortName
      AND ki.SubmittedOn > DATEADD(day, -30, GETDATE())
      AND ki.RequestStatus IN (0, 1)
    ORDER BY ki.SubmittedOn DESC;

    IF (@requestId IS NOT NULL)
    BEGIN
        IF (@existingStatus = 0)
            UPDATE EXT.OfficeForms_KennelImport
               SET ConfirmCode = @code, ConfirmAttempts = 0, updatedAt = GETDATE()
             WHERE KennelImportId = @requestId;

        COMMIT TRANSACTION;
        SELECT 1 AS success, 0 AS errorCode, 0 AS errorType;
        SELECT @requestId AS requestId, @email AS email, @firstName AS firstName,
               @kennelName AS kennelName,
               CASE WHEN @existingStatus = 0 THEN @code END AS confirmCode,
               1 AS alreadySubmitted;
        RETURN;
    END

    SET @requestId = NEWID();

    INSERT EXT.OfficeForms_KennelImport
        (KennelImportId, FirstName, LastName, HashName, NameToUse, EmailAddress, IsKennelAdmin,
         KennelName, KennelShortName, KennelUrl, KennelDescription, KennelPinColor,
         NumberOfRunsPerMonth, NumberOfHashersPerRun,
         Country, CountryId, Region, RegionId, City, CityId,
         HashCash, KennelFacebookUrl, SubmitterEmail, SubmittedOn,
         nextRunNumber, comments, HashRunsDotOrg, HowDidYouLearnAboutHc,
         RequestStatus, ConfirmCode, ConfirmAttempts, SubmitIp, TermsAnswers, updatedAt)
    SELECT
        @requestId, @firstName, @lastName, COALESCE(@hashName, N''), N'My Hash Name', @email, N'Yes',
        @kennelName, @kennelShortName, @kennelUrl, @kennelDescription, N'Blue',
        COALESCE(@runsPerMonth, N'Unknown'), COALESCE(@hashersPerRun, N'Unknown'),
        LEFT(co.CountryName, 50), @countryId, LEFT(re.RegionName, 50), @regionId,
        COALESCE(LEFT(ci.CityName, 50), @cityText), @cityId,
        COALESCE(@hashCash, N''), @kennelFacebookUrl, @email, GETDATE(),
        @nextRunNumber, @comments, N'Yes', @howDidYouLearn,
        0, @code, 0, @submitIp,
        LEFT(N'1: ' + @terms1 + N' | 2: ' + @terms2 + N' | 3: ' + @terms3, 1000),
        GETDATE()
    FROM HC.Country co
    LEFT JOIN HC.Region re ON re.id = @regionId
    LEFT JOIN HC.City   ci ON ci.id = @cityId
    WHERE co.id = @countryId;

    COMMIT TRANSACTION;

    SELECT 1 AS success, 0 AS errorCode, 0 AS errorType;
    SELECT @requestId AS requestId, @email AS email, @firstName AS firstName,
           @kennelName AS kennelName, @code AS confirmCode, 0 AS alreadySubmitted;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @errorId UNIQUEIDENTIFIER = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<web>', 'Unhandled error in publicWeb_submitKennelRequest',
            ERROR_MESSAGE(), @procName, NULL);
    SELECT 0 AS success, 1729 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 1729 AS errorCode,
           N'Something went wrong' AS errorTitle,
           N'We could not save your request just now. Please try again in a few minutes.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
GO
