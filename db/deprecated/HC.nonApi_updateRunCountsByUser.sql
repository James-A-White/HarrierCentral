CREATE OR ALTER PROCEDURE [HC].[nonApi_updateRunCountsByUser]

@userId uniqueidentifier,
@eventDateTime datetime = null

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
    VALUES ('OBSOLETE SP', 'Obsolete SP called (delegated to HC6): HC.nonApi_updateRunCountsByUser');
    EXEC HC6.nonApi_updateRunCountsByUser @userId = @userId;  -- HC6 dropped the unused @eventDateTime
    RETURN;

BEGIN

	-- EXEC [HC].[nonApi_updateRunCountsByUser] @userId = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC'

	--declare @userId uniqueidentifier = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC'
	--declare @userId uniqueidentifier = '4A504F81-8A89-406E-BD7D-B5FEA05A03A2'
	--declare @userId uniqueidentifier = '6F28BB4A-040D-410B-BBEA-A630DFD5AA2F'

	-- EXEC HC.nonApi_updateRunCountsByUser @userId = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC'
	-- 

	-- EXEC HC.nonApi_updateRunCountsByUser @userId = 'F5178416-A459-44DC-B926-9CA639A991E6'

	-- If the user is anonymous, don't update the run counts
	IF NOT EXISTS (SELECT * FROM HC.Hasher where id = @userid AND isAnonymous = 0) RETURN

	---- for some reason using the CTE is faster than a regular join
	--;with cte as (select 
	--	hem.UserId,
	--	evt.kennelId
	--from HC.HasherEventMap hem 
	--inner join HC.Event evt on hem.EventId = evt.id
	--where 
	--		hem.AttendenceState >= 20
	--	AND evt.IsCountedRun = 1 
	--	AND evt.removed = 0 
	--	AND evt.IsVisible = 1
	--	AND hem.VirginVisitorType = 0
	--	AND hem.userId = @userId
	--)

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
		distinct 
				newid()
			   ,@userId
			   ,KennelId
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
	from [HC5].[fn_HkmRecordsToInsert](@userId)

	;with cte as 
	(
		select 
			evt.id as evtId,
			evt.EventStartDatetimeIndexed,
			hem.isHare,
			ROW_NUMBER() OVER (partition by hem.userId order by evt.eventStartDatetimeIndexed,evt.kennelId,evt.EventNumber,evt.id) as totalRuns,
			ROW_NUMBER() OVER (partition by hem.userId, hem.isHare order by evt.eventStartDatetimeIndexed,evt.kennelId,evt.EventNumber,evt.id) as totalHaring,
			ROW_NUMBER() OVER (partition by hem.userId, hem.kennelId order by evt.eventStartDatetimeIndexed,evt.kennelId,evt.EventNumber,evt.id) as totalRunsThisKennel,
			ROW_NUMBER() OVER (partition by hem.userId, hem.kennelId, hem.isHare order by evt.eventStartDatetimeIndexed,evt.kennelId,evt.EventNumber,evt.id) as totalHaringThisKennel,
			ROW_NUMBER() OVER (partition by hem.userId, hem.kennelId, datepart(year,evt.eventStartDatetimeIndexed) order by evt.eventStartDatetimeIndexed,evt.kennelId,evt.EventNumber,evt.id) as ytdTotalRunsThisKennel,
			ROW_NUMBER() OVER (partition by hem.userId, hem.kennelId, hem.isHare, datepart(year,evt.eventStartDatetimeIndexed) order by evt.eventStartDatetimeIndexed,evt.kennelId,evt.EventNumber,evt.id) as ytdHaringThisKennel,
			hem.id, 
			hem.UserId,
			evt.kennelId
		from HC.HasherEventMap hem WITH(INDEX=IX_HemRunCount)
			inner join HC.Event evt  WITH(INDEX=IX_EvtRunCount) on hem.EventId = evt.id
		where hem.AttendenceState >= 20
			AND hem.userId = @userId
			AND hem.VirginVisitorType = 0
			AND evt.IsCountedRun = 1 
			AND evt.IsVisible = 1
			AND evt.removed = 0 
	) 
	,cte2 as 
	(
		select 
			cte.evtId,
			cte.EventStartDatetimeIndexed,
			cte.IsHare,
			cte.totalRuns,
			case when cte.IsHare = 1 then cte.totalHaring else null end as totalHaring,
			cte.totalRunsThisKennel,
			case when cte.IsHare = 1 then cte.totalHaringThisKennel else null end as totalHaringThisKennel,
			cte.ytdTotalRunsThisKennel,
			case when cte.IsHare = 1 then cte.ytdHaringThisKennel else null end as ytdHaringThisKennel,
			--case when cte.rollingYear = 0 then cte.rollingYearTotalRunsThisKennel else null end as rollingYearTotalRunsThisKennel,
			--case when cte.IsHare = 1 and cte.rollingYear = 0 then cte.rollingYearHaringThisKennel else null end as rollingYearHaringThisKennel,
			cte.id as hemId,
			cte.UserId as userId,
			cte.KennelId,
			cte.totalRunsThisKennel + hkm.HistoricalTotalRunCount as runsPlusHistoryByKennel, 
			case when cte.isHare = 1 then cte.totalHaringThisKennel + hkm.HistoricalHaringCount else null end as haringPlusHistoryByKennel
		from cte 
			left outer join HC.HasherKennelMap hkm on hkm.UserId = cte.UserId and hkm.KennelId = cte.KennelId
	)
	-- update run counts in HEM
	update hem 
	set 
	hem.TotalRuns = coalesce(rc.totalRuns,0),
	hem.TotalHaring = coalesce(rc.totalHaring,0),
	hem.TotalRunsThisKennel = coalesce(rc.totalRunsThisKennel,0),
	hem.TotalHaringThisKennel = coalesce(rc.totalHaringThisKennel,0),
	hem.YtdTotalRunsThisKennel = coalesce(rc.ytdTotalRunsThisKennel,0),
	hem.YtdHaringThisKennel = coalesce(rc.ytdHaringThisKennel,0),
	hem.updatedAt = getdate()
	--SELECT
	--	hem.id,
	--	hem.TotalRuns,rc.totalRuns,
	--	hem.TotalHaring,rc.totalHaring,
	--	hem.TotalRunsThisKennel,rc.totalRunsThisKennel,
	--	hem.TotalHaringThisKennel,rc.totalHaringThisKennel,
	--	hem.YtdTotalRunsThisKennel,rc.ytdTotalRunsThisKennel,
	--	hem.YtdHaringThisKennel,rc.ytdHaringThisKennel
	from HC.HasherEventMap hem 
	inner join cte2 rc on rc.hemId = hem.id
	where hem.userId = @userId AND
		hem.AttendenceState >= 20 
		AND
		(
			coalesce(hem.TotalRuns,-999) != coalesce(rc.totalRuns,-999) 
			OR coalesce(hem.TotalHaring,-999) != coalesce(rc.totalHaring,-999)
			OR coalesce(hem.TotalRunsThisKennel,-999) != coalesce(rc.totalRunsThisKennel,-999)
			OR coalesce(hem.TotalHaringThisKennel,-999) != coalesce(rc.totalHaringThisKennel,-999)
			OR coalesce(hem.YtdTotalRunsThisKennel,-999) != coalesce(rc.ytdTotalRunsThisKennel,-999)
			OR coalesce(hem.YtdHaringThisKennel,-999) != coalesce(rc.ytdHaringThisKennel,-999) 
		)
	

	-- if the Hasher is not attending an event, erase all of the stats
	UPDATE hem set 
	hem.TotalRuns = null,
	hem.TotalHaring = null,
	hem.TotalRunsThisKennel = null,
	hem.TotalHaringThisKennel = null,
	hem.YtdTotalRunsThisKennel = null,
	hem.YtdHaringThisKennel = null
	FROM HC.HasherEventMap hem
	WHERE hem.AttendenceState < 20
	AND hem.userId = @userId
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
	left outer join HC.HasherEventMap hem on hem.KennelId = hkm.KennelId and hem.UserId = hkm.UserId and hem.AttendenceState >= 20
	left outer join HC.Event evt on hem.EventId = evt.id
	where hkm.userId = @userId
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
	hkm.RollingYearTotalRunCount = rc.rollingYearTotalRunsThisKennel, 
	hkm.RollingYearHaringCount = rc.rollingYearHaringThisKennel,
	hkm.updatedAt = getdate()
	FROM HC.HasherKennelMap hkm 
	INNER JOIN cte on hkm.userid = cte.UserId AND hkm.KennelId = cte.KennelId
	INNER JOIN [HC4].[vwRunCountsRolling] rc on hkm.UserId = rc.userId and hkm.KennelId = rc.KennelId
	WHERE 
	hkm.UserId = @userId 
	AND
	(
		COALESCE(hkm.HcTotalRunCount,-999) != COALESCE(cte.maxTotalRunsThisKennel,999) OR
		COALESCE(hkm.HcHaringCount,-999) != COALESCE(cte.maxTotalHaringThisKennel,999) OR
		COALESCE(hkm.YtdTotalRunCount,-999) != COALESCE(cte.maxYtdTotalRunsThisKennel,999) OR
		COALESCE(hkm.YtdHaringCount,-999) != COALESCE(cte.maxYtdHaringThisKennel,999) OR
		COALESCE(hkm.DateOfLastRun, '1/1/1990') != COALESCE(cte.dateOfLastRun,'1/1/1990') OR
		COALESCE(RollingYearTotalRunCount,99999) != coalesce(rc.rollingYearTotalRunsThisKennel,99999) OR
		COALESCE(RollingYearHaringCount,99999) != coalesce(rc.rollingYearHaringThisKennel,99999)
	)


END
