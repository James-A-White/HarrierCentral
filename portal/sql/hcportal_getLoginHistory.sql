SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [HC5].[hcportal_getLoginHistory]
	
	-- required parameters
	@publicHasherId uniqueidentifier = NULL,
	@accessToken nvarchar(1000) = NULL,
	@userId uniqueidentifier = NULL,

	-- optional parameters
	@ipAddress nvarchar(100) = NULL,
	@ipGeoDetails nvarchar(2000) = NULL

AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @now datetime2 = GETDATE()
	DECLARE @cutoffDate datetime2 = DATEADD(year, -1, @now)

	DECLARE @errorId uniqueidentifier
	DECLARE @isError int = 0
	DECLARE @errorTitle nvarchar(500) = ''

	-- Validation: publicHasherId
	IF (@publicHasherId IS NULL) OR (datalength(@publicHasherId) != 16)
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'Null or invalid publicHasherId'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) 
		VALUES (@errorId, '<unknown>', 'Null or empty publicHasherId',
			'Null or empty publicHasherId was passed to ' + OBJECT_NAME(@@PROCID),
			OBJECT_NAME(@@PROCID), @publicHasherId)
		
		SELECT 
			@errorId as errorId,
			cast(2 as int) as errorType,
			@errorTitle as errorTitle,
			'Null or empty value was passed as the publicHasherId to ' + OBJECT_NAME(@@PROCID) as errorUserMessage,
			'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage,
			OBJECT_NAME(@@PROCID) as errorProc
	END

	-- Validation: userId
	IF (@userId IS NULL) OR (datalength(@userId) != 16)
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'Null or invalid userId'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) 
		VALUES (@errorId, '<unknown>', 'Null or empty userId',
			'Null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),
			OBJECT_NAME(@@PROCID), @publicHasherId)
		
		SELECT 
			@errorId as errorId,
			cast(2 as int) as errorType,
			@errorTitle as errorTitle,
			'Null value was passed as the userId to ' + OBJECT_NAME(@@PROCID) as errorUserMessage,
			'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage,
			OBJECT_NAME(@@PROCID) as errorProc
	END

	-- Validation: Access token
	IF (HC.CHECK_PORTAL_ACCESS_TOKEN(@publicHasherId, OBJECT_NAME(@@PROCID), @accessToken, NULL) = 0) AND (@isError = 0) 
	BEGIN
		SET @errorId = newid()
		SET @errorTitle = 'Invalid access token'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId, string_1) 
		VALUES (@errorId, '<unknown>', 'Invalid access token',
			'An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),
			OBJECT_NAME(@@PROCID), @publicHasherId, @accessToken)

		SELECT 
			@errorId as errorId,
			cast(3 as int) as errorType,
			@errorTitle as errorTitle,
			'An invalid access token was passed to ' + OBJECT_NAME(@@PROCID) as errorUserMessage,
			'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage,
			OBJECT_NAME(@@PROCID) as errorProc
		SET @isError = 1
	END

	-- Logging
	INSERT INTO [LOG].[GeneralLog]
		([LogSource], [Message], [Data], [Timestamp])
	VALUES (
		'Admin Portal: hcportal_getLoginHistory',
		CASE WHEN @isError = 1 THEN @errorTitle + ' ' ELSE '' END
			+ COALESCE(@ipAddress, '<no IP address>')
			+ ' >> ' + COALESCE(CAST(@userId AS nvarchar(100)), '<no userId>'),
		COALESCE(@ipGeoDetails, '{"ip": "<no IP address>"}'),
		@now
	)

	IF (@isError = 1)
	BEGIN
		RETURN
	END

	-- =============================================
	-- Return login history for the specified user
	-- Last 365 days, ordered most recent first
	-- =============================================
	SELECT 
		ll.LoginDate AS loginDate,
		ll.HcVersion AS hcVersion,
		COALESCE(ll.SystemVersion, '') AS systemVersion,
		CASE WHEN ll.SystemName LIKE '%ios%' THEN 1 ELSE 0 END AS isIphone,
		COALESCE(c.Latitude, 0.0) AS latitude,
		COALESCE(c.Longitude, 0.0) AS longitude,
		COALESCE(c.CityFullName, '') AS locationName
	FROM HC.LaunchAndLogin ll WITH (NOLOCK)
	LEFT OUTER JOIN HC.City c WITH (NOLOCK) ON c.id = ll.CityId
	WHERE ll.UserId = @userId
		AND ll.LoginDate > @cutoffDate
	ORDER BY ll.LoginDate DESC
	OPTION (RECOMPILE)

END
GO
