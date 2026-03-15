/****** Object:  Table [LOG].[GeneralLog]    Script Date: 3/15/2026 7:42:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [LOG].[GeneralLog](
	[idx] [int] IDENTITY(1,1) NOT NULL,
	[LogSource] [nvarchar](50) NOT NULL,
	[Message] [nvarchar](255) NOT NULL,
	[StrParam1] [nvarchar](500) NULL,
	[Data] [nvarchar](4000) NULL,
	[Timestamp] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_GeneralLog] PRIMARY KEY CLUSTERED 
(
	[idx] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_GeneralLog]    Script Date: 3/15/2026 7:42:10 AM ******/
CREATE NONCLUSTERED INDEX [IX_GeneralLog] ON [LOG].[GeneralLog]
(
	[Timestamp] ASC,
	[LogSource] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_GeneralLog_Timestamp_LogSource]    Script Date: 3/15/2026 7:42:10 AM ******/
CREATE NONCLUSTERED INDEX [IX_GeneralLog_Timestamp_LogSource] ON [LOG].[GeneralLog]
(
	[Timestamp] ASC,
	[LogSource] ASC
)
INCLUDE([Data],[Message],[StrParam1]) WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [LOG].[GeneralLog] ADD  CONSTRAINT [DF_GeneralLog_Timestamp]  DEFAULT (getdate()) FOR [Timestamp]
GO
