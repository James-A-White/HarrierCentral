-- Run-once (James, 2026-10-17, permissions audit #3): refuse the legacy HC5
-- third-party sign-in, which the 2.x app reaches through the old AppApi. It
-- trusted the provider ids and email the caller sent, with no server-side
-- check of the provider's token. Same parameters as before (2.x calls still
-- bind); the reply is HC5's own error row, which the 2.x app shows. The
-- original is kept in db/deprecated/HC5.hcapp_processThirdPartyLogin.
-- original-2026-10-17.sql for the verified rebuild (E1.F1.S8). The HC6 copy
-- refuses the same way (SP build 87).
ALTER PROCEDURE [HC5].[hcapp_processThirdPartyLogin]
 @deviceId nvarchar(50),
 @accessToken nvarchar(1000),
 @hashersUpdatedAfter nvarchar(50),
 @firstName nvarchar(120),
 @lastName nvarchar(120),
 @hashName nvarchar(120),
 @email nvarchar(120),
 @photo nvarchar(2000),
 @thirdPartyLoginType nvarchar(120),
 @thirdPartyUserId nvarchar(1000),
 @thirdPartyAccessToken nvarchar(1000),
 @thirdPartyAuthorizationCode nvarchar(1000),
 @thirdPartyAccessTokenExpires nvarchar(150) = '1/1/2100',
 @includeInGlobalHashDirectory int = -1,
 @hcVersion nvarchar(100),
 @latitude decimal(18,15) = 0,
 @longitude decimal(19,15) = 0,
 @thirdPartyEmail nvarchar(120)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @errorId UNIQUEIDENTIFIER = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, string_1)
    VALUES (@errorId, LEFT(@hcVersion, 50), 'Third-party sign-in refused',
            CONCAT('HC5, until the verified rebuild (E1.F1.S8); type=', LEFT(ISNULL(@thirdPartyLoginType, '?'), 40)),
            OBJECT_NAME(@@PROCID), NULL, LEFT(@deviceId, 50));
    SELECT @errorId AS errorId,
           CAST(13 AS INT) AS errorType,
           'Sign in with your email' AS errorTitle,
           'Apple and Google sign-in are not available at the moment. Please sign in with the code we email you instead.' AS errorUserMessage,
           'Refused until the verified rebuild (E1.F1.S8).' AS debugMessage,
           OBJECT_NAME(@@PROCID) AS errorProc;
END
GO
