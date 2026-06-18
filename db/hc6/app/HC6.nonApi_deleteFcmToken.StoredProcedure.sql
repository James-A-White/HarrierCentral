CREATE OR ALTER PROCEDURE [HC6].[nonApi_deleteFcmToken]
    @fcmToken NVARCHAR(500)
AS
-- =====================================================================
-- Procedure: HC6.nonApi_deleteFcmToken
-- Description: Clears a stale or invalid FCM registration token from
--   HC.Device by setting FcmToken = NULL and stamping FcmTokenDeleted.
--   Called by AppApiHC6, PortalApiHC6, and RunCheckInNotification
--   whenever FCM returns UNREGISTERED or NOT_FOUND for a token.
-- Parameters:
--   @fcmToken - The stale FCM registration token to clear.
-- Returns: Nothing. Fire-and-forget helper; errors swallowed by callers.
-- Author: Harrier Central
-- Created: 2026-06-15
-- HC5 Source: HC5.hcinternalapi_removeStaleFcmToken (partial),
--             AppApiHC6.DeleteFcmToken inline SQL,
--             PortalApiHC6.DeleteFcmToken inline SQL
-- Breaking Changes vs HC5:
--   HC5.hcinternalapi_removeStaleFcmToken did DELETE FROM HC.Device,
--   destroying the device record and its location/audit history.
--   HC6 sets FcmToken = NULL and stamps FcmTokenDeleted, preserving
--   the device row. AppApiHC6 already used this safer pattern; HC6
--   standardises it across all callers.
-- =====================================================================
SET NOCOUNT ON;

IF @fcmToken IS NULL OR LEN(@fcmToken) = 0 RETURN;

UPDATE HC.Device
SET    FcmToken        = NULL,
       FcmTokenDeleted = SYSUTCDATETIME()
WHERE  FcmToken = @fcmToken;
