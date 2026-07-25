CREATE OR ALTER PROCEDURE [HC3].[extApi_daily_updateRunCounts]
AS
BEGIN
	-- EXEC [HC3].[extApi_dailyMaintenance]
	SET NOCOUNT ON

	DECLARE @startTime datetime
	SET @startTime = getdate()

	-- 2026-07-25: run-count recompute REMOVED — run counts are now owned by the
	-- HC6 SPs (HC6.nonApi_updateRunCountsForAllUsers). The old HC5 updater
	-- (HC.nonApi_updateRunCountsForAllUsers) used the EventStartDatetime columns
	-- and fought the HC6 version, churning ~100k HasherEventMap rows nightly.
	-- It has been neutered (logs + returns). Kennel-credit stays here until HC6
	-- has a ...ForAllUsers credit equivalent.
	-- EXEC HC.nonApi_updateRunCountsForAllUsers   -- retired
	EXEC HC.nonApi_updateKennelCreditForAllUsers

	INSERT LOG.GeneralLog(LogSource,Message) VALUES ('DAILY - update counts and credits','Execution time: ' + cast(datediff(second,@startTime,getdate()) as nvarchar(50)))

	SELECT 'Execution time: ' + cast(datediff(second,@startTime,getdate()) as nvarchar(50)) as Result
END
