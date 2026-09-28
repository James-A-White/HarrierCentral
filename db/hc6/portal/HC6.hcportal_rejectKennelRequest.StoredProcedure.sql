CREATE OR ALTER PROCEDURE [HC6].[hcportal_rejectKennelRequest]
    @deviceId        UNIQUEIDENTIFIER = NULL,
    @accessToken     NVARCHAR(1000)   = NULL,
    @kennelImportIds NVARCHAR(MAX),
    @newStatus       SMALLINT,
    @reviewNote      NVARCHAR(MAX)    = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcportal_rejectKennelRequest
-- Description: Closes kennel requests without creating a kennel
--   (E12.F1.S5): rejected (3), spam (4) or a duplicate (5), with an
--   optional note — or reopens a closed one (1) when it was closed by
--   mistake. Takes several ids at once, '|'-delimited, because the spam
--   comes in bursts and the queue is cleared in one pass. An approved
--   request is never touched: its kennel exists, and removing a kennel is
--   a different decision made on the kennel page.
--   Replaces the DELETE branch of the INSTEAD OF trigger on
--   EXT.vwOfficeForms_KennelImport (HC3W), which set removed = 1.
--   Requires an HC.PlatformAdmin row with CanEditKennel.
-- Parameters: @deviceId, @accessToken (auth);
--   @kennelImportIds — one or more KennelImportIds, '|'-delimited;
--   @newStatus — 1 reopen · 3 rejected · 4 spam · 5 duplicate;
--   @reviewNote — optional, at most 1000 characters (replaces the old note
--   when given).
-- Returns: rowset 0 — { Success, ErrorMessage, UpdatedCount }.
-- Author: Harrier Central
-- Created: 2026-09-28
-- HC5 Source: none (replaces trgVwOfficeForms_KennelImport DELETE, HC3W)
-- Breaking Changes: none (new)
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName   NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @authError  NVARCHAR(255);
DECLARE @callerId   UNIQUEIDENTIFIER;
DECLARE @callerType INT;

EXEC HC6.ValidatePortalAuth
    @deviceId, @accessToken, @procName, NULL,
    @authError OUTPUT, @callerId OUTPUT, @callerType OUTPUT;

IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage, 0 AS UpdatedCount;
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM HC.PlatformAdmin pa
               WHERE pa.UserId = @callerId AND pa.removed = 0 AND pa.CanEditKennel = 1)
BEGIN
    SELECT 0 AS Success, 'Not authorised: Platform Admin with CanEditKennel required' AS ErrorMessage,
           0 AS UpdatedCount;
    RETURN;
END

SET @reviewNote = NULLIF(TRIM(@reviewNote), N'');

IF (@newStatus NOT IN (1, 3, 4, 5) OR LEN(COALESCE(@kennelImportIds, N'')) = 0
    OR LEN(@reviewNote) > 1000)
BEGIN
    SELECT 0 AS Success,
           CASE WHEN LEN(@reviewNote) > 1000 THEN 'The note may be at most 1000 characters'
                ELSE 'kennelImportIds and newStatus (1, 3, 4 or 5) are required' END AS ErrorMessage,
           0 AS UpdatedCount;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @ids TABLE (id UNIQUEIDENTIFIER PRIMARY KEY);
    INSERT @ids (id)
    SELECT DISTINCT TRY_CAST(TRIM(s.value) AS UNIQUEIDENTIFIER)
    FROM STRING_SPLIT(@kennelImportIds, '|') s
    WHERE TRY_CAST(TRIM(s.value) AS UNIQUEIDENTIFIER) IS NOT NULL;

    UPDATE ki SET
        RequestStatus = @newStatus,
        ReviewNote    = COALESCE(@reviewNote, ki.ReviewNote),
        ReviewedBy    = @callerId,
        ReviewedAt    = SYSDATETIMEOFFSET(),
        -- A reopened request goes back to the queue; a closed one can no
        -- longer be confirmed by its email code.
        ConfirmCode   = CASE WHEN @newStatus = 1 THEN ki.ConfirmCode ELSE NULL END,
        removed       = CASE WHEN @newStatus = 1 THEN 0 ELSE 1 END,
        updatedAt     = GETDATE()
    FROM EXT.OfficeForms_KennelImport ki
    JOIN @ids i ON i.id = ki.KennelImportId
    WHERE ki.RequestStatus <> 2
      AND ki.KennelId IS NULL;

    DECLARE @updated INT = @@ROWCOUNT;

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage, @updated AS UpdatedCount;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_rejectKennelRequest',
            ERROR_MESSAGE(), @procName, @callerId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage, 0 AS UpdatedCount;
END CATCH
GO
