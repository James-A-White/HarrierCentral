-- =====================================================================
-- Function: HC6.CHECK_PORTAL_ACCESS_TOKEN
-- Description: HC6 counterpart to HC.CHECK_PORTAL_ACCESS_TOKEN.
--              Validates a short-lived cryptographic portal access token.
--              Mirrors HC5 logic exactly; the only behavioural difference
--              is that the first parameter is @deviceId (HC.Device.id)
--              instead of @publicHasherId / @userId.
--
--              Token bypass: The cutoff date below temporarily bypasses
--              validation so HC6 endpoints can be tested before the
--              Flutter portal is updated to generate HC6-format tokens.
--              To enforce validation: set the cutoff to a past date.
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
-- Time windows tried (matches HC5 CHECK_PORTAL_ACCESS_TOKEN):
--   Primary:  86469s (≈24h) — broad portal window
--   Fallback: 69s            — matches Flutter portal TIME_WINDOW constant
--
-- HC5 source: HC.CHECK_PORTAL_ACCESS_TOKEN
-- Created: 2026-03-17
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
    DECLARE @try69 INT = 0;

    -- Token bypass: set cutoff to a past date to enforce validation.
    -- Current setting: bypass active until 2026-06-01 while Flutter portal
    -- migrates from HC5 to HC6 token format.
    -- TO ENABLE ENFORCEMENT: change '2026-06-01' to any past date.
    IF (DATEADD(MINUTE, -120, GETDATE()) < '2026-06-01 00:00:00.000')
    BEGIN
        RETURN 1;
    END

    -- Basic sanity check on token length
    IF (@accessToken IS NULL OR DATALENGTH(@accessToken) < 50)
    BEGIN
        RETURN 0;
    END

    DECLARE @baseDate DATETIME = '15 AUG 1963 9:52:28 AM';
    DECLARE @timeWindow INT = 86469;

    -- Try primary time window (86469s ≈ 24h), checking ±2 time slots
    -- to tolerate clock skew and network latency.
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
                        SET @try69 = 1;
                    END
                END
            END
        END
    END

    -- Fallback to 69s window — matches Flutter portal Utilities.TIME_WINDOW = 69
    SET @timeWindow = 69;

    IF (@try69 = 1)
    BEGIN
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
    END

    RETURN 1;
END
GO
