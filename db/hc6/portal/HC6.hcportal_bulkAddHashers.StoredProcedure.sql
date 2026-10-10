CREATE OR ALTER PROCEDURE [HC6].[hcportal_bulkAddHashers]

-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
@deviceId uniqueidentifier = NULL,
@accessToken nvarchar(1000) = NULL,
@publicKennelId uniqueidentifier = NULL,
@newHasherJson nvarchar(MAX) = NULL,
-- 1 = called by "Import from file" (E2.F2.S6, 2026-10-10): rows already in
-- this kennel are left untouched (ALREADY IN KENNEL), a row with no email
-- is matched to a kennel member by name or gets a placeholder address
-- (hc-<id>@noemail.invalid — .invalid can never be delivered), and every
-- added hasher is given an invite code. 0 = the paste grid, unchanged.
@fromImport smallint = 0

AS
-- =====================================================================
-- Procedure: HC6.hcportal_bulkAddHashers
-- Description: Bulk adds or updates multiple hashers (members) for a
--   kennel. Accepts a JSON array of hasher data, validates email format,
--   creates new HC.Hasher records for new users, creates/updates
--   HasherKennelMap relationships, and optionally updates historical
--   run counts. Uses a cursor to iterate through the input array.
-- Parameters: @deviceId (auth), @accessToken (auth),
--   @publicKennelId (routing), @newHasherJson (JSON array of hashers)
-- Returns: On error: HC6 standard error envelope (Success, ErrorMessage).
--   On success: BulkAddResult rowset with per-hasher outcomes.
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_bulkAddHashers
-- Breaking Changes:
--   - Membership "never expires" date changed from 2100-01-01 to 2999-12-31
--   - Validation now short-circuits with RETURN on first error
--   - Added TRY/CATCH and transaction around all writes
--   - nonApi_updateRunCountsByUser now called inside transaction
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog inserts (error logging moved to API shim)
--   - Removed GeneralLog inserts (request logging moved to API shim)
--   - @publicHasherId replaced by @deviceId (device-bound auth via HC.Device lookup)
-- 2026-10-10: @fromImport (see the parameter); results are matched back to
--   input rows by position, not email (an import row may have none); the
--   CATCH now logs to HC.ErrorLog.
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- Auth validation
    DECLARE @authError NVARCHAR(255);
    DECLARE @hasherId UNIQUEIDENTIFIER;
    DECLARE @callerType INT;
    DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
    EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @publicKennelId, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
    IF @authError IS NOT NULL
    BEGIN
        SELECT 0 AS Success, @authError AS ErrorMessage;
        RETURN;
    END

    -- Validation: publicKennelId must not be NULL
    IF (@publicKennelId IS NULL)
    BEGIN
        SELECT 0 AS Success, 'NULL or invalid publicKennelId' AS ErrorMessage;
        RETURN;
    END

    -- Resolve internal kennel ID from public ID
    DECLARE @kennelId uniqueidentifier
    SELECT @kennelId = id from HC.Kennel WHERE PublicKennelId = @publicKennelId

    IF (@kennelId IS NULL)
    BEGIN
        SELECT 0 AS Success, 'No record found with provided @publicKennelId' AS ErrorMessage;
        RETURN;
    END

    -- Privilege check: caller must have admin or member-management rights (L6 fix).
    -- 0x40000012 = superAdmin | authIsAdmin | authCanManageHashers; 0x40000081 covers superAdmin+authIsAdmin.
    -- Accept either admin flag or the member-management flag (0x0010 = authCanManageHashers / 0x0002 = manage-members).
    DECLARE @appAccessFlags INT = 0;
    SELECT @appAccessFlags = ISNULL(hkm.AppAccessFlags, 0)
    FROM HC.HasherKennelMap hkm
    WHERE hkm.UserId = @hasherId AND hkm.KennelId = @kennelId;

    IF (@appAccessFlags & 0x40000081) = 0
    BEGIN
        SELECT 0 AS Success, 'You are not authorised to add members to this kennel.' AS ErrorMessage;
        RETURN;
    END

    -- Validation: newHasherJson must not be NULL or too short
    IF (@newHasherJson IS NULL) OR (LEN(@newHasherJson) < 5)
    BEGIN
        SELECT 0 AS Success, 'NULL or invalid new Hasher data' AS ErrorMessage;
        RETURN;
    END

    -- Parse JSON into temp table
        SELECT
        CAST(j.[key] AS INT) AS rowNo
        , x.publicHasherId
        , x.publicKennelId
        , x.firstName
        , x.lastName
        , x.email
        , x.hashName
        , x.historicTotalRuns
        , x.historicHaring
        , x.addHasherStatus
        into #newHasherTemp
    FROM OPENJSON(@newHasherJson) j
    CROSS APPLY OPENJSON(j.value)
        WITH (
        publicHasherId NVARCHAR(500) '$.publicHasherId',
        publicKennelId NVARCHAR(500) '$.publicKennelId',
        firstName NVARCHAR(500) '$.firstName',
        lastName NVARCHAR(500) '$.lastName',
        email NVARCHAR(500) '$.eMail',
        hashName nvarchar(500) '$.hashName',
        historicTotalRuns int '$.historicTotalRuns',
        historicHaring int '$.historicHaring',
        addHasherStatus nvarchar(500) '$.addHasherStatus'
        ) x;

    -- Create output table to track results
    SELECT * into #outputTable FROM #newHasherTemp

        DECLARE
    @rowNo int,
    @firstName nvarchar(500),
    @lastName nvarchar(500),
    @email nvarchar(500),
    @hashName nvarchar(500),
    @addHasherStatus nvarchar(500),
    @historicTotalRuns int,
    @historicHaring int

        DECLARE nhCrsr CURSOR LOCAL FOR SELECT
        rowNo
        , firstName
        , lastName
        , hashName
        , email
        , historicTotalRuns
        , historicHaring
        , addHasherStatus
        FROM #newHasherTemp
    ORDER BY rowNo

    OPEN nhCrsr

    FETCH NEXT FROM nhCrsr into @rowNo, @firstName, @lastName, @hashName, @email, @historicTotalRuns, @historicHaring, @addHasherStatus

    DECLARE @newHasherId uniqueidentifier,
        @newPublicHasherId uniqueidentifier,
        @hkmId uniqueidentifier,
        @ahStatus nvarchar(50),
        @photo nvarchar(100)

    -- Wrap entire cursor loop in a single transaction
    BEGIN TRANSACTION;

    WHILE (@@FETCH_STATUS = 0)
    BEGIN

                SET @newHasherId = NULL
        SET @newPublicHasherId = NULL
        SET @ahStatus = NULL
        SET @hkmId = NULL
        SET @email = NULLIF(LTRIM(RTRIM(@email)), '')

        IF (@fromImport = 1 AND @email IS NULL)
        BEGIN
            -- No address: is this somebody already in the kennel? Match on hash
            -- name, else on first + last name (re-importing a file must not
            -- duplicate the people who had no email the first time).
            SELECT TOP 1 @newHasherId = h.id, @newPublicHasherId = h.PublicHasherId
            FROM HC.HasherKennelMap k
            JOIN HC.Hasher h ON h.id = k.UserId
            WHERE k.KennelId = @kennelId AND k.removed = 0 AND ISNULL(h.Removed, 0) = 0
              AND ((NULLIF(LTRIM(RTRIM(@hashName)), '') IS NOT NULL AND LOWER(LTRIM(RTRIM(h.HashName))) = LOWER(LTRIM(RTRIM(@hashName))))
                OR (NULLIF(LTRIM(RTRIM(@firstName)), '') IS NOT NULL AND NULLIF(LTRIM(RTRIM(@lastName)), '') IS NOT NULL
                    AND LOWER(LTRIM(RTRIM(h.FirstName))) = LOWER(LTRIM(RTRIM(@firstName)))
                    AND LOWER(LTRIM(RTRIM(h.LastName))) = LOWER(LTRIM(RTRIM(@lastName)))));
            IF (@newHasherId IS NOT NULL)
                SET @ahStatus = 'ALREADY IN KENNEL'
            ELSE
                SET @email = 'hc-' + LOWER(LEFT(REPLACE(CAST(NEWID() AS NVARCHAR(40)), '-', ''), 12)) + '@noemail.invalid';
        END

        IF (@ahStatus IS NULL)
            SELECT
                @newHasherId = id,
                @newPublicHasherId = PublicHasherId
            FROM HC.Hasher where Email = @email

        -- An import leaves people already in this kennel exactly as they are.
        IF (@fromImport = 1 AND @ahStatus IS NULL AND @newHasherId IS NOT NULL
            AND EXISTS (SELECT 1 FROM HC.HasherKennelMap k WHERE k.UserId = @newHasherId AND k.KennelId = @kennelId AND k.removed = 0))
            SET @ahStatus = 'ALREADY IN KENNEL'

                -- if the email is not valid don't even attempt to process
        IF (@ahStatus IS NULL AND @email LIKE '%_@__%.__%')
        BEGIN
            IF (@newHasherId IS NULL)
            BEGIN
                IF (@hashName IS NULL) SET @hashName = ''

                SELECT @photo = 'bundle://avatar-' + CAST(CAST(RAND() * 48 as INT) + 1 as nvarchar(50))
                SET @newPublicHasherId = newid()

                INSERT HC.Hasher(PublicHasherId, FirstName, LastName, HashName, Email, HomeKennelId, Photo)
                VALUES (@newPublicHasherId, @firstName, @lastName, @hashName, @email, @kennelId, @photo)

                SELECT @newHasherId = id FROM HC.Hasher where Email = @email
                SET @ahStatus = 'NEW HC USER'
            END

            SELECT @hkmId = id FROM HC.HasherKennelMap where UserId = @newHasherId AND KennelId = @kennelId

            IF (@hkmId IS NULL)
                BEGIN
                    INSERT HC.HasherKennelMap(UserId, KennelId, Following, MembershipExpirationDate) VALUES (@newHasherId, @kennelId, 1, '2999-12-31')
                    SET @ahStatus = coalesce(@ahStatus, 'NEW MEMBER')
                END
            ELSE
                BEGIN
                    IF (SELECT COUNT(*) FROM HC.HasherKennelMap where UserId = @newHasherId AND KennelId = @kennelId AND Following = 1 AND MembershipExpirationDate > getdate()) = 0
                        BEGIN
                            UPDATE HC.HasherKennelMap SET Following = 1, MembershipExpirationDate = '2999-12-31' WHERE id = @hkmId
                            SET @ahStatus = coalesce(@ahStatus, 'NEW MEMBER')
                        END
                END

            -- Keep the automated MEMBER standing bit (0x0001) in sync
            EXEC HC6.nonApi_syncMemberStandingBit @userId = @newHasherId, @kennelId = @kennelId;

            DECLARE @runCountsUpdated int = 0

            IF (@historicTotalRuns IS NOT NULL)
            BEGIN
                DECLARE @htr int

                SELECT @htr = hkm.HistoricalTotalRunCount
                FROM HC.HasherKennelMap hkm
                WHERE hkm.UserId = @newHasherId
                AND hkm.KennelId = @kennelId

                if (@htr != @historicTotalRuns)
                BEGIN
                    SET @runCountsUpdated = 1
                    UPDATE hkm
                        SET hkm.HistoricalTotalRunCount = @historicTotalRuns,
                        hkm.updatedAt = getdate()
                        FROM HC.HasherKennelMap hkm
                        WHERE hkm.UserId = @newHasherId
                        AND hkm.KennelId = @kennelId

                    SET @ahStatus = coalesce(@ahStatus, 'UPDATE RUN COUNTS')
                END
            END

            IF (@historicHaring IS NOT NULL)
            BEGIN
                DECLARE @hh int

                SELECT @hh = hkm.HistoricalHaringCount
                FROM HC.HasherKennelMap hkm
                WHERE hkm.UserId = @newHasherId
                AND hkm.KennelId = @kennelId

                if (@hh != @historicHaring)
                BEGIN
                    SET @runCountsUpdated = 1
                    UPDATE hkm
                        SET hkm.HistoricalHaringCount = @historicHaring,
                        hkm.updatedAt = getdate()
                        FROM HC.HasherKennelMap hkm
                        WHERE hkm.UserId = @newHasherId
                        AND hkm.KennelId = @kennelId

                    SET @ahStatus = coalesce(@ahStatus, 'UPDATE RUN COUNTS')
                END
            END

            IF (@runCountsUpdated = 1)
            BEGIN
                EXEC [HC6].[nonApi_updateRunCountsByUser]
                    @userId = @newHasherId
            END

                        SET @ahStatus = coalesce(@ahStatus, 'NO CHANGE')

            -- Everyone an import adds gets an invite code to be emailed.
            IF (@fromImport = 1 AND @ahStatus IN ('NEW HC USER', 'NEW MEMBER'))
                EXEC HC6.nonApi_ensureUserInviteCode @userId = @newHasherId;

        END -- end of email check
        UPDATE #outputTable
           SET publicHasherId = @newPublicHasherId,
               email = coalesce(@email, email),
               addHasherStatus = coalesce(@ahStatus, 'ERROR')
         WHERE rowNo = @rowNo

        FETCH NEXT FROM nhCrsr into @rowNo, @firstName, @lastName, @hashName, @email, @historicTotalRuns, @historicHaring, @addHasherStatus
    END

    COMMIT TRANSACTION;

    CLOSE nhCrsr
    DEALLOCATE nhCrsr

    -- Return results
    SELECT
        publicHasherId,
        publicKennelId,
        firstName,
        lastName,
        email,
        hashName,
        historicTotalRuns,
        historicHaring,
                addHasherStatus
    FROM #outputTable
    ORDER BY rowNo

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    -- Clean up cursor if still open
    IF CURSOR_STATUS('local', 'nhCrsr') >= 0
    BEGIN
        CLOSE nhCrsr;
        DEALLOCATE nhCrsr;
    END

        INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<portal>', 'Unhandled error in hcportal_bulkAddHashers', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), @hasherId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
