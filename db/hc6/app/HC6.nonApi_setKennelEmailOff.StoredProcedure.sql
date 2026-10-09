CREATE OR ALTER PROCEDURE [HC6].[nonApi_setKennelEmailOff]

    @userId   UNIQUEIDENTIFIER = NULL,
    @kennelId UNIQUEIDENTIFIER = NULL

AS
-- =====================================================================
-- Procedure: HC6.nonApi_setKennelEmailOff
-- Description: The unsubscribe link (E19.F3.S2). Sets the hasher's
--   email-alert setting for the kennel to 2 (off) — the same value the
--   app's dialog writes — and clears any per-run "on" overrides for that
--   kennel's runs, so one tap really does stop the emails. Called by the
--   EmailUnsubscribe API endpoint after it has verified the signed
--   token; no device auth. Idempotent.
-- Returns: { Success, ErrorMessage, kennelName, kennelSlug } envelope.
-- Author: Harrier Central
-- Created: 2026-10-09
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    IF (@userId IS NULL OR @kennelId IS NULL)
        THROW 50000, 'userId and kennelId are required', 1;

    BEGIN TRANSACTION;

    UPDATE HC.HasherKennelMap
    SET KennelEmailAlertPreference = 2
    WHERE UserId = @userId AND KennelId = @kennelId AND removed = 0
      AND ISNULL(KennelEmailAlertPreference, 0) <> 2;

    UPDATE hem
    SET EventEmailAlertPreference = 2
    FROM HC.HasherEventMap hem
    JOIN HC.Event e ON e.id = hem.EventId
    WHERE hem.UserId = @userId AND e.KennelId = @kennelId
      AND hem.EventEmailAlertPreference = 1;

    COMMIT TRANSACTION;

    SELECT 1 AS Success, NULL AS ErrorMessage,
           k.KennelName AS kennelName, k.KennelUniqueShortName AS kennelSlug
    FROM HC.Kennel k WHERE k.id = @kennelId;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (NEWID(), '<api>', 'Unhandled error in setKennelEmailOff', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), @userId, @kennelId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage, NULL AS kennelName, NULL AS kennelSlug;
END CATCH
