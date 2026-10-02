CREATE OR ALTER PROCEDURE [HC6].[hcapp_getCoRunners]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getCoRunners
-- Description: Run Counts › By Hasher (E10.F1.S5): everyone the caller
--   has run with (HC6.CoRunners: both attended), most runs together first.
--   The caller's OWN history, so a hasher who chose "nobody" for search
--   still appears (James, 2026-10-02) — each run's attendee list already
--   shows them. The whole list in one reply (759 rows for James, ~60 ms);
--   the app searches it locally.
-- Returns: rowset 0 — { PublicHasherId, DisplayName, Photo,
--   HomeKennelShortName, HomeKennelLogo, RunsTogether, LastTogether }
--   (LastTogether = EventStartDatetimeGmt, an instant)
-- Author: Harrier Central
-- Created: 2026-10-02
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 144, @param = NULL,
    @userId = @userId OUTPUT, @deviceSecret = @deviceSecret OUTPUT,
    @timeWindow = @timeWindow OUTPUT, @errorCode = @errorCode OUTPUT,
    @errorType = @errorType OUTPUT, @errorId = @errorId OUTPUT,
    @errorTitle = @errorTitle OUTPUT, @errorMsg = @errorMsg OUTPUT;

IF (@errorCode IS NOT NULL)
BEGIN
    SELECT @errorId AS errorId, @errorType AS errorType, @errorCode AS errorCode,
           @errorTitle AS errorTitle, @errorMsg AS errorUserMessage, @procName AS errorProc;
    RETURN;
END

BEGIN TRY
    SELECT UPPER(CAST(h.PublicHasherId AS NVARCHAR(40))) AS PublicHasherId,
           h.DisplayName                                 AS DisplayName,
           h.Photo                                       AS Photo,
           k.KennelShortName                             AS HomeKennelShortName,
           k.KennelLogo                                  AS HomeKennelLogo,
           c.RunsTogether                                AS RunsTogether,
           c.LastTogether                                AS LastTogether
    FROM HC6.CoRunners(@userId) c
    JOIN HC.Hasher h ON h.id = c.UserId AND h.deleted = 0 AND ISNULL(h.Removed, 0) = 0
    LEFT JOIN HC.Kennel k ON k.id = h.HomeKennelId AND k.deleted = 0
    ORDER BY c.RunsTogether DESC, c.LastTogether DESC;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in getCoRunners',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
