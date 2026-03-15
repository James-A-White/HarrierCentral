CREATE OR ALTER PROCEDURE [HC6].[hcportal_updateKennelHasher]

-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
@publicHasherId uniqueidentifier = NULL,
@accessToken nvarchar(1000) = NULL,
@hasherBeingEditedPublicId uniqueidentifier = NULL,
@publicKennelId uniqueidentifier = NULL,

-- optional parameters: personal details
@firstName nvarchar(250) = NULL,       -- HC5 was NVARCHAR(150), widened to match Hasher.FirstName NVARCHAR(250)
@lastName nvarchar(250) = NULL,        -- HC5 was NVARCHAR(150), widened to match Hasher.LastName NVARCHAR(250)
@eMail nvarchar(250) = NULL,
@hashName nvarchar(250) = NULL,

-- optional parameters: membership and preferences
-- TODO: Change to proper types (BIT/INT) when portal is updated
@isMember nvarchar(50) = NULL,
@status nvarchar(50) = NULL,
@emailAlerts nvarchar(50) = NULL,
@notifications nvarchar(50) = NULL,

-- optional parameters: discounts
@discountPercent smallint = NULL,
@discountAmount smallmoney = NULL,
@discountDescription nvarchar(50) = NULL,

-- optional parameters: historical run counts
-- TODO: Change to proper types (BIT/INT) when portal is updated
@historicTotalRuns nvarchar(50) = NULL,
@historicHaring nvarchar(50) = NULL,
@historicCountsAreEstimates nvarchar(50) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_updateKennelHasher
-- Description: Updates a hasher's profile and kennel-specific settings
--   for a given kennel. Allows editing of personal details (name, email,
--   hash name), discount settings, membership status, notification
--   preferences, historical run counts, and historical count estimates.
--   The SP determines which fields to update based on which parameters
--   are non-NULL.
-- Parameters: @publicHasherId (auth), @accessToken (auth),
--   @hasherBeingEditedPublicId (target hasher), @publicKennelId (kennel
--   context), plus optional update fields
-- Returns: On error: HC6 standard error envelope (Success, ErrorMessage).
--   On historicTotalRuns/historicHaring update: HistoricalRunCountUpdate
--   rowset with updated counts. Otherwise: no result rowset (success
--   inferred from absence of error).
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_updateKennelHasher
-- Breaking Changes:
--   - @firstName widened from NVARCHAR(150) to NVARCHAR(250) to match table
--   - @lastName widened from NVARCHAR(150) to NVARCHAR(250) to match table
--   - Membership "never expires" date changed from 2100-01-01 to 2999-12-31
--   - HC.nonApi_updateRunCountsByUser now called for haring updates too
--     (was commented out in HC5)
--   - All writes wrapped in a single transaction
--   - Validation now short-circuits with RETURN on first error
--   - Removed commented-out debug SELECT statements
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog inserts (error logging moved to API shim)
--   - Removed GeneralLog inserts (request logging moved to API shim)
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- Auth validation
    DECLARE @authError NVARCHAR(255);
    EXEC HC6.ValidatePortalAuth @publicHasherId, @accessToken, OBJECT_NAME(@@PROCID), @hasherBeingEditedPublicId, @authError OUTPUT;
    IF @authError IS NOT NULL
    BEGIN
        SELECT 0 AS Success, @authError AS ErrorMessage;
        RETURN;
    END

    -- Resolve internal hasher ID from public ID (the calling user)
    DECLARE @hasherId uniqueidentifier
    SELECT @hasherId = id from HC.Hasher WHERE PublicHasherId = @publicHasherId

    IF (@hasherId IS NULL)
    BEGIN
        SELECT 0 AS Success, 'No record found with provided @publicHasherId' AS ErrorMessage;
        RETURN;
    END

    -- Validation: hasherBeingEditedPublicId must not be NULL
    IF (@hasherBeingEditedPublicId IS NULL)
    BEGIN
        SELECT 0 AS Success, 'Null or invalid hasherBeingEditedId' AS ErrorMessage;
        RETURN;
    END

    -- Resolve internal ID for the hasher being edited
    DECLARE @hasherBeingEditedId uniqueidentifier
    SELECT @hasherBeingEditedId = id from HC.Hasher WHERE PublicHasherId = @hasherBeingEditedPublicId

    IF (@hasherBeingEditedId IS NULL)
    BEGIN
        SELECT 0 AS Success, 'No record found with provided @hasherBeingEditedId' AS ErrorMessage;
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

    -- Wrap all writes in a single transaction
    BEGIN TRANSACTION;

    -- Update personal details on HC.Hasher if any provided
    IF (
        (@eMail IS NOT NULL)
        OR (@firstName IS NOT NULL)
        OR (@lastName IS NOT NULL)
        OR (@hashName IS NOT NULL)
    )
    BEGIN
        UPDATE HC.Hasher
            SET
                Email = coalesce(@eMail, Email),
                FirstName = coalesce(@firstName, FirstName),
                LastName = coalesce(@lastName, LastName),
                HashName = coalesce(@hashName, HashName),
                updatedAt = getdate()
            WHERE PublicHasherId = @hasherBeingEditedPublicId
    END

    -- Update discount fields on HC.HasherKennelMap if any provided
    IF (
        (@discountAmount IS NOT NULL)
        OR (@discountPercent IS NOT NULL)
        OR (@discountDescription IS NOT NULL)
    )
    BEGIN
        UPDATE HC.HasherKennelMap
            SET
                DiscountAmount = coalesce(@discountAmount, DiscountAmount),
                DiscountPercent = coalesce(@discountPercent, DiscountPercent),
                DiscountDescription = coalesce(@discountDescription, DiscountDescription),
                updatedAt = getdate()
            FROM HC.HasherKennelMap hkm
            INNER JOIN HC.Hasher h on hkm.UserId = h.id
            INNER JOIN HC.Kennel k on hkm.KennelId = k.id
            WHERE h.PublicHasherId = @hasherBeingEditedPublicId
            AND k.PublicKennelId = @publicKennelId
    END

    -- Update membership status if provided
    IF (
        (@isMember IS NOT NULL) OR (@status IS NOT NULL)
    )
    BEGIN
        UPDATE hkm
            SET hkm.MembershipExpirationDate =
                case when lower(@isMember) = 'yes' OR lower(@status) = 'member' then '2999-12-31' else dateadd(day, -1, getdate()) end,
            hkm.Following = 1,
            hkm.updatedAt = getdate()
            FROM HC.HasherKennelMap hkm
            INNER JOIN HC.Hasher h on hkm.UserId = h.id
            INNER JOIN HC.Kennel k on hkm.KennelId = k.id
            WHERE h.PublicHasherId = @hasherBeingEditedPublicId
            AND k.PublicKennelId = @publicKennelId
    END

    -- Update notification and email alert preferences if provided
    IF ((@emailAlerts IS NOT NULL) OR (@notifications IS NOT NULL))
    BEGIN
        UPDATE hkm
            SET
                hkm.KennelNotificationPreference = case when @notifications is null then hkm.KennelNotificationPreference
                                                        when lower(@notifications) = 'on' then 1
                                                        when lower(@notifications) = 'off' then 2
                                                        when lower(@notifications) = 'auto' then 0
                                                        else hkm.KennelNotificationPreference end,
                hkm.KennelEmailAlertPreference = case when @emailAlerts is null then hkm.KennelEmailAlertPreference
                                                      when lower(@emailAlerts) = 'on' then 1
                                                      when lower(@emailAlerts) = 'off' then 2
                                                      when lower(@emailAlerts) = 'auto' then 0
                                                      else hkm.KennelEmailAlertPreference end,
                hkm.updatedAt = getdate()
            FROM HC.HasherKennelMap hkm
            INNER JOIN HC.Hasher h on hkm.UserId = h.id
            INNER JOIN HC.Kennel k on hkm.KennelId = k.id
            WHERE h.PublicHasherId = @hasherBeingEditedPublicId
            AND k.PublicKennelId = @publicKennelId
    END

    -- Update historical count estimate flag if provided
    IF (@historicCountsAreEstimates IS NOT NULL)
    BEGIN
        UPDATE hkm
            SET
                hkm.HistoricalCountIsEstimate = case when lower(@historicCountsAreEstimates) = 'yes' then 1
                                                     when lower(@historicCountsAreEstimates) = 'no' then 0
                                                     else hkm.HistoricalCountIsEstimate end,
            hkm.updatedAt = getdate()
            FROM HC.HasherKennelMap hkm
            INNER JOIN HC.Hasher h on hkm.UserId = h.id
            INNER JOIN HC.Kennel k on hkm.KennelId = k.id
            WHERE h.PublicHasherId = @hasherBeingEditedPublicId
            AND k.PublicKennelId = @publicKennelId
    END

    -- Here we have to deal with a bit of a disconnect in how we
    -- count runs. The database stores the number of pack runs
    -- and the number of hared runs, the sum of which is the
    -- number of total runs. By contrast, the UI displays and
    -- lets the user edit the number of pack runs or the number
    -- of total runs. So when either of the two parameters is
    -- edited, we need to adjust the other accordingly.

    -- Use the already-resolved IDs (avoid redundant lookups from HC5)
    DECLARE @hid uniqueidentifier = @hasherBeingEditedId,
            @kid uniqueidentifier = @kennelId

    -- Update historical total run count if provided and numeric
    IF ((@historicTotalRuns IS NOT NULL) AND (ISNUMERIC(@historicTotalRuns) = 1))
    BEGIN
        DECLARE @htr int = cast(@historicTotalRuns as int)
        if (@htr is not null)
        BEGIN
            UPDATE hkm
                SET hkm.HistoricalTotalRunCount = @htr,
                hkm.updatedAt = getdate()
                FROM HC.HasherKennelMap hkm
                INNER JOIN HC.Hasher h on hkm.UserId = h.id
                INNER JOIN HC.Kennel k on hkm.KennelId = k.id
                WHERE h.PublicHasherId = @hasherBeingEditedPublicId
                AND k.PublicKennelId = @publicKennelId

            EXEC [HC].[nonApi_updateRunCountsByUser]
                @userId = @hid

            SELECT  hkm.id as hkmId,
                    hkm.HistoricalHaringCount,
                    hkm.HistoricalTotalRunCount,
                    hkm.HcTotalRunCount,
                    hkm.HcHaringCount,
                    @hasherBeingEditedPublicId as hasherBeingEditedId,
                    @publicHasherId as publicHasherId
                FROM HC.HasherKennelMap hkm
                INNER JOIN HC.Hasher h on hkm.UserId = h.id
                INNER JOIN HC.Kennel k on hkm.KennelId = k.id
                WHERE h.PublicHasherId = @hasherBeingEditedPublicId
                AND k.PublicKennelId = @publicKennelId

        END
    END

    -- Update historical haring count if provided and numeric
    IF ((@historicHaring IS NOT NULL) AND(ISNUMERIC(@historicHaring) = 1))
    BEGIN
        DECLARE @hh int = cast(@historicHaring as int)
        IF (@hh is not null)
        BEGIN
            UPDATE hkm
                SET hkm.HistoricalHaringCount = @hh,
                hkm.updatedAt = getdate()
                FROM HC.HasherKennelMap hkm
                INNER JOIN HC.Hasher h on hkm.UserId = h.id
                INNER JOIN HC.Kennel k on hkm.KennelId = k.id
                WHERE h.PublicHasherId = @hasherBeingEditedPublicId
                AND k.PublicKennelId = @publicKennelId

            -- HC5 had this commented out -- re-enabled in HC6 so run counts
            -- are recalculated when haring is updated too
            EXEC [HC].[nonApi_updateRunCountsByUser]
                @userId = @hid

            SELECT  hkm.id as hkmId,
                    hkm.HistoricalHaringCount,
                    hkm.HistoricalTotalRunCount,
                    hkm.HcTotalRunCount,
                    hkm.HcHaringCount,
                    @hasherBeingEditedPublicId as hasherBeingEditedId,
                    @publicHasherId as publicHasherId
                FROM HC.HasherKennelMap hkm
                INNER JOIN HC.Hasher h on hkm.UserId = h.id
                INNER JOIN HC.Kennel k on hkm.KennelId = k.id
                WHERE h.PublicHasherId = @hasherBeingEditedPublicId
                AND k.PublicKennelId = @publicKennelId
        END
    END

    COMMIT TRANSACTION;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
