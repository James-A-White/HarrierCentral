CREATE OR ALTER PROCEDURE [HC6].[hcportal_getNewsflashList]

    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getNewsflashList
-- Description: Returns all newsflashes (including soft-deleted, flagged
--              with IsDeleted = 1) for the HC Admin Tools management
--              screen. Includes a DismissedCount per newsflash showing
--              how many users have clicked "I've read it".
-- Parameters: @deviceId, @accessToken (auth)
-- Returns: Rowset 0: all newsflashes ordered by CreatedAt DESC,
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

    SELECT
        nf.NewsflashId              AS newsflashId,
        nf.Title                    AS title,
        nf.BodyText                 AS bodyText,
        nf.ImageUrl                 AS imageUrl,
        nf.StartDate                AS startDate,
        nf.EndDate                  AS endDate,
        nf.KennelId                 AS kennelId,
        k.KennelName                AS kennelName,
        nf.IsDeleted                AS isDeleted,
        nf.CreatedAt                AS createdAt,
        nf.UpdatedAt                AS updatedAt,
        ISNULL(rc.DismissedCount, 0) AS dismissedCount
    FROM HC.PortalNewsflash nf
    LEFT JOIN HC.Kennel k ON k.id = nf.KennelId
    LEFT JOIN (
        SELECT NewsflashId, COUNT(*) AS DismissedCount
        FROM HC.PortalNewsflashRead
        WHERE IsDismissed = 1
        GROUP BY NewsflashId
    ) rc ON rc.NewsflashId = nf.NewsflashId
    ORDER BY nf.CreatedAt DESC;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
