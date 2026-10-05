-- LOG.AzureDailyCost — Azure cost per UTC day per service (2026-10-05,
-- approved by James). Created by
-- db/hc6/app/archive/2026-10-05_ai_usage_and_azure_cost.sql.
CREATE TABLE [LOG].[AzureDailyCost](
	[CostDate] [date] NOT NULL,
	[ServiceName] [nvarchar](100) NOT NULL,
	[Cost] [decimal](10, 4) NOT NULL,
	[Currency] [char](3) NOT NULL,
	[RetrievedAt] [datetime2](0) NOT NULL CONSTRAINT [DF_AzureDailyCost_RetrievedAt] DEFAULT (sysutcdatetime()),
 CONSTRAINT [PK_AzureDailyCost] PRIMARY KEY CLUSTERED ([CostDate] ASC, [ServiceName] ASC)
) ON [PRIMARY]
GO
