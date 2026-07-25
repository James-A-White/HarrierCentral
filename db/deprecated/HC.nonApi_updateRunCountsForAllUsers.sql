CREATE OR ALTER PROCEDURE [HC].[nonApi_updateRunCountsForAllUsers]

	@updatedSince datetime = NULL

AS

-- =====================================================================
-- OBSOLETE (guarded 2026-07-25): run-count maintenance is now owned by the
-- HC6 run-count SPs. This legacy HC5 updater used the EventStartDatetime
-- columns and fought the HC6 version, churning ~100k HasherEventMap rows.
-- It now DELEGATES to the HC6 equivalent (so any live caller still gets the
-- correct HC6-computed counts) and logs the call so the remaining legacy
-- callers can be found and retired. Original body preserved below (unreachable).
-- =====================================================================
    SET NOCOUNT ON;
    INSERT INTO LOG.GeneralLog (LogSource, Message)
    VALUES ('OBSOLETE SP', 'Obsolete SP called (delegated to HC6): HC.nonApi_updateRunCountsForAllUsers');
    EXEC HC6.nonApi_updateRunCountsForAllUsers @updatedSince = @updatedSince;
    RETURN;

BEGIN

	--declare @userId uniqueidentifier = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC'
	--declare @userId uniqueidentifier = '4A504F81-8A89-406E-BD7D-B5FEA05A03A2'

	-- EXEC HC.nonApi_updateRunCountsForAllUsers
	-- SELECT * FROM HC.HasherEventMap hem where hem.id = 'C7B79FB7-9053-4912-92DA-1114A7AB4A13'

	SELECT @updatedSince = dateadd(minute,-1,coalesce(@updatedSince,'1/1/2000'))

	--SELECT hem.UserId into #tempHashersToUpdate FROM HC.HasherEventMap hem where updatedAt > dateadd(second,-1,@updatedSince)

	-- for some reason using the CTE is faster than a regular join
	;with cte as (select distinct
		hem.UserId,
		evt.kennelId
	from HC.HasherEventMap hem 
	inner join HC.Event evt on hem.EventId = evt.id
	where 
			hem.AttendenceState >= 20
		AND evt.IsCountedRun = 1 
		AND evt.removed = 0 
		AND evt.IsVisible = 1
		AND hem.VirginVisitorType = 0
		AND hem.updatedAt > @updatedSince
	)

	INSERT INTO [HC].[HasherKennelMap]
			   ([id]
			   ,[UserId]
			   ,[KennelId]
			   ,[Following]
			   ,[IsMember]
			   ,[IsKennelFollowing]
			   ,[IsHomeKennel]
			   ,[KennelNotificationPreference]
			   ,[KennelEmailAlertPreference]
			   ,[MismanagementRoles]
			   ,[MismanagementRoleFlags]
			   ,[HcWebPermissionFlags]
			   ,[UserRoleFlags]
			   ,[AppAccessFlags]
			   ,[HistoricalTotalRunCount]
			   ,[HistoricalPackRunCount]
			   ,[HistoricalHaringCount]
			   ,[HistoricalCountIsEstimate]
			   ,[HcTotalRunCount]
			   ,[HcHaringCount]
			   ,[YtdTotalRunCount]
			   ,[YtdHaringCount]
			   ,[CurrentPackRunCount]
			   ,[CurrentHaringCount]
			   ,[KennelCredit]
			   ,[DiscountAmount]
			   ,[DiscountPercent]
			   ,[DiscountDescription]
			   --,[DateOfLastRun]
			   --,[MembershipExpirationDate]
			   --,[MemberSince]
			   ,[CanEditRunAttendence]
			   ,[removed]
			   ,[updatedAt])

	select 
		 
				newid()
			   ,cte.UserId
			   ,cte.KennelId
			   ,0 --[Following]
			   ,0 --[IsMember]
			   ,0 --[IsKennelFollowing]
			   ,0 --[IsHomeKennel]
			   ,0 --[KennelNotificationPreference]
			   ,0 --[KennelEmailAlertPreference]
			   ,0 --[MismanagementRoles]
			   ,0 --[MismanagementRoleFlags]
			   ,0 --[HcWebPermissionFlags]
			   ,0 --[UserRoleFlags]
			   ,0 --[AppAccessFlags]
			   ,0 --[HistoricalTotalRunCount]
			   ,0 --[HistoricalPackRunCount]
			   ,0 --[HistoricalHaringCount]
			   ,0 --[HistoricalCountIsEstimate]
			   ,0 --[HcTotalRunCount]
			   ,0 --[HcHaringCount]
			   ,0 --[YtdTotalRunCount]
			   ,0 --[YtdHaringCount]
			   ,0 --[CurrentPackRunCount]
			   ,0 --[CurrentHaringCount]
			   ,0 --[KennelCredit]
			   ,0 --[DiscountAmount]
			   ,0 --[DiscountPercent]
			   ,'' --[DiscountDescription]
			   -- [DateOfLastRun]
			   -- [MembershipExpirationDate]
			   --,[MemberSince]
			   ,0 --,[CanEditRunAttendence]
			   ,0 -- [removed]
			   ,getdate()
	from cte 
	left outer join HC.HasherKennelMap hkm on hkm.UserId = cte.UserId and hkm.KennelId = cte.KennelId
	where hkm.id is null


	-- update run counts in HEM
	update hem 
	set 
	hem.TotalRuns = rc.totalRuns,
	hem.TotalHaring = rc.totalHaring,
	hem.TotalRunsThisKennel = rc.totalRunsThisKennel,
	hem.TotalHaringThisKennel = rc.totalHaringThisKennel,
	hem.YtdTotalRunsThisKennel = rc.ytdTotalRunsThisKennel,
	hem.YtdHaringThisKennel = rc.ytdHaringThisKennel,
	hem.updatedAt = getdate()

	--SELECT 
	--		hem.updatedAt,hem.UserId,hem.KennelId,hem.EventId,hem.id,
	--		hem.TotalRuns as hemTotalRuns,rc.totalRuns,
	--		hem.TotalHaring as hemTotalHaring,rc.totalHaring,
	--		hem.TotalRunsThisKennel as hemTotalRunsThisKennel,rc.totalRunsThisKennel,
	--		hem.TotalHaringThisKennel as hemTotalHaringThisKennel,rc.totalHaringThisKennel,
	--		hem.YtdTotalRunsThisKennel as hemYtdTotalRunsThisKennel,rc.ytdTotalRunsThisKennel,
	--		hem.YtdHaringThisKennel as hemYtdHaringThisKennel,rc.ytdHaringThisKennel
	from HC.HasherEventMap hem
	inner join HC5.fn_GetRunCounts(@updatedSince) rc  on rc.hemId = hem.id
	inner join HC.Hasher h on hem.UserId = h.id
	where 
		h.isAnonymous = 0 AND
		hem.AttendenceState >= 20 AND
		(
			coalesce(hem.TotalRuns,-999) != coalesce(rc.totalRuns,-999) or 
			coalesce(hem.TotalHaring,-999) != coalesce(rc.totalHaring,-999) or 
			coalesce(hem.TotalRunsThisKennel,-999) != coalesce(rc.totalRunsThisKennel,-999) or 
			coalesce(hem.TotalHaringThisKennel,-999) != coalesce(rc.totalHaringThisKennel,-999) or
			coalesce(hem.YtdTotalRunsThisKennel,-999) != coalesce(rc.ytdTotalRunsThisKennel,-999) or
			coalesce(hem.YtdHaringThisKennel,-999) != coalesce(rc.ytdHaringThisKennel,-999) 
		)

	UPDATE hem set 
	hem.TotalRuns = null,
	hem.TotalHaring = null,
	hem.TotalRunsThisKennel = null,
	hem.TotalHaringThisKennel = null,
	hem.YtdTotalRunsThisKennel = null,
	hem.YtdHaringThisKennel = null,
	hem.updatedAt = getdate()

	FROM HC.HasherEventMap hem
	WHERE hem.AttendenceState < 20
	AND
	(
		hem.TotalRuns IS NOT null OR
		hem.TotalHaring IS NOT null OR
		hem.TotalRunsThisKennel IS NOT null OR
		hem.TotalHaringThisKennel IS NOT null OR
		hem.YtdTotalRunsThisKennel IS NOT null OR
		hem.YtdHaringThisKennel IS NOT null 
	)

	-- update HKM records
	-- also need to make sure we update HKM records when a user has no runs with a kennel
	-- this can happen if a user is checked into a run for a kennel and then checked back out
	-- and they have no other runs with that kennel

	DECLARE @thisYear int = datepart(year,getdate())

	;with cte as 
	(select 
		coalesce(MAX(hem.totalRunsThisKennel),0) as maxTotalRunsThisKennel,
		coalesce(MAX(hem.totalHaringThisKennel),0) as maxTotalHaringThisKennel,
		coalesce(MAX(case when datepart(year,evt.EventStartDatetimeIndexed) = @thisYear then hem.YtdTotalRunsThisKennel ELSE NULL END),0) as maxYtdTotalRunsThisKennel,
		coalesce(MAX(case when datepart(year,evt.EventStartDatetimeIndexed) = @thisYear then hem.YtdHaringThisKennel ELSE NULL END),0) as maxYtdHaringThisKennel,
		MAX(evt.EventStartDatetimeIndexed) as dateOfLastRun,
		hkm.UserId,
		hkm.kennelId
	from HC.HasherKennelMap hkm 
		INNER JOIN HC.Hasher h on hkm.UserId = h.id
		INNER JOIN HC.Kennel ken on hkm.KennelId = ken.id
		INNER JOIN HC.City c on c.id = ken.CityId
		INNER JOIN DomainValues.Timezone tz on c.TimezoneId = tz.id
		LEFT OUTER JOIN HC.HasherEventMap hem on hem.KennelId = hkm.KennelId and hem.UserId = hkm.UserId and hem.AttendenceState >= 20
		INNER JOIN HC.Event evt on hem.EventId = evt.id AND (cast(evt.EventStartDatetime as datetime) AT TIME ZONE tz.Timezone) AT TIME ZONE 'UTC' < getdate()
	where h.isAnonymous = 0
	group by hkm.UserId,hkm.KennelId)


