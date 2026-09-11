CREATE OR ALTER PROCEDURE [HC6].[hcportal_setHasherNotesSuppression]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL,
    @hasherId    UNIQUEIDENTIFIER,
    @suppressed  SMALLINT
AS
-- =====================================================================
-- Procedure: HC6.hcportal_setHasherNotesSuppression
-- Description: The Harrier Central override on shared run notes (E3.F4.S5):
--   a Platform Admin hides (1) or allows (0) every note a hasher shares, in
--   every kennel, for a breach of Harrier Central's content rules. Held as
--   bit 0x2000 of HC.Hasher.Preferences; the hasher's private notes are never
--   affected. Requires an HC.PlatformAdmin row with CanEditKennel.
-- Returns: rowset 0 — success envelope.
-- Author: Harrier Central
-- Created: 2026-09-11
-- HC5 Source: none (new)
-- Breaking Changes: none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName   NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @authError  NVARCHAR(500);
DECLARE @callerId   UNIQUEIDENTIFIER;
DECLARE @callerType INT;

EXEC HC6.ValidatePortalAuth
    @deviceId, @accessToken, @procName, NULL,
    @authError OUTPUT, @callerId OUTPUT, @callerType OUTPUT;

IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM HC.PlatformAdmin pa WHERE pa.UserId = @callerId AND pa.removed = 0 AND pa.CanEditKennel = 1)
BEGIN
    SELECT 0 AS Success, 'Not authorised: Platform Admin with CanEditKennel required' AS ErrorMessage;
    RETURN;
END

IF (@hasherId IS NULL OR @suppressed NOT IN (0, 1))
BEGIN
    SELECT 0 AS Success, 'hasherId and suppressed (0/1) are required' AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;
    UPDATE HC.Hasher
       SET Preferences = CASE WHEN @suppressed = 1 THEN Preferences | 8192 ELSE Preferences & ~8192 END,
           updatedAt = GETDATE()
     WHERE id = @hasherId AND deleted = 0;
    IF (@@ROWCOUNT = 0)
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success, 'Hasher not found' AS ErrorMessage;
        RETURN;
    END
    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_setHasherNotesSuppression',
            ERROR_MESSAGE(), @procName, @callerId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
