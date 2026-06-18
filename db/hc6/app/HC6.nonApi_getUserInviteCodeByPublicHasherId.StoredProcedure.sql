CREATE OR ALTER PROCEDURE [HC6].[nonApi_getUserInviteCodeByPublicHasherId]
    @publicHasherId UNIQUEIDENTIFIER
AS
-- =====================================================================
-- Procedure: HC6.nonApi_getUserInviteCodeByPublicHasherId
-- Description: Resolves a hasher's email address and invite code from
--   their public hasher ID so the EmailInviteCode Azure Function can
--   send an invite without exposing the email address to the client.
--   Called only from the EmailInviteCode endpoint — never from the app.
-- Parameters:
--   @publicHasherId - HC.Hasher.PublicHasherId (from hcapp_findHashersByHashName)
-- Returns:
--   Single row: { Email, InviteCode } or empty set if not found / removed.
-- Author: Harrier Central
-- Created: 2026-06-15
-- HC5 Source: HC.nonApi_getUserInviteCodeByPublicHasherId
-- Breaking Changes vs HC5 (HC schema):
--   Moved from HC schema to HC6 schema.
-- =====================================================================
SET NOCOUNT ON;

SELECT
    h.Email,
    REPLACE(h.ResetCode, 'URC:', '') AS InviteCode
FROM HC.Hasher h
WHERE h.PublicHasherId = @publicHasherId
  AND h.Removed        = 0;
