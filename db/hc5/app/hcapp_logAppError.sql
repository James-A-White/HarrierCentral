



CREATE PROCEDURE [HC5].[hcapp_logAppError]

 @deviceId uniqueidentifier,
 @accessToken nvarchar(1000),
 @httpBody nvarchar(MAX) = NULL,
 @errorText nvarchar(1000),
 @extraData nvarchar(MAX) = NULL

AS

-- EXEC HC3.gdprDelete @userId = 'DCA00F27-5672-4435-B798-154E16ECD74B',@accessToken = 'aaaa'

BEGIN

SET NOCOUNT ON
	
INSERT INTO [HC].[AppError]
           (
            [DeviceId]
           ,[HttpBody]
           ,[ErrorText]
           ,[ExtraData]
           )
     VALUES
           (
			@deviceId,
			@httpBody,
			@errorText,
			@extraData
		   )

SELECT 'Error recorded' as result

END


