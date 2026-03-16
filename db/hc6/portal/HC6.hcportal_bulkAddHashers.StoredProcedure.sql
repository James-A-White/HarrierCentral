CREATE OR ALTER PROCEDURE [HC6].[hcportal_bulkAddHashers]

-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
@deviceId uniqueidentifier = NULL,
@accessToken nvarchar(1000) = NULL,
@publicKennelId uniqueidentifier = NULL,
@newHasherJson nvarchar(MAX) = NULL

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
--   - HC.nonApi_updateRunCountsByUser now called inside transaction
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog inserts (error logging moved to API shim)
--   - Removed GeneralLog inserts (request logging moved to API shim)
--   - @publicHasherId replaced by @deviceId (device-bound auth via HC.Device lookup)
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- Auth validation
    DECLARE @authError NVARCHAR(255);
    DECLARE @hasherId UNIQUEIDENTIFIER;
    DECLARE @callerType INT;
    EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, OBJECT_NAME(@@PROCID), @publicKennelId, @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;
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

    -- Validation: newHasherJson must not be NULL or too short
    IF (@newHasherJson IS NULL) OR (LEN(@newHasherJson) < 5)
    BEGIN
        SELECT 0 AS Success, 'NULL or invalid new Hasher data' AS ErrorMessage;
        RETURN;
    END

    -- Parse JSON into temp table
    SELECT
        publicHasherId
        , publicKennelId
        , firstName
        , lastName
        , email
        , hashName
        , historicTotalRuns
        , historicHaring
        , addHasherStatus
        into #newHasherTemp
    FROM OPENJSON(@newHasherJson)
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
        );

    -- Create output table to track results
    SELECT * into #outputTable FROM #newHasherTemp

    DECLARE
    @firstName nvarchar(500),
    @lastName nvarchar(500),
    @email nvarchar(500),
    @hashName nvarchar(500),
    @addHasherStatus nvarchar(500),
    @historicTotalRuns int,
    @historicHaring int

    DECLARE nhCrsr CURSOR FOR SELECT
        firstName
        , lastName
        , hashName
        , email
        , historicTotalRuns
        , historicHaring
        , addHasherStatus
    FROM #newHasherTemp

    OPEN nhCrsr

    FETCH NEXT FROM nhCrsr into @firstName, @lastName, @hashName, @email, @historicTotalRuns, @historicHaring, @addHasherStatus

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

        SELECT
            @newHasherId = id,
            @newPublicHasherId = PublicHasherId
        FROM HC.Hasher where Email = @email

        -- if the email is not valid don't even attempt to process
        IF (@email LIKE '%_@__%.__%')
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
                EXEC [HC].[nonApi_updateRunCountsByUser]
                    @userId = @newHasherId
            END

            SET @ahStatus = coalesce(@ahStatus, 'NO CHANGE')

        END -- end of email check
        UPDATE #outputTable SET publicHasherId = @newPublicHasherId, addHasherStatus = coalesce(@ahStatus, 'ERROR') WHERE Email = @email

        FETCH NEXT FROM nhCrsr into @firstName, @lastName, @hashName, @email, @historicTotalRuns, @historicHaring, @addHasherStatus
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

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    -- Clean up cursor if still open
    IF CURSOR_STATUS('local', 'nhCrsr') >= 0
    BEGIN
        CLOSE nhCrsr;
        DEALLOCATE nhCrsr;
    END

    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
