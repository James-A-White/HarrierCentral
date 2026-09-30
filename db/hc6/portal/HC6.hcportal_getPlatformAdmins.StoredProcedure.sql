CREATE OR ALTER PROCEDURE [HC6].[hcportal_getPlatformAdmins]
    @deviceId    UNIQUEIDENTIFIER = NULL,
    @accessToken NVARCHAR(1000)   = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcportal_getPlatformAdmins
-- Description: The platform staff list for HC Admin Tools › Platform
--   admins (E12.F7.S1, James 2026-09-30): every live HC.PlatformAdmin row
--   with the person behind it and the four capabilities the row grants.
--   HC.PlatformAdmin is the ONLY platform-wide grant — AppAccessFlags
--   0x40000000 is the kennel-founder bit (see /hc-authorizations) — so this
--   list is who can moderate rooms and DMs, merge accounts, run the
--   monitor, and shape permissions.
--   Requires an HC.PlatformAdmin row with CanManagePermissions: the person
--   who may hand out power is the person who may see who holds it.
-- Parameters: @deviceId, @accessToken (auth).
-- Returns:
--   On refusal: rowset 0 — { Success = 0, ErrorMessage }.
--   On success: rowset 0 — one row per admin (see contract), IsSelf = 1 on
--   the caller's own row so the portal can refuse to let them remove it.
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

BEGIN TRY
    SELECT
        h.id                                   AS HasherId,
        h.HashName,
        h.FirstName,
        h.LastName,
        h.Email,
        hk.KennelShortName                     AS HomeKennel,
        pa.CanViewMonitor,
        pa.CanManageNewsflash,
        pa.CanEditKennel,
        pa.CanManagePermissions,
        pa.createdAt                           AS CreatedAt,
        pa.updatedAt                           AS UpdatedAt,
        CAST(CASE WHEN pa.UserId = @callerId THEN 1 ELSE 0 END AS SMALLINT) AS IsSelf
    FROM HC.PlatformAdmin pa
    JOIN HC.Hasher h ON h.id = pa.UserId
    LEFT JOIN HC.Kennel hk ON hk.id = h.HomeKennelId
    WHERE pa.removed = 0
    ORDER BY TRIM(h.HashName), h.LastName, h.FirstName;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Unhandled error in hcportal_getPlatformAdmins',
            ERROR_MESSAGE(), @procName, @callerId);
    THROW;
END CATCH
GO
