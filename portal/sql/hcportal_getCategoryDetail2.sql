SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [HC5].[hcportal_getCategoryDetail2]
	
	-- required parameters (we accept nulls so we can trap errors in SQL instead of having the SP fail to execute)
	@publicHasherId uniqueidentifier = NULL,
	@accessToken nvarchar(1000) = NULL,
	@categoryId smallint = NULL,
	@days smallint = 7,

	-- optional parameters
	@hcVersion nvarchar(100) = NULL,
	@hcBuild nvarchar(100) = NULL,
	@ipAddress nvarchar(100) = NULL,
	@ipGeoDetails nvarchar(2000) = NULL

AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- Allow dirty reads for reporting queries

	-- Performance optimization: Calculate datetime values once
	DECLARE @now datetime2 = GETDATE()
	DECLARE @minutes int = 60
	IF (@days != 0) SET @minutes = (@days * 24 * 60)
	DECLARE @cutoffDate datetime2 = DATEADD(minute, -@minutes, @now)

	DECLARE @errorId uniqueidentifier
	DECLARE @isError int = 0
	DECLARE @errorTitle nvarchar(500) = ''

	-- Validation: publicHasherId
	IF (@publicHasherId IS NULL) OR (datalength(@publicHasherId) != 16)
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'Null or invalid publicHasherId'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) 
		VALUES (@errorId,'<unknown>','Null or empty publicHasherId','Null or empty publicHasherId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@publicHasherId)
		
		SELECT 
			@errorId as errorId,
			cast (2 as int) as errorType 
			,@errorTitle as errorTitle
			,'Null or empty value was passed as the publicHasherId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
			,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
	END

	-- Validation: categoryId
	IF (@categoryId IS NULL)
	BEGIN
		SET @errorId = newid()
		SET @isError = 1
		SET @errorTitle = 'Null categoryId'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) 
		VALUES (@errorId,'<unknown>','Null or empty categoryId','Null or empty categoryId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@publicHasherId)
		
		SELECT 
			@errorId as errorId,
			cast (2 as int) as errorType 
			,@errorTitle as errorTitle
			,'Null value was passed as the categoryId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
			,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
	END

	-- Validation: Access token
	IF (HC.CHECK_PORTAL_ACCESS_TOKEN(@publicHasherId,OBJECT_NAME(@@PROCID),@accessToken,NULL) = 0) AND (@isError = 0) 
	BEGIN
		SET @errorId = newid()
		SET @errorTitle = 'Invalid access token'

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) 
		VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@publicHasherId,@accessToken)

		SELECT 
			@errorId as errorId,
			cast (3 as int) as errorType 
			,@errorTitle as errorTitle
			,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
			,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
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
		'Admin Portal: hcportal_getCategoryDetail'
        ,CASE WHEN @isError = 1 THEN @errorTitle + ' ' ELSE '' END + COALESCE(@ipAddress,'<no IP address>')
		,COALESCE(@ipGeoDetails,'{   "ip": "<no IP address>",   "hostname": "<none>",   "city": "<none>",   "region": "<none>",   "country": "??",   "loc": 0,0",   "org": "<none>",   "postal": "<none>",   "timezone": "<none>" }')
        ,@now
	)

	IF (@isError = 1)
	BEGIN
		RETURN
	END

	-- =============================================
	-- Helper: reusable timeAgo expression is inlined per-category
	-- since SQL doesn't support inline functions cleanly.
	-- Pattern:  < 60 min → "(Xm ago)"
	--           < 24 hrs → "(Xh Ym ago)"
	--           else     → "(Xd ago)"
	-- =============================================

	-- =============================================
	-- CATEGORY 0: New Hashers
	-- Headers: Time | Name | Location
	-- =============================================
	IF (@categoryId = 0)
	BEGIN
		-- Metadata row: column headers
		SELECT 
			'Time' AS col1,
			'Name' AS col2,
			'Location' AS col3,
			'' AS col4,
			'' AS col5,
			'' AS col6

		-- Data rows
		;WITH cte AS (
			SELECT 
				h.id AS hasherId,
				h.createdAt,
				h.displayName,
				h.HomeKennelId,
				c.CityFullName
			FROM HC.Hasher h WITH (NOLOCK)
			OUTER APPLY (
				SELECT TOP 1 c.CityFullName
				FROM HC.City c WITH (NOLOCK)
				WHERE h.HomeLatitude != 51.503300000
				ORDER BY h.HomeGeolocation.STDistance(c.CityGeolocation) ASC
			) c
			WHERE h.createdAt > @cutoffDate
		)
		SELECT 
			CASE 
				WHEN DATEDIFF(minute, cte.createdAt, @now) < 60 
					THEN CAST(DATEDIFF(minute, cte.createdAt, @now) AS nvarchar(10)) + 'm ago'
				WHEN DATEDIFF(minute, cte.createdAt, @now) / 60 < 24 
					THEN CAST(DATEDIFF(minute, cte.createdAt, @now) / 60 AS nvarchar(10)) + 'h ' 
						+ RIGHT('00' + CAST(DATEDIFF(minute, cte.createdAt, @now) % 60 AS nvarchar(10)), 2) + 'm ago'
				ELSE CAST(DATEDIFF(day, cte.createdAt, @now) AS nvarchar(10)) + 'd ago'
			END AS col1,
			cte.displayName AS col2,
			COALESCE(cte.CityFullName, '') AS col3,
			'' AS col4,
			'' AS col5,
			'' AS col6
		FROM cte
		WHERE cte.HomeKennelId IS NULL

		UNION ALL

		SELECT 
			CASE 
				WHEN DATEDIFF(minute, cte.createdAt, @now) < 60 
					THEN CAST(DATEDIFF(minute, cte.createdAt, @now) AS nvarchar(10)) + 'm ago'
				WHEN DATEDIFF(minute, cte.createdAt, @now) / 60 < 24 
					THEN CAST(DATEDIFF(minute, cte.createdAt, @now) / 60 AS nvarchar(10)) + 'h ' 
						+ RIGHT('00' + CAST(DATEDIFF(minute, cte.createdAt, @now) % 60 AS nvarchar(10)), 2) + 'm ago'
				ELSE CAST(DATEDIFF(day, cte.createdAt, @now) AS nvarchar(10)) + 'd ago'
			END AS col1,
			cte.displayName AS col2,
			k.KennelName AS col3,
			'' AS col4,
			'' AS col5,
			'' AS col6
		FROM cte
		INNER JOIN HC.Kennel k WITH (NOLOCK) ON cte.HomeKennelId = k.id

		ORDER BY col1
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 1: Event RSVPs
	-- Headers: Time | Kennel | Run# | Hasher | Status | Stats
	-- =============================================
	IF (@categoryId = 1)
	BEGIN
		-- Metadata row
		SELECT 
			'Time' AS col1,
			'Kennel' AS col2,
			'Run #' AS col3,
			'Hasher' AS col4,
			'Status' AS col5,
			'Runs / Hares' AS col6

		-- Data rows
		SELECT 
			CASE 
				WHEN DATEDIFF(minute, hem.updatedAt, @now) < 60 
					THEN CAST(DATEDIFF(minute, hem.updatedAt, @now) AS nvarchar(10)) + 'm ago'
				WHEN DATEDIFF(minute, hem.updatedAt, @now) / 60 < 24 
					THEN CAST(DATEDIFF(minute, hem.updatedAt, @now) / 60 AS nvarchar(10)) + 'h ' 
						+ RIGHT('00' + CAST(DATEDIFF(minute, hem.updatedAt, @now) % 60 AS nvarchar(10)), 2) + 'm ago'
				ELSE CAST(DATEDIFF(day, hem.updatedAt, @now) AS nvarchar(10)) + 'd ago'
			END AS col1,
			ken.KennelName AS col2,
			CAST(evt.EventNumber AS nvarchar(20)) AS col3,
			CASE 
				WHEN hem.VirginVisitorType = 0 THEN h.DisplayName 
				ELSE hem.DisplayName + ' (v/v)' 
			END AS col4,
			CASE 
				WHEN RsvpState = 0 THEN ''
				WHEN RsvpState = 1 THEN 'Not coming'
				WHEN RsvpState = 2 THEN 'Might come'
				WHEN RsvpState = 3 THEN 'Coming'
				ELSE '??'
			END
			+ CASE 
				WHEN AttendenceState = 0 THEN ''
				WHEN AttendenceState = 10 THEN ' / Not at hash'
				WHEN AttendenceState = 20 THEN ' / At hash'
				WHEN AttendenceState = 30 THEN ' / On inn'
				ELSE ' / ??'
			END AS col5,
			CAST(COALESCE(hem.TotalRunsThisKennel, 0) AS nvarchar(20)) + ' / '
				+ CAST(COALESCE(hem.TotalHaringThisKennel, 0) AS nvarchar(20)) AS col6
		FROM HC.HasherEventMap hem WITH (NOLOCK)
		INNER JOIN HC.Event evt WITH (NOLOCK) ON hem.EventId = evt.id
		INNER JOIN HC.Kennel ken WITH (NOLOCK) ON ken.id = hem.KennelId
		INNER JOIN HC.Hasher h WITH (NOLOCK) ON h.id = hem.UserId
		WHERE hem.updatedAt > @cutoffDate
		ORDER BY hem.updatedAt DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 2: New Events
	-- Headers: Time | Source | Kennel | Run # | Date | Event Name
	-- =============================================
	IF (@categoryId = 2)
	BEGIN
		-- Metadata row
		SELECT 
			'Time' AS col1,
			'Source' AS col2,
			'Kennel' AS col3,
			'Run #' AS col4,
			'Event Date' AS col5,
			'Event Name' AS col6

		-- Data rows
		SELECT 
			CASE 
				WHEN DATEDIFF(minute, evt.createdAt, @now) < 60 
					THEN CAST(DATEDIFF(minute, evt.createdAt, @now) AS nvarchar(10)) + 'm ago'
				WHEN DATEDIFF(minute, evt.createdAt, @now) / 60 < 24 
					THEN CAST(DATEDIFF(minute, evt.createdAt, @now) / 60 AS nvarchar(10)) + 'h ' 
						+ RIGHT('00' + CAST(DATEDIFF(minute, evt.createdAt, @now) % 60 AS nvarchar(10)), 2) + 'm ago'
				ELSE CAST(DATEDIFF(day, evt.createdAt, @now) AS nvarchar(10)) + 'd ago'
			END AS col1,
			CASE 
				WHEN evt.InboundIntegrationId = 0 THEN 'HC'
				WHEN evt.InboundIntegrationId = 1 THEN 'FB'
				WHEN evt.InboundIntegrationId = 3 THEN 'SD'
				WHEN evt.InboundIntegrationId = 5 THEN 'BE'
				ELSE '??'
			END AS col2,
			ken.KennelName AS col3,
			CAST(evt.EventNumber AS nvarchar(10)) AS col4,
			CONVERT(nvarchar(50), CAST(evt.EventStartDatetimeIndexed AS datetime2), 100) AS col5,
			evt.EventName AS col6
		FROM HC.Event evt WITH (NOLOCK)
		INNER JOIN HC.Kennel ken WITH (NOLOCK) ON evt.KennelId = ken.id
		WHERE evt.createdAt > @cutoffDate
		ORDER BY evt.createdAt DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 3: New Kennels
	-- Headers: Time | Kennel | Location
	-- =============================================
	IF (@categoryId = 3)
	BEGIN
		-- Metadata row
		SELECT 
			'Time' AS col1,
			'Kennel' AS col2,
			'Location' AS col3,
			'' AS col4,
			'' AS col5,
			'' AS col6

		-- Data rows
		SELECT
			CASE 
				WHEN DATEDIFF(minute, ken.createdAt, @now) < 60 
					THEN CAST(DATEDIFF(minute, ken.createdAt, @now) AS nvarchar(10)) + 'm ago'
				WHEN DATEDIFF(minute, ken.createdAt, @now) / 60 < 24 
					THEN CAST(DATEDIFF(minute, ken.createdAt, @now) / 60 AS nvarchar(10)) + 'h ' 
						+ RIGHT('00' + CAST(DATEDIFF(minute, ken.createdAt, @now) % 60 AS nvarchar(10)), 2) + 'm ago'
				ELSE CAST(DATEDIFF(day, ken.createdAt, @now) AS nvarchar(10)) + 'd ago'
			END AS col1,
			ken.KennelName AS col2,
			COALESCE(c.CityFullName, c.cityCountryName, c.cityName) AS col3,
			'' AS col4,
			'' AS col5,
			'' AS col6
		FROM HC.Kennel ken WITH (NOLOCK)
		INNER JOIN HC.City c WITH (NOLOCK) ON ken.CityId = c.id
		WHERE ken.createdAt > @cutoffDate
		ORDER BY ken.createdAt DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 4: App Logins
	-- Headers: Time | Name | Device | OS | Location
	-- =============================================
	IF (@categoryId = 4)
	BEGIN
		-- Metadata row
		SELECT 
			'Time' AS col1,
			'Name' AS col2,
			'Device' AS col3,
			'OS' AS col4,
			'Location' AS col5,
			'' AS col6

		-- Data rows
		SELECT 
			CASE 
				WHEN DATEDIFF(minute, ll.LoginDate, @now) < 60 
					THEN CAST(DATEDIFF(minute, ll.LoginDate, @now) AS nvarchar(10)) + 'm ago'
				WHEN DATEDIFF(minute, ll.LoginDate, @now) / 60 < 24 
					THEN CAST(DATEDIFF(minute, ll.LoginDate, @now) / 60 AS nvarchar(10)) + 'h ' 
						+ RIGHT('00' + CAST(DATEDIFF(minute, ll.LoginDate, @now) % 60 AS nvarchar(10)), 2) + 'm ago'
				ELSE CAST(DATEDIFF(day, ll.LoginDate, @now) AS nvarchar(10)) + 'd ago'
			END AS col1,
			COALESCE(h.displayName, '<no name>') AS col2,
			COALESCE(
				CASE WHEN DeviceName = '<unknown>' THEN NULL ELSE DeviceName END,
				COALESCE(Manufacturer, '')
			)
			+ COALESCE(', ' + DeviceType, '') AS col3,
			COALESCE(SystemName, '') + ' ' + COALESCE(SystemVersion, '') AS col4,
			COALESCE(c.CityFullName, '') AS col5,
			'' AS col6
		FROM HC.LaunchAndLogin ll WITH (NOLOCK)
		LEFT OUTER JOIN HC.Hasher h WITH (NOLOCK) ON ll.UserId = h.id
		LEFT OUTER JOIN HC.City c WITH (NOLOCK) ON c.id = ll.CityId
		WHERE ll.LoginDate > @cutoffDate
			AND ll.UserId <> '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC' 
			AND ll.UserId <> 'D0B7EF01-C6E3-4723-9D2F-2AE864A59F1A'
		ORDER BY ll.LoginDate DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 5: Payments
	-- Headers: Time | Event | Hasher | Processed By | Amount | Type
	-- =============================================
	IF (@categoryId = 5)
	BEGIN
		-- Metadata row
		SELECT 
			'Time' AS col1,
			'Event' AS col2,
			'Hasher' AS col3,
			'Processed By' AS col4,
			'Amount' AS col5,
			'Type' AS col6

		-- Data rows
		SELECT 
			CASE 
				WHEN DATEDIFF(minute, p.createdAt, @now) < 60 
					THEN CAST(DATEDIFF(minute, p.createdAt, @now) AS nvarchar(10)) + 'm ago'
				WHEN DATEDIFF(minute, p.createdAt, @now) / 60 < 24 
					THEN CAST(DATEDIFF(minute, p.createdAt, @now) / 60 AS nvarchar(10)) + 'h ' 
						+ RIGHT('00' + CAST(DATEDIFF(minute, p.createdAt, @now) % 60 AS nvarchar(10)), 2) + 'm ago'
				ELSE CAST(DATEDIFF(day, p.createdAt, @now) AS nvarchar(10)) + 'd ago'
			END AS col1,
			k.KennelName + ' #' + CAST(evt.EventNumber AS nvarchar(20)) AS col2,
			CASE 
				WHEN hem.VirginVisitorType = 0 THEN h1.DisplayName 
				ELSE hem.DisplayName + ' (v/v)' 
			END AS col3,
			COALESCE(
				'Cancelled: ' + h3.DisplayName,
				h2.DisplayName
			) AS col4,
			REPLACE(COALESCE(k.CurrencySymbol, c.CurrencySymbol), '^', CAST(p.CreditAmount AS nvarchar(10)))
				+ ' / '
				+ REPLACE(COALESCE(k.CurrencySymbol, c.CurrencySymbol), '^', CAST(p.DebitAmount AS nvarchar(10)))
				+ CASE WHEN p.CreditAvailable > 0 
					THEN ' (cr: ' + REPLACE(COALESCE(k.CurrencySymbol, c.CurrencySymbol), '^', CAST(p.CreditAvailable AS nvarchar(10))) + ')' 
					ELSE '' 
				END AS col5,
			CASE 
				WHEN p.PaymentType = 0 THEN 'Unknown'
				WHEN p.PaymentType = 1 THEN 'Not paid'
				WHEN p.PaymentType = 2 THEN 'Free'
				WHEN p.PaymentType = 3 THEN 'Cash'
				WHEN p.PaymentType = 4 THEN 'Bank transfer'
				WHEN p.PaymentType = 5 THEN 'Cash (other)'
				WHEN p.PaymentType = 6 THEN 'Hash credit'
				WHEN p.PaymentType = 7 THEN 'Bank (other)'
				ELSE 'Error'
			END
			+ CASE WHEN DATALENGTH(p.PaymentProvider) > 2 THEN ' [' + p.PaymentProvider + ']' ELSE '' END
			+ CASE WHEN p.DoPayForExtras > 0 
				THEN ' + ' + COALESCE(evt.ExtrasDescription, 'Extras') 
				ELSE '' 
			END AS col6
		FROM HC.Payment p WITH (NOLOCK)
		INNER JOIN HC.HasherEventMap hem WITH (NOLOCK) ON p.HasherEventMapId = hem.id
		INNER JOIN HC.Hasher h1 WITH (NOLOCK) ON p.UserId = h1.id
		INNER JOIN HC.Hasher h2 WITH (NOLOCK) ON p.PaymentProcessedBy_userId = h2.id
		LEFT OUTER JOIN HC.Hasher h3 WITH (NOLOCK) ON p.CancelledBy_UserId = h3.id
		INNER JOIN HC.Event evt WITH (NOLOCK) ON evt.id = p.EventId
		INNER JOIN HC.Kennel k WITH (NOLOCK) ON evt.KennelId = k.id
		INNER JOIN HC.Country c WITH (NOLOCK) ON k.CountryId = c.id
		WHERE p.createdAt > @cutoffDate
		ORDER BY p.createdAt DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 6: Portal Access
	-- Headers: Time | Name | Kennel
	-- =============================================
	IF (@categoryId = 6)
	BEGIN
		-- Metadata row
		SELECT 
			'Time' AS col1,
			'Name' AS col2,
			'Kennel' AS col3,
			'' AS col4,
			'' AS col5,
			'' AS col6

		-- Data rows
		SELECT 
			CASE 
				WHEN DATEDIFF(minute, pa.accessDate, @now) < 60 
					THEN CAST(DATEDIFF(minute, pa.accessDate, @now) AS nvarchar(10)) + 'm ago'
				WHEN DATEDIFF(minute, pa.accessDate, @now) / 60 < 24 
					THEN CAST(DATEDIFF(minute, pa.accessDate, @now) / 60 AS nvarchar(10)) + 'h ' 
						+ RIGHT('00' + CAST(DATEDIFF(minute, pa.accessDate, @now) % 60 AS nvarchar(10)), 2) + 'm ago'
				ELSE CAST(DATEDIFF(day, pa.accessDate, @now) AS nvarchar(10)) + 'd ago'
			END AS col1,
			h.DisplayName AS col2,
			COALESCE(k.KennelName, '') AS col3,
			'' AS col4,
			'' AS col5,
			'' AS col6
		FROM HC.PortalAccess pa WITH (NOLOCK)
		INNER JOIN HC.Hasher h WITH (NOLOCK) ON pa.hasherId = h.id
		LEFT OUTER JOIN HC.Kennel k WITH (NOLOCK) ON h.HomeKennelId = k.id
		WHERE pa.accessDate > @cutoffDate
			AND pa.hasherId <> '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC' 
			AND pa.hasherId <> 'D0B7EF01-C6E3-4723-9D2F-2AE864A59F1A'
		ORDER BY pa.accessDate DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 7: Errors
	-- Headers: Time | Error | User | Stored Proc
	-- =============================================
	IF (@categoryId = 7)
	BEGIN
		-- Metadata row
		SELECT 
			'Time' AS col1,
			'Error' AS col2,
			'User' AS col3,
			'Stored Proc' AS col4,
			'' AS col5,
			'' AS col6

		-- Data rows
		SELECT 
			CASE 
				WHEN DATEDIFF(minute, er.updatedAt, @now) < 60 
					THEN CAST(DATEDIFF(minute, er.updatedAt, @now) AS nvarchar(10)) + 'm ago'
				WHEN DATEDIFF(minute, er.updatedAt, @now) / 60 < 24 
					THEN CAST(DATEDIFF(minute, er.updatedAt, @now) / 60 AS nvarchar(10)) + 'h ' 
						+ RIGHT('00' + CAST(DATEDIFF(minute, er.updatedAt, @now) % 60 AS nvarchar(10)), 2) + 'm ago'
				ELSE CAST(DATEDIFF(day, er.updatedAt, @now) AS nvarchar(10)) + 'd ago'
			END AS col1,
			er.ErrorDescription AS col2,
			COALESCE(h.displayName, CAST(er.userId AS nvarchar(100)), '<no user>') AS col3,
			er.ProcName AS col4,
			'' AS col5,
			'' AS col6
		FROM HC.ErrorLog er WITH (NOLOCK)
		LEFT OUTER JOIN HC.Hasher h WITH (NOLOCK) ON er.userId = h.id
		WHERE er.updatedAt > @cutoffDate
		ORDER BY er.updatedAt DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 8: HashRuns.Org Traffic
	-- Headers: Time | Location | Page | Kennel | Event
	-- =============================================
	IF (@categoryId = 8)
	BEGIN
		-- Metadata row
		SELECT 
			'Time' AS col1,
			'Location' AS col2,
			'Page' AS col3,
			'Kennel' AS col4,
			'Event' AS col5,
			'' AS col6

		-- Data rows
		SELECT 
			CASE 
				WHEN DATEDIFF(minute, gl.Timestamp, @now) < 60 
					THEN CAST(DATEDIFF(minute, gl.Timestamp, @now) AS nvarchar(10)) + 'm ago'
				WHEN DATEDIFF(minute, gl.Timestamp, @now) / 60 < 24 
					THEN CAST(DATEDIFF(minute, gl.Timestamp, @now) / 60 AS nvarchar(10)) + 'h ' 
						+ RIGHT('00' + CAST(DATEDIFF(minute, gl.Timestamp, @now) % 60 AS nvarchar(10)), 2) + 'm ago'
				ELSE CAST(DATEDIFF(day, gl.Timestamp, @now) AS nvarchar(10)) + 'd ago'
			END AS col1,
			j.city + ', ' + j.region + ', ' + j.country AS col2,
			gl.message AS col3,
			COALESCE(ken.KennelName, '') AS col4,
			COALESCE(evt.EventName, '') AS col5,
			'' AS col6
		FROM LOG.GeneralLog gl WITH (NOLOCK)
		CROSS APPLY (
			SELECT 
				JSON_VALUE(gl.data, '$.city') AS city,
				JSON_VALUE(gl.data, '$.region') AS region,
				JSON_VALUE(gl.data, '$.country') AS country
		) j
		LEFT OUTER JOIN HC.Event evt WITH (NOLOCK) ON evt.PublicEventId = gl.StrParam1 
		LEFT OUTER JOIN HC.Kennel ken WITH (NOLOCK) ON ken.id = evt.KennelId
		WHERE (gl.LogSource = 'HashRuns.Org Event List' OR gl.LogSource = 'HashRuns.Org Single Event')
			AND gl.Timestamp > @cutoffDate
		ORDER BY gl.Timestamp DESC
		OPTION (RECOMPILE)
	END

	-- =============================================
	-- CATEGORY 100: Version Adoption
	-- Headers: Time | Logins | This Ver | Name | Version | Platform
	-- =============================================
	IF (@categoryId = 100)
	BEGIN
		-- Metadata row
		SELECT 
			'Time' AS col1,
			'Logins' AS col2,
			'This Ver' AS col3,
			'Name' AS col4,
			'Version' AS col5,
			'Platform' AS col6

		-- Data rows
		;WITH cte AS (
			SELECT 
				MAX(ll.LoginDate) AS updatedAt,
				ll.UserId,
				MAX(ll.idx) AS idx,
				COUNT(CASE WHEN ll.HcVersion LIKE '%' + @hcVersion + '%' AND ll.HcVersion LIKE '%' + @hcBuild + '%' THEN 1 ELSE NULL END) AS thisVersionCnt,
				COUNT(*) AS twoWeekCnt
			FROM HC.LaunchAndLogin ll WITH (NOLOCK)
			WHERE ll.LoginDate > @cutoffDate
			GROUP BY ll.UserId
		)
		SELECT 
			CASE 
				WHEN DATEDIFF(minute, MAX(cte.updatedAt), @now) < 60 
					THEN CAST(DATEDIFF(minute, MAX(cte.updatedAt), @now) AS nvarchar(10)) + 'm ago'
				WHEN DATEDIFF(minute, MAX(cte.updatedAt), @now) / 60 < 24 
					THEN CAST(DATEDIFF(minute, MAX(cte.updatedAt), @now) / 60 AS nvarchar(10)) + 'h ' 
						+ RIGHT('00' + CAST(DATEDIFF(minute, MAX(cte.updatedAt), @now) % 60 AS nvarchar(10)), 2) + 'm ago'
				ELSE CAST(DATEDIFF(day, MAX(cte.updatedAt), @now) AS nvarchar(10)) + 'd ago'
			END AS col1,
			CAST(cte.twoWeekCnt AS nvarchar(20)) AS col2,
			CAST(cte.thisVersionCnt AS nvarchar(20)) AS col3,
			h.DisplayName AS col4,
			ll.HcVersion AS col5,
			CASE 
				WHEN ll.SystemName LIKE '%ios%' THEN 'iOS' 
				WHEN ll.SystemName IS NULL THEN '??'
				ELSE 'Android' 
			END AS col6
		FROM cte
		INNER JOIN HC.Hasher h WITH (NOLOCK) ON cte.UserId = h.id
		INNER JOIN HC.LaunchAndLogin ll WITH (NOLOCK) ON ll.idx = cte.idx
		WHERE ll.HcVersion LIKE '%' + @hcVersion + '%' 
			AND ll.HcVersion LIKE '%' + @hcBuild + '%'	  
		GROUP BY h.DisplayName, ll.HcVersion, cte.updatedAt, cte.thisVersionCnt, cte.twoWeekCnt, ll.SystemName
		ORDER BY cte.twoWeekCnt DESC
		OPTION (RECOMPILE)
	END
END
