CREATE OR ALTER PROCEDURE [HC6].[hcportal_respondToNewsflash]

    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000) = NULL,
    @newsflashId    UNIQUEIDENTIFIER = NULL,
    @isDismissed    BIT = NULL  -- 1 = "I've read it"; 0 = "Read Later" (snooze until tomorrow)

AS
-- =====================================================================
-- Procedure: HC6.hcportal_respondToNewsflash
-- Description: Records the authenticated user's response to a newsflash.
--              Upserts a HC.PortalNewsflashRead row per user per newsflash.
--              "I've read it" (@isDismissed = 1): permanently dismisses.
--              "Read Later" (@isDismissed = 0): snoozes until the next
--              calendar day (NextShowDate = tomorrow's UTC date).
-- Parameters: @deviceId, @accessToken (auth)
--             @newsflashId — the newsflash being responded to
--             @isDismissed — 1 = dismiss, 0 = snooze
-- Returns: Standard success envelope
-- Author: Harrier Central
-- Created: 2026-04-10
-- HC5 Source: n/a — new feature
-- Breaking Changes: n/a
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    -- Validate inputs before auth (fast-fail on obviously bad calls)
    IF @newsflashId IS NULL
    BEGIN
        SELECT 0 AS Success, 'newsflashId is required' AS ErrorMessage;
        RETURN;
    END

    IF @isDismissed IS NULL
    BEGIN
        SELECT 0 AS Success, 'isDismissed is required' AS ErrorMessage;
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

    -- Validate newsflash exists (allow responding to soft-deleted — user may have
    -- received it before deletion and is now dismissing it)
    IF NOT EXISTS (SELECT 1 FROM HC.PortalNewsflash WHERE NewsflashId = @newsflashId)
    BEGIN
        SELECT 0 AS Success, 'Newsflash not found' AS ErrorMessage;
        RETURN;
    END

    BEGIN TRANSACTION;

    DECLARE @nextShowDate DATE = CASE
        WHEN @isDismissed = 1 THEN NULL
        ELSE CAST(DATEADD(day, 1, GETUTCDATE()) AS DATE)
    END;

    IF EXISTS (
        SELECT 1 FROM HC.PortalNewsflashRead
        WHERE NewsflashId = @newsflashId AND HasherId = @hasherId
    )
    BEGIN
        UPDATE HC.PortalNewsflashRead
        SET IsDismissed  = @isDismissed,
            NextShowDate = @nextShowDate,
            UpdatedAt    = GETUTCDATE()
        WHERE NewsflashId = @newsflashId
          AND HasherId = @hasherId;
    END
    ELSE
    BEGIN
        INSERT INTO HC.PortalNewsflashRead
            (NewsflashId, HasherId, IsDismissed, NextShowDate, UpdatedAt)
        VALUES
            (@newsflashId, @hasherId, @isDismissed, @nextShowDate, GETUTCDATE());
    END

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
