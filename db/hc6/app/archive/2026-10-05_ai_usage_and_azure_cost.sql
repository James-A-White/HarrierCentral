-- =====================================================================
-- Run-once: LOG.AiUsage and LOG.AzureDailyCost (2026-10-05)
--
-- Both tables approved by James on 2026-10-05 ("New LOG.AiUsage table",
-- "New LOG.AzureDailyCost").
--
-- LOG.AiUsage — one row per AI model call, so token cost can be tracked
--   and shown on the portal's Usage Data monitor ('AI Tokens' row). Rows
--   from one timer run or one portal Test share a SessionId.
-- LOG.AzureDailyCost — one row per day per Azure service, read from Azure
--   Cost Management by the API's AzureDailyCost timer ('Azure Cost' row,
--   green when lower).
--
-- Neither table is synced: no updatedAt trigger to disable. Also marks
-- HC.Integration 6 Enabled (see below).
-- Idempotent: safe to re-run. Archive to db/hc6/app/archive/ once run.
-- =====================================================================
SET NOCOUNT ON;

IF OBJECT_ID('LOG.AiUsage') IS NULL
BEGIN
    CREATE TABLE LOG.AiUsage (
        Id               BIGINT IDENTITY(1,1) NOT NULL,
        CalledAt         DATETIME2(0)     NOT NULL CONSTRAINT DF_AiUsage_CalledAt DEFAULT (SYSUTCDATETIME()),
        SessionId        UNIQUEIDENTIFIER NULL,     -- one timer run / one portal Test
        Feature          NVARCHAR(50)     NOT NULL, -- 'runsPage', 'runsPageTest', …
        KennelId         UNIQUEIDENTIFIER NULL,
        Model            NVARCHAR(100)    NOT NULL, -- the deployment called
        PromptTokens     INT              NOT NULL CONSTRAINT DF_AiUsage_Prompt DEFAULT (0),
        CompletionTokens INT              NOT NULL CONSTRAINT DF_AiUsage_Completion DEFAULT (0),
        TotalTokens      AS (PromptTokens + CompletionTokens) PERSISTED,
        -- USD at the price in force when the call was made. DECIMAL(12,8),
        -- not the usual DECIMAL(10,4): one call costs about $0.0008, which
        -- four places would round by up to 6%.
        CostUsd          DECIMAL(12,8)    NULL,
        DurationMs       INT              NULL,
        Outcome          NVARCHAR(50)     NOT NULL, -- ok | length | content_filter | refusal | bad_json | http_<code> | timeout | unreachable
        Detail           NVARCHAR(500)    NULL,
        CONSTRAINT PK_AiUsage PRIMARY KEY CLUSTERED (Id)
    );
    CREATE NONCLUSTERED INDEX IX_AiUsage_CalledAt ON LOG.AiUsage (CalledAt)
        INCLUDE (Feature, KennelId, PromptTokens, CompletionTokens, CostUsd, Outcome);
    PRINT 'Created LOG.AiUsage';
END

IF OBJECT_ID('LOG.AzureDailyCost') IS NULL
BEGIN
    CREATE TABLE LOG.AzureDailyCost (
        CostDate     DATE           NOT NULL,   -- the UTC usage day
        ServiceName  NVARCHAR(100)  NOT NULL,   -- Cost Management's ServiceName
        Cost         DECIMAL(10,4)  NOT NULL,
        Currency     CHAR(3)        NOT NULL,   -- the billing currency (GBP)
        -- Last time this row was read. Cost Management settles a day over the
        -- following ~24 h, so the importer re-reads recent days; a day counts
        -- as complete once it was read 2+ days after it began.
        RetrievedAt  DATETIME2(0)   NOT NULL CONSTRAINT DF_AzureDailyCost_RetrievedAt DEFAULT (SYSUTCDATETIME()),
        CONSTRAINT PK_AzureDailyCost PRIMARY KEY CLUSTERED (CostDate, ServiceName)
    );
    PRINT 'Created LOG.AzureDailyCost';
END

-- Integration 6 (Runs page) is switched per kennel by the editor's
-- Inbound Integration drop-down; its Enabled flag now only drives the
-- monitor tile (James, 2026-10-05: "Drop-down only"). Mark it live so the
-- tile does not show the red disabled sign over a working import.
UPDATE HC.Integration SET Enabled = 1 WHERE IntegrationId = 6 AND Enabled = 0;

SELECT name, create_date FROM sys.tables
WHERE object_id IN (OBJECT_ID('LOG.AiUsage'), OBJECT_ID('LOG.AzureDailyCost'));
