-- LOG.AiUsage — one row per AI model call (2026-10-05, approved by James).
-- Created by db/hc6/app/archive/2026-10-05_ai_usage_and_azure_cost.sql.
CREATE TABLE [LOG].[AiUsage](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CalledAt] [datetime2](0) NOT NULL CONSTRAINT [DF_AiUsage_CalledAt] DEFAULT (sysutcdatetime()),
	[SessionId] [uniqueidentifier] NULL,
	[Feature] [nvarchar](50) NOT NULL,
	[KennelId] [uniqueidentifier] NULL,
	[Model] [nvarchar](100) NOT NULL,
	[PromptTokens] [int] NOT NULL CONSTRAINT [DF_AiUsage_Prompt] DEFAULT (0),
	[CompletionTokens] [int] NOT NULL CONSTRAINT [DF_AiUsage_Completion] DEFAULT (0),
	[TotalTokens] AS ([PromptTokens]+[CompletionTokens]) PERSISTED,
	[CostUsd] [decimal](12, 8) NULL,
	[DurationMs] [int] NULL,
	[Outcome] [nvarchar](50) NOT NULL,
	[Detail] [nvarchar](500) NULL,
 CONSTRAINT [PK_AiUsage] PRIMARY KEY CLUSTERED ([Id] ASC)
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_AiUsage_CalledAt] ON [LOG].[AiUsage] ([CalledAt] ASC)
INCLUDE ([Feature],[KennelId],[PromptTokens],[CompletionTokens],[CostUsd],[Outcome])
GO
