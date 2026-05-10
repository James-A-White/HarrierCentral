
CREATE PROCEDURE [HC5].[hcapp_checkConnection]

@deviceId uniqueidentifier,
@accessToken nvarchar(1000)

AS

BEGIN

	SET NOCOUNT ON
	SELECT 'Connected' as result

END
