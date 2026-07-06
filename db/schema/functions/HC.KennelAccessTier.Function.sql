CREATE OR ALTER FUNCTION [HC].[KennelAccessTier] (@userId UNIQUEIDENTIFIER, @kennelId UNIQUEIDENTIFIER)
RETURNS TABLE AS RETURN
(
    SELECT
        CASE WHEN COALESCE(hkm.KennelStanding, 0) & 0x0100 <> 0 THEN 20      -- admin
             WHEN COALESCE(hkm.KennelStanding, 0) & 0x0107 <> 0 THEN 10      -- member-tier (MEMBER|ALUMNI|TRUSTED|ADMIN)
             ELSE 0 END AS Tier,
        COALESCE(hkm.KennelStanding, 0) AS Standing
    FROM (SELECT 1 AS one) AS d
    LEFT JOIN HC.HasherKennelMap hkm
        ON hkm.UserId = @userId AND hkm.KennelId = @kennelId
);
GO
