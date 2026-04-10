CREATE OR ALTER PROCEDURE [HC6].[hcportal_getNewsflashReaders]

    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000) = NULL,
    @newsflashId    UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_getNewsflashReaders
-- Description: Returns the full interaction list for a single newsflash,
--              showing every user who has responded (dismissed or snoozed).
--              Intended for the admin "who has read this?" sortable list.
--              Users who have never interacted are not included.
-- Parameters: @deviceId, @accessToken (auth)
--             @newsflashId — the newsflash to query
-- Returns: Rowset 0: reader rows ordered by UpdatedAt DESC,
--          or error envelope on auth/validation failure
-- Author: Harrier Central
-- Created: 2026-04-10
-- HC5 Source: n/a — new feature
-- Breaking Changes: n/a
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    IF @newsflashId IS NULL
    BEGIN
        SELECT 0 AS Success, 'newsflashId is required' AS ErrorMessage;
        RETURN;
    END

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

    -- Allow querying soft-deleted newsflashes — admins may want to see
    -- the reader list after a newsflash has been deleted
    IF NOT EXISTS (SELECT 1 FROM HC.PortalNewsflash WHERE NewsflashId = @newsflashId)
    BEGIN
        SELECT 0 AS Success, 'Newsflash not found' AS ErrorMessage;
        RETURN;
    END

    SELECT
        h.PublicHasherId   AS publicHasherId,
        h.HashName         AS hashName,
        h.DisplayName      AS displayName,
        nfr.IsDismissed    AS isDismissed,
        nfr.NextShowDate   AS nextShowDate,
        nfr.UpdatedAt      AS updatedAt
    FROM HC.PortalNewsflashRead nfr
    INNER JOIN HC.Hasher h ON h.id = nfr.HasherId
    WHERE nfr.NewsflashId = @newsflashId
    ORDER BY nfr.UpdatedAt DESC;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
