CREATE OR ALTER PROCEDURE [HC6].[hcportal_approveKennelRequest]
    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @kennelImportId UNIQUEIDENTIFIER
AS
-- =====================================================================
-- Procedure: HC6.hcportal_approveKennelRequest
-- Description: Approves a kennel request (E12.F1.S6) and gives the club
--   everything it needs to start the same day:
--     1. HC.Kennel — names, description, links, price, location, a unique
--        short name (the web address), and a default logo: one of the
--        twelve Harrier Central coins as bundle://C-NNN, which the apps and
--        the portal draw with the kennel's short name on it.
--     2. The requester as the kennel's HC admin (AppAccessFlags, the same
--        grant the portal's kennel admins hold). Their account is created
--        if the email has none, exactly as hcapp_addEditUser creates one;
--        an existing account is reused and its home kennel left alone.
--        Mismanagement roles are NOT granted — a club office is the club's
--        to give, and HC admin is an independent grantor (CLAUDE.md).
--     3. Every platform admin with CanEditKennel as a helper admin, so the
--        new club has someone to call. Replaces the hard-coded Tuna Melt
--        row in HC3W.importKennel.
--     4. A compliant invite code on the requester's account; the portal
--        API emails it with the welcome (PortalApiHC6 side effect) and
--        strips it from the reply, so it never reaches the reviewer.
--   The request row is locked (UPDLOCK) for the whole transaction, so a
--   double click cannot make two kennels. Requires an HC.PlatformAdmin row
--   with CanEditKennel.
-- Parameters: @deviceId, @accessToken (auth); @kennelImportId.
-- Returns:
--   rowset 0 — { Success, ErrorMessage }.
--   rowset 1 (success only) — { KennelId, KennelName, KennelUniqueShortName,
--     AdminHasherId, AdminEmail, AdminFirstName, AdminHashName,
--     AdminIsNew, InviteCode }. InviteCode is removed by the API.
-- Author: Harrier Central
-- Created: 2026-09-28
-- HC5 Source: none (replaces HC3W.importKennel)
-- Breaking Changes vs HC3W.importKennel:
--   - No dbo.Users login (and no hard-coded password hash): HC6 sign-in is
--     the emailed invite code.
--   - KennelLogo is chosen at random from the twelve coins (bundle://C-NNN).
--   - Helper admins come from HC.PlatformAdmin, not a hard-coded id.
--   - The requester gets HC admin access only, not every mismanagement role.
--   - Facebook fields are no longer copied (the integration is retired).
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

IF (@kennelImportId IS NULL)
BEGIN
    SELECT 0 AS Success, 'kennelImportId is required' AS ErrorMessage;
    RETURN;
END

-- The HC admin grant the portal's kennel admins hold (410 + 351 of the
-- live admin rows use it), and the web-content permissions with it.
DECLARE @adminAccessFlags INT = 1073741887;
DECLARE @adminWebFlags    INT = 127;
DECLARE @neverExpires     DATETIME = '2100-01-01';

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @status SMALLINT, @kennelName NVARCHAR(250), @shortName NVARCHAR(250),
            @description NVARCHAR(4000), @kennelUrl NVARCHAR(250),
            @countryId UNIQUEIDENTIFIER, @regionId UNIQUEIDENTIFIER, @cityId UNIQUEIDENTIFIER,
            @hashCash NVARCHAR(50), @email NVARCHAR(250), @firstName NVARCHAR(250),
            @lastName NVARCHAR(250), @hashName NVARCHAR(250);

    SELECT @status      = ki.RequestStatus,
           @kennelName  = TRIM(ki.KennelName),
           @shortName   = TRIM(ki.KennelShortName),
           @description = ki.KennelDescription,
           @kennelUrl   = NULLIF(TRIM(ki.KennelUrl), N''),
           @countryId   = ki.CountryId,
           @regionId    = ki.RegionId,
           @cityId      = ki.CityId,
           @hashCash    = ki.HashCash,
           @email       = LOWER(TRIM(ki.EmailAddress)),
           @firstName   = TRIM(ki.FirstName),
           @lastName    = TRIM(ki.LastName),
           @hashName    = TRIM(ki.HashName)
    FROM EXT.OfficeForms_KennelImport ki WITH (UPDLOCK, HOLDLOCK)
    WHERE ki.KennelImportId = @kennelImportId;

    -- Every refusal happens before anything is written; ROLLBACK first
    -- only releases the lock.
    DECLARE @invalid NVARCHAR(500) = CASE
        WHEN @status IS NULL          THEN 'Request not found'
        WHEN @status = 2              THEN 'This request has already been approved'
        WHEN @status NOT IN (0, 1)    THEN 'Only an open request can be approved — reopen it first'
        WHEN LEN(COALESCE(@kennelName, N'')) = 0 THEN 'The kennel needs a name'
        WHEN LEN(COALESCE(@shortName, N'')) = 0 THEN 'The kennel needs a short name'
        WHEN LEN(@shortName) > 20     THEN 'The short name may be at most 20 characters — edit it first'
        WHEN @shortName COLLATE Latin1_General_BIN LIKE '%[^A-Za-z0-9]%'
                                      THEN 'The short name may only hold letters and digits (it becomes the web address) — edit it first'
        WHEN @countryId IS NULL OR @regionId IS NULL OR @cityId IS NULL
                                      THEN 'Pick the country, region and city first'
        WHEN NOT EXISTS (SELECT 1 FROM HC.City c JOIN HC.Region r ON r.id = c.RegionId
                         WHERE c.id = @cityId AND c.RegionId = @regionId AND r.CountryId = @countryId)
                                      THEN 'The city, region and country do not agree — pick them again'
        WHEN @email IS NULL OR @email NOT LIKE '%_@_%._%'
                                      THEN 'The request needs a valid email address for the kennel admin'
        ELSE NULL END;

    IF (@invalid IS NOT NULL)
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success, @invalid AS ErrorMessage;
        RETURN;
    END

    -- ── Unique short name: LH3, else LH3-GB, else LH3-GB1..99 ──────────
    -- (HC3W.importKennel's rule, kept so existing addresses look alike.)
    DECLARE @countryCode NVARCHAR(20) = (SELECT c.CountryCode FROM HC.Country c WHERE c.id = @countryId);
    DECLARE @uniqueShortName NVARCHAR(100);
    DECLARE @n INT = 0;
    DECLARE @candidate NVARCHAR(100) = @shortName;
    WHILE (@uniqueShortName IS NULL AND @n < 100)
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM HC.Kennel k WITH (UPDLOCK, HOLDLOCK)
                       WHERE k.KennelUniqueShortName = @candidate)
            SET @uniqueShortName = @candidate;
        ELSE
        BEGIN
            SET @n += 1;
            SET @candidate = @shortName + N'-' + COALESCE(@countryCode, N'X')
                           + CASE WHEN @n = 1 THEN N'' ELSE CAST(@n - 1 AS NVARCHAR(10)) END;
        END
    END

    IF (@uniqueShortName IS NULL)
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success, 'No free web address for that short name — edit it first' AS ErrorMessage;
        RETURN;
    END

    -- ── 1. The kennel ─────────────────────────────────────────────────
    -- One of the twelve coins C-000 … C-330, as bundle://C-NNN: the value
    -- every app build and the portal draw as the coin WITH THE KENNEL'S
    -- SHORT NAME written on it (KennelLogo), and the one the portal's own
    -- coin picker saves. A plain image URL shows a blank coin (2026-09-28).
    DECLARE @logo NVARCHAR(1000) =
        N'bundle://C-' + RIGHT(N'00' + CAST((ABS(CHECKSUM(NEWID())) % 12) * 30 AS NVARCHAR(3)), 3);

    -- The form's price is free text ("5", "£5", "5 euros"): keep the
    -- number when there is one, else 0 for the admin to set.
    DECLARE @price DECIMAL(10,4) = COALESCE(TRY_CAST(
        NULLIF(TRANSLATE(COALESCE(@hashCash, N''), N'$£€¥', N'    '), N'') AS DECIMAL(10,4)), 0);
    IF (@price < 0 OR @price > 100000) SET @price = 0;

    DECLARE @kennelId UNIQUEIDENTIFIER = NEWID();

    INSERT HC.Kennel
        (id, KennelName, KennelShortName, KennelUniqueShortName, KennelDescription,
         KennelLogo, KennelWebsiteUrl, DefaultEventPriceForMembers, DefaultEventPriceForNonMembers,
         CityId, ProvinceStateId, CountryId, RunCountStartDate, KennelStatus,
         IntegrationType, InboundIntegrationId, DisseminateHashRunsDotOrg, removed, deleted)
    VALUES
        (@kennelId, @kennelName, @shortName, @uniqueShortName, COALESCE(@description, N''),
         @logo, @kennelUrl, @price, @price,
         @cityId, @regionId, @countryId, SYSDATETIMEOFFSET(), 2,
         N'None', 0, 5, 0, 0);

    -- ── 2. The requester as HC admin ──────────────────────────────────
    DECLARE @adminId UNIQUEIDENTIFIER;
    DECLARE @adminIsNew SMALLINT = 0;
    SELECT TOP 1 @adminId = h.id FROM HC.Hasher h WHERE h.Email = @email AND h.Removed = 0;

    IF (@adminId IS NULL)
    BEGIN
        -- The same new-account insert as hcapp_addEditUser (new-user mode),
        -- with the new kennel as home kennel. trgInsertHkmRecordForHomeHash
        -- then adds a home-kennel membership row, which the upsert below
        -- turns into the admin row.
        SET @adminId = NEWID();
        SET @adminIsNew = 1;
        INSERT HC.Hasher
            (id, FirstName, LastName, Email, HashName, Photo, NameDisplayPreference,
             IncludeInGlobalHashDirectory, Preferences, HomeKennelId, updatedAt)
        VALUES
            (@adminId, COALESCE(@firstName, N''), COALESCE(@lastName, N''), @email,
             COALESCE(@hashName, N''), N'',
             CASE WHEN LEN(COALESCE(@hashName, N'')) > 0 THEN 1 ELSE 2 END,
             0, 14, @kennelId, GETDATE());

        INSERT HC.LaunchAndLogin (HcVersion, UserId, UserName)
        VALUES (N'<portal>', @adminId,
                N'+' + COALESCE(NULLIF(@hashName, N''), @firstName + N' ' + @lastName, N'<no name>') + N'+');
    END

    IF EXISTS (SELECT 1 FROM HC.HasherKennelMap m WHERE m.UserId = @adminId AND m.KennelId = @kennelId)
        UPDATE HC.HasherKennelMap SET
            Following = 1, IsMember = 1, removed = 0,
            AppAccessFlags = COALESCE(AppAccessFlags, 0) | @adminAccessFlags,
            HcWebPermissionFlags = COALESCE(HcWebPermissionFlags, 0) | @adminWebFlags,
            CanEditRunAttendence = 1, MembershipExpirationDate = @neverExpires,
            updatedAt = GETDATE()
        WHERE UserId = @adminId AND KennelId = @kennelId;
    ELSE
        INSERT HC.HasherKennelMap
            (UserId, KennelId, Following, IsMember, IsHomeKennel, MismanagementRoleFlags,
             HcWebPermissionFlags, UserRoleFlags, AppAccessFlags, MembershipExpirationDate,
             MemberSince, CanEditRunAttendence, removed, updatedAt)
        VALUES
            (@adminId, @kennelId, 1, 1, 0, 0,
             @adminWebFlags, 0, @adminAccessFlags, @neverExpires,
             GETDATE(), 1, 0, GETDATE());

    -- ── 3. Platform admins as helpers ─────────────────────────────────
    INSERT HC.HasherKennelMap
        (UserId, KennelId, Following, IsMember, IsHomeKennel, MismanagementRoleFlags,
         HcWebPermissionFlags, UserRoleFlags, AppAccessFlags, MembershipExpirationDate,
         MemberSince, CanEditRunAttendence, removed, updatedAt)
    SELECT pa.UserId, @kennelId, 1, 0, 0, 0,
           @adminWebFlags, 0, @adminAccessFlags, @neverExpires,
           GETDATE(), 1, 0, GETDATE()
    FROM HC.PlatformAdmin pa
    JOIN HC.Hasher h ON h.id = pa.UserId AND h.Removed = 0
    WHERE pa.removed = 0 AND pa.CanEditKennel = 1
      AND pa.UserId <> @adminId;

    -- ── 4. A usable sign-in code for the welcome email ────────────────
    -- NULL rotation: never invalidate a code the person may already hold.
    EXEC HC6.nonApi_ensureUserInviteCode @userId = @adminId, @rotateIfOlderThanMinutes = NULL;

    UPDATE EXT.OfficeForms_KennelImport SET
        RequestStatus    = 2,
        KennelId         = @kennelId,
        KennelImportedOn = GETDATE(),
        ReviewedBy       = @callerId,
        ReviewedAt       = SYSDATETIMEOFFSET(),
        ConfirmCode      = NULL,
        updatedAt        = GETDATE()
    WHERE KennelImportId = @kennelImportId;

    COMMIT TRANSACTION;

    SELECT 1 AS Success, NULL AS ErrorMessage;
    SELECT @kennelId        AS KennelId,
           @kennelName      AS KennelName,
           @uniqueShortName AS KennelUniqueShortName,
           @adminId         AS AdminHasherId,
           h.Email          AS AdminEmail,
           h.FirstName      AS AdminFirstName,
           h.HashName       AS AdminHashName,
           @adminIsNew      AS AdminIsNew,
           REPLACE(h.ResetCode, N'URC:', N'') AS InviteCode
    FROM HC.Hasher h
    WHERE h.id = @adminId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_approveKennelRequest',
            ERROR_MESSAGE(), @procName, @callerId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
