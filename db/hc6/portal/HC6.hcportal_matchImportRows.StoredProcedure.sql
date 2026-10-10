CREATE OR ALTER PROCEDURE [HC6].[hcportal_matchImportRows]
    @deviceId       UNIQUEIDENTIFIER = NULL,
    @accessToken    NVARCHAR(1000)   = NULL,
    @publicKennelId UNIQUEIDENTIFIER = NULL,
    @rowsJson       NVARCHAR(MAX)    = NULL   -- [{firstName, lastName, hashName, eMail}, ...] in grid order
AS
-- =====================================================================
-- Procedure: HC6.hcportal_matchImportRows
-- Description: Before an "Import from file" is saved (E2.F2.S6, James
--   2026-10-10): rows that look like a member of THIS kennel — same first
--   and last name, or same hash name — but carry a DIFFERENT email. The
--   portal asks the admin whether each is the same person and whether to
--   use the new address. Only this kennel's members are considered, so a
--   common name is never matched to a stranger in another club.
--   canChangeEmail follows the 2026-09-23 ownership rule (as in
--   hcportal_updateKennelHasher): the member has never signed in (no
--   LastLoginDateTime, no HC.Device row) and this kennel is their home
--   (or they have none); and the new address is not already another
--   account's. Reads only.
-- Returns:
--   On error: { Success = 0, ErrorMessage }
--   rowset 0: { Success = 1, ErrorMessage = NULL }
--   rowset 1: rowNo (0-based, as sent), publicHasherId, hashName,
--             firstName, lastName, currentEmail, matchedBy ('name' |
--             'hashName'), signedIn, emailInUse, canChangeEmail
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
    SELECT 0 AS Success, 'You are not authorised to add members to this kennel.' AS ErrorMessage;
    RETURN;
END

BEGIN TRY
    DECLARE @rows TABLE (rowNo INT PRIMARY KEY, firstName NVARCHAR(250), lastName NVARCHAR(250), hashName NVARCHAR(250), email NVARCHAR(250));
    INSERT @rows (rowNo, firstName, lastName, hashName, email)
    SELECT CAST(j.[key] AS INT),
           NULLIF(LTRIM(RTRIM(x.firstName)), ''), NULLIF(LTRIM(RTRIM(x.lastName)), ''),
           NULLIF(LTRIM(RTRIM(x.hashName)), ''), NULLIF(LOWER(LTRIM(RTRIM(x.email))), '')
    FROM OPENJSON(ISNULL(@rowsJson, '[]')) j
    CROSS APPLY OPENJSON(j.value) WITH (
        firstName NVARCHAR(250) '$.firstName', lastName NVARCHAR(250) '$.lastName',
        hashName  NVARCHAR(250) '$.hashName',  email    NVARCHAR(250) '$.eMail') x;

    SELECT 1 AS Success, NULL AS ErrorMessage;

    -- A row with an email that is NOT a member's here, matched on name or
    -- hash name to a member whose address differs. Name beats hash name.
    ;WITH members AS (
        SELECT h.id, h.PublicHasherId, h.HashName, h.FirstName, h.LastName, h.Email, h.HomeKennelId,
               CASE WHEN h.LastLoginDateTime IS NOT NULL
                      OR EXISTS (SELECT 1 FROM HC.Device d WHERE d.UserId = h.id) THEN 1 ELSE 0 END AS signedIn
        FROM HC.HasherKennelMap k
        JOIN HC.Hasher h ON h.id = k.UserId
        WHERE k.KennelId = @kennelId AND k.removed = 0 AND ISNULL(h.Removed, 0) = 0 AND h.deleted = 0
    ), cand AS (
        SELECT r.rowNo, m.*, r.email AS fileEmail,
               CASE WHEN r.firstName IS NOT NULL AND r.lastName IS NOT NULL
                     AND LOWER(LTRIM(RTRIM(m.FirstName))) = LOWER(r.firstName)
                     AND LOWER(LTRIM(RTRIM(m.LastName)))  = LOWER(r.lastName) THEN 'name' ELSE 'hashName' END AS matchedBy,
               ROW_NUMBER() OVER (PARTITION BY r.rowNo ORDER BY
                   CASE WHEN r.firstName IS NOT NULL AND r.lastName IS NOT NULL
                         AND LOWER(LTRIM(RTRIM(m.FirstName))) = LOWER(r.firstName)
                         AND LOWER(LTRIM(RTRIM(m.LastName)))  = LOWER(r.lastName) THEN 0 ELSE 1 END) AS pick
        FROM @rows r
        JOIN members m
          ON (    (r.firstName IS NOT NULL AND r.lastName IS NOT NULL
                   AND LOWER(LTRIM(RTRIM(m.FirstName))) = LOWER(r.firstName)
                   AND LOWER(LTRIM(RTRIM(m.LastName)))  = LOWER(r.lastName))
               OR (r.hashName IS NOT NULL AND LOWER(LTRIM(RTRIM(m.HashName))) = LOWER(r.hashName)))
        WHERE r.email IS NOT NULL
          AND r.email NOT LIKE '%@noemail.invalid'   -- a made-up address is "no email", never a new one to offer
          AND LOWER(ISNULL(m.Email, '')) <> r.email
          -- the file's address is not already this kennel's member (that row is matched by email)
          AND NOT EXISTS (SELECT 1 FROM members m2 WHERE LOWER(m2.Email) = r.email)
    )
    SELECT c.rowNo,
           LOWER(CAST(c.PublicHasherId AS NVARCHAR(40))) AS publicHasherId,
           c.HashName AS hashName, c.FirstName AS firstName, c.LastName AS lastName,
           c.Email AS currentEmail, c.matchedBy, c.signedIn,
           CASE WHEN EXISTS (SELECT 1 FROM HC.Hasher x WHERE LOWER(x.Email) = c.fileEmail) THEN 1 ELSE 0 END AS emailInUse,
           CASE WHEN c.signedIn = 0
                 AND (c.HomeKennelId = @kennelId OR c.HomeKennelId IS NULL)
                 AND NOT EXISTS (SELECT 1 FROM HC.Hasher x WHERE LOWER(x.Email) = c.fileEmail)
                THEN 1 ELSE 0 END AS canChangeEmail
    FROM cand c
    WHERE c.pick = 1
    ORDER BY c.rowNo;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, kennelId)
    VALUES (NEWID(), '<portal>', 'Unhandled error in hcportal_matchImportRows', ERROR_MESSAGE(), @procName, @userId, @kennelId);
    SELECT 0 AS Success, 'The file could not be checked against the members. Please try again.' AS ErrorMessage;
END CATCH
