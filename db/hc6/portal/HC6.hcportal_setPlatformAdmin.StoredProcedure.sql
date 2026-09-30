CREATE OR ALTER PROCEDURE [HC6].[hcportal_setPlatformAdmin]
    @deviceId             UNIQUEIDENTIFIER = NULL,
    @accessToken          NVARCHAR(1000)   = NULL,
    @targetHasherId       UNIQUEIDENTIFIER = NULL,
    @removed              SMALLINT         = 0,
    @canViewMonitor       SMALLINT         = NULL,
    @canManageNewsflash   SMALLINT         = NULL,
    @canEditKennel        SMALLINT         = NULL,
    @canManagePermissions SMALLINT         = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcportal_setPlatformAdmin
-- Description: Mints, changes or de-mints a platform admin (E12.F7.S1,
--   James 2026-09-30): the one write path for HC.PlatformAdmin, which until
--   now was seeded by hand. Upserts on UserId (the unique key) — a person
--   removed earlier is revived rather than duplicated — writes whichever
--   capabilities were passed (NULL = keep), and @removed = 1 de-mints.
--
--   Guards, because this is the platform's own power:
--     * caller must be a live platform admin with CanManagePermissions;
--     * a caller cannot de-mint themselves or drop their own
--       CanManagePermissions — the last person out would lock the door;
--     * the change cannot leave NOBODY with CanManagePermissions;
--     * the target must be a live, signed-in account.
--   Every change is written to LOG.GeneralLog with the before/after flags.
-- Parameters: @deviceId, @accessToken (auth); @targetHasherId;
--   @removed 0|1; the four capability flags, NULL to leave as is. A NEW
--   admin's unspecified flags default to 0.
-- Returns: rowset 0 — { Success, ErrorMessage }.
-- Author: Harrier Central
-- Created: 2026-09-30
-- HC5 Source: none (new)
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
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

IF NOT EXISTS (SELECT 1 FROM HC.PlatformAdmin pa
               WHERE pa.UserId = @callerId AND pa.removed = 0 AND pa.CanManagePermissions = 1)
BEGIN
    SELECT 0 AS Success, 'Not authorised: Platform Admin with CanManagePermissions required' AS ErrorMessage;
    RETURN;
END

IF (@targetHasherId IS NULL)
BEGIN
    SELECT 0 AS Success, 'A hasher is required' AS ErrorMessage;
    RETURN;
END

DECLARE @targetName NVARCHAR(250);
SELECT @targetName = COALESCE(NULLIF(TRIM(h.HashName), N''),
                              NULLIF(TRIM(CONCAT(h.FirstName, N' ', h.LastName)), N''),
                              h.Email)
FROM HC.Hasher h
WHERE h.id = @targetHasherId AND h.Removed = 0;
IF (@targetName IS NULL)
BEGIN
    SELECT 0 AS Success, 'That account does not exist or is disabled' AS ErrorMessage;
    RETURN;
END

SET @removed = CASE WHEN @removed = 1 THEN 1 ELSE 0 END;

-- The caller may not saw off the branch they are sitting on.
IF (@targetHasherId = @callerId AND (@removed = 1 OR @canManagePermissions = 0))
BEGIN
    SELECT 0 AS Success, 'You cannot remove your own platform admin access — ask another platform admin to' AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    BEGIN TRANSACTION;

    -- The row as it stands (if any), locked so two admins editing the same
    -- person cannot interleave.
    DECLARE @wasRemoved SMALLINT, @oldFlags NVARCHAR(50), @existed SMALLINT = 0;
    SELECT @existed = 1,
           @wasRemoved = CAST(pa.removed AS SMALLINT),
           @oldFlags = CONCAT(pa.CanViewMonitor, pa.CanManageNewsflash, pa.CanEditKennel, pa.CanManagePermissions)
    FROM HC.PlatformAdmin pa WITH (UPDLOCK, HOLDLOCK)
    WHERE pa.UserId = @targetHasherId;

    IF (@existed = 0)
    BEGIN
        IF (@removed = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 0 AS Success, @targetName + ' is not a platform admin' AS ErrorMessage;
            RETURN;
        END
        INSERT HC.PlatformAdmin (UserId, CanViewMonitor, CanManageNewsflash, CanEditKennel, CanManagePermissions, removed)
        VALUES (@targetHasherId,
                COALESCE(@canViewMonitor, 0), COALESCE(@canManageNewsflash, 0),
                COALESCE(@canEditKennel, 0),  COALESCE(@canManagePermissions, 0), 0);
        SET @oldFlags = N'(none)';
    END
    ELSE
    BEGIN
        UPDATE HC.PlatformAdmin
           SET removed              = @removed,
               -- A revived admin starts from the flags passed, not the old ones.
               CanViewMonitor       = COALESCE(@canViewMonitor,       CASE WHEN @wasRemoved = 1 THEN 0 ELSE CanViewMonitor END),
               CanManageNewsflash   = COALESCE(@canManageNewsflash,   CASE WHEN @wasRemoved = 1 THEN 0 ELSE CanManageNewsflash END),
               CanEditKennel        = COALESCE(@canEditKennel,        CASE WHEN @wasRemoved = 1 THEN 0 ELSE CanEditKennel END),
               CanManagePermissions = COALESCE(@canManagePermissions, CASE WHEN @wasRemoved = 1 THEN 0 ELSE CanManagePermissions END),
               updatedAt            = SYSDATETIMEOFFSET()
         WHERE UserId = @targetHasherId;
        IF (@wasRemoved = 1) SET @oldFlags = N'(removed)';
    END

    -- Nobody may be left holding the keys to this very screen.
    IF NOT EXISTS (SELECT 1 FROM HC.PlatformAdmin pa WHERE pa.removed = 0 AND pa.CanManagePermissions = 1)
    BEGIN
        ROLLBACK TRANSACTION;
        SELECT 0 AS Success, 'At least one platform admin must keep Manage permissions' AS ErrorMessage;
        RETURN;
    END

    DECLARE @newFlags NVARCHAR(50);
    SELECT @newFlags = CASE WHEN pa.removed = 1 THEN N'(removed)'
                            ELSE CONCAT(pa.CanViewMonitor, pa.CanManageNewsflash, pa.CanEditKennel, pa.CanManagePermissions) END
    FROM HC.PlatformAdmin pa WHERE pa.UserId = @targetHasherId;

    INSERT LOG.GeneralLog (LogSource, Message, StrParam1, Data, [Timestamp])
    VALUES (@procName,
            N'Platform admin ' + CAST(@targetHasherId AS NVARCHAR(36)) + N' (' + @targetName + N') '
              + CASE WHEN @removed = 1 THEN N'removed' WHEN @existed = 0 OR @wasRemoved = 1 THEN N'minted' ELSE N'changed' END,
            N'by ' + CAST(@callerId AS NVARCHAR(36)),
            N'flags monitor/newsflash/kennel/permissions: ' + @oldFlags + N' -> ' + @newFlags,
            SYSDATETIMEOFFSET());

    COMMIT TRANSACTION;
    SELECT 1 AS Success, NULL AS ErrorMessage;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_setPlatformAdmin',
            ERROR_MESSAGE(), @procName, @callerId);
    SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
GO
