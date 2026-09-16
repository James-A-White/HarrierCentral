CREATE OR ALTER PROCEDURE [HC6].[publicWeb_getPasskey]
    @credentialId NVARCHAR(500)
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_getPasskey
-- Description: The stored public key and counter for a passkey, plus the
--              device credentials it is bound to (E9.F7.S6). Called by the
--              Next.js login route BEFORE it verifies the authenticator's
--              signature with the public key; only if that verification
--              passes does the route turn the device credentials into a
--              member cookie. There is no token to validate here — the
--              passkey assertion IS the proof, and it can only be checked
--              in code — so this SP is reachable solely through
--              PublicWebAdminApi behind HC_INTERNAL_SECRET, and returns
--              nothing for an unknown credential.
-- Parameters:  @credentialId - base64url credential id from the assertion
-- Returns:     No rows = unknown. One row: deviceId, deviceSecret,
--              timeWindow, publicKey, counter, transports, hasherId,
--              publicHasherId, hashName, displayName, photo.
-- Author:      Harrier Central
-- Created:     2026-09-16
-- HC5 Source:  none
-- =====================================================================
SET NOCOUNT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
BEGIN TRY
    SELECT
        d.id                        AS deviceId,
        d.DeviceSecret              AS deviceSecret,
        d.TimeWindow                AS timeWindow,
        d.PasskeyPublicKey          AS publicKey,
        COALESCE(d.PasskeyCounter, 0) AS counter,
        COALESCE(d.PasskeyTransports, '') AS transports,
        h.id                        AS hasherId,
        h.PublicHasherId            AS publicHasherId,
        COALESCE(h.HashName, '')    AS hashName,
        COALESCE(h.DisplayName, '') AS displayName,
        COALESCE(h.Photo, '')       AS photo
    FROM HC.Device d
    INNER JOIN HC.Hasher h ON h.id = d.UserId AND h.Removed = 0 AND h.deleted = 0
    WHERE d.PasskeyCredentialId = @credentialId
      AND d.removed = 0;
END TRY
BEGIN CATCH
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<web>', 'Unhandled error in publicWeb_getPasskey', ERROR_MESSAGE(), @procName, NULL);
    THROW;
END CATCH
