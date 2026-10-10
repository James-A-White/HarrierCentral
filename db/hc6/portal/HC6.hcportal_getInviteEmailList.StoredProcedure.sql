CREATE OR ALTER PROCEDURE [HC6].[hcportal_getInviteEmailList]
    @deviceId        UNIQUEIDENTIFIER = NULL,
    @accessToken     NVARCHAR(1000)   = NULL,
    @publicKennelId  UNIQUEIDENTIFIER = NULL,
    @scope           NVARCHAR(20)     = NULL,  -- 'imported' | 'neverLoggedIn'
    @publicHasherIds NVARCHAR(MAX)    = NULL   -- '|'-separated, for 'imported'
AS
-- =====================================================================
-- Procedure: HC6.hcportal_getInviteEmailList
-- Description: Who "Email invite codes" would write to, and their codes
--   (E2.F2.S6, James 2026-10-10). Called by the InviteEmails API endpoint
--   with the portal admin's own token — the codes go to the API, never to
--   the browser.
--     'imported'      — the hashers the last "Import from file" added
--                       (@publicHasherIds), still in this kennel;
--     'neverLoggedIn' — everyone in this kennel (live row) whose account
--                       has never signed in to the app.
--   Never a removed or deleted account, nor one whose holder blocked all
--   email. Every listed hasher is given an invite code if they lack one
--   (nonApi_ensureUserInviteCode) — the one write here. Whether an
--   address can be delivered and whether it was invited in the last 7
--   days are reported, not filtered: the API decides and counts.
--   Gate: the same as adding members (hcportal_bulkAddHashers).
-- Returns:
--   On error: { Success = 0, ErrorMessage }
--   rowset 0: { Success = 1, ErrorMessage = NULL, kennelId, kennelName,
--               kennelShortName, kennelSlug, kennelLogo, adminId }
--   rowset 1: hasherId, publicHasherId, firstName, hashName, email,
--             inviteCode (the six letters), inviteEmailedAt, isPlaceholder
-- Author: Harrier Central
-- Created: 2026-10-10
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @authError NVARCHAR(255), @userId UNIQUEIDENTIFIER, @callerType INT;
EXEC HC6.ValidatePortalAuth @deviceId, @accessToken, @procName, @publicKennelId, @authError OUTPUT, @userId OUTPUT, @callerType OUTPUT;
IF @authError IS NOT NULL
BEGIN
    SELECT 0 AS Success, @authError AS ErrorMessage;
    RETURN;
END

DECLARE @kennelId UNIQUEIDENTIFIER = (SELECT k.id FROM HC.Kennel k WHERE k.PublicKennelId = @publicKennelId);
IF (@kennelId IS NULL)
BEGIN
    SELECT 0 AS Success, 'No kennel with that id.' AS ErrorMessage;
    RETURN;
END

IF (ISNULL((SELECT hkm.AppAccessFlags FROM HC.HasherKennelMap hkm WHERE hkm.UserId = @userId AND hkm.KennelId = @kennelId), 0) & 0x40000081) = 0
BEGIN
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (NEWID(), '<portal>', 'Not authorised', 'Caller may not manage members of this kennel', @procName, @userId, @kennelId);
    SELECT 0 AS Success, 'You are not authorised to invite members of this kennel.' AS ErrorMessage;
    RETURN;
END

IF (@scope IS NULL OR @scope NOT IN ('imported', 'neverLoggedIn'))
BEGIN
    SELECT 0 AS Success, 'Choose who to send the invite codes to.' AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    DECLARE @who TABLE (hasherId UNIQUEIDENTIFIER PRIMARY KEY);

    IF (@scope = 'imported')
        INSERT @who (hasherId)
        SELECT DISTINCT h.id
        FROM STRING_SPLIT(ISNULL(@publicHasherIds, ''), '|') s
        JOIN HC.Hasher h ON h.PublicHasherId = TRY_CAST(LTRIM(RTRIM(s.value)) AS UNIQUEIDENTIFIER)
        JOIN HC.HasherKennelMap k ON k.UserId = h.id AND k.KennelId = @kennelId AND k.removed = 0
        WHERE ISNULL(h.Removed, 0) = 0 AND h.deleted = 0 AND ISNULL(h.EmailBlocked, 0) = 0;
    ELSE
        INSERT @who (hasherId)
        SELECT DISTINCT h.id
        FROM HC.HasherKennelMap k
        JOIN HC.Hasher h ON h.id = k.UserId
        WHERE k.KennelId = @kennelId AND k.removed = 0
          AND ISNULL(h.Removed, 0) = 0 AND h.deleted = 0 AND ISNULL(h.EmailBlocked, 0) = 0
          AND h.LastLoginDateTime IS NULL;

    -- Everyone listed gets a code if they have none (a no-op when compliant).
    DECLARE @hid UNIQUEIDENTIFIER;
    DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT hasherId FROM @who;
    OPEN c;
    FETCH NEXT FROM c INTO @hid;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC HC6.nonApi_ensureUserInviteCode @userId = @hid;
        FETCH NEXT FROM c INTO @hid;
    END
    CLOSE c; DEALLOCATE c;

    SELECT 1 AS Success, NULL AS ErrorMessage,
           LOWER(CAST(k.id AS NVARCHAR(40))) AS kennelId, k.KennelName AS kennelName,
           k.KennelShortName AS kennelShortName, k.KennelUniqueShortName AS kennelSlug,
           k.KennelLogo AS kennelLogo, LOWER(CAST(@userId AS NVARCHAR(40))) AS adminId
    FROM HC.Kennel k WHERE k.id = @kennelId;

    SELECT LOWER(CAST(h.id AS NVARCHAR(40)))             AS hasherId,
           LOWER(CAST(h.PublicHasherId AS NVARCHAR(40))) AS publicHasherId,
           h.FirstName                                    AS firstName,
           h.HashName                                     AS hashName,
           h.Email                                        AS email,
           CASE WHEN h.ResetCode LIKE 'URC:%' THEN SUBSTRING(h.ResetCode, 5, 6) END AS inviteCode,
           h.InviteEmailedAt                              AS inviteEmailedAt,
           CASE WHEN h.Email LIKE '%@noemail.invalid' THEN 1 ELSE 0 END AS isPlaceholder
    FROM @who w
    JOIN HC.Hasher h ON h.id = w.hasherId
    ORDER BY LOWER(COALESCE(NULLIF(h.HashName, ''), h.FirstName, ''));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (NEWID(), '<portal>', 'Unhandled error in hcportal_getInviteEmailList', ERROR_MESSAGE(), @procName, @userId, @kennelId);
    SELECT 0 AS Success, 'The invite list could not be built. Please try again.' AS ErrorMessage;
END CATCH
