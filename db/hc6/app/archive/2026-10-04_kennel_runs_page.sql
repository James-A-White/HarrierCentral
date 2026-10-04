-- Run-once (James runs, or says "run it"): the kennel RUNS PAGE import
-- (James, 2026-10-04: "add to the Kennel Editor a field for the runs page and
-- add the field to HC.Kennel … an API that runs on a timer 4 times a day using
-- the small Azure OpenAI model only when the page changes").
--
-- HC.Kennel gains:
--   RunsPageUrl        the kennel's page of upcoming runs (set in the portal)
--   RunsPageHash       SHA-256 of the page's text at the last read — the model
--                      is only called when this changes
--   RunsPageCheckedAt  last time the page was fetched
--   RunsPageChangedAt  last time its text changed (and the model was called)
--   RunsPageStatus     one line for the portal: what the last read found
-- None is in a sync rowset. HC.Kennel IS synced, so its updatedAt trigger is
-- off for the ALTER (house rule) and taught that a write touching
-- RunsPageCheckedAt is the importer's bookkeeping: it never stamps the row, so
-- reading a page four times a day never re-syncs a phone.
--
-- HC.Integration gains id 6, "Import from kennel runs page": the
-- InboundIntegrationId imported runs carry. Enabled = 0 on purpose — the
-- per-minute HcExternalDataIntegration timer only runs enabled rows; the runs
-- page has its own timer (RunsPageImport).
SET NOCOUNT ON;
SET XACT_ABORT ON;

DISABLE TRIGGER HC.trgUpdateModifiedOnDateForKennels ON HC.Kennel;
IF COL_LENGTH('HC.Kennel', 'RunsPageUrl') IS NULL
    ALTER TABLE HC.Kennel ADD
        RunsPageUrl       NVARCHAR(500) NULL,
        RunsPageHash      CHAR(64)      NULL,
        RunsPageCheckedAt DATETIME2(0)  NULL,
        RunsPageChangedAt DATETIME2(0)  NULL,
        RunsPageStatus    NVARCHAR(500) NULL;
ENABLE TRIGGER HC.trgUpdateModifiedOnDateForKennels ON HC.Kennel;
GO

CREATE OR ALTER TRIGGER [HC].[trgUpdateModifiedOnDateForKennels]
   ON  HC.Kennel
   AFTER INSERT, UPDATE
AS 
BEGIN

	SET NOCOUNT ON;

	IF ((NOT UPDATE(updatedAt)) AND (NOT UPDATE(IntegrationLastExecuted)) AND (NOT UPDATE(IntegrationLastShameEmailSent)) AND (NOT UPDATE(RunsPageCheckedAt)))
	BEGIN
		UPDATE tbl Set updatedAt = dateadd(MICROSECOND,tbl.updatedAtBias,SYSDATETIME()) 
		FROM HC.Kennel tbl
		INNER JOIN INSERTED ins on tbl.id = ins.id
	END

	IF UPDATE(updatedAt)
	BEGIN
		UPDATE tbl Set updatedAt = dateadd(MICROSECOND,tbl.updatedAtBias,CAST(ins.updatedAt as datetime2)) 
		FROM HC.Kennel tbl
		INNER JOIN INSERTED ins on tbl.id = ins.id
	END

	---- if the run attendence is changed at the Kennel level
	---- make sure we update all Events for the Kennel where
	---- the CanEditRunAttendence is null so that they are
	---- propagated to the mobile devices
	--IF UPDATE(CanEditRunAttendence)
	--BEGIN
	--	UPDATE HC.Event Set updatedAt = GETDATE() FROM HC.Event 
	--		WHERE KennelId in (SELECT id from INSERTED) 
	--		AND CanEditRunAttendence is null
	--	SET NOCOUNT ON
	--END

END
GO

IF NOT EXISTS (SELECT 1 FROM HC.Integration WHERE IntegrationId = 6)
BEGIN
    -- IntegrationId is an identity column; 6 is the id the app's
    -- integrationPlatformNames list gives this source.
    SET IDENTITY_INSERT HC.Integration ON;
    -- Direction / Type / HttpRequestType copied from Berlin (5), the other
    -- inbound import; Interval is documentation (6 h = 4 a day).
    INSERT HC.Integration (IntegrationId, IntegrationName, IntegrationAbbreviation, Interval, IntervalOffset,
                           Direction, Type, Enabled, CustomUrl, HttpRequestType, IntegrationMethodName,
                           MaxLat, MinLat, MaxLon, MinLon, Removed, updatedAt)
    SELECT 6, N'Import from kennel runs page', N'Runs page', 360, 0,
           Direction, Type, 0, N'', HttpRequestType, N'RunsPageImport',
           90, -90, 180, -180, 0, SYSDATETIMEOFFSET()
    FROM HC.Integration WHERE IntegrationId = 5;
    SET IDENTITY_INSERT HC.Integration OFF;
END
GO

SELECT COL_LENGTH('HC.Kennel', 'RunsPageUrl') AS runsPageUrlBytes;
SELECT name, is_disabled FROM sys.triggers WHERE parent_id = OBJECT_ID('HC.Kennel') AND name = 'trgUpdateModifiedOnDateForKennels';
SELECT IntegrationId, IntegrationName, Enabled FROM HC.Integration WHERE IntegrationId = 6;
GO
