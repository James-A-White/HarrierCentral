-- =====================================================================
-- Function: HC6.IsGeneratedEmail
-- Description: 1 when an account's address was made up by Harrier Central
--   rather than given by a person, so it reaches nobody (James, 2026-10-10).
--   The email is the account's key, so a hasher without one still needs a
--   unique address. Generated shapes:
--     hc-<12 hex>@noemail.invalid      import / bulk add with no address (2026-10-10)
--     URC:<code>@…                     invite-code placeholder accounts
--     removed_…                        a removed or GDPR-deleted account
--     <GUID>@harriercentral.com        older adds without an address
--     anonymous <word>@harriercentral.com   the 2022 anonymous batch
--   Addresses a kennel typed itself (fake@bmph3.com) are NOT generated: they
--   are the kennel's data and are left to bounce.
--   Senders exclude these (run emails, invites, the announcement) and the
--   portal and app show them in dark red. THE SAME RULE is copied in:
--     api/Endpoints/HcEmail.cs            GeneratedEmail.Is (both mailers refuse)
--     portal/lib/util/generated_email.dart
--     mobile-app/lib/util/generated_email.dart
--   Change all four together.
-- Parameters: @email - HC.Hasher.Email
-- Returns: SMALLINT 1 / 0
-- Author: Harrier Central
-- Created: 2026-10-10
-- =====================================================================
CREATE OR ALTER FUNCTION [HC6].[IsGeneratedEmail] (@email NVARCHAR(250))
RETURNS SMALLINT
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @e NVARCHAR(250) = LOWER(LTRIM(RTRIM(ISNULL(@email, ''))));
    DECLARE @at INT = CHARINDEX('@', @e);
    RETURN CASE
        WHEN @e LIKE '%@noemail.invalid'                                   THEN 1
        WHEN @e LIKE 'urc:%'                                               THEN 1
        WHEN @e LIKE 'removed[_]%'                                         THEN 1
        WHEN @e LIKE '%@harriercentral.com'
             AND (@e LIKE 'anonymous %'
                  OR (@at = 37 AND TRY_CAST(LEFT(@e, 36) AS UNIQUEIDENTIFIER) IS NOT NULL)) THEN 1
        ELSE 0 END;
END
GO
