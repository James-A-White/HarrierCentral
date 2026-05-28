-- =====================================================================
-- Function: HC6.CHECK_PORTAL_ACCESS_TOKEN
-- Description: HC6 counterpart to HC.CHECK_PORTAL_ACCESS_TOKEN.
--              Validates a short-lived cryptographic portal access token.
--              Mirrors HC5 logic exactly; the only behavioural difference
--              is that the first parameter is @deviceId (HC.Device.id)
--              instead of @publicHasherId / @userId.
--
-- Parameters:
--   @deviceId     - HC.Device.id of the authenticating device
--   @procName     - SP name baked into the token on the client side
--   @accessToken  - Token string to validate
--   @paramString  - UPPER(deviceSecret) + callerParamString,
--                   assembled by HC6.ValidatePortalAuth
--
-- Returns: 1 = valid, 0 = invalid
--
-- Time window: 69s — matches Flutter portal Utilities.TIME_WINDOW constant.
--   ±2 block tolerance = 5 attempts total to tolerate clock skew and latency.
--   The legacy 86469s (≈24h) primary window has been removed (security fix C2).
--   The development auth bypass has been removed (security fix C1).
--
-- HC5 source: HC.CHECK_PORTAL_ACCESS_TOKEN
-- Created: 2026-03-17
-- Updated: 2026-05-28 — removed auth bypass (C1) and 86469s window (C2)
-- =====================================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER FUNCTION [HC6].[CHECK_PORTAL_ACCESS_TOKEN]
(
    @deviceId       UNIQUEIDENTIFIER,
    @procName       NVARCHAR(100),
    @accessToken    NVARCHAR(1000),
    @paramString    NVARCHAR(650)
)
RETURNS INT
WITH EXECUTE AS CALLER
AS
BEGIN
    DECLARE @generatedToken NVARCHAR(2000);

    -- Basic sanity check on token length
    IF (@accessToken IS NULL OR DATALENGTH(@accessToken) < 50)
    BEGIN
        RETURN 0;
    END

    DECLARE @baseDate   DATETIME = '15 AUG 1963 9:52:28 AM';
    DECLARE @timeWindow INT      = 69;

    -- Try 69s window with ±2 block tolerance (5 attempts total).
    SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@deviceId, @procName, 0, @paramString, @timeWindow, @baseDate);
    IF @generatedToken != @accessToken
    BEGIN
        SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@deviceId, @procName, 1, @paramString, @timeWindow, @baseDate);
        IF @generatedToken != @accessToken
        BEGIN
            SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@deviceId, @procName, -1, @paramString, @timeWindow, @baseDate);
            IF @generatedToken != @accessToken
            BEGIN
                SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@deviceId, @procName, 2, @paramString, @timeWindow, @baseDate);
                IF @generatedToken != @accessToken
                BEGIN
                    SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@deviceId, @procName, -2, @paramString, @timeWindow, @baseDate);
                    IF @generatedToken != @accessToken
                    BEGIN
                        RETURN 0;
                    END
                END
            END
        END
    END

    RETURN 1;
END
GO
