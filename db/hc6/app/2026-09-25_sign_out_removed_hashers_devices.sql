-- =====================================================================
-- RUN-ONCE: sign out every device that belongs to a removed hasher.
--
-- Until 2026-09-25, HC6.hcapp_gdprDelete scrubbed the Hasher row and left
-- the person's devices alone: still signed in, still holding live push
-- tokens. The SP now signs them out itself. This does the same for the
-- hashers deleted before that change.
--
-- Measured 2026-09-25: 25 devices belong to removed hashers; 8 hold a
-- push token. NONE was used more than a day after its hasher was removed
-- (so no one working is locked out). The check is repeated below and the
-- script refuses to run if that has changed.
--
-- Each device gets what hcapp_signOutDevice gives one (see its header):
-- a new DeviceSecret, SignedOutAt (kept if already set), FcmToken and
-- ApnsToken cleared, removed = 1. HC.Device has no triggers.
--
-- Deploy HC6.hcapp_gdprDelete 1.1.0 first, or a deletion made in between
-- is missed. Idempotent: a second run finds nothing to change.
-- After running: move this file to db/hc6/app/archive/.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Guard: nothing still in use.
IF EXISTS (
    SELECT 1
    FROM HC.Device d
    JOIN HC.Hasher h ON h.id = d.UserId
    WHERE h.Removed = 1
      AND d.LastLogin > DATEADD(DAY, 1, CAST(h.updatedAt AS DATETIMEOFFSET(7))))
BEGIN
    SELECT 'REFUSED: a removed hasher''s device was used after the removal. Investigate first.' AS result;
    SELECT h.id AS hasherId, d.id AS deviceId, h.updatedAt AS hasherUpdatedAt, d.LastLogin
    FROM HC.Device d JOIN HC.Hasher h ON h.id = d.UserId
    WHERE h.Removed = 1
      AND d.LastLogin > DATEADD(DAY, 1, CAST(h.updatedAt AS DATETIMEOFFSET(7)));
    RETURN;
END

SELECT 'before' AS stage,
       COUNT(*) AS devicesOfRemovedHashers,
       SUM(CASE WHEN d.FcmToken IS NOT NULL OR d.ApnsToken IS NOT NULL THEN 1 ELSE 0 END) AS withPushToken,
       SUM(CASE WHEN d.SignedOutAt IS NULL THEN 1 ELSE 0 END) AS stillSignedIn
FROM HC.Device d JOIN HC.Hasher h ON h.id = d.UserId
WHERE h.Removed = 1;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @devId UNIQUEIDENTIFIER, @binaryData VARBINARY(MAX), @newSecret NVARCHAR(150);
    DECLARE devs CURSOR LOCAL FAST_FORWARD FOR
        SELECT d.id
        FROM HC.Device d JOIN HC.Hasher h ON h.id = d.UserId
        WHERE h.Removed = 1
          AND (d.SignedOutAt IS NULL OR d.FcmToken IS NOT NULL
               OR d.ApnsToken IS NOT NULL OR d.removed = 0);
    OPEN devs;
    FETCH NEXT FROM devs INTO @devId;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @binaryData = CRYPT_GEN_RANDOM(150);
        SELECT @newSecret = LEFT(UPPER(REPLACE(REPLACE(
            CAST('' AS XML).value('xs:base64Binary(sql:variable("@binaryData"))', 'varchar(max)'),
            '+', ''), '/', '')), 75);

        UPDATE HC.Device
           SET DeviceSecret = @newSecret,
               SignedOutAt  = COALESCE(SignedOutAt, SYSDATETIMEOFFSET()),
               FcmToken     = NULL,
               ApnsToken    = NULL,
               removed      = 1,
               updatedAt    = GETDATE()
         WHERE id = @devId;

        FETCH NEXT FROM devs INTO @devId;
    END
    CLOSE devs;
    DEALLOCATE devs;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;   -- FIRST: the log must survive
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Run-once sign-out of removed hashers'' devices failed',
            ERROR_MESSAGE(), '2026-09-25_sign_out_removed_hashers_devices', NULL);
    THROW;
END CATCH

SELECT 'after' AS stage,
       COUNT(*) AS devicesOfRemovedHashers,
       SUM(CASE WHEN d.FcmToken IS NOT NULL OR d.ApnsToken IS NOT NULL THEN 1 ELSE 0 END) AS withPushToken,
       SUM(CASE WHEN d.SignedOutAt IS NULL THEN 1 ELSE 0 END) AS stillSignedIn
FROM HC.Device d JOIN HC.Hasher h ON h.id = d.UserId
WHERE h.Removed = 1;
