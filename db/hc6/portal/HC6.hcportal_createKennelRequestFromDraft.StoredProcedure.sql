CREATE OR ALTER PROCEDURE [HC6].[hcportal_createKennelRequestFromDraft]
    @deviceId          UNIQUEIDENTIFIER = NULL,
    @accessToken       NVARCHAR(1000)   = NULL,
    @kennelName        NVARCHAR(MAX)    = NULL,
    @kennelShortName   NVARCHAR(MAX)    = NULL,
    @kennelDescription NVARCHAR(MAX)    = NULL,
    @kennelUrl         NVARCHAR(MAX)    = NULL,
    @kennelFacebookUrl NVARCHAR(MAX)    = NULL,
    @countryId         UNIQUEIDENTIFIER = NULL,
    @regionId          UNIQUEIDENTIFIER = NULL,
    @cityId            UNIQUEIDENTIFIER = NULL,
    @countryText       NVARCHAR(MAX)    = NULL,
    @regionText        NVARCHAR(MAX)    = NULL,
    @cityText          NVARCHAR(MAX)    = NULL,
    @hashCash          NVARCHAR(MAX)    = NULL,
    @nonMemberPrice    NVARCHAR(MAX)    = NULL,
    @firstName         NVARCHAR(MAX)    = NULL,
    @lastName          NVARCHAR(MAX)    = NULL,
    @hashName          NVARCHAR(MAX)    = NULL,
    @emailAddress      NVARCHAR(MAX)    = NULL,
    @logoUrl           NVARCHAR(MAX)    = NULL,
    @foundedOn         NVARCHAR(MAX)    = NULL,
    @runDayOfWeek      SMALLINT         = NULL,
    @runStartTime      NVARCHAR(MAX)    = NULL,
    @runsPageUrl       NVARCHAR(MAX)    = NULL,
    @socialLinksJson   NVARCHAR(MAX)    = NULL,
    @sourceJson        NVARCHAR(MAX)    = NULL,
    @comments          NVARCHAR(MAX)    = NULL,
    -- 2026-10-14 (idempotency audit P4): minted by the portal ONCE per draft
    -- page. NULL = the old behaviour (a new id every call).
    @kennelImportId    UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcportal_createKennelRequestFromDraft
