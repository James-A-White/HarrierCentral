CREATE OR ALTER PROCEDURE [HC].[nonApi_getUserInviteCodeByPublicHasherId]

    @publicHasherId UNIQUEIDENTIFIER

AS
-- =====================================================================
-- Procedure: HC.nonApi_getUserInviteCodeByPublicHasherId
-- Description: Server-side companion to HC.nonApi_getUserInviteCode.
--   Resolves a hasher's email address and invite code from their
--   public hasher ID so the EmailInviteCode Azure Function can send
--   an invite without exposing the email address to the client.
--   Called only from the EmailInviteCode endpoint — never from the app.
-- Parameters:
--   @publicHasherId - HC.Hasher.PublicHasherId (from hcapp_findHashersByHashName)
-- Returns:
--   Single row: { Email, InviteCode } or empty set if not found / removed.
-- Author: Harrier Central
-- Created: 2026-06-04
-- =====================================================================
SET NOCOUNT ON;

SELECT
    h.Email,
    REPLACE(h.ResetCode, 'URC:', '') AS InviteCode
FROM HC.Hasher h
WHERE h.PublicHasherId = @publicHasherId
  AND h.Removed = 0;
