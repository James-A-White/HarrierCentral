SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [HC5].[hcportal_toggleKennelSong]
	
	-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
	@publicHasherId uniqueidentifier = NULL,
	@accessToken nvarchar(1000) = NULL,
	@publicKennelId uniqueidentifier = NULL,
	@songId uniqueidentifier = NULL,
	@isInKennel smallint = NULL,  -- 1 = add to kennel, 0 = remove from kennel

	-- optional parameters
	@hcVersion nvarchar(100) = NULL,
	@hcBuild nvarchar(100) = NULL,
	@ipAddress nvarchar(100) = NULL,
	@ipGeoDetails nvarchar(2000) = NULL

AS
BEGIN
	SET NOCOUNT ON

	DECLARE @now datetime2 = GETDATE()
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

	-- Validation: publicKennelId
	IF ((@publicKennelId IS NULL) OR (datalength(@publicKennelId) != 16)) AND (@isError = 0)
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'Null or invalid publicKennelId'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) 
		VALUES (@errorId, '<unknown>', 'Null or empty publicKennelId',
			'Null or empty publicKennelId was passed to ' + OBJECT_NAME(@@PROCID),
			OBJECT_NAME(@@PROCID), @publicHasherId)
		
		SELECT 
			@errorId as errorId,
			cast(2 as int) as errorType,
			@errorTitle as errorTitle,
			'Null or empty value was passed as the publicKennelId to ' + OBJECT_NAME(@@PROCID) as errorUserMessage,
			'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage,
			OBJECT_NAME(@@PROCID) as errorProc
	END

	-- Validation: songId
	IF ((@songId IS NULL) OR (datalength(@songId) != 16)) AND (@isError = 0)
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'Null or invalid songId'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) 
		VALUES (@errorId, '<unknown>', 'Null or empty songId',
			'Null or empty songId was passed to ' + OBJECT_NAME(@@PROCID),
			OBJECT_NAME(@@PROCID), @publicHasherId)
		
		SELECT 
			@errorId as errorId,
			cast(2 as int) as errorType,
			@errorTitle as errorTitle,
			'Null or empty value was passed as the songId to ' + OBJECT_NAME(@@PROCID) as errorUserMessage,
			'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage,
			OBJECT_NAME(@@PROCID) as errorProc
	END

	-- Validation: isInKennel
	IF (@isInKennel IS NULL OR @isInKennel NOT IN (0, 1)) AND (@isError = 0)
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'Null or invalid isInKennel value'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) 
		VALUES (@errorId, '<unknown>', 'Null or invalid isInKennel',
			'Null or invalid isInKennel was passed to ' + OBJECT_NAME(@@PROCID),
			OBJECT_NAME(@@PROCID), @publicHasherId)
		
		SELECT 
			@errorId as errorId,
			cast(2 as int) as errorType,
			@errorTitle as errorTitle,
			'isInKennel must be 0 or 1' as errorUserMessage,
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
		([LogSource]
		,[Message]
		,[Data]
		,[Timestamp])
	VALUES
		(
		'Admin Portal: hcportal_toggleKennelSong',
		CASE WHEN @isError = 1 THEN @errorTitle + ' ' ELSE '' END + COALESCE(@ipAddress, '<no IP address>'),
		COALESCE(@ipGeoDetails, '{ "ip": "<no IP address>" }'),
		@now
	)

	IF (@isError = 1)
	BEGIN
		RETURN
	END

	-- =============================================
	-- Add or remove song from kennel
	-- =============================================

	IF @isInKennel = 1
	BEGIN
		-- Adding song to kennel: check if a row already exists
		IF EXISTS (SELECT 1 FROM HC.KennelSongMap WHERE SongId = @songId AND KennelId = @publicKennelId)
		BEGIN
			-- Row exists — un-remove it
			UPDATE HC.KennelSongMap
			SET Removed = 0, ModifiedAt = @now
			WHERE SongId = @songId AND KennelId = @publicKennelId
		END
		ELSE
		BEGIN
			-- No row — insert a new mapping
			INSERT INTO HC.KennelSongMap (id, SongId, KennelId, Removed, CreatedAt)
			VALUES (NEWID(), @songId, @publicKennelId, 0, @now)
		END
	END
	ELSE
	BEGIN
		-- Removing song from kennel: soft-delete by setting Removed = 1
		UPDATE HC.KennelSongMap
		SET Removed = 1, ModifiedAt = @now
		WHERE SongId = @songId AND KennelId = @publicKennelId AND Removed = 0
	END

	-- Return success
	SELECT 
		cast(1 as int) as resultCode,
		'Success' as result

END
GO