update hkm set
	hkm.CurrentHaringCount = 0,
	hkm.CurrentPackRunCount = 0,
	hkm.HistoricalPackRunCount = 0,
	hkm.HcTotalRunCount = cte.maxTotalRunsThisKennel,
	hkm.HcHaringCount = cte.maxTotalHaringThisKennel,
	hkm.YtdTotalRunCount = cte.maxYtdTotalRunsThisKennel,
	hkm.YtdHaringCount = cte.maxYtdHaringThisKennel,
	hkm.DateOfLastRun = cte.dateOfLastRun,
	hkm.updatedAt = getdate()
	--SELECT *
	FROM HC.HasherKennelMap hkm 
	INNER JOIN cte on hkm.userid = cte.UserId AND hkm.KennelId = cte.KennelId
	WHERE 
	(
		COALESCE(hkm.HcTotalRunCount,-999) != COALESCE(cte.maxTotalRunsThisKennel,999) OR
		COALESCE(hkm.HcHaringCount,-999) != COALESCE(cte.maxTotalHaringThisKennel,999) OR
		COALESCE(hkm.YtdTotalRunCount,-999) != COALESCE(cte.maxYtdTotalRunsThisKennel,999) OR
		COALESCE(hkm.YtdHaringCount,-999) != COALESCE(cte.maxYtdHaringThisKennel,999) OR
		COALESCE(hkm.DateOfLastRun, '1/1/1990') != COALESCE(cte.dateOfLastRun,'1/1/1990')
	)

	UPDATE hkm SET 
		RollingYearTotalRunCount = rc.rollingYearTotalRunsThisKennel, 
		RollingYearHaringCount = rc.rollingYearHaringThisKennel,
		updatedAt = getdate()
	FROM HC.HasherKennelMap hkm 
	INNER JOIN HC.Hasher h on hkm.UserId = h.id
	INNER JOIN HC5.fn_GetRunCountsRolling(@updatedSince) rc on hkm.UserId = rc.userId and hkm.KennelId = rc.KennelId
	WHERE 
		h.isAnonymous = 0
		AND
		(
			coalesce(RollingYearTotalRunCount,99999) != coalesce(rc.rollingYearTotalRunsThisKennel,99999) OR
			coalesce(RollingYearHaringCount,99999) != coalesce(rc.rollingYearHaringThisKennel,99999)
		)

	INSERT LOG.GeneralLog(LogSource,Message) VALUES ('RUN COUNTS','Updated all user run counts')

END