-- Idempotency: client-id — @kennelImportId minted once per draft page; a repeat returns it, nothing inserted.
-- Description: "New kennel from a website" (E12.F1.S10, James 2026-10-10):
--   a platform admin has had the AI read a club's website and chatted in
--   what it lacked; Next turns that draft into an ordinary kennel request
--   (status 1 — new, confirmed: a platform admin made it), which then opens
--   in the request review page and is approved there as any other
--   (hcportal_approveKennelRequest). Nothing outside the request table is
--   written. Called by the KennelFromWebsite API, which has already copied
--   the chosen logo into our blob storage.
--   Fields the draft lacks are stored empty (the table's NOT NULL columns),
--   and the review page's Approve says what is still needed.
--   Requires an HC.PlatformAdmin row with CanEditKennel.
-- Parameters: @deviceId, @accessToken (auth); the draft. User text arrives
--   NVARCHAR(MAX) and is checked against the column widths with LEN.
--   @foundedOn 'yyyy' | 'yyyy-mm' | 'yyyy-mm-dd'; @runDayOfWeek 1 Mon … 7
--   Sun; @runStartTime 'HH:mm'; @socialLinksJson as HC6.SocialLinksProblem;
--   @sourceJson { field: "the words on the site it came from", … }.
-- Returns:
--   rowset 0 — { Success, ErrorMessage }
--   rowset 1 (success only) — { KennelImportId }
-- Idempotent writes ("creates a row", 2026-10-14, idempotency audit P4):
--   the portal mints @kennelImportId once per draft page and sends it on
--   every Save. Found WITH (UPDLOCK, HOLDLOCK) inside the transaction =>
--   a repeat after a lost reply: success with that id, nothing written (the
--   API's logo copy is keyed on the same id, so it is not redone either).
--   An id held by a request that is not a website draft is refused.
-- Author: Harrier Central
-- Created: 2026-10-10
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

SET @kennelName        = NULLIF(TRIM(@kennelName), N'');
SET @kennelShortName   = NULLIF(TRIM(@kennelShortName), N'');
SET @kennelDescription = NULLIF(TRIM(@kennelDescription), N'');
SET @kennelUrl         = NULLIF(TRIM(@kennelUrl), N'');
SET @kennelFacebookUrl = NULLIF(TRIM(@kennelFacebookUrl), N'');
SET @countryText       = NULLIF(TRIM(@countryText), N'');
SET @regionText        = NULLIF(TRIM(@regionText), N'');
SET @cityText          = NULLIF(TRIM(@cityText), N'');
SET @hashCash          = NULLIF(TRIM(@hashCash), N'');
SET @nonMemberPrice    = NULLIF(TRIM(@nonMemberPrice), N'');
SET @firstName         = NULLIF(TRIM(@firstName), N'');
SET @lastName          = NULLIF(TRIM(@lastName), N'');
SET @hashName          = NULLIF(TRIM(@hashName), N'');
SET @emailAddress      = NULLIF(LOWER(TRIM(@emailAddress)), N'');
SET @logoUrl           = NULLIF(TRIM(@logoUrl), N'');
SET @foundedOn         = NULLIF(TRIM(@foundedOn), N'');
SET @runStartTime      = NULLIF(TRIM(@runStartTime), N'');
SET @runsPageUrl       = NULLIF(TRIM(@runsPageUrl), N'');
SET @socialLinksJson   = NULLIF(TRIM(@socialLinksJson), N'');
SET @sourceJson        = NULLIF(TRIM(@sourceJson), N'');
SET @comments          = NULLIF(TRIM(@comments), N'');

-- Every refusal before anything is written (no transaction to roll back).
DECLARE @invalid NVARCHAR(400) = CASE
    WHEN @kennelName IS NULL                       THEN 'The kennel needs a name'
    WHEN LEN(@kennelName) > 250                    THEN 'The kennel name may be at most 250 characters'
    WHEN LEN(ISNULL(@kennelShortName, N'')) > 250  THEN 'The short name is too long'
    WHEN LEN(ISNULL(@kennelDescription, N'')) > 4000 THEN 'The description may be at most 4,000 characters'
    WHEN LEN(ISNULL(@kennelUrl, N'')) > 250        THEN 'The website address may be at most 250 characters'
    WHEN LEN(ISNULL(@kennelFacebookUrl, N'')) > 250 THEN 'The Facebook address may be at most 250 characters'
    WHEN LEN(ISNULL(@hashCash, N'')) > 50 OR LEN(ISNULL(@nonMemberPrice, N'')) > 50
                                                   THEN 'A run fee may be at most 50 characters'
    WHEN LEN(ISNULL(@firstName, N'')) > 250 OR LEN(ISNULL(@lastName, N'')) > 250 OR LEN(ISNULL(@hashName, N'')) > 250
                                                   THEN 'A name may be at most 250 characters'
    WHEN LEN(ISNULL(@emailAddress, N'')) > 250     THEN 'The email may be at most 250 characters'
    WHEN @emailAddress IS NOT NULL AND @emailAddress NOT LIKE N'%_@_%._%'
                                                   THEN 'That email address does not look right'
    WHEN LEN(ISNULL(@logoUrl, N'')) > 1000 OR LEN(ISNULL(@runsPageUrl, N'')) > 1000
                                                   THEN 'An address may be at most 1,000 characters'
    WHEN @logoUrl IS NOT NULL AND @logoUrl NOT LIKE N'https://%' THEN 'The logo must be an https address'
    WHEN @runsPageUrl IS NOT NULL AND @runsPageUrl NOT LIKE N'http%://%' THEN 'The runs page must be a web address'
    WHEN @foundedOn IS NOT NULL AND NOT (
            (LEN(@foundedOn) = 4  AND @foundedOn LIKE N'[12][0-9][0-9][0-9]')
         OR (LEN(@foundedOn) = 7  AND TRY_CAST(@foundedOn + N'-01' AS DATE) IS NOT NULL)
         OR (LEN(@foundedOn) = 10 AND TRY_CAST(@foundedOn AS DATE) IS NOT NULL))
                                                   THEN 'Founded must be a year, year-month or full date'
    WHEN @runDayOfWeek IS NOT NULL AND @runDayOfWeek NOT BETWEEN 1 AND 7
                                                   THEN 'The run day must be 1 (Monday) to 7 (Sunday)'
    WHEN @runStartTime IS NOT NULL AND TRY_CAST(@runStartTime AS TIME(0)) IS NULL
                                                   THEN 'The start time must be HH:mm'
    WHEN @sourceJson IS NOT NULL AND ISJSON(@sourceJson) = 0 THEN 'sourceJson is not JSON'
    WHEN @comments IS NOT NULL AND LEN(@comments) > 4000 THEN 'The notes may be at most 4,000 characters'
    ELSE HC6.SocialLinksProblem(@socialLinksJson) END;

IF (@invalid IS NOT NULL)
BEGIN
    SELECT 0 AS Success, @invalid AS ErrorMessage;
    RETURN;
END

-- The place names come from our own rows when the ids are given.
IF (@cityId IS NOT NULL)
    SELECT @cityText = ci.CityName, @regionId = re.id, @regionText = re.RegionName,
           @countryId = co.id, @countryText = co.CountryName
    FROM HC.City ci JOIN HC.Region re ON re.id = ci.RegionId JOIN HC.Country co ON co.id = re.CountryId
    WHERE ci.id = @cityId;
ELSE IF (@countryId IS NOT NULL)
    SELECT @countryText = co.CountryName FROM HC.Country co WHERE co.id = @countryId;

BEGIN TRY
    DECLARE @requestId UNIQUEIDENTIFIER = COALESCE(@kennelImportId, NEWID());
    DECLARE @callerEmail NVARCHAR(250) = (SELECT h.Email FROM HC.Hasher h WHERE h.id = @callerId);

    BEGIN TRANSACTION;

    IF (@kennelImportId IS NOT NULL)
    BEGIN
        DECLARE @existingSource NVARCHAR(20);
        DECLARE @found SMALLINT = 0;
        SELECT @found = 1, @existingSource = ki.RequestSource
        FROM EXT.OfficeForms_KennelImport ki WITH (UPDLOCK, HOLDLOCK)
        WHERE ki.KennelImportId = @kennelImportId;

        IF (@found = 1)
        BEGIN
            IF (ISNULL(@existingSource, N'') <> N'website')
            BEGIN
                ROLLBACK TRANSACTION;
                SELECT 0 AS Success, 'kennelImportId is already in use' AS ErrorMessage;
                RETURN;
            END
            -- A repeat of a Save that already committed: the same answer.
            COMMIT TRANSACTION;
            SELECT 1 AS Success, NULL AS ErrorMessage;
            SELECT LOWER(CAST(@requestId AS NVARCHAR(40))) AS KennelImportId;
            RETURN;
        END
    END

    INSERT EXT.OfficeForms_KennelImport
        (KennelImportId, FirstName, LastName, HashName, NameToUse, EmailAddress, IsKennelAdmin,
         KennelName, KennelShortName, KennelUrl, KennelDescription,
         Country, CountryId, Region, RegionId, City, CityId,
         HashCash, NonMemberPrice, KennelFacebookUrl, SubmitterEmail, SubmittedOn,
         comments, HashRunsDotOrg, HowDidYouLearnAboutHc,
         RequestStatus, ConfirmAttempts, ConfirmedAt,
         LogoUrl, FoundedOn, RunDayOfWeek, RunStartTime, RunsPageUrl,
         SocialLinksJson, SourceJson, RequestSource, updatedAt)
    VALUES
        (@requestId, COALESCE(@firstName, N''), COALESCE(@lastName, N''), COALESCE(@hashName, N''),
         N'My Hash Name', COALESCE(@emailAddress, N''), N'Yes',
         @kennelName, COALESCE(@kennelShortName, N''), @kennelUrl, COALESCE(@kennelDescription, N''),
         LEFT(COALESCE(@countryText, N''), 50), @countryId, LEFT(@regionText, 50), @regionId,
         LEFT(COALESCE(@cityText, N''), 50), @cityId,
         COALESCE(@hashCash, N''), @nonMemberPrice, @kennelFacebookUrl, @callerEmail, GETDATE(),
         @comments, N'Yes', N'Platform admin: New kennel from a website',
         1, 0, SYSDATETIMEOFFSET(),
         @logoUrl, @foundedOn, @runDayOfWeek, TRY_CAST(@runStartTime AS TIME(0)), @runsPageUrl,
         @socialLinksJson, @sourceJson, N'website', GETDATE());

    COMMIT TRANSACTION;

    SELECT 1 AS Success, NULL AS ErrorMessage;
    SELECT LOWER(CAST(@requestId AS NVARCHAR(40))) AS KennelImportId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<portal>', 'Unhandled error in hcportal_createKennelRequestFromDraft',
            ERROR_MESSAGE(), @procName, @callerId);
    SELECT 0 AS Success, 'The request could not be saved. Please try again.' AS ErrorMessage;
END CATCH
GO
