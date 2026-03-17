SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [HC5].[hcportal_getSongs]
	
	-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
	@publicHasherId uniqueidentifier = NULL,
	@accessToken nvarchar(1000) = NULL,
	@publicKennelId uniqueidentifier = NULL,

	-- optional parameters
	@hcVersion nvarchar(100) = NULL,
	@hcBuild nvarchar(100) = NULL,
	@ipAddress nvarchar(100) = NULL,
	@ipGeoDetails nvarchar(2000) = NULL

AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- Allow dirty reads for reporting queries

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
		'Admin Portal: hcportal_getSongs',
		CASE WHEN @isError = 1 THEN @errorTitle + ' ' ELSE '' END + COALESCE(@ipAddress, '<no IP address>'),
		COALESCE(@ipGeoDetails, '{ "ip": "<no IP address>" }'),
		@now
	)

	IF (@isError = 1)
	BEGIN
		RETURN
	END

	-- =============================================
	-- Return all non-removed songs with kennel membership flag
	-- isInKennel = 1 if the song exists in KennelSongMap for this kennel (and not removed), 0 otherwise
	-- =============================================
	SELECT 
		s.id,
		s.SongName,
		s.TuneOf,
		s.BawdyRating,
		s.Notes,
		s.Actions,
		s.Variants,
		s.ImageUrl,
		s.AudioUrl,
		s.AutoAddToKennel,
		s.Rank,
		s.AddedBy_KennelId,
		s.AddedBy_UserId,
		s.Lyrics,
		s.Tags,
		s.createdAt,
		cast(CASE WHEN ksm.id IS NOT NULL THEN 1 ELSE 0 END as smallint) as isInKennel
	FROM HC.Song s WITH (NOLOCK)
	LEFT JOIN HC.KennelSongMap ksm WITH (NOLOCK)
		ON ksm.SongId = s.id
		AND ksm.KennelId = @publicKennelId
		AND ksm.Removed = 0
	WHERE s.Removed = 0
	ORDER BY s.SongName ASC

END
GO
