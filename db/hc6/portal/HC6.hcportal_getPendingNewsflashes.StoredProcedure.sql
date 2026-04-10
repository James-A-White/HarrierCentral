CREATE OR ALTER PROCEDURE [HC6].[hcportal_getPendingNewsflashes]

    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getPendingNewsflashes
-- Description: Returns all newsflashes that are due to be shown to the
--              authenticated user, ordered by StartDate ASC. A newsflash
--              is due if it is active (not deleted, within date range),
--              visible to the user's kennel (or platform-wide), and has
--              not been dismissed or snoozed until a future date.
-- Parameters: @deviceId, @accessToken (auth)
-- Returns: Rowset 0: pending newsflash rows ordered by StartDate ASC,
--          or error envelope on auth failure
-- Author: Harrier Central
-- Created: 2026-04-10
-- HC5 Source: n/a — new feature
-- Breaking Changes: n/a
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- Auth
    DECLARE @authError  NVARCHAR(255);
    DECLARE @hasherId   UNIQUEIDENTIFIER;
    DECLARE @callerType INT;
    DECLARE @procName   NVARCHAR(128) = OBJECT_NAME(@@PROCID);

    EXEC HC6.ValidatePortalAuth
        @deviceId, @accessToken, @procName, NULL,
        @authError OUTPUT, @hasherId OUTPUT, @callerType OUTPUT;

    IF @authError IS NOT NULL
    BEGIN
        SELECT 0 AS Success, @authError AS ErrorMessage;
        RETURN;
    END

    DECLARE @today DATE = CAST(GETUTCDATE() AS DATE);

    -- Return all due newsflashes for this user, ordered by StartDate ASC.
    -- The portal iterates through the list client-side, showing one at a time.
    SELECT
        nf.NewsflashId  AS newsflashId,
        nf.Title        AS title,
        nf.BodyText     AS bodyText,
        nf.ImageUrl     AS imageUrl,
        nf.StartDate    AS startDate,
        nf.EndDate      AS endDate
    FROM HC.PortalNewsflash nf
    WHERE nf.IsDeleted = 0
      AND nf.StartDate <= @today
      AND (nf.EndDate IS NULL OR nf.EndDate >= @today)
      -- Platform-wide OR user belongs to the targeted kennel
      AND (
          nf.KennelId IS NULL
          OR nf.KennelId IN (
              SELECT hkm.KennelId
              FROM HC.HasherKennelMap hkm
              WHERE hkm.UserId = @hasherId
                AND (hkm.MembershipExpirationDate > GETUTCDATE() OR hkm.Following = 1)
          )
      )
      -- Exclude dismissed or still-snoozed newsflashes
      AND NOT EXISTS (
          SELECT 1
          FROM HC.PortalNewsflashRead nfr
          WHERE nfr.NewsflashId = nf.NewsflashId
            AND nfr.HasherId = @hasherId
            AND (
                nfr.IsDismissed = 1
                OR (nfr.IsDismissed = 0 AND nfr.NextShowDate > @today)
            )
      )
    ORDER BY nf.StartDate ASC;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
