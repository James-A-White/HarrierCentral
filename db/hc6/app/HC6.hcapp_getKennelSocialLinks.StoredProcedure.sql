CREATE OR ALTER PROCEDURE [HC6].[hcapp_getKennelSocialLinks]
    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @publicKennelId UNIQUEIDENTIFIER = NULL,
    @kennelId       UNIQUEIDENTIFIER = NULL
AS
-- =====================================================================
-- Procedure: HC6.hcapp_getKennelSocialLinks
-- Description: A kennel's social and chat links (E12.F4.S4) as the caller
--   may see them — fetched when the kennel page opens, never synced. The
--   app's kennels sync goes to every phone, and members-only entries are
--   chat-group invite links (what spammers harvest), so they are not put
--   in the sync: they are handed out here, to members only. A link is of
--   no use offline anyway — it opens another app.
--   Who sees the members-only entries: the kennel's members
--   (MembershipExpirationDate in the future — never IsMember) and its
--   admins (AppAccessFlags superAdmin | authIsAdmin, 0x40000081). Everyone
--   else gets the public entries. The rule itself is
--   HC6.KennelSocialLinksVisible, shared with publicWeb_getLandingPageData.
--   Called by the app (internal @kennelId) and by the signed-in public web
--   as a browser device (@publicKennelId). The public id wins when both
--   are sent.
-- Parameters: @deviceId, @accessToken (standard device token, no compound)
--             @publicKennelId | @kennelId — the kennel
-- Returns: rowset 0 — { socialLinksJson (NVARCHAR(MAX) JSON array or NULL),
--   includesMembers (SMALLINT 1 = the members-only entries are included) }.
--   An unknown, deleted or removed kennel returns one row of NULL / 0.
--   Auth failure: the standard error rowset instead.
-- Author: Harrier Central
-- Created: 2026-10-14
-- Idempotency: read-only — reads the kennel and the caller's membership.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @errorType INT;
DECLARE @errorTitle NVARCHAR(500), @errorMsg NVARCHAR(MAX);
DECLARE @userId UNIQUEIDENTIFIER, @deviceSecret NVARCHAR(150), @timeWindow INT;

EXEC HC6.ValidateAppAuth
    @deviceId = @deviceId, @accessToken = @accessToken, @procName = @procName,
    @spNumber = 155, @param = NULL,
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
    -- The public id is resolved once, at the door (/hc-primary-keys).
    DECLARE @kid UNIQUEIDENTIFIER, @json NVARCHAR(MAX);
    IF (@publicKennelId IS NOT NULL)
        SELECT @kid = k.id, @json = k.SocialLinksJson
        FROM HC.Kennel k
        WHERE k.PublicKennelId = @publicKennelId AND k.deleted = 0 AND ISNULL(k.removed, 0) = 0;
    ELSE IF (@kennelId IS NOT NULL)
        SELECT @kid = k.id, @json = k.SocialLinksJson
        FROM HC.Kennel k
        WHERE k.id = @kennelId AND k.deleted = 0 AND ISNULL(k.removed, 0) = 0;

    DECLARE @includeMembers SMALLINT = 0;
    IF (@kid IS NOT NULL AND @json IS NOT NULL
        AND EXISTS (SELECT 1 FROM HC.HasherKennelMap hkm
                    WHERE hkm.UserId = @userId AND hkm.KennelId = @kid
                      AND (hkm.MembershipExpirationDate > SYSDATETIMEOFFSET()
                           OR (ISNULL(hkm.AppAccessFlags, 0) & 0x40000081) <> 0)))
        SET @includeMembers = 1;

    SELECT HC6.KennelSocialLinksVisible(@json, @includeMembers) AS socialLinksJson,
           @includeMembers                                     AS includesMembers;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), HC6.DeviceHcVersion(@deviceId), 'Unhandled error in getKennelSocialLinks',
            ERROR_MESSAGE(), @procName, @userId);
    THROW;
END CATCH
GO
