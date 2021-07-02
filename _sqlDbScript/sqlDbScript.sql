/****** Object:  Database [HarrierCentralWebDb]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'HarrierCentralWebDb')
BEGIN
CREATE DATABASE [HarrierCentralWebDb]  (EDITION = 'Basic', SERVICE_OBJECTIVE = 'Basic', MAXSIZE = 2 GB) WITH CATALOG_COLLATION = SQL_Latin1_General_CP1_CI_AS;

END
GO
ALTER DATABASE [HarrierCentralWebDb] SET COMPATIBILITY_LEVEL = 120
GO
ALTER DATABASE [HarrierCentralWebDb] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET ARITHABORT OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [HarrierCentralWebDb] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [HarrierCentralWebDb] SET READ_COMMITTED_SNAPSHOT ON 
GO
ALTER DATABASE [HarrierCentralWebDb] SET  MULTI_USER 
GO
ALTER DATABASE [HarrierCentralWebDb] SET ENCRYPTION ON
GO
ALTER DATABASE [HarrierCentralWebDb] SET QUERY_STORE = ON
GO
ALTER DATABASE [HarrierCentralWebDb] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 7), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 10, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
/****** Object:  User [zapieruser]    Script Date: 7/2/2021 4:18:13 AM ******/
CREATE USER [zapieruser] FOR LOGIN [zapierlogin] WITH DEFAULT_SCHEMA=[EXT]
GO
/****** Object:  User [officeFormsUser]    Script Date: 7/2/2021 4:18:13 AM ******/
CREATE USER [officeFormsUser] FOR LOGIN [officeFormsLogin] WITH DEFAULT_SCHEMA=[EXT]
GO
/****** Object:  Schema [Admin]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Admin')
EXEC sys.sp_executesql N'CREATE SCHEMA [Admin]'
GO
/****** Object:  Schema [DEV]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'DEV')
EXEC sys.sp_executesql N'CREATE SCHEMA [DEV]'
GO
/****** Object:  Schema [DomainValues]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'DomainValues')
EXEC sys.sp_executesql N'CREATE SCHEMA [DomainValues]'
GO
/****** Object:  Schema [Events]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Events')
EXEC sys.sp_executesql N'CREATE SCHEMA [Events]'
GO
/****** Object:  Schema [EXT]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'EXT')
EXEC sys.sp_executesql N'CREATE SCHEMA [EXT]'
GO
/****** Object:  Schema [Geography]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Geography')
EXEC sys.sp_executesql N'CREATE SCHEMA [Geography]'
GO
/****** Object:  Schema [Hashers]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Hashers')
EXEC sys.sp_executesql N'CREATE SCHEMA [Hashers]'
GO
/****** Object:  Schema [HC]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'HC')
EXEC sys.sp_executesql N'CREATE SCHEMA [HC]'
GO
/****** Object:  Schema [HC_BACKUP]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'HC_BACKUP')
EXEC sys.sp_executesql N'CREATE SCHEMA [HC_BACKUP]'
GO
/****** Object:  Schema [HC2]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'HC2')
EXEC sys.sp_executesql N'CREATE SCHEMA [HC2]'
GO
/****** Object:  Schema [HC3]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'HC3')
EXEC sys.sp_executesql N'CREATE SCHEMA [HC3]'
GO
/****** Object:  Schema [HC3W]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'HC3W')
EXEC sys.sp_executesql N'CREATE SCHEMA [HC3W]'
GO
/****** Object:  Schema [Kennels]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Kennels')
EXEC sys.sp_executesql N'CREATE SCHEMA [Kennels]'
GO
/****** Object:  Schema [Transactions]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'Transactions')
EXEC sys.sp_executesql N'CREATE SCHEMA [Transactions]'
GO
/****** Object:  Schema [UNUSED]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'UNUSED')
EXEC sys.sp_executesql N'CREATE SCHEMA [UNUSED]'
GO
/****** Object:  Schema [WORDZ]    Script Date: 7/2/2021 4:18:13 AM ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = N'WORDZ')
EXEC sys.sp_executesql N'CREATE SCHEMA [WORDZ]'
GO
/****** Object:  UserDefinedFunction [dbo].[fn_diagramobjects]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_diagramobjects]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'
	CREATE FUNCTION [dbo].[fn_diagramobjects]() 
	RETURNS int
	WITH EXECUTE AS N''dbo''
	AS
	BEGIN
		declare @id_upgraddiagrams		int
		declare @id_sysdiagrams			int
		declare @id_helpdiagrams		int
		declare @id_helpdiagramdefinition	int
		declare @id_creatediagram	int
		declare @id_renamediagram	int
		declare @id_alterdiagram 	int 
		declare @id_dropdiagram		int
		declare @InstalledObjects	int

		select @InstalledObjects = 0

		select 	@id_upgraddiagrams = object_id(N''dbo.sp_upgraddiagrams''),
			@id_sysdiagrams = object_id(N''dbo.sysdiagrams''),
			@id_helpdiagrams = object_id(N''dbo.sp_helpdiagrams''),
			@id_helpdiagramdefinition = object_id(N''dbo.sp_helpdiagramdefinition''),
			@id_creatediagram = object_id(N''dbo.sp_creatediagram''),
			@id_renamediagram = object_id(N''dbo.sp_renamediagram''),
			@id_alterdiagram = object_id(N''dbo.sp_alterdiagram''), 
			@id_dropdiagram = object_id(N''dbo.sp_dropdiagram'')

		if @id_upgraddiagrams is not null
			select @InstalledObjects = @InstalledObjects + 1
		if @id_sysdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 2
		if @id_helpdiagrams is not null
			select @InstalledObjects = @InstalledObjects + 4
		if @id_helpdiagramdefinition is not null
			select @InstalledObjects = @InstalledObjects + 8
		if @id_creatediagram is not null
			select @InstalledObjects = @InstalledObjects + 16
		if @id_renamediagram is not null
			select @InstalledObjects = @InstalledObjects + 32
		if @id_alterdiagram  is not null
			select @InstalledObjects = @InstalledObjects + 64
		if @id_dropdiagram is not null
			select @InstalledObjects = @InstalledObjects + 128
		
		return @InstalledObjects 
	END
	' 
END
GO
/****** Object:  UserDefinedFunction [HC].[CHECK_ACCESS_TOKEN]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[CHECK_ACCESS_TOKEN]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'
CREATE FUNCTION [HC].[CHECK_ACCESS_TOKEN] (@userId uniqueidentifier, @procName nvarchar(100), @accessToken nvarchar(1000), @paramString nvarchar(500))
RETURNS int
WITH EXECUTE AS CALLER
AS
BEGIN  
 -- Check three tokens... the one generated for this point in time and the previous and next codes.   
 -- This allows the clock on the user''s phone to be off by a small bit of time and yet still   
 -- produce a good access code. It also covers the case where an access code takes time to travel   
 -- through the network to reach the server and may be expired by the time it arrives. This also   
 -- helps cover cases where the division and rounding to INT on the server produces a different  
 -- number than the division that occurs on the client.  
 DECLARE @generatedToken nvarchar(2000)  
 DECLARE @try30 int = 0
 
 RETURN 1 -- Uncomment this line to disable access token checks  
 IF ((@accessToken is null) OR (datalength(@accessToken) < 50))   
 BEGIN  
  -- fail if Access token is null or does not have the correct amount of characters  
  -- return 0 to indicate failure  
  RETURN 0 
 END  
   
 SET @generatedToken = HC.CREATE_ACCESS_TOKEN(@userid,@procName,0,@paramString,5760)  
 if @generatedToken != @accessToken  
 BEGIN  
  SET @generatedToken = HC.CREATE_ACCESS_TOKEN(@userid,@procName,1,@paramString,5760)  
  if @generatedToken != @accessToken  
  BEGIN  
   SET @generatedToken = HC.CREATE_ACCESS_TOKEN(@userid,@procName,-1,@paramString,5760)  
   if @generatedToken != @accessToken  
   BEGIN  
    SET @generatedToken = HC.CREATE_ACCESS_TOKEN(@userid,@procName,2,@paramString,5760)  
    if @generatedToken != @accessToken  
    BEGIN  
     SET @generatedToken = HC.CREATE_ACCESS_TOKEN(@userid,@procName,-2,@paramString,5760)  
     if @generatedToken != @accessToken  
     BEGIN  
      SET @try30 = 1 
     END  
    END  
   END  
  END  
 END  

 IF (@try30 = 1)
 BEGIN
	 SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,0,@paramString,30)  
	 if @generatedToken != @accessToken  
	 BEGIN  
	  SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,1,@paramString,30)  
	  if @generatedToken != @accessToken  
	  BEGIN  
	   SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,-1,@paramString,30)  
	   if @generatedToken != @accessToken  
	   BEGIN  
		SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,2,@paramString,30)  
		if @generatedToken != @accessToken  
		BEGIN  
		 SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,-2,@paramString,30)  
		 if @generatedToken != @accessToken  
		 BEGIN  
		  RETURN 0
		 END  
		END  
	   END  
	  END  
	 END 
 END

  
 RETURN 1  
END  
' 
END
GO
/****** Object:  UserDefinedFunction [HC].[CREATE_ACCESS_TOKEN]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[CREATE_ACCESS_TOKEN]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'
CREATE FUNCTION [HC].[CREATE_ACCESS_TOKEN] (@userId uniqueidentifier, @procName varchar(500),@offset int,@paramString nvarchar(500), @timeWindow int)
RETURNS varchar(MAX)
WITH EXECUTE AS CALLER
AS
BEGIN
	declare @bin as varbinary(max)

	if @paramString IS NOT NULL SET @paramString = upper(''#''+@paramString)

	--return upper(cast(@userId as nvarchar(50))) + ''#''+@procName+''#'' + cast((cast(datediff(second,''25 Jul 1993 15:00'',GETUTCDATE()) / 5760 as int)+@offset) as nvarchar(50))
	DECLARE @str as varchar(2000)
	SET @str = upper(cast(@userId as varchar(50))) + ''#''+@procName+''#'' + cast((cast(datediff(second,''25 Jul 1993 15:00'',GETUTCDATE()) / @timeWindow as int)+@offset) as varchar(50)) + coalesce(@paramString,'''')
	SET @bin = HASHBYTES(''SHA2_256'',@str)
	return cast('''' as xml).value(''xs:hexBinary(sql:variable("@bin"))'', ''varchar(max)'')
END


' 
END
GO
/****** Object:  UserDefinedFunction [HC].[CREATE_ACCESS_TOKEN_V2]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[CREATE_ACCESS_TOKEN_V2]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'
CREATE FUNCTION [HC].[CREATE_ACCESS_TOKEN_V2] (@userId uniqueidentifier, @procName varchar(500),@offset int,@paramString nvarchar(500), @timeWindow int)
RETURNS varchar(MAX)
WITH EXECUTE AS CALLER
AS
BEGIN
	declare @bin as varbinary(max)

	if @paramString IS NOT NULL SET @paramString = upper(''#''+@paramString)

	--return upper(cast(@userId as nvarchar(50))) + ''#''+@procName+''#'' + cast((cast(datediff(second,''25 Jul 1993 15:00'',GETUTCDATE()) / 5760 as int)+@offset) as nvarchar(50))
	DECLARE @str as varchar(2000)
	--SET @str = upper(cast(@userId as varchar(50))) + ''#''+@procName+''#'' + cast((cast(datediff(second,''25 Jul 1993 15:00'',GETUTCDATE()) / @timeWindow as int)+@offset) as varchar(50)) + coalesce(@paramString,'''')
	SET @str = upper(cast(@userId as varchar(50)) + ''#''+@procName+''#'' + cast((cast(datediff(second,''25 Jul 1993 15:00'',GETUTCDATE()) / @timeWindow as int)+@offset) as varchar(50)) + coalesce(@paramString,''''))
	SET @bin = HASHBYTES(''SHA2_256'',@str)
	return cast('''' as xml).value(''xs:hexBinary(sql:variable("@bin"))'', ''varchar(max)'')
END


' 
END
GO
/****** Object:  UserDefinedFunction [HC].[GENERATE_SIX_RANDOM_CHARACTERS]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[GENERATE_SIX_RANDOM_CHARACTERS]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'
CREATE FUNCTION [HC].[GENERATE_SIX_RANDOM_CHARACTERS] (@number int,@prefix nvarchar(120),@includeNumbers char(1))
RETURNS nvarchar(50)
WITH EXECUTE AS CALLER
AS
BEGIN
	 DECLARE @base int = 36
	 IF (UPPER(@includeNumbers) = ''N'') SET @base = 26

	 -- SELECT HC.GENERATE_SIX_RANDOM_CHARACTERS(CAST( RAND() * 2147483647 as int),''USC:'',''Y'')
	
     DECLARE @dividend int = @number
        ,@remainder int = 0 
        ,@numberString varchar(MAX) = CASE WHEN @number = 0 THEN ''0'' ELSE '''' END ;
      WHILE (@dividend > 0 OR @remainder > 0)
         BEGIN
            SET @remainder = @dividend % @base ; --The reminder by the division number in base
            SET @dividend = @dividend / @base ; -- The integer part of the division, becomes the new divident for the next loop
            IF(@dividend > 0 OR @remainder > 0)--check that not correspond the last loop when quotient and reminder is 0
                SET @numberString =  CHAR( (CASE WHEN @remainder <= 25 THEN ASCII(''A'') ELSE ASCII(''0'')-26 END) + @remainder ) + @numberString;
     END;
     RETURN(@prefix+RIGHT(''AAAAAA'' + @numberString,6));
END
' 
END
GO
/****** Object:  UserDefinedFunction [HC].[InlineMax]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[InlineMax]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'create function [HC].[InlineMax](@val1 int, @val2 int)
returns int
as
begin
  if @val1 > @val2
    return @val1
  return isnull(@val2,@val1)
end' 
END
GO
/****** Object:  UserDefinedFunction [HC].[NUMBER_TO_STR_BASE]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[NUMBER_TO_STR_BASE]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'
CREATE FUNCTION [HC].[NUMBER_TO_STR_BASE] (@base int,@number int)
RETURNS varchar(MAX)
WITH EXECUTE AS CALLER
AS
BEGIN
     DECLARE @dividend int = @number
        ,@remainder int = 0 
        ,@numberString varchar(MAX) = CASE WHEN @number = 0 THEN ''0'' ELSE '''' END ;
     SET @base = CASE WHEN @base <= 36 THEN @base ELSE 36 END;--The max base is 36, includes the range of [0-9A-Z]
     WHILE (@dividend > 0 OR @remainder > 0)
         BEGIN
            SET @remainder = @dividend % @base ; --The reminder by the division number in base
            SET @dividend = @dividend / @base ; -- The integer part of the division, becomes the new divident for the next loop
            IF(@dividend > 0 OR @remainder > 0)--check that not correspond the last loop when quotient and reminder is 0
                SET @numberString =  CHAR( (CASE WHEN @remainder <= 25 THEN ASCII(''A'') ELSE ASCII(''0'')-26 END) + @remainder ) + @numberString;
     END;
     RETURN(@numberString);
END
' 
END
GO
/****** Object:  Table [HC].[EmailLog]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[EmailLog]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[EmailLog](
	[id] [uniqueidentifier] NOT NULL,
	[EmailTemplaterId] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NOT NULL,
	[DateSent] [datetimeoffset](7) NOT NULL,
	[NumberSent] [int] NOT NULL,
	[ServerReply] [nvarchar](2500) NULL,
 CONSTRAINT [PK_EmailLog] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[Hasher]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[Hasher]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[Hasher](
	[id] [uniqueidentifier] NOT NULL,
	[HomeKennelId] [uniqueidentifier] NULL,
	[MotherKennelId] [uniqueidentifier] NULL,
	[SupportCode] [nvarchar](50) NOT NULL,
	[ResetCode] [nvarchar](50) NOT NULL,
	[QR_code] [nvarchar](50) NOT NULL,
	[QR_secret_code] [uniqueidentifier] NOT NULL,
	[DisplayName] [nvarchar](250) NOT NULL,
	[HashName] [nvarchar](250) NULL,
	[FirstName] [nvarchar](250) NULL,
	[LastName] [nvarchar](250) NULL,
	[Email] [nvarchar](250) NOT NULL,
	[Photo] [nvarchar](250) NULL,
	[Gender] [nvarchar](50) NULL,
	[FacebookId] [nvarchar](250) NULL,
	[FacebookAccessToken] [nvarchar](250) NULL,
	[FacebookAccessTokenLastUpdated] [datetimeoffset](7) NULL,
	[Locale] [nvarchar](50) NULL,
	[Description] [nvarchar](4000) NULL,
	[HomeLatitude] [decimal](12, 9) NULL,
	[HomeLongitude] [decimal](13, 9) NULL,
	[HomeGeolocation] [geography] NULL,
	[NameDisplayPreference] [smallint] NOT NULL,
	[Preferences] [int] NOT NULL,
	[HcWebUserId] [int] NULL,
	[IncludeInGlobalHashDirectory] [smallint] NOT NULL,
	[Removed] [smallint] NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL,
	[SingleSignOnId] [nvarchar](250) NULL,
	[SingleSignOnType] [nvarchar](50) NULL,
	[ResetCodeLastUpdated] [datetimeoffset](7) NULL,
 CONSTRAINT [PK_Hasher] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[HasherKennelMap]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[HasherKennelMap]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[HasherKennelMap](
	[id] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[Following] [smallint] NOT NULL,
	[IsMember] [smallint] NOT NULL,
	[IsKennelFollowing] [smallint] NOT NULL,
	[IsHomeKennel] [smallint] NOT NULL,
	[KennelNotificationPreference] [smallint] NOT NULL,
	[KennelEmailAlertPreference] [smallint] NOT NULL,
	[MismanagementRoles] [int] NOT NULL,
	[MismanagementRoleFlags] [int] NOT NULL,
	[HcWebPermissionFlags] [int] NOT NULL,
	[UserRoleFlags] [int] NOT NULL,
	[AppAccessFlags] [int] NULL,
	[HistoricalPackRunCount] [smallint] NOT NULL,
	[HistoricalHaringCount] [smallint] NOT NULL,
	[HistoricalCountIsEstimate] [smallint] NOT NULL,
	[CurrentPackRunCount] [smallint] NOT NULL,
	[CurrentHaringCount] [smallint] NOT NULL,
	[DateOfLastRun] [datetimeoffset](7) NULL,
	[MembershipExpirationDate] [datetimeoffset](7) NULL,
	[MemberSince] [datetimeoffset](7) NULL,
	[CanEditRunAttendence] [smallint] NOT NULL,
	[removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_HasherKennelMap] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[Event]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[Event]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[Event](
	[id] [uniqueidentifier] NOT NULL,
	[EventStartDatetime] [datetimeoffset](7) NULL,
	[EventEndDatetime] [datetimeoffset](7) NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[IsVisible] [smallint] NOT NULL,
	[IsCountedRun] [smallint] NOT NULL,
	[IsPromotedEvent] [smallint] NOT NULL,
	[EventGeographicScope] [smallint] NOT NULL,
	[ThemeRunType] [int] NOT NULL,
	[Tags1] [int] NOT NULL,
	[Tags2] [int] NOT NULL,
	[Tags3] [int] NOT NULL,
	[AbsoluteEventNumber] [smallint] NULL,
	[EventNumber] [smallint] NOT NULL,
	[EventNumberIncrement] [smallint] NOT NULL,
	[DoTrackHashCash] [smallint] NOT NULL,
	[EventPriceForMembers] [decimal](10, 4) NULL,
	[EventPriceForNonMembers] [decimal](10, 4) NULL,
	[EventPriceForExtras] [decimal](10, 4) NULL,
	[ExtrasDescription] [nvarchar](250) NULL,
	[EventCurrencyType] [nvarchar](10) NULL,
	[BankScheme] [nvarchar](10) NULL,
	[BankAccountNumber] [nvarchar](50) NULL,
	[BankBic] [nvarchar](50) NULL,
	[BankBeneficiary] [nvarchar](150) NULL,
	[EventPaymentScheme] [nvarchar](10) NULL,
	[EventPaymentUrl] [nvarchar](2000) NULL,
	[EventPaymentUrlExpires] [datetimeoffset](7) NULL,
	[UnconfirmedBankXferCount] [int] NOT NULL,
	[UserEventCounterIncrement] [smallint] NOT NULL,
	[EventName] [nvarchar](250) NOT NULL,
	[EventDescription] [nvarchar](4000) NULL,
	[EventImage] [nvarchar](500) NULL,
	[EventImageOffsetX] [smallint] NULL,
	[EventImageOffsetY] [smallint] NULL,
	[LocationOneLineDesc] [nvarchar](250) NULL,
	[LocationCity] [nvarchar](250) NULL,
	[LocationStreet] [nvarchar](250) NULL,
	[LocationPostCode] [nvarchar](250) NULL,
	[LocationSubRegion] [nvarchar](250) NULL,
	[LocationRegion] [nvarchar](250) NULL,
	[LocationCountry] [nvarchar](250) NULL,
	[Latitude] [decimal](18, 15) NULL,
	[Longitude] [decimal](19, 15) NULL,
	[EventGeolocation] [geography] NULL,
	[MinimumParticipantsRequired] [smallint] NOT NULL,
	[MaximumParticipantsAllowed] [smallint] NULL,
	[Organizer_HasherId] [uniqueidentifier] NULL,
	[CanEditRunAttendence] [smallint] NOT NULL,
	[Hares] [nvarchar](2500) NULL,
	[UseFbRunDetails] [smallint] NOT NULL,
	[UseFbLocation] [smallint] NOT NULL,
	[UseFbLatLon] [smallint] NOT NULL,
	[UpdateDataFromFacebook] [smallint] NOT NULL,
	[EventSource] [nvarchar](50) NOT NULL,
	[EventFacebookId] [nvarchar](250) NULL,
	[FacebookRecordLastUpdated] [datetimeoffset](7) NULL,
	[FbEventName] [nvarchar](250) NULL,
	[FbEventDescription] [nvarchar](4000) NULL,
	[FbEventStartDatetime] [datetimeoffset](7) NULL,
	[FbEventImage] [nvarchar](500) NULL,
	[FbEventImageOffsetX] [smallint] NULL,
	[FbEventImageOffsetY] [smallint] NULL,
	[FbLocationOneLineDesc] [nvarchar](250) NULL,
	[FbLocationCity] [nvarchar](250) NULL,
	[FbLocationStreet] [nvarchar](250) NULL,
	[FbLocationPostCode] [nvarchar](250) NULL,
	[FbLocationSubRegion] [nvarchar](250) NULL,
	[FbLocationRegion] [nvarchar](250) NULL,
	[FbLocationCountry] [nvarchar](250) NULL,
	[FbLatitude] [decimal](18, 15) NULL,
	[FbLongitude] [decimal](19, 15) NULL,
	[FbEventGeoLocation] [geography] NULL,
	[PublishToGoogleId] [nvarchar](250) NULL,
	[removed] [smallint] NOT NULL,
	[deleted] [bit] NOT NULL,
	[lastModified] [datetimeoffset](7) NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Event] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[EmailTemplate]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[EmailTemplate]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[EmailTemplate](
	[id] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NULL,
	[Description] [nvarchar](250) NOT NULL,
	[Subject] [nvarchar](250) NOT NULL,
	[Template] [nvarchar](max) NOT NULL,
	[EmailTypeFlag] [int] NOT NULL,
	[HoursBeforeRun] [smallint] NOT NULL,
	[DaysBeforeRun] [smallint] NOT NULL,
	[SendToAll] [smallint] NOT NULL,
	[SendToMembers] [smallint] NOT NULL,
	[SendToMismanagement] [smallint] NOT NULL,
	[SendToFollowers] [smallint] NOT NULL,
	[SendToVisitors] [smallint] NOT NULL,
	[ReplyToEmailAddress] [nvarchar](250) NOT NULL,
	[SenderName] [nvarchar](250) NOT NULL,
	[SendWhenHareAssigned] [smallint] NOT NULL,
 CONSTRAINT [PK_EmailTemplate] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[Kennel]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[Kennel]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[Kennel](
	[id] [uniqueidentifier] NOT NULL,
	[KennelStatus] [smallint] NOT NULL,
	[KennelName] [nvarchar](250) NOT NULL,
	[IntegrationType] [nvarchar](50) NOT NULL,
	[IntegrationImportDaysInPast] [smallint] NOT NULL,
	[IntegrationImportDaysInFuture] [smallint] NOT NULL,
	[IntegrationForceUpdatesUntil] [datetimeoffset](7) NULL,
	[IntegrationAutoImportEvents] [smallint] NOT NULL,
	[IntegrationImportOnlyTaggedEvents] [smallint] NOT NULL,
	[IntegrationTagForImport] [nvarchar](500) NULL,
	[GoogleCalendarId] [nvarchar](250) NULL,
	[KennelFacebookId] [nvarchar](250) NULL,
	[KennelFacebookToken] [nvarchar](1000) NULL,
	[KennelFacebookTokenUserId] [uniqueidentifier] NULL,
	[KennelFacebookTokenUsername] [nvarchar](200) NULL,
	[KennelFacebookTokenLastUpdated] [datetimeoffset](7) NULL,
	[PublishToGoogleCalendar] [smallint] NOT NULL,
	[PublishToGoogleCalendarId] [nvarchar](250) NULL,
	[CanEditRunAttendence] [smallint] NOT NULL,
	[KennelShortName] [nvarchar](10) NULL,
	[KennelDescription] [nvarchar](4000) NULL,
	[KennelLogo] [nvarchar](500) NOT NULL,
	[KennelPinColor] [smallint] NOT NULL,
	[KennelCoverPhoto] [nvarchar](500) NULL,
	[KennelWebsiteUrl] [nvarchar](500) NULL,
	[KennelMismanagementTeam] [nvarchar](4000) NULL,
	[DefaultEventPriceForMembers] [decimal](10, 4) NOT NULL,
	[DefaultEventPriceForNonMembers] [decimal](10, 4) NOT NULL,
	[DefaultEventCurrencyType] [nvarchar](10) NULL,
	[DefaultRunStartTime] [time](7) NOT NULL,
	[CurrencyCode] [nvarchar](5) NULL,
	[PrimaryCultureCode] [nvarchar](10) NULL,
	[CurrencySymbol] [nvarchar](5) NULL,
	[DigitsAfterDecimal] [smallint] NULL,
	[BankScheme] [nvarchar](10) NULL,
	[BankAccountNumber] [nvarchar](50) NULL,
	[BankBic] [nvarchar](50) NULL,
	[BankBeneficiary] [nvarchar](150) NULL,
	[KennelPaymentScheme] [nvarchar](50) NULL,
	[KennelPaymentUrl] [nvarchar](2000) NULL,
	[KennelPaymentUrlExpires] [datetimeoffset](7) NULL,
	[KennelPaymentMemberSurcharge] [decimal](10, 4) NULL,
	[KennelPaymentNonMemberSurcharge] [decimal](10, 4) NULL,
	[KennelPaymentScheme2] [nvarchar](50) NULL,
	[KennelPaymentUrl2] [nvarchar](2000) NULL,
	[KennelPaymentUrlExpires2] [datetimeoffset](7) NULL,
	[KennelPaymentMemberSurcharge2] [decimal](10, 4) NULL,
	[KennelPaymentNonMemberSurcharge2] [decimal](10, 4) NULL,
	[KennelPaymentScheme3] [nvarchar](50) NULL,
	[KennelPaymentUrl3] [nvarchar](2000) NULL,
	[KennelPaymentUrlExpires3] [datetimeoffset](7) NULL,
	[KennelPaymentMemberSurcharge3] [decimal](10, 4) NULL,
	[KennelPaymentNonMemberSurcharge3] [decimal](10, 4) NULL,
	[AllowSelfPayment] [smallint] NOT NULL,
	[AllowNegativeCredit] [smallint] NOT NULL,
	[CityId] [uniqueidentifier] NOT NULL,
	[ProvinceStateId] [uniqueidentifier] NOT NULL,
	[CountryId] [uniqueidentifier] NOT NULL,
	[Latitude] [decimal](18, 14) NULL,
	[Longitude] [decimal](19, 15) NULL,
	[KennelGeolocation] [geography] NULL,
	[MembershipDurationInMonths] [int] NOT NULL,
	[RunCountStartDate] [datetimeoffset](7) NULL,
	[DistancePreference] [smallint] NULL,
	[ExtApiKey] [nvarchar](120) NULL,
	[removed] [smallint] NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL,
 CONSTRAINT [PK_Kennel_1] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  View [HC3W].[vwAdEmailLogList]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3W].[vwAdEmailLogList]'))
EXEC dbo.sp_executesql @statement = N'




CREATE VIEW [HC3W].[vwAdEmailLogList] AS

SELECT 
	h.HcWebUserId,
	elog.[id]
      ,[EmailTemplaterId]
      ,elog.[EventId]
      ,[DateSent]
      ,[NumberSent]
      ,[ServerReply]
FROM HC.Kennel k 
INNER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = k.id
INNER JOIN HC.Hasher h ON hkm.UserId = h.id
INNER JOIN HC.EmailTemplate em on em.KennelId = k.id
INNER JOIN HC.Event e on e.KennelId = k.id
INNER JOIN HC.EmailLog elog on elog.EventId = e.id
WHERE ((hkm.HcWebPermissionFlags & 0x0001) = 0x0001 AND h.HcWebUserId IS NOT NULL) OR (h.HcWebUserId < 10)
' 
GO
/****** Object:  Table [HC].[Country]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[Country]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[Country](
	[id] [uniqueidentifier] NOT NULL,
	[CountryCode] [nvarchar](5) NOT NULL,
	[Latitude] [float] NOT NULL,
	[Longitude] [float] NOT NULL,
	[CountryName] [nvarchar](250) NOT NULL,
	[ContinentCode] [nvarchar](5) NOT NULL,
	[ContinentName] [nvarchar](100) NOT NULL,
	[FlagFile] [nvarchar](100) NULL,
	[CurrencyCode] [nvarchar](5) NOT NULL,
	[PrimaryCultureCode] [nvarchar](10) NOT NULL,
	[ShowRegion] [smallint] NOT NULL,
	[CurrencySymbol] [nvarchar](5) NOT NULL,
	[DigitsAfterDecimal] [smallint] NOT NULL,
	[DistancePreference] [smallint] NOT NULL,
	[Removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Country] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  View [dbo].[vw_deleteCurrencyTest]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteCurrencyTest]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteCurrencyTest] as
select c.CountryName, c.CurrencySymbol, c.DigitsAfterDecimal,c.id from HC.Country c' 
GO
/****** Object:  View [HC3W].[vwSaHasher]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3W].[vwSaHasher]'))
EXEC dbo.sp_executesql @statement = N'
CREATE VIEW [HC3W].[vwSaHasher] AS

SELECT [id]
      ,[HomeKennelId]
      ,[MotherKennelId]
      ,[SupportCode]
      ,[ResetCode]
      ,[QR_code]
      ,[QR_secret_code]
      ,[DisplayName]
      ,[HashName]
      ,[FirstName]
      ,[LastName]
      ,[Email]
      ,[Photo]
      ,[Gender]
      ,[FacebookId]
      ,[Locale]
      ,[Description]
      ,[HomeLatitude]
      ,[HomeLongitude]
      ,[HomeGeolocation]
      ,[NameDisplayPreference]
      ,[HcWebUserId]
      ,[Removed]
      ,[version]
      ,[createdAt]
      ,[updatedAt]
      ,[deleted]
  FROM [HC].[Hasher] WHERE Removed = 0
' 
GO
/****** Object:  View [dbo].[vw_deleteHcPhotos]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteHcPhotos]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteHcPhotos] as
select Photo,id,DisplayName from HC.Hasher
where createdAt > dateadd(day,-20,getdate())' 
GO
/****** Object:  View [HC3W].[vwAdKennel]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3W].[vwAdKennel]'))
EXEC dbo.sp_executesql @statement = N'









CREATE VIEW [HC3W].[vwAdKennel] AS

SELECT 

	  [id]

	  -- Basic Kennel info
      ,[KennelStatus]
      ,[KennelName]
      ,[KennelShortName]
      ,[KennelDescription]
      ,[KennelLogo]
	  ,[KennelPinColor]
      ,[KennelCoverPhoto]
      ,[KennelWebsiteUrl]
	  ,[KennelMismanagementTeam]

	  -- Hash Cash info
      ,[DefaultEventPriceForMembers]
      ,[DefaultEventPriceForNonMembers]
      ,[DefaultEventCurrencyType]
      ,[CurrencyCode]
      ,[PrimaryCultureCode]
      ,[CurrencySymbol]
      ,[DigitsAfterDecimal]
      ,[BankScheme]
      ,[BankAccountNumber]
      ,[BankBic]
      ,[BankBeneficiary]
	  ,[KennelPaymentScheme]
      ,[KennelPaymentUrl]
      ,[KennelPaymentUrlExpires]
	  ,[KennelPaymentMemberSurcharge]
	  ,[KennelPaymentNonMemberSurcharge]
	  ,[KennelPaymentScheme2]
      ,[KennelPaymentUrl2]
      ,[KennelPaymentUrlExpires2]
	  ,[KennelPaymentMemberSurcharge2]
	  ,[KennelPaymentNonMemberSurcharge2]
	  ,[KennelPaymentScheme3]
      ,[KennelPaymentUrl3]
      ,[KennelPaymentUrlExpires3]
	  ,[KennelPaymentMemberSurcharge3]
	  ,[KennelPaymentNonMemberSurcharge3]
	  ,[AllowSelfPayment]
	  ,[AllowNegativeCredit]

	  -- Location info
      ,[CityId]
      ,[ProvinceStateId]
      ,[CountryId]
      ,[Latitude]
      ,[Longitude]

	  ,[DefaultRunStartTime]
      ,[MembershipDurationInMonths]
      ,[RunCountStartDate]
      ,[ExtApiKey]
	  ,[DistancePreference]

	  -- integration fields
	  ,[IntegrationType]
	  ,[IntegrationAutoImportEvents]
      ,[IntegrationImportOnlyTaggedEvents]
      ,[IntegrationTagForImport]
	  ,[GoogleCalendarId]
	  ,[KennelFacebookId]

	  -- publish to fields
	  ,[PublishToGoogleCalendar]
	  ,[PublishToGoogleCalendarId]

	  ,[CanEditRunAttendence]

FROM HC.Kennel
' 
GO
/****** Object:  View [dbo].[vwEventAdjusted]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vwEventAdjusted]'))
EXEC dbo.sp_executesql @statement = N'
CREATE VIEW [dbo].[vwEventAdjusted] 

AS

SELECT evt.[id]

      ,evt.[EventEndDatetime]
      ,evt.[KennelId]
      ,evt.[IsVisible]
      ,evt.[IsCountedRun]
      ,evt.[IsPromotedEvent]
      ,evt.[EventGeographicScope]
      ,evt.[ThemeRunType]
      ,evt.[AbsoluteEventNumber]
      ,evt.[EventNumber]
      ,evt.[EventNumberIncrement]
      ,evt.[DoTrackHashCash]
	  ,CASE WHEN evt.DoTrackHashCash = 0 THEN ''-'' ELSE COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(coalesce(evt.[EventPriceForMembers],k.DefaultEventPriceForMembers),20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') END as EventPriceForMembers
      ,CASE WHEN evt.DoTrackHashCash = 0 THEN ''-'' ELSE COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(coalesce(evt.[EventPriceForNonMembers],k.DefaultEventPriceForNonMembers),20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') END as EventPriceForNonMembers
      ,evt.[EventPriceForExtras]
      ,evt.[ExtrasDescription]
      ,evt.[EventCurrencyType]
      ,evt.[BankScheme]
      ,evt.[BankAccountNumber]
      ,evt.[BankBic]
      ,evt.[BankBeneficiary]
      ,evt.[EventPaymentUrl]
      ,evt.[EventPaymentUrlExpires]
      ,evt.[UnconfirmedBankXferCount]
      ,evt.[UserEventCounterIncrement]

      ,CASE WHEN UseFbRunDetails = 0 THEN evt.[EventName] ELSE evt.[FbEventName] END AS [EventName]
      ,CASE WHEN UseFbRunDetails = 0 THEN evt.[EventDescription] ELSE evt.[FbEventDescription] END AS [EventDescription]
	  ,CASE WHEN UseFbRunDetails = 0 THEN evt.[EventStartDatetime] ELSE evt.[FbEventStartDatetime] END AS [EventStartDatetime]
      ,CASE WHEN UseFbRunDetails = 0 THEN evt.[EventImage] ELSE evt.[FbEventImage] END AS [EventImage]
      ,CASE WHEN UseFbRunDetails = 0 THEN evt.[EventImageOffsetX] ELSE evt.[FbEventImageOffsetX] END AS [EventImageOffsetX]
      ,CASE WHEN UseFbRunDetails = 0 THEN evt.[EventImageOffsetY] ELSE evt.[FbEventImageOffsetY] END AS [EventImageOffsetY]

      ,CASE WHEN UseFbLocation = 0 THEN evt.[LocationOneLineDesc] ELSE evt.[FbLocationOneLineDesc] END AS [LocationOneLineDesc]
      ,CASE WHEN UseFbLocation = 0 THEN evt.[LocationCity] ELSE evt.[FbLocationCity] END AS [LocationCity]
      ,CASE WHEN UseFbLocation = 0 THEN evt.[LocationStreet] ELSE evt.[FbLocationStreet] END AS [LocationStreet]
      ,CASE WHEN UseFbLocation = 0 THEN evt.[LocationPostCode] ELSE evt.[FbLocationPostCode] END AS [LocationPostCode]
      ,CASE WHEN UseFbLocation = 0 THEN evt.[LocationCountry] ELSE evt.[FbLocationCountry] END AS [LocationCountry]

      ,CASE WHEN UseFbLatLon = 0 THEN evt.[Latitude] ELSE evt.[FbLatitude] END AS [Latitude]
      ,CASE WHEN UseFbLatLon = 0 THEN evt.[Longitude] ELSE evt.[FbLongitude] END AS [Longitude]
	  ,CASE WHEN UseFbLatLon = 0 THEN evt.[EventGeolocation] ELSE evt.[FbEventGeoLocation] END AS [EventGeolocation]

      ,evt.[MinimumParticipantsRequired]
      ,evt.[MaximumParticipantsAllowed]
      ,evt.[Organizer_HasherId]
      ,evt.[CanEditRunAttendence]
      ,evt.[Hares]

      ,evt.[UpdateDataFromFacebook]
      ,evt.[EventFacebookId]
      ,evt.[FacebookRecordLastUpdated]

      ,evt.[removed]
      ,evt.[deleted]
      ,evt.[lastModified]
      ,evt.[version]
      ,evt.[createdAt]
      ,evt.[updatedAt]
  FROM [HC].[Event] evt
  INNER JOIN HC.Kennel k on evt.KennelId = k.id
  INNER JOIN HC.Country co on co.id = k.CountryId
' 
GO
/****** Object:  View [HC].[vwEventAdjusted]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC].[vwEventAdjusted]'))
EXEC dbo.sp_executesql @statement = N'

CREATE VIEW [HC].[vwEventAdjusted] 

AS

SELECT evt.[id]

      ,evt.[EventEndDatetime]
      ,evt.[KennelId]
      ,evt.[IsVisible]
      ,evt.[IsCountedRun]
      ,evt.[IsPromotedEvent]
      ,evt.[EventGeographicScope]
      ,evt.[ThemeRunType]
      ,evt.[AbsoluteEventNumber]
      ,evt.[EventNumber]
      ,evt.[EventNumberIncrement]
      ,evt.[DoTrackHashCash]
	  ,CASE WHEN evt.DoTrackHashCash = 0 THEN ''-'' ELSE COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(coalesce(evt.[EventPriceForMembers],k.DefaultEventPriceForMembers),20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') END as EventPriceForMembers
      ,CASE WHEN evt.DoTrackHashCash = 0 THEN ''-'' ELSE COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(coalesce(evt.[EventPriceForNonMembers],k.DefaultEventPriceForNonMembers),20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') END as EventPriceForNonMembers
      ,evt.[EventPriceForExtras]
      ,evt.[ExtrasDescription]
      ,evt.[EventCurrencyType]
      ,evt.[BankScheme]
      ,evt.[BankAccountNumber]
      ,evt.[BankBic]
      ,evt.[BankBeneficiary]
      ,evt.[EventPaymentUrl]
      ,evt.[EventPaymentUrlExpires]
      ,evt.[UnconfirmedBankXferCount]
      ,evt.[UserEventCounterIncrement]

      ,CASE WHEN UseFbRunDetails = 0 THEN evt.[EventName] ELSE evt.[FbEventName] END AS [EventName]
      ,CASE WHEN UseFbRunDetails = 0 THEN evt.[EventDescription] ELSE evt.[FbEventDescription] END AS [EventDescription]
	  ,CASE WHEN UseFbRunDetails = 0 THEN evt.[EventStartDatetime] ELSE evt.[FbEventStartDatetime] END AS [EventStartDatetime]
      ,CASE WHEN UseFbRunDetails = 0 THEN evt.[EventImage] ELSE evt.[FbEventImage] END AS [EventImage]
      ,CASE WHEN UseFbRunDetails = 0 THEN evt.[EventImageOffsetX] ELSE evt.[FbEventImageOffsetX] END AS [EventImageOffsetX]
      ,CASE WHEN UseFbRunDetails = 0 THEN evt.[EventImageOffsetY] ELSE evt.[FbEventImageOffsetY] END AS [EventImageOffsetY]

      ,CASE WHEN UseFbLocation = 0 THEN evt.[LocationOneLineDesc] ELSE evt.[FbLocationOneLineDesc] END AS [LocationOneLineDesc]
      ,CASE WHEN UseFbLocation = 0 THEN evt.[LocationCity] ELSE evt.[FbLocationCity] END AS [LocationCity]
      ,CASE WHEN UseFbLocation = 0 THEN evt.[LocationStreet] ELSE evt.[FbLocationStreet] END AS [LocationStreet]
      ,CASE WHEN UseFbLocation = 0 THEN evt.[LocationPostCode] ELSE evt.[FbLocationPostCode] END AS [LocationPostCode]
      ,CASE WHEN UseFbLocation = 0 THEN evt.[LocationCountry] ELSE evt.[FbLocationCountry] END AS [LocationCountry]

      ,CASE WHEN UseFbLatLon = 0 THEN evt.[Latitude] ELSE evt.[FbLatitude] END AS [Latitude]
      ,CASE WHEN UseFbLatLon = 0 THEN evt.[Longitude] ELSE evt.[FbLongitude] END AS [Longitude]
	  ,CASE WHEN UseFbLatLon = 0 THEN evt.[EventGeolocation] ELSE evt.[FbEventGeoLocation] END AS [EventGeolocation]

      ,evt.[MinimumParticipantsRequired]
      ,evt.[MaximumParticipantsAllowed]
      ,evt.[Organizer_HasherId]
      ,evt.[CanEditRunAttendence]
      ,evt.[Hares]

      ,evt.[UpdateDataFromFacebook]
      ,evt.[EventFacebookId]
      ,evt.[FacebookRecordLastUpdated]

      ,evt.[removed]
      ,evt.[deleted]
      ,evt.[lastModified]
      ,evt.[version]
      ,evt.[createdAt]
      ,evt.[updatedAt]
  FROM [HC].[Event] evt
  INNER JOIN HC.Kennel k on evt.KennelId = k.id
  INNER JOIN HC.Country co on co.id = k.CountryId
' 
GO
/****** Object:  View [dbo].[vw_deleteFilthRuns]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteFilthRuns]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteFilthRuns] AS
select * from HC.event  where KennelId = ''5029DE3A-D231-47AA-BE72-ECE9BCCD55D1''' 
GO
/****** Object:  View [dbo].[vw_deleteAddHashers]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteAddHashers]'))
EXEC dbo.sp_executesql @statement = N'

CREATE view [dbo].[vw_deleteAddHashers] as
select FirstName,LastName,HashName,Email from HC.Hasher 
' 
GO
/****** Object:  Table [HC].[Region]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[Region]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[Region](
	[id] [uniqueidentifier] NOT NULL,
	[RegionName] [nvarchar](100) NOT NULL,
	[CountryId] [uniqueidentifier] NOT NULL,
	[FlagFile] [nvarchar](100) NULL,
	[Removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Region] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[City]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[City]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[City](
	[id] [uniqueidentifier] NOT NULL,
	[CityName] [nvarchar](100) NOT NULL,
	[CityCountryName] [nvarchar](250) NULL,
	[CityFullName] [nvarchar](350) NULL,
	[ShowRegion] [smallint] NULL,
	[RegionId] [uniqueidentifier] NOT NULL,
	[Latitude] [numeric](12, 9) NOT NULL,
	[Longitude] [numeric](13, 9) NOT NULL,
	[City_ASCII] [nvarchar](100) NULL,
	[CityGeolocation] [geography] NOT NULL,
	[FlagFile] [nvarchar](100) NULL,
	[TimezoneId] [int] NULL,
	[Removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_City2] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  View [HC3W].[vwAdKennelList]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3W].[vwAdKennelList]'))
EXEC dbo.sp_executesql @statement = N'





CREATE VIEW [HC3W].[vwAdKennelList] AS

SELECT 
	h.HcWebUserId,

	k.[id]
	  -- Basic Kennel info
      --,[KennelStatus]
      ,[KennelName]
      ,[KennelShortName]
      --,[KennelDescription]
      --,[KennelLogo]
	  --,[KennelPinColor]
      --,[KennelCoverPhoto]
      ,[KennelWebsiteUrl]
	  ,CASE WHEN coalesce(c.ShowRegion,co.ShowRegion,0) = 1 THEN c.CityFullName ELSE c.CityCountryName END AS CityName

	  ---- Hash Cash info
   --   ,[DefaultEventPriceForMembers]
   --   ,[DefaultEventPriceForNonMembers]
   --   ,[DefaultEventCurrencyType]
   --   ,[CurrencyCode]
   --   ,[PrimaryCultureCode]
   --   ,[CurrencySymbol]
   --   ,[DigitsAfterDecimal]
   --   ,[BankScheme]
   --   ,[BankAccountNumber]
   --   ,[BankBic]
   --   ,[BankBeneficiary]
   --   ,[KennelPaymentUrl]
   --   ,[KennelPaymentUrlExpires]
	  --,[AllowNegativeCredit]

	  ---- Location info
   --   ,[CityId]
   --   ,[ProvinceStateId]
   --   ,[CountryId]
   --   ,[Latitude]
   --   ,[Longitude]

	  --,[DefaultRunStartTime]
   --   ,[MembershipDurationInMonths]
   --   ,[RunCountStartDate]
   --   ,[ExtApiKey]

	  --,[AutoImportFacebookEvents]
   --   ,[ImportOnlyTaggedEvents]
   --   ,k.[CanEditRunAttendence]
   --   ,[FacebookTagForImport]

FROM HC.Kennel k 
INNER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = k.id
INNER JOIN HC.Hasher h ON hkm.UserId = h.id
INNER JOIN HC.City c on c.id = k.CityId
INNER JOIN HC.Region r on c.RegionId = r.id
INNER JOIN HC.Country co on r.CountryId = co.id
WHERE ((hkm.MismanagementRoleFlags & 0x0001) != 0 AND h.HcWebUserId IS NOT NULL) OR (h.HcWebUserId < 10)
' 
GO
/****** Object:  Table [HC].[HasherEventMap]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[HasherEventMap]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[HasherEventMap](
	[id] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NULL,
	[HasherOwnEventId] [uniqueidentifier] NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[RunCountId] [int] NOT NULL,
	[RegistrationId] [uniqueidentifier] NULL,
	[UserStartEvent] [datetimeoffset](7) NULL,
	[UserEndEvent] [datetimeoffset](7) NULL,
	[EventCost] [smallmoney] NULL,
	[Rsvp] [datetimeoffset](7) NULL,
	[RsvpState] [smallint] NOT NULL,
	[AttendenceState] [smallint] NOT NULL,
	[IsHare] [smallint] NOT NULL,
	[EventNotificationPreference] [smallint] NULL,
	[EventEmailAlertPreference] [smallint] NULL,
	[EventCountOverride] [smallint] NULL,
	[VirginVisitorType] [smallint] NOT NULL,
	[DisplayName] [nvarchar](120) NULL,
	[Email] [nvarchar](120) NULL,
	[PhoneNumber] [nvarchar](120) NULL,
	[removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_HcHasherEventMap] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  View [dbo].[vw_deleteImportHemRecords]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteImportHemRecords]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteImportHemRecords] as 
select top 10 EventId,UserId,UserStartEvent,Rsvp,RsvpState,AttendenceState,IsHare,VirginVisitorType from HC.HasherEventMap' 
GO
/****** Object:  View [dbo].[vw_deleteMe_facebookIds]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteMe_facebookIds]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteMe_facebookIds]
as
select top 20 * from HC.Kennel where KennelFacebookId is not null' 
GO
/****** Object:  View [dbo].[vw_deleteMe_importEvents]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteMe_importEvents]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteMe_importEvents] as
select top 1 id,EventStartDatetime,KennelId,EventName,EventDescription from HC.Event' 
GO
/****** Object:  View [HC3W].[vwAdEventList]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3W].[vwAdEventList]'))
EXEC dbo.sp_executesql @statement = N'


CREATE VIEW [HC3W].[vwAdEventList]

AS

SELECT 
	h.HcWebUserId,

	-- FB run details flag
	CASE WHEN (e.UseFbRunDetails = 1 AND e.FbEventName IS NOT NULL) THEN e.FbEventName ELSE e.EventName END AS eventName,
	CASE WHEN (e.UseFbRunDetails = 1 AND e.FbEventStartDatetime IS NOT NULL) THEN convert(datetime,e.FbEventStartDatetime) ELSE convert(datetime,e.EventStartDatetime) END AS eventStartDatetime, -- This is a bit of a hack, force conversion into local time prior to sending over the wire. TODO: Eventually send over the event UTC and a separate time offset
	-- FB location flag
	CASE WHEN (e.UseFbLocation = 1 AND e.FbLocationCity IS NOT NULL) THEN e.FbLocationCity ELSE e.LocationCity END AS locationCity,

	e.[KennelId],
	e.[id] as eventId,
	CASE WHEN (e.IsCountedRun = 1 AND e.IsVisible = 1) THEN cast(e.[EventNumber] as NVARCHAR(10)) ELSE '''' end as EventNumberStr,
	e.[DoTrackHashCash],
	e.[IsCountedRun],
	e.[IsVisible],
	e.[UpdateDataFromFacebook],
	DATEDIFF(month,CASE WHEN (e.UseFbRunDetails = 1 AND e.FbEventStartDatetime IS NOT NULL) THEN convert(datetime,e.FbEventStartDatetime) ELSE convert(datetime,e.EventStartDatetime) END,getdate()) as MonthsSinceRun,
	FORMAT(CASE WHEN (e.UseFbRunDetails = 1 AND e.FbEventStartDatetime IS NOT NULL) THEN convert(datetime,e.FbEventStartDatetime) ELSE convert(datetime,e.EventStartDatetime) END,''ddd, dd MMM yyyy'') as EventStartDateTimeString,
	e.[Hares],
	(SELECT COUNT(*) FROM HC.HasherEventMap hem WHERE hem.EventId = e.id AND hem.RsvpState >= 3) as RsvpedForRun,
	(SELECT COUNT(*) FROM HC.HasherEventMap hem WHERE hem.EventId = e.id AND hem.AttendenceState >= 20) as AttendedRun

	,cast([EventStartDatetime] as datetime) as EventStartDateTimeForInsert
	,[AbsoluteEventNumber] as AbsoluteEventNumberForInsert
	,[EventName] as EventNameForInsert
	,[EventDescription] as EventDescriptionForInsert
	,[LocationOneLineDesc] as LocationOneLineDescriptionForInsert
	,[LocationCity] as LocationCityForInsert
	,[LocationStreet] as LocationStreetForInsert
	,[LocationPostCode] as LocationPostCodeForInsert
	,[LocationRegion] as LocationRegionForInsert
	,[LocationSubRegion] as LocationSubRegionForInsert
	,[LocationCountry] as LocationCountryForInsert
	,[Latitude] as LatitudeForInsert
	,[Longitude] as LongitudeForInsert

FROM HC.Event e
INNER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = e.KennelId
INNER JOIN HC.Hasher h ON hkm.UserId = h.id
WHERE ((hkm.MismanagementRoleFlags & 0x0001) != 0 AND h.HcWebUserId IS NOT NULL) OR (h.HcWebUserId < 10)
' 
GO
/****** Object:  Table [HC].[Payment]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[Payment]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[Payment](
	[id] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NULL,
	[HasherEventMapId] [uniqueidentifier] NULL,
	[EventId] [uniqueidentifier] NULL,
	[PaymentProcessedBy_userId] [uniqueidentifier] NOT NULL,
	[CreditAmount] [smallmoney] NOT NULL,
	[DebitAmount] [smallmoney] NOT NULL,
	[Surcharge] [smallmoney] NOT NULL,
	[PaymentProvider] [nvarchar](50) NULL,
	[PaidDate] [datetimeoffset](7) NOT NULL,
	[PaymentType] [smallint] NOT NULL,
	[ProductType] [smallint] NOT NULL,
	[CreditAvailable] [smallmoney] NOT NULL,
	[CancelledDate] [datetimeoffset](7) NULL,
	[CancelledBy_UserId] [uniqueidentifier] NULL,
	[ConfirmedDate] [datetimeoffset](7) NULL,
	[ConfirmedBy_UserId] [uniqueidentifier] NULL,
	[PaymentReference] [nvarchar](50) NULL,
	[DoPayForExtras] [smallint] NOT NULL,
	[Notes] [nvarchar](500) NULL,
	[removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Payment] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[RunCounts]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[RunCounts]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[RunCounts](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[TotalPackRunsThisKennel] [int] NOT NULL,
	[TotalHaringThisKennel] [int] NOT NULL,
	[TotalPackRunsAllKennels] [int] NOT NULL,
	[TotalHaringAllKennels] [int] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_RunCounts] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  View [HC3W].[vwAdRunAttendence]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3W].[vwAdRunAttendence]'))
EXEC dbo.sp_executesql @statement = N'





CREATE VIEW [HC3W].[vwAdRunAttendence] AS 

SELECT 
	h.HcWebUserId,
	hem.id as hemId,
	e.[KennelId],
	e.[id] as eventId,
	e.IsCountedRun,
	CASE WHEN (e.IsCountedRun = 1 AND e.IsVisible = 1) THEN cast(e.[EventNumber] as NVARCHAR(10)) ELSE '''' end as EventNumberStr,
	hem.UserId,
	CAST (e.[EventStartDatetime] as DateTime) as EventStartDateTime,
	DATEDIFF(month,e.EventStartDatetime,getdate()) as MonthsSinceRun,
	CASE WHEN hem.VirginVisitorType = 0 then h2.DisplayName ELSE hem.DisplayName END as DisplayName,
	hem.IsHare,
	CASE WHEN (e.IsCountedRun = 1 AND e.IsVisible = 1) THEN CAST(rc.TotalPackRunsThisKennel + rc.TotalHaringThisKennel as nvarchar(10)) ELSE '''' END as TotalPackRunsThisKennel,
	CASE WHEN (e.IsCountedRun = 1 AND e.IsVisible = 1) THEN CAST(rc.TotalPackRunsAllKennels + rc.TotalHaringAllKennels as nvarchar(10)) ELSE '''' END as TotalPackRunsAllKennels,
	CASE WHEN (e.IsCountedRun = 1 AND e.IsVisible = 1) THEN CAST(rc.TotalHaringThisKennel as nvarchar(10)) ELSE '''' END as TotalHaringThisKennel,
	CASE WHEN (e.IsCountedRun = 1 AND e.IsVisible = 1) THEN CAST(rc.TotalHaringAllKennels as nvarchar(10)) ELSE '''' END as TotalHaringAllKennels,
	hem.VirginVisitorType,
	CASE 
		WHEN hem.VirginVisitorType = 0 THEN ''Local''
		WHEN hem.VirginVisitorType = 1 THEN ''Virgin''
		WHEN hem.VirginVisitorType = 2 THEN ''Visitor''
		ELSE ''Unknown''
	END as VirginVisitorTypeStr,
	hem.Email,
	hem.PhoneNumber,
	CASE WHEN e.DoTrackHashCash = 0 THEN ''-'' ELSE COALESCE(CASE 
		WHEN pay.PaymentType IS NULL THEN ''None*''
		WHEN pay.PaymentType = 1 THEN ''None''
		WHEN pay.PaymentType = 2 THEN ''Free''
		WHEN pay.PaymentType = 3 THEN ''Cash''
		WHEN pay.PaymentType = 4 THEN ''Bank''
		WHEN pay.PaymentType = 5 THEN ''Cash +''
		WHEN pay.PaymentType = 6 THEN ''Credit''
		WHEN pay.PaymentType = 7 THEN ''Bank +''
	ELSE ''Unknown'' END,''Unknown'') END as PaymentStr,
	COALESCE(pay.PaymentType,0) as PaymentType,
	CASE WHEN e.DoTrackHashCash = 0 THEN ''-'' ELSE COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(CASE WHEN COALESCE(hkm2.MembershipExpirationDate,''1/1/2000'') < e.EventStartDateTime THEN COALESCE(pay.DebitAmount,e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers) ELSE COALESCE(pay.DebitAmount,e.EventPriceForMembers,k.DefaultEventPriceForMembers) END ,20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') END as Owed,
	CASE WHEN e.DoTrackHashCash = 0 THEN ''-'' ELSE COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(pay.CreditAmount,20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') END as Paid,
	CASE WHEN e.DoTrackHashCash = 0 THEN ''-'' ELSE COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(pay.CreditAvailable,20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') END as CreditAvailable
	
FROM HC.Event e
-- NOTE: These inner joins are all about determining the kennels accessible by the one making the query and not the hashers being returned from the query
INNER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = e.KennelId
INNER JOIN HC.Hasher h ON hkm.UserId = h.id
INNER JOIN HC.HasherEventMap hem on hem.EventId = e.id
INNER JOIN HC.Kennel k on e.KennelId = k.id
INNER JOIN HC.Country co on co.id = k.CountryId
-- NOTE: The joins are related to the actual rows being returned. Be careful, for example, to not use hkm when you really need hkm2!
LEFT OUTER JOIN HC.Hasher h2 on h2.id = hem.UserId
LEFT OUTER JOIN HC.HasherKennelMap hkm2 on hkm2.KennelId = k.id AND hkm2.UserId = hem.UserId
LEFT OUTER JOIN HC.RunCounts rc on rc.id = hem.RunCountId
LEFT OUTER JOIN HC.Payment pay on pay.HasherEventMapId = hem.id AND pay.CancelledBy_UserId IS NULL
WHERE (((hkm.MismanagementRoleFlags & 0x0001) != 0 AND h.HcWebUserId IS NOT NULL) OR (h.HcWebUserId < 10))
AND hem.VirginVisitorType <= 2
AND h.HcWebUserId IS NOT NULL
AND hem.AttendenceState >= 20
AND e.IsVisible = 1
' 
GO
/****** Object:  View [dbo].[vw_deleteDnhRuns]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteDnhRuns]'))
EXEC dbo.sp_executesql @statement = N'CREATE View [dbo].[vw_deleteDnhRuns] 
AS

select * from HC.Event where EventName like ''%DNH-19%''' 
GO
/****** Object:  View [HC3W].[vwAdHasherList]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3W].[vwAdHasherList]'))
EXEC dbo.sp_executesql @statement = N'














/****** Object:  View [HC3W].[vwSaHasher]    Script Date: 12/11/19 2:29:26 PM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

CREATE VIEW [HC3W].[vwAdHasherList] AS

SELECT 
	   h.HcWebUserId
	  ,hkm2.id
      ,hkm2.UserId
      ,hkm2.KennelId
	  ,k2.KennelShortName
	  ,h2.DisplayName
	  ,h2.FirstName
	  ,h2.LastName
	  ,h2.HashName
	  ,case when (h.HcWebUserId < 10) then h2.Email else SUBSTRING(h2.Email,1,1) + replicate(''*'',charindex(''@'',h2.Email,1)-2) + ''@'' + SUBSTRING(SUBSTRING(h2.Email,charindex(''@'',h2.Email,1)+1,1000) ,1,1) + replicate(''*'',charindex(''.'',SUBSTRING(h2.Email,charindex(''@'',h2.Email,1)+2,1000) ,1)-1) + SUBSTRING(SUBSTRING(h2.Email,charindex(''@'',h2.Email,1)+1,1000),CHARINDEX(''.'',SUBSTRING(h2.Email,charindex(''@'',h2.Email,1)+1,1000),1),1000) end as Email
      ,hkm2.Following
	  ,hkm2.IsKennelFollowing
	  ,hkm2.MismanagementRoles
      ,hkm2.MismanagementRoleFlags
	  ,hkm2.HcWebPermissionFlags
      ,hkm2.UserRoleFlags
      ,hkm2.AppAccessFlags
	  ,hkm2.MembershipExpirationDate
	  ,hkm2.KennelEmailAlertPreference
	  ,CASE WHEN hkm2.MembershipExpirationDate > GETDATE() THEN 1 ELSE 0 END AS isMember
      ,hkm2.removed
      ,hkm2.updatedAt
	  ,CASE WHEN ((hkm.HcWebPermissionFlags & 0x0003 = 0x0003) OR (h.HcWebUserId < 10)) THEN 1 ELSE 0 END AS CanAssignAsAdmin
	  ,h2.HomeKennelId
	  ,CASE WHEN h2.HomeKennelId = hkm2.KennelId THEN 1 ELSE 0 END as IsHomeKennel
  FROM [HC].[HasherKennelMap] hkm
  INNER JOIN HC.Hasher h on hkm.UserId = h.id,
  HC.HasherKennelMap hkm2
  INNER JOIN HC.Hasher h2 on h2.id = hkm2.UserId
  INNER JOIN HC.Kennel k2 on k2.id = hkm2.KennelId
  WHERE (((hkm.HcWebPermissionFlags & 0x0001) = 0x0001 AND h.HcWebUserId IS NOT NULL) OR (h.HcWebUserId < 10))
  AND hkm2.KennelId = hkm.KennelId AND hkm2.Following = 1 --AND h2.Removed = 0
  --order by k2.KennelShortName, h2.DisplayName, h.HcWebUserId
' 
GO
/****** Object:  View [HC3W].[vwAdEvent]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3W].[vwAdEvent]'))
EXEC dbo.sp_executesql @statement = N'


CREATE VIEW [HC3W].[vwAdEvent]

AS

SELECT [id]
      ,cast([EventStartDatetime] as datetime) as EventStartDatetime
      ,cast([EventEndDatetime] as datetime) as EventEndDatetime
      ,[KennelId]
      ,[IsVisible]
      ,[IsCountedRun]
      ,[IsPromotedEvent]
      ,[EventGeographicScope]
      ,[ThemeRunType]
	  ,[Tags1]
	  ,[Tags2]
	  ,[Tags3]
      ,[AbsoluteEventNumber]
      ,[EventNumber]
      ,[EventNumberIncrement]
	  ,[DoTrackHashCash]
      ,[EventPriceForMembers]
      ,[EventPriceForNonMembers]
	  ,[EventPriceForExtras]
	  ,[ExtrasDescription]
      ,[EventCurrencyType]
      ,[BankScheme]
      ,[BankAccountNumber]
      ,[BankBic]
      ,[BankBeneficiary]
	  ,[EventPaymentScheme]
      ,[EventPaymentUrl]
      ,[EventPaymentUrlExpires]
      ,[UnconfirmedBankXferCount]
      ,[UserEventCounterIncrement]
      ,[EventName]
      ,[EventDescription]
      ,[EventImage]
      ,[EventImageOffsetX]
      ,[EventImageOffsetY]
      ,[LocationOneLineDesc]
      ,[LocationCity]
      ,[LocationStreet]
      ,[LocationPostCode]
	  ,[LocationSubRegion]
	  ,[LocationRegion]
      ,[LocationCountry]
      ,[Latitude]
      ,[Longitude]
      ,[EventGeolocation]
      ,[MinimumParticipantsRequired]
      ,[MaximumParticipantsAllowed]
      ,[Organizer_HasherId]
      ,[CanEditRunAttendence]
      ,[Hares]
      ,[UseFbRunDetails]
      ,[UseFbLocation]
      ,[UseFbLatLon]
      ,[UpdateDataFromFacebook]
      ,[EventFacebookId]
      ,[FacebookRecordLastUpdated]
      ,[FbEventName]
      ,[FbEventDescription]
      ,[FbEventStartDatetime]
      ,[FbEventImage]
      ,[FbEventImageOffsetX]
      ,[FbEventImageOffsetY]
      ,[FbLocationOneLineDesc]
      ,[FbLocationCity]
      ,[FbLocationStreet]
      ,[FbLocationPostCode]
	  ,[FbLocationSubRegion]
	  ,[FbLocationRegion]
      ,[FbLocationCountry]
      ,[FbLatitude]
      ,[FbLongitude]
      ,[removed]
      ,[deleted]
      ,[lastModified]
      ,[version]
      ,[createdAt]
      ,[updatedAt]
  FROM [HC].[Event]
' 
GO
/****** Object:  View [dbo].[vw_deleteTheWhites]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteTheWhites]'))
EXEC dbo.sp_executesql @statement = N'CREATE VIEW [dbo].[vw_deleteTheWhites] AS
select * from HC.Hasher where LastName = ''White''' 
GO
/****** Object:  Table [DomainValues].[MisManagementRoles]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DomainValues].[MisManagementRoles]') AND type in (N'U'))
BEGIN
CREATE TABLE [DomainValues].[MisManagementRoles](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[RoleName] [nvarchar](50) NOT NULL,
	[RoleShortName] [nvarchar](50) NOT NULL,
	[BitFlags] [int] NOT NULL,
	[BitMask] [nchar](10) NOT NULL,
	[PropertyName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_MisManagementRoles] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  View [HC3].[vwMmByKennel]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3].[vwMmByKennel]'))
EXEC dbo.sp_executesql @statement = N'

CREATE VIEW [HC3].[vwMmByKennel]

AS

SELECT 
hkm.KennelId as KennelId,STRING_AGG(mr.RoleName + CHAR(9) +REPLACE(h.DisplayName,''"'',''\"'') ,CHAR(13)) WITHIN GROUP (ORDER BY mr.id) as MmRoles
FROM HC.HasherKennelMap hkm
INNER JOIN HC.Hasher h on hkm.UserId = h.id,
DomainValues.MismanagementRoles mr 
WHERE (hkm.MismanagementRoles & mr.BitFlags) != 0 AND mr.id != 1
GROUP BY hkm.KennelId

' 
GO
/****** Object:  Table [HC].[Receipt]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[Receipt]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[Receipt](
	[id] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[ReceiptAmount] [decimal](12, 4) NOT NULL,
	[CostCategory] [smallint] NOT NULL,
	[DateUploaded] [datetimeoffset](7) NOT NULL,
	[ImageUrl] [nvarchar](500) NULL,
	[ReceiptShortDesc] [nvarchar](255) NULL,
	[Notes] [nvarchar](1000) NULL,
	[ReimbursedBy] [uniqueidentifier] NULL,
	[ReimbursedOn] [datetimeoffset](7) NULL,
	[ReimbursedAmount] [decimal](12, 4) NULL,
	[ReimbursedNotes] [nvarchar](1000) NULL,
	[removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Receipt] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  View [HC3W].[vwAdProfitLossReport]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3W].[vwAdProfitLossReport]'))
EXEC dbo.sp_executesql @statement = N'
CREATE VIEW [HC3W].[vwAdProfitLossReport] AS

select 
	h.HcWebUserId,
	e.id, 
	e.EventName,
	e.EventStartDatetime,
	CASE WHEN (e.IsCountedRun = 1 AND e.IsVisible = 1) THEN cast(e.[EventNumber] as NVARCHAR(10)) ELSE '''' end as EventNumberStr,
	k.id as KennelId,
	DATEDIFF(month,e.EventStartDatetime,getdate()) as MonthsSinceRun,

	COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(coalesce(pay.credit,0),20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') as collected,
	COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(coalesce(pay.debit,0),20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') as owed,
	COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(coalesce(receipt.receipts,0),20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') as receipts,
	COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(coalesce(receipt.reimbursements,0),20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') as reimbursements,
	COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(coalesce(debit-receipts,0),20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') as profitLoss,
	COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(coalesce(debit-reimbursements,0),20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') as actualProfitLoss,
	COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(coalesce(owed,0),20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') as notPaid,
	COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(coalesce(excessPayment,0),20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') as excessPayment,
	COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(coalesce(cashOnHand,0),20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') as cashOnHand,
	COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(coalesce(bankTransfers,0),20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') as bankTransfers

	from HC.Event e
	INNER JOIN HC.Kennel k on k.id = e.KennelId
	INNER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = e.KennelId
	INNER JOIN HC.Hasher h ON hkm.UserId = h.id
	INNER JOIN HC.Country co on co.id = k.CountryId
	OUTER APPLY(SELECT
		 SUM(p.CreditAmount),
		 SUM(p.DebitAmount),
		 SUM(CASE WHEN p.DebitAmount > p.CreditAmount THEN p.DebitAmount - p.CreditAmount ELSE 0 END),
		 SUM(CASE WHEN p.DebitAmount < p.CreditAmount THEN p.CreditAmount - p.DebitAmount ELSE 0 END),
		 SUM(CASE WHEN p.PaymentType = 3 OR p.PaymentType = 5 THEN p.CreditAmount ELSE 0 END),
		 SUM(CASE WHEN p.PaymentType = 4 OR p.PaymentType = 7 THEN p.CreditAmount ELSE 0 END)
		 FROM HC.Payment p WHERE p.EventId = e.id AND p.CancelledBy_UserId IS NULL) as pay(credit, debit, owed, excessPayment,cashOnHand,bankTransfers)
	OUTER APPLY(SELECT SUM(r.ReceiptAmount) as receiptTotal,SUM(r.ReimbursedAmount) as reimbursed FROM HC.Receipt r where r.EventId = e.id) as receipt(receipts, reimbursements)
	WHERE (((hkm.MismanagementRoleFlags & 0x0101) = 0x0101 AND h.HcWebUserId IS NOT NULL) OR (h.HcWebUserId < 10))
	AND e.IsVisible = 1
	AND e.DoTrackHashCash = 1


' 
GO
/****** Object:  View [dbo].[vw_deleteEditFacebookKennels]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteEditFacebookKennels]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteEditFacebookKennels] as 
select * from HC.Kennel where KennelFacebookId is not null' 
GO
/****** Object:  View [HC3W].[vwAdHashCashReport]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3W].[vwAdHashCashReport]'))
EXEC dbo.sp_executesql @statement = N'
CREATE VIEW [HC3W].[vwAdHashCashReport] AS 

SELECT 
	hem.id as id,
	pay.id as payId,
	h.HcWebUserId,
	e.[KennelId],
	e.[id] as eventId,
	e.IsCountedRun,
	CASE WHEN (e.IsCountedRun = 1 AND e.IsVisible = 1) THEN cast(e.[EventNumber] as NVARCHAR(10)) ELSE '''' end as EventNumberStr,
	hem.UserId,
	CAST (e.[EventStartDatetime] as DateTime) as EventStartDatetime,
	DATEDIFF(month,e.EventStartDatetime,getdate()) as MonthsSinceRun,
	CASE WHEN hem.VirginVisitorType = 0 then h2.DisplayName ELSE hem.DisplayName END as DisplayName,
	hem.IsHare,
	hem.VirginVisitorType,
	CASE 
		WHEN hem.VirginVisitorType = 0 THEN ''Local''
		WHEN hem.VirginVisitorType = 1 THEN ''Virgin''
		WHEN hem.VirginVisitorType = 2 THEN ''Visitor''
		ELSE ''Unknown''
	END as VirginVisitorTypeStr,
	COALESCE(CASE 
		WHEN pay.PaymentType IS NULL THEN ''None*''
		WHEN pay.PaymentType = 1 THEN ''None''
		WHEN pay.PaymentType = 2 THEN ''Free''
		WHEN pay.PaymentType = 3 THEN ''Cash''
		WHEN pay.PaymentType = 4 THEN ''Bank''
		WHEN pay.PaymentType = 5 THEN ''Cash +''
		WHEN pay.PaymentType = 6 THEN ''Credit''
		WHEN pay.PaymentType = 7 THEN ''Bank +''
	ELSE ''Unknown'' END,''Unknown'') as PaymentStr,
	COALESCE(pay.PaymentType,0) as PaymentType,
	COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(CASE WHEN COALESCE(hkm2.MembershipExpirationDate,''1/1/2000'') < e.EventStartDateTime THEN COALESCE(pay.DebitAmount,e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers) ELSE COALESCE(pay.DebitAmount,e.EventPriceForMembers,k.DefaultEventPriceForMembers) END ,20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') as Owed,
	COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(pay.CreditAmount,20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') as Paid,
	COALESCE(REPLACE(coalesce(k.CurrencySymbol,co.CurrencySymbol,''$^''),''^'',TRIM(STR(pay.CreditAvailable,20,coalesce(k.DigitsAfterDecimal,co.DigitsAfterDecimal,2))) ),'''') as CreditAvailable,
	CAST (pay.PaidDate as DateTime) as PaidDate,
	coalesce(h3.DisplayName,'''') as PaidTo,
	coalesce(pay.PaymentReference,''<none>'') as paymentReference,
	pay.ProductType,
	coalesce(h4.DisplayName,'''') as ConfirmedBy,
	CAST (pay.ConfirmedDate as DateTime) as ConfirmedDate
FROM HC.Event e
-- NOTE: These inner joins are all about determining the kennels accessible by the one making the query and not the hashers being returned from the query
INNER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = e.KennelId
INNER JOIN HC.Hasher h ON hkm.UserId = h.id
INNER JOIN HC.HasherEventMap hem on hem.EventId = e.id
INNER JOIN HC.Kennel k on e.KennelId = k.id
INNER JOIN HC.Country co on co.id = k.CountryId
-- NOTE: The joins are related to the actual rows being returned. Be careful, for example, to not use hkm when you really need hkm2!
LEFT OUTER JOIN HC.Hasher h2 on h2.id = hem.UserId
LEFT OUTER JOIN HC.HasherKennelMap hkm2 on hkm2.KennelId = k.id AND hkm2.UserId = hem.UserId
LEFT OUTER JOIN HC.RunCounts rc on rc.id = hem.RunCountId
LEFT OUTER JOIN HC.Payment pay on pay.HasherEventMapId = hem.id AND pay.CancelledBy_UserId IS NULL
LEFT OUTER JOIN HC.Hasher h3 on pay.PaymentProcessedBy_userId = h3.id
LEFT OUTER JOIN HC.Hasher h4 on pay.ConfirmedBy_UserId = h4.id
WHERE (((hkm.MismanagementRoleFlags & 0x0021) = 0x0021 AND h.HcWebUserId IS NOT NULL) OR (h.HcWebUserId < 10))
AND hem.VirginVisitorType <= 3
AND hem.AttendenceState >= 20
AND e.IsVisible = 1
AND e.DoTrackHashCash = 1
' 
GO
/****** Object:  View [HC3W].[vwAdHasher]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3W].[vwAdHasher]'))
EXEC dbo.sp_executesql @statement = N'








/****** Object:  View [HC3W].[vwSaHasher]    Script Date: 12/11/19 2:29:26 PM ******/
--SET ANSI_NULLS ON
--GO

--SET QUOTED_IDENTIFIER ON
--GO

CREATE VIEW [HC3W].[vwAdHasher] AS

SELECT 
	   -- WebUserId for user making changes
	   h.HcWebUserId
	   
	   -- Hasher information to update
      ,h2.[HomeKennelId] as homeKennelId
      ,h2.[MotherKennelId] as motherKennelId
      ,h2.[SupportCode] as supportCode
      ,REPLACE(h2.[ResetCode],''URC:'','''') as inviteCode
      ,REPLACE(h2.[QR_code],''UQR:'','''') as qrCode
      ,h2.[QR_secret_code] as qrSecretCode
      ,h2.[DisplayName] as displayName
      ,h2.[HashName] as hashName
      ,h2.[FirstName] as firstName
      ,h2.[LastName] as lastName
      ,case when (h.HcWebUserId < 10) then h2.Email else SUBSTRING(h2.Email,1,1) + replicate(''*'',charindex(''@'',h2.Email,1)-2) + ''@'' + SUBSTRING(SUBSTRING(h2.Email,charindex(''@'',h2.Email,1)+1,1000) ,1,1) + replicate(''*'',charindex(''.'',SUBSTRING(h2.Email,charindex(''@'',h2.Email,1)+2,1000) ,1)-1) + SUBSTRING(SUBSTRING(h2.Email,charindex(''@'',h2.Email,1)+1,1000),CHARINDEX(''.'',SUBSTRING(h2.Email,charindex(''@'',h2.Email,1)+1,1000),1),1000) end as Email
      ,h2.[Photo] as photo
      ,h2.[Gender] as gender
      ,h2.[FacebookId] as facebookId
      ,h2.[Locale] as locale
      ,h2.[Description] as description
	  ,h2.[Preferences] as preferences
	  ,(h2.[Preferences] & 0x00000003) as distancePreference
      ,h2.[HomeLatitude] as homeLatitude
      ,h2.[HomeLongitude] as homeLongitude
      ,h2.[HomeGeolocation] as homeGeolocation
      ,h2.[NameDisplayPreference] as nameDisplayPreference
	  ,CASE WHEN h2.HomeKennelId = hkm2.KennelId THEN 1 ELSE 0 END as isHomeKennel

	  -- HKM information to update
	  ,hkm2.[id] as hkmId
      ,hkm2.[UserId] as userId
      ,hkm2.[KennelId] as kennelId
      ,hkm2.[Following] as following
      --,hkm2.[IsMember] as isMember   -- deprecated as a stored value, now calculated from membership date
      ,hkm2.[IsKennelFollowing] as isKennelFollowing
      --,hkm2.[IsHomeKennel] -- deprecated as stored value, now pulled from HC.Hasher 
      ,hkm2.[KennelNotificationPreference] as kennelNotificationPreference
      ,hkm2.[KennelEmailAlertPreference] as kennelEmailPreference
	  ,hkm2.[MismanagementRoles] as mismanagementRoles
      ,hkm2.[MismanagementRoleFlags] as mismanagementRoleFlags
      ,hkm2.[HcWebPermissionFlags] as hcWebPermissionFlags
      ,hkm2.[UserRoleFlags] as userRoleFlags
      ,hkm2.[AppAccessFlags] as appAccessFlags
      ,hkm2.[HistoricalPackRunCount] as historicalPackRunCount
      ,hkm2.[HistoricalHaringCount] as historicalHaringCount
      ,hkm2.[HistoricalCountIsEstimate] as historicalCountIsEstimate
      ,hkm2.[CurrentPackRunCount] as currentPackRunCount
      ,hkm2.[CurrentHaringCount] as currentHaringCount
      ,CAST(hkm2.[DateOfLastRun] as datetime) as dateOfLastRun
      ,CAST(hkm2.[MembershipExpirationDate] as datetime) as membershipExpirationDate
      ,CAST(hkm2.[MemberSince] as datetime) as memberSince
      ,hkm2.[CanEditRunAttendence] as canEditRunAttendence

	  -- Composite fields, not updatable
	  ,CASE WHEN hkm2.MembershipExpirationDate > GETDATE() THEN 1 ELSE 0 END AS isMember
	  ,CASE WHEN ((hkm.HcWebPermissionFlags & 0x0003 = 0x0003) OR (h.HcWebUserId < 10)) THEN 1 ELSE 0 END AS canAssignAsAdmin
	  
	  -- do the join here to make it easier in the WebApp
	  ,k2.KennelName as kennelName

  FROM [HC].[HasherKennelMap] hkm
  INNER JOIN HC.Hasher h on hkm.UserId = h.id,
  HC.HasherKennelMap hkm2
  INNER JOIN HC.Hasher h2 on h2.id = hkm2.UserId
  INNER JOIN HC.Kennel k2 on k2.id = hkm2.KennelId
  WHERE (((hkm.HcWebPermissionFlags & 0x0001) = 0x0001 AND h.HcWebUserId IS NOT NULL) OR (h.HcWebUserId < 10))
  AND hkm2.KennelId = hkm.KennelId AND hkm2.Following = 1
  --order by k2.KennelShortName, h2.DisplayName, h.HcWebUserId
' 
GO
/****** Object:  View [dbo].[vw_dev_kennelMembership]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_dev_kennelMembership]'))
EXEC dbo.sp_executesql @statement = N'
CREATE view [dbo].[vw_dev_kennelMembership]

as

select top 999999 h.HashName,
k.KennelName,
hkm.MismanagementRoleFlags,
hkm.MembershipExpirationDate,
hkm.id as hkmId,
k.id as kId, 
h.id as hId
from HC.HasherKennelMap hkm
inner join HC.Hasher h on hkm.UserId = h.id
inner join HC.Kennel k on hkm.KennelId = k.id
order by h.HashName,k.KennelName
' 
GO
/****** Object:  View [HC].[deleteTempCities]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC].[deleteTempCities]'))
EXEC dbo.sp_executesql @statement = N'create view 

[HC].[deleteTempCities]

AS 

select * from HC.City where Latitude between 52 and 53 and Longitude  between 4 and  5' 
GO
/****** Object:  View [dbo].[vw_deleteEditFILTHhash]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteEditFILTHhash]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteEditFILTHhash] as select * from HC.Kennel where KennelName like ''%FILTH%''' 
GO
/****** Object:  View [dbo].[vw_deleteEditNetherlands]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteEditNetherlands]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteEditNetherlands] as select * from HC.Country h where h.CountryName like ''%nether%''' 
GO
/****** Object:  View [dbo].[vw_deleteEditPayments]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteEditPayments]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteEditPayments] as select * from HC.Payment' 
GO
/****** Object:  View [dbo].[vw_insertHashers]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_insertHashers]'))
EXEC dbo.sp_executesql @statement = N'
CREATE VIEW [dbo].[vw_insertHashers] AS 
SELECT 
      [DisplayName]
      ,[HashName]
      ,[FirstName]
      ,[LastName]
      ,[Email]
  FROM [HC].[Hasher]
' 
GO
/****** Object:  View [dbo].[vw_insertHkmRecords]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_insertHkmRecords]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_insertHkmRecords] as 
select userId, kennelId from HC.HasherKennelMap' 
GO
/****** Object:  View [HC3W].[vwSaHasherPermissions]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3W].[vwSaHasherPermissions]'))
EXEC dbo.sp_executesql @statement = N'




CREATE VIEW [HC3W].[vwSaHasherPermissions]

AS

SELECT 
	h.id as UserId, 
	hkm.id as HkmId,
	k.id as KennelId, 
	k.KennelShortName, 
	k.KennelName,
	hkm.UserRoleFlags, 
	hkm.AppAccessFlags, 
	hkm.MismanagementRoleFlags,
	hkm.HcWebPermissionFlags
FROM HC.Hasher h
inner join HC.HasherKennelMap hkm on h.id = hkm.userId
inner join HC.Kennel k on hkm.KennelId = k.id
WHERE ((hkm.Following = 1) OR (h.HcWebUserId < 10))


' 
GO
/****** Object:  View [dbo].[vw_deleteOpeeRuns]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteOpeeRuns]'))
EXEC dbo.sp_executesql @statement = N'create view
[dbo].[vw_deleteOpeeRuns] as 
select * from HC.HasherEventMap where userId = ''0CDBB109-215E-4B5F-A405-F6C9FBCB18EC''' 
GO
/****** Object:  View [dbo].[vw_deleteSlippery]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteSlippery]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteSlippery] AS
select * from HC.Hasher h where h.DisplayName like ''%Slippery Edg%''' 
GO
/****** Object:  View [dbo].[vw_deleteSlippery2]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteSlippery2]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteSlippery2] AS
select hkm.* from HC.Hasher h 
INNER JOIN HC.HasherKennelMap hkm on hkm.UserId = h.id
where h.DisplayName like ''%Slippery Edg%''' 
GO
/****** Object:  View [HC].[vwEventCommonFields]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC].[vwEventCommonFields]'))
EXEC dbo.sp_executesql @statement = N'












CREATE VIEW [HC].[vwEventCommonFields]

AS	
		
		SELECT
			  k.id as KennelId
			  ,e.[id] as EventId
			  ,e.[EventFacebookId]
			  ,e.[EventName]
			  ,e.[EventNumber]
			  ,case WHEN e.IsCountedRun = 1 THEN ''Run #''+cast(e.EventNumber as nvarchar(25)) ELSE ''n/a'' END as EventNumberStr
			  ,e.[EventDescription]
			  ,coalesce(e.[EventImage],k.kennelLogo) as EventImage
			  ,e.[EventStartDatetime]
			  ,e.[EventEndDatetime]
			  ,e.[lastModified]
			  ,e.[UserEventCounterIncrement]
			  ,e.[MinimumParticipantsRequired]
			  ,e.[MaximumParticipantsAllowed]
			  ,left(datename(dw,e.[EventStartDatetime]),3) as WeekDayName
			  ,right(''00'' + convert(nvarchar(2),datepart(day,e.[EventStartDatetime])),2) as DayNumber
			  ,left(datename(month,e.[EventStartDatetime]),3) + CASE WHEN format(getdate(),''yy'') <> format(e.[EventStartDatetime],''yy'') THEN '' '''''' + format(e.[EventStartDatetime],''yy'') ELSE '''' END as MonthNameShort
			  ,REPLACE(FORMAT(cast(e.[EventStartDatetime] as datetime),''h:mm tt''),'':00'','''') as EventTimeFormatted
			  ,e.LocationStreet
			  ,e.LocationPostCode
			  ,e.[LocationOneLineDesc]
			  ,coalesce(e.LocationCity,c.CityName,''<no city>'') as LocationCity
			  ,e.[Latitude] as PinLatitude
			  ,e.[Longitude] as PinLongitude
			  ,coalesce(e.EventCurrencyType,k.DefaultEventCurrencyType,''en-us'') as CurrencyType
			  ,REPLACE(FORMAT(coalesce(e.EventPriceForMembers,k.DefaultEventPriceForMembers,e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,0),''C'',coalesce(e.EventCurrencyType,k.DefaultEventCurrencyType,''en-us'')),'','',''.'') as PriceForMembers
			  ,REPLACE(FORMAT(coalesce(e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,e.EventPriceForMembers,k.DefaultEventPriceForMembers,0),''C'',coalesce(e.EventCurrencyType,k.DefaultEventCurrencyType,''en-us'')),'','',''.'') as PriceForNonMembers
			  ,coalesce(e.[Latitude],k.[Latitude],c.[Latitude]) as Latitude
			  ,coalesce(e.[Longitude],k.[Longitude],c.[Longitude]) as Longitude
			  ,(select count(hemYes.id) from HC.HasherEventMap hemYes where hemYes.EventId = e.id and hemYes.RsvpState = 3) as WillAttendCount
			  ,(select count(hemMaybe.id) from HC.HasherEventMap hemMaybe where hemMaybe.EventId = e.id and hemMaybe.RsvpState = 2) as MightAttendCount
			  ,(select count(hemNo.id) from HC.HasherEventMap hemNo where hemNo.EventId = e.id and hemNo.RsvpState = 1) as WillNotAttendCount
			  ,case when e.EventStartDatetime < dateadd(day,-1,getdate()) THEN 1 ELSE 0 END AS EventComplete
			  ,coalesce(e.[EventGeolocation],k.[KennelGeoLocation],c.[CityGeoLocation]) as PrimaryGeoLocation
			  ,e.[deleted]
		from HC.Event e 
		inner join HC.Kennel k on e.KennelId = k.id
		inner join HC.City c on c.id = k.CityId
		
' 
GO
/****** Object:  View [dbo].[vw_deleteTempKennelList]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteTempKennelList]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteTempKennelList] as select * from HC.Kennel where kennelLogo like ''http%''' 
GO
/****** Object:  Table [HC].[LaunchAndLogin]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[LaunchAndLogin]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[LaunchAndLogin](
	[id] [uniqueidentifier] NOT NULL,
	[LoginDate] [datetimeoffset](7) NOT NULL,
	[HcVersion] [nvarchar](200) NOT NULL,
	[UserName] [nvarchar](250) NULL,
	[UserId] [uniqueidentifier] NULL,
	[DeviceId] [nvarchar](100) NULL,
	[DeviceType] [nvarchar](100) NULL,
	[DeviceName] [nvarchar](100) NULL,
	[SystemName] [nvarchar](100) NULL,
	[SystemVersion] [nvarchar](100) NULL,
	[Manufacturer] [nvarchar](100) NULL,
	[Latitude] [decimal](18, 15) NULL,
	[Longitude] [decimal](19, 15) NULL,
	[CityId] [uniqueidentifier] NULL
) ON [PRIMARY]
END
GO
/****** Object:  View [HC3W].[vwAdDuplicates]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3W].[vwAdDuplicates]'))
EXEC dbo.sp_executesql @statement = N'




CREATE VIEW [HC3W].[vwAdDuplicates]
AS

-- select * from HC3W.vwAdDuplicates

select distinct

h.HcWebUserId,
a.id as aId,
a.DisplayName as aDisplayName,
a.FirstName as aFirstName,
a.LastName as aLastName,
coalesce(kA.KennelName,''<no home kennel>'') as aHomeKennel,
userA.lastRunDate as aLastRunDate,
userA.totalRuns as aTotalRuns,
userA.kennelsFollowed as aKennelsFollowed,
uA.lastAppLogin as aLastAppLogin,
uA.timesLoggedIn as aTimesLoggedIn,

b.id as bId,
b.DisplayName as bDisplayName,
b.FirstName as bFirstName,
b.LastName as bLastName,
coalesce(kB.KennelName,''<no home kennel>'') as bHomeKennel,
userB.lastRunDate as bLastRunDate,
userB.totalRuns as bTotalRuns,
userB.kennelsFollowed as bKennelsFollowed,
uB.lastAppLogin as bLastAppLogin,
uB.timesLoggedIn as bTimesLoggedIn

from HC.Hasher a inner join HC.Hasher b 
on lower(a.displayName) = lower(b.displayName)
AND lower(a.firstName) = lower(b.firstName)
AND lower(a.lastName) = lower(b.lastName)
LEFT OUTER JOIN HC.Kennel kA on kA.id = a.HomeKennelId
LEFT OUTER JOIN HC.Kennel kB on kB.id = b.HomeKennelId
OUTER APPLY (select max(hkm.DateOfLastRun),sum(coalesce(hkm.currentPackRunCount,0)) + sum(coalesce(hkm.currentHaringCount,0)) as totalRuns,count(case when hkm.Following = 1 then 1 else null end) as kennelsFollowed FROM HC.HasherKennelMap hkm where hkm.UserId = a.id) as userA(lastRunDate,totalRuns,kennelsFollowed)
OUTER APPLY (select max(hkm.DateOfLastRun),sum(coalesce(hkm.currentPackRunCount,0)) + sum(coalesce(hkm.currentHaringCount,0)) as totalRuns,count(case when hkm.Following = 1 then 1 else null end) as kennelsFollowed FROM HC.HasherKennelMap hkm where hkm.UserId = b.id) as userB(lastRunDate,totalRuns,kennelsFollowed)
OUTER APPLY (select max(ll.LoginDate),count(*) from HC.LaunchAndLogin ll where ll.UserId = a.id) uA(lastAppLogin,timesLoggedIn)
OUTER APPLY (select max(ll.LoginDate),count(*) from HC.LaunchAndLogin ll where ll.UserId = b.id) uB(lastAppLogin,timesLoggedIn)
,HC.HasherKennelMap hkm
inner join HC.Hasher h on h.id = hkm.UserId
WHERE 
((h.HcWebUserId <= 10) OR ((hkm.HcWebPermissionFlags & 1) = 1
AND (hkm.KennelId = a.HomeKennelId OR hkm.KennelId = b.HomeKennelId)))
AND h.HcWebUserId is not null
AND a.id != b.id
AND a.SupportCode > b.SupportCode
AND a.Removed = 0 AND b.Removed = 0
' 
GO
/****** Object:  View [HC3W].[vwAdEmailTemplateList]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[HC3W].[vwAdEmailTemplateList]'))
EXEC dbo.sp_executesql @statement = N'







CREATE VIEW [HC3W].[vwAdEmailTemplateList] AS

SELECT 
	h.HcWebUserId,
	em.[id]
      ,em.[KennelId]
      ,[EventId]
	  ,em.[Description]
      ,[Subject]
      ,[Template]
      ,[HoursBeforeRun]
      ,[DaysBeforeRun]
      ,[SendToAll]
      ,[SendToMembers]
      ,[SendToMismanagement]
	  ,[SendToVisitors]
	  ,[SendToFollowers]
	  ,[SenderName]
	  ,[ReplyToEmailAddress]
	  ,[SendWhenHareAssigned]
FROM HC.Kennel k 
INNER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = k.id
INNER JOIN HC.Hasher h ON hkm.UserId = h.id
INNER JOIN HC.EmailTemplate em on em.KennelId = k.id
WHERE ((hkm.HcWebPermissionFlags & 0x0001) = 0x0001 AND h.HcWebUserId IS NOT NULL) OR (h.HcWebUserId < 10)
' 
GO
/****** Object:  UserDefinedFunction [HC].[DelimitedSplit8K]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DelimitedSplit8K]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'CREATE FUNCTION [HC].[DelimitedSplit8K]
--===== Define I/O parameters
        (@pString VARCHAR(8000), @pDelimiter CHAR(1))
--WARNING!!! DO NOT USE MAX DATA-TYPES HERE!  IT WILL KILL PERFORMANCE!
RETURNS TABLE WITH SCHEMABINDING AS
 RETURN
--===== "Inline" CTE Driven "Tally Table" produces values from 1 up to 10,000...
     -- enough to cover VARCHAR(8000)
  WITH E1(N) AS (
                 SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL
                 SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL
                 SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
                ),                          --10E+1 or 10 rows
       E2(N) AS (SELECT 1 FROM E1 a, E1 b), --10E+2 or 100 rows
       E4(N) AS (SELECT 1 FROM E2 a, E2 b), --10E+4 or 10,000 rows max
 cteTally(N) AS (--==== This provides the "base" CTE and limits the number of rows right up front
                     -- for both a performance gain and prevention of accidental "overruns"
                 SELECT TOP (ISNULL(DATALENGTH(@pString),0)) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM E4
                ),
cteStart(N1) AS (--==== This returns N+1 (starting position of each "element" just once for each delimiter)
                 SELECT 1 UNION ALL
                 SELECT t.N+1 FROM cteTally t WHERE SUBSTRING(@pString,t.N,1) = @pDelimiter
                ),
cteLen(N1,L1) AS(--==== Return start and length (for use in substring)
                 SELECT s.N1,
                        ISNULL(NULLIF(CHARINDEX(@pDelimiter,@pString,s.N1),0)-s.N1,8000)
                   FROM cteStart s
                )
--===== Do the actual split. The ISNULL/NULLIF combo handles the length for the final element when no delimiter is found.
 SELECT ItemNumber = ROW_NUMBER() OVER(ORDER BY l.N1),
        Item       = SUBSTRING(@pString, l.N1, l.L1)
   FROM cteLen l
;' 
END
GO
/****** Object:  View [dbo].[vw_deleteFixCaps]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteFixCaps]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteFixCaps] as 
select id,DutchOriginal,Dutch from Wordz where ASCII(left(DutchOriginal, 1)) 
between ASCII(''A'') and ASCII(''Z'') and Dutch is not null' 
GO
/****** Object:  View [dbo].[vw_deleteFixDutchWordz]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteFixDutchWordz]'))
EXEC dbo.sp_executesql @statement = N'create view [dbo].[vw_deleteFixDutchWordz]
as
select id,Dutch,DutchOut from Wordz where Dutch like ''%,%'' and DutchOut is null' 
GO
/****** Object:  View [dbo].[vw_deleteFixWordz]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.views WHERE object_id = OBJECT_ID(N'[dbo].[vw_deleteFixWordz]'))
EXEC dbo.sp_executesql @statement = N'
CREATE view [dbo].[vw_deleteFixWordz] as 
select top 200 id, EnglishOut from Wordz where English like ''%,%''


' 
GO
/****** Object:  Table [dbo].[BusinessUnits]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[BusinessUnits]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[BusinessUnits](
	[id] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[ParentUnitId] [int] NULL,
	[deleted] [bit] NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_BusinessUnits_1] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Contacts]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Contacts]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Contacts](
	[ContactId] [int] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](30) NULL,
	[FirstName] [nvarchar](50) NOT NULL,
	[LastName] [nvarchar](50) NOT NULL,
	[Email] [nvarchar](100) NOT NULL,
	[IdentityNo] [nvarchar](20) NULL,
	[UserId] [int] NULL,
 CONSTRAINT [PK_Contacts] PRIMARY KEY CLUSTERED 
(
	[ContactId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[currency]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[currency]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[currency](
	[name] [nvarchar](100) NULL,
	[code] [nvarchar](100) NULL,
	[symbol] [nvarchar](100) NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Exceptions]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Exceptions]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Exceptions](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[GUID] [uniqueidentifier] NOT NULL,
	[ApplicationName] [nvarchar](50) NOT NULL,
	[MachineName] [nvarchar](50) NOT NULL,
	[CreationDate] [datetime] NOT NULL,
	[Type] [nvarchar](100) NOT NULL,
	[IsProtected] [bit] NOT NULL,
	[Host] [nvarchar](100) NULL,
	[Url] [nvarchar](500) NULL,
	[HTTPMethod] [nvarchar](10) NULL,
	[IPAddress] [nvarchar](40) NULL,
	[Source] [nvarchar](100) NULL,
	[Message] [nvarchar](1000) NULL,
	[Detail] [nvarchar](max) NULL,
	[StatusCode] [int] NULL,
	[SQL] [nvarchar](max) NULL,
	[DeletionDate] [datetime] NULL,
	[FullJson] [nvarchar](max) NULL,
	[ErrorHash] [int] NULL,
	[DuplicateCount] [int] NOT NULL,
 CONSTRAINT [PK_Exceptions] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Languages]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Languages]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Languages](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LanguageId] [nvarchar](10) NOT NULL,
	[LanguageName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Languages] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[MeetingAgendaRelevant]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MeetingAgendaRelevant]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[MeetingAgendaRelevant](
	[AgendaRelevantId] [int] IDENTITY(1,1) NOT NULL,
	[AgendaId] [int] NOT NULL,
	[ContactId] [int] NOT NULL,
 CONSTRAINT [PK_MeetingAgendaRelevant] PRIMARY KEY CLUSTERED 
(
	[AgendaRelevantId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[MeetingAgendas]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MeetingAgendas]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[MeetingAgendas](
	[AgendaId] [int] IDENTITY(1,1) NOT NULL,
	[MeetingId] [int] NOT NULL,
	[AgendaNumber] [int] NOT NULL,
	[Title] [nvarchar](2000) NULL,
	[Description] [nvarchar](max) NULL,
	[AgendaTypeId] [int] NOT NULL,
	[RequestedByContactId] [int] NULL,
	[Images] [nvarchar](max) NULL,
	[Attachments] [nvarchar](max) NULL,
 CONSTRAINT [PK_MeetingAgendas] PRIMARY KEY CLUSTERED 
(
	[AgendaId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[MeetingAgendaTypes]    Script Date: 7/2/2021 4:18:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MeetingAgendaTypes]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[MeetingAgendaTypes](
	[AgendaTypeId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_MeetingAgendaTypes] PRIMARY KEY CLUSTERED 
(
	[AgendaTypeId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[MeetingAttendees]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MeetingAttendees]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[MeetingAttendees](
	[AttendeeId] [int] IDENTITY(1,1) NOT NULL,
	[MeetingId] [int] NOT NULL,
	[ContactId] [int] NOT NULL,
	[AttendeeType] [int] NOT NULL,
	[AttendanceStatus] [int] NOT NULL,
 CONSTRAINT [PK_MeetingAttendees] PRIMARY KEY CLUSTERED 
(
	[AttendeeId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[MeetingDecisionRelevant]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MeetingDecisionRelevant]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[MeetingDecisionRelevant](
	[DecisionRelevantId] [int] IDENTITY(1,1) NOT NULL,
	[DecisionId] [int] NOT NULL,
	[ContactId] [int] NOT NULL,
 CONSTRAINT [PK_MeetingDecisionRelevant] PRIMARY KEY CLUSTERED 
(
	[DecisionRelevantId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[MeetingDecisions]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MeetingDecisions]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[MeetingDecisions](
	[DecisionId] [int] IDENTITY(1,1) NOT NULL,
	[MeetingId] [int] NOT NULL,
	[AgendaId] [int] NOT NULL,
	[Description] [nvarchar](max) NULL,
	[DecisionNumber] [int] NOT NULL,
	[ResponsibleContactId] [int] NULL,
	[DueDate] [datetime] NULL,
	[ResolutionStatus] [int] NOT NULL,
	[Images] [nvarchar](max) NULL,
	[Attachments] [nvarchar](max) NULL,
 CONSTRAINT [PK_MeetingDecisions] PRIMARY KEY CLUSTERED 
(
	[DecisionId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[MeetingLocations]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MeetingLocations]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[MeetingLocations](
	[LocationId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[Address] [nvarchar](300) NULL,
	[Latitude] [float] NOT NULL,
	[Longitude] [float] NOT NULL,
 CONSTRAINT [PK_MeetingLocations] PRIMARY KEY CLUSTERED 
(
	[LocationId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Meetings]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Meetings]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Meetings](
	[MeetingId] [int] IDENTITY(1,1) NOT NULL,
	[MeetingName] [nvarchar](100) NOT NULL,
	[MeetingNumber] [nvarchar](20) NULL,
	[MeetingGuid] [uniqueidentifier] NOT NULL,
	[MeetingTypeId] [int] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[LocationId] [int] NULL,
	[UnitId] [int] NULL,
	[OrganizerContactId] [int] NULL,
	[ReporterContactId] [int] NULL,
	[InsertUserId] [int] NOT NULL,
	[InsertDate] [datetime] NOT NULL,
	[UpdateUserId] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[deleted] [bit] NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Meetings] PRIMARY KEY CLUSTERED 
(
	[MeetingId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[MeetingTypes]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MeetingTypes]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[MeetingTypes](
	[MeetingTypeId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_MeetingTypes] PRIMARY KEY CLUSTERED 
(
	[MeetingTypeId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[RolePermissions]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[RolePermissions]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[RolePermissions](
	[RolePermissionId] [bigint] IDENTITY(1,1) NOT NULL,
	[RoleId] [int] NOT NULL,
	[PermissionKey] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_RolePermissions] PRIMARY KEY CLUSTERED 
(
	[RolePermissionId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Roles]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Roles]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Roles](
	[RoleId] [int] IDENTITY(1,1) NOT NULL,
	[RoleName] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_Roles] PRIMARY KEY CLUSTERED 
(
	[RoleId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[SourceData]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SourceData]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[SourceData](
	[type] [nvarchar](25) NULL,
	[event_id] [nvarchar](250) NULL,
	[start_time] [nvarchar](250) NULL,
	[end_time] [nvarchar](250) NULL,
	[name] [nvarchar](250) NULL,
	[description] [nvarchar](max) NULL,
	[parent_group.id] [nvarchar](250) NULL,
	[updated_time] [nvarchar](250) NULL,
	[place.name] [nvarchar](250) NULL,
	[place.location.city] [nvarchar](250) NULL,
	[place.location.country] [nvarchar](250) NULL,
	[place.location.latitude] [nvarchar](250) NULL,
	[place.location.longitude] [nvarchar](250) NULL,
	[place.location.street] [nvarchar](250) NULL,
	[place.location.zip] [nvarchar](250) NULL,
	[place.id] [nvarchar](250) NULL,
	[cover.offset_x] [nvarchar](25) NULL,
	[cover.offset_y] [nvarchar](25) NULL,
	[cover.source] [nvarchar](500) NULL,
	[cover.id] [nvarchar](250) NULL,
	[owner.name] [nvarchar](250) NULL,
	[owner.id] [nvarchar](250) NULL,
	[attending_count] [nvarchar](25) NULL,
	[declined_count] [nvarchar](25) NULL,
	[interested_count] [nvarchar](25) NULL,
	[maybe_count] [nvarchar](25) NULL,
	[noreply_count] [nvarchar](25) NULL,
	[is_draft] [nvarchar](25) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[sysdiagrams]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sysdiagrams]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[sysdiagrams](
	[name] [sysname] NOT NULL,
	[principal_id] [int] NOT NULL,
	[diagram_id] [int] IDENTITY(1,1) NOT NULL,
	[version] [int] NULL,
	[definition] [varbinary](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[diagram_id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
 CONSTRAINT [UK_principal_name] UNIQUE NONCLUSTERED 
(
	[principal_id] ASC,
	[name] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[tempImport]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tempImport]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[tempImport](
	[userId] [uniqueidentifier] NOT NULL,
	[eventId] [uniqueidentifier] NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[UserPermissions]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UserPermissions]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[UserPermissions](
	[UserPermissionId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[PermissionKey] [nvarchar](100) NOT NULL,
	[Granted] [bit] NOT NULL,
 CONSTRAINT [PK_UserPermissions] PRIMARY KEY CLUSTERED 
(
	[UserPermissionId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[UserPreferences]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UserPreferences]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[UserPreferences](
	[UserPreferenceId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[PreferenceType] [nvarchar](100) NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
	[Value] [nvarchar](max) NULL,
 CONSTRAINT [PK_UserPreferences] PRIMARY KEY CLUSTERED 
(
	[UserPreferenceId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[UserRoles]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UserRoles]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[UserRoles](
	[UserRoleId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[RoleId] [int] NOT NULL,
 CONSTRAINT [PK_UserRoles] PRIMARY KEY CLUSTERED 
(
	[UserRoleId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Users]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Users](
	[UserId] [int] IDENTITY(1,1) NOT NULL,
	[Username] [nvarchar](100) NOT NULL,
	[DisplayName] [nvarchar](100) NOT NULL,
	[Email] [nvarchar](100) NOT NULL,
	[Source] [nvarchar](4) NOT NULL,
	[PasswordHash] [nvarchar](86) NOT NULL,
	[PasswordSalt] [nvarchar](10) NOT NULL,
	[InsertDate] [datetime] NOT NULL,
	[InsertUserId] [int] NOT NULL,
	[UpdateDate] [datetime] NULL,
	[UpdateUserId] [int] NULL,
	[IsActive] [smallint] NOT NULL,
	[LastDirectoryUpdate] [datetime] NULL,
	[UserImage] [nvarchar](100) NULL,
	[AuthToken] [nvarchar](2000) NULL,
	[AuthTokenType] [nvarchar](10) NULL,
	[AuthTokenLastUpdated] [datetime] NULL,
	[FirstName] [nvarchar](100) NULL,
	[LastName] [nvarchar](100) NULL,
	[SingleSignOnId] [nvarchar](250) NULL,
	[SingleSignOnType] [nvarchar](50) NULL,
 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[VersionInfo]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[VersionInfo]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[VersionInfo](
	[Version] [bigint] NOT NULL,
	[AppliedOn] [datetime] NULL,
	[Description] [nvarchar](1024) NULL
) ON [PRIMARY]
END
GO
/****** Object:  Index [UC_Version]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[VersionInfo]') AND name = N'UC_Version')
CREATE UNIQUE CLUSTERED INDEX [UC_Version] ON [dbo].[VersionInfo]
(
	[Version] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[world_cities_table]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[world_cities_table]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[world_cities_table](
	[city] [nvarchar](33) NULL,
	[city_ascii] [nvarchar](39) NULL,
	[lat] [numeric](12, 9) NULL,
	[lng] [numeric](13, 9) NULL,
	[pop] [numeric](10, 1) NULL,
	[country] [nvarchar](32) NULL,
	[iso2] [nvarchar](3) NULL,
	[iso3] [nvarchar](3) NULL,
	[province] [nvarchar](43) NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [dbo].[Year2020]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Year2020]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[Year2020](
	[Type] [nvarchar](255) NULL,
	[ID] [nvarchar](255) NULL,
	[Duration] [float] NULL,
	[Start Date] [datetime] NULL,
	[End Date] [datetime] NULL,
	[Project] [nvarchar](255) NULL,
	[Task Title] [nvarchar](255) NULL,
	[Notes] [nvarchar](255) NULL,
	[Application] [nvarchar](255) NULL,
	[Title] [nvarchar](255) NULL,
	[Path] [nvarchar](255) NULL,
	[Containing Task's ID] [nvarchar](255) NULL,
	[StartPlus10] [datetime] NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [DEV].[EnumPaymentTypes]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DEV].[EnumPaymentTypes]') AND type in (N'U'))
BEGIN
CREATE TABLE [DEV].[EnumPaymentTypes](
	[paymentTypeId] [int] NOT NULL,
	[name] [nvarchar](50) NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [DEV].[ImportHashers]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DEV].[ImportHashers]') AND type in (N'U'))
BEGIN
CREATE TABLE [DEV].[ImportHashers](
	[idx] [int] IDENTITY(1,1) NOT NULL,
	[HashName] [nvarchar](250) NOT NULL,
	[First] [char](1) NOT NULL,
	[Last] [char](1) NOT NULL,
 CONSTRAINT [PK_ImportHashers] PRIMARY KEY CLUSTERED 
(
	[idx] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [DEV].[timezone]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DEV].[timezone]') AND type in (N'U'))
BEGIN
CREATE TABLE [DEV].[timezone](
	[city] [nvarchar](500) NOT NULL,
	[city_ascii] [nvarchar](500) NOT NULL,
	[lat] [decimal](19, 8) NOT NULL,
	[lon] [decimal](19, 8) NOT NULL,
	[pop] [numeric](18, 3) NOT NULL,
	[country] [nvarchar](500) NOT NULL,
	[iso2] [nvarchar](5) NOT NULL,
	[iso3] [nvarchar](5) NOT NULL,
	[province] [nvarchar](500) NOT NULL,
	[timezone] [nvarchar](500) NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [DEV].[WindowsTimezoneMap]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DEV].[WindowsTimezoneMap]') AND type in (N'U'))
BEGIN
CREATE TABLE [DEV].[WindowsTimezoneMap](
	[WindowsTimezone] [nvarchar](150) NULL,
	[Region] [nvarchar](50) NULL,
	[Timezones] [nvarchar](3500) NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [DomainValues].[CurrencyCodes]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DomainValues].[CurrencyCodes]') AND type in (N'U'))
BEGIN
CREATE TABLE [DomainValues].[CurrencyCodes](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Nation] [nvarchar](500) NOT NULL,
	[CurrencyName] [nvarchar](100) NOT NULL,
	[CurrencyCode] [nvarchar](50) NOT NULL,
	[CurrencyNumericCode] [nvarchar](50) NOT NULL,
	[DigitsAfterDecimal] [int] NOT NULL,
	[CultureCode] [nvarchar](50) NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [DomainValues].[EventGeographicScope]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DomainValues].[EventGeographicScope]') AND type in (N'U'))
BEGIN
CREATE TABLE [DomainValues].[EventGeographicScope](
	[EventEnumId] [smallint] NOT NULL,
	[EventEnumName] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_EventEnum] PRIMARY KEY CLUSTERED 
(
	[EventEnumId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [DomainValues].[EventRegistrationType]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DomainValues].[EventRegistrationType]') AND type in (N'U'))
BEGIN
CREATE TABLE [DomainValues].[EventRegistrationType](
	[EventRegistrationEnumId] [smallint] IDENTITY(1,1) NOT NULL,
	[EventRegistrationEnumName] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_EventRegistrationEnum] PRIMARY KEY CLUSTERED 
(
	[EventRegistrationEnumId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [DomainValues].[EventThemeType]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DomainValues].[EventThemeType]') AND type in (N'U'))
BEGIN
CREATE TABLE [DomainValues].[EventThemeType](
	[EventEnumId] [bigint] NOT NULL,
	[EventEnumName] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_EventThemeEnum] PRIMARY KEY CLUSTERED 
(
	[EventEnumId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [DomainValues].[KennelStatusEnum]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DomainValues].[KennelStatusEnum]') AND type in (N'U'))
BEGIN
CREATE TABLE [DomainValues].[KennelStatusEnum](
	[KennelStatusEnumId] [smallint] NOT NULL,
	[KennelStatusEnumName] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_KennelStatusEnum] PRIMARY KEY CLUSTERED 
(
	[KennelStatusEnumId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [DomainValues].[MismanagementEnum]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DomainValues].[MismanagementEnum]') AND type in (N'U'))
BEGIN
CREATE TABLE [DomainValues].[MismanagementEnum](
	[MismanagementEnumId] [smallint] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](250) NOT NULL,
	[Abbreviation] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_MismanagementEnum] PRIMARY KEY CLUSTERED 
(
	[MismanagementEnumId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [DomainValues].[Timezone]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DomainValues].[Timezone]') AND type in (N'U'))
BEGIN
CREATE TABLE [DomainValues].[Timezone](
	[id] [int] IDENTITY(10,10) NOT NULL,
	[FullTimezone] [nvarchar](303) NOT NULL,
	[Timezone] [nvarchar](300) NOT NULL,
	[SubTimezone] [nvarchar](150) NOT NULL,
 CONSTRAINT [PK_Timezone] PRIMARY KEY NONCLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Timezone]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[DomainValues].[Timezone]') AND name = N'IX_Timezone')
CREATE CLUSTERED INDEX [IX_Timezone] ON [DomainValues].[Timezone]
(
	[FullTimezone] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Table [EXT].[FbAppEvent]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[FbAppEvent]') AND type in (N'U'))
BEGIN
CREATE TABLE [EXT].[FbAppEvent](
	[FbAppEventId] [uniqueidentifier] NOT NULL,
	[UserId] [nvarchar](100) NULL,
	[UserName] [nvarchar](250) NULL,
	[UserEmail] [nvarchar](250) NULL,
	[UserFirstName] [nvarchar](100) NULL,
	[UserLastName] [nvarchar](100) NULL,
	[GroupId] [nvarchar](100) NULL,
	[GroupName] [nvarchar](250) NULL,
	[GroupDescription] [nvarchar](4000) NULL,
	[GroupCoverPhoto] [nvarchar](500) NULL,
	[Verb] [nvarchar](150) NOT NULL,
	[UpdateTime] [nvarchar](50) NULL,
	[FbGroupJson] [nvarchar](4000) NULL,
	[FbUserJson] [nvarchar](4000) NULL,
	[OriginalActorId] [nvarchar](50) NULL,
	[OriginalGroupId] [nvarchar](50) NULL,
	[updatedAt] [datetime] NOT NULL,
 CONSTRAINT [PK_FbAppEvent] PRIMARY KEY CLUSTERED 
(
	[FbAppEventId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [EXT].[OfficeForms_KennelImport]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[OfficeForms_KennelImport]') AND type in (N'U'))
BEGIN
CREATE TABLE [EXT].[OfficeForms_KennelImport](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[KennelImportId] [uniqueidentifier] NULL,
	[KennelImportedOn] [datetime] NULL,
	[KennelAdminInviteCode] [nvarchar](50) NULL,
	[KennelId] [uniqueidentifier] NULL,
	[FirstName] [nvarchar](250) NOT NULL,
	[LastName] [nvarchar](250) NOT NULL,
	[HashName] [nvarchar](250) NOT NULL,
	[NameToUse] [nvarchar](250) NOT NULL,
	[EmailAddress] [nvarchar](250) NOT NULL,
	[IsKennelAdmin] [nvarchar](250) NOT NULL,
	[KennelName] [nvarchar](250) NOT NULL,
	[KennelShortName] [nvarchar](250) NOT NULL,
	[KennelUrl] [nvarchar](250) NULL,
	[KennelDescription] [nvarchar](4000) NOT NULL,
	[KennelPinColor] [nvarchar](50) NOT NULL,
	[IsRunningPostCovid] [nvarchar](50) NULL,
	[NumberOfRunsPerMonth] [nvarchar](50) NOT NULL,
	[NumberOfHashersPerRun] [nvarchar](50) NOT NULL,
	[WhenStartRunningPostCovid] [nvarchar](50) NULL,
	[Country] [nvarchar](50) NOT NULL,
	[CountryId] [uniqueidentifier] NULL,
	[Region] [nvarchar](50) NULL,
	[RegionId] [uniqueidentifier] NULL,
	[City] [nvarchar](50) NOT NULL,
	[CityId] [uniqueidentifier] NULL,
	[HashCash] [nvarchar](50) NOT NULL,
	[KennelFacebookId] [nvarchar](50) NULL,
	[KennelFacebookEmailAddress] [nvarchar](250) NULL,
	[UserIsFacebookAdmin] [nvarchar](50) NULL,
	[SubmitterEmail] [nvarchar](250) NULL,
	[SubmittedOn] [datetime] NULL,
 CONSTRAINT [PK_OfficeForms_KennelImport] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [EXT].[Zapier_FbEvent]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[Zapier_FbEvent]') AND type in (N'U'))
BEGIN
CREATE TABLE [EXT].[Zapier_FbEvent](
	[zapierFbEventId] [uniqueidentifier] NULL,
	[id] [nvarchar](50) NULL,
	[attending_count] [int] NULL,
	[declined_count] [int] NULL,
	[description] [nvarchar](4000) NULL,
	[start_time] [datetimeoffset](7) NULL,
	[end_time] [datetimeoffset](7) NULL,
	[interested_count] [int] NULL,
	[is_cancelled] [nvarchar](10) NULL,
	[maybe_count] [int] NULL,
	[name] [nvarchar](250) NULL,
	[parent_group_id] [nvarchar](50) NULL,
	[place_name] [nvarchar](250) NULL,
	[place_location_city] [nvarchar](250) NULL,
	[place_location_country] [nvarchar](250) NULL,
	[place_locatoin_latittude] [decimal](12, 9) NULL,
	[place_location_longitude] [decimal](13, 9) NULL,
	[place_location_street] [nvarchar](250) NULL,
	[place_location_zip] [nvarchar](50) NULL,
	[place_id] [nvarchar](50) NULL,
	[updatedTime] [datetimeoffset](7) NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [EXT].[Zapier_GCal]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[Zapier_GCal]') AND type in (N'U'))
BEGIN
CREATE TABLE [EXT].[Zapier_GCal](
	[zapierGcalId] [uniqueidentifier] NULL,
	[id] [nvarchar](50) NULL,
	[etag] [nvarchar](50) NULL,
	[status] [nvarchar](50) NULL,
	[htmlLink] [nvarchar](250) NULL,
	[created] [datetimeoffset](7) NULL,
	[updated] [datetimeoffset](7) NULL,
	[summary] [nvarchar](500) NULL,
	[description] [nvarchar](4000) NULL,
	[location] [nvarchar](500) NULL,
	[creator_email] [nvarchar](250) NULL,
	[organizer_email] [nvarchar](250) NULL,
	[start_datetime] [datetimeoffset](7) NULL,
	[end_datetime] [datetimeoffset](7) NULL,
	[iCalUID] [nvarchar](250) NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [Hashers].[HasherEventMap]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Hashers].[HasherEventMap]') AND type in (N'U'))
BEGIN
CREATE TABLE [Hashers].[HasherEventMap](
	[id] [nvarchar](255) NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Hashers].[HasherFriendMap]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Hashers].[HasherFriendMap]') AND type in (N'U'))
BEGIN
CREATE TABLE [Hashers].[HasherFriendMap](
	[id] [nvarchar](255) NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[BusinessUnits]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[BusinessUnits]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[BusinessUnits](
	[id] [nvarchar](255) NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[ErrorLog]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[ErrorLog]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[ErrorLog](
	[id] [uniqueidentifier] NOT NULL,
	[HcVersion] [nvarchar](250) NOT NULL,
	[ErrorName] [nvarchar](250) NULL,
	[ErrorDescription] [nvarchar](2500) NULL,
	[ProcName] [nvarchar](250) NULL,
	[userId] [uniqueidentifier] NULL,
	[kennelId] [uniqueidentifier] NULL,
	[eventId] [uniqueidentifier] NULL,
	[deviceId] [nvarchar](250) NULL,
	[string_1] [nvarchar](1000) NULL,
	[string_2] [nvarchar](1000) NULL,
	[errorCode] [int] NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL,
 CONSTRAINT [PK_ErrorLog] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[HasherFriendMap]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[HasherFriendMap]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[HasherFriendMap](
	[id] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[Friend_UserId] [uniqueidentifier] NOT NULL,
	[FriendNotificationPreference] [smallint] NOT NULL,
	[Ignore] [smallint] NOT NULL,
	[FriendSince] [datetimeoffset](7) NULL,
 CONSTRAINT [PK_HasherFriendMap] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[HasherOwnEvent]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[HasherOwnEvent]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[HasherOwnEvent](
	[id] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NULL,
	[EvebtUd] [uniqueidentifier] NULL,
	[KennelName] [nvarchar](500) NULL,
	[Place] [nvarchar](2000) NULL,
	[EventStartDatetime] [datetimeoffset](7) NULL,
	[Latitude] [decimal](18, 15) NULL,
	[Longitude] [decimal](19, 15) NULL,
	[removed] [smallint] NOT NULL,
	[deleted] [bit] NOT NULL,
	[lastModified] [datetimeoffset](7) NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_HasherOwnEvent] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[KennelAuthorization]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[KennelAuthorization]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[KennelAuthorization](
	[id] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[Auth_FacebookIntegration] [smallint] NOT NULL,
	[Auth_TrackPayments] [smallint] NOT NULL,
	[Auth_Haberdashery] [smallint] NOT NULL,
	[Auth_CustomSongbook] [smallint] NOT NULL,
	[Auth_WebsiteIntegration] [smallint] NOT NULL,
	[Auth_AllowCredit] [smallint] NOT NULL,
	[Auth_PushNotifications] [smallint] NOT NULL,
	[Auth_CheckInAndOut] [smallint] NOT NULL,
	[Auth_PromoteEvents] [smallint] NOT NULL,
	[Auth_CustomLogo] [smallint] NOT NULL,
	[Auth_MembersAllowed] [smallint] NOT NULL,
	[Auth_HareRaisingManagement] [smallint] NOT NULL,
	[StartDate] [datetimeoffset](7) NOT NULL,
	[EndDate] [datetimeoffset](7) NULL,
	[Notes] [nvarchar](1000) NULL,
 CONSTRAINT [PK_KennelAuthorization] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[KennelCredit]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[KennelCredit]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[KennelCredit](
	[id] [uniqueidentifier] NOT NULL,
	[userId] [uniqueidentifier] NOT NULL,
	[kennelId] [uniqueidentifier] NOT NULL,
	[balanceAsOfEventId] [uniqueidentifier] NOT NULL,
	[currentBalance] [smallmoney] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[removed] [smallint] NOT NULL,
 CONSTRAINT [PK_KennelCredit] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[LoginNotifications]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[LoginNotifications]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[LoginNotifications](
	[id] [uniqueidentifier] NOT NULL,
	[ServerStatusCode] [smallint] NOT NULL,
	[LoginMessageTitle] [nvarchar](120) NOT NULL,
	[LoginMessage] [nvarchar](500) NOT NULL,
	[MessageWindowOpens] [datetimeoffset](7) NOT NULL,
	[MessageWindowCloses] [datetimeoffset](7) NOT NULL,
	[MessageDisplayType] [smallint] NOT NULL,
	[MessageImageUrl] [nvarchar](500) NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_ServerMaintenanceWindow] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[Meetings]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[Meetings]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[Meetings](
	[id] [nvarchar](255) NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[ServerStatus]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[ServerStatus]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[ServerStatus](
	[id] [uniqueidentifier] NOT NULL,
	[ApiVersion] [nvarchar](25) NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[IosDownloadLink] [nvarchar](250) NOT NULL,
	[AndroidDownloadLink] [nvarchar](250) NOT NULL,
	[ImageRootUrl] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_ServerStatus] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC].[WebAppLogin]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[WebAppLogin]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC].[WebAppLogin](
	[id] [uniqueidentifier] NOT NULL,
	[Username] [nvarchar](100) NOT NULL,
	[LoginDatetime] [datetimeoffset](7) NOT NULL,
	[LoginSuccessful] [smallint] NOT NULL,
	[Browser] [nvarchar](50) NULL,
	[BrowserId] [nvarchar](50) NULL,
	[IsMobileDevice] [smallint] NULL,
	[MobileDeviceModel] [nvarchar](50) NULL,
	[MobileDeviceManufacturer] [nvarchar](50) NULL,
	[Platform] [nvarchar](50) NULL,
	[Type] [nvarchar](50) NULL,
	[Version] [nvarchar](20) NULL,
 CONSTRAINT [PK_WebAppLogin] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[City]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[City]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[City](
	[id] [uniqueidentifier] NOT NULL,
	[CityName] [nvarchar](100) NOT NULL,
	[CityCountryName] [nvarchar](250) NULL,
	[CityFullName] [nvarchar](350) NULL,
	[ShowRegion] [smallint] NULL,
	[RegionId] [uniqueidentifier] NOT NULL,
	[Latitude] [numeric](12, 9) NOT NULL,
	[Longitude] [numeric](13, 9) NOT NULL,
	[City_ASCII] [nvarchar](100) NULL,
	[CityGeolocation] [geography] NOT NULL,
	[FlagFile] [nvarchar](100) NULL,
	[TimezoneId] [int] NULL,
	[Removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[Country]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[Country]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[Country](
	[id] [uniqueidentifier] NOT NULL,
	[CountryCode] [nvarchar](5) NOT NULL,
	[Latitude] [float] NOT NULL,
	[Longitude] [float] NOT NULL,
	[CountryName] [nvarchar](250) NOT NULL,
	[ContinentCode] [nvarchar](5) NOT NULL,
	[ContinentName] [nvarchar](100) NOT NULL,
	[FlagFile] [nvarchar](100) NULL,
	[CurrencyCode] [nvarchar](5) NOT NULL,
	[PrimaryCultureCode] [nvarchar](10) NOT NULL,
	[ShowRegion] [smallint] NOT NULL,
	[CurrencySymbol] [nvarchar](5) NOT NULL,
	[DigitsAfterDecimal] [smallint] NOT NULL,
	[DistancePreference] [smallint] NOT NULL,
	[Removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[EmailLog]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[EmailLog]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[EmailLog](
	[id] [uniqueidentifier] NOT NULL,
	[EmailTemplaterId] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NOT NULL,
	[DateSent] [datetimeoffset](7) NOT NULL,
	[NumberSent] [int] NOT NULL,
	[ServerReply] [nvarchar](2500) NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[EmailTemplate]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[EmailTemplate]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[EmailTemplate](
	[id] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NULL,
	[Description] [nvarchar](250) NOT NULL,
	[Subject] [nvarchar](250) NOT NULL,
	[Template] [nvarchar](max) NOT NULL,
	[EmailTypeFlag] [int] NOT NULL,
	[HoursBeforeRun] [smallint] NOT NULL,
	[DaysBeforeRun] [smallint] NOT NULL,
	[SendToAll] [smallint] NOT NULL,
	[SendToMembers] [smallint] NOT NULL,
	[SendToMismanagement] [smallint] NOT NULL,
	[SendToFollowers] [smallint] NOT NULL,
	[SendToVisitors] [smallint] NOT NULL,
	[ReplyToEmailAddress] [nvarchar](250) NOT NULL,
	[SenderName] [nvarchar](250) NOT NULL,
	[SendWhenHareAssigned] [smallint] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[Event]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[Event]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[Event](
	[id] [uniqueidentifier] NOT NULL,
	[EventStartDatetime] [datetimeoffset](7) NULL,
	[EventEndDatetime] [datetimeoffset](7) NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[IsVisible] [smallint] NOT NULL,
	[IsCountedRun] [smallint] NOT NULL,
	[IsPromotedEvent] [smallint] NOT NULL,
	[EventGeographicScope] [smallint] NOT NULL,
	[ThemeRunType] [int] NOT NULL,
	[Tags1] [int] NOT NULL,
	[Tags2] [int] NOT NULL,
	[Tags3] [int] NOT NULL,
	[AbsoluteEventNumber] [smallint] NULL,
	[EventNumber] [smallint] NOT NULL,
	[EventNumberIncrement] [smallint] NOT NULL,
	[DoTrackHashCash] [smallint] NOT NULL,
	[EventPriceForMembers] [decimal](10, 4) NULL,
	[EventPriceForNonMembers] [decimal](10, 4) NULL,
	[EventPriceForExtras] [decimal](10, 4) NULL,
	[ExtrasDescription] [nvarchar](250) NULL,
	[EventCurrencyType] [nvarchar](10) NULL,
	[BankScheme] [nvarchar](10) NULL,
	[BankAccountNumber] [nvarchar](50) NULL,
	[BankBic] [nvarchar](50) NULL,
	[BankBeneficiary] [nvarchar](150) NULL,
	[EventPaymentUrl] [nvarchar](2000) NULL,
	[EventPaymentUrlExpires] [datetimeoffset](7) NULL,
	[UnconfirmedBankXferCount] [int] NOT NULL,
	[UserEventCounterIncrement] [smallint] NOT NULL,
	[EventName] [nvarchar](250) NOT NULL,
	[EventDescription] [nvarchar](4000) NULL,
	[EventImage] [nvarchar](500) NULL,
	[EventImageOffsetX] [smallint] NULL,
	[EventImageOffsetY] [smallint] NULL,
	[LocationOneLineDesc] [nvarchar](250) NULL,
	[LocationCity] [nvarchar](250) NULL,
	[LocationStreet] [nvarchar](250) NULL,
	[LocationPostCode] [nvarchar](250) NULL,
	[LocationCountry] [nvarchar](250) NULL,
	[Latitude] [decimal](18, 15) NULL,
	[Longitude] [decimal](19, 15) NULL,
	[EventGeolocation] [geography] NULL,
	[MinimumParticipantsRequired] [smallint] NOT NULL,
	[MaximumParticipantsAllowed] [smallint] NULL,
	[Organizer_HasherId] [uniqueidentifier] NULL,
	[CanEditRunAttendence] [smallint] NOT NULL,
	[Hares] [nvarchar](2500) NULL,
	[UseFbRunDetails] [smallint] NOT NULL,
	[UseFbLocation] [smallint] NOT NULL,
	[UseFbLatLon] [smallint] NOT NULL,
	[UpdateDataFromFacebook] [smallint] NOT NULL,
	[EventFacebookId] [nvarchar](250) NULL,
	[FacebookRecordLastUpdated] [datetimeoffset](7) NULL,
	[FbEventName] [nvarchar](250) NULL,
	[FbEventDescription] [nvarchar](4000) NULL,
	[FbEventStartDatetime] [datetimeoffset](7) NULL,
	[FbEventImage] [nvarchar](500) NULL,
	[FbEventImageOffsetX] [smallint] NULL,
	[FbEventImageOffsetY] [smallint] NULL,
	[FbLocationOneLineDesc] [nvarchar](250) NULL,
	[FbLocationCity] [nvarchar](250) NULL,
	[FbLocationStreet] [nvarchar](250) NULL,
	[FbLocationPostCode] [nvarchar](250) NULL,
	[FbLocationCountry] [nvarchar](250) NULL,
	[FbLatitude] [decimal](18, 15) NULL,
	[FbLongitude] [decimal](19, 15) NULL,
	[FbEventGeoLocation] [geography] NULL,
	[removed] [smallint] NOT NULL,
	[deleted] [bit] NOT NULL,
	[lastModified] [datetimeoffset](7) NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[Hasher]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[Hasher]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[Hasher](
	[id] [uniqueidentifier] NOT NULL,
	[HomeKennelId] [uniqueidentifier] NULL,
	[MotherKennelId] [uniqueidentifier] NULL,
	[SupportCode] [nvarchar](50) NOT NULL,
	[ResetCode] [nvarchar](50) NOT NULL,
	[QR_code] [nvarchar](50) NOT NULL,
	[QR_secret_code] [uniqueidentifier] NOT NULL,
	[DisplayName] [nvarchar](250) NOT NULL,
	[HashName] [nvarchar](250) NULL,
	[FirstName] [nvarchar](250) NULL,
	[LastName] [nvarchar](250) NULL,
	[Email] [nvarchar](250) NOT NULL,
	[Photo] [nvarchar](250) NULL,
	[Gender] [nvarchar](50) NULL,
	[FacebookId] [nvarchar](250) NULL,
	[FacebookAccessToken] [nvarchar](250) NULL,
	[FacebookAccessTokenLastUpdated] [datetimeoffset](7) NULL,
	[Locale] [nvarchar](50) NULL,
	[Description] [nvarchar](4000) NULL,
	[HomeLatitude] [decimal](12, 9) NULL,
	[HomeLongitude] [decimal](13, 9) NULL,
	[HomeGeolocation] [geography] NULL,
	[NameDisplayPreference] [smallint] NOT NULL,
	[Preferences] [int] NOT NULL,
	[HcWebUserId] [int] NULL,
	[IncludeInGlobalHashDirectory] [smallint] NOT NULL,
	[Removed] [smallint] NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[HasherEventMap]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[HasherEventMap]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[HasherEventMap](
	[id] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NULL,
	[HasherOwnEventId] [uniqueidentifier] NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[RunCountId] [int] NOT NULL,
	[RegistrationId] [uniqueidentifier] NULL,
	[UserStartEvent] [datetimeoffset](7) NULL,
	[UserEndEvent] [datetimeoffset](7) NULL,
	[EventCost] [smallmoney] NULL,
	[Rsvp] [datetimeoffset](7) NULL,
	[RsvpState] [smallint] NOT NULL,
	[AttendenceState] [smallint] NOT NULL,
	[IsHare] [smallint] NOT NULL,
	[EventNotificationPreference] [smallint] NULL,
	[EventEmailAlertPreference] [smallint] NULL,
	[EventCountOverride] [smallint] NULL,
	[VirginVisitorType] [smallint] NOT NULL,
	[DisplayName] [nvarchar](120) NULL,
	[Email] [nvarchar](120) NULL,
	[PhoneNumber] [nvarchar](120) NULL,
	[removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[HasherFriendMap]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[HasherFriendMap]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[HasherFriendMap](
	[id] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[Friend_UserId] [uniqueidentifier] NOT NULL,
	[FriendNotificationPreference] [smallint] NOT NULL,
	[Ignore] [smallint] NOT NULL,
	[FriendSince] [datetimeoffset](7) NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[HasherKennelMap]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[HasherKennelMap]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[HasherKennelMap](
	[id] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[Following] [smallint] NOT NULL,
	[IsMember] [smallint] NOT NULL,
	[IsKennelFollowing] [smallint] NOT NULL,
	[IsHomeKennel] [smallint] NOT NULL,
	[KennelNotificationPreference] [smallint] NOT NULL,
	[KennelEmailAlertPreference] [smallint] NOT NULL,
	[MismanagementRoles] [int] NOT NULL,
	[MismanagementRoleFlags] [int] NOT NULL,
	[HcWebPermissionFlags] [int] NOT NULL,
	[UserRoleFlags] [int] NOT NULL,
	[AppAccessFlags] [int] NULL,
	[HistoricalPackRunCount] [smallint] NOT NULL,
	[HistoricalHaringCount] [smallint] NOT NULL,
	[HistoricalCountIsEstimate] [smallint] NOT NULL,
	[CurrentPackRunCount] [smallint] NOT NULL,
	[CurrentHaringCount] [smallint] NOT NULL,
	[DateOfLastRun] [datetimeoffset](7) NULL,
	[MembershipExpirationDate] [datetimeoffset](7) NULL,
	[MemberSince] [datetimeoffset](7) NULL,
	[CanEditRunAttendence] [smallint] NOT NULL,
	[removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[HasherOwnEvent]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[HasherOwnEvent]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[HasherOwnEvent](
	[id] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NULL,
	[EventId] [uniqueidentifier] NULL,
	[EventStartDatetime] [datetimeoffset](7) NULL,
	[IsVisible] [smallint] NOT NULL,
	[IsCountedRun] [smallint] NOT NULL,
	[AbsoluteEventNumber] [smallint] NULL,
	[EventNumber] [smallint] NULL,
	[EventName] [nvarchar](250) NULL,
	[EventDescription] [nvarchar](4000) NULL,
	[LocationOneLineDesc] [nvarchar](250) NULL,
	[LocationCity] [nvarchar](250) NULL,
	[LocationStreet] [nvarchar](250) NULL,
	[LocationPostCode] [nvarchar](250) NULL,
	[LocationCountry] [nvarchar](250) NULL,
	[Latitude] [decimal](18, 15) NULL,
	[Longitude] [decimal](19, 15) NULL,
	[EventGeolocation] [geography] NULL,
	[Hares] [nvarchar](2500) NULL,
	[removed] [smallint] NOT NULL,
	[deleted] [bit] NOT NULL,
	[lastModified] [datetimeoffset](7) NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[Kennel]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[Kennel]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[Kennel](
	[id] [uniqueidentifier] NOT NULL,
	[KennelStatus] [smallint] NOT NULL,
	[KennelName] [nvarchar](250) NOT NULL,
	[KennelFacebookId] [nvarchar](250) NULL,
	[KennelFacebookToken] [nvarchar](1000) NULL,
	[KennelFacebookTokenUserId] [uniqueidentifier] NULL,
	[KennelFacebookTokenLastUpdated] [datetimeoffset](7) NULL,
	[KennelFacebookImportDaysInPast] [smallint] NOT NULL,
	[KennelFacebookImportDaysInFuture] [smallint] NOT NULL,
	[KennelFacebookForceUpdatesUntil] [datetimeoffset](7) NULL,
	[AutoImportFacebookEvents] [smallint] NOT NULL,
	[ImportOnlyTaggedEvents] [smallint] NOT NULL,
	[CanEditRunAttendence] [smallint] NOT NULL,
	[FacebookTagForImport] [nvarchar](500) NULL,
	[KennelShortName] [nvarchar](10) NULL,
	[KennelDescription] [nvarchar](4000) NULL,
	[KennelLogo] [nvarchar](500) NOT NULL,
	[KennelCoverPhoto] [nvarchar](500) NULL,
	[KennelWebsiteUrl] [nvarchar](500) NULL,
	[KennelMismanagementTeam] [nvarchar](4000) NULL,
	[DefaultEventPriceForMembers] [decimal](10, 4) NOT NULL,
	[DefaultEventPriceForNonMembers] [decimal](10, 4) NOT NULL,
	[DefaultEventCurrencyType] [nvarchar](10) NULL,
	[DefaultRunStartTime] [time](7) NOT NULL,
	[CurrencyCode] [nvarchar](5) NULL,
	[PrimaryCultureCode] [nvarchar](10) NULL,
	[CurrencySymbol] [nvarchar](5) NULL,
	[DigitsAfterDecimal] [smallint] NULL,
	[BankScheme] [nvarchar](10) NULL,
	[BankAccountNumber] [nvarchar](50) NULL,
	[BankBic] [nvarchar](50) NULL,
	[BankBeneficiary] [nvarchar](150) NULL,
	[KennelPaymentUrl] [nvarchar](2000) NULL,
	[KennelPaymentUrlExpires] [datetimeoffset](7) NULL,
	[AllowNegativeCredit] [smallint] NOT NULL,
	[CityId] [uniqueidentifier] NOT NULL,
	[ProvinceStateId] [uniqueidentifier] NOT NULL,
	[CountryId] [uniqueidentifier] NOT NULL,
	[Latitude] [decimal](18, 14) NULL,
	[Longitude] [decimal](19, 15) NULL,
	[KennelGeolocation] [geography] NULL,
	[MembershipDurationInMonths] [int] NOT NULL,
	[RunCountStartDate] [datetimeoffset](7) NULL,
	[DistancePreference] [smallint] NULL,
	[ExtApiKey] [nvarchar](120) NULL,
	[removed] [smallint] NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[KennelAuthorization]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[KennelAuthorization]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[KennelAuthorization](
	[id] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[Auth_FacebookIntegration] [smallint] NOT NULL,
	[Auth_TrackPayments] [smallint] NOT NULL,
	[Auth_Haberdashery] [smallint] NOT NULL,
	[Auth_CustomSongbook] [smallint] NOT NULL,
	[Auth_WebsiteIntegration] [smallint] NOT NULL,
	[Auth_AllowCredit] [smallint] NOT NULL,
	[Auth_PushNotifications] [smallint] NOT NULL,
	[Auth_CheckInAndOut] [smallint] NOT NULL,
	[Auth_PromoteEvents] [smallint] NOT NULL,
	[Auth_CustomLogo] [smallint] NOT NULL,
	[Auth_MembersAllowed] [smallint] NOT NULL,
	[Auth_HareRaisingManagement] [smallint] NOT NULL,
	[StartDate] [datetimeoffset](7) NOT NULL,
	[EndDate] [datetimeoffset](7) NULL,
	[Notes] [nvarchar](1000) NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[KennelCredit]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[KennelCredit]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[KennelCredit](
	[id] [uniqueidentifier] NOT NULL,
	[userId] [uniqueidentifier] NOT NULL,
	[kennelId] [uniqueidentifier] NOT NULL,
	[balanceAsOfEventId] [uniqueidentifier] NOT NULL,
	[currentBalance] [smallmoney] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[removed] [smallint] NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[LaunchAndLogin]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[LaunchAndLogin]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[LaunchAndLogin](
	[id] [uniqueidentifier] NOT NULL,
	[LoginDate] [datetimeoffset](7) NOT NULL,
	[HcVersion] [nvarchar](200) NOT NULL,
	[UserName] [nvarchar](250) NULL,
	[UserId] [uniqueidentifier] NULL,
	[DeviceId] [nvarchar](100) NULL,
	[DeviceType] [nvarchar](100) NULL,
	[DeviceName] [nvarchar](100) NULL,
	[SystemName] [nvarchar](100) NULL,
	[SystemVersion] [nvarchar](100) NULL,
	[Manufacturer] [nvarchar](100) NULL,
	[Latitude] [decimal](18, 15) NULL,
	[Longitude] [decimal](19, 15) NULL,
	[CityId] [uniqueidentifier] NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[LoginNotifications]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[LoginNotifications]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[LoginNotifications](
	[id] [uniqueidentifier] NOT NULL,
	[ServerStatusCode] [smallint] NOT NULL,
	[LoginMessageTitle] [nvarchar](120) NOT NULL,
	[LoginMessage] [nvarchar](500) NOT NULL,
	[MessageWindowOpens] [datetimeoffset](7) NOT NULL,
	[MessageWindowCloses] [datetimeoffset](7) NOT NULL,
	[MessageDisplayType] [smallint] NOT NULL,
	[MessageImageUrl] [nvarchar](500) NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[Payment]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[Payment]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[Payment](
	[id] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NULL,
	[HasherEventMapId] [uniqueidentifier] NULL,
	[EventId] [uniqueidentifier] NULL,
	[PaymentProcessedBy_userId] [uniqueidentifier] NOT NULL,
	[CreditAmount] [smallmoney] NOT NULL,
	[DebitAmount] [smallmoney] NOT NULL,
	[PaidDate] [datetimeoffset](7) NOT NULL,
	[PaymentType] [smallint] NOT NULL,
	[ProductType] [smallint] NOT NULL,
	[CreditAvailable] [smallmoney] NOT NULL,
	[CancelledDate] [datetimeoffset](7) NULL,
	[CancelledBy_UserId] [uniqueidentifier] NULL,
	[ConfirmedDate] [datetimeoffset](7) NULL,
	[ConfirmedBy_UserId] [uniqueidentifier] NULL,
	[PaymentReference] [nvarchar](50) NULL,
	[DoPayForExtras] [smallint] NOT NULL,
	[Notes] [nvarchar](500) NULL,
	[removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[Recepit]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[Recepit]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[Recepit](
	[id] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[ReceiptAmount] [decimal](12, 4) NOT NULL,
	[CostCategory] [smallint] NOT NULL,
	[DateUploaded] [datetimeoffset](7) NOT NULL,
	[ImageUrl] [nvarchar](500) NULL,
	[ReceiptShortDesc] [nvarchar](255) NULL,
	[Notes] [nvarchar](1000) NULL,
	[ReimbursedBy] [uniqueidentifier] NULL,
	[ReimbursedOn] [datetimeoffset](7) NULL,
	[ReimbursedAmount] [decimal](12, 4) NULL,
	[ReimbursedNotes] [nvarchar](1000) NULL,
	[removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[Region]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[Region]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[Region](
	[id] [uniqueidentifier] NOT NULL,
	[RegionName] [nvarchar](100) NOT NULL,
	[CountryId] [uniqueidentifier] NOT NULL,
	[FlagFile] [nvarchar](100) NULL,
	[Removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[RunCounts]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[RunCounts]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[RunCounts](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[TotalPackRunsThisKennel] [int] NOT NULL,
	[TotalHaringThisKennel] [int] NOT NULL,
	[TotalPackRunsAllKennels] [int] NOT NULL,
	[TotalHaringAllKennels] [int] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[ServerStatus]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[ServerStatus]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[ServerStatus](
	[id] [uniqueidentifier] NOT NULL,
	[ApiVersion] [nvarchar](25) NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
	[IosDownloadLink] [nvarchar](250) NOT NULL,
	[AndroidDownloadLink] [nvarchar](250) NOT NULL,
	[ImageRootUrl] [nvarchar](250) NOT NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [HC_BACKUP].[WebAppLogin]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC_BACKUP].[WebAppLogin]') AND type in (N'U'))
BEGIN
CREATE TABLE [HC_BACKUP].[WebAppLogin](
	[id] [uniqueidentifier] NOT NULL,
	[Username] [nvarchar](100) NOT NULL,
	[LoginDatetime] [datetimeoffset](7) NOT NULL,
	[LoginSuccessful] [smallint] NOT NULL,
	[Browser] [nvarchar](50) NULL,
	[BrowserId] [nvarchar](50) NULL,
	[IsMobileDevice] [smallint] NULL,
	[MobileDeviceModel] [nvarchar](50) NULL,
	[MobileDeviceManufacturer] [nvarchar](50) NULL,
	[Platform] [nvarchar](50) NULL,
	[Type] [nvarchar](50) NULL,
	[Version] [nvarchar](20) NULL
) ON [PRIMARY]
END
GO
/****** Object:  Table [Kennels].[Haberdashery]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Kennels].[Haberdashery]') AND type in (N'U'))
BEGIN
CREATE TABLE [Kennels].[Haberdashery](
	[HaberdasheryId] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](250) NOT NULL,
	[Description] [nvarchar](4000) NULL,
	[CostToManufacture] [money] NULL,
	[RetailPrice] [money] NULL,
	[QuantityManufactured] [int] NOT NULL,
	[Photo] [nvarchar](500) NULL,
 CONSTRAINT [PK_Haberdashery] PRIMARY KEY CLUSTERED 
(
	[HaberdasheryId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Kennels].[Mismanagement]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Kennels].[Mismanagement]') AND type in (N'U'))
BEGIN
CREATE TABLE [Kennels].[Mismanagement](
	[MismanagementId] [uniqueidentifier] NOT NULL,
	[HasherId] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[MismanagementEnumId] [smallint] NOT NULL,
	[EffectiveFrom] [date] NULL,
	[EffectiveTo] [date] NULL,
 CONSTRAINT [PK_Mismanagement] PRIMARY KEY CLUSTERED 
(
	[MismanagementId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Transactions].[EventRegistration]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Transactions].[EventRegistration]') AND type in (N'U'))
BEGIN
CREATE TABLE [Transactions].[EventRegistration](
	[EventRegistrationId] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NOT NULL,
	[EventParticipantId] [uniqueidentifier] NULL,
	[HasherId] [uniqueidentifier] NOT NULL,
	[DateRegistered] [datetime] NOT NULL,
	[RegistrationNotes] [nvarchar](2000) NULL,
 CONSTRAINT [PK_EventRegistration] PRIMARY KEY CLUSTERED 
(
	[EventRegistrationId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [Transactions].[HaberdasherySale]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Transactions].[HaberdasherySale]') AND type in (N'U'))
BEGIN
CREATE TABLE [Transactions].[HaberdasherySale](
	[HaberdasherySaleId] [uniqueidentifier] NOT NULL,
	[HaberdasheryId] [uniqueidentifier] NOT NULL,
	[HasherId] [uniqueidentifier] NULL,
	[SaleAmount] [money] NULL,
 CONSTRAINT [PK_HaberdasherySale] PRIMARY KEY CLUSTERED 
(
	[HaberdasherySaleId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [UNUSED].[FeaturedEvent]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[FeaturedEvent]') AND type in (N'U'))
BEGIN
CREATE TABLE [UNUSED].[FeaturedEvent](
	[id] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NOT NULL,
	[StartDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_FeaturedEvent] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [UNUSED].[FeaturedKennel]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[FeaturedKennel]') AND type in (N'U'))
BEGIN
CREATE TABLE [UNUSED].[FeaturedKennel](
	[id] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[StartDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_FeaturedKennel] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [UNUSED].[FeaturedSong]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[FeaturedSong]') AND type in (N'U'))
BEGIN
CREATE TABLE [UNUSED].[FeaturedSong](
	[id] [uniqueidentifier] NOT NULL,
	[SongId] [uniqueidentifier] NOT NULL,
	[StartDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_FeaturedSong] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [UNUSED].[Haberdashery]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[Haberdashery]') AND type in (N'U'))
BEGIN
CREATE TABLE [UNUSED].[Haberdashery](
	[id] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NULL,
	[ItemName] [nvarchar](120) NOT NULL,
	[Description] [nvarchar](500) NULL,
	[Price] [smallmoney] NOT NULL,
	[CurrencyCulture] [nvarchar](50) NULL,
	[SizesAvailable] [nvarchar](2000) NULL,
	[ImageUrl] [nvarchar](500) NULL,
	[ReverseSideImageUrl] [nvarchar](500) NULL,
	[InStock] [smallint] NOT NULL,
	[Archive] [smallint] NOT NULL,
	[ShowOnHomePage] [smallint] NOT NULL,
 CONSTRAINT [PK_Haberdashery_1] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [UNUSED].[KennelSongMap]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[KennelSongMap]') AND type in (N'U'))
BEGIN
CREATE TABLE [UNUSED].[KennelSongMap](
	[id] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[SongId] [uniqueidentifier] NOT NULL,
	[Following] [smallint] NOT NULL,
 CONSTRAINT [PK_KennelSongMap] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [UNUSED].[Song]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[Song]') AND type in (N'U'))
BEGIN
CREATE TABLE [UNUSED].[Song](
	[id] [uniqueidentifier] NOT NULL,
	[SongName] [nvarchar](120) NOT NULL,
	[TuneOf] [nvarchar](500) NULL,
	[BawdyRating] [smallint] NOT NULL,
	[Notes] [nvarchar](max) NULL,
	[Actions] [nvarchar](max) NULL,
	[Variants] [nvarchar](max) NULL,
	[ImageUrl] [nvarchar](500) NULL,
	[AudioUrl] [nvarchar](500) NULL,
	[AutoAddToKennel] [smallint] NOT NULL,
	[Rank] [smallint] NOT NULL,
	[AddedBy_KennelId] [uniqueidentifier] NULL,
	[AddedBy_UserId] [uniqueidentifier] NULL,
	[Lyrics] [nvarchar](max) NOT NULL,
	[Tags] [nvarchar](max) NULL,
 CONSTRAINT [PK__Song__3213E83F1B3241A3] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
END
GO
/****** Object:  Table [WORDZ].[WordFreq]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[WORDZ].[WordFreq]') AND type in (N'U'))
BEGIN
CREATE TABLE [WORDZ].[WordFreq](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Word] [nvarchar](255) NULL,
	[Count] [int] NULL,
	[Source] [varchar](20) NULL,
	[Rank] [int] NULL,
 CONSTRAINT [PK_WordFreq] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [WORDZ].[Wordz]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[WORDZ].[Wordz]') AND type in (N'U'))
BEGIN
CREATE TABLE [WORDZ].[Wordz](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[EnglishOriginal] [nvarchar](255) NULL,
	[English] [nvarchar](255) NULL,
	[Type] [nvarchar](255) NULL,
	[GermanOriginal] [nvarchar](255) NULL,
	[FrenchOriginal] [nvarchar](255) NULL,
	[DutchOriginal] [nvarchar](255) NULL,
	[Dutch] [nvarchar](255) NULL,
	[DutchBase] [nvarchar](255) NULL,
	[DutchFreq] [int] NULL,
	[DutchAudioFile] [nvarchar](255) NULL,
 CONSTRAINT [PK_Wordz] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
END
GO
/****** Object:  Table [WORDZ].[WordzAudio]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[WORDZ].[WordzAudio]') AND type in (N'U'))
BEGIN
CREATE TABLE [WORDZ].[WordzAudio](
	[fileName] [nvarchar](255) NULL,
	[DutchBase] [nvarchar](255) NULL
) ON [PRIMARY]
END
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Exceptions_App_Del_Cre]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Exceptions]') AND name = N'IX_Exceptions_App_Del_Cre')
CREATE NONCLUSTERED INDEX [IX_Exceptions_App_Del_Cre] ON [dbo].[Exceptions]
(
	[ApplicationName] ASC,
	[DeletionDate] ASC,
	[CreationDate] DESC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Exceptions_GUID_App_Del_Cre]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Exceptions]') AND name = N'IX_Exceptions_GUID_App_Del_Cre')
CREATE NONCLUSTERED INDEX [IX_Exceptions_GUID_App_Del_Cre] ON [dbo].[Exceptions]
(
	[GUID] ASC,
	[ApplicationName] ASC,
	[DeletionDate] ASC,
	[CreationDate] DESC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Exceptions_Hash_App_Cre_Del]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Exceptions]') AND name = N'IX_Exceptions_Hash_App_Cre_Del')
CREATE NONCLUSTERED INDEX [IX_Exceptions_Hash_App_Cre_Del] ON [dbo].[Exceptions]
(
	[ErrorHash] ASC,
	[ApplicationName] ASC,
	[CreationDate] DESC,
	[DeletionDate] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_RolePerm_RoleId_PermKey]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[RolePermissions]') AND name = N'UQ_RolePerm_RoleId_PermKey')
CREATE UNIQUE NONCLUSTERED INDEX [UQ_RolePerm_RoleId_PermKey] ON [dbo].[RolePermissions]
(
	[RoleId] ASC,
	[PermissionKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_UserPerm_UserId_PermKey]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[UserPermissions]') AND name = N'UQ_UserPerm_UserId_PermKey')
CREATE UNIQUE NONCLUSTERED INDEX [UQ_UserPerm_UserId_PermKey] ON [dbo].[UserPermissions]
(
	[UserId] ASC,
	[PermissionKey] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_UserPref_UID_PrefType_Name]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[UserPreferences]') AND name = N'IX_UserPref_UID_PrefType_Name')
CREATE UNIQUE NONCLUSTERED INDEX [IX_UserPref_UID_PrefType_Name] ON [dbo].[UserPreferences]
(
	[UserId] ASC,
	[PreferenceType] ASC,
	[Name] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_UserRoles_RoleId_UserId]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[UserRoles]') AND name = N'IX_UserRoles_RoleId_UserId')
CREATE NONCLUSTERED INDEX [IX_UserRoles_RoleId_UserId] ON [dbo].[UserRoles]
(
	[RoleId] ASC,
	[UserId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [UQ_UserRoles_UserId_RoleId]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[UserRoles]') AND name = N'UQ_UserRoles_UserId_RoleId')
CREATE UNIQUE NONCLUSTERED INDEX [UQ_UserRoles_UserId_RoleId] ON [dbo].[UserRoles]
(
	[UserId] ASC,
	[RoleId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_UserUniqueEmail]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND name = N'IX_UserUniqueEmail')
CREATE UNIQUE NONCLUSTERED INDEX [IX_UserUniqueEmail] ON [dbo].[Users]
(
	[Email] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_CityUpdated]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[HC].[City]') AND name = N'IX_CityUpdated')
CREATE NONCLUSTERED INDEX [IX_CityUpdated] ON [HC].[City]
(
	[updatedAt] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_CountryUpdated]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[HC].[Country]') AND name = N'IX_CountryUpdated')
CREATE NONCLUSTERED INDEX [IX_CountryUpdated] ON [HC].[Country]
(
	[updatedAt] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [i1]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[HC].[ErrorLog]') AND name = N'i1')
CREATE NONCLUSTERED INDEX [i1] ON [HC].[ErrorLog]
(
	[updatedAt] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_Event_KidIsCountedDeleted2]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[HC].[Event]') AND name = N'IX_Event_KidIsCountedDeleted2')
CREATE NONCLUSTERED INDEX [IX_Event_KidIsCountedDeleted2] ON [HC].[Event]
(
	[KennelId] ASC,
	[IsCountedRun] ASC,
	[deleted] ASC
)
INCLUDE([AbsoluteEventNumber]) WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_EventByKennelIsCountedStartDateAbsEvtNum]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[HC].[Event]') AND name = N'IX_EventByKennelIsCountedStartDateAbsEvtNum')
CREATE NONCLUSTERED INDEX [IX_EventByKennelIsCountedStartDateAbsEvtNum] ON [HC].[Event]
(
	[KennelId] ASC,
	[IsCountedRun] ASC,
	[EventStartDatetime] ASC,
	[AbsoluteEventNumber] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_HasherUniqueEmail]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[HC].[Hasher]') AND name = N'IX_HasherUniqueEmail')
CREATE UNIQUE NONCLUSTERED INDEX [IX_HasherUniqueEmail] ON [HC].[Hasher]
(
	[Email] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_HasherEventMap]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[HC].[HasherEventMap]') AND name = N'IX_HasherEventMap')
CREATE NONCLUSTERED INDEX [IX_HasherEventMap] ON [HC].[HasherEventMap]
(
	[EventId] ASC,
	[UserId] ASC,
	[DisplayName] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_HasherFriendMap]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[HC].[HasherFriendMap]') AND name = N'IX_HasherFriendMap')
CREATE UNIQUE NONCLUSTERED INDEX [IX_HasherFriendMap] ON [HC].[HasherFriendMap]
(
	[UserId] ASC,
	[Friend_UserId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_HasherKennelMap]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[HC].[HasherKennelMap]') AND name = N'IX_HasherKennelMap')
CREATE UNIQUE NONCLUSTERED INDEX [IX_HasherKennelMap] ON [HC].[HasherKennelMap]
(
	[KennelId] ASC,
	[UserId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_PaymentReference]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[HC].[Payment]') AND name = N'IX_PaymentReference')
CREATE UNIQUE NONCLUSTERED INDEX [IX_PaymentReference] ON [HC].[Payment]
(
	[PaymentReference] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_RegionUpdated]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[HC].[Region]') AND name = N'IX_RegionUpdated')
CREATE NONCLUSTERED INDEX [IX_RegionUpdated] ON [HC].[Region]
(
	[updatedAt] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Object:  Index [IX_KennelSongMap]    Script Date: 7/2/2021 4:18:14 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[UNUSED].[KennelSongMap]') AND name = N'IX_KennelSongMap')
CREATE UNIQUE NONCLUSTERED INDEX [IX_KennelSongMap] ON [UNUSED].[KennelSongMap]
(
	[KennelId] ASC,
	[SongId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_BusinessUnits_id]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[BusinessUnits] ADD  CONSTRAINT [DF_BusinessUnits_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__BusinessU__delet__793DFFAF]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[BusinessUnits] ADD  CONSTRAINT [DF__BusinessU__delet__793DFFAF]  DEFAULT ((0)) FOR [deleted]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__BusinessU__creat__01D345B0]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[BusinessUnits] ADD  CONSTRAINT [DF__BusinessU__creat__01D345B0]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__BusinessU__updat__02C769E9]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[BusinessUnits] ADD  CONSTRAINT [DF__BusinessU__updat__02C769E9]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_Exceptions_IsProtected]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[Exceptions] ADD  CONSTRAINT [DF_Exceptions_IsProtected]  DEFAULT ((1)) FOR [IsProtected]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_Exceptions_DuplicateCount]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[Exceptions] ADD  CONSTRAINT [DF_Exceptions_DuplicateCount]  DEFAULT ((1)) FOR [DuplicateCount]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__Meetings__delete__7A3223E8]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[Meetings] ADD  DEFAULT ((0)) FOR [deleted]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__Meetings__create__05A3D694]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[Meetings] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__Meetings__update__0697FACD]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[Meetings] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_UserPermissions_Grant]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[UserPermissions] ADD  CONSTRAINT [DF_UserPermissions_Grant]  DEFAULT ((1)) FOR [Granted]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF_Users_IsActive]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_IsActive]  DEFAULT ((1)) FOR [IsActive]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__world_citi__city__160F4887]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [city]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__world_cit__city___17036CC0]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [city_ascii]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__world_citie__lat__17F790F9]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [lat]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__world_citie__lng__18EBB532]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [lng]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__world_citie__pop__19DFD96B]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [pop]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__world_cit__count__1AD3FDA4]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [country]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__world_citi__iso2__1BC821DD]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [iso2]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__world_citi__iso3__1CBC4616]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [iso3]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DF__world_cit__provi__1DB06A4F]') AND type = 'D')
BEGIN
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [province]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[DF_FbAppEvent_FbAppEventId]') AND type = 'D')
BEGIN
ALTER TABLE [EXT].[FbAppEvent] ADD  CONSTRAINT [DF_FbAppEvent_FbAppEventId]  DEFAULT (newid()) FOR [FbAppEventId]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[DF_FbAppEvent_updatedAt]') AND type = 'D')
BEGIN
ALTER TABLE [EXT].[FbAppEvent] ADD  CONSTRAINT [DF_FbAppEvent_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[DF_KennelImport_KennelId2]') AND type = 'D')
BEGIN
ALTER TABLE [EXT].[OfficeForms_KennelImport] ADD  CONSTRAINT [DF_KennelImport_KennelId2]  DEFAULT (newid()) FOR [KennelImportId]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[DF_OfficeForms_KennelImport_MapPinColor]') AND type = 'D')
BEGIN
ALTER TABLE [EXT].[OfficeForms_KennelImport] ADD  CONSTRAINT [DF_OfficeForms_KennelImport_MapPinColor]  DEFAULT (N'Blue') FOR [KennelPinColor]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[DF_OfficeForms_KennelImport_IsRunningPostCovid]') AND type = 'D')
BEGIN
ALTER TABLE [EXT].[OfficeForms_KennelImport] ADD  CONSTRAINT [DF_OfficeForms_KennelImport_IsRunningPostCovid]  DEFAULT (N'Unknown') FOR [IsRunningPostCovid]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[DF_OfficeForms_KennelImport_NumberOfRunsPerMonth]') AND type = 'D')
BEGIN
ALTER TABLE [EXT].[OfficeForms_KennelImport] ADD  CONSTRAINT [DF_OfficeForms_KennelImport_NumberOfRunsPerMonth]  DEFAULT (N'Unknown') FOR [NumberOfRunsPerMonth]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[DF_OfficeForms_KennelImport_NumberOfHashersPerRun]') AND type = 'D')
BEGIN
ALTER TABLE [EXT].[OfficeForms_KennelImport] ADD  CONSTRAINT [DF_OfficeForms_KennelImport_NumberOfHashersPerRun]  DEFAULT (N'Unknown') FOR [NumberOfHashersPerRun]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[DF_OfficeForms_KennelImport_WhenStartRunningPostCovid]') AND type = 'D')
BEGIN
ALTER TABLE [EXT].[OfficeForms_KennelImport] ADD  CONSTRAINT [DF_OfficeForms_KennelImport_WhenStartRunningPostCovid]  DEFAULT (N'Unknown') FOR [WhenStartRunningPostCovid]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[DF_OfficeForms_KennelImport_SubmittedOn]') AND type = 'D')
BEGIN
ALTER TABLE [EXT].[OfficeForms_KennelImport] ADD  CONSTRAINT [DF_OfficeForms_KennelImport_SubmittedOn]  DEFAULT (getdate()) FOR [SubmittedOn]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[DF_Zapier_FbEvent_zapierFbEventId]') AND type = 'D')
BEGIN
ALTER TABLE [EXT].[Zapier_FbEvent] ADD  CONSTRAINT [DF_Zapier_FbEvent_zapierFbEventId]  DEFAULT (newid()) FOR [zapierFbEventId]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[DF_Zapier_zapierId]') AND type = 'D')
BEGIN
ALTER TABLE [EXT].[Zapier_GCal] ADD  CONSTRAINT [DF_Zapier_zapierId]  DEFAULT (newid()) FOR [zapierGcalId]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Hashers].[DF__HasherEve__creat__61BC4730]') AND type = 'D')
BEGIN
ALTER TABLE [Hashers].[HasherEventMap] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Hashers].[DF__HasherEve__updat__62B06B69]') AND type = 'D')
BEGIN
ALTER TABLE [Hashers].[HasherEventMap] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Hashers].[DF__HasherEve__delet__63A48FA2]') AND type = 'D')
BEGIN
ALTER TABLE [Hashers].[HasherEventMap] ADD  DEFAULT ((0)) FOR [deleted]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Hashers].[DF__HasherFri__creat__67752086]') AND type = 'D')
BEGIN
ALTER TABLE [Hashers].[HasherFriendMap] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Hashers].[DF__HasherFri__updat__686944BF]') AND type = 'D')
BEGIN
ALTER TABLE [Hashers].[HasherFriendMap] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Hashers].[DF__HasherFri__delet__695D68F8]') AND type = 'D')
BEGIN
ALTER TABLE [Hashers].[HasherFriendMap] ADD  DEFAULT ((0)) FOR [deleted]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__BusinessU__creat__5C036DDA]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[BusinessUnits] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__BusinessU__updat__5CF79213]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[BusinessUnits] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__BusinessU__delet__5DEBB64C]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[BusinessUnits] ADD  DEFAULT ((0)) FOR [deleted]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_City_id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[City] ADD  CONSTRAINT [DF_City_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_City_UseCityFullName]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[City] ADD  CONSTRAINT [DF_City_UseCityFullName]  DEFAULT ((0)) FOR [ShowRegion]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_City_Removed]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[City] ADD  CONSTRAINT [DF_City_Removed]  DEFAULT ((0)) FOR [Removed]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_City_updatedAt]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[City] ADD  CONSTRAINT [DF_City_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Country_CountryId]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_CountryId]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Country_PrimaryCultureCode]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_PrimaryCultureCode]  DEFAULT (N'en-US') FOR [PrimaryCultureCode]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Country_ShowRegion]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_ShowRegion]  DEFAULT ((0)) FOR [ShowRegion]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Country_CurrencySymbol]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_CurrencySymbol]  DEFAULT (' ') FOR [CurrencySymbol]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Country_DigitsAfterDecimal]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_DigitsAfterDecimal]  DEFAULT ((2)) FOR [DigitsAfterDecimal]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Country_DistancePreference]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_DistancePreference]  DEFAULT ((0)) FOR [DistancePreference]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Country_Removed]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_Removed]  DEFAULT ((0)) FOR [Removed]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Country_updatedAt]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_EmailLog_id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailLog] ADD  CONSTRAINT [DF_EmailLog_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_EmailLog_NumberSent]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailLog] ADD  CONSTRAINT [DF_EmailLog_NumberSent]  DEFAULT ((0)) FOR [NumberSent]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_EmailTemplate_id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailTemplate] ADD  CONSTRAINT [DF_EmailTemplate_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_EmailTemplate_Description]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailTemplate] ADD  CONSTRAINT [DF_EmailTemplate_Description]  DEFAULT ('Email template') FOR [Description]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_EmailTemplate_EmailTypeFlag]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailTemplate] ADD  CONSTRAINT [DF_EmailTemplate_EmailTypeFlag]  DEFAULT ((1)) FOR [EmailTypeFlag]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_EmailTemplate_HoursBeforeRun]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailTemplate] ADD  CONSTRAINT [DF_EmailTemplate_HoursBeforeRun]  DEFAULT ((12)) FOR [HoursBeforeRun]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_EmailTemplate_DaysBeforeRun]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailTemplate] ADD  CONSTRAINT [DF_EmailTemplate_DaysBeforeRun]  DEFAULT ((3)) FOR [DaysBeforeRun]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_EmailTemplate_SendToAll]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailTemplate] ADD  CONSTRAINT [DF_EmailTemplate_SendToAll]  DEFAULT ((1)) FOR [SendToAll]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Table_1_SendToMembersOnly]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailTemplate] ADD  CONSTRAINT [DF_Table_1_SendToMembersOnly]  DEFAULT ((0)) FOR [SendToMembers]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_EmailTemplate_SendToMismanagement]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailTemplate] ADD  CONSTRAINT [DF_EmailTemplate_SendToMismanagement]  DEFAULT ((0)) FOR [SendToMismanagement]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_EmailTemplate_SendToFollowers]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailTemplate] ADD  CONSTRAINT [DF_EmailTemplate_SendToFollowers]  DEFAULT ((0)) FOR [SendToFollowers]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_EmailTemplate_SendToVisitors]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailTemplate] ADD  CONSTRAINT [DF_EmailTemplate_SendToVisitors]  DEFAULT ((0)) FOR [SendToVisitors]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_EmailTemplate_ReplyToEmailAddress]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailTemplate] ADD  CONSTRAINT [DF_EmailTemplate_ReplyToEmailAddress]  DEFAULT ('noreply@harriercentral.com') FOR [ReplyToEmailAddress]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_EmailTemplate_SenderName]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailTemplate] ADD  CONSTRAINT [DF_EmailTemplate_SenderName]  DEFAULT ('') FOR [SenderName]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_EmailTemplate_SendWhenHareAssigned]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[EmailTemplate] ADD  CONSTRAINT [DF_EmailTemplate_SendWhenHareAssigned]  DEFAULT ((0)) FOR [SendWhenHareAssigned]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_ErrorLog_HasherId]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[ErrorLog] ADD  CONSTRAINT [DF_ErrorLog_HasherId]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_ErrorLog_HcVersion]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[ErrorLog] ADD  CONSTRAINT [DF_ErrorLog_HcVersion]  DEFAULT (N'pre 0.6.4') FOR [HcVersion]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_ErrorLog_createdA__2AC04CAA]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[ErrorLog] ADD  CONSTRAINT [DF_ErrorLog_createdA__2AC04CAA]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_ErrorLog_updatedA__2BB470E3]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[ErrorLog] ADD  CONSTRAINT [DF_ErrorLog_updatedA__2BB470E3]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_ErrorLog_deleted__2CA8951C]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[ErrorLog] ADD  CONSTRAINT [DF_ErrorLog_deleted__2CA8951C]  DEFAULT ((0)) FOR [deleted]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HC_Event_EventId]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_HC_Event_EventId]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_IsVisible]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_IsVisible]  DEFAULT ((1)) FOR [IsVisible]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_IsCountedRun]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_IsCountedRun]  DEFAULT ((1)) FOR [IsCountedRun]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_IsPromotedRun]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_IsPromotedRun]  DEFAULT ((0)) FOR [IsPromotedEvent]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_EventGeographicScope]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_EventGeographicScope]  DEFAULT ((0)) FOR [EventGeographicScope]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HC_Event_IsThemeRun]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_HC_Event_IsThemeRun]  DEFAULT ((0)) FOR [ThemeRunType]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_Tags1]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_Tags1]  DEFAULT ((0)) FOR [Tags1]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_Tags2]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_Tags2]  DEFAULT ((0)) FOR [Tags2]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_Tags3]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_Tags3]  DEFAULT ((0)) FOR [Tags3]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_EventNumber]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_EventNumber]  DEFAULT ((0)) FOR [EventNumber]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_RunCount]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_RunCount]  DEFAULT ((1)) FOR [EventNumberIncrement]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_DoTrackHashCash]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_DoTrackHashCash]  DEFAULT ((0)) FOR [DoTrackHashCash]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_UnconfirmedBankXferCount]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_UnconfirmedBankXferCount]  DEFAULT ((0)) FOR [UnconfirmedBankXferCount]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_UserCountIncrement]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_UserCountIncrement]  DEFAULT ((1)) FOR [UserEventCounterIncrement]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HC_Event_MinimumRequired]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_HC_Event_MinimumRequired]  DEFAULT ((1)) FOR [MinimumParticipantsRequired]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_CanEditRunAttendence]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_CanEditRunAttendence]  DEFAULT ((1)) FOR [CanEditRunAttendence]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_UseFbData]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_UseFbData]  DEFAULT ((0)) FOR [UseFbRunDetails]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_UseFbLocation]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_UseFbLocation]  DEFAULT ((0)) FOR [UseFbLocation]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_UseFbLatLon]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_UseFbLatLon]  DEFAULT ((0)) FOR [UseFbLatLon]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_UpdateDataFromFacebook]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_UpdateDataFromFacebook]  DEFAULT ((0)) FOR [UpdateDataFromFacebook]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_EventSource]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_EventSource]  DEFAULT (N'Unknown') FOR [EventSource]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_removed]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_removed]  DEFAULT ((0)) FOR [removed]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__Event__deleted__22CA2527]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF__Event__deleted__22CA2527]  DEFAULT ((0)) FOR [deleted]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Event_lastModified]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_lastModified]  DEFAULT (getdate()) FOR [lastModified]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__Event__createdAt__414EAC47]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF__Event__createdAt__414EAC47]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__Event__updatedAt__4242D080]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF__Event__updatedAt__4242D080]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Hasher_HasherId]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_HasherId]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Hasher_SupportCode]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_SupportCode]  DEFAULT (N'#####') FOR [SupportCode]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Hasher_ResetCode]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_ResetCode]  DEFAULT (N'######') FOR [ResetCode]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Hasher_QR_code]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_QR_code]  DEFAULT (N'######') FOR [QR_code]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Hasher_QR_secret_code]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_QR_secret_code]  DEFAULT (newid()) FOR [QR_secret_code]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Hasher_HomeLatitude]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_HomeLatitude]  DEFAULT ((51.5033)) FOR [HomeLatitude]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Hasher_HomeLongitude]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_HomeLongitude]  DEFAULT ((0.1195)) FOR [HomeLongitude]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Hasher_NameDisplayPreference]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_NameDisplayPreference]  DEFAULT ((1)) FOR [NameDisplayPreference]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Hasher_Preferences]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_Preferences]  DEFAULT ((0)) FOR [Preferences]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Hasher_IncludeInGlobalHashDirectory]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_IncludeInGlobalHashDirectory]  DEFAULT ((0)) FOR [IncludeInGlobalHashDirectory]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Hasher_Removed]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_Removed]  DEFAULT ((0)) FOR [Removed]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__Hasher__createdA__2AC04CAA]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF__Hasher__createdA__2AC04CAA]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__Hasher__updatedA__2BB470E3]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF__Hasher__updatedA__2BB470E3]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__Hasher__deleted__2CA8951C]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF__Hasher__deleted__2CA8951C]  DEFAULT ((0)) FOR [deleted]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherEventMap_HasherEventMapId]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_HasherEventMapId]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherEventMap_RsvpState]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_RsvpState]  DEFAULT ((0)) FOR [RsvpState]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherEventMap_AttendenceState]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_AttendenceState]  DEFAULT ((0)) FOR [AttendenceState]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__HasherEve__IsHar__6E565CE8]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF__HasherEve__IsHar__6E565CE8]  DEFAULT ((0)) FOR [IsHare]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherEventMap_IsVirgin]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_IsVirgin]  DEFAULT ((0)) FOR [VirginVisitorType]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherEventMap_removed]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_removed]  DEFAULT ((0)) FOR [removed]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherEventMap_updatedAt]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherFriendMap_Id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherFriendMap] ADD  CONSTRAINT [DF_HasherFriendMap_Id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherFriendMap_FriendNotificationPreference]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherFriendMap] ADD  CONSTRAINT [DF_HasherFriendMap_FriendNotificationPreference]  DEFAULT ((0)) FOR [FriendNotificationPreference]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherFriendMap_State]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherFriendMap] ADD  CONSTRAINT [DF_HasherFriendMap_State]  DEFAULT ((0)) FOR [Ignore]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_HasherId]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_HasherId]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_Following]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_Following]  DEFAULT ((1)) FOR [Following]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_State]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_State]  DEFAULT ((0)) FOR [IsMember]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_IsInPack]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_IsInPack]  DEFAULT ((0)) FOR [IsKennelFollowing]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_IsHomeKennel]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_IsHomeKennel]  DEFAULT ((0)) FOR [IsHomeKennel]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_KennelNotificationPreference]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_KennelNotificationPreference]  DEFAULT ((0)) FOR [KennelNotificationPreference]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_KennelEmailPreferences]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_KennelEmailPreferences]  DEFAULT ((0)) FOR [KennelEmailAlertPreference]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_MismanagementRoles]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_MismanagementRoles]  DEFAULT ((0)) FOR [MismanagementRoles]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_IsMismanagement]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_IsMismanagement]  DEFAULT ((0)) FOR [MismanagementRoleFlags]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_HcWebPermissionFlags]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_HcWebPermissionFlags]  DEFAULT ((0)) FOR [HcWebPermissionFlags]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_UserRoleFlags]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_UserRoleFlags]  DEFAULT ((0)) FOR [UserRoleFlags]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_AppAccessFlags]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_AppAccessFlags]  DEFAULT ((0)) FOR [AppAccessFlags]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_HistoricalRunCount]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_HistoricalRunCount]  DEFAULT ((0)) FOR [HistoricalPackRunCount]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_HistoricalHaringCount]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_HistoricalHaringCount]  DEFAULT ((0)) FOR [HistoricalHaringCount]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_HistoricalCountIsEstimate]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_HistoricalCountIsEstimate]  DEFAULT ((0)) FOR [HistoricalCountIsEstimate]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_CurrentPackRunCount]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_CurrentPackRunCount]  DEFAULT ((0)) FOR [CurrentPackRunCount]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_CurrentHaringCount]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_CurrentHaringCount]  DEFAULT ((0)) FOR [CurrentHaringCount]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_MemberSince]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_MemberSince]  DEFAULT (getdate()) FOR [MemberSince]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_CanEditRunAttendence]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_CanEditRunAttendence]  DEFAULT ((1)) FOR [CanEditRunAttendence]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_removed]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_removed]  DEFAULT ((0)) FOR [removed]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherKennelMap_updatedAt]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherOwnEvent_id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherOwnEvent] ADD  CONSTRAINT [DF_HasherOwnEvent_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherOwnEvent_removed]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherOwnEvent] ADD  CONSTRAINT [DF_HasherOwnEvent_removed]  DEFAULT ((0)) FOR [removed]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherOwnEvent_deleted]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherOwnEvent] ADD  CONSTRAINT [DF_HasherOwnEvent_deleted]  DEFAULT ((0)) FOR [deleted]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherOwnEvent_lastModified]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherOwnEvent] ADD  CONSTRAINT [DF_HasherOwnEvent_lastModified]  DEFAULT (getdate()) FOR [lastModified]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_HasherOwnEvent_updatedAt]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[HasherOwnEvent] ADD  CONSTRAINT [DF_HasherOwnEvent_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_KennelStatus]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_KennelStatus]  DEFAULT ((1)) FOR [KennelStatus]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_IntegrationType]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_IntegrationType]  DEFAULT (N'None') FOR [IntegrationType]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_KennelFacebookImportDaysInPast]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_KennelFacebookImportDaysInPast]  DEFAULT ((4)) FOR [IntegrationImportDaysInPast]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_KennelFacebookImportDaysInFuture]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_KennelFacebookImportDaysInFuture]  DEFAULT ((90)) FOR [IntegrationImportDaysInFuture]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_AutoImportFacebookEvents]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_AutoImportFacebookEvents]  DEFAULT ((0)) FOR [IntegrationAutoImportEvents]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_ImportOnlyTaggedEvents]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_ImportOnlyTaggedEvents]  DEFAULT ((0)) FOR [IntegrationImportOnlyTaggedEvents]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_PublishToGoogleCalendar]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_PublishToGoogleCalendar]  DEFAULT ((0)) FOR [PublishToGoogleCalendar]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_CanEditRunAttendence]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_CanEditRunAttendence]  DEFAULT ((1)) FOR [CanEditRunAttendence]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_KennelLogo]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_KennelLogo]  DEFAULT (N'bundle://defaultKennelLogo') FOR [KennelLogo]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_KennelPinColor]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_KennelPinColor]  DEFAULT ((0)) FOR [KennelPinColor]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_KennelMismanagementTeam]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_KennelMismanagementTeam]  DEFAULT ('<none listed>') FOR [KennelMismanagementTeam]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_DefaultEventPriceForNonMembers]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_DefaultEventPriceForNonMembers]  DEFAULT ((0)) FOR [DefaultEventPriceForNonMembers]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_DefaultRunStartTime]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_DefaultRunStartTime]  DEFAULT ('12:00:00.0000000') FOR [DefaultRunStartTime]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_AllowSelfPayment]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_AllowSelfPayment]  DEFAULT ((1)) FOR [AllowSelfPayment]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_AllowNegativeCredit]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_AllowNegativeCredit]  DEFAULT ((0)) FOR [AllowNegativeCredit]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_MembershipDurationInMonths]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_MembershipDurationInMonths]  DEFAULT ((12)) FOR [MembershipDurationInMonths]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Kennel_removed]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_removed]  DEFAULT ((0)) FOR [removed]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__Kennel__createdA__338A9CD5]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF__Kennel__createdA__338A9CD5]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__Kennel__updatedA__347EC10E]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF__Kennel__updatedA__347EC10E]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__Kennel__deleted__3572E547]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF__Kennel__deleted__3572E547]  DEFAULT ((0)) FOR [deleted]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelAuthorization_id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelAuthorization_AutoFacebookEventImport]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_AutoFacebookEventImport]  DEFAULT ((0)) FOR [Auth_FacebookIntegration]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelAuthorization_TrackPayments]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_TrackPayments]  DEFAULT ((0)) FOR [Auth_TrackPayments]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelAuthorization_Haberdashery]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_Haberdashery]  DEFAULT ((0)) FOR [Auth_Haberdashery]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelAuthorization_CustomSongbook]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_CustomSongbook]  DEFAULT ((0)) FOR [Auth_CustomSongbook]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelAuthorization_WebsiteIntegration]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_WebsiteIntegration]  DEFAULT ((0)) FOR [Auth_WebsiteIntegration]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelAuthorization_AllowCredit]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_AllowCredit]  DEFAULT ((0)) FOR [Auth_AllowCredit]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelAuthorization_PushNotifications]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_PushNotifications]  DEFAULT ((0)) FOR [Auth_PushNotifications]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelAuthorization_CheckInAndOut]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_CheckInAndOut]  DEFAULT ((0)) FOR [Auth_CheckInAndOut]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelAuthorization_PromoteEvents]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_PromoteEvents]  DEFAULT ((0)) FOR [Auth_PromoteEvents]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelAuthorization_CustomLogo]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_CustomLogo]  DEFAULT ((0)) FOR [Auth_CustomLogo]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelAuthorization_AuthorizationAmount]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_AuthorizationAmount]  DEFAULT ((10)) FOR [Auth_MembersAllowed]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelAuthorization_HareRaisingManagement]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_HareRaisingManagement]  DEFAULT ((0)) FOR [Auth_HareRaisingManagement]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelAuthorization_StartDate]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_StartDate]  DEFAULT (getdate()) FOR [StartDate]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelCredit_id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelCredit] ADD  CONSTRAINT [DF_KennelCredit_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_KennelCredit_removed]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[KennelCredit] ADD  CONSTRAINT [DF_KennelCredit_removed]  DEFAULT ((0)) FOR [removed]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_LaunchAndLogin_id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[LaunchAndLogin] ADD  CONSTRAINT [DF_LaunchAndLogin_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_LaunchAndLogin_DateAndTime]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[LaunchAndLogin] ADD  CONSTRAINT [DF_LaunchAndLogin_DateAndTime]  DEFAULT (getdate()) FOR [LoginDate]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_LaunchAndLogin_HcVersion]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[LaunchAndLogin] ADD  CONSTRAINT [DF_LaunchAndLogin_HcVersion]  DEFAULT (N'pre 0.6.4') FOR [HcVersion]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_ServerMaintenanceWindow_id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[LoginNotifications] ADD  CONSTRAINT [DF_ServerMaintenanceWindow_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_ServerMaintenanceWindow_CreatedDate]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[LoginNotifications] ADD  CONSTRAINT [DF_ServerMaintenanceWindow_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__Meetings__create__6D2DF9DC]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Meetings] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__Meetings__update__6E221E15]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Meetings] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF__Meetings__delete__6F16424E]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Meetings] ADD  DEFAULT ((0)) FOR [deleted]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Payment_id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Payment_CreditAmount]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_CreditAmount]  DEFAULT ((0)) FOR [CreditAmount]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Payment_DebitAmount]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_DebitAmount]  DEFAULT ((0)) FOR [DebitAmount]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Payment_Surcharge]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_Surcharge]  DEFAULT ((0)) FOR [Surcharge]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Payment_PaidDate]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_PaidDate]  DEFAULT (getdate()) FOR [PaidDate]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Payment_ProductType]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_ProductType]  DEFAULT ((1)) FOR [ProductType]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Payment_CreditAvailable]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_CreditAvailable]  DEFAULT ((0)) FOR [CreditAvailable]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Payment_DoPayForExtras]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_DoPayForExtras]  DEFAULT ((0)) FOR [DoPayForExtras]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Payment_removed]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_removed]  DEFAULT ((0)) FOR [removed]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Payment_updatedAt]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Receipt_id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Receipt] ADD  CONSTRAINT [DF_Receipt_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Receipt_CostCategory]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Receipt] ADD  CONSTRAINT [DF_Receipt_CostCategory]  DEFAULT ((0)) FOR [CostCategory]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Receipt_DateUploaded]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Receipt] ADD  CONSTRAINT [DF_Receipt_DateUploaded]  DEFAULT (getdate()) FOR [DateUploaded]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Receipt_removed]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Receipt] ADD  CONSTRAINT [DF_Receipt_removed]  DEFAULT ((0)) FOR [removed]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Receipt_updatedAt]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Receipt] ADD  CONSTRAINT [DF_Receipt_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Region_id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Region] ADD  CONSTRAINT [DF_Region_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Region_Removed]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Region] ADD  CONSTRAINT [DF_Region_Removed]  DEFAULT ((0)) FOR [Removed]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_Region_updatedAt]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[Region] ADD  CONSTRAINT [DF_Region_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_RunCounts_updatedAt]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[RunCounts] ADD  CONSTRAINT [DF_RunCounts_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_ServerStatus_id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[ServerStatus] ADD  CONSTRAINT [DF_ServerStatus_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_ServerStatus_CreatedDate]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[ServerStatus] ADD  CONSTRAINT [DF_ServerStatus_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_ServerStatus_IosDownloadLink]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[ServerStatus] ADD  CONSTRAINT [DF_ServerStatus_IosDownloadLink]  DEFAULT ('') FOR [IosDownloadLink]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_ServerStatus_AndroidDownloadLink]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[ServerStatus] ADD  CONSTRAINT [DF_ServerStatus_AndroidDownloadLink]  DEFAULT ('') FOR [AndroidDownloadLink]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_ServerStatus_ImageRootUrl]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[ServerStatus] ADD  CONSTRAINT [DF_ServerStatus_ImageRootUrl]  DEFAULT ('') FOR [ImageRootUrl]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_WebAppLogin_id]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[WebAppLogin] ADD  CONSTRAINT [DF_WebAppLogin_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[DF_WebAppLogin_LoginSuccessful]') AND type = 'D')
BEGIN
ALTER TABLE [HC].[WebAppLogin] ADD  CONSTRAINT [DF_WebAppLogin_LoginSuccessful]  DEFAULT ((0)) FOR [LoginSuccessful]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Kennels].[DF_Mismanagement_MismanagementId]') AND type = 'D')
BEGIN
ALTER TABLE [Kennels].[Mismanagement] ADD  CONSTRAINT [DF_Mismanagement_MismanagementId]  DEFAULT (newid()) FOR [MismanagementId]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Transactions].[DF_EventRegistration_DateRegistered]') AND type = 'D')
BEGIN
ALTER TABLE [Transactions].[EventRegistration] ADD  CONSTRAINT [DF_EventRegistration_DateRegistered]  DEFAULT (getdate()) FOR [DateRegistered]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[DF_FeaturedEvent_id]') AND type = 'D')
BEGIN
ALTER TABLE [UNUSED].[FeaturedEvent] ADD  CONSTRAINT [DF_FeaturedEvent_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[DF_FeaturedKennel_id]') AND type = 'D')
BEGIN
ALTER TABLE [UNUSED].[FeaturedKennel] ADD  CONSTRAINT [DF_FeaturedKennel_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[DF_FeaturedSong_id]') AND type = 'D')
BEGIN
ALTER TABLE [UNUSED].[FeaturedSong] ADD  CONSTRAINT [DF_FeaturedSong_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[DF_Haberdashery_id]') AND type = 'D')
BEGIN
ALTER TABLE [UNUSED].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[DF_Haberdashery_Price]') AND type = 'D')
BEGIN
ALTER TABLE [UNUSED].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_Price]  DEFAULT ((0)) FOR [Price]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[DF_Haberdashery_InStock]') AND type = 'D')
BEGIN
ALTER TABLE [UNUSED].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_InStock]  DEFAULT ((1)) FOR [InStock]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[DF_Haberdashery_Archive]') AND type = 'D')
BEGIN
ALTER TABLE [UNUSED].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_Archive]  DEFAULT ((0)) FOR [Archive]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[DF_Haberdashery_ShowOnHomePage]') AND type = 'D')
BEGIN
ALTER TABLE [UNUSED].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_ShowOnHomePage]  DEFAULT ((0)) FOR [ShowOnHomePage]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[DF_KennelSongMap_Id]') AND type = 'D')
BEGIN
ALTER TABLE [UNUSED].[KennelSongMap] ADD  CONSTRAINT [DF_KennelSongMap_Id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[DF_KennelSongMap_Following]') AND type = 'D')
BEGIN
ALTER TABLE [UNUSED].[KennelSongMap] ADD  CONSTRAINT [DF_KennelSongMap_Following]  DEFAULT ((1)) FOR [Following]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[DF_Song_id]') AND type = 'D')
BEGIN
ALTER TABLE [UNUSED].[Song] ADD  CONSTRAINT [DF_Song_id]  DEFAULT (newid()) FOR [id]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[DF_Song_Rating]') AND type = 'D')
BEGIN
ALTER TABLE [UNUSED].[Song] ADD  CONSTRAINT [DF_Song_Rating]  DEFAULT ((1)) FOR [BawdyRating]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[DF_Song_AutoAddToKennel]') AND type = 'D')
BEGIN
ALTER TABLE [UNUSED].[Song] ADD  CONSTRAINT [DF_Song_AutoAddToKennel]  DEFAULT ((0)) FOR [AutoAddToKennel]
END
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[UNUSED].[DF_Song_Rank]') AND type = 'D')
BEGIN
ALTER TABLE [UNUSED].[Song] ADD  CONSTRAINT [DF_Song_Rank]  DEFAULT ((0)) FOR [Rank]
END
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Contacts_UserId]') AND parent_object_id = OBJECT_ID(N'[dbo].[Contacts]'))
ALTER TABLE [dbo].[Contacts]  WITH CHECK ADD  CONSTRAINT [FK_Contacts_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Contacts_UserId]') AND parent_object_id = OBJECT_ID(N'[dbo].[Contacts]'))
ALTER TABLE [dbo].[Contacts] CHECK CONSTRAINT [FK_Contacts_UserId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_AgendaRel_AgendaId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingAgendaRelevant]'))
ALTER TABLE [dbo].[MeetingAgendaRelevant]  WITH CHECK ADD  CONSTRAINT [FK_AgendaRel_AgendaId] FOREIGN KEY([AgendaId])
REFERENCES [dbo].[MeetingAgendas] ([AgendaId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_AgendaRel_AgendaId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingAgendaRelevant]'))
ALTER TABLE [dbo].[MeetingAgendaRelevant] CHECK CONSTRAINT [FK_AgendaRel_AgendaId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_AgendaRel_ContactId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingAgendaRelevant]'))
ALTER TABLE [dbo].[MeetingAgendaRelevant]  WITH CHECK ADD  CONSTRAINT [FK_AgendaRel_ContactId] FOREIGN KEY([ContactId])
REFERENCES [dbo].[Contacts] ([ContactId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_AgendaRel_ContactId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingAgendaRelevant]'))
ALTER TABLE [dbo].[MeetingAgendaRelevant] CHECK CONSTRAINT [FK_AgendaRel_ContactId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetAgendas_AgendaTypeId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingAgendas]'))
ALTER TABLE [dbo].[MeetingAgendas]  WITH CHECK ADD  CONSTRAINT [FK_MeetAgendas_AgendaTypeId] FOREIGN KEY([AgendaTypeId])
REFERENCES [dbo].[MeetingAgendaTypes] ([AgendaTypeId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetAgendas_AgendaTypeId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingAgendas]'))
ALTER TABLE [dbo].[MeetingAgendas] CHECK CONSTRAINT [FK_MeetAgendas_AgendaTypeId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetAgendas_MeetingId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingAgendas]'))
ALTER TABLE [dbo].[MeetingAgendas]  WITH CHECK ADD  CONSTRAINT [FK_MeetAgendas_MeetingId] FOREIGN KEY([MeetingId])
REFERENCES [dbo].[Meetings] ([MeetingId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetAgendas_MeetingId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingAgendas]'))
ALTER TABLE [dbo].[MeetingAgendas] CHECK CONSTRAINT [FK_MeetAgendas_MeetingId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetAgendas_RequestedBy]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingAgendas]'))
ALTER TABLE [dbo].[MeetingAgendas]  WITH CHECK ADD  CONSTRAINT [FK_MeetAgendas_RequestedBy] FOREIGN KEY([RequestedByContactId])
REFERENCES [dbo].[Contacts] ([ContactId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetAgendas_RequestedBy]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingAgendas]'))
ALTER TABLE [dbo].[MeetingAgendas] CHECK CONSTRAINT [FK_MeetAgendas_RequestedBy]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetAttendees_ContactId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingAttendees]'))
ALTER TABLE [dbo].[MeetingAttendees]  WITH CHECK ADD  CONSTRAINT [FK_MeetAttendees_ContactId] FOREIGN KEY([ContactId])
REFERENCES [dbo].[Contacts] ([ContactId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetAttendees_ContactId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingAttendees]'))
ALTER TABLE [dbo].[MeetingAttendees] CHECK CONSTRAINT [FK_MeetAttendees_ContactId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetAttendees_MeetingId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingAttendees]'))
ALTER TABLE [dbo].[MeetingAttendees]  WITH CHECK ADD  CONSTRAINT [FK_MeetAttendees_MeetingId] FOREIGN KEY([MeetingId])
REFERENCES [dbo].[Meetings] ([MeetingId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetAttendees_MeetingId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingAttendees]'))
ALTER TABLE [dbo].[MeetingAttendees] CHECK CONSTRAINT [FK_MeetAttendees_MeetingId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DecisionRel_ContactId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingDecisionRelevant]'))
ALTER TABLE [dbo].[MeetingDecisionRelevant]  WITH CHECK ADD  CONSTRAINT [FK_DecisionRel_ContactId] FOREIGN KEY([ContactId])
REFERENCES [dbo].[Contacts] ([ContactId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DecisionRel_ContactId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingDecisionRelevant]'))
ALTER TABLE [dbo].[MeetingDecisionRelevant] CHECK CONSTRAINT [FK_DecisionRel_ContactId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DecisionRel_DecisionId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingDecisionRelevant]'))
ALTER TABLE [dbo].[MeetingDecisionRelevant]  WITH CHECK ADD  CONSTRAINT [FK_DecisionRel_DecisionId] FOREIGN KEY([DecisionId])
REFERENCES [dbo].[MeetingDecisions] ([DecisionId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_DecisionRel_DecisionId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingDecisionRelevant]'))
ALTER TABLE [dbo].[MeetingDecisionRelevant] CHECK CONSTRAINT [FK_DecisionRel_DecisionId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetDecisions_AgendaId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingDecisions]'))
ALTER TABLE [dbo].[MeetingDecisions]  WITH CHECK ADD  CONSTRAINT [FK_MeetDecisions_AgendaId] FOREIGN KEY([AgendaId])
REFERENCES [dbo].[MeetingAgendas] ([AgendaId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetDecisions_AgendaId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingDecisions]'))
ALTER TABLE [dbo].[MeetingDecisions] CHECK CONSTRAINT [FK_MeetDecisions_AgendaId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetDecisions_AgendaType]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingDecisions]'))
ALTER TABLE [dbo].[MeetingDecisions]  WITH CHECK ADD  CONSTRAINT [FK_MeetDecisions_AgendaType] FOREIGN KEY([DecisionNumber])
REFERENCES [dbo].[MeetingAgendaTypes] ([AgendaTypeId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetDecisions_AgendaType]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingDecisions]'))
ALTER TABLE [dbo].[MeetingDecisions] CHECK CONSTRAINT [FK_MeetDecisions_AgendaType]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetDecisions_MeetingId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingDecisions]'))
ALTER TABLE [dbo].[MeetingDecisions]  WITH CHECK ADD  CONSTRAINT [FK_MeetDecisions_MeetingId] FOREIGN KEY([MeetingId])
REFERENCES [dbo].[Meetings] ([MeetingId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetDecisions_MeetingId]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingDecisions]'))
ALTER TABLE [dbo].[MeetingDecisions] CHECK CONSTRAINT [FK_MeetDecisions_MeetingId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetDecisions_RequestedBy]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingDecisions]'))
ALTER TABLE [dbo].[MeetingDecisions]  WITH CHECK ADD  CONSTRAINT [FK_MeetDecisions_RequestedBy] FOREIGN KEY([ResponsibleContactId])
REFERENCES [dbo].[Contacts] ([ContactId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_MeetDecisions_RequestedBy]') AND parent_object_id = OBJECT_ID(N'[dbo].[MeetingDecisions]'))
ALTER TABLE [dbo].[MeetingDecisions] CHECK CONSTRAINT [FK_MeetDecisions_RequestedBy]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Meetings_LocationId]') AND parent_object_id = OBJECT_ID(N'[dbo].[Meetings]'))
ALTER TABLE [dbo].[Meetings]  WITH CHECK ADD  CONSTRAINT [FK_Meetings_LocationId] FOREIGN KEY([LocationId])
REFERENCES [dbo].[MeetingLocations] ([LocationId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Meetings_LocationId]') AND parent_object_id = OBJECT_ID(N'[dbo].[Meetings]'))
ALTER TABLE [dbo].[Meetings] CHECK CONSTRAINT [FK_Meetings_LocationId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Meetings_Organizer]') AND parent_object_id = OBJECT_ID(N'[dbo].[Meetings]'))
ALTER TABLE [dbo].[Meetings]  WITH CHECK ADD  CONSTRAINT [FK_Meetings_Organizer] FOREIGN KEY([OrganizerContactId])
REFERENCES [dbo].[Contacts] ([ContactId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Meetings_Organizer]') AND parent_object_id = OBJECT_ID(N'[dbo].[Meetings]'))
ALTER TABLE [dbo].[Meetings] CHECK CONSTRAINT [FK_Meetings_Organizer]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Meetings_Reporter]') AND parent_object_id = OBJECT_ID(N'[dbo].[Meetings]'))
ALTER TABLE [dbo].[Meetings]  WITH CHECK ADD  CONSTRAINT [FK_Meetings_Reporter] FOREIGN KEY([ReporterContactId])
REFERENCES [dbo].[Contacts] ([ContactId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Meetings_Reporter]') AND parent_object_id = OBJECT_ID(N'[dbo].[Meetings]'))
ALTER TABLE [dbo].[Meetings] CHECK CONSTRAINT [FK_Meetings_Reporter]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Meetings_TypeId]') AND parent_object_id = OBJECT_ID(N'[dbo].[Meetings]'))
ALTER TABLE [dbo].[Meetings]  WITH CHECK ADD  CONSTRAINT [FK_Meetings_TypeId] FOREIGN KEY([MeetingTypeId])
REFERENCES [dbo].[MeetingTypes] ([MeetingTypeId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_Meetings_TypeId]') AND parent_object_id = OBJECT_ID(N'[dbo].[Meetings]'))
ALTER TABLE [dbo].[Meetings] CHECK CONSTRAINT [FK_Meetings_TypeId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_RolePermissions_RoleId]') AND parent_object_id = OBJECT_ID(N'[dbo].[RolePermissions]'))
ALTER TABLE [dbo].[RolePermissions]  WITH CHECK ADD  CONSTRAINT [FK_RolePermissions_RoleId] FOREIGN KEY([RoleId])
REFERENCES [dbo].[Roles] ([RoleId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_RolePermissions_RoleId]') AND parent_object_id = OBJECT_ID(N'[dbo].[RolePermissions]'))
ALTER TABLE [dbo].[RolePermissions] CHECK CONSTRAINT [FK_RolePermissions_RoleId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_UserPermissions_UserId]') AND parent_object_id = OBJECT_ID(N'[dbo].[UserPermissions]'))
ALTER TABLE [dbo].[UserPermissions]  WITH CHECK ADD  CONSTRAINT [FK_UserPermissions_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
ON DELETE CASCADE
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_UserPermissions_UserId]') AND parent_object_id = OBJECT_ID(N'[dbo].[UserPermissions]'))
ALTER TABLE [dbo].[UserPermissions] CHECK CONSTRAINT [FK_UserPermissions_UserId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_UserRoles_RoleId]') AND parent_object_id = OBJECT_ID(N'[dbo].[UserRoles]'))
ALTER TABLE [dbo].[UserRoles]  WITH CHECK ADD  CONSTRAINT [FK_UserRoles_RoleId] FOREIGN KEY([RoleId])
REFERENCES [dbo].[Roles] ([RoleId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_UserRoles_RoleId]') AND parent_object_id = OBJECT_ID(N'[dbo].[UserRoles]'))
ALTER TABLE [dbo].[UserRoles] CHECK CONSTRAINT [FK_UserRoles_RoleId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_UserRoles_UserId]') AND parent_object_id = OBJECT_ID(N'[dbo].[UserRoles]'))
ALTER TABLE [dbo].[UserRoles]  WITH CHECK ADD  CONSTRAINT [FK_UserRoles_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
ON DELETE CASCADE
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK_UserRoles_UserId]') AND parent_object_id = OBJECT_ID(N'[dbo].[UserRoles]'))
ALTER TABLE [dbo].[UserRoles] CHECK CONSTRAINT [FK_UserRoles_UserId]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_City_Region]') AND parent_object_id = OBJECT_ID(N'[HC].[City]'))
ALTER TABLE [HC].[City]  WITH CHECK ADD  CONSTRAINT [FK_City_Region] FOREIGN KEY([RegionId])
REFERENCES [HC].[Region] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_City_Region]') AND parent_object_id = OBJECT_ID(N'[HC].[City]'))
ALTER TABLE [HC].[City] CHECK CONSTRAINT [FK_City_Region]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_City_Timezone]') AND parent_object_id = OBJECT_ID(N'[HC].[City]'))
ALTER TABLE [HC].[City]  WITH CHECK ADD  CONSTRAINT [FK_City_Timezone] FOREIGN KEY([TimezoneId])
REFERENCES [DomainValues].[Timezone] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_City_Timezone]') AND parent_object_id = OBJECT_ID(N'[HC].[City]'))
ALTER TABLE [HC].[City] CHECK CONSTRAINT [FK_City_Timezone]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_EmailLog_EmailTemplate]') AND parent_object_id = OBJECT_ID(N'[HC].[EmailLog]'))
ALTER TABLE [HC].[EmailLog]  WITH CHECK ADD  CONSTRAINT [FK_EmailLog_EmailTemplate] FOREIGN KEY([EmailTemplaterId])
REFERENCES [HC].[EmailTemplate] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_EmailLog_EmailTemplate]') AND parent_object_id = OBJECT_ID(N'[HC].[EmailLog]'))
ALTER TABLE [HC].[EmailLog] CHECK CONSTRAINT [FK_EmailLog_EmailTemplate]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_EmailLog_Event]') AND parent_object_id = OBJECT_ID(N'[HC].[EmailLog]'))
ALTER TABLE [HC].[EmailLog]  WITH CHECK ADD  CONSTRAINT [FK_EmailLog_Event] FOREIGN KEY([EventId])
REFERENCES [HC].[Event] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_EmailLog_Event]') AND parent_object_id = OBJECT_ID(N'[HC].[EmailLog]'))
ALTER TABLE [HC].[EmailLog] CHECK CONSTRAINT [FK_EmailLog_Event]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_EmailTemplate_Event]') AND parent_object_id = OBJECT_ID(N'[HC].[EmailTemplate]'))
ALTER TABLE [HC].[EmailTemplate]  WITH CHECK ADD  CONSTRAINT [FK_EmailTemplate_Event] FOREIGN KEY([EventId])
REFERENCES [HC].[Event] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_EmailTemplate_Event]') AND parent_object_id = OBJECT_ID(N'[HC].[EmailTemplate]'))
ALTER TABLE [HC].[EmailTemplate] CHECK CONSTRAINT [FK_EmailTemplate_Event]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_EmailTemplate_Kennel]') AND parent_object_id = OBJECT_ID(N'[HC].[EmailTemplate]'))
ALTER TABLE [HC].[EmailTemplate]  WITH CHECK ADD  CONSTRAINT [FK_EmailTemplate_Kennel] FOREIGN KEY([KennelId])
REFERENCES [HC].[Kennel] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_EmailTemplate_Kennel]') AND parent_object_id = OBJECT_ID(N'[HC].[EmailTemplate]'))
ALTER TABLE [HC].[EmailTemplate] CHECK CONSTRAINT [FK_EmailTemplate_Kennel]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Event_EventGeographicScope]') AND parent_object_id = OBJECT_ID(N'[HC].[Event]'))
ALTER TABLE [HC].[Event]  WITH CHECK ADD  CONSTRAINT [FK_Event_EventGeographicScope] FOREIGN KEY([EventGeographicScope])
REFERENCES [DomainValues].[EventGeographicScope] ([EventEnumId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Event_EventGeographicScope]') AND parent_object_id = OBJECT_ID(N'[HC].[Event]'))
ALTER TABLE [HC].[Event] CHECK CONSTRAINT [FK_Event_EventGeographicScope]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Event_Kennel]') AND parent_object_id = OBJECT_ID(N'[HC].[Event]'))
ALTER TABLE [HC].[Event]  WITH CHECK ADD  CONSTRAINT [FK_Event_Kennel] FOREIGN KEY([KennelId])
REFERENCES [HC].[Kennel] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Event_Kennel]') AND parent_object_id = OBJECT_ID(N'[HC].[Event]'))
ALTER TABLE [HC].[Event] CHECK CONSTRAINT [FK_Event_Kennel]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_HasherEventMap_Event]') AND parent_object_id = OBJECT_ID(N'[HC].[HasherEventMap]'))
ALTER TABLE [HC].[HasherEventMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherEventMap_Event] FOREIGN KEY([EventId])
REFERENCES [HC].[Event] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_HasherEventMap_Event]') AND parent_object_id = OBJECT_ID(N'[HC].[HasherEventMap]'))
ALTER TABLE [HC].[HasherEventMap] CHECK CONSTRAINT [FK_HasherEventMap_Event]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_HasherEventMap_Hasher]') AND parent_object_id = OBJECT_ID(N'[HC].[HasherEventMap]'))
ALTER TABLE [HC].[HasherEventMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherEventMap_Hasher] FOREIGN KEY([UserId])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_HasherEventMap_Hasher]') AND parent_object_id = OBJECT_ID(N'[HC].[HasherEventMap]'))
ALTER TABLE [HC].[HasherEventMap] CHECK CONSTRAINT [FK_HasherEventMap_Hasher]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_HasherEventMap_RunCounts]') AND parent_object_id = OBJECT_ID(N'[HC].[HasherEventMap]'))
ALTER TABLE [HC].[HasherEventMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherEventMap_RunCounts] FOREIGN KEY([RunCountId])
REFERENCES [HC].[RunCounts] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_HasherEventMap_RunCounts]') AND parent_object_id = OBJECT_ID(N'[HC].[HasherEventMap]'))
ALTER TABLE [HC].[HasherEventMap] CHECK CONSTRAINT [FK_HasherEventMap_RunCounts]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_HasherFriendMap_Hasher]') AND parent_object_id = OBJECT_ID(N'[HC].[HasherFriendMap]'))
ALTER TABLE [HC].[HasherFriendMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherFriendMap_Hasher] FOREIGN KEY([UserId])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_HasherFriendMap_Hasher]') AND parent_object_id = OBJECT_ID(N'[HC].[HasherFriendMap]'))
ALTER TABLE [HC].[HasherFriendMap] CHECK CONSTRAINT [FK_HasherFriendMap_Hasher]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_HasherFriendMap_Hasher1]') AND parent_object_id = OBJECT_ID(N'[HC].[HasherFriendMap]'))
ALTER TABLE [HC].[HasherFriendMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherFriendMap_Hasher1] FOREIGN KEY([Friend_UserId])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_HasherFriendMap_Hasher1]') AND parent_object_id = OBJECT_ID(N'[HC].[HasherFriendMap]'))
ALTER TABLE [HC].[HasherFriendMap] CHECK CONSTRAINT [FK_HasherFriendMap_Hasher1]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_HasherKennelMap_Hasher]') AND parent_object_id = OBJECT_ID(N'[HC].[HasherKennelMap]'))
ALTER TABLE [HC].[HasherKennelMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherKennelMap_Hasher] FOREIGN KEY([UserId])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_HasherKennelMap_Hasher]') AND parent_object_id = OBJECT_ID(N'[HC].[HasherKennelMap]'))
ALTER TABLE [HC].[HasherKennelMap] CHECK CONSTRAINT [FK_HasherKennelMap_Hasher]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_HasherKennelMap_Kennel]') AND parent_object_id = OBJECT_ID(N'[HC].[HasherKennelMap]'))
ALTER TABLE [HC].[HasherKennelMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherKennelMap_Kennel] FOREIGN KEY([KennelId])
REFERENCES [HC].[Kennel] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_HasherKennelMap_Kennel]') AND parent_object_id = OBJECT_ID(N'[HC].[HasherKennelMap]'))
ALTER TABLE [HC].[HasherKennelMap] CHECK CONSTRAINT [FK_HasherKennelMap_Kennel]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Kennel_City]') AND parent_object_id = OBJECT_ID(N'[HC].[Kennel]'))
ALTER TABLE [HC].[Kennel]  WITH CHECK ADD  CONSTRAINT [FK_Kennel_City] FOREIGN KEY([CityId])
REFERENCES [HC].[City] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Kennel_City]') AND parent_object_id = OBJECT_ID(N'[HC].[Kennel]'))
ALTER TABLE [HC].[Kennel] CHECK CONSTRAINT [FK_Kennel_City]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Kennel_Country]') AND parent_object_id = OBJECT_ID(N'[HC].[Kennel]'))
ALTER TABLE [HC].[Kennel]  WITH CHECK ADD  CONSTRAINT [FK_Kennel_Country] FOREIGN KEY([CountryId])
REFERENCES [HC].[Country] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Kennel_Country]') AND parent_object_id = OBJECT_ID(N'[HC].[Kennel]'))
ALTER TABLE [HC].[Kennel] CHECK CONSTRAINT [FK_Kennel_Country]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Kennel_KennelStatusEnum]') AND parent_object_id = OBJECT_ID(N'[HC].[Kennel]'))
ALTER TABLE [HC].[Kennel]  WITH CHECK ADD  CONSTRAINT [FK_Kennel_KennelStatusEnum] FOREIGN KEY([KennelStatus])
REFERENCES [DomainValues].[KennelStatusEnum] ([KennelStatusEnumId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Kennel_KennelStatusEnum]') AND parent_object_id = OBJECT_ID(N'[HC].[Kennel]'))
ALTER TABLE [HC].[Kennel] CHECK CONSTRAINT [FK_Kennel_KennelStatusEnum]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Kennel_Region]') AND parent_object_id = OBJECT_ID(N'[HC].[Kennel]'))
ALTER TABLE [HC].[Kennel]  WITH CHECK ADD  CONSTRAINT [FK_Kennel_Region] FOREIGN KEY([ProvinceStateId])
REFERENCES [HC].[Region] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Kennel_Region]') AND parent_object_id = OBJECT_ID(N'[HC].[Kennel]'))
ALTER TABLE [HC].[Kennel] CHECK CONSTRAINT [FK_Kennel_Region]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_KennelAuthorization_Kennel]') AND parent_object_id = OBJECT_ID(N'[HC].[KennelAuthorization]'))
ALTER TABLE [HC].[KennelAuthorization]  WITH CHECK ADD  CONSTRAINT [FK_KennelAuthorization_Kennel] FOREIGN KEY([KennelId])
REFERENCES [HC].[Kennel] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_KennelAuthorization_Kennel]') AND parent_object_id = OBJECT_ID(N'[HC].[KennelAuthorization]'))
ALTER TABLE [HC].[KennelAuthorization] CHECK CONSTRAINT [FK_KennelAuthorization_Kennel]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_KennelCredit_Hasher]') AND parent_object_id = OBJECT_ID(N'[HC].[KennelCredit]'))
ALTER TABLE [HC].[KennelCredit]  WITH CHECK ADD  CONSTRAINT [FK_KennelCredit_Hasher] FOREIGN KEY([userId])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_KennelCredit_Hasher]') AND parent_object_id = OBJECT_ID(N'[HC].[KennelCredit]'))
ALTER TABLE [HC].[KennelCredit] CHECK CONSTRAINT [FK_KennelCredit_Hasher]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_KennelCredit_Kennel]') AND parent_object_id = OBJECT_ID(N'[HC].[KennelCredit]'))
ALTER TABLE [HC].[KennelCredit]  WITH CHECK ADD  CONSTRAINT [FK_KennelCredit_Kennel] FOREIGN KEY([kennelId])
REFERENCES [HC].[Kennel] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_KennelCredit_Kennel]') AND parent_object_id = OBJECT_ID(N'[HC].[KennelCredit]'))
ALTER TABLE [HC].[KennelCredit] CHECK CONSTRAINT [FK_KennelCredit_Kennel]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_LaunchAndLogin_Hasher]') AND parent_object_id = OBJECT_ID(N'[HC].[LaunchAndLogin]'))
ALTER TABLE [HC].[LaunchAndLogin]  WITH NOCHECK ADD  CONSTRAINT [FK_LaunchAndLogin_Hasher] FOREIGN KEY([UserId])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_LaunchAndLogin_Hasher]') AND parent_object_id = OBJECT_ID(N'[HC].[LaunchAndLogin]'))
ALTER TABLE [HC].[LaunchAndLogin] NOCHECK CONSTRAINT [FK_LaunchAndLogin_Hasher]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Payment_Event]') AND parent_object_id = OBJECT_ID(N'[HC].[Payment]'))
ALTER TABLE [HC].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_Event] FOREIGN KEY([EventId])
REFERENCES [HC].[Event] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Payment_Event]') AND parent_object_id = OBJECT_ID(N'[HC].[Payment]'))
ALTER TABLE [HC].[Payment] CHECK CONSTRAINT [FK_Payment_Event]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Payment_Hasher]') AND parent_object_id = OBJECT_ID(N'[HC].[Payment]'))
ALTER TABLE [HC].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_Hasher] FOREIGN KEY([UserId])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Payment_Hasher]') AND parent_object_id = OBJECT_ID(N'[HC].[Payment]'))
ALTER TABLE [HC].[Payment] CHECK CONSTRAINT [FK_Payment_Hasher]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Payment_Hasher1]') AND parent_object_id = OBJECT_ID(N'[HC].[Payment]'))
ALTER TABLE [HC].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_Hasher1] FOREIGN KEY([PaymentProcessedBy_userId])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Payment_Hasher1]') AND parent_object_id = OBJECT_ID(N'[HC].[Payment]'))
ALTER TABLE [HC].[Payment] CHECK CONSTRAINT [FK_Payment_Hasher1]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Payment_Hasher2]') AND parent_object_id = OBJECT_ID(N'[HC].[Payment]'))
ALTER TABLE [HC].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_Hasher2] FOREIGN KEY([CancelledBy_UserId])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Payment_Hasher2]') AND parent_object_id = OBJECT_ID(N'[HC].[Payment]'))
ALTER TABLE [HC].[Payment] CHECK CONSTRAINT [FK_Payment_Hasher2]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Payment_Hasher3]') AND parent_object_id = OBJECT_ID(N'[HC].[Payment]'))
ALTER TABLE [HC].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_Hasher3] FOREIGN KEY([ConfirmedBy_UserId])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Payment_Hasher3]') AND parent_object_id = OBJECT_ID(N'[HC].[Payment]'))
ALTER TABLE [HC].[Payment] CHECK CONSTRAINT [FK_Payment_Hasher3]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Payment_HasherEventMap]') AND parent_object_id = OBJECT_ID(N'[HC].[Payment]'))
ALTER TABLE [HC].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_HasherEventMap] FOREIGN KEY([HasherEventMapId])
REFERENCES [HC].[HasherEventMap] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Payment_HasherEventMap]') AND parent_object_id = OBJECT_ID(N'[HC].[Payment]'))
ALTER TABLE [HC].[Payment] CHECK CONSTRAINT [FK_Payment_HasherEventMap]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Payment_Kennel]') AND parent_object_id = OBJECT_ID(N'[HC].[Payment]'))
ALTER TABLE [HC].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_Kennel] FOREIGN KEY([KennelId])
REFERENCES [HC].[Kennel] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Payment_Kennel]') AND parent_object_id = OBJECT_ID(N'[HC].[Payment]'))
ALTER TABLE [HC].[Payment] CHECK CONSTRAINT [FK_Payment_Kennel]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Receipt_Event]') AND parent_object_id = OBJECT_ID(N'[HC].[Receipt]'))
ALTER TABLE [HC].[Receipt]  WITH CHECK ADD  CONSTRAINT [FK_Receipt_Event] FOREIGN KEY([EventId])
REFERENCES [HC].[Event] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Receipt_Event]') AND parent_object_id = OBJECT_ID(N'[HC].[Receipt]'))
ALTER TABLE [HC].[Receipt] CHECK CONSTRAINT [FK_Receipt_Event]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Receipt_Hasher]') AND parent_object_id = OBJECT_ID(N'[HC].[Receipt]'))
ALTER TABLE [HC].[Receipt]  WITH CHECK ADD  CONSTRAINT [FK_Receipt_Hasher] FOREIGN KEY([UserId])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Receipt_Hasher]') AND parent_object_id = OBJECT_ID(N'[HC].[Receipt]'))
ALTER TABLE [HC].[Receipt] CHECK CONSTRAINT [FK_Receipt_Hasher]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Receipt_Hasher1]') AND parent_object_id = OBJECT_ID(N'[HC].[Receipt]'))
ALTER TABLE [HC].[Receipt]  WITH CHECK ADD  CONSTRAINT [FK_Receipt_Hasher1] FOREIGN KEY([ReimbursedBy])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Receipt_Hasher1]') AND parent_object_id = OBJECT_ID(N'[HC].[Receipt]'))
ALTER TABLE [HC].[Receipt] CHECK CONSTRAINT [FK_Receipt_Hasher1]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Region_Country]') AND parent_object_id = OBJECT_ID(N'[HC].[Region]'))
ALTER TABLE [HC].[Region]  WITH CHECK ADD  CONSTRAINT [FK_Region_Country] FOREIGN KEY([CountryId])
REFERENCES [HC].[Country] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[HC].[FK_Region_Country]') AND parent_object_id = OBJECT_ID(N'[HC].[Region]'))
ALTER TABLE [HC].[Region] CHECK CONSTRAINT [FK_Region_Country]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Kennels].[FK_Mismanagement_Hasher]') AND parent_object_id = OBJECT_ID(N'[Kennels].[Mismanagement]'))
ALTER TABLE [Kennels].[Mismanagement]  WITH CHECK ADD  CONSTRAINT [FK_Mismanagement_Hasher] FOREIGN KEY([HasherId])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Kennels].[FK_Mismanagement_Hasher]') AND parent_object_id = OBJECT_ID(N'[Kennels].[Mismanagement]'))
ALTER TABLE [Kennels].[Mismanagement] CHECK CONSTRAINT [FK_Mismanagement_Hasher]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Kennels].[FK_Mismanagement_MismanagementEnum]') AND parent_object_id = OBJECT_ID(N'[Kennels].[Mismanagement]'))
ALTER TABLE [Kennels].[Mismanagement]  WITH CHECK ADD  CONSTRAINT [FK_Mismanagement_MismanagementEnum] FOREIGN KEY([MismanagementEnumId])
REFERENCES [DomainValues].[MismanagementEnum] ([MismanagementEnumId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Kennels].[FK_Mismanagement_MismanagementEnum]') AND parent_object_id = OBJECT_ID(N'[Kennels].[Mismanagement]'))
ALTER TABLE [Kennels].[Mismanagement] CHECK CONSTRAINT [FK_Mismanagement_MismanagementEnum]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Transactions].[FK_EventRegistration_Hasher]') AND parent_object_id = OBJECT_ID(N'[Transactions].[EventRegistration]'))
ALTER TABLE [Transactions].[EventRegistration]  WITH CHECK ADD  CONSTRAINT [FK_EventRegistration_Hasher] FOREIGN KEY([HasherId])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Transactions].[FK_EventRegistration_Hasher]') AND parent_object_id = OBJECT_ID(N'[Transactions].[EventRegistration]'))
ALTER TABLE [Transactions].[EventRegistration] CHECK CONSTRAINT [FK_EventRegistration_Hasher]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Transactions].[FK_HaberdasherySale_Haberdashery]') AND parent_object_id = OBJECT_ID(N'[Transactions].[HaberdasherySale]'))
ALTER TABLE [Transactions].[HaberdasherySale]  WITH CHECK ADD  CONSTRAINT [FK_HaberdasherySale_Haberdashery] FOREIGN KEY([HaberdasheryId])
REFERENCES [Kennels].[Haberdashery] ([HaberdasheryId])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Transactions].[FK_HaberdasherySale_Haberdashery]') AND parent_object_id = OBJECT_ID(N'[Transactions].[HaberdasherySale]'))
ALTER TABLE [Transactions].[HaberdasherySale] CHECK CONSTRAINT [FK_HaberdasherySale_Haberdashery]
GO
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Transactions].[FK_HaberdasherySale_Hasher]') AND parent_object_id = OBJECT_ID(N'[Transactions].[HaberdasherySale]'))
ALTER TABLE [Transactions].[HaberdasherySale]  WITH CHECK ADD  CONSTRAINT [FK_HaberdasherySale_Hasher] FOREIGN KEY([HasherId])
REFERENCES [HC].[Hasher] ([id])
GO
IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[Transactions].[FK_HaberdasherySale_Hasher]') AND parent_object_id = OBJECT_ID(N'[Transactions].[HaberdasherySale]'))
ALTER TABLE [Transactions].[HaberdasherySale] CHECK CONSTRAINT [FK_HaberdasherySale_Hasher]
GO
IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'[HC].[CK_Event_IsCountedRun]') AND parent_object_id = OBJECT_ID(N'[HC].[Event]'))
ALTER TABLE [HC].[Event]  WITH CHECK ADD  CONSTRAINT [CK_Event_IsCountedRun] CHECK  (([IsCountedRun]>=(0) AND [IsCountedRun]<=(1)))
GO
IF  EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'[HC].[CK_Event_IsCountedRun]') AND parent_object_id = OBJECT_ID(N'[HC].[Event]'))
ALTER TABLE [HC].[Event] CHECK CONSTRAINT [CK_Event_IsCountedRun]
GO
IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'[HC].[CK_Event_IsPromotedEvent]') AND parent_object_id = OBJECT_ID(N'[HC].[Event]'))
ALTER TABLE [HC].[Event]  WITH CHECK ADD  CONSTRAINT [CK_Event_IsPromotedEvent] CHECK  (([IsPromotedEvent]>=(0) AND [IsPromotedEvent]<=(1)))
GO
IF  EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'[HC].[CK_Event_IsPromotedEvent]') AND parent_object_id = OBJECT_ID(N'[HC].[Event]'))
ALTER TABLE [HC].[Event] CHECK CONSTRAINT [CK_Event_IsPromotedEvent]
GO
IF NOT EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'[HC].[CK_Event_IsVisible]') AND parent_object_id = OBJECT_ID(N'[HC].[Event]'))
ALTER TABLE [HC].[Event]  WITH CHECK ADD  CONSTRAINT [CK_Event_IsVisible] CHECK  (([IsVisible]>=(0) AND [IsVisible]<=(1)))
GO
IF  EXISTS (SELECT * FROM sys.check_constraints WHERE object_id = OBJECT_ID(N'[HC].[CK_Event_IsVisible]') AND parent_object_id = OBJECT_ID(N'[HC].[Event]'))
ALTER TABLE [HC].[Event] CHECK CONSTRAINT [CK_Event_IsVisible]
GO
/****** Object:  StoredProcedure [dbo].[sp_alterdiagram]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_alterdiagram]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_alterdiagram] AS' 
END
GO

	ALTER PROCEDURE [dbo].[sp_alterdiagram]
	(
		@diagramname 	sysname,
		@owner_id	int	= null,
		@version 	int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
	
		declare @theId 			int
		declare @retval 		int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
		declare @ShouldChangeUID	int
	
		if(@diagramname is null)
		begin
			RAISERROR ('Invalid ARG', 16, 1)
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();	 
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		revert;
	
		select @ShouldChangeUID = 0
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		
		if(@DiagId IS NULL or (@IsDbo = 0 and @theId <> @UIDFound))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end
	
		if(@IsDbo <> 0)
		begin
			if(@UIDFound is null or USER_NAME(@UIDFound) is null) -- invalid principal_id
			begin
				select @ShouldChangeUID = 1 ;
			end
		end

		-- update dds data			
		update dbo.sysdiagrams set definition = @definition where diagram_id = @DiagId ;

		-- change owner
		if(@ShouldChangeUID = 1)
			update dbo.sysdiagrams set principal_id = @theId where diagram_id = @DiagId ;

		-- update dds version
		if(@version is not null)
			update dbo.sysdiagrams set version = @version where diagram_id = @DiagId ;

		return 0
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_creatediagram]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_creatediagram]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_creatediagram] AS' 
END
GO

	ALTER PROCEDURE [dbo].[sp_creatediagram]
	(
		@diagramname 	sysname,
		@owner_id		int	= null, 	
		@version 		int,
		@definition 	varbinary(max)
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
	
		declare @theId int
		declare @retval int
		declare @IsDbo	int
		declare @userName sysname
		if(@version is null or @diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID(); 
		select @IsDbo = IS_MEMBER(N'db_owner');
		revert; 
		
		if @owner_id is null
		begin
			select @owner_id = @theId;
		end
		else
		begin
			if @theId <> @owner_id
			begin
				if @IsDbo = 0
				begin
					RAISERROR (N'E_INVALIDARG', 16, 1);
					return -1
				end
				select @theId = @owner_id
			end
		end
		-- next 2 line only for test, will be removed after define name unique
		if EXISTS(select diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @diagramname)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end
	
		insert into dbo.sysdiagrams(name, principal_id , version, definition)
				VALUES(@diagramname, @theId, @version, @definition) ;
		
		select @retval = @@IDENTITY 
		return @retval
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_dropdiagram]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_dropdiagram]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_dropdiagram] AS' 
END
GO

	ALTER PROCEDURE [dbo].[sp_dropdiagram]
	(
		@diagramname 	sysname,
		@owner_id	int	= null
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
	
		if(@diagramname is null)
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end
	
		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT; 
		
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end
	
		delete from dbo.sysdiagrams where diagram_id = @DiagId;
	
		return 0;
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_helpdiagramdefinition]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_helpdiagramdefinition]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_helpdiagramdefinition] AS' 
END
GO

	ALTER PROCEDURE [dbo].[sp_helpdiagramdefinition]
	(
		@diagramname 	sysname,
		@owner_id	int	= null 		
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		set nocount on

		declare @theId 		int
		declare @IsDbo 		int
		declare @DiagId		int
		declare @UIDFound	int
	
		if(@diagramname is null)
		begin
			RAISERROR (N'E_INVALIDARG', 16, 1);
			return -1
		end
	
		execute as caller;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner');
		if(@owner_id is null)
			select @owner_id = @theId;
		revert; 
	
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname;
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId ))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1);
			return -3
		end

		select version, definition FROM dbo.sysdiagrams where diagram_id = @DiagId ; 
		return 0
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_helpdiagrams]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_helpdiagrams]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_helpdiagrams] AS' 
END
GO

	ALTER PROCEDURE [dbo].[sp_helpdiagrams]
	(
		@diagramname sysname = NULL,
		@owner_id int = NULL
	)
	WITH EXECUTE AS N'dbo'
	AS
	BEGIN
		DECLARE @user sysname
		DECLARE @dboLogin bit
		EXECUTE AS CALLER;
			SET @user = USER_NAME();
			SET @dboLogin = CONVERT(bit,IS_MEMBER('db_owner'));
		REVERT;
		SELECT
			[Database] = DB_NAME(),
			[Name] = name,
			[ID] = diagram_id,
			[Owner] = USER_NAME(principal_id),
			[OwnerID] = principal_id
		FROM
			sysdiagrams
		WHERE
			(@dboLogin = 1 OR USER_NAME(principal_id) = @user) AND
			(@diagramname IS NULL OR name = @diagramname) AND
			(@owner_id IS NULL OR principal_id = @owner_id)
		ORDER BY
			4, 5, 1
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_renamediagram]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_renamediagram]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_renamediagram] AS' 
END
GO

	ALTER PROCEDURE [dbo].[sp_renamediagram]
	(
		@diagramname 		sysname,
		@owner_id		int	= null,
		@new_diagramname	sysname
	
	)
	WITH EXECUTE AS 'dbo'
	AS
	BEGIN
		set nocount on
		declare @theId 			int
		declare @IsDbo 			int
		
		declare @UIDFound 		int
		declare @DiagId			int
		declare @DiagIdTarg		int
		declare @u_name			sysname
		if((@diagramname is null) or (@new_diagramname is null))
		begin
			RAISERROR ('Invalid value', 16, 1);
			return -1
		end
	
		EXECUTE AS CALLER;
		select @theId = DATABASE_PRINCIPAL_ID();
		select @IsDbo = IS_MEMBER(N'db_owner'); 
		if(@owner_id is null)
			select @owner_id = @theId;
		REVERT;
	
		select @u_name = USER_NAME(@owner_id)
	
		select @DiagId = diagram_id, @UIDFound = principal_id from dbo.sysdiagrams where principal_id = @owner_id and name = @diagramname 
		if(@DiagId IS NULL or (@IsDbo = 0 and @UIDFound <> @theId))
		begin
			RAISERROR ('Diagram does not exist or you do not have permission.', 16, 1)
			return -3
		end
	
		-- if((@u_name is not null) and (@new_diagramname = @diagramname))	-- nothing will change
		--	return 0;
	
		if(@u_name is null)
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @theId and name = @new_diagramname
		else
			select @DiagIdTarg = diagram_id from dbo.sysdiagrams where principal_id = @owner_id and name = @new_diagramname
	
		if((@DiagIdTarg is not null) and  @DiagId <> @DiagIdTarg)
		begin
			RAISERROR ('The name is already used.', 16, 1);
			return -2
		end		
	
		if(@u_name is null)
			update dbo.sysdiagrams set [name] = @new_diagramname, principal_id = @theId where diagram_id = @DiagId
		else
			update dbo.sysdiagrams set [name] = @new_diagramname where diagram_id = @DiagId
		return 0
	END
	
GO
/****** Object:  StoredProcedure [dbo].[sp_upgraddiagrams]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_upgraddiagrams]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[sp_upgraddiagrams] AS' 
END
GO

	ALTER PROCEDURE [dbo].[sp_upgraddiagrams]
	AS
	BEGIN
		IF OBJECT_ID(N'dbo.sysdiagrams') IS NOT NULL
			return 0;
	
		CREATE TABLE dbo.sysdiagrams
		(
			name sysname NOT NULL,
			principal_id int NOT NULL,	-- we may change it to varbinary(85)
			diagram_id int PRIMARY KEY IDENTITY,
			version int,
	
			definition varbinary(max)
			CONSTRAINT UK_principal_name UNIQUE
			(
				principal_id,
				name
			)
		);


		/* Add this if we need to have some form of extended properties for diagrams */
		/*
		IF OBJECT_ID(N'dbo.sysdiagram_properties') IS NULL
		BEGIN
			CREATE TABLE dbo.sysdiagram_properties
			(
				diagram_id int,
				name sysname,
				value varbinary(max) NOT NULL
			)
		END
		*/

		IF OBJECT_ID(N'dbo.dtproperties') IS NOT NULL
		begin
			insert into dbo.sysdiagrams
			(
				[name],
				[principal_id],
				[version],
				[definition]
			)
			select	 
				convert(sysname, dgnm.[uvalue]),
				DATABASE_PRINCIPAL_ID(N'dbo'),			-- will change to the sid of sa
				0,							-- zero for old format, dgdef.[version],
				dgdef.[lvalue]
			from dbo.[dtproperties] dgnm
				inner join dbo.[dtproperties] dggd on dggd.[property] = 'DtgSchemaGUID' and dggd.[objectid] = dgnm.[objectid]	
				inner join dbo.[dtproperties] dgdef on dgdef.[property] = 'DtgSchemaDATA' and dgdef.[objectid] = dgnm.[objectid]
				
			where dgnm.[property] = 'DtgSchemaNAME' and dggd.[uvalue] like N'_EA3E6268-D998-11CE-9454-00AA00A3F36E_' 
			return 2;
		end
		return 1;
	END
	
GO
/****** Object:  StoredProcedure [DEV].[backupTables]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DEV].[backupTables]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [DEV].[backupTables] AS' 
END
GO
ALTER PROCEDURE [DEV].[backupTables] AS

drop table HC_BACKUP.City
drop table HC_BACKUP.Country
drop table HC_BACKUP.EmailLog
drop table HC_BACKUP.EmailTemplate
drop table HC_BACKUP.[Event]
drop table HC_BACKUP.Hasher
drop table HC_BACKUP.HasherEventMap
drop table HC_BACKUP.HasherFriendMap
drop table HC_BACKUP.HasherKennelMap
drop table HC_BACKUP.HasherOwnEvent
drop table HC_BACKUP.Kennel
drop table HC_BACKUP.KennelAuthorization
drop table HC_BACKUP.KennelCredit
drop table HC_BACKUP.LaunchAndLogin
drop table HC_BACKUP.LoginNotifications
drop table HC_BACKUP.Payment
drop table HC_BACKUP.Recepit
drop table HC_BACKUP.Region
drop table HC_BACKUP.RunCounts
drop table HC_BACKUP.ServerStatus
drop table HC_BACKUP.WebAppLogin


select * into HC_BACKUP.City FROM HC.City
select * into HC_BACKUP.Country FROM HC.Country
select * into HC_BACKUP.EmailLog FROM HC.EmailLog
select * into HC_BACKUP.EmailTemplate FROM HC.EmailTemplate
select * into HC_BACKUP.Event FROM HC.[Event]
select * into HC_BACKUP.Hasher FROM HC.Hasher
select * into HC_BACKUP.HasherEventMap FROM HC.HasherEventMap
select * into HC_BACKUP.HasherFriendMap FROM HC.HasherFriendMap
select * into HC_BACKUP.HasherKennelMap FROM HC.HasherKennelMap
select * into HC_BACKUP.HasherOwnEvent FROM HC.HasherOwnEvent
select * into HC_BACKUP.Kennel FROM HC.Kennel
select * into HC_BACKUP.KennelAuthorization FROM HC.KennelAuthorization
select * into HC_BACKUP.KennelCredit FROM HC.KennelCredit
select * into HC_BACKUP.LaunchAndLogin FROM HC.LaunchAndLogin
select * into HC_BACKUP.LoginNotifications FROM HC.LoginNotifications
select * into HC_BACKUP.Payment FROM HC.Payment
select * into HC_BACKUP.Recepit FROM HC.Receipt
select * into HC_BACKUP.Region FROM HC.Region
select * into HC_BACKUP.RunCounts FROM HC.RunCounts
select * into HC_BACKUP.ServerStatus FROM HC.ServerStatus
select * into HC_BACKUP.WebAppLogin FROM HC.WebAppLogin
GO
/****** Object:  StoredProcedure [DEV].[CleanDb]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DEV].[CleanDb]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [DEV].[CleanDb] AS' 
END
GO
ALTER PROC [DEV].[CleanDb] AS

delete from HC.HasherEventMap where EventId not in (select id from HC.Event)
delete from HC.HasherEventMap where UserId not in (select id from HC.Hasher)
delete from HC.HasherKennelMap where UserId not in (select id from HC.Hasher)
delete from HC.HasherKennelMap where KennelId not in (select id from HC.Kennel)
delete from HC.Payment where HasherEventMapId not in (select id from HC.HasherEventMap)
delete from HC.RunCounts where id not in (select RunCountId from HC.HasherEventMap)
GO
/****** Object:  StoredProcedure [DEV].[DeleteKennel]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DEV].[DeleteKennel]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [DEV].[DeleteKennel] AS' 
END
GO
--select * from HC.Kennel where KennelName like '%test%'

ALTER PROC [DEV].[DeleteKennel]

	@kennelId uniqueidentifier

AS

-- select * from HC.Kennel order by updatedAt desc
-- EXEC DEV.DeleteKennel @kennelId = '9A7C3145-1ABE-4983-BC5B-08553DADAD58'

select h.HashName, h.FirstName, h.LastName, hkm.* from HC.HasherKennelMap hkm
inner join HC.Hasher h on hkm.UserId = h.id
where KennelId = @kennelId 

delete from HC.HasherKennelMap where id in (
select hkm.id from HC.HasherKennelMap hkm
inner join HC.Hasher h on hkm.UserId = h.id
where KennelId = @kennelId )

select * from HC.Payment where KennelId = @kennelId and EventId 
in (select id from HC.Event evt where evt.KennelId = @kennelId)

delete from HC.Payment where KennelId = @kennelId and EventId 
in (select id from HC.Event evt where evt.KennelId = @kennelId)

select * from HC.HasherEventMap 
where EventId in (select id from HC.Event evt where evt.KennelId = @kennelId)

delete from HC.HasherEventMap 
where EventId in (select id from HC.Event evt where evt.KennelId = @kennelId)

select * from HC.Event evt where evt.KennelId = @kennelId

delete from HC.Event  where KennelId = @kennelId

select * from HC.Kennel where id = @kennelId

delete from HC.Kennel where id = @kennelId

update EXT.OfficeForms_KennelImport SET kennelId = null, KennelImportedOn = null
WHERE KennelId = @kennelId








GO
/****** Object:  StoredProcedure [DEV].[deleteTestUsers]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DEV].[deleteTestUsers]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [DEV].[deleteTestUsers] AS' 
END
GO
ALTER procedure [DEV].[deleteTestUsers]

AS

select * into #temp from HC.Hasher where firstName like 'Test%'

select * from #temp

delete from HC.HasherKennelMap where userId in (select id from #temp)
delete from HC.HasherEventMap where userId in (select id from #temp)

delete from HC.Hasher where id in (select id from #temp)


drop table #temp
GO
/****** Object:  StoredProcedure [DEV].[DeleteUser]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DEV].[DeleteUser]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [DEV].[DeleteUser] AS' 
END
GO
ALTER PROC [DEV].[DeleteUser]

@email nvarchar(250)

AS

-- EXEC DEV.DeleteUser @email = 'james@jamesawhite.com'

DECLARE @id uniqueidentifier
select @id = id from HC.Hasher where email = @email

delete from HC.HasherKennelMap  where UserId  = @id

delete from HC.Hasher where email = @email
delete from dbo.Users where email = @email
GO
/****** Object:  StoredProcedure [DEV].[RecompileHc2AndHc3]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[DEV].[RecompileHc2AndHc3]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [DEV].[RecompileHc2AndHc3] AS' 
END
GO
ALTER PROCEDURE [DEV].[RecompileHc2AndHc3]

AS

DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql += 'EXEC sp_recompile ''HC2.'+[name]+''''+CHAR(10) FROM sys.objects WHERE [type] IN ('P') and schema_id = 13 and parent_object_id = 0 and type_desc = 'SQL_STORED_PROCEDURE'
EXEC (@sql);

SET @sql = ''
SELECT @sql += 'EXEC sp_recompile ''HC3.'+[name]+''''+CHAR(10) FROM sys.objects WHERE [type] IN ('P') and schema_id = 15 and parent_object_id = 0 and type_desc = 'SQL_STORED_PROCEDURE'
EXEC (@sql);


GO
/****** Object:  StoredProcedure [EXT].[ProcessKennelImports]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[EXT].[ProcessKennelImports]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [EXT].[ProcessKennelImports] AS' 
END
GO

ALTER PROC [EXT].[ProcessKennelImports]

AS

BEGIN

	SET NOCOUNT ON

	DECLARE @KennelImportId uniqueidentifier, 
			@Country nvarchar(250),
			@CountryId uniqueidentifier,
			@Region nvarchar(250),
			@RegionId uniqueidentifier,
			@RegionName nvarchar(250),
			@City nvarchar(250),
			@CityId uniqueidentifier

	DECLARE xCrsr CURSOR FOR SELECT KennelImportId, Country,Region,City FROM EXT.OfficeForms_KennelImport where CountryId IS NULL

	OPEN xCrsr

	FETCH NEXT FROM xCrsr INTO @KennelImportId,@Country,@Region,@City

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		SELECT @CountryId = c.id FROM HC.Country c where c.CountryName = @Country
		IF (@CountryId IS NOT NULL)
		BEGIN
			SELECT @RegionId = r.id FROM HC.Region r where r.RegionName = @Region AND r.CountryId = @CountryId
			IF (@RegionId IS NOT NULL)
				BEGIN
					SELECT @CityId = ci.id FROM HC.City ci WHERE ci.RegionId = @RegionId AND ci.CityName like '%'+@City+'%'
				END
			ELSE
				BEGIN
					SELECT 
						@CityId = ci.id,
						@RegionId = r.id,
						@RegionName = r.RegionName
					FROM HC.City ci 
					INNER JOIN HC.Region r on ci.RegionId = r.id
					WHERE r.CountryId = @CountryId AND ci.CityName like '%'+@City+'%'
				END

			UPDATE EXT.OfficeForms_KennelImport SET 
				CountryId = @CountryId, 
				RegionId = @RegionId, 
				Region = coalesce(@RegionName,Region),
				CityId = @CityId 
			WHERE KennelImportId = @KennelImportId

		END
		FETCH NEXT FROM xCrsr INTO @KennelImportId,@Country,@Region,@City
	END

	CLOSE xCrsr
	DEALLOCATE xCrsr

END
GO
/****** Object:  StoredProcedure [HC].[nonApi_adjustHasherRunCounts]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[nonApi_adjustHasherRunCounts]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC].[nonApi_adjustHasherRunCounts] AS' 
END
GO
ALTER PROCEDURE [HC].[nonApi_adjustHasherRunCounts]

@limitByUser smallint = null,
@userId uniqueidentifier = null,
@hasherEventMapId uniqueidentifier = null,
@kennelId uniqueidentifier = null

AS


BEGIN

-- EXEC HC.nonApi_adjustHasherRunCounts @userId = '624C51B3-2F64-4DE5-9458-B506E75AC544', @limitByUser = 1

SET NOCOUNT ON


SET @limitByUser = coalesce(@limitByUser,0)

--SELECT @limitByUser,@userId,@kennelId


-- Start by calculating the updated run counts and putting these into a temp table
SELECT 
 hem.id
,evt.KennelId
,case when hem.AttendenceState >= 20 then evt.EventStartDatetime else null end as EventStartDatetime -- this is used to determine the date of the last run for this hasher
,hem.UserId
,hem.VirginVisitorType
,hem.UserStartEvent
,hem.RunCountId
,hem.AttendenceState
,sum(case when ((hem.isHare = 1) AND (hem.AttendenceState >=20)) then evt.UserEventCounterIncrement else 0 end) over (PARTITION BY hem.UserId, evt.IsCountedRun, evt.KennelId order by evt.EventStartDatetime asc,evt.id) + coalesce(hkm.HistoricalHaringCount,0) as TotalHaringThisKennel
,sum(case when ((hem.isHare = 0) AND (hem.AttendenceState >=20)) then evt.UserEventCounterIncrement else 0 end) over (PARTITION BY hem.UserId, evt.IsCountedRun, evt.KennelId order by evt.EventStartDatetime asc,evt.id) + coalesce(hkm.HistoricalPackRunCount,0) as TotalPackRunsThisKennel
,sum(case when ((hem.isHare = 1) AND (hem.AttendenceState >=20)) then evt.UserEventCounterIncrement else 0 end) over (PARTITION BY hem.UserId, evt.IsCountedRun order by evt.EventStartDatetime asc,evt.id) + coalesce((select sum(hkm2.HistoricalHaringCount) from HC.HasherKennelMap hkm2 where hkm2.UserId = hem.UserId),0) as TotalHaringAllKennels
,sum(case when ((hem.isHare = 0) AND (hem.AttendenceState >=20)) then evt.UserEventCounterIncrement else 0 end) over (PARTITION BY hem.UserId, evt.IsCountedRun order by evt.EventStartDatetime asc,evt.id) + coalesce((select sum(hkm2.HistoricalPackRunCount) from HC.HasherKennelMap hkm2 where hkm2.UserId = hem.UserId),0) as TotalPackRunsAllKennels
INTO #temp
FROM HC.HasherEventMap hem
INNER JOIN HC.Event evt on hem.EventId = evt.id
LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.userId = hem.UserId and hkm.KennelId = evt.KennelId
WHERE 
--hem.VirginVisitorType = 0 -- only track run counts for non-virgins / non-visitors
 evt.deleted = 0 AND evt.IsVisible <> 0
AND (
	   ((@limitByUser = 1) AND (hem.userId = @userId) AND (evt.KennelId = @kennelId)) 
	OR ((@limitByUser = 2) AND (hem.id = @hasherEventMapId))
	OR ((@limitByUser = 3) AND (hem.UserId = @userId))
	OR (@limitByUser = 0)
   )
-- This line is commented out for testing, eventually add it back in for production
-- AND evt.EventStartDatetime <= dateadd(day,1,getdate())
AND evt.IsCountedRun = 1
--AND evt.EventStartDatetime < dateadd(day,1,getdate())

--select * 
--FROM HC.RunCounts rc
--INNER JOIN #temp t on t.RunCountId = rc.id
--WHERE (coalesce(rc.TotalHaringThisKennel,-99999) <>  t.TotalHaringThisKennel )
--OR (coalesce(rc.TotalPackRunsThisKennel,-99999) <>  t.TotalPackRunsThisKennel)
--OR (coalesce(rc.TotalHaringAllKennels,-99999) <>   t.TotalHaringAllKennels )
--OR (coalesce(rc.TotalPackRunsAllKennels,-99999) <>  t.TotalPackRunsAllKennels )

--select * from #temp


-- run count records were already inserted when the HEM record was created
-- now, apply updates only where they are required
UPDATE HC.RunCounts 
SET TotalHaringThisKennel =  t.TotalHaringThisKennel  , 
TotalPackRunsThisKennel =  t.TotalPackRunsThisKennel , 
TotalHaringAllKennels =  t.TotalHaringAllKennels , 
TotalPackRunsAllKennels =  t.TotalPackRunsAllKennels ,
updatedAt = getdate()
FROM HC.RunCounts rc
INNER JOIN #temp t on t.RunCountId = rc.id
WHERE (coalesce(rc.TotalHaringThisKennel,-99999) <>  t.TotalHaringThisKennel )
OR (coalesce(rc.TotalPackRunsThisKennel,-99999) <>  t.TotalPackRunsThisKennel)
OR (coalesce(rc.TotalHaringAllKennels,-99999) <>   t.TotalHaringAllKennels )
OR (coalesce(rc.TotalPackRunsAllKennels,-99999) <>  t.TotalPackRunsAllKennels )


--select * from #temp order by EventStartDatetime desc

-- find cases where Hashers have runs but have never followed a Kennel. Go ahead and insert an HKM record so we can keep
-- track of run counts
INSERT INTO [HC].[HasherKennelMap]
           ([UserId]
           ,[KennelId]
           ,[Following]
           ,[IsMember]
           ,[MismanagementRoleFlags]
           ,[AppAccessFlags]
           ,[HistoricalPackRunCount]
           ,[HistoricalHaringCount]
           ,[CurrentPackRunCount]
           ,[CurrentHaringCount]
		   ,[updatedAt])
select top 1 t.UserId
		,t.KennelId
		,0 as Following
		,0 as IsMember
		,0 as MismanagementRoleFlags
		,0 as AppAccessFlags
		,0 as HistoricalPackRunCount
		,0 as HistoricalHaringCount
		,0 as CurrentPackRunCount
		,0 as CurrentHaringCount
		,getdate()
from #temp t left outer join HC.HasherKennelMap hkm on hkm.KennelId = t.KennelId AND hkm.UserId = t.UserId
WHERE hkm.id is null AND VirginVisitorType = 0


-- now update the run counts by kennel in HasherKennelMap
update HC.HasherKennelMap SET 
	CurrentPackRunCount = t.TotalPackRunsThisKennel,
	CurrentHaringCount = t.TotalHaringThisKennel,
	DateOfLastRun = t.DateOfLastRun,
	updatedAt = getdate()
FROM HC.HasherKennelMap hkm 
inner join 
	(select max(tmp.TotalPackRunsThisKennel) as TotalPackRunsThisKennel
	,max(tmp.TotalHaringThisKennel) as TotalHaringThisKennel
	,max(tmp.eventStartDatetime) as DateOfLastRun
	,tmp.UserId
	,tmp.KennelId 
	from #temp tmp 
	group by tmp.UserId,tmp.KennelId) t
on hkm.UserId = t.UserId and hkm.KennelId = t.KennelId

drop table #temp

END

GO
/****** Object:  StoredProcedure [HC].[nonApi_fbAppEvent]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[nonApi_fbAppEvent]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC].[nonApi_fbAppEvent] AS' 
END
GO

ALTER PROCEDURE [HC].[nonApi_fbAppEvent]

@FbUserJson nvarchar(4000), -- this is JSON that was returned from a subsequent Graph API call after the Webhook was received
@FbGroupInfoJson nvarchar(4000), -- this is JSON that was returned from a subsequent Graph API call after the Webhook was received
@Verb nvarchar(150),
@UpdateTime nvarchar(50),
@fbActorId nvarchar(50), -- this is the raw ID that was provided by the original Webhook call
@fbGroupId nvarchar(50)  -- this si the raw ID that was provided by the original Webhook call

-- NOTE: If we have valid raw IDs but no JSON it means that our Facebook Graph API calls are failing

AS

-- NOTE: This is a non-API stored procedure not publicly available so we do not need to process tokens.

BEGIN

	DECLARE @userId nvarchar(100),
			@userName nvarchar(250),
			@userEmail nvarchar(250),
			@userFirstName nvarchar(100),
			@userLastName nvarchar(100)

	IF (DATALENGTH(@FbUserJson) > 10)
	BEGIN
		SET @userId = COALESCE(JSON_VALUE(@FbUserJson,'$.id'),'')
		SET @userName = COALESCE(JSON_VALUE(@FbUserJson,'$.name'),'')
		SET @userEmail = COALESCE(JSON_VALUE(@FbUserJson,'$.email'),'')
		SET @userFirstName = COALESCE(JSON_VALUE(@FbUserJson,'$.first_name'),'')
		SET @userLastName = COALESCE(JSON_VALUE(@FbUserJson,'$.last_name'),'')
	END

	DECLARE @groupId nvarchar(100),
			@groupName nvarchar(250),
			@groupDescription nvarchar(4000),
			@groupCover nvarchar(500)

	IF (DATALENGTH(@FbGroupInfoJson) > 10)
	BEGIN
		SET @groupId = COALESCE(JSON_VALUE(@FbGroupInfoJson, '$.id'),'')
		SET @groupName = COALESCE(JSON_VALUE(@FbGroupInfoJson, '$.name'),'')
		SET @groupDescription = COALESCE(JSON_VALUE(@FbGroupInfoJson, '$.description'),'')
		SET @groupCover = COALESCE(JSON_VALUE(@FbGroupInfoJson, '$.cover.source'),'')

	END

	INSERT INTO [EXT].[FbAppEvent]
			   ([UserId]
			   ,[UserName]
			   ,[UserEmail]
			   ,[UserFirstName]
			   ,[UserLastName]
			   ,[GroupId]
			   ,[GroupName]
			   ,[GroupDescription]
			   ,[GroupCoverPhoto]
			   ,[Verb]
			   ,[UpdateTime]
			   ,[FbGroupJson]
			   ,[FbUserJson]
			   ,[OriginalActorId]
			   ,[OriginalGroupId]
			   )
	select 
		@userId,
		@userName,
		@userEmail,
		@userFirstName,
		@userLastName,
		@groupId,
		@groupName,
		@groupDescription,
		@groupCover,
		COALESCE(@Verb,'<unknown>'),
		@UpdateTime,
		@FbGroupInfoJson,
		@FbUserJson,
		@fbActorId,
		@fbGroupId
	

	IF (@groupId is not null)
	BEGIN
		IF(@verb = 'delete')
		BEGIN
			-- deactivate FB integration if HC app is removed from FB group
			UPDATE HC.Kennel 
				SET IntegrationType = 'None'
				where KennelFacebookId = @groupId
		END

		IF(@verb = 'add')
		BEGIN
			-- activate FB integration if HC app is removed from FB group
			UPDATE HC.Kennel 
				SET IntegrationType = 'Facebook'
				where KennelFacebookId = @groupId
		END
	END

END
GO
/****** Object:  StoredProcedure [HC].[nonApi_getUserInviteCode]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[nonApi_getUserInviteCode]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC].[nonApi_getUserInviteCode] AS' 
END
GO

ALTER PROCEDURE [HC].[nonApi_getUserInviteCode]

@email nvarchar(250)-- this si the raw ID that was provided by the original Webhook call

AS

-- NOTE: This is a non-API stored procedure not publicly available so we do not need to process tokens.

BEGIN

	DECLARE @Loop nvarchar(10) = 'Yes',
			@EmergencyStop smallint = 0,
			@QR nvarchar(50),
			@ResetCodeLastUpdated datetimeoffset(7),
			@MinutesSinceLastReset int

	SELECT @ResetCodeLastUpdated = ResetCodeLastUpdated FROM HC.Hasher where email = @email

	IF ((@ResetCodeLastUpdated IS NULL) OR (ABS(datediff(minute,@ResetCodeLastUpdated,getdate())) > 60))
	BEGIN
		-- create a new invite code, but make sure it's unique before using it.
		WHILE (@Loop = 'Yes')
		BEGIN
			SET @EmergencyStop = @EmergencyStop + 1
			IF @EmergencyStop > 10 SET @Loop = 'No'
			SET @QR = 'URC:'+SUBSTRING(TRIM(HC.NUMBER_TO_STR_BASE (25,(RAND() * (2147483647 - 91466177)) + 91466177)),0,7)
			-- if the QR code is unique, go ahead and insert it
			IF (SELECT count(*) FROM HC.Hasher WHERE ResetCode = @QR) = 0
			BEGIN
				SET @Loop = 'No'
				UPDATE HC.Hasher set ResetCode = @QR,ResetCodeLastUpdated = getdate() WHERE email = @email
			END
		END
	END
		
	DECLARE @inviteCode nvarchar(50)

	SELECT @inviteCode = h.ResetCode from HC.Hasher h where h.email = @email

	SELECT coalesce(@inviteCode,'The email address provided was not found in our database. Please try another email address.') as inviteCode

END
GO
/****** Object:  StoredProcedure [HC].[nonApi_logError]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[nonApi_logError]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC].[nonApi_logError] AS' 
END
GO
ALTER PROCEDURE [HC].[nonApi_logError]


--$"EXEC HC.nonApi_logError @ErrorType='{errorType}',@Message='{message}'";

-- NOTE: This procedure is never called directly by the public API, so we do not need to process tokens here.

@errorType nvarchar(250) = '<unknown>',
@message nvarchar(2500) = '<unknown>',
@location nvarchar(250) = '<unknown>',
@inputText nvarchar(1000) = '<unknown>'

AS

BEGIN   

INSERT INTO [HC].[ErrorLog]
           (
		   --[id]
           [HcVersion]
          ,[ErrorName]
          ,[ErrorDescription]
          ,[ProcName]
     --      ,[userId]
     --      ,[kennelId]
     --      ,[eventId]
     --      ,[deviceId]
          ,[string_1]
     --      ,[string_2]
     --      ,[errorCode]
     --      ,[createdAt]
     --      ,[updatedAt]
     --      ,[deleted]
		   )
     VALUES
           (

		   --<id, uniqueidentifier,>
           'AzureFunctions7'
			,@errorType
            ,@message
	        ,@location
     --      ,<userId, uniqueidentifier,>
     --      ,<kennelId, uniqueidentifier,>
     --      ,<eventId, uniqueidentifier,>
     --      ,<deviceId, nvarchar(250),>
            ,@inputText
     --      ,<string_2, nvarchar(1000),>
     --      ,<errorCode, int,>
     --      ,<createdAt, datetimeoffset(7),>
     --      ,<updatedAt, datetimeoffset(7),>
     --      ,<deleted, bit,>
		   
		   )





SET NOCOUNT ON





END
GO
/****** Object:  StoredProcedure [HC].[nonApi_rptKennelRunStats]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[nonApi_rptKennelRunStats]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC].[nonApi_rptKennelRunStats] AS' 
END
GO
ALTER Procedure [HC].[nonApi_rptKennelRunStats]

@KennelId uniqueidentifier

AS

--DECLARE @KennelId uniqueidentifier
--SET @KennelId = '5029DE3A-D231-47AA-BE72-ECE9BCCD55D1'

SELECT 
	h.DisplayName as Display_name
	,e.EventName as Event_name
	,e.EventStartDatetime as Event_date
	,e.EventNumber as Run_number
	,h.id as hid
	,e.id as eid
	--,hem.id as hemId
	,(coalesce(cast((cast(p.DebitAmount as money) * 10000) as int)+p.PaymentType,99990000)+100000000) * case when hem.isHare = 1 then -1 else 1 end as paid
	,count(*) OVER (Partition by h.id order by e.EventStartDatetime) as runcount
	,sum(hem.isHare) OVER (Partition by h.id order by e.EventStartDatetime) as hareCount
	,a.Total_hashers
INTO #temp FROM HC.HasherEventMap hem 
INNER JOIN HC.Event e ON hem.EventId = e.id
INNER JOIN HC.Hasher h ON hem.UserId = h.id
LEFT OUTER JOIN HC.Payment p on p.HasherEventMapId = hem.id and p.CancelledBy_UserId IS NULL,
	(SELECT COUNT(*) AS Total_hashers, hem2.EventId 
	FROM HC.HasherEventMap hem2 INNER JOIN HC.Event e2 ON hem2.EventId = e2.id 
	WHERE e2.KennelId = @KennelId AND hem2.AttendenceState >= 20 
	GROUP BY hem2.EventId) AS a
WHERE 
	e.kennelId = @kennelId 
	AND hem.AttendenceState >= 20 
	AND a.EventId = hem.EventId
	AND e.KennelId != h.id



INSERT INTO #temp (Display_name,Event_name,Event_date,Run_number,hid,eid,paid,runcount,hareCount,Total_hashers)
SELECT 
'Visitors & Virgins',e.EventName,e.EventStartDatetime,e.EventNumber,h.id,e.id,(coalesce(cast((cast(sum(p.DebitAmount) as money) * 10000) as int),99990000)+(count(*)*100000000)),99999,0,(select top 1 Total_hashers from #temp t where t.Event_date = e.EventStartDatetime)
FROM HC.HasherEventMap hem 
INNER JOIN HC.Event e ON hem.EventId = e.id
INNER JOIN HC.Hasher h ON hem.UserId = h.id
LEFT OUTER JOIN HC.Payment p on p.HasherEventMapId = hem.id and p.CancelledBy_UserId IS NULL
	WHERE e.kennelId = @kennelId 
	AND hem.AttendenceState >= 20 
	--AND a.EventId = hem.EventId
	AND e.KennelId = h.id
	GROUP BY e.EventName,e.EventStartDatetime,e.EventNumber,h.id,e.id
--SELECT 
--	h.DisplayName as Display_name
--	,e.EventName as Event_name
--	,e.EventStartDatetime as Event_date
--	,e.EventNumber as Run_number
--	,h.id as hid
--	,e.id as eid
--	--,hem.id as hemId
--	,(coalesce(cast((cast(sum(p.DebitAmount) as money) * 10000) as int)+3,99990000)+100000000) as paid
--	,count(*) as runcount
--	,0 as hareCount
--	,a.Total_hashers as Total_hashers
--FROM HC.HasherEventMap hem 
--INNER JOIN HC.Event e ON hem.EventId = e.id
--INNER JOIN HC.Hasher h ON hem.UserId = h.id
--LEFT OUTER JOIN HC.Payment p on p.HasherEventMapId = hem.id and p.CancelledBy_UserId IS NULL,
--	(SELECT COUNT(*) AS Total_hashers, hem2.EventId 
--	FROM HC.HasherEventMap hem2 INNER JOIN HC.Event e2 ON hem2.EventId = e2.id 
--	WHERE e2.KennelId = @KennelId AND hem2.AttendenceState >= 20 
--	GROUP BY hem2.EventId) AS a
--WHERE 
--	e.kennelId = @kennelId 
--	AND hem.AttendenceState >= 20 
--	--AND a.EventId = hem.EventId
--	AND e.KennelId = h.id
--	GROUP BY h.DisplayName,e.EventName,e.EventNumber,h.id,e.id,e.EventStartDatetime,a.Total_hashers





INSERT INTO #temp (paid,hid,Display_name,eid,Event_name,Run_number,Event_date) select max(runcount), hid, Display_name,'00000000-0000-0000-0000-000000000000','Run totals',0,'1/1/2200' from #temp group by hid,Display_name
INSERT INTO #temp (paid,hid,Display_name,eid,Event_name,Run_number,Event_date) select max(hareCount), hid, Display_name,'00000000-0000-0000-0000-000000000000','Times hared',0,'1/1/2100' from #temp group by hid,Display_name

--select * from #temp where Display_name like '%virgin%'

DECLARE
    @cols nvarchar(max),
    @stmt nvarchar(max),
	@dispName nvarchar(500),
	@rc int

DECLARE xCrsr CURSOR FOR 
	SELECT Display_name,max(runcount) 
	FROM #temp 
	GROUP BY Display_name 
	ORDER BY max(runcount) DESC

OPEN xCrsr

FETCH NEXT FROM xCrsr INTO @dispName,@rc
WHILE (@@FETCH_STATUS = 0)
BEGIN
	SET @cols = isnull(@cols + ', ', '') + '[' + @dispName + ']'
	FETCH NEXT FROM xCrsr INTO @dispName,@rc
END

CLOSE xCrsr
DEALLOCATE xCrsr

SELECT @stmt = '
SELECT * FROM
(select Event_name,Run_number,Total_hashers,Event_date,Display_name,paid from #temp) as s
pivot (sum(paid) for Display_name in (' + @cols +')) as AvgIncomePerDay
order by Event_date desc
'
EXEC sp_executesql @stmt = @stmt

DROP TABLE #temp

GO
/****** Object:  StoredProcedure [HC].[nonApi_updateEventFromExternalIntegration]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[nonApi_updateEventFromExternalIntegration]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC].[nonApi_updateEventFromExternalIntegration] AS' 
END
GO

ALTER PROCEDURE [HC].[nonApi_updateEventFromExternalIntegration]

@Source nvarchar(50),
@ExternalEventId nvarchar(250),
@KennelId uniqueidentifier,
@EventName nvarchar(250) = NULL,
@EventDescription nvarchar(4000) = NULL,
@StartTime datetimeoffset = NULL,
@EventImage nvarchar(500) = NULL,
@PlaceName nvarchar(500) = NULL,
@City nvarchar(500) = NULL,
@Country nvarchar(500) = NULL,
@Region nvarchar(500) = NULL,
@SubRegion nvarchar(500) = NULL,
@Latitude decimal (18,15) = NULL,
@Longitude decimal (19,15) = NULL,
@Street nvarchar(500) = NULL,
@Zip nvarchar(100) = NULL,
@OffsetX int = NULL,
@OffsetY int = NULL,
@AbsoluteEventNumber int = NULL,
@IsCountedRun int = NULL,
@IsVisible int = NULL,
@ForceUpdate int = NULL

AS

-- NOTE: This is a non-API stored procedure not publicly available so we do not need to process tokens.

BEGIN

if (@Latitude = -1) SET @Latitude = NULL
if (@Longitude = -1) SET @Longitude  = NULL
if (@StartTime < '1900-01-01 00:00:00') SET @StartTime = NULL
if (@AbsoluteEventNumber = -1) SET @AbsoluteEventNumber = NULL
if (@IsCountedRun = -1) SET @IsCountedRun = NULL
if (@IsVisible = -1) SET @IsVisible = NULL

DECLARE @eventId UNIQUEIDENTIFIER

	DECLARE @lat DECIMAL(18,15)
	DECLARE @lon DECIMAL(19,15)
	DECLARE @geo GEOGRAPHY

--IF (SELECT COUNT(*) FROM HC.Event evt where evt.EventFacebookId = @FacebookEventId and evt.KennelId = @KennelId) > 0
IF (SELECT COUNT(*) FROM HC.Event evt where evt.KennelId = @KennelId AND ((coalesce(evt.EventFacebookId,'') = @ExternalEventId) 
OR ((evt.EventStartDatetime = cast (@StartTime as datetimeoffset)) AND (evt.EventFacebookId is null)))) > 0 -- this second line catches cases where we have an existing event in the server on the same date time as an event that has been added to FB, in this case we want to update the exsiting event with the FB data so we use EventStartDatetime and not FbEventStartDatetime
BEGIN
	DECLARE @timeChanged NVARCHAR(20)
	DECLARE @nameChanged NVARCHAR(20)
	DECLARE @descChanged NVARCHAR(20)
	DECLARE @locChanged NVARCHAR(20)
	DECLARE @evtName NVARCHAR(500)
	DECLARE @serverLat DECIMAL(18,15)
	DECLARE @serverLon DECIMAL(19,15)
	
	SELECT 
		@timeChanged = CASE WHEN ((@StartTime IS NOT NULL) AND (cast (@StartTime as datetimeoffset) <> COALESCE(evt.[FbEventStartDatetime],evt.[EventStartDatetime]))) THEN 'Time, ' ELSE '' END
		,@nameChanged = CASE WHEN ((@EventName IS NOT NULL) AND (@EventName <> evt.[FbEventName])) THEN 'Name, ' ELSE '' END
		,@descChanged = CASE WHEN ((@EventDescription IS NOT NULL) AND (@EventDescription <> evt.[FbEventDescription])) THEN 'Description, ' ELSE '' END
		,@locChanged = CASE WHEN ((@PlaceName IS NOT NULL) AND (@PlaceName <> evt.[FbLocationOneLineDesc])) THEN 'Location, ' ELSE '' END
		,@evtName = coalesce(@EventName,evt.[FbEventName])
		,@eventId = id
		,@serverLat = FbLatitude
		,@serverLon = FbLongitude
		FROM HC.Event evt WHERE evt.KennelId = @KennelId AND ((coalesce(evt.EventFacebookId,'') = @ExternalEventId) OR ((evt.EventStartDatetime = cast (@StartTime as datetimeoffset)) AND (evt.EventFacebookId is null)))
	--FROM HC.Event evt WHERE 
	--  evt.EventFacebookId = @FacebookEventId 
	--  AND evt.KennelId = @KennelId

	SELECT @lat = coalesce(@serverLat,@latitude)
	SELECT @lon = coalesce(@serverLon,@longitude)

	IF ((@lat IS NOT NULL) AND (@lon IS NOT NULL))
	BEGIN
		SET @geo = geography::Point(@lat, @lon, 4326)
	END

	UPDATE HC.Event SET 
	   [EventSource] = @Source
      ,[FacebookRecordLastUpdated] = getdate()
	  ,[EventFacebookId] = coalesce(@ExternalEventId,evt.[EventFacebookId])
      ,[FbEventStartDatetime] = coalesce(@StartTime,evt.[FbEventStartDatetime])
      ,[FbEventName] = coalesce(@EventName,evt.[FbEventName])
      ,[FbEventDescription] = coalesce(@EventDescription,evt.[FbEventDescription])
      ,[FbEventImage] = coalesce(@EventImage,evt.[FbEventImage])
      ,[FbEventImageOffsetX] = coalesce(@OffsetX,evt.[FbEventImageOffsetX])
      ,[FbEventImageOffsetY] = coalesce(@OffsetY,evt.[FbEventImageOffsetY])

      ,[FbLocationOneLineDesc] = coalesce(@PlaceName,evt.[FbLocationOneLineDesc])
      ,[FbLocationCity] = coalesce(@City,evt.[FbLocationCity])
      ,[FbLocationStreet] = coalesce(@Street,evt.[FbLocationStreet])
      ,[FbLocationPostCode] = coalesce(@Zip,evt.[FbLocationPostCode])
      ,[FbLocationCountry] = coalesce(@Country,evt.[FbLocationCountry])
	  ,[FbLocationRegion] = coalesce(@Region,evt.[FbLocationRegion])
	  ,[FbLocationSubRegion] = coalesce(@SubRegion,evt.[FbLocationSubRegion])

      ,[FbLatitude] = coalesce(@Latitude,evt.[FbLatitude])
      ,[FbLongitude] = coalesce(@Longitude,evt.[FbLongitude])
	  ,[FbEventGeolocation] = coalesce(@geo,evt.[FbEventGeolocation])

      ,[AbsoluteEventNumber] = coalesce(@AbsoluteEventNumber,evt.[AbsoluteEventNumber])

	  ,[IsCountedRun] = coalesce(@IsCountedRun,evt.[IsCountedRun])
	  ,[IsVisible] = coalesce(@IsVisible,evt.[IsVisible])
	  ,[updatedAt] = getdate()

	  FROM HC.Event evt WHERE id = @eventId
	  AND evt.UpdateDataFromFacebook != 0
	  AND 
	  (
      ((@ForceUpdate IS NOT NULL) AND (@ForceUpdate = 1))
		OR ((@StartTime IS NOT NULL) AND (cast (@StartTime as datetimeoffset) <> evt.[FbEventStartDatetime]))
		OR ((@EventName IS NOT NULL) AND (@EventName <> evt.[FbEventName]))
		OR ((@EventDescription IS NOT NULL) AND (@EventDescription <> evt.[FbEventDescription]))
		OR ((@EventImage IS NOT NULL) AND (@EventImage <> evt.[FbEventImage]))
		OR ((@OffsetX IS NOT NULL) AND (@OffsetX <> evt.[FbEventImageOffsetX]))
		OR ((@OffsetY IS NOT NULL) AND (@OffsetY <> evt.[FbEventImageOffsetY]))
		OR ((@PlaceName IS NOT NULL) AND (@PlaceName <> evt.[FbLocationOneLineDesc]))
		OR ((@ExternalEventId IS NOT NULL) AND (@ExternalEventId <> coalesce(evt.[EventFacebookId],'')))
		--OR ((@City IS NOT NULL) AND (@City <> evt.[LocationCity]))
		--OR ((@Street IS NOT NULL) AND (@Street <> evt.[LocationStreet]))
		--OR ((@Zip IS NOT NULL) AND (@Zip <> evt.[LocationPostCode]))
		--OR ((@Country IS NOT NULL) AND (@Country <> evt.[LocationCountry]))
		--OR ((@Latitude IS NOT NULL) AND (@Latitude <> coalesce(evt.[FbLatitude],-999)))
		--OR ((@Longitude IS NOT NULL) AND (@Longitude <> coalesce(evt.[FbLongitude],-999)))
		OR ((@AbsoluteEventNumber IS NOT NULL) AND (@AbsoluteEventNumber <> coalesce(evt.[AbsoluteEventNumber],-999)))
		OR ((@IsCountedRun IS NOT NULL) AND (@IsCountedRun <> coalesce(evt.[IsCountedRun],-999)))
		OR ((@IsVisible IS NOT NULL) AND (@IsVisible <> coalesce(evt.[IsVisible],-999)))
	  )

	  IF (@@ROWCOUNT = 0)
	  BEGIN
	     SELECT 'Rows updated = 0' as Result, '00000000-0000-0000-0000-000000000000' as EventId
	  END
	  ELSE
	  BEGIN
		 
		 EXEC HC.nonApi_updateRunNumbers  @eventId = @eventId

		 -- Format the text string that will be sent as a notification to mobile devices
		 DECLARE @res NVARCHAR(500)

	     SELECT @res = 'The event, ' + @evtName + ', has been updated. '

		 if (datalength (@timeChanged + @locChanged +  @descChanged + @nameChanged) > 0)
		 BEGIN
			DECLARE @changedAttributes nvarchar(150)
			SELECT @changedAttributes = @nameChanged + @timeChanged + @locChanged + @descChanged
			SELECT @changedAttributes = LEFT(@changedAttributes,(datalength(@changedAttributes) / 2) - 2) + ' '

			SELECT @res = @res + @changedAttributes + 'changed.'
		 END
		 
		 SELECT @res AS Result, @eventId as EventId

	  END

END
ELSE
BEGIN

SET @eventId = newid()

	IF ((@latitude IS NOT NULL) AND (@longitude IS NOT NULL))
	BEGIN
		SET @geo = geography::Point(@latitude, @longitude, 4326)
	END

INSERT INTO [HC].[Event]
           (id
		   ,[EventSource]
		   ,[EventFacebookId]
           ,[FacebookRecordLastUpdated]
		   ,[EventStartDatetime]
           ,[FbEventStartDatetime]
           ,[KennelId]
           ,[IsCountedRun]
		   ,[IsVisible]
           ,[AbsoluteEventNumber]
		   ,[EventName]
           ,[FbEventName]
           ,[FbEventDescription]
           ,[FbEventImage]
           ,[FbEventImageOffsetX]
           ,[FbEventImageOffsetY]
           ,[FbLocationOneLineDesc]
           ,[FbLocationCity]
           ,[FbLocationStreet]
           ,[FbLocationPostCode]
           ,[FbLocationCountry]
		   ,[FbLocationRegion]
		   ,[FbLocationSubRegion]
           ,[FbLatitude]
           ,[FbLongitude]
		   ,[FbEventGeolocation]
		   ,[UseFbLatLon]
		   ,[UseFbLocation]
		   ,[UseFbRunDetails]
		   ,[UpdateDataFromFacebook]
		   ,[updatedAt]
			)
     VALUES
           (
		    @eventId
		   ,@Source
		   ,@ExternalEventId 
           ,getdate() -- <FacebookRecordLastUpdated, datetimeoffset(7),>
           ,@StartTime 
		   ,@StartTime
           ,@KennelId 
           ,coalesce(@IsCountedRun,1)
           ,coalesce(@IsVisible,1)
           ,@AbsoluteEventNumber
           ,@EventName
		   ,@EventName
           ,@EventDescription
           ,@EventImage
           ,@OffsetX
           ,@OffsetY
           ,@PlaceName
           ,@City
           ,@Street
           ,@Zip
           ,@Country
		   ,@Region
		   ,@SubRegion
           ,@Latitude
           ,@Longitude
		   ,@geo
		   ,1
		   ,1
		   ,1
		   ,1
		   ,getdate())

    EXEC HC.nonApi_updateRunNumbers  @eventId = @eventId

	SELECT 'A new event, ' + @EventName + ', has been added from Facebook' as Result, @eventId as EventId
END


END
GO
/****** Object:  StoredProcedure [HC].[nonApi_updateRunNumbers]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC].[nonApi_updateRunNumbers]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC].[nonApi_updateRunNumbers] AS' 
END
GO
ALTER PROCEDURE [HC].[nonApi_updateRunNumbers]

-- NOTE: This procedure is never called directly by the public API, so we do not need to process tokens here.

@kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
@eventId uniqueidentifier = '00000000-0000-0000-0000-000000000000'

AS

BEGIN   

-- EXEC HC.nonApi_updateRunNumbers
-- EXEC HC.nonApi_updateRunNumbers @kennelId = '9963AD79-772C-4B56-9298-7B6E6294D131'
-- EXEC HC.nonApi_updateRunNumbers @eventId = '7747594a-d814-42be-b573-10130800f317'

SET NOCOUNT ON

	DECLARE @earliestEvent datetimeoffset(7)
	DECLARE @latestEvent datetimeoffset(7)
	
	-- if only one record was updated we don't have to update the run numbers for 
	-- the entire Kennel...  only those event records that are before and after this
	-- event that are bounded by event records with absolute run numbers need to be updated
	IF (@eventId <> '00000000-0000-0000-0000-000000000000')
	BEGIN
		SET NOCOUNT ON
		DECLARE @eventStartDate datetimeoffset(7)
		SELECT @eventStartDate = e.EventStartDatetime, @kennelId = e.KennelId FROM HC.Event e where e.id = @eventId

		SELECT @earliestEvent = max(e.EventStartDatetime) FROM HC.Event e where e.KennelId = @kennelId and e.EventStartDatetime < @eventStartDate AND e.AbsoluteEventNumber IS NOT NULL AND e.IsCountedRun = 1
		SELECT @latestEvent = min(e.EventStartDatetime) FROM HC.Event e where e.KennelId = @kennelId and e.EventStartDatetime > @eventStartDate AND e.AbsoluteEventNumber IS NOT NULL AND e.IsCountedRun = 1		
	END 
	
	-- Create a #temp table with all of the runs for a Kennel and add a column "LastAbsoluteNumber" to each row
	-- that contains a copy of the last run number that is added by the user and not calculated by the system
	-- This number will be used by the windowing function to calculate the run numbers for runs without their own AbsoluteNumber
	SELECT e.id, e.KennelId, e.EventNumberIncrement, e.AbsoluteEventNumber, 
	COALESCE(e.AbsoluteEventNumber, 
	(SELECT max(e1.AbsoluteEventNumber) from HC.Event e1 where e1.deleted = 0 and e1.isVisible <> 0 AND e1.EventStartDatetime <= e.EventStartDatetime AND e1.IsCountedRun = 1 and coalesce(e1.AbsoluteEventNumber,0) >= 0 and e1.KennelId = e.KennelId)) as LastAbsoluteNumber,
	e.EventNumber,
	e.EventStartDatetime,
	(select coalesce(min(AbsoluteEventNumber),1) from HC.Event e2 where e2.deleted = 0 and e2.IsVisible <> 0 AND e2.IsCountedRun = 1 and coalesce(e2.AbsoluteEventNumber,0) >= 0 and e2.KennelId = e.KennelId) as firstRunNumber
	into #temp
	FROM HC.Event e 
	WHERE kennelId = @kennelId AND e.deleted = 0 AND e.IsVisible <> 0 AND e.IsCountedRun = 1
	AND e.EventStartDatetime >= coalesce(@earliestEvent,'1/1/1900') AND e.EventStartDatetime < coalesce(@latestEvent,'12/31/2099')
	order by EventStartDatetime

	--select * from #temp order by EventStartDatetime

	-- any runs in the table that exist before the first AbsoluteEventNumber will still have a NULL in the LastAbsoluteNumber field
	-- this update "back fills" those rows so that all rows should now have their own LastAbsoluteNumber that can be used by the windowing function
	update #temp set LastAbsoluteNumber = HC.InlineMax(firstRunNumber - (select sum(t2.EventNumberIncrement) from #temp t2 where t2.LastAbsoluteNumber is null and coalesce(t2.AbsoluteEventNumber,0) >= 0 and t2.KennelId = t.KennelId),1)
	from #temp t
	where t.LastAbsoluteNumber is null

	-- count the records within each window and order them by event time. Add this count to the absloute event number to get the event number for each row
	-- Windowing functions cannot be used in Update statements, so we have to create a second #temp table
	
	--select * from #temp order by EventStartDatetime

	select 
		SUM(t.EventNumberIncrement) OVER (PARTITION BY t.KennelId,t.LastAbsoluteNumber ORDER BY t.EventStartDatetime ASC,t.id) - 1 + coalesce(t.LastAbsoluteNumber,1) as NewEventNumber
		,t.id
		,coalesce(k.KennelShortName,k.KennelName) + ' #' as KennelName
		,t.EventNumber
		,t.EventStartDatetime
		into #temp2 
	from #temp t
	inner join HC.Event ev on ev.id = t.id
	inner join HC.Kennel k on k.id = ev.KennelId

	--select * from #temp2 order by EventStartDatetime

	---- now update the base table accordingly with the proper event numbers
	update HC.Event 
	set EventNumber = t.NewEventNumber,updatedAt = getdate()
	--,EventName = REPLACE(EventName,'#' + CAST(t.EventNumber as nvarchar(10)),'#' + CAST(t.NewEventNumber as nvarchar(10)))
	from HC.Event e
	inner join #temp2 t on e.id = t.id 
	WHERE e.EventNumber <> t.NewEventNumber

	drop table #temp
	drop table #temp2

END
GO
/****** Object:  StoredProcedure [HC2].[getPaymentReport]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC2].[getPaymentReport]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC2].[getPaymentReport] AS' 
END
GO
ALTER PROCEDURE [HC2].[getPaymentReport]

 @userId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @accessToken nvarchar(1000) = 'none',
 @kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @eventId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @showAllTransactions smallint = 0,
 @paidTo uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @paidBy uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @includeAggregates smallint = 1

AS

BEGIN

	SET NOCOUNT ON

	if @userId = '00000000-0000-0000-0000-000000000000' SET @userId = NULL
	if @paidBy = '00000000-0000-0000-0000-000000000000' SET @paidBy = NULL
	if @paidTo = '00000000-0000-0000-0000-000000000000' SET @paidTo = NULL
	if @kennelId = '00000000-0000-0000-0000-000000000000' SET @kennelId = NULL
	if @eventId = '00000000-0000-0000-0000-000000000000' SET @eventId = NULL

	if ((@showAllTransactions != 0) AND (@showAllTransactions != 1)) SET @showAllTransactions = 0

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error'),NULL) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	select 
		hem.id as hemId,
		hem.UserId as userId,
		CASE WHEN (hem.[VirginVisitorType] <> 0)	
			THEN 
			coalesce(hem.DisplayName,'<no name>') + CASE WHEN (hem.[VirginVisitorType] = 1) THEN ' (Virgin)' ELSE ' (Visitor)' END	
			ELSE 
		coalesce(paidBy.DisplayName,hem.DisplayName) END as paidBy
	into #tempHashersNotPaid
	from HC.HasherEventMap hem 
		left outer join HC.Hasher paidBy on hem.UserId = paidBy.id
	where @eventId is not null
	-- only look at people who are actually at the event
	and hem.EventId = @eventId and hem.AttendenceState >= 20 
	-- and remove any records where the user has paid
	and hem.id not in (select pay2.HasherEventMapId from HC.Payment pay2 where pay2.EventId = @eventId and pay2.PaymentType >= 2 and pay2.CancelledBy_UserId is null)
	
	
	SELECT coalesce(sum(p.creditAmount)-sum(p.debitAmount),0) as creditAvailable
			,hnp.userId
			,hnp.hemId
			,hnp.paidBy
			,case when hkm.IsMember = 1 then coalesce(evt.EventPriceForMembers,ken.defaultEventPriceForMembers,0) else coalesce(evt.EventPriceForNonMembers,ken.defaultEventPriceForNonMembers,0) end as eventPrice
			,coun.CurrencySymbol
			,coun.DigitsAfterDecimal
	INTO #creditTemp
	FROM #tempHashersNotPaid hnp
	INNER JOIN HC.Event evt on evt.id = @eventId
	INNER JOIN HC.Kennel ken on ken.id = evt.KennelId
	INNER JOIN HC.Country coun on ken.CountryId = coun.id
	--INNER JOIN HC.HasherKennelMap hkm on hnp.userId = hkm.UserId and hkm.KennelId = evt.KennelId
	LEFT OUTER JOIN HC.HasherKennelMap hkm on hnp.userId = hkm.UserId and hkm.KennelId = evt.KennelId
	LEFT OUTER JOIN HC.Payment p on p.UserId = hnp.userId and p.CancelledDate is null
	GROUP BY hnp.userId,hnp.hemId, hnp.paidBy, 
	case when hkm.IsMember = 1 then coalesce(evt.EventPriceForMembers,ken.defaultEventPriceForMembers,0) else coalesce(evt.EventPriceForNonMembers,ken.defaultEventPriceForNonMembers,0) end,
	coun.CurrencySymbol,
	coun.DigitsAfterDecimal

	declare @hashersNotPaidCount nvarchar(20)
	select @hashersNotPaidCount = cast(count(*) as nvarchar(20)) from #tempHashersNotPaid


select * from (
	select 
		pay.HasherEventMapId as hasherEventMapId,
		pay.UserId as userIdWhoPaid,
		pay.id as paymentId,
		CASE WHEN (hem.[VirginVisitorType] <> 0)	
			THEN 
			coalesce(hem.DisplayName,'<no name>') + CASE WHEN (hem.[VirginVisitorType] = 1) THEN ' (Virgin)' ELSE ' (Visitor)' END	ELSE
		coalesce(paidBy.DisplayName,hem.DisplayName) END as paidBy, 
		coalesce(paidTo.DisplayName,'<user deleted>') as paidTo, 
		cancelledBy.DisplayName as cancelledBy, 
		pay.CreditAmount as creditAmount, 
		pay.DebitAmount as debitAmount, 
		pay.PaymentType as paymentType,
		pay.PaidDate as paymentDate,
		pay.CancelledDate as cancelledDate,
		pay.PaymentReference as paymentReference,
		pay.Notes as notes,
		0 as creditRemaining,
		coun.CurrencySymbol as currencySymbol,
		coun.DigitsAfterDecimal as digitsAfterDecimal
	from HC.Payment pay 
		inner join HC.HasherEventMap hem on hem.id = pay.HasherEventMapId
		inner join HC.Event evt on pay.EventId = evt.id
		inner join HC.Kennel k on k.id = evt.KennelId
		inner join HC.Country coun on coun.id = k.CountryId
		left outer join HC.Hasher paidBy on pay.UserId = paidBy.id
		left outer join HC.Hasher paidTo on pay.PaymentProcessedBy_userId = paidTo.id
		left outer join HC.Hasher cancelledBy on pay.CancelledBy_UserId = cancelledBy.id
	where ((@kennelId is NULL) OR (pay.KennelId = @kennelId))
		AND ((@eventId is NULL) OR (pay.EventId = @eventId))
		AND ((@showAllTransactions = 1) OR (@showAllTransactions = 0 AND pay.CancelledBy_UserId is null))
		AND ((@paidBy is NULL) OR (@paidBy = pay.UserId))
		AND ((@paidTo is NULL) OR (@paidTo = pay.PaymentProcessedBy_userId))

	union
		-- this union query will only run when an eventId is provided
		-- its purpose is to provide records of Hashers at events that have not paid yet

		select 
		t.hemId as hasherEventMapId,
		t.userId as userIdWhoPaid,
		null as paymentId,
		t.paidBy as paidBy, 
		'none' as paidTo, 
		null as cancelledBy, 
		0 as creditAmount, 
		eventPrice as debitAmount, 
		1 as paymentType,
		null as paymentDate,
		null as cancelledDate,
		'none' as paymentReference,
		null as notes,
		creditAvailable as creditRemaining,
		t.CurrencySymbol as currencySymbol,
		t.DigitsAfterDecimal as digitsAfterDecimal
	from #creditTemp t

		union
		-- this union query will only run when an eventId is provided
		-- its purpose is to provide aggregate counts by payment type

		select 
		'00000000-0000-0000-0000-000000000000' as hasherEventMapId,
		'00000000-0000-0000-0000-000000000000' as userIdWhoPaid,
		null as paymentId,
		'not used' as paidBy, 
		'not used' as paidTo, 
		null as cancelledBy, 
		coalesce(sum(pay.CreditAmount),0) as creditTotal, 
		coalesce(sum(pay.DebitAmount),0) as debitTotal, 
		(coalesce(pay.PaymentType, 1)+100) as paymentType,
		null as paymentDate,
		null as cancelledDate,
		case when (coalesce(pay.PaymentType, 1)+100) = 101 then @hashersNotPaidCount else cast(count(*) as nvarchar(20)) end as paymentReference,
		null as notes,
		0 as creditRemaining,
		'' as currencySymbol,
		0 as digitsAfterDecimal

from HC.HasherEventMap hem
left outer join HC.Payment pay on pay.HasherEventMapId = hem.id
where @eventId is not null
and CancelledBy_UserId is null
and hem.EventId = @eventId
and pay.PaymentType > 1
group by (coalesce(pay.PaymentType, 1)+100)

union 
	-- and finally tag on the aggregate count of the number of hashers who have not paid for this event
		select 
		'00000000-0000-0000-0000-000000000000' as hasherEventMapId,
		'00000000-0000-0000-0000-000000000000' as userIdWhoPaid,
		null as paymentId,
		'not used' as paidBy, 
		'not used' as paidTo, 
		null as cancelledBy, 
		0 as creditTotal, 
		0 as debitTotal, 
		101 as paymentType,
		null as paymentDate,
		null as cancelledDate,
		@hashersNotPaidCount as paymentReference,
		null as notes,
		0 as creditRemaining,
		'' as currencySymbol,
		0 as digitsAfterDecimal
		where @eventId is not null
) tbl
ORDER BY paidBy


drop table #creditTemp
drop table #tempHashersNotPaid

END
	

  
GO
/****** Object:  StoredProcedure [HC3].[addEditEvent]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[addEditEvent]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[addEditEvent] AS' 
END
GO

ALTER PROCEDURE [HC3].[addEditEvent]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @narrowEventsUpdatedAfter datetimeoffset(7),
 @eventId uniqueidentifier = null,
 @kennelId uniqueidentifier = null,
 @startDatetime datetimeoffset(7) = null,
 @endDatetime datetimeoffset(7) = null,
 @isCountedRun smallint = null,
 @isVisible smallint = null,
 @isPromotedEvent smallint = null,
 @eventGeographicScope smallint = null,
 @ThemeRunType smallint = null,
 @eventName nvarchar(120) = null,
 @eventDescription nvarchar(4000) = null,
 @locationCity nvarchar(250) = null,
 @locationStreet nvarchar(250) = null,
 @locationPostCode nvarchar(50) = null,
 @locationCountry nvarchar(250) = null,
 @locationOneLineDesc nvarchar(250) = null,
 @eventFacebookId nvarchar(250) = null,
 @coverPhotoUrl nvarchar(500) = null,
 @coverPhotoOffsetX int = null,
 @coverPhotoOffsetY int = null,
 @latitude decimal(18,15) = null,
 @longitude decimal(19,15) = null,
 @fbLatitude decimal(18,15) = null,
 @fbLongitude decimal(19,15) = null,
 @eventPriceForMembers float = null,
 @eventPriceForNonMembers float = null,
 @absoluteEventNumber smallint = null,
 @eventCurrencyType nvarchar(10) = null,
 @deleted smallint = null

AS

BEGIN

SET NOCOUNT ON

	DECLARE @errorId uniqueidentifier

	IF (@userId IS NULL) OR (@userId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF (@eventId IS NULL) OR (@eventId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty eventId','A null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty eventId' as errorTitle
		,'A null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END


	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken,NULL) = 0 
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	DECLARE @resultStr nvarchar(250)
	DECLARE @resultInt int

	if (@eventId = '00000000-0000-0000-0000-000000000000') SET @eventId = NULL
	if (@kennelId = '00000000-0000-0000-0000-000000000000') SET @kennelId = NULL
	if ((@startDatetime IS NOT NULL) AND (@startDatetime <= '1/1/1901')) SET @startDatetime = NULL
	if ((@endDatetime IS NOT NULL) AND (@endDatetime <= '1/1/1901')) SET @endDatetime = NULL
	if (@isCountedRun = -1) SET @isCountedRun = NULL
	if (@isVisible = -1) SET @isVisible = NULL
	if (@isPromotedEvent = -1) SET @isPromotedEvent = NULL
	if (@eventGeographicScope = -1) SET @eventGeographicScope = NULL
	if (@ThemeRunType = -1) SET @ThemeRunType = NULL
	if (DATALENGTH(@eventName) < 1) SET @eventName = NULL
	if (DATALENGTH(@eventDescription) < 1) SET @eventDescription = NULL
	if (DATALENGTH(@locationCity) < 1) SET @locationCity = NULL
	if (DATALENGTH(@locationStreet) < 1) SET @locationStreet = NULL
	if (DATALENGTH(@locationPostCode) < 1) SET @locationPostCode = NULL
	if (DATALENGTH(@locationCountry) < 1) SET @locationCountry = NULL
	if (DATALENGTH(@locationOneLineDesc) < 1) SET @locationOneLineDesc = NULL
	if (DATALENGTH(@eventFacebookId) < 5) SET @eventFacebookId = NULL
	if (DATALENGTH(@coverPhotoUrl) < 5) SET @coverPhotoUrl = NULL
	if (@coverPhotoOffsetX = -1) SET @coverPhotoOffsetX = NULL
	if (@coverPhotoOffsetY = -1) SET @coverPhotoOffsetY = NULL
	if (@latitude = -1) SET @latitude = NULL
	if (@longitude = -1) SET @longitude = NULL
	if (@fbLatitude = -1) SET @fbLatitude = NULL
	if (@fbLongitude = -1) SET @fbLongitude = NULL
	if (@eventPriceForMembers = -1) SET @eventPriceForMembers = NULL
	if (@eventPriceForNonMembers = -1) SET @eventPriceForNonMembers = NULL
	if (@absoluteEventNumber = -1) SET @absoluteEventNumber = NULL -- if AbsoluteEventNumber is zero, that will cause the record to null out the value currently in AbsoluteEventNumber
	if (DATALENGTH(@eventCurrencyType) < 4) SET @eventCurrencyType = NULL
	if (@deleted = -1) SET @deleted = NULL

	if (@eventFacebookId like '%break%') SET @eventFacebookId = ''
	
	DECLARE @lat DECIMAL(18,15)
	DECLARE @lon DECIMAL(19,15)
	DECLARE @geo GEOGRAPHY

	SELECT @lat = coalesce(@latitude,@fbLatitude)
	SELECT @lon = coalesce(@longitude,@fbLongitude)

	IF ((@lat IS NOT NULL) AND (@lon IS NOT NULL))
	BEGIN
		SET @geo = geography::Point(@lat, @lon, 4326)
	END

    if ((@deleted IS NOT NULL) AND (@deleted = 1))
	BEGIN
		SET NOCOUNT ON
		-- use the kennel id and date if we don't have an eventId
		--if ((@eventId = '00000000-0000-0000-0000-000000000000') OR (@eventId is null))
		--BEGIN
		--	select top 1 @eventId = id from HC.Event WHERE KennelId = @kennelId AND cast(EventStartDatetime as Date) = cast(@startDatetime as Date)
		--END

		--if ((@eventId is not null) AND (@eventId <> '00000000-0000-0000-0000-000000000000'))
		--BEGIN
		--	UPDATE HC.Event SET 
		--	deleted = 1
		--	FROM HC.Event e where e.id = @eventId
		--END
			
	END
	ELSE
	BEGIN
	-- does a record exist? If so, we are in "edit" mode
	if ((@eventId is not null) AND ((SELECT count(*) from HC.Event e where e.id = @eventId) > 0))
		BEGIN

			UPDATE HC.Event SET 
			--KennelId = coalesce(@kennelId,KennelId),
			EventStartDatetime = coalesce(@startDatetime,EventStartDatetime),
			EventEndDatetime = coalesce(@endDatetime,EventEndDatetime),
			IsCountedRun = coalesce(@isCountedRun,IsCountedRun,0),
			IsVisible = coalesce(@isVisible,IsVisible),
			IsPromotedEvent = coalesce(@isPromotedEvent,IsPromotedEvent),
			EventGeographicScope = coalesce(@eventGeographicScope,EventGeographicScope),
			ThemeRunType = coalesce(@ThemeRunType,ThemeRunType,0),
			EventName = coalesce(@eventName, EventName),
			EventDescription = coalesce(@eventDescription, EventDescription),
			LocationCity = coalesce(@locationCity, LocationCity),
			LocationStreet = coalesce(@locationStreet, LocationStreet),
			LocationPostCode = coalesce(@locationPostCode,LocationPostCode),
			LocationCountry = coalesce(@locationCountry,LocationCountry),
			LocationOneLineDesc = coalesce(@locationOneLineDesc, LocationOneLineDesc),
			EventFacebookId = coalesce(@eventFacebookId, EventFacebookId),
			EventImage = coalesce(@coverPhotoUrl, EventImage),
			EventImageOffsetX = coalesce(@coverPhotoOffsetX,EventImageOffsetX),
			EventImageOffsetY = coalesce(@coverPhotoOffsetY,EventImageOffsetY),
			Latitude = coalesce(cast(@latitude as decimal(18,15)),Latitude),
			Longitude = coalesce(cast(@longitude as decimal(19,15)),Longitude),
			FbLatitude = coalesce(cast(@fbLatitude as decimal(18,15)),FbLatitude),
			FbLongitude = coalesce(cast(@fbLongitude as decimal(19,15)),FbLongitude),
			EventGeolocation = coalesce(@geo,EventGeoLocation),
			EventPriceForMembers = coalesce(@eventPriceForMembers,EventPriceForMembers),
			EventPriceForNonMembers = coalesce(@eventPriceForNonMembers,EventPriceForNonMembers),
			AbsoluteEventNumber = case when @absoluteEventNumber = 0 then null else coalesce(@absoluteEventNumber, AbsoluteEventNumber) end,
			EventCurrencyType = coalesce(@eventCurrencyType, EventCurrencyType),
			deleted = coalesce(@deleted, deleted),
			updatedAt = getdate()
			FROM HC.Event e where e.id = @eventId

			set @resultStr = 'Updated record x ' + cast (@eventId as nvarchar(50)) + ' set name to: ' + coalesce(@eventName,'opps, it is null!')
			set @resultInt = 1
		END
		ELSE
		BEGIN
			-- record does not exist, we're in insert mode
			if ((datalength(Trim(@eventName)) > 0) AND (@startDatetime is not null) AND ((@kennelId is not null) AND (@kennelId <> '00000000-0000-0000-0000-000000000000')))
			BEGIN

				if (cast(@startDatetime as time) = '00:00:00.0000000')
				BEGIN
					DECLARE	 @time time(7),
							 @diffSeconds int

					SELECT @time = DefaultRunStartTime from HC.Kennel where id = @kennelId

					if (@time is not null) 
					BEGIN
						SELECT @diffSeconds = datediff(second,'00:00:00',@time)
						SET @startDateTime = dateadd(second,@diffSeconds,@startDateTime)
					END
				END

				if (@eventId is null) SET @eventId = newid()

				if ((@kennelId is not null) AND (@kennelId != '00000000-0000-0000-0000-000000000000'))
				BEGIN
					SELECT @eventPriceForMembers = coalesce(@eventPriceForMembers,k.DefaultEventPriceForMembers),
							@eventPriceForNonMembers = coalesce(@eventPriceForNonMembers,k.DefaultEventPriceForNonMembers)
					 from HC.Kennel k WHERE k.id = @kennelId
				END

				INSERT HC.Event 
					(
						id
						,KennelId
						,EventStartDatetime
						,EventEndDatetime
						,IsCountedRun
						,IsVisible
						,IsPromotedEvent
						,EventGeographicScope
						,ThemeRunType
						,EventName
						,EventDescription
						,LocationCity
						,LocationStreet
						,LocationPostCode
						,LocationCountry
						,LocationOneLineDesc
						,EventFacebookId
						,EventImage
						,EventImageOffsetX
						,EventImageOffsetY
						,Latitude
						,Longitude
						,FbLatitude
						,FbLongitude
						,EventGeolocation
						,EventPriceForMembers
						,EventPriceForNonMembers
						,AbsoluteEventNumber
						,EventCurrencyType
						,deleted
						,updatedAt
					) VALUES 
					(
						@eventId
						,@KennelId
						,@startDatetime
						,@endDatetime
						,coalesce(@isCountedRun,0)
						,coalesce(@isVisible,1)
						,coalesce(@isPromotedEvent,0)
						,coalesce(@eventGeographicScope,0)
						,coalesce(@ThemeRunType,0)
						,@eventName
						,@eventDescription
						,@locationCity
						,@locationStreet
						,@locationPostCode
						,@locationCountry
						,@locationOneLineDesc
						,@eventFacebookId
						,@coverPhotoUrl
						,coalesce(@coverPhotoOffsetX,0)
						,coalesce(@coverPhotoOffsetY,0)
						,cast(@latitude as decimal(18,15))
						,cast(@longitude as decimal(19,15))
						,cast(@fbLatitude as decimal(18,15))
						,cast(@fbLongitude as decimal(19,15))
						,@geo
						,@eventPriceForMembers
						,@eventPriceForNonMembers
						,@absoluteEventNumber
						,@eventCurrencyType,coalesce(@deleted,0)
						,getdate()
					)

				SET @resultStr = 'Insert succeeded'
				SET @resultInt = 1
			END
		END
	END

	EXEC HC.nonApi_updateRunNumbers @eventId = @eventId
	
	DECLARE @RC int

	DECLARE @procName nvarchar(100)
	SET @procName = OBJECT_NAME(@@PROCID)

	EXECUTE @RC = [HC3].[syncUserData] 
	   @userId
	  ,@accessToken
	  ,@hashersUpdatedAfter = 'ignore'
	  ,@citiesUpdatedAfter = 'ignore'
	  ,@regionsUpdatedAfter = 'ignore'
	  ,@countriesUpdatedAfter = 'ignore'
	  ,@kennelsUpdatedAfter = 'ignore'
	  ,@hasherKennelMapUpdatedAfter = 'ignore'
	  ,@hasherEventMapUpdatedAfter = 'ignore'
	  ,@narrowEventsUpdatedAfter = @narrowEventsUpdatedAfter
	  ,@procName = @procName
	  ,@param = NULL
	  

END






GO
/****** Object:  StoredProcedure [HC3].[addEditReceipt]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[addEditReceipt]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[addEditReceipt] AS' 
END
GO



ALTER PROCEDURE [HC3].[addEditReceipt]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @receiptId uniqueidentifier,
 @eventId uniqueidentifier,
 @receiptShortDesc nvarchar(500),
 @receiptAmount decimal(12,4),
 @notes nvarchar(1000),
 @reimbursedBy uniqueidentifier,
 @reimbursedOn nvarchar(50),
 @reimbursedAmount decimal(12,4),
 @reimbursedNotes nvarchar(1000),
 @imageUrl nvarchar(1000),
 @receiptsUpdatedAfter nvarchar(50),
 @removed smallint

AS

BEGIN

-- EXEC HC.joinKennel @kennelId = '9e85d401-213d-47ad-8a6e-44e5476925f4', @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @state = '1'

	SET NOCOUNT ON

	DECLARE @errorId uniqueidentifier

	IF (@removed = -1) SET @removed = NULL
	IF (@reimbursedAmount < 0) SET @reimbursedAmount = NULL
	IF (@reimbursedBy = '00000000-0000-0000-0000-000000000000') SET @reimbursedBy = NULL
	IF (@reimbursedNotes = '') SET @reimbursedNotes = NULL
	IF (@notes = '') SET @notes = NULL
	IF (@receiptAmount < 0) SET @receiptAmount = NULL
	IF (@receiptShortDesc = '') SET @receiptShortDesc = NULL

	IF (@userId IS NULL) OR (@userId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF (@eventId IS NULL) OR (@eventId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty eventId','A null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty eventId' as errorTitle
		,'A null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken,NULL) = 0 
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	DECLARE 
		@finished smallint,
		@reimbursedOnDate datetimeoffset(7)
		
	SET @reimbursedOnDate = CAST(@reimbursedOn as datetimeoffset(7)) 
	if (@reimbursedOnDate < '1/1/2000') SET @reimbursedOnDate = NULL

	SET @finished = 0
	

	if (datalength(@imageUrl) < 20) SET @imageUrl = NULL
	
	if ((@receiptId IS NOT NULL) AND (@receiptId != '00000000-0000-0000-0000-000000000000'))
	BEGIN
		IF ((@reimbursedBy IS NOT NULL) AND (@reimbursedBy != '00000000-0000-0000-0000-000000000000') AND (@reimbursedBy != 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF'))
		BEGIN
			SET @reimbursedOnDate = getdate()
			SELECT @reimbursedAmount = ReceiptAmount from HC.Receipt where id = @receiptId
		END

		if ((SELECT count(*) from HC.Receipt where id = @receiptId) > 0)
		BEGIN
			UPDATE HC.Receipt 
				SET 
					ReceiptAmount = coalesce(@receiptAmount,ReceiptAmount),
					ReceiptShortDesc = coalesce(@receiptShortDesc,ReceiptShortDesc),
					UserId = @userId,
					ImageUrl = coalesce(@imageUrl,ImageUrl),
					removed = coalesce(@removed,removed),
					notes = coalesce(@notes,Notes),
					ReimbursedBy = CASE WHEN @reimbursedBy = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF' THEN NULL ELSE coalesce(@reimbursedBy,ReimbursedBy) END,
					ReimbursedOn = CASE WHEN @reimbursedBy = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF' THEN NULL ELSE coalesce(@reimbursedOnDate,ReimbursedOn) END,
					ReimbursedAmount = CASE WHEN @reimbursedBy = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF' THEN NULL ELSE coalesce(@reimbursedAmount,ReimbursedAmount) END,
					ReimbursedNotes = CASE WHEN @reimbursedBy = 'FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF' THEN NULL ELSE coalesce(@reimbursedNotes,ReimbursedNotes) END,
					updatedAt = getdate()
				 WHERE id = @receiptId
			SET @finished = 1
		END	
	END

	if (@finished = 0)
	BEGIN
		SET @receiptId = newid()
	
		INSERT HC.Receipt (
			id,
			EventId,
			UserId,
			ReceiptAmount,
			CostCategory,
			DateUploaded,
			ImageUrl,
			ReceiptShortDesc,
			Notes,
			ReimbursedBy,
			ReimbursedOn,
			ReimbursedAmount,
			ReimbursedNotes,
			removed,
			updatedAt
		)
		VALUES (
			@receiptId, 
			@eventId, 
			@userId, 
			@receiptAmount, 
			0, 
			getdate(), 
			@imageUrl,
			@receiptShortDesc,
			@notes,
			@reimbursedBy,
			@reimbursedOnDate,
			@reimbursedAmount,
			@reimbursedNotes,
			@removed,getdate())

	END

		DECLARE @procName nvarchar(500)
		SET @procName = OBJECT_NAME(@@PROCID)

		EXEC HC3.syncEventAdminData 
		 @userId = @userId,
		 @accessToken = @accessToken,
		 @eventId = @eventId,
		 @hashersUpdatedAfter = 'ignore',
		 @hasherEventMapUpdatedAfter = 'ignore',
		 @hasherKennelMapUpdatedAfter = 'ignore',
		 @narrowEventsUpdatedAfter = 'ignore',
		 @paymentsUpdatedAfter = 'ignore', 
		 @receiptsUpdatedAfter = @receiptsUpdatedAfter,
		 @procName = @procName,
		 @param = NULL
END





GO
/****** Object:  StoredProcedure [HC3].[addEditUser]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[addEditUser]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[addEditUser] AS' 
END
GO

ALTER PROCEDURE [HC3].[addEditUser]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @hcVersion nvarchar(250),
 @hashersUpdatedAfter nvarchar(50),
 @hasherEventMapUpdatedAfter nvarchar(50),
 @hasherKennelMapUpdatedAfter nvarchar(50),
 @targetUserId uniqueidentifier,
 @email nvarchar(250) = null,
 @firstName nvarchar(100) = null,
 @lastName nvarchar(100) = null,
 @hashName nvarchar(100) = null,
 @photo nvarchar(500) = null,
 @includeInGlobalHashDirectory int = null,
 @preferences int = null,
 @eventId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @historicalPackRunCount int = null,
 @historicalHaringCount int = null,
 @historicalCountIsEstimate int = null,
 @followKennelOnAddNewUser int = null

AS

BEGIN

SET NOCOUNT ON

-- NOTES: This proc edits an existing user... either the user who called it or an admin who is editing another user's record

	DECLARE @errorId uniqueidentifier

	IF (@userId IS NULL)
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	DECLARE @paramString nvarchar(250)

	SET @paramString = upper(cast(coalesce(@targetUserId,'00000000-0000-0000-0000-000000000000') as nvarchar(50))) 

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken,@paramString) = 0 
	BEGIN
		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,string_1) VALUES (@errorId,@hcVersion,'Invalid access token','The access token did not validate',OBJECT_NAME(@@PROCID),@userId,cast(@targetUserId as nvarchar(40)))

		select 
		@errorId as errorId,
		cast (1 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'A security safety feature has been activated. Contact the Harrier Central support team at connect@harriercentral.com to resolve the issue.' as errorUserMessage
		,'This could be an indication that there is an error in the code. It can also be a sign of potential malicious activity.' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	if (@targetUserId != '00000000-0000-0000-0000-000000000000')
	BEGIN
		if (SELECT count(*) from HC.Hasher h where h.id = @targetUserId) = 0
		BEGIN

			SET @errorId = newid()

			INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,string_1) VALUES (@errorId,@hcVersion,'User not found','The userId provided to the edit user interface was not found. It is possible that this user has been deleted from Harrier Central.',OBJECT_NAME(@@PROCID),@userId,cast(@targetUserId as nvarchar(40)))

			select 
			@errorId as errorId,
			cast (5 as int) as errorType 
			,'User not found' as errorTitle
			,'The userId provided to the edit user interface was not found. It is possible that this user has been deleted from Harrier Central.' as errorUserMessage
			,'This is a standard error that is anticipated and does not require debugging' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
			RETURN
		END
	END

	if (@firstName = '') SET @firstName = null
	if (@lastName = '') SET @lastName = null
	if (@photo = '') SET @photo = null
	if (@email = '') SET @email = null
	if (@hashName = '') SET @hashName = null
	if (@includeInGlobalHashDirectory = -1) SET @includeInGlobalHashDirectory = NULL
	if (@preferences = -1) SET @preferences = NULL

	IF (@email is not null)
	BEGIN
		IF (SELECT count(*) from HC.Hasher h where h.Email = trim(@email) and h.id <> @targetUserId) > 0
		BEGIN
			SET @errorId = newid()

			INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,string_1) VALUES (@errorId,@hcVersion,'Duplicate email','A user being edited is being registered with a duplicate e-mail address to one already in the system',OBJECT_NAME(@@PROCID),@userId,@email)

			select 
			@errorId as errorId,
			cast (10005 as int) as errorType 
			,'Email address already exists' as errorTitle
			,'A user already exists with this e-mail address in the system. Please register with a different e-mail address.' as errorUserMessage
			,'This is a standard error that is anticipated and does not require debugging' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
			RETURN
		END
	END

	IF (@targetUserId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @targetUserId = newid()

		INSERT [HC].[Hasher]
			   ([id]
			   ,[FirstName]
			   ,[LastName]
			   ,[Email]
			   ,[HashName]
			   ,[Photo]
			   ,[DisplayName]
			   ,[NameDisplayPreference]
			   ,[IncludeInGlobalHashDirectory]
			   ,[Preferences]
			   ,[updatedAt])
		 VALUES
			   (@targetUserId,
				coalesce(@firstName,''),
				coalesce(@lastName,''),
				coalesce(@email, ''),
				coalesce(@hashName, ''),
				coalesce(@photo, ''),
				CASE WHEN datalength(coalesce(@hashName,'')) != 0 
					THEN @hashName
				ELSE
					coalesce(@firstName,'') + ' ' + coalesce(@lastName,'')
				END,
				CASE WHEN datalength(coalesce(@hashName,'')) != 0 
					THEN 1
				ELSE
					2
				END,
				COALESCE(@includeInGlobalHashDirectory,0),
				COALESCE(@preferences,0),
				getdate())


		IF ((@eventId IS NOT NULL) AND (@eventId != '00000000-0000-0000-0000-000000000000'))
		BEGIN

			INSERT INTO HC.RunCounts ([TotalPackRunsThisKennel]
			   ,[TotalHaringThisKennel]
			   ,[TotalPackRunsAllKennels]
			   ,[TotalHaringAllKennels]
			   ,[updatedAt]) VALUES (0,0,0,0,GETDATE())
		
			INSERT INTO HC.HasherEventMap(UserId,EventId,RunCountId,RsvpState,AttendenceState,UserStartEvent,Rsvp,updatedAt) VALUES (@targetUserId,@eventId,@@IDENTITY,3,0,GETDATE(),GETDATE(),GETDATE()) 

		END

		IF ((@kennelId IS NOT NULL) AND (@kennelId != '00000000-0000-0000-0000-000000000000') AND (coalesce(@followKennelOnAddNewUser,0) != 0))
		BEGIN
			INSERT INTO [HC].[HasherKennelMap]
           (
           [UserId]
           ,[KennelId]
           ,[Following]
           ,[IsMember]
		   ,[IsHomeKennel]
           ,[MismanagementRoleFlags]
           ,[UserRoleFlags]
           ,[AppAccessFlags]
           ,[HistoricalPackRunCount]
           ,[HistoricalHaringCount]
		   ,[HistoricalCountIsEstimate]
           ,[CurrentPackRunCount]
           ,[CurrentHaringCount]
           ,[MemberSince]
           ,[removed]
           ,[updatedAt])
			 VALUES (
				   @targetUserId,
				   @kennelId,
				   1, -- following (show up in the member list by setting following to 1)
				   0, -- IsMember (we want them to show up in the member list, but we don't want them to actually be a member yet because they might not have paid membership fees)
				   0, -- IsHomeKennel
				   0, -- MismanagementRoleFlags
				   0, -- UserRoleFlags
				   0, -- AppAccessFlags
				   coalesce(@historicalPackRunCount,0), -- HistoricalRunCount
				   coalesce(@historicalHaringCount,0), -- HistoricalHaringCount
				   coalesce(@historicalCountIsEstimate,0),
				   CASE WHEN ((@eventId IS NOT NULL) AND (@eventId != '00000000-0000-0000-0000-000000000000')) THEN 1 ELSE 0 END, -- CurrentPackRunCount
				   0, -- CurrentHaringCount
				   getdate(), -- member since
				   0, -- removed
				   getdate() -- updated At
				  )

		END
		ELSE
		BEGIN
			-- for new users, set them up to follow a kennel so some runs will show
			DECLARE @amsKennelId uniqueidentifier
			DECLARE @filthKennelId uniqueidentifier

			SELECT TOP 1 @amsKennelId = id from HC.Kennel where KennelName like '%Amsterdam%'
			SELECT TOP 1 @filthKennelId = id from HC.Kennel where KennelName like '%FILTH%'

			IF (@amsKennelId is not null)
			BEGIN
			   INSERT INTO [HC].[HasherKennelMap]
			   (
			   [UserId]
			   ,[KennelId]
			   ,[Following]
			   ,[IsMember]
			   ,[IsHomeKennel]
			   ,[MismanagementRoleFlags]
			   ,[UserRoleFlags]
			   ,[AppAccessFlags]
			   ,[HistoricalPackRunCount]
			   ,[HistoricalHaringCount]
			   ,[HistoricalCountIsEstimate]
			   ,[CurrentPackRunCount]
			   ,[CurrentHaringCount]
			   ,[MemberSince]
			   ,[removed]
			   ,[updatedAt])
				 VALUES (
					   @targetUserId,
					   @amsKennelId,
					   1, -- following (show up in the member list by setting following to 1)
					   0, -- IsMember (we want them to show up in the member list, but we don't want them to actually be a member yet because they might not have paid membership fees)
					   0, -- IsHomeKennel
					   0, -- MismanagementRoleFlags
					   0, -- UserRoleFlags
					   0, -- AppAccessFlags
					   0, -- HistoricalRunCount
					   0, -- HistoricalHaringCount
					   0, -- historicalCountIsEstimate
					   0, -- CurrentPackRunCount
					   0, -- CurrentHaringCount
					   getdate(), -- member since
					   0, -- removed
					   getdate() -- updated At
					  )
			END

			IF (@filthKennelId is not null)
			BEGIN
			   INSERT INTO [HC].[HasherKennelMap]
			   (
			   [UserId]
			   ,[KennelId]
			   ,[Following]
			   ,[IsMember]
			   ,[IsHomeKennel]
			   ,[MismanagementRoleFlags]
			   ,[UserRoleFlags]
			   ,[AppAccessFlags]
			   ,[HistoricalPackRunCount]
			   ,[HistoricalHaringCount]
			   ,[HistoricalCountIsEstimate]
			   ,[CurrentPackRunCount]
			   ,[CurrentHaringCount]
			   ,[MemberSince]
			   ,[removed]
			   ,[updatedAt])
				 VALUES (
					   @targetUserId,
					   @filthKennelId,
					   1, -- following (show up in the member list by setting following to 1)
					   0, -- IsMember (we want them to show up in the member list, but we don't want them to actually be a member yet because they might not have paid membership fees)
					   0, -- IsHomeKennel
					   0, -- MismanagementRoleFlags
					   0, -- UserRoleFlags
					   0, -- AppAccessFlags
					   0, -- HistoricalRunCount
					   0, -- HistoricalHaringCount
					   0, -- historicalCountIsEstimate
					   0, -- CurrentPackRunCount
					   0, -- CurrentHaringCount
					   getdate(), -- member since
					   0, -- removed
					   getdate() -- updated At
					  )
			END

		END
	END
	ELSE
		BEGIN
		-- this stored proc is not used to add members to kennels or events
		-- when updating a Hasher, only when inserting one, so all we have to
		-- handle here is the update hasher case
		UPDATE HC.Hasher 
		SET
		FirstName = coalesce(@firstName,FirstName),
		LastName = coalesce(@lastName,LastName),
		Email = coalesce(@email, Email),
		HashName = coalesce(@hashName, HashName),
		Photo = coalesce(@photo, Photo),
		DisplayName = CASE WHEN h.NameDisplayPreference = 1
				THEN coalesce(@hashName, h.HashName)
			WHEN h.NameDisplayPreference = 2
				THEN coalesce(@firstName,h.FirstName) + ' ' + coalesce(@lastName,h.LastName)
			ELSE coalesce(@hashName, h.HashName) + ' (' + coalesce(@firstName,h.FirstName) + ' ' + coalesce(@lastName,h.LastName) + ')' END,
		IncludeInGlobalHashDirectory = coalesce(@IncludeInGlobalHashDirectory,IncludeInGlobalHashDirectory),
		Preferences = coalesce(@preferences,Preferences),
		updatedAt = getdate()
		FROM HC.Hasher h where id = @targetUserId

		IF ((@kennelId IS NOT NULL) AND (@kennelId != '00000000-0000-0000-0000-000000000000') AND ((@historicalHaringCount is not null) OR (@historicalPackRunCount is not null)))
		BEGIN
			UPDATE HC.HasherKennelMap 
				SET 
					HistoricalHaringCount = coalesce(@historicalHaringCount,HistoricalHaringCount),
					HistoricalPackRunCount = coalesce(@historicalPackRunCount,HistoricalPackRunCount),
					HistoricalCountIsEstimate = coalesce(@historicalCountIsEstimate,HistoricalCountIsEstimate)
		FROM HC.HasherKennelMap 
		WHERE userId = @targetUserId AND KennelId = @kennelId
		END

	END

	DECLARE @RC int

	DECLARE @procName nvarchar(100)
	SET @procName = OBJECT_NAME(@@PROCID)


	IF (@userId = '00000000-0000-0000-0000-000000000000')
	BEGIN
		-- this case is for when a new user is being created because someone
		-- is adding an account when installing an app for the first time
		SELECT 
			h.id as hasherId,
			coalesce(h.FirstName,'') as firstName,
			coalesce(h.LastName,'') as lastName,
			coalesce(h.DisplayName,'') as dispName,
			coalesce(h.HashName,'') as hashName,
			coalesce(h.Photo,'') as photo,
			coalesce(h.NameDisplayPreference,0) as dispPref,
			coalesce(h.SupportCode,'') as supportCode,
			coalesce(h.ResetCode,'') as resetCode,
			coalesce(h.FacebookId,'') as facebookId,
			coalesce(h.QR_code,'') as qrCode,
			coalesce(h.QR_secret_code,'') as qrSecretCode,
			--coalesce(h.Preferences,0) as preferences,
			--coalesce(h.IncludeInGlobalHashDirectory,0) as includeInGlobalHashDirectory,
			coalesce(h.updatedAt,getdate()) as updatedAt,
			coalesce(h.Removed,0) as removed
			-- either sync the users, or in the case when a new user has been added (@targetUserId has been specified), return only that one record
		FROM HC.Hasher h where h.id = @targetUserId

	END
	ELSE
	BEGIN
		IF ( ((@eventId IS NULL) OR (@eventId = '00000000-0000-0000-0000-000000000000')) AND ((@kennelId IS NULL) OR (@kennelId = '00000000-0000-0000-0000-000000000000')))
		BEGIN
			-- this case is when a user is being edited but is not being added as a member of a Kennel or
			-- or added to an event
			EXECUTE @RC = [HC3].[syncUserData] 
			@userId = @userId
			,@accessToken = @accessToken
			,@hashersUpdatedAfter = @hashersUpdatedAfter
			,@citiesUpdatedAfter = 'ignore'
			,@regionsUpdatedAfter = 'ignore'
			,@countriesUpdatedAfter = 'ignore'
			,@kennelsUpdatedAfter = 'ignore'
			,@hasherKennelMapUpdatedAfter ='ignore'
			,@hasherEventMapUpdatedAfter = 'ignore'
			,@narrowEventsUpdatedAfter = 'ignore'
			,@procName = @procName
			,@param = @paramString 
				
		END
		ELSE IF ((@eventId IS NOT NULL) AND (@eventId != '00000000-0000-0000-0000-000000000000'))
		BEGIN
			-- this case is when a user is being added and also needs to be added to an event
			-- the user can be added as just a Hasher or can also be added as a member of the
			-- Kennel
			EXECUTE @RC = [HC3].[syncEventAdminData]
			@userId = @userId
			,@accessToken = @accessToken
			,@eventId = @eventId
			,@hashersUpdatedAfter = @hashersUpdatedAfter
			,@hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter
			,@hasherKennelMapUpdatedAfter = 'ignore'
			,@narrowEventsUpdatedAfter = 'ignore'
			,@paymentsUpdatedAfter = 'ignore'
			,@receiptsUpdatedAfter = 'ignore'
			,@procName = @procName
			,@param = @paramString
		END
		ELSE IF ((@kennelId IS NOT NULL) AND (@kennelId != '00000000-0000-0000-0000-000000000000'))
		BEGIN
			-- this case is when a user is being added and also needs to be added as a 
			-- Kennel member
			EXECUTE @RC = [HC3].[syncKennelAdminData] 
			@userId
			,@accessToken
			,@kennelId = @kennelId
			,@kennelsUpdatedAfter = 'ignore'
			,@hashersUpdatedAfter =  @hashersUpdatedAfter
			,@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter
			,@procName = @procName
			,@param = @paramString	
		END
	END

END





GO
/****** Object:  StoredProcedure [HC3].[admin_dataIntegrityCheck]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[admin_dataIntegrityCheck]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[admin_dataIntegrityCheck] AS' 
END
GO

ALTER PROCEDURE [HC3].[admin_dataIntegrityCheck]

AS

SELECT 'Orphaned payments: Payments in system for hashers that were not at a hash'

select k.KennelShortName,e.EventName,e.EventNumber,e.IsVisible, e.DoTrackHashCash, e.EventStartDatetime, h.displayName, pay.creditAmount, pay.DebitAmount, hem.AttendenceState from HC.HasherEventMap hem
inner join HC.Payment pay on pay.HasherEventMapId = hem.id
inner join HC.Hasher h on h.id = hem.UserId
INNER JOIN HC.Event e on e.id = pay.EventId
INNER JOIN HC.Kennel k on k.id = e.KennelId
WHERE (hem.AttendenceState < 20 OR e.IsVisible = 0 OR e.DoTrackHashCash = 0) AND pay.CancelledBy_UserId is null
order by k.KennelShortName, e.EventStartDatetime, PaidDate desc

GO
/****** Object:  StoredProcedure [HC3].[approveLogin]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[approveLogin]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[approveLogin] AS' 
END
GO


ALTER PROCEDURE [HC3].[approveLogin]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@deviceId nvarchar(100),
@deviceType nvarchar(100),
@deviceName nvarchar(100),
@systemName nvarchar(100),
@systemVersion nvarchar(100),
@manufacturer nvarchar(100),
@latitude decimal(18,15),
@longitude decimal (19,15),
@hcVersion nvarchar(200) = 'pre 0.6.4',
@fbToken nvarchar(500) = null

AS

BEGIN

	SET NOCOUNT ON

-- EXEC HC.approveLaunch @userId = '00000000-0000-0000-0000-000000000000', @accessToken = '', @deviceId = 'TestDevice', @deviceType = 'iPhone 6s / iOS 11.4', @latitude = 52.4, @longitude = 4.4

	DECLARE @paramString nvarchar(500)
	SET @paramString = cast (@deviceId as nvarchar(50))

	DECLARE @errorId uniqueidentifier

	IF (@userId IS NULL)
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END


	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken,@paramString) = 0 
	BEGIN
		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,string_1) VALUES (@errorId,@hcVersion,'Invalid access token','The access token did not validate',OBJECT_NAME(@@PROCID),@userId,cast(@deviceId as nvarchar(40)))

		select 
		@errorId as errorId,
		cast (1 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'A security safety feature has been activated. Contact the Harrier Central support team at connect@harriercentral.com to resolve the issue.' as errorUserMessage
		,'This could be an indication that there is an error in the code. It can also be a sign of potential malicious activity.' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	DECLARE @userName nvarchar(250),
			@email nvarchar(250)

	SELECT @userName = coalesce(h.displayName, h.firstName + ' ' + h.lastName, '<no name>'),
		   @email = h.Email,
		   @fbToken = coalesce(@fbToken,h.FacebookAccessToken)
	FROM HC.Hasher h WHERE h.id = @userId

	UPDATE HC.Hasher set FacebookAccessToken = @fbToken, FacebookAccessTokenLastUpdated = getdate() FROM HC.Hasher where id = @userId and FacebookAccessToken != @fbToken
	UPDATE HC.Kennel set KennelFacebookToken = @fbToken, KennelFacebookTokenLastUpdated = getdate() FROM HC.Kennel where KennelFacebookTokenUsername = @email AND KennelFacebookToken != @fbToken

	INSERT HC.LaunchAndLogin 
	(
		UserId
		,UserName
		,HcVersion
		,DeviceType
		,DeviceId
		,DeviceName
		,SystemName
		,SystemVersion
		,Manufacturer
		,Latitude
		,Longitude
	)
	VALUES
	(
		@userId
		,@userName
		,@hcVersion
		,@deviceType
		,@deviceId
		,@deviceName
		,@systemName
		,@systemVersion
		,@manufacturer
		,@latitude
		,@longitude
	)

	DECLARE @ServerStatusCode smallint
	DECLARE @LoginMessageTitle nvarchar(120)
	DECLARE @LoginMessage nvarchar(500)
	DECLARE @MessageEndDate datetimeoffset(7)
	DECLARE @MessageDisplayType smallint
	DECLARE @MessageImageUrl nvarchar(500)

	-- Server status codes (to be implemented)
	-- 0 - Server down for maintenance
	-- 1 - Server full up
	-- 2 - Server running degraded

	-- Message display type codes
	-- 0 - None
	-- 1 - Alert
	-- 2 - Full view
	-- 3 - Full view with countdown timer
	-- 4 - Image from URL, do not continue
	-- 5 - Image from URL, allow continue

	-- Approval codes (to be implemented)
	-- 0 - Unknown
	-- 1 - Approved for login
	-- 2 - Not authorized device
	-- 3 - User account does not exist
	-- 4 - User account not authorized

	SELECT TOP 1 
	@ServerStatusCode = smp.ServerStatusCode,
	@LoginMessageTitle = smp.LoginMessageTitle,
	@LoginMessage = smp.LoginMessage,
	@MessageEndDate = smp.MessageWindowCloses,
	@MessageDisplayType = smp.MessageDisplayType,
	@MessageImageUrl = smp.MessageImageUrl
	FROM HC.LoginNotifications smp
	WHERE getdate() between smp.MessageWindowOpens and smp.MessageWindowCloses order by CreatedDate desc

	if (@ServerStatusCode is null) SET @ServerStatusCode = 1
	if (@LoginMessageTitle is null) SET @LoginMessageTitle = 'Harrier Central Message'
	if (@LoginMessage is null) SET @LoginMessage = 'Server running'
	if (@MessageEndDate is null) SET @MessageEndDate = '1/1/2100'
	if (@MessageDisplayType is null) SET @MessageDisplayType = 0
	if (@MessageImageUrl is null) SET @MessageImageUrl = ''

	DECLARE @ApprovalCode int
	SET @ApprovalCode = 1

	SELECT TOP 1 
		svr.ApiVersion as apiVersion
		,case when @ServerStatusCode = 1 then @ApprovalCode else 0 end as approvalCode
		,@LoginMessageTitle as loginMessageTitle
		,@LoginMessage as loginMessage
		,@ServerStatusCode as serverStatusCode
		,@MessageEndDate as messageEndDate
		,@MessageDisplayType as messageDisplayType
		,@MessageImageUrl as messageImageUrl
		,svr.IosDownloadLink as iosDownloadLink
		,svr.AndroidDownloadLink as androidDownloadLink
		,svr.ImageRootUrl as imageRootUrl
	FROM HC.ServerStatus svr
	ORDER BY svr.CreatedDate desc

END
GO
/****** Object:  StoredProcedure [HC3].[authorizeDevice]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[authorizeDevice]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[authorizeDevice] AS' 
END
GO
ALTER PROCEDURE [HC3].[authorizeDevice]

 @userId nvarchar(50),
 @accessToken nvarchar(1000),
 @hcVersion nvarchar(250),
 @scanText nvarchar(250),
 @deviceId nvarchar(250),
 @includeInGlobalHashDirectory int = -1

AS

BEGIN

SET NOCOUNT ON
-- EXEC HC.authorizeDevice @scanText = 'USC:73b9e85c-b8e0-4edb-8a9e-ea55cdfa0de6 ', @deviceId = '0C2852D4-A60E-4BA9-8628-4B0F246034C4'

	IF HC.CHECK_ACCESS_TOKEN('00000000-0000-0000-0000-000000000000',OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error'),null) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

IF (@includeInGlobalHashDirectory = -1) SET @includeInGlobalHashDirectory = NULL

SET @userId = NULL
DECLARE @errorId uniqueidentifier

if (@scanText like 'URC:%')
BEGIN
	SELECT top 1 
		@userId = h.id 
	FROM HC.Hasher h where h.ResetCode = @scanText

	DECLARE @include smallint

	IF (@userId is not null)
		BEGIN

			SELECT @include = h.IncludeInGlobalHashDirectory FROM HC.Hasher h WHERE h.id = @userId

			if ((@includeInGlobalHashDirectory IS NOT NULL) AND (@include != @includeInGlobalHashDirectory))
			BEGIN
				UPDATE HC.Hasher set IncludeInGlobalHashDirectory = @includeInGlobalHashDirectory, updatedAt = getdate() where id = @userId
			END

			SELECT
				h.id as hasherId,
				h.Photo as photo,
				h.DisplayName as displayName,
				h.Email as email,
				h.FacebookId as facebookId,
				h.FirstName as firstName,
				h.HashName as hashName,
				h.LastName as lastName,
				h.QR_code as qrCode,
				h.SupportCode as supportCode,
				h.QR_secret_code as qrSecretCode,
				h.ResetCode as resetCode,
				h.IncludeInGlobalHashDirectory as includeInGlobalHashDirectory
			FROM HC.Hasher h where h.id = @userId
		END
	ELSE
		BEGIN
			SET @errorId = newid()

			INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,deviceId,string_1) VALUES (@errorId,@hcVersion,'User invite code not found','A new user is being registered with a duplicate e-mail address to one already in the system',OBJECT_NAME(@@PROCID),'00000000-0000-0000-0000-000000000000',@deviceId,@scanText)

			SELECT 
			@errorId as errorId,
			cast (5 as int) as errorType 
			,'Invite code not found' as errorTitle
			,'The invite code provided was not found in the Harrier Central system' as errorUserMessage
			,'This is a standard error that is anticipated and does not require debugging' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
			RETURN
		END

END

END

GO
/****** Object:  StoredProcedure [HC3].[extApi_getKennelEmailList]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[extApi_getKennelEmailList]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[extApi_getKennelEmailList] AS' 
END
GO
ALTER PROCEDURE [HC3].[extApi_getKennelEmailList]

@kennelExtApiKey nvarchar(250)

AS

-- EXEC HC3.extApi_getKennelEmailList @kennelExtApiKey = 'JuJeUqgT5EqoO/AiG55MV5a8YQwwxdBIqkuI95krJrs='
-- https://harrier.azurewebsites.net/api/ext_getKennelEmailList?kennelExtApiKey=JuJeUqgT5EqoO/AiG55MV5a8YQwwxdBIqkuI95krJrs=
 
select h.DisplayName as Display_name
,h.Email 
from HC.Kennel k
inner join HC.HasherKennelMap hkm on hkm.KennelId = k.id
inner join HC.Hasher h on h.id = hkm.UserId
where k.ExtApiKey = @kennelExtApiKey
AND hkm.KennelEmailAlertPreference = 1
order by h.HashName



GO
/****** Object:  StoredProcedure [HC3].[extApi_getKennelMembers]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[extApi_getKennelMembers]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[extApi_getKennelMembers] AS' 
END
GO
ALTER PROCEDURE [HC3].[extApi_getKennelMembers]

@kennelExtApiKey nvarchar(250)

AS

-- EXEC HC3.extApi_getKennelMembers @kennelExtApiKey = 'JuJeUqgT5EqoO/AiG55MV5a8YQwwxdBIqkuI95krJrs='
-- https://harrier.azurewebsites.net/api/ext_getKennelMembers?kennelExtApiKey=JuJeUqgT5EqoO/AiG55MV5a8YQwwxdBIqkuI95krJrs=

select 
h.HashName as Hash_name
,h.FirstName as First_name
,h.LastName as Last_name
,h.Email as eMail
,replace(h.ResetCode,'URC:','') as Invite_code
,case when (hkm.kennelId = h.HomeKennelId) then 'Yes' else 'No' end as Is_home_kennel
,case when hkm.KennelNotificationPreference = 0 then 'Auto' when hkm.KennelNotificationPreference = 1 then 'On' when hkm.KennelNotificationPreference = 2 then 'Off' else 'Unknown' end as Notifications
,case when hkm.KennelEmailAlertPreference = 0 then 'Auto' when hkm.KennelEmailAlertPreference = 1 then 'On' when hkm.KennelEmailAlertPreference = 2 then 'Off' else 'Unknown' end as Email_alerts
,hkm.HistoricalHaringCount as Historic_haring
,hkm.HistoricalPackRunCount + hkm.HistoricalHaringCount as Historic_total_runs
,hkm.CurrentHaringCount as Haring_in_HC
,hkm.CurrentHaringCount + hkm.CurrentPackRunCount as Runs_in_HC
,hkm.CurrentHaringCount + hkm.HistoricalHaringCount as Total_haring
,hkm.CurrentHaringCount + hkm.CurrentPackRunCount + hkm.HistoricalPackRunCount + hkm.HistoricalHaringCount as Total_runs
,case when hkm.HistoricalCountIsEstimate = 1 then 'Yes' else 'No' end as Historic_counts_are_estimates
,hkm.DateOfLastRun as Date_of_last_run
,case when hkm.Following = 1 then 'Yes' else 'No' end as Following
,hkm.MembershipExpirationDate as Membership_expiration_date
,coalesce(kc.currentBalance,0) as Hash_credit
from HC.Kennel k
inner join HC.HasherKennelMap hkm on hkm.KennelId = k.id
inner join HC.Hasher h on hkm.UserId = h.id
left outer join HC.KennelCredit kc on kc.kennelId = k.id and kc.userId = h.id
where k.ExtApiKey = @kennelExtApiKey
and hkm.MembershipExpirationDate > getdate()
order by h.HashName



GO
/****** Object:  StoredProcedure [HC3].[extApi_getKennelPayments]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[extApi_getKennelPayments]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[extApi_getKennelPayments] AS' 
END
GO
ALTER PROCEDURE [HC3].[extApi_getKennelPayments]

@kennelExtApiKey nvarchar(250)

AS

-- EXEC HC3.extApi_getKennelPayments @kennelExtApiKey = 'JuJeUqgT5EqoO/AiG55MV5a8YQwwxdBIqkuI95krJrs='
-- https://harrier.azurewebsites.net/api/ext_getKennelPayments?kennelExtApiKey=JuJeUqgT5EqoO/AiG55MV5a8YQwwxdBIqkuI95krJrs=

select 
e.EventName as Event_name,
e.EventNumber as Event_number,
pay.PaidDate AT TIME ZONE c.WindowsTimezone as Paid_date,
case 
	when hem.VirginVisitorType = 0 then paidBy.DisplayName 
	else hem.DisplayName + 
		case 
			when hem.VirginVisitorType = 1 then ' (Virgin)' 
			else ' (Visitor)' 
		end
	end as Paid_by,
paidTo.DisplayName as Paid_to,
pay.CreditAmount as Amount_paid,
pay.DebitAmount as Amount_due,
case
 	when pay.paymentType = 0 then 'Unknown' 
	when pay.paymentType = 1 then 'Not paid'
	when pay.paymentType = 2 then 'Free run'
	when pay.paymentType = 3 then 'Cash'
	when pay.paymentType = 4 then 'Bank transfer'
	when pay.paymentType = 5 then 'Cash (other amount)'
	when pay.paymentType = 6 then 'Hash credit'
	when pay.paymentType = 7 then 'Bank transfer (other amount)'
	else 'Error' 
	end as Payment_method,
pay.PaymentReference as Payment_reference,
case
	when pay.ProductType = 1 then 'Run fee'
	else 'Unknown product'
	end as Product_type,
case when (pay.PaymentType = 4 OR pay.PaymentType = 7) then 
	case when pay.ConfirmedDate is null then '<not confirmed>' else cast(pay.ConfirmedDate as nvarchar(50)) end
	else '<n/a>' 
	end as DateConfirmed,
coalesce(confirmedBy.DisplayName,'.') as Confirmed_by

from HC.Kennel k
inner join HC.Payment pay on pay.KennelId = k.id
inner join HC.HasherEventMap hem on pay.HasherEventMapId = hem.id
inner join HC.Event e on pay.EventId = e.id
inner join HC.City c on c.id = k.CityId
left outer join HC.Hasher paidBy on paidBy.id = pay.UserId
left outer join HC.Hasher paidTo on paidTo.id = pay.PaymentProcessedBy_userId
left outer join HC.Hasher confirmedBy on confirmedBy.id = pay.ConfirmedBy_UserId


where k.ExtApiKey = @kennelExtApiKey
and CancelledDate is null
order by e.EventStartDatetime desc, paidBy.DisplayName asc


GO
/****** Object:  StoredProcedure [HC3].[getPaymentReport]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[getPaymentReport]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[getPaymentReport] AS' 
END
GO
ALTER PROCEDURE [HC3].[getPaymentReport]

 @userId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @accessToken nvarchar(1000) = 'none',
 @kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @eventId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @showAllTransactions smallint = 0,
 @paidTo uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @paidBy uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @includeAggregates smallint = 1

AS

BEGIN

	SET NOCOUNT ON

	if @userId = '00000000-0000-0000-0000-000000000000' SET @userId = NULL
	if @paidBy = '00000000-0000-0000-0000-000000000000' SET @paidBy = NULL
	if @paidTo = '00000000-0000-0000-0000-000000000000' SET @paidTo = NULL
	if @kennelId = '00000000-0000-0000-0000-000000000000' SET @kennelId = NULL
	if @eventId = '00000000-0000-0000-0000-000000000000' SET @eventId = NULL

	if ((@showAllTransactions != 0) AND (@showAllTransactions != 1)) SET @showAllTransactions = 0

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error'),NULL) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	select 
		hem.id as hemId,
		hem.UserId as userId,
		CASE WHEN (hem.[VirginVisitorType] <> 0)	
			THEN 
			coalesce(hem.DisplayName,'<no name>') + CASE WHEN (hem.[VirginVisitorType] = 1) THEN ' (Virgin)' ELSE ' (Visitor)' END	
			ELSE 
		coalesce(paidBy.DisplayName,hem.DisplayName) END as paidBy
	into #tempHashersNotPaid
	from HC.HasherEventMap hem 
		left outer join HC.Hasher paidBy on hem.UserId = paidBy.id
	where @eventId is not null
	-- only look at people who are actually at the event
	and hem.EventId = @eventId and hem.AttendenceState >= 20 
	-- and remove any records where the user has paid
	and hem.id not in (select pay2.HasherEventMapId from HC.Payment pay2 where pay2.EventId = @eventId and pay2.PaymentType >= 2 and pay2.CancelledBy_UserId is null)
	
	
	SELECT coalesce(sum(p.creditAmount)-sum(p.debitAmount),0) as creditAvailable
			,hnp.userId
			,hnp.hemId
			,hnp.paidBy
			,case when hkm.IsMember = 1 then coalesce(evt.EventPriceForMembers,ken.defaultEventPriceForMembers,0) else coalesce(evt.EventPriceForNonMembers,ken.defaultEventPriceForNonMembers,0) end as eventPrice
			,coun.CurrencySymbol
			,coun.DigitsAfterDecimal
	INTO #creditTemp
	FROM #tempHashersNotPaid hnp
	INNER JOIN HC.Event evt on evt.id = @eventId
	INNER JOIN HC.Kennel ken on ken.id = evt.KennelId
	INNER JOIN HC.Country coun on ken.CountryId = coun.id
	--INNER JOIN HC.HasherKennelMap hkm on hnp.userId = hkm.UserId and hkm.KennelId = evt.KennelId
	LEFT OUTER JOIN HC.HasherKennelMap hkm on hnp.userId = hkm.UserId and hkm.KennelId = evt.KennelId
	LEFT OUTER JOIN HC.Payment p on p.UserId = hnp.userId and p.CancelledDate is null
	GROUP BY hnp.userId,hnp.hemId, hnp.paidBy, 
	case when hkm.IsMember = 1 then coalesce(evt.EventPriceForMembers,ken.defaultEventPriceForMembers,0) else coalesce(evt.EventPriceForNonMembers,ken.defaultEventPriceForNonMembers,0) end,
	coun.CurrencySymbol,
	coun.DigitsAfterDecimal

	declare @hashersNotPaidCount nvarchar(20)
	select @hashersNotPaidCount = cast(count(*) as nvarchar(20)) from #tempHashersNotPaid


select * from (
	select 
		pay.HasherEventMapId as hasherEventMapId,
		pay.UserId as userIdWhoPaid,
		pay.id as paymentId,
		CASE WHEN (hem.[VirginVisitorType] <> 0)	
			THEN 
			coalesce(hem.DisplayName,'<no name>') + CASE WHEN (hem.[VirginVisitorType] = 1) THEN ' (Virgin)' ELSE ' (Visitor)' END	ELSE
		coalesce(paidBy.DisplayName,hem.DisplayName) END as paidBy, 
		coalesce(paidTo.DisplayName,'<user deleted>') as paidTo, 
		cancelledBy.DisplayName as cancelledBy, 
		pay.CreditAmount as creditAmount, 
		pay.DebitAmount as debitAmount, 
		pay.PaymentType as paymentType,
		pay.PaidDate as paymentDate,
		pay.CancelledDate as cancelledDate,
		pay.PaymentReference as paymentReference,
		pay.Notes as notes,
		0 as creditRemaining,
		coun.CurrencySymbol as currencySymbol,
		coun.DigitsAfterDecimal as digitsAfterDecimal
	from HC.Payment pay 
		inner join HC.HasherEventMap hem on hem.id = pay.HasherEventMapId
		inner join HC.Event evt on pay.EventId = evt.id
		inner join HC.Kennel k on k.id = evt.KennelId
		inner join HC.Country coun on coun.id = k.CountryId
		left outer join HC.Hasher paidBy on pay.UserId = paidBy.id
		left outer join HC.Hasher paidTo on pay.PaymentProcessedBy_userId = paidTo.id
		left outer join HC.Hasher cancelledBy on pay.CancelledBy_UserId = cancelledBy.id
	where ((@kennelId is NULL) OR (pay.KennelId = @kennelId))
		AND ((@eventId is NULL) OR (pay.EventId = @eventId))
		AND ((@showAllTransactions = 1) OR (@showAllTransactions = 0 AND pay.CancelledBy_UserId is null))
		AND ((@paidBy is NULL) OR (@paidBy = pay.UserId))
		AND ((@paidTo is NULL) OR (@paidTo = pay.PaymentProcessedBy_userId))

	union
		-- this union query will only run when an eventId is provided
		-- its purpose is to provide records of Hashers at events that have not paid yet

		select 
		t.hemId as hasherEventMapId,
		t.userId as userIdWhoPaid,
		null as paymentId,
		t.paidBy as paidBy, 
		'none' as paidTo, 
		null as cancelledBy, 
		0 as creditAmount, 
		eventPrice as debitAmount, 
		1 as paymentType,
		null as paymentDate,
		null as cancelledDate,
		'none' as paymentReference,
		null as notes,
		creditAvailable as creditRemaining,
		t.CurrencySymbol as currencySymbol,
		t.DigitsAfterDecimal as digitsAfterDecimal
	from #creditTemp t

		union
		-- this union query will only run when an eventId is provided
		-- its purpose is to provide aggregate counts by payment type

		select 
		'00000000-0000-0000-0000-000000000000' as hasherEventMapId,
		'00000000-0000-0000-0000-000000000000' as userIdWhoPaid,
		null as paymentId,
		'not used' as paidBy, 
		'not used' as paidTo, 
		null as cancelledBy, 
		coalesce(sum(pay.CreditAmount),0) as creditTotal, 
		coalesce(sum(pay.DebitAmount),0) as debitTotal, 
		(coalesce(pay.PaymentType, 1)+100) as paymentType,
		null as paymentDate,
		null as cancelledDate,
		case when (coalesce(pay.PaymentType, 1)+100) = 101 then @hashersNotPaidCount else cast(count(*) as nvarchar(20)) end as paymentReference,
		null as notes,
		0 as creditRemaining,
		'' as currencySymbol,
		0 as digitsAfterDecimal

from HC.HasherEventMap hem
left outer join HC.Payment pay on pay.HasherEventMapId = hem.id
where @eventId is not null
and CancelledBy_UserId is null
and hem.EventId = @eventId
and pay.PaymentType > 1
group by (coalesce(pay.PaymentType, 1)+100)

union 
	-- and finally tag on the aggregate count of the number of hashers who have not paid for this event
		select 
		'00000000-0000-0000-0000-000000000000' as hasherEventMapId,
		'00000000-0000-0000-0000-000000000000' as userIdWhoPaid,
		null as paymentId,
		'not used' as paidBy, 
		'not used' as paidTo, 
		null as cancelledBy, 
		0 as creditTotal, 
		0 as debitTotal, 
		101 as paymentType,
		null as paymentDate,
		null as cancelledDate,
		@hashersNotPaidCount as paymentReference,
		null as notes,
		0 as creditRemaining,
		'' as currencySymbol,
		0 as digitsAfterDecimal
		where @eventId is not null
) tbl
ORDER BY paidBy


drop table #creditTemp
drop table #tempHashersNotPaid

END
	

  
GO
/****** Object:  StoredProcedure [HC3].[getResetCode]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[getResetCode]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[getResetCode] AS' 
END
GO




ALTER PROCEDURE [HC3].[getResetCode]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @supportCode nvarchar(1000)

AS

BEGIN

-- EXEC HC2.updateAvatar @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @accessToken = '', @avatarUrl = 'bundle://Avatar-2'

SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error'),NULL) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

DECLARE @result nvarchar(100)
SET @result = 'Support code not found'

IF EXISTS(SELECT * FROM HC.Hasher WHERE SupportCode = @supportCode)
BEGIN 
	SELECT @result = ResetCode FROM HC.Hasher h where h.SupportCode = @supportCode
END

SELECT @result as result

END


GO
/****** Object:  StoredProcedure [HC3].[joinEvent]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[joinEvent]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[joinEvent] AS' 
END
GO


ALTER PROCEDURE [HC3].[joinEvent]

 @userId uniqueidentifier, -- the one making the call to this SP
 @accessToken nvarchar(1000),
 @eventId uniqueidentifier,
 @hasherId uniqueidentifier, -- the hasher who is joining the event
 @hasherEventMapId uniqueidentifier,
 
 @isHare VARCHAR(10) = '-1',
 @rsvpState VARCHAR(10) = '-1',
 @attendenceState VARCHAR(10) = '-1',
 @virginVisitorType VARCHAR(10) = '-1',
 @notificationState VARCHAR(10) = '-1',
 @emailAlertState VARCHAR(10) = '-1',

 @hasherEventMapUpdatedAfter nvarchar(50),
 @hasherKennelMapUpdatedAfter nvarchar(50),
 @paymentsUpdatedAfter nvarchar(50),
 @kennelCreditsUpdatedAfter nvarchar(50) = 'ignore'

AS

BEGIN

	DECLARE @errorId uniqueidentifier

	IF (@userId IS NULL) OR (@userId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF (@eventId IS NULL) OR (@eventId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty eventId','A null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty eventId' as errorTitle
		,'A null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken,NULL) = 0 
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

DECLARE @kennelId uniqueidentifier
DECLARE @isHareNumeric smallint
DECLARE @rsvpStateNumeric smallint
DECLARE @attendenceStateNumeric smallint
DECLARE @virginVisitorTypeNumeric smallint
DECLARE @notificationStateNumeric smallint
DECLARE @emailAlertStateNumeric smallint
DECLARE @serverMessage nvarchar(250)
DECLARE @hasherName nvarchar(120)
DECLARE @isMember int

DECLARE @previousAttendence int, 
		@alreadyText nvarchar(50),
		@memberPrice smallmoney,
		@nonMemberPrice smallmoney,
		@eventPrice smallmoney

SET @isHareNumeric = coalesce(CAST(@isHare as smallint),-1)
SET @rsvpStateNumeric = coalesce(CAST(@rsvpState as smallint),-1)
SET @attendenceStateNumeric = coalesce(CAST(@attendenceState as smallint),-1)
SET @virginVisitorTypeNumeric = coalesce(CAST(@virginVisitorType as smallint),-1)
SET @notificationStateNumeric = coalesce(CAST(@notificationState as smallint),-1)
SET @emailAlertStateNumeric = coalesce(CAST(@emailAlertState as smallint),-1)

if (@hasherEventMapId = '00000000-0000-0000-0000-000000000000') SET @hasherEventMapId = null

DECLARE @specialCase1Count int

-- SPECIAL CASE #1
-- First, let's check for a case where a Hasher is being scanned in after a run, but they are being scanned in 
-- to the wrong run (e.g. this can happen on hash weekends when there is more than one run at a time)
if ((@hasherEventMapId is null) AND (@attendenceStateNumeric >= 30) AND (@virginVisitorTypeNumeric = 0) AND (@hasherId is not null))
BEGIN
	SELECT @previousAttendence = hem.attendenceState from HC.HasherEventMap hem where hem.EventId = @eventId AND hem.UserId = @hasherId

	-- if @previousAttendence is null, the Hasher has not checked in at the beginning of this run, maybe they checked in to a different run?
	if (@previousAttendence is null)
	BEGIN
		

		SELECT @specialCase1Count = count(*) FROM HC.HasherEventMap hem3 where hem3.id in (
		
		SELECT hem.id 
			FROM HC.Event evt1, HC.Event evt2, HC.HasherEventMap hem
			WHERE 
				evt1.id = @eventId 
				AND evt2.KennelId = evt1.KennelId 
				AND cast(evt2.eventStartDatetime as date) = cast(evt1.eventStartDatetime as date) 
				AND evt2.id != evt1.id
				AND hem.userId = @hasherId
				AND hem.EventId = evt2.id
				AND hem.AttendenceState < 30
		) 

		if (@specialCase1Count > 0)
		BEGIN

			-- let's check to see if the Hasher was checked in to another run on this date
			UPDATE HC.HasherEventMap SET AttendenceState = @attendenceStateNumeric, updatedAt = getdate() FROM HC.HasherEventMap hem3 where hem3.id in (
		
			SELECT hem.id 
				FROM HC.Event evt1, HC.Event evt2, HC.HasherEventMap hem
				WHERE 
					evt1.id = @eventid 
					AND evt2.KennelId = evt1.KennelId 
					AND cast(evt2.eventStartDatetime as date) = cast(evt1.eventStartDatetime as date) 
					AND evt2.id != evt1.id
					AND hem.userId = @hasherId
					AND hem.EventId = evt2.id
					AND hem.AttendenceState < 30
			) 

			SELECT @serverMessage = h.DisplayName + ' was checked in to a different run and has been checked in to that run.' FROM HC.Hasher h where h.id = @hasherId
		END

	END
END


-- if SPECIAL CASE #1 executed and had rows, don't attempt further processing
IF (coalesce(@specialCase1Count,0) = 0)
	BEGIN

		-- There are three cases where this can be called
		-- Case #1: HasherId and HasherEventMapId are null... this is when the user is RSVP'ing themselves
		-- Case #2: HasherEventMapId is null but HasherId is not null... this is where an admin is RSVP'ing another Hasher who has a record in HC.Hasher
		-- Case #3: HasherEventMapId is not null, but HasherId is null... this is where an admin is RSVP'ing a Visitor or Virgin who does not have a record in HC.Hasher


		if (((@hasherId is null) AND (@hasherEventMapId is null)) OR (@hasherId = @userId)) -- CASE #1
		BEGIN
			SET @hasherId = @userId
			SET @hasherName = 'You are '
		END



		-- set the keyword 'already ' for the display of messages when scanning someone in at the Hash
		-- no need to do this, however, if someone is not at the Hash yet (e.g. a change to an RSVP)
		IF (@attendenceStateNumeric >= 20)
		BEGIN
			SELECT @previousAttendence = hem.attendenceState from HC.HasherEventMap hem where hem.EventId = @eventId AND hem.UserId = @hasherId
			IF (@attendenceStateNumeric <= @previousAttendence) SET @alreadyText = 'already '
		END


		if (@hasherEventMapId is null) -- Handle CASE #1 and #2
		BEGIN

			SELECT 
				@hasherEventMapId = hem.id,
				@kennelId = e.KennelId,
				@hasherName = coalesce(@hasherName,h.displayName + ' is '),
				@isMember = case when coalesce(hkm.MembershipExpirationDate,'1/1/2000') > getdate() then 1 else 0 end,
				@memberPrice = coalesce(e.eventPriceForMembers,k.defaultEventPriceForMembers,0),
				@nonMemberPrice = coalesce(e.eventPriceForNonMembers,k.defaultEventPriceForNonMembers,0)
			from HC.Event e
			INNER JOIN HC.Kennel k on k.id = e.KennelId
			LEFT OUTER JOIN HC.HasherEventMap hem on hem.EventId = e.id AND hem.UserId = @hasherId
			LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.KennelId = e.KennelId AND hkm.UserId = @hasherId
			,HC.Hasher h
			WHERE e.id = @eventId AND  h.id = @hasherId


			IF (@hasherEventMapId is null)
			BEGIN 
				SET @hasherEventMapId = newid()

				INSERT INTO HC.RunCounts ([TotalPackRunsThisKennel]
				   ,[TotalHaringThisKennel]
				   ,[TotalPackRunsAllKennels]
				   ,[TotalHaringAllKennels]
				   ,[updatedAt]) VALUES (0,0,0,0,GETDATE())
		
				INSERT INTO HC.HasherEventMap(id,UserId,EventId,RunCountId,updatedAt) VALUES (@hasherEventMapId,@hasherId,@eventId,@@IDENTITY,getdate()) 
			END
		END
		ELSE
		BEGIN
			SELECT 
			@kennelId = e.kennelId,
			@isMember = case when coalesce(hkm.MembershipExpirationDate,'1/1/2000') > getdate() then 1 else 0 end, -- membership determination required for payment popup 
			@memberPrice = coalesce(e.eventPriceForMembers,k.defaultEventPriceForMembers,0),
			@nonMemberPrice = coalesce(e.eventPriceForNonMembers,k.defaultEventPriceForNonMembers,0)
			FROM HC.Event e 
			INNER JOIN HC.Kennel k on k.id = e.KennelId
			LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.kennelId = e.kennelId AND hkm.userId = @hasherId
			WHERE e.id = @eventId
		END

		IF (@isMember = 0) 
			SET @eventPrice = @nonMemberPrice
		ELSE
			SET @eventPrice = @memberPrice

		IF (@hasherName IS NULL) SELECT @hasherName = case when (h.id = hem.userId) then 'You are ' else coalesce(h.DisplayName,hem.DisplayName) + ' is ' end from HC.Hasher h,HC.HasherEventMap hem where h.id = @hasherId and hem.EventId = @eventId and hem.UserId = @hasherId

		UPDATE HC.HasherEventMap SET 
			IsHare = case when @isHareNumeric <> -1 then @isHareNumeric else IsHare end,
			RsvpState = case when @rsvpStateNumeric <> -1 then @rsvpStateNumeric else RsvpState end,
			Rsvp = case when @rsvpState <> -1 then getdate() else Rsvp end,
			AttendenceState = case when @attendenceStateNumeric <> -1 then @attendenceStateNumeric else AttendenceState end,
			VirginVisitorType = case when @virginVisitorTypeNumeric <> -1 then @virginVisitorTypeNumeric else VirginVisitorType end,
			EventNotificationPreference = case when @notificationStateNumeric = 0 THEN NULL WHEN  @notificationStateNumeric <> -1 THEN @notificationStateNumeric ELSE EventNotificationPreference end,
			EventEmailAlertPreference = case when @emailAlertStateNumeric = 0 THEN NULL WHEN  @emailAlertStateNumeric <> -1 THEN @emailAlertStateNumeric ELSE EventEmailAlertPreference end,
			updatedAt = getdate()
			WHERE id = @hasherEventMapId

		SET @serverMessage = @hasherName + coalesce(@alreadyText,'') + 'recorded as ' + case when @attendenceStateNumeric = 20 then 'at the Hash'  when @attendenceStateNumeric = 30 then 'On Inn' end

		DECLARE @payCount int

		if ((@attendenceStateNumeric >= 20) AND (@eventPrice != 0))
		BEGIN
			-- determine if the Hasher has paid or not, this is needed when scanning is dnne to determine if the payment popup should be displayed
			SELECT @payCount = COUNT(*) from HC.Payment pay WHERE pay.HasherEventMapId = @hasherEventMapId and pay.CancelledBy_UserId is NULL

			-- set the message appropriately
			IF @payCount = 0 
				SET @serverMessage = @serverMessage + '. Don''t forget to pay for the Hash' 
			ELSE 
				IF @attendenceStateNumeric = 20
					SET @serverMessage = @serverMessage + ' and paid. Enjoy your run!' 
				ELSE IF @attendenceStateNumeric = 30
					SET @serverMessage = @serverMessage + ' and paid. Enjoy your beer!' 
		END

		DECLARE @virginVisitorTypeInt int
		SELECT @virginVisitorTypeInt = hem.VirginVisitorType from HC.HasherEventMap hem where hem.id = @hasherEventMapId

		-- don't try to count runs for virgins / visitors
		IF (@attendenceStateNumeric <> -1 OR @rsvpStateNumeric <> -1) AND @virginVisitorTypeInt <= 0
		BEGIN
			IF (@hasherId is not null)
				BEGIN
					-- Handle CASES #1 & #2
					EXEC HC.nonApi_adjustHasherRunCounts @limitByUser = 1,@userId = @hasherId,@kennelId = @kennelId
				END
			ELSE
				BEGIN
					-- Handle CASE #3
					EXEC HC.nonApi_adjustHasherRunCounts @limitByUser = 2,@hasherEventMapId = @hasherEventMapId
				END
		END

		-- if attendence is not at the Hash, check for any payment transactions and cancel them
		IF (@attendenceStateNumeric <> -1 AND @attendenceStateNumeric < 20)
		BEGIN

			UPDATE HC.Payment SET CancelledBy_UserId = @userId, CancelledDate = GETDATE(), UpdatedAt = GETDATE() FROM HC.Payment pay WHERE pay.HasherEventMapId = @hasherEventMapId AND pay.CancelledBy_UserId IS NULL
			if ((@@ROWCOUNT > 0) AND (@virginVisitorTypeInt = 0))
			BEGIN
				IF (@hasherId is NULL) SELECT @hasherId = hem.UserId from HC.HasherEventMap hem where hem.id = @hasherEventMapId

				-- TODO: See how we can optimize this so we are not having to constantly re-calculate the credit available!!!
				-- Update the Kennel Credit table if necessary
				DECLARE @creditAvailable smallmoney
				SELECT @creditAvailable = SUM(pay.creditAmount) - SUM(pay.debitAmount) FROM HC.Payment pay WHERE pay.KennelId = @kennelId AND pay.UserId = @hasherId AND pay.CancelledDate IS NULL AND pay.PaymentType BETWEEN 5 AND 7 
				if (@creditAvailable IS NOT NULL)
					BEGIN
						DECLARE @latestEventId uniqueidentifier
						SELECT top 1 @latestEventId = hem.EventId from HC.HasherEventMap hem 
						INNER JOIN HC.Event evt on hem.EventId = evt.id and hem.UserId = @hasherId
						WHERE evt.KennelId = @kennelId AND hem.AttendenceState >= 20
						ORDER BY evt.EventStartDatetime desc

						MERGE HC.KennelCredit AS [Target] 
						USING (SELECT @hasherId AS userId, @kennelId AS kennelId) AS [Source] ON [Target].kennelId = [Source].kennelId AND [Target].userId = [Source].userId 
						WHEN MATCHED THEN UPDATE SET [Target].currentBalance = @creditAvailable, [Target].balanceAsOfEventId = @eventId, [Target].updatedAt = getdate() 
						WHEN NOT MATCHED THEN INSERT (userId, kennelId,currentBalance,balanceAsOfEventId,updatedAt) VALUES (@hasherId, @kennelId,@creditAvailable,@latestEventId,getdate());
					END
				ELSE
					BEGIN
						UPDATE HC.KennelCredit SET currentBalance = 0, balanceAsOfEventId = @eventId, updatedAt = GETDATE() FROM HC.KennelCredit kc WHERE kc.userId = @hasherId and kc.kennelId = @kennelId
					END

				EXEC HC3.nonApi_updateHasherCreditBalance @hemId = @hasherEventMapId

			END




		END
		
		


		IF (@isHareNumeric != -1)
		BEGIN

		DECLARE @hares NVARCHAR(2500)

			SELECT @hares = STRING_AGG(h.DisplayName,', ') WITHIN GROUP (ORDER BY h.displayName ASC) 
			FROM HC.HasherEventMap hem
			INNER JOIN HC.Hasher h ON hem.UserId = h.id
			WHERE eventId = @eventId AND isHare = 1 AND RsvpState = 3

			UPDATE HC.Event SET hares = @hares, updatedAt = getdate() WHERE id = @eventId

		END
	END



-- send back adHoc data to support cases when the user was scanned in at a Hash
-- TODO: may want to clean this up one day

DECLARE @ahd_notificationPrefs int,
		@ahd_emailAlertPrefs int,
		@ahd_hasherId uniqueidentifier,
		@ahd_currentPackRunCount int,
		@ahd_currentHaringCount int,
		@ahd_rsvpState int,
		@ahd_willHareState int,
		@ahd_hares nvarchar(2500)


		SELECT 
		@ahd_hasherId = hem.UserId,
		@ahd_notificationPrefs = coalesce(hem.EventNotificationPreference,hkm.KennelNotificationPreference),
		@ahd_emailAlertPrefs = coalesce(hem.EventEmailAlertPreference,hkm.KennelEmailAlertPreference),
		@ahd_currentPackRunCount = coalesce(hkm.CurrentPackRunCount,-1),
		@ahd_currentHaringCount = coalesce(hkm.CurrentHaringCount,-1),
		@ahd_rsvpState = coalesce(hem.rsvpState,-1),
		@ahd_willHareState = coalesce(hem.isHare,0),
		@ahd_hares = coalesce(evt.Hares, '')
		FROM HC.HasherEventMap hem
		INNER JOIN HC.Event evt on hem.eventId = evt.id
		LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.kennelId = @kennelId AND hkm.userId = hem.userId
		WHERE hem.id = @hasherEventMapId

SELECT
		1 as adHocDataId,
		@serverMessage as userMessage,
		coalesce(@payCount,0) as isPaid,
		@isMember as isMember,  
		@hasherEventMapId as hasherEventMapId,
		coalesce(@ahd_hasherId,@hasherId) as hasherId,
		@ahd_notificationPrefs as notificationPreference,
		@ahd_emailAlertPrefs as emailAlertPreference,
		@ahd_currentHaringCount as currentHaringCount,
		@ahd_currentPackRunCount as currentPackRunCount,
		@ahd_rsvpState as rsvpState,
		@ahd_willHareState as willHareState,
		@ahd_hares as hares


DECLARE @procName nvarchar(500)
SET @procName = OBJECT_NAME(@@PROCID)
SET @hasherKennelMapUpdatedAfter = coalesce(@hasherKennelMapUpdatedAfter,'ignore')

EXEC HC3.syncEventAdminData 
@userId = @userId,
@accessToken = @accessToken,
@eventId = @eventId,
@hashersUpdatedAfter = 'ignore',
@hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter,
@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
@narrowEventsUpdatedAfter = 'ignore',
@paymentsUpdatedAfter = @paymentsUpdatedAfter,
@kennelCreditsUpdatedAfter = @kennelCreditsUpdatedAfter,
@receiptsUpdatedAfter = 'ignore',
@procName = @procName,
@param = NULL


END





GO
/****** Object:  StoredProcedure [HC3].[joinEventAsVisitor]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[joinEventAsVisitor]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[joinEventAsVisitor] AS' 
END
GO
ALTER PROCEDURE [HC3].[joinEventAsVisitor]  

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@eventId uniqueidentifier, 
@displayName nvarchar(250), 
@virginVisitorType smallint,
@attendenceState smallint,
@email nvarchar(250),
@phoneNumber nvarchar(250),
@hasherEventMapUpdatedAfter nvarchar(50),
@paymentsUpdatedAfter nvarchar(50)

AS

-- exec HC.joinEventAsVisitor @eventId = '7B10155A-92D4-40D7-929A-CF2BDE968444', @displayName = 'Stacy', @virginVisitorType = '0'
BEGIN

SET NOCOUNT ON

	DECLARE @errorId uniqueidentifier

	IF (@userId IS NULL) OR (@userId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF (@eventId IS NULL) OR (@eventId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty eventId','A null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty eventId' as errorTitle
		,'A null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken,NULL) = 0 
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

DECLARE @isGenericUserPresent smallint  
DECLARE @kennelId uniqueidentifier   
DECLARE @hasherEventMapId uniqueidentifier

-- only two types of Virgin/Visitors at the moment... check to make sure it's one of these
IF ((@VirginVisitorType = 1) OR (@VirginVisitorType = 2))  
BEGIN  
		-- The generic user is a record in HC.Hasher that is available to be mapped to for visitors, virgins and anyone else who 
		-- is not in the system. This allows us to account for people on runs without having to add a new HC.Hasher record
		-- for each one of them.
		SELECT  @isGenericUserPresent = count(*) from HC.Hasher h inner join HC.Event e on h.id = e.KennelId WHERE e.id = @eventId AND e.deleted = 0 and e.IsVisible <> 0  

		-- if the "generic user" is not present for this Kennel, go ahead and add one in HC.Hasher
		if (@isGenericUserPresent = 0)  
		BEGIN   
			SELECT 
				@kennelId = e.KennelId 
			FROM HC.Event e 
			WHERE e.id = @eventId AND e.deleted = 0 and e.IsVisible <> 0
	
			INSERT INTO [HC].[Hasher]             
			(
				[id] 
				,[DisplayName]
				,[FirstName]
				,[LastName]
				,[HashName]            
				,[Description]       
				,[HomeLatitude]       
				,[HomeLongitude])   
				SELECT     
					k.id    
					,'Placeholder user for visitors / virgins for ' + k.KennelName 
					,'Placeholder'
					,'User'
					,'Placeholder user' 
					,'Placeholder user for visitors / virgins for ' + k.KennelName    
					,coalesce(k.Latitude,0)
					,coalesce(k.Longitude,0)   
				FROM HC.Event e 
				INNER JOIN HC.Kennel k 
				ON e.KennelId = k.id   
				WHERE e.id = @eventId AND e.deleted = 0 and e.IsVisible <> 0   
		
		END    

		SET @hasherEventMapId = NEWID()

		-- Now, insert a record for the visitor (virgin) into HC.HasherEventMap and return 'Success' as the result
		INSERT INTO HC.RunCounts ([TotalPackRunsThisKennel]
			   ,[TotalHaringThisKennel]
			   ,[TotalPackRunsAllKennels]
			   ,[TotalHaringAllKennels]
			   ,[updatedAt]) VALUES (0,0,0,0,GETDATE())

		INSERT INTO [HC].[HasherEventMap]
				   ([id]
				   ,[EventId]
				   ,[RunCountId]
				   ,[UserId]
				   ,[UserStartEvent]
				   ,[EventCost]
				   ,[Rsvp]
				   ,[RsvpState]
				   ,[AttendenceState]
				   ,[VirginVisitorType] -- 0 = HasherInSystem, 1 = Virgin, 2 = Visitor
				   ,[DisplayName]
				   ,[Email]
				   ,[PhoneNumber]
				   ,[updatedAt])

				SELECT @hasherEventMapId
					,@eventId
					,@@IDENTITY
					,e.KennelId  -- Virgins and Visitors don't have their own UserId, so we put in the KennelId instead as a flag
					,getdate()
					,e.EventPriceForNonMembers
					,getdate()
					,3 -- RSVP state as 'coming'
					,@attendenceState
					,@virginVisitorType
					,@displayName
					,@email
					,@phoneNumber
					,getdate()
					from HC.Event e where e.id = @eventId and e.deleted = 0 and e.IsVisible <> 0


-- send back adHoc data to support cases when the user was scanned in at a Hash

SELECT
		1 as adHocDataId,
		@hasherEventMapId as hasherEventMapId


		DECLARE @procName nvarchar(500)
		SET @procName = OBJECT_NAME(@@PROCID)

		EXEC HC3.syncEventAdminData 
		 @userId = @userId,
		 @accessToken = @accessToken,
		 @eventId = @eventId,
		 @hashersUpdatedAfter = 'ignore',
		 @hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter,
		 @hasherKennelMapUpdatedAfter = 'ignore',
		 @narrowEventsUpdatedAfter = 'ignore',
		 @paymentsUpdatedAfter = @paymentsUpdatedAfter,
		 @receiptsUpdatedAfter = 'ignore',
		 @procName = @procName,
		 @param = NULL

END

END


GO
/****** Object:  StoredProcedure [HC3].[joinKennel]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[joinKennel]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[joinKennel] AS' 
END
GO



ALTER PROCEDURE [HC3].[joinKennel]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @kennelId uniqueidentifier,
 @targetUserId uniqueidentifier,
 @isFollowing smallint = null,
 @isHomeKennel smallint = null,
 @notificationState smallint = null,
 @emailAlertState smallint = null,
 @monthsToAddToMembership smallint = null,
 @paymentAmount decimal(12,6) = NULL,
 @kennelsUpdatedAfter nvarchar(50),
 @hasherKennelMapUpdatedAfter nvarchar(50),
 @hashersUpdatedAfter nvarchar(50) = 'ignore'

AS

BEGIN

	if (@isFollowing = -1) SET @isFollowing = null
	if (@isHomeKennel = -1) SET @isHomeKennel = null
	if (@monthsToAddToMembership = 0) SET @monthsToAddToMembership = null
	if (@notificationState = -1) SET @notificationState = null
	if (@emailAlertState = -1) SET @emailAlertState = null
	if (@hashersUpdatedAfter is null) SET @hashersUpdatedAfter = 'ignore'

-- EXEC HC.joinKennel @kennelId = '9e85d401-213d-47ad-8a6e-44e5476925f4', @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @state = '1'

	SET NOCOUNT ON

	DECLARE @errorId uniqueidentifier

	IF (@userId IS NULL) OR (@userId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF (@kennelId IS NULL) OR (@kennelId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty KennelId','A null or empty kennelId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty kennelId' as errorTitle
		,'A null or empty value was passed as the kennelId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken,NULL) = 0 
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF @isHomeKennel = 1 SET @isFollowing = 1

	-- remove the home kennel desgination if someone unfollows a kennel
	if @isFollowing = 0 OR @isFollowing = 2 OR @isHomeKennel = 0
	BEGIN
		if ((SELECT count(*) from HC.Hasher where id = @targetUserId and HomeKennelId = @kennelId) > 0)
		BEGIN
			UPDATE HC.Hasher SET HomeKennelId = NULL, updatedAt = getdate() WHERE id = @targetUserId and HomeKennelId = @kennelId
		END	
	END

	IF @isHomeKennel = 1
	BEGIN
		UPDATE HC.Hasher SET HomeKennelId = @kennelId, updatedAt = getdate() WHERE id = @targetUserId
	END

	DECLARE @isMember smallint
	DECLARE @newExpirationDate datetimeoffset(7)
	DECLARE @memberSince datetimeoffset(7)
	
	DECLARE @hkmId uniqueidentifier
	SELECT @hkmId = id FROM HC.HasherKennelMap WHERE UserId = @targetUserId AND KennelId = @kennelId

	IF (@hkmId is null)
		BEGIN 
			SET @isMember = 0

			IF ((@monthsToAddToMembership IS NOT NULL) AND (@monthsToAddToMembership > 0))
			BEGIN
				SET @isMember = 1
				SET @newExpirationDate = dateadd(month,@monthsToAddToMembership,getdate())
				SET @memberSince = getdate()
			END

			SET @hkmId = newid()
			INSERT INTO HC.HasherKennelMap(id,UserId,KennelId,[Following],[IsMember],[MembershipExpirationDate],[MemberSince],[IsHomeKennel],[KennelNotificationPreference],[KennelEmailAlertPreference],[updatedAt]) VALUES (@hkmId,@targetUserId,@kennelId,coalesce(@isFollowing,0),coalesce(@isMember,0),@newExpirationDate,@memberSince,coalesce(@isHomeKennel,0),coalesce(@notificationState,0),coalesce(@emailAlertState,0),getdate()) 
		END
	ELSE
		BEGIN
			UPDATE HC.HasherKennelMap SET 
				[Following] = coalesce(@isFollowing,[Following]),
				[IsMember] = 
				CASE 
					WHEN (@monthsToAddToMembership = -9999)
						THEN 0
							 
					WHEN dateadd(month,@monthsToAddToMembership,coalesce(MembershipExpirationDate,getdate())) > getdate()
						THEN 1
					ELSE
						0
					END,
				[IsHomeKennel] = coalesce(@isHomeKennel,[isHomeKennel]),
				[KennelNotificationPreference] = coalesce(@notificationState,[KennelNotificationPreference],0),
				[KennelEmailAlertPreference] = coalesce(@emailAlertState,[KennelEmailAlertPreference],0),
				[MembershipExpirationDate] = 
				CASE 
					WHEN ((@monthsToAddToMembership IS NULL) OR (@monthsToAddToMembership = -9999))
						THEN
							CASE WHEN (@monthsToAddToMembership = -9999) THEN NULL ELSE MembershipExpirationDate END
					ELSE 
						CASE 
							WHEN ((MembershipExpirationDate < getdate()) OR (MembershipExpirationDate IS NULL)) 
								THEN dateadd(month,@monthsToAddToMembership,getdate()) 
							ELSE 
								dateadd(month,@monthsToAddToMembership,MembershipExpirationDate) 
							END
					END,
				[MemberSince] = 
					CASE 
					WHEN MemberSince IS NOT NULL THEN 
						CASE WHEN (@monthsToAddToMembership = -9999) THEN NULL ELSE MemberSince END
					 
					ELSE 
						CASE 
							WHEN ((@monthsToAddToMembership IS NULL) OR (@monthsToAddToMembership <= 0)) 
								THEN NULL
							ELSE 
								getdate()
							END
					END,
				[updatedAt] = getdate()
				FROM HC.HasherKennelMap
				WHERE id = @hkmId
		END



	DECLARE @RC int

	-- send back adHoc data to update the UI correctly
	SELECT
		1 as adHocDataId,
		[Following] as following,
		[KennelNotificationPreference] as kennelNotificationPreference,
		[KennelEmailAlertPreference] as kennelEmailAlertPreference,
		CASE WHEN hkm.kennelId = h.HomeKennelId then 1 else 0 end as isHomeKennel
		FROM HC.HasherKennelMap hkm
		INNER JOIN HC.Hasher h on h.id = hkm.UserId
		WHERE hkm.id = @hkmId

	DECLARE @procName nvarchar(100)
	SET @procName = OBJECT_NAME(@@PROCID)

	if ((@targetUserId IS NULL) OR (@targetUserId = @userId))
		EXECUTE @RC = [HC3].[syncUserData] 
		   @userId
		  ,@accessToken
		  ,@hashersUpdatedAfter = @hashersUpdatedAfter
		  ,@citiesUpdatedAfter = 'ignore'
		  ,@regionsUpdatedAfter = 'ignore'
		  ,@countriesUpdatedAfter = 'ignore'
		  ,@kennelsUpdatedAfter = @kennelsUpdatedAfter
		  ,@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter
		  ,@hasherEventMapUpdatedAfter = 'ignore'
		  ,@narrowEventsUpdatedAfter = 'ignore'
		  ,@procName = @procName
		  ,@param = NULL
	ELSE
		EXECUTE @RC = [HC3].[syncKennelAdminData] 
		   @userId
		  ,@accessToken
		  ,@kennelId = @kennelId
		  ,@hashersUpdatedAfter = @hashersUpdatedAfter
		  ,@kennelsUpdatedAfter = @kennelsUpdatedAfter
		  ,@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter
		  ,@procName = @procName
		  ,@param = NULL	

	

END





GO
/****** Object:  StoredProcedure [HC3].[logEmailsSent]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[logEmailsSent]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[logEmailsSent] AS' 
END
GO
ALTER PROCEDURE [HC3].[logEmailsSent]

	@eventId uniqueidentifier,
	@templateId uniqueidentifier,
	@response nvarchar(250),
	@emailsSent int

AS

INSERT INTO [HC].[EmailLog]
           (
            [EmailTemplaterId]
           ,[EventId]
           ,[DateSent]
           ,[NumberSent]
           ,[ServerReply])
     VALUES
           (@templateId,@eventId,GETDATE(),@emailsSent,@response)
GO
/****** Object:  StoredProcedure [HC3].[nonApi_fixRunCountsInHkm]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[nonApi_fixRunCountsInHkm]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[nonApi_fixRunCountsInHkm] AS' 
END
GO
ALTER PROCEDURE [HC3].[nonApi_fixRunCountsInHkm]

AS

select evt.kennelId,hem.userId,max(rc.TotalPackRunsThisKennel) as packRunCount,max(rc.TotalHaringThisKennel) as haringCount 
into #temp
from HC.RunCounts rc 
inner join HC.HasherEventMap hem on rc.id = hem.runCountId
inner join HC.Event evt on hem.eventId = evt.id
group by evt.KennelId, hem.userId


select * from #temp t
inner join HC.HasherKennelMap hkm on hkm.UserId = t.userId and hkm.KennelId = t.kennelId
where hkm.CurrentPackRunCount != t.packRunCount or hkm.CurrentHaringCount != t.haringCount

update HC.HasherKennelMap set CurrentPackRunCount = t.packRunCount, CurrentHaringCount = t.haringCount, updatedAt = getdate()
from #temp t
inner join HC.HasherKennelMap hkm on hkm.UserId = t.userId and hkm.KennelId = t.kennelId
where hkm.CurrentPackRunCount != t.packRunCount or hkm.CurrentHaringCount != t.haringCount

SELECT @@ROWCOUNT

select * from #temp t
inner join HC.HasherKennelMap hkm on hkm.UserId = t.userId and hkm.KennelId = t.kennelId
where hkm.CurrentPackRunCount != t.packRunCount or hkm.CurrentHaringCount != t.haringCount

drop table #temp
GO
/****** Object:  StoredProcedure [HC3].[nonApi_testRunCounts]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[nonApi_testRunCounts]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[nonApi_testRunCounts] AS' 
END
GO
ALTER PROCEDURE [HC3].[nonApi_testRunCounts]

AS



select evt.kennelId,hem.userId,max(rc.TotalPackRunsThisKennel) as packRunCount,max(rc.TotalHaringThisKennel) as haringCount 
into #temp
from HC.RunCounts rc 
inner join HC.HasherEventMap hem on rc.id = hem.runCountId
inner join HC.Event evt on hem.eventId = evt.id
group by evt.KennelId, hem.userId


select hkm.CurrentPackRunCount as hkmCurrentPackRunCount, t.packRunCount as calculatedPackRunCount, hkm.CurrentHaringCount as hkmCurrentHaringCount, t.haringCount as calculatedHaringCount, * from #temp t
inner join HC.HasherKennelMap hkm on hkm.UserId = t.userId and hkm.KennelId = t.kennelId
where hkm.CurrentPackRunCount != t.packRunCount or hkm.CurrentHaringCount != t.haringCount


drop table #temp
GO
/****** Object:  StoredProcedure [HC3].[nonApi_updateHasherCreditBalance]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[nonApi_updateHasherCreditBalance]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[nonApi_updateHasherCreditBalance] AS' 
END
GO
--select * from HC.Payment p 
--where p.UserId = '0290C1D1-3396-4CFE-B89F-258A224D6F45'

--select * from HC.Hasher h where h.DisplayName like '%fiddler%'

/*
select e.kennelId,* from HC.HasherEventMap hem
inner join HC.Event e on hem.EventId = e.id

where hem.userId = '0290C1D1-3396-4CFE-B89F-258A224D6F45'
order by e.EventStartDatetime desc
*/


ALTER PROCEDURE [HC3].[nonApi_updateHasherCreditBalance]

@hemId uniqueidentifier = NULL,
@userId uniqueidentifier = NULL,
@kennelId uniqueidentifier = NULL

AS

IF ((@userId IS NULL) OR (@kennelId IS NULL))
BEGIN
	SELECT @userId = userId, @kennelId = e.KennelId from HC.HasherEventMap hem
	INNER JOIN HC.Event e on e.id = hem.EventId
	WHERE hem.id = @hemId
END

-- get new running balance for this Hasher in this kennel starting from "day 1" and put in temp table
select pay.id, sum(pay.CreditAmount - pay.DebitAmount) OVER (Order By e.eventStartDatetime) AS RunningTotal into #temp from HC.Event e 
INNER JOIN HC.HasherEventMap hem on hem.EventId = e.id and hem.UserId = @userId
INNER JOIN HC.Payment pay on pay.HasherEventMapId = hem.id
where e.KennelId = @kennelId
AND e.IsVisible != 0
AND pay.CancelledDate is null
order by e.EventStartDatetime desc

-- look for cases where the #temp table does not match the Payment table and update only those rows that changed
UPDATE HC.Payment set CreditAvailable = t.RunningTotal, updatedAt = getdate()
FROM HC.Payment p inner join #temp t on p.id = t.id 
WHERE CreditAvailable != t.RunningTotal

drop table #temp










GO
/****** Object:  StoredProcedure [HC3].[processFacebookLogin]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[processFacebookLogin]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[processFacebookLogin] AS' 
END
GO
ALTER PROCEDURE [HC3].[processFacebookLogin]

 @userId nvarchar(50),
 @accessToken nvarchar(1000),
 @hashersUpdatedAfter nvarchar(50),
 @firstName nvarchar(120),
 @lastName nvarchar(120),
 @hashName nvarchar(120),
 @email nvarchar(120),
 @photo nvarchar(500),
 @facebookId nvarchar(120),
 @facebookAccessToken nvarchar(250),
 @includeInGlobalHashDirectory int = -1,
 @hcVersion nvarchar(100)

AS

BEGIN

SET NOCOUNT ON

	DECLARE @paramString nvarchar(250)
	SET @paramString = upper(cast(coalesce(@userId,'00000000-0000-0000-0000-000000000000') as nvarchar(50))) 

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error'),@paramString) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END




IF (@includeInGlobalHashDirectory = -1) SET @includeInGlobalHashDirectory = NULL
if (@hashName = '') SET @hashName = null

SET @userId = NULL
DECLARE @errorId uniqueidentifier
DECLARE @isNewUser smallint

SET @isNewUser = 1

	IF ((SELECT COUNT(*) FROM HC.Hasher h where h.Email = @email) > 0)
	BEGIN
		SET @isNewUser = 0
		UPDATE HC.Hasher
			SET 
				FirstName = @firstName,
				LastName = @lastName,
				Photo = @photo,
				IncludeInGlobalHashDirectory = coalesce(@includeInGlobalHashDirectory,IncludeInGlobalHashDirectory),
				FacebookId = @facebookId,
				FacebookAccessToken = @facebookAccessToken,
				FacebookAccessTokenLastUpdated = getdate(),
				HashName = coalesce(@hashName,HashName),
				updatedAt = getdate()
			FROM HC.Hasher ha
			WHERE ha.Email = @email

	END
	ELSE
	BEGIN
		
		SET @userId = newid()

		INSERT [HC].[Hasher]
			   ([id]
			   ,[FirstName]
			   ,[LastName]
			   ,[Email]
			   ,[HashName]
			   ,[Photo]
			   ,[DisplayName]
			   ,[NameDisplayPreference]
			   ,[IncludeInGlobalHashDirectory]
			   ,[FacebookId]
			   ,[FacebookAccessToken]
			   ,[FacebookAccessTokenLastUpdated]
			   ,[updatedAt])
		 VALUES
			   (@userId,
				coalesce(@firstName,''),
				coalesce(@lastName,''),
				coalesce(@email, ''),
				coalesce(@hashName, ''),
				coalesce(@photo, ''),
				CASE WHEN datalength(coalesce(@hashName,'')) != 0 
					THEN @hashName
				ELSE
					coalesce(@firstName,'') + ' ' + coalesce(@lastName,'')
				END,
				CASE WHEN datalength(coalesce(@hashName,'')) != 0 
					THEN 1
				ELSE
					2
				END,
				COALESCE(@includeInGlobalHashDirectory,0),
				@facebookId,
				@facebookAccessToken,
				getdate(),
				getdate())




	END




	SELECT top 1 
		@userId = h.id 
	FROM HC.Hasher h where h.email = @email

	IF (@userId is not null)
		BEGIN

			SELECT
				h.id as hasherId,
				h.Photo as photo,
				h.DisplayName as displayName,
				h.Email as email,
				h.FacebookId as facebookId,
				h.FirstName as firstName,
				h.HashName as hashName,
				h.LastName as lastName,
				h.QR_code as qrCode,
				h.SupportCode as supportCode,
				h.QR_secret_code as qrSecretCode,
				h.ResetCode as resetCode,
				h.IncludeInGlobalHashDirectory as includeInGlobalHashDirectory
			FROM HC.Hasher h where h.id = @userId
		END
	ELSE
		BEGIN
			SET @errorId = newid()

			INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,deviceId,string_1) VALUES (@errorId,@hcVersion,'User reset code not found','A new user is being registered with a duplicate e-mail address to one already in the system',OBJECT_NAME(@@PROCID),'00000000-0000-0000-0000-000000000000','',@email)

			SELECT 
			@errorId as errorId,
			cast (5 as int) as errorType 
			,'Reset code not found' as errorTitle
			,'The reset code provided was not found in the Harrier Central system' as errorUserMessage
			,'This is a standard error that is anticipated and does not require debugging' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
			RETURN
		END

	-- Now update the Kennels that have this user as a FB admin
	UPDATE HC.Kennel set KennelFacebookToken = @facebookAccessToken, KennelFacebookTokenLastUpdated = getdate() FROM HC.Kennel where KennelFacebookTokenUsername = @email
	
	DECLARE @procName nvarchar(100)
	SET @procName = OBJECT_NAME(@@PROCID)

	DECLARE @RC int


	IF (@isNewUser = 1)
	BEGIN
		-- this case is for when a new user is being created because someone
		-- is adding an account when installing an app for the first time
		SELECT 
			h.id as hasherId,
			coalesce(h.FirstName,'') as firstName,
			coalesce(h.LastName,'') as lastName,
			coalesce(h.DisplayName,'') as dispName,
			coalesce(h.HashName,'') as hashName,
			coalesce(h.Photo,'') as photo,
			coalesce(h.NameDisplayPreference,0) as dispPref,
			coalesce(h.SupportCode,'') as supportCode,
			coalesce(h.ResetCode,'') as resetCode,
			coalesce(h.FacebookId,'') as facebookId,
			coalesce(h.QR_code,'') as qrCode,
			coalesce(h.QR_secret_code,'') as qrSecretCode,
			--coalesce(h.Preferences,0) as preferences,
			--coalesce(h.IncludeInGlobalHashDirectory,0) as includeInGlobalHashDirectory,
			coalesce(h.updatedAt,getdate()) as updatedAt,
			coalesce(h.Removed,0) as removed
			-- either sync the users, or in the case when a new user has been added (@targetUserId has been specified), return only that one record
		FROM HC.Hasher h where h.id = @userId

	END
	ELSE
	BEGIN
			-- this case is when a user is being edited but is not being added as a member of a Kennel or
			-- or added to an event
		EXECUTE @RC = [HC3].[syncUserData] 
			@userId = @userId
			,@accessToken = @accessToken
			,@hashersUpdatedAfter = @hashersUpdatedAfter
			,@citiesUpdatedAfter = 'ignore'
			,@regionsUpdatedAfter = 'ignore'
			,@countriesUpdatedAfter = 'ignore'
			,@kennelsUpdatedAfter = 'ignore'
			,@hasherKennelMapUpdatedAfter ='ignore'
			,@hasherEventMapUpdatedAfter = 'ignore'
			,@narrowEventsUpdatedAfter = 'ignore'
			,@procName = @procName
			,@param = @paramString	
		END

END

GO
/****** Object:  StoredProcedure [HC3].[processPayment]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[processPayment]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[processPayment] AS' 
END
GO

ALTER PROCEDURE [HC3].[processPayment]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@userIdWhoPaid uniqueidentifier = NULL,
@eventId uniqueidentifier,
@hasherEventMapId uniqueidentifier = NULL,
@paymentType smallint,
@productType smallint = 1,
@paymentAmount decimal(12,6) = NULL,
@minimumAttendenceValue smallint = NULL,

@hasherEventMapUpdatedAfter nvarchar(50) = 'ignore',
@hasherKennelMapUpdatedAfter nvarchar(50) = 'ignore',
@paymentsUpdatedAfter nvarchar(50) = 'ignore',
@kennelCreditsUpdatedAfter nvarchar(50) = 'ignore',
@doPayForExtras smallint = 0,
@surcharge decimal(10,4) = NULL,
@paymentProvider nvarchar(50) = NULL,
@appDomainType nvarchar(50) = 'AppDomainType.event'

AS

BEGIN

-- payment type codes:
--    1 = not paid
--    2 = free run
--    3 = cash
--    4 = bank transfer
--    5 = cash (other amount)
--    6 = hash credit
--    7 = bank transfer (other amount)
--	100 = confirm bank transfer

-- product type codes:
--	  1 = event
--    2 = membership
--    3 = haberdashery

-- doPayForExtras:
--    0 = payForRunOnly
--    1 = payForRunAndExtras

-- exec HC.payForEvent @userId = '624C51B3-2F64-4DE5-9458-B506E75AC544', @hasherEventMapId = '0bc3a6ea-0e9f-432e-acb0-079c1557f004', @paymentType = 3

SET NOCOUNT ON

	IF (@productType is null) SET @productType = 1
	IF (@doPayForExtras is null) SET @doPayForExtras = 0

	DECLARE @paramString nvarchar(500)

	SET @paramString = cast(coalesce(@hasherEventMapId,'00000000-0000-0000-0000-000000000000') as nvarchar(50)) + '#' + cast(coalesce(@userIdWhoPaid,'00000000-0000-0000-0000-000000000000') as nvarchar(50)) + '#' + cast(cast(@paymentAmount as int) as nvarchar(50)) + '#' + cast(@eventId as nvarchar(50))
	--SET @paramString = ''

	DECLARE @errorId uniqueidentifier

	IF (@userId IS NULL) OR (@userId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF ((@eventId IS NULL) OR (@eventId = '00000000-0000-0000-0000-000000000000') AND (@productType = 1))
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty eventId','A null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty eventId' as errorTitle
		,'A null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	--IF (@userIdWhoPaid IS NULL) OR (@userIdWhoPaid = '00000000-0000-0000-0000-000000000000')
	--BEGIN

	--	SET @errorId = newid()

	--	INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or empty userIdWhoPaid','A null or empty userIdWhoPaid was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
	--	SELECT 
	--	@errorId as errorId,
	--	cast (2 as int) as errorType 
	--	,'Null or empty userIdWhoPaid' as errorTitle
	--	,'A null or empty value was passed as the userIdWhoPaid to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
	--	,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
	--	,OBJECT_NAME(@@PROCID) as errorProc
	--	RETURN
	--END

	DECLARE @serverMessage nvarchar(120)

	IF (((@paymentAmount IS NULL) OR (@paymentAmount < 0)) AND (@paymentType < 100))
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or negative payment amount','A null or negative payment amount was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or negative payment amount' as errorTitle
		,'A null or negative value was passed as the payment amount to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken,@paramString) = 0 
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	if (@paymentType = 100)
	BEGIN
		UPDATE HC.Payment SET ConfirmedDate = GETDATE(), ConfirmedBy_UserId = @userId, updatedAt = GETDATE() WHERE HasherEventMapId = @hasherEventMapId AND CancelledDate is null
	END
	ELSE
	BEGIN
			if (@minimumAttendenceValue < 0) SET @minimumAttendenceValue = NULL

			if ((@hasherEventMapId is null) OR (@hasherEventMapId = '00000000-0000-0000-0000-000000000000'))
			BEGIN
				SELECT @hasherEventMapId = id FROM HC.HasherEventMap hem where hem.UserId = @userIdWhoPaid AND hem.EventId = @eventId


				IF ((@hasherEventMapId is null) OR (@hasherEventMapId = '00000000-0000-0000-0000-000000000000'))
				BEGIN

					SET @hasherEventMapId = newid()

					INSERT INTO HC.RunCounts ([TotalPackRunsThisKennel]
				   ,[TotalHaringThisKennel]
				   ,[TotalPackRunsAllKennels]
				   ,[TotalHaringAllKennels]
				   ,[updatedAt]) VALUES (0,0,0,0,GETDATE())

					INSERT HC.HasherEventMap (id,UserId,EventId,RunCountId,RsvpState,Rsvp,UserStartEvent,AttendenceState,updatedAt) VALUES (@hasherEventMapId,@userIdWhoPaid,@eventId,@@IDENTITY,3, getdate(),getdate(),coalesce(@minimumAttendenceValue,0),getdate())
				END
			END

			DECLARE @paymentExists int

			SELECT @paymentExists = COUNT(*) FROM HC.Payment p where p.HasherEventMapId = @hasherEventMapId AND p.CancelledDate IS NULL

			DECLARE
				 @eventPrice money,
				 @extrasPrice money,
				 @creditAmount money,
				 @kennelId uniqueidentifier,
				 @kennelName nvarchar(250),
				 @payer_userIdGuid uniqueidentifier,
				 @attendenceState int,
				 @payer_userName nvarchar(120)

			SELECT
			@eventPrice = CASE WHEN coalesce(hkm.MembershipExpirationDate,'1/1/2000') > getdate() THEN
				coalesce(e.EventPriceForMembers,k.DefaultEventPriceForMembers,e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,0)
			ELSE
				coalesce(e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,e.EventPriceForMembers,k.DefaultEventPriceForMembers,0)
			END
			,@extrasPrice = CASE WHEN @doPayForExtras = 1 THEN coalesce(e.EventPriceForExtras,0) ELSE 0 END
			,@kennelId = k.id
			,@kennelName = coalesce(k.KennelShortName,k.KennelName,'<No kennel name>')
			,@payer_userIdGuid = hem.UserId
			,@attendenceState = hem.AttendenceState
			,@eventId = coalesce(@eventId,e.id)
			,@payer_userName = coalesce(CASE 
				WHEN (h.NameDisplayPreference = 1 AND datalength(h.HashName) > 0)
					THEN h.HashName
				WHEN (h.NameDisplayPreference = 2 OR datalength(h.HashName) = 0)
					THEN h.FirstName + ' ' + h.LastName
				ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
				END,hem.DisplayName,'<no name>')
			FROM HC.HasherEventMap hem
			INNER JOIN HC.Event e ON e.id = hem.EventId
			INNER JOIN HC.Kennel k on k.id = e.KennelId
			LEFT OUTER JOIN HC.HasherKennelMap hkm on hem.UserId = hkm.UserId AND hkm.KennelId = e.kennelId
			LEFT OUTER JOIN HC.Hasher h on h.id = hem.UserId
			WHERE hem.id = @hasherEventMapId --AND e.deleted = 0 AND e.IsVisible <> 0

			SET @eventPrice = @eventPrice + @extrasPrice

			if ((@paymentType = 1) AND (@paymentExists > 0)) -- handle the 'Not paid' case
			BEGIN
				UPDATE HC.Payment SET CancelledDate = getdate(), CancelledBy_UserId = @userId, updatedAt = getdate() WHERE CancelledDate is null AND HasherEventMapId = @hasherEventMapId
			END

			IF (@paymentType = 2) 
			BEGIN
				SET @eventPrice = @extrasPrice -- in this case the run is "free", extras will be zero unless the @doPayForExtras flag is set, we still charge for extras even if the run is free
			END

			DECLARE @paymentReference NVARCHAR(50)
			SET @paymentReference = 'NONE'

			IF ((@paymentType >= 2) AND (@paymentType <= 7)) -- in this case the run is paid in cash, bank transfer or using credits or was free
			BEGIN

				-- set the track Hash Cash flag. This should only perform an update the first time a transaction is made.
				UPDATE HC.Event SET DoTrackHashCash = 1 FROM HC.Event e WHERE e.id = @eventId AND DoTrackHashCash != 1
				
				DECLARE @count int
				SET @count = 1

				-- loop until there are no duplicates
				WHILE (@count > 0)
				BEGIN
					SET @paymentReference = HC.NUMBER_TO_STR_BASE (36,(RAND() * (2147483647 - 60466177)) + 60466176)
					SELECT @count = COUNT(*) FROM HC.Payment WHERE PaymentReference = @paymentReference
				END
		
				IF ((@paymentType = 5) OR (@paymentType = 7))
					SET @creditAmount = @paymentAmount
				ELSE
					SET @creditAmount = @eventPrice

				IF (@paymentType = 6) SET @creditAmount = 0 -- this is the case when hashers are paying using their existing 'hash credit'

				if (@paymentExists > 0)
				BEGIN
					-- We only allow one payment per event, so cancel any previous payments when a new payment comes in for an event that is of type "free", "cash", "bank transfer", or "credit"
					UPDATE HC.Payment SET CancelledDate = getdate(), CancelledBy_UserId = @userId, updatedAt = getdate() WHERE CancelledDate is null AND HasherEventMapId = @hasherEventMapId
				END

				-- Now insert a new payment record
				INSERT HC.Payment (KennelId, UserId, EventId, HasherEventMapId, CreditAmount,DebitAmount,CreditAvailable,PaymentProcessedBy_userId,PaidDate, PaymentType, ProductType, PaymentReference, DoPayForExtras, PaymentProvider, Surcharge, updatedAt) 
						VALUES (@kennelId,@payer_userIdGuid,@eventId,@hasherEventMapId,@creditAmount,@eventPrice,0,@userId,GETDATE(),@paymentType, @productType, @paymentReference,@doPayForExtras, @paymentProvider, coalesce(@surcharge,0), getdate())


				-- if they have paid, mark them as being at the event.
				UPDATE HC.HasherEventMap set UserStartEvent = getdate(), RsvpState = 3, AttendenceState = CASE when AttendenceState < @minimumAttendenceValue then @minimumAttendenceValue else AttendenceState end, updatedAt = getdate() where id = @hasherEventMapId

				SELECT @attendenceState = CASE WHEN coalesce(@attendenceState,0) < @minimumAttendenceValue THEN @minimumAttendenceValue ELSE @attendenceState END


			END


			-- TODO: See how we can optimize this so we are not having to constantly re-calculate the credit available!!!
			-- Update the Kennel Credit table if necessary
			--IF (@paymentExists > 0 OR (@paymentType >= 5) AND (@paymentType <= 7))
			--BEGIN
				DECLARE @creditAvailable smallmoney
				SELECT @creditAvailable = SUM(pay.creditAmount) - SUM(pay.debitAmount) FROM HC.Payment pay WHERE pay.KennelId = @kennelId AND pay.UserId = @payer_userIdGuid AND pay.CancelledDate IS NULL AND pay.PaymentType BETWEEN 5 AND 7 
				if (@creditAvailable IS NOT NULL)
					BEGIN
						DECLARE @latestEventId uniqueidentifier
						SELECT top 1 @latestEventId = hem.EventId from HC.HasherEventMap hem 
						INNER JOIN HC.Event evt on hem.EventId = evt.id and hem.UserId = @payer_userIdGuid
						WHERE evt.KennelId = @kennelId AND hem.AttendenceState >= 20
						ORDER BY evt.EventStartDatetime desc

						MERGE HC.KennelCredit AS [Target] 
						USING (SELECT @payer_userIdGuid AS userId, @kennelId AS kennelId) AS [Source] ON [Target].kennelId = [Source].kennelId AND [Target].userId = [Source].userId 
						WHEN MATCHED THEN UPDATE SET [Target].currentBalance = @creditAvailable, [Target].balanceAsOfEventId = @eventId, [Target].updatedAt = getdate() 
						WHEN NOT MATCHED THEN INSERT (userId, kennelId,currentBalance,balanceAsOfEventId,updatedAt) VALUES (@payer_userIdGuid, @kennelId,@creditAvailable,@latestEventId,getdate());
					END
				ELSE
					BEGIN
						UPDATE HC.KennelCredit SET currentBalance = 0, balanceAsOfEventId = @eventId, updatedAt = GETDATE() FROM HC.KennelCredit kc WHERE kc.userId = @payer_userIdGuid and kc.kennelId = @kennelId
					END

				EXEC HC3.nonApi_updateHasherCreditBalance @hemId = @hasherEventMapId
			--END

			IF (@userIdWhoPaid IS NOT NULL)
				BEGIN
					EXEC HC.nonApi_adjustHasherRunCounts @limitByUser = 1,@userId = @userIdWhoPaid, @kennelId = @kennelId
				END
			ELSE
				BEGIN
					EXEC HC.nonApi_adjustHasherRunCounts @limitByUser = 2,@hasherEventMapId = @hasherEventMapId
				END
	END



	-- send back adHoc data to support cases when the user was scanned in at a Hash
	SELECT
		1 as adHocDataId,
		@payer_userName as hasherWhoPaid,
		@attendenceState as attendenceState,
		3 as rsvpState,
		@paymentType as paymentType,
		@productType as productType,
		@eventPrice as debitAmount,
		@creditAmount as creditAmount,
		@paymentAmount as paymentAmount,
		@creditAvailable as creditAvailable,
		@paymentReference as paymentReference

	DECLARE @procName nvarchar(500)
	SET @procName = OBJECT_NAME(@@PROCID)

	if (@appDomainType = 'AppDomainType.event')
		BEGIN
			EXEC HC3.syncEventAdminData 
				@userId = @userId,
				@accessToken = @accessToken,
				@eventId = @eventId,
				@hashersUpdatedAfter = 'ignore',
				@hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter,
				@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter,
				@narrowEventsUpdatedAfter = 'ignore',
				@paymentsUpdatedAfter = @paymentsUpdatedAfter,
				@kennelCreditsUpdatedAfter = @kennelCreditsUpdatedAfter,
				@receiptsUpdatedAfter = 'ignore',
				@procName = @procName,
				@param = @paramString
		END
	ELSE
		BEGIN
			EXECUTE [HC3].[syncUserData] 
			   @userId = @userId
			  ,@accessToken = @accessToken
			  ,@hashersUpdatedAfter = 'ignore'
			  ,@citiesUpdatedAfter = 'ignore'
			  ,@regionsUpdatedAfter = 'ignore'
			  ,@countriesUpdatedAfter = 'ignore'
			  ,@kennelsUpdatedAfter = 'ignore'
			  ,@hasherKennelMapUpdatedAfter = @hasherKennelMapUpdatedAfter
			  ,@hasherEventMapUpdatedAfter = @hasherEventMapUpdatedAfter
			  ,@narrowEventsUpdatedAfter = 'ignore'
			  ,@paymentsUpdatedAfter = @paymentsUpdatedAfter
			  ,@procName = @procName
			  ,@param = @paramString
		END

END
GO
/****** Object:  StoredProcedure [HC3].[rptApi_emailRunDetails]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[rptApi_emailRunDetails]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[rptApi_emailRunDetails] AS' 
END
GO
ALTER PROCEDURE [HC3].[rptApi_emailRunDetails]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@eventId uniqueidentifier

AS

/*

EXEC HC3.rptApi_emailRunDetails @userId = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC',
 @accessToken = 'C429B418D5641B6E7F9EFDE9932B88AA17CF95FAC042F132A65CC8DF01B9519E', 
 @eventId = '1AFCF394-9DCC-47D4-B939-78BBBCE9364E'

 */

DECLARE @errorId uniqueidentifier

	IF (@userId IS NULL)
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END


	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken,@eventId) = 0 
	BEGIN
		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,string_1) VALUES (@errorId,'<unknown>','Invalid access token','The access token did not validate',OBJECT_NAME(@@PROCID),@userId,'')

		select 
		@errorId as errorId,
		cast (1 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'A security safety feature has been activated. Contact the Harrier Central support team at connect@harriercentral.com to resolve the issue.' as errorUserMessage
		,'This could be an indication that there is an error in the code. It can also be a sign of potential malicious activity.' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	-- first get the e-mail body data
	select 
		h.DisplayName as sender,
		h.Email as senderEmail,

		k.KennelShortName + ' run information ' + case when datalength(coalesce(evt.EventName,'')) = 0 then '' else 'for ' + evt.EventName end as SubjectLine,

	
	'Hash Kennel: ' + k.kennelName +  CHAR(13)+CHAR(10) + 
	coalesce(case when datalength(coalesce(evt.EventName,'')) = 0 then '' else 'Event name: ' + evt.EventName + CHAR(13)+CHAR(10) end ,'') +
	coalesce(case when evt.IsCountedRun != 1 then '' else 'Run Number: ' + cast(evt.EventNumber as nvarchar(10)) + CHAR(13)+CHAR(10) end ,'') +
	'Date: ' + convert(nvarchar(100),CAST(EventStartDatetime as datetime2),100) + CHAR(13)+CHAR(10) + 
	coalesce(case when datalength(coalesce(evt.Hares,'')) = 0 then '' else 'Hares: ' + evt.Hares + CHAR(13)+CHAR(10) end ,'') +

	CHAR(13)+CHAR(10) + 

	case when coalesce(evt.EventPriceForMembers,k.DefaultEventPriceForMembers,0) > 0 then 'Event price (members): ' + cast(coalesce(evt.EventPriceForMembers,k.DefaultEventPriceForMembers) as nvarchar(20)) + CHAR(13)+CHAR(10) end +
	case when coalesce(evt.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,0) > 0 then 'Event price (non-members): ' + cast(coalesce(evt.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers) as nvarchar(20)) + CHAR(13)+CHAR(10) end +

	CHAR(13)+CHAR(10) + 
	coalesce(case when datalength(coalesce(evt.LocationOneLineDesc,'')) = 0 then '' else 'Location: ' + evt.LocationOneLineDesc + CHAR(13)+CHAR(10) end,'') +
	coalesce(case when datalength(coalesce(evt.LocationStreet,'')) = 0 then '' else 'Street: ' + evt.LocationStreet + CHAR(13)+CHAR(10) end ,'') +
	coalesce(case when datalength(coalesce(evt.LocationPostCode,'')) = 0 then '' else 'Post Code: ' + evt.LocationPostCode + CHAR(13)+CHAR(10) end ,'') +
	coalesce(case when datalength(coalesce(evt.LocationCity,'')) = 0 then '' else 'City: ' + evt.LocationCity + ', ' + evt.LocationCountry + CHAR(13)+CHAR(10) end ,'') +
	coalesce(case when coalesce(evt.latitude,evt.FbLatitude) is null then '' else 'Lat/Long: ' + cast(cast(coalesce(evt.latitude,evt.FbLatitude) as decimal(9,6)) as nvarchar(15)) + ', ' + cast(cast(coalesce(evt.longitude,evt.FbLongitude) as decimal(10,6)) as nvarchar(15)) end ,'') +

	coalesce(case when datalength(evt.EventFacebookId) = 0 then '' else CHAR(13)+CHAR(10) + 'Facebook Event: https://www.facebook.com/events/' + evt.EventFacebookId end,'') +
	'' as EventDetailsPlainText,


	'Hash Kennel: ' + k.kennelName +  CHAR(13)+CHAR(10) + 
	coalesce(case when datalength(coalesce(evt.EventName,'')) = 0 then '' else 'Event name: ' + evt.EventName + CHAR(13)+CHAR(10) end ,'') +
	coalesce(case when evt.IsCountedRun != 1 then '' else 'Run Number: ' + cast(evt.EventNumber as nvarchar(10)) + CHAR(13)+CHAR(10) end ,'') +
	'Date: ' + convert(nvarchar(100),CAST(EventStartDatetime as datetime2),100) + CHAR(13)+CHAR(10) + 
	coalesce(case when datalength(coalesce(evt.Hares,'')) = 0 then '' else 'Hares: ' + evt.Hares + CHAR(13)+CHAR(10) end ,'') +

	CHAR(13)+CHAR(10) + 

	case when coalesce(evt.EventPriceForMembers,k.DefaultEventPriceForMembers,0) > 0 then 'Event price (members): ' + cast(coalesce(evt.EventPriceForMembers,k.DefaultEventPriceForMembers) as nvarchar(20)) + CHAR(13)+CHAR(10) end +
	case when coalesce(evt.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,0) > 0 then 'Event price (non-members): ' + cast(coalesce(evt.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers) as nvarchar(20)) + CHAR(13)+CHAR(10) end +

	CHAR(13)+CHAR(10) + 
	coalesce(case when datalength(coalesce(evt.LocationOneLineDesc,'')) = 0 then '' else 'Location: ' + evt.LocationOneLineDesc + CHAR(13)+CHAR(10) end,'') +
	coalesce(case when datalength(coalesce(evt.LocationStreet,'')) = 0 then '' else 'Street: ' + evt.LocationStreet + CHAR(13)+CHAR(10) end ,'') +
	coalesce(case when datalength(coalesce(evt.LocationPostCode,'')) = 0 then '' else 'Post Code: ' + evt.LocationPostCode + CHAR(13)+CHAR(10) end ,'') +
	coalesce(case when datalength(coalesce(evt.LocationCity,'')) = 0 then '' else 'City: ' + evt.LocationCity + ', ' + evt.LocationCountry + CHAR(13)+CHAR(10) end ,'') +
	coalesce(case when coalesce(evt.latitude,evt.FbLatitude) is null then '' else 'Lat/Long: ' + cast(cast(coalesce(evt.latitude,evt.FbLatitude) as decimal(9,6)) as nvarchar(15)) + ', ' + cast(cast(coalesce(evt.longitude,evt.FbLongitude) as decimal(10,6)) as nvarchar(15)) end ,'') +

	coalesce(case when datalength(evt.EventFacebookId) = 0 then '' else CHAR(13)+CHAR(10) + 'Facebook Event: https://www.facebook.com/events/' + evt.EventFacebookId end,'') +
	'' as EventDetailsHtml,

	coalesce(case when datalength(coalesce(evt.EventDescription,'')) = 0 then '' else EventDescription end,'') as EventDescription
	FROM HC.Event evt 
	INNER JOIN HC.Kennel k ON k.id = evt.KennelId,
	HC.Hasher h
	WHERE evt.id = @eventId and h.id = @userId


	-- now select all the receipients
	SELECT h.DisplayName,h.Email 
	FROM HC.Event evt
	INNER JOIN HC.HasherKennelMap hkm ON hkm.kennelId = evt.kennelId
	INNER JOIN HC.Hasher h ON h.id = hkm.UserId
	LEFT OUTER JOIN HC.HasherEventMap hem ON hem.EventId = evt.id and hem.UserId = h.id
	WHERE evt.id = @eventId
	AND coalesce(hem.EventEmailAlertPreference,hkm.KennelEmailAlertPreference) = 1


	
GO
/****** Object:  StoredProcedure [HC3].[rptApi_sendScheduledEmails]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[rptApi_sendScheduledEmails]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[rptApi_sendScheduledEmails] AS' 
END
GO
ALTER PROCEDURE [HC3].[rptApi_sendScheduledEmails]

AS

/*

This procedure is used to automatically send reminder e-mails for upcoming events. Currently it only reads the 
Kennel's event template, it does not look for templates specific to events. I also have to update it to e-mail
to visitors.

*/

/*

EXEC [HC3].[rptApi_sendScheduledEmails]

 */


 select
	emt.KennelId,
	evt.id as EventId,
	emt.Subject,
	emt.Template,
	emt.SendToAll,
	emt.SendToFollowers,
	emt.SendToVisitors,
	emt.SendToMembers,
	emt.SendToMismanagement,
	'Hash Kennel: ' + k.kennelName +  CHAR(13)+CHAR(10) + 
	coalesce(case when datalength(coalesce(evt.EventName,'')) = 0 then '' else 'Event name: ' + evt.EventName + CHAR(13)+CHAR(10) end ,'') +
	coalesce(case when evt.IsCountedRun != 1 then '' else 'Run Number: ' + cast(evt.EventNumber as nvarchar(10)) + CHAR(13)+CHAR(10) end ,'') +
	'Date: ' + convert(nvarchar(100),CAST(EventStartDatetime as datetime2),100) + CHAR(13)+CHAR(10) + 
	coalesce(case when datalength(coalesce(evt.Hares,'')) = 0 then '' else 'Hares: ' + evt.Hares + CHAR(13)+CHAR(10) end ,'') +

	CHAR(13)+CHAR(10) + 

	case when evt.EventPriceForMembers != '-' then 'Event price (members): ' + evt.EventPriceForMembers + CHAR(13)+CHAR(10) ELSE '' end +
	case when evt.EventPriceForNonMembers != '-' then 'Event price (non-members): ' + evt.EventPriceForNonMembers + CHAR(13)+CHAR(10) + CHAR(13)+CHAR(10) ELSE '' end 

	+ coalesce(case when datalength(coalesce(evt.LocationOneLineDesc,'')) = 0 then '' else 'Location: ' + evt.LocationOneLineDesc + CHAR(13)+CHAR(10) end,'')
	+ coalesce(case when datalength(coalesce(evt.LocationStreet,'')) = 0 then '' else 'Street: ' + evt.LocationStreet + CHAR(13)+CHAR(10) end ,'')
	+ coalesce(case when datalength(coalesce(evt.LocationPostCode,'')) = 0 then '' else 'Post Code: ' + evt.LocationPostCode + CHAR(13)+CHAR(10) end ,'')
	+ coalesce(case when datalength(coalesce(evt.LocationCity,'')) = 0 then '' else 'City: ' + evt.LocationCity + ', ' + evt.LocationCountry + CHAR(13)+CHAR(10) end ,'')
	+ coalesce(case when evt.latitude is null then '' else 'Lat/Long: ' + cast(cast(evt.latitude as decimal(9,6)) as nvarchar(15)) + ', ' + cast(cast(evt.longitude as decimal(10,6)) as nvarchar(15)) end ,'')
	+ coalesce(case when datalength(evt.EventFacebookId) = 0 then '' else CHAR(13)+CHAR(10) + 'Facebook Event: https://www.facebook.com/events/' + evt.EventFacebookId end,'')
	+ ''
	as EventDetailsPlainText,
			'Hash Kennel: ' + k.kennelName +  CHAR(13)+CHAR(10) + 
	coalesce(case when datalength(coalesce(evt.EventName,'')) = 0 then '' else 'Event name: ' + evt.EventName + CHAR(13)+CHAR(10) end ,'') +
	coalesce(case when evt.IsCountedRun != 1 then '' else 'Run Number: ' + cast(evt.EventNumber as nvarchar(10)) + CHAR(13)+CHAR(10) end ,'') +
	'Date: ' + convert(nvarchar(100),CAST(EventStartDatetime as datetime2),100) + CHAR(13)+CHAR(10) + 
	coalesce(case when datalength(coalesce(evt.Hares,'')) = 0 then '' else 'Hares: ' + evt.Hares + CHAR(13)+CHAR(10) end ,'') +

	CHAR(13)+CHAR(10) + 

	case when evt.EventPriceForMembers != '-' then 'Event price (members): ' + evt.EventPriceForMembers + CHAR(13)+CHAR(10) ELSE '' end +
	case when evt.EventPriceForNonMembers != '-' then 'Event price (non-members): ' + evt.EventPriceForNonMembers + CHAR(13)+CHAR(10) + CHAR(13)+CHAR(10) ELSE '' end 

	+ coalesce(case when datalength(coalesce(evt.LocationOneLineDesc,'')) = 0 then '' else 'Location: ' + evt.LocationOneLineDesc + CHAR(13)+CHAR(10) end,'')
	+ coalesce(case when datalength(coalesce(evt.LocationStreet,'')) = 0 then '' else 'Street: ' + evt.LocationStreet + CHAR(13)+CHAR(10) end ,'')
	+ coalesce(case when datalength(coalesce(evt.LocationPostCode,'')) = 0 then '' else 'Post Code: ' + evt.LocationPostCode + CHAR(13)+CHAR(10) end ,'')
	+ coalesce(case when datalength(coalesce(evt.LocationCity,'')) = 0 then '' else 'City: ' + evt.LocationCity + ', ' + evt.LocationCountry + CHAR(13)+CHAR(10) end ,'')
	+ coalesce(case when evt.latitude is null then '' else 'Lat/Long: ' + cast(cast(evt.latitude as decimal(9,6)) as nvarchar(15)) + ', ' + cast(cast(evt.longitude as decimal(10,6)) as nvarchar(15)) end ,'')

	+ coalesce(case when datalength(evt.EventFacebookId) = 0 then '' else CHAR(13)+CHAR(10) + 'Facebook Event: https://www.facebook.com/events/' + evt.EventFacebookId end,'')
	+ '' 
	as EventDetailsHtmlText
	,coalesce(case when datalength(coalesce(evt.EventDescription,'')) = 0 then '' else EventDescription end,'') as EventDescription
	,coalesce(case when datalength(coalesce(evt.EventName,'')) = 0 then '' else EventName end,'') as EventName
	,emt.SenderName
	,emt.ReplyToEmailAddress
	,emt.id as TemplateId
	,cast(evt.EventStartDatetime as DateTime) as EventStartDatetime
	,(coalesce(evt.LocationOneLineDesc,'')) as LocationOneLine
	,(coalesce(evt.LocationStreet,'')) as LocationStreet
	,(coalesce(evt.LocationPostCode,'')) as LocationPostCode
	,(coalesce(evt.LocationCity,'')) as LocationCity
	,(coalesce(evt.latitude,0)) as Latitude
	,(coalesce(evt.longitude,0)) as longitude
	,(coalesce(evt.EventNumber,0)) as eventNumber
	,k.KennelName
	,k.KennelShortName
	,k.KennelLogo
	,coalesce(evt.EventPaymentUrl,k.KennelPaymentUrl,'') as paymentUrl
	,k.KennelMismanagementTeam
into #temp
from HC.EmailTemplate emt
 INNER JOIN HC.Kennel k on emt.KennelId = k.id
 INNER JOIN HC.vwEventAdjusted evt on evt.KennelId = k.id
 LEFT OUTER JOIN HC.EmailLog elog on elog.EmailTemplaterId = emt.id AND elog.EventId = evt.id
 WHERE elog.id IS NULL
 AND GETDATE() BETWEEN  DATEADD(hour,-8,DATEADD(hour,-emt.HoursBeforeRun,DATEADD(day,-emt.DaysBeforeRun,evt.EventStartDatetime))) 
 AND DATEADD(hour,8,DATEADD(hour,-emt.HoursBeforeRun,DATEADD(day,-emt.DaysBeforeRun,evt.EventStartDatetime)))
 AND evt.IsVisible = 1
 AND ((emt.SendWhenHareAssigned = 0) OR ((emt.SendWhenHareAssigned = 1) AND (coalesce(datalength(evt.Hares),0) = 0)) OR ((emt.SendWhenHareAssigned = 2) AND (coalesce(datalength(evt.Hares),0) > 0)))

 select * from #temp

 --now select all the receipients
SELECT 
	-- top 1
	evt.id as EventId, 
	h.DisplayName,
	h.Email,
	CAST((hkm.MismanagementRoleFlags & 0x0001) | (hkm.AppAccessFlags & 0x0001) AS smallint) AS isMisManagement,
	CAST(CASE WHEN (hkm.MembershipExpirationDate > getdate()) THEN 1 ELSE 0 END AS smallint) AS isMember,
	CAST(hkm.Following as smallint) as isFollowing,
	CAST(0 as smallint) as isVisitor
	--hem.AttendenceState,
	--evt.EventName
FROM HC.Event evt
INNER JOIN HC.HasherKennelMap hkm ON hkm.kennelId = evt.kennelId
INNER JOIN HC.Hasher h ON h.id = hkm.UserId
LEFT OUTER JOIN HC.HasherEventMap hem ON hem.EventId = evt.id and hem.UserId = h.id
WHERE evt.id in (select EventId from #temp)
AND coalesce(hem.EventEmailAlertPreference,hkm.KennelEmailAlertPreference) = 1
AND (hkm.Following = 1 OR ((hkm.MismanagementRoleFlags & 0x0001) = 1) OR ((hkm.HcWebPermissionFlags & 0x0001) = 1) OR hkm.MembershipExpirationDate > getdate())
--AND h.Email like '%james%'

UNION

SELECT 
	-- now get all of the visitors
	evt2.id as EventId, 
	coalesce(h2.DisplayName,hem2.DisplayName,'<no name>') as DisplayName,
	coalesce(h2.Email,hem2.Email,'<no email>') as Email,
	cast(0 as smallint) AS isMisManagement,
	cast(0 as smallint) AS isMember,
	cast(0 as smallint) as isFollowing,
	cast(1 as smallint) as isVisitor
	--hem2.AttendenceState,
	--evt2.EventName
	FROM HC.Event evt2
	INNER JOIN HC.HasherEventMap hem2 on hem2.EventId = evt2.id
	LEFT OUTER JOIN HC.Hasher h2 on h2.id = hem2.UserId
	LEFT OUTER JOIN HC.HasherKennelMap hkm2 ON hkm2.kennelId = evt2.kennelId AND hkm2.UserId = hem2.UserId
	WHERE evt2.id in (select EventId from #temp)
		AND hem2.RsvpState >= 3
		AND ((hkm2.id is null) OR (hkm2.Following != 1 AND ((hkm2.MismanagementRoleFlags & 0x0001) = 0) AND ((hkm2.HcWebPermissionFlags & 0x0001) = 0) AND hkm2.MembershipExpirationDate < getdate()))
		--AND (h2.Email IS NULL OR h2.Email like '%james%')

drop table #temp



	
GO
/****** Object:  StoredProcedure [HC3].[rptKennelRunStats]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[rptKennelRunStats]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[rptKennelRunStats] AS' 
END
GO

ALTER PROCEDURE [HC3].[rptKennelRunStats]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @kennelId uniqueidentifier

AS

BEGIN

SET NOCOUNT ON

	DECLARE @errorId uniqueidentifier

	IF (@userId IS NULL) OR (@userId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken,NULL) = 0 
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	EXEC HC.nonApi_rptKennelRunStats @kennelId = @kennelId

END





GO
/****** Object:  StoredProcedure [HC3].[syncEventAdminData]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[syncEventAdminData]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[syncEventAdminData] AS' 
END
GO



ALTER PROCEDURE [HC3].[syncEventAdminData]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @eventId uniqueidentifier,
 @hashersUpdatedAfter nvarchar(50) = 'ignore',
 @hasherEventMapUpdatedAfter nvarchar(50) = 'ignore',
 @hasherKennelMapUpdatedAfter nvarchar(50) = 'ignore',
 @narrowEventsUpdatedAfter nvarchar(50) = 'ignore',
 @paymentsUpdatedAfter nvarchar(50) = 'ignore',
 @receiptsUpdatedAfter nvarchar(50) = 'ignore',
 @kennelCreditsUpdatedAfter nvarchar(50) = 'ignore',
 @procName nvarchar(100) = NULL,
 @param nvarchar(500) = NULL

AS

BEGIN

SET NOCOUNT ON

	DECLARE @errorId uniqueidentifier

	IF (@userId IS NULL) OR (@userId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF (@eventId IS NULL) OR (@eventId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty EventId','A null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty eventId' as errorTitle
		,'A null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,coalesce(@procName,OBJECT_NAME(@@PROCID)),@accessToken,@param) = 0 
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	if ((@hashersUpdatedAfter IS NULL) OR (@hashersUpdatedAfter <= '2000-01-01 00:00:00')) SET @hashersUpdatedAfter = 'ignore'
	if ((@hasherEventMapUpdatedAfter IS NULL) OR (@hasherEventMapUpdatedAfter <= '2000-01-01 00:00:00')) SET @hasherEventMapUpdatedAfter = 'ignore'
	if ((@hasherKennelMapUpdatedAfter IS NULL) OR (@hasherKennelMapUpdatedAfter <= '2000-01-01 00:00:00')) SET @hasherKennelMapUpdatedAfter = 'ignore'
	if ((@narrowEventsUpdatedAfter IS NULL) OR (@narrowEventsUpdatedAfter <= '2000-01-01 00:00:00')) SET @narrowEventsUpdatedAfter = 'ignore'
	if ((@paymentsUpdatedAfter IS NULL) OR (@paymentsUpdatedAfter <= '2000-01-01 00:00:00')) SET @paymentsUpdatedAfter = 'ignore'
	if ((@kennelCreditsUpdatedAfter IS NULL) OR (@kennelCreditsUpdatedAfter <= '2000-01-01 00:00:00')) SET @kennelCreditsUpdatedAfter = 'ignore'


	--if ((@hasherEventMapUpdatedAfter IS NULL) ) SET @hasherEventMapUpdatedAfter = 'ignore'
	--if ((@hasherKennelMapUpdatedAfter IS NULL) ) SET @hasherKennelMapUpdatedAfter = 'ignore'
	--if ((@narrowEventsUpdatedAfter IS NULL) ) SET @narrowEventsUpdatedAfter = 'ignore'
	--if ((@paymentsUpdatedAfter IS NULL) ) SET @paymentsUpdatedAfter = 'ignore'
	--if ((@kennelCreditsUpdatedAfter IS NULL) ) SET @kennelCreditsUpdatedAfter = 'ignore'

	DECLARE @kennelId uniqueidentifier
	SELECT @kennelId = kennelId from HC.Event where id = @eventId

	DECLARE @ua datetimeoffset(7)

	if (LOWER(@hashersUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@hashersUpdatedAfter as datetimeoffset(7))
		SELECT 
			h.id as hasherId,
			h.HomeKennelId as homeKennelId,
			coalesce(h.FirstName,'') as firstName,
			coalesce(h.LastName,'') as lastName,
			coalesce(h.DisplayName,'') as dispName,
			coalesce(h.HashName,'') as hashName,
			coalesce(h.Photo,'') as photo,
			coalesce(h.NameDisplayPreference,0) as dispPref,
			coalesce(h.ResetCode,'') as resetCode,
			coalesce(h.QR_code,'') as qrCode,
			coalesce(h.IncludeInGlobalHashDirectory,0) as includeInGlobalHashDirectory,
			coalesce(h.Preferences,0) as preferences,
			coalesce(h.updatedAt,getdate()) as updatedAt,
			coalesce(h.Removed,0) as removed
		FROM HC.Hasher h where updatedAt >= @ua
	END

	if (LOWER(@hasherEventMapUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@hasherEventMapUpdatedAfter as datetimeoffset(7))
		SELECT 
			 [id] as hemId

			,[UserId] as userId
			,[EventId] as eventId
			-- comment out
			,[HasherOwnEventId] as hasherOwnEventId
			,[UserStartEvent] as userStartEvent
			,[UserEndEvent] as userEndEvent
			,[RsvpState] as rsvpState
			,[AttendenceState] as attendenceState
			,[IsHare] as isHare
			,[EventNotificationPreference] as eventNotificationPreference
			,[EventEmailAlertPreference] as eventEmailAlertPreference
			,[EventCountOverride] as eventCountOverride
			,[VirginVisitorType] as virginVisitorType
			,[DisplayName] as displayName
			,[Email] as email
			,[PhoneNumber] as phoneNumber
			,[removed] as removed
			,[updatedAt] as updatedAt
		FROM HC.HasherEventMap where updatedAt > @ua and EventId = @eventId
	END


	if (LOWER(@hasherKennelMapUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@hasherKennelMapUpdatedAfter as datetimeoffset(7))
		SELECT 
		   [id] as hkmId
		  ,[UserId] as userId
		  ,[KennelId] as kennelId

		  ,[Following] as following
		  ,CASE WHEN coalesce(MembershipExpirationDate,'1/1/2000') > getdate() THEN 1 ELSE 0 END as isMember
		  ,[IsHomeKennel] as isHomeKennel
		  ,[IsKennelFollowing] as isKennelFollowing
		  ,[KennelNotificationPreference] as kennelNotificationPreference
		  ,[KennelEmailAlertPreference] as kennelEmailAlertPreference
		  ,[MismanagementRoleFlags] as mismanagementRoleFlags
		  ,[MismanagementRoles] as mismanagementRoles
		  ,[UserRoleFlags] as userRoleFlags
		  ,[AppAccessFlags] as appAccessFlags
		  -- comment next two out
		  ,[CurrentPackRunCount] as currentPackRunCount
		  ,[CurrentHaringCount] as currentHaringCount
		  ,[HistoricalPackRunCount] as historicalPackRunCount
		  ,[HistoricalHaringCount] as historicalHaringCount
		  ,[HistoricalCountIsEstimate] as historicalCountIsEstimate
		  ,[MembershipExpirationDate] as membershipExpirationDate
		  ,[MemberSince] as memberSince
		  ,[DateOfLastRun] as dateOfLastRun

		  ,[removed] as removed
		  ,[updatedAt] as updatedAt
		FROM HC.HasherKennelMap where updatedAt > @ua and KennelId = @kennelId
	END

	if (LOWER(@narrowEventsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@narrowEventsUpdatedAfter as datetimeoffset(7))
		SELECT 
			 evt.[id] as eventId
			,[KennelId] as kennelId
			,[IsVisible] as isVisible
			,[IsCountedRun] as isCountedRun
			,[EventGeographicScope] as eventGeographicScope
			,[EventNumber] as eventNumber
			,evt.[EventPriceForMembers] as eventPriceForMembers
			,evt.[EventPriceForNonMembers] as eventPriceForNonMembers
			,[EventFacebookId] as eventFacebookId
			,[AbsoluteEventNumber] as absoluteEventNumber
			,evt.[CanEditRunAttendence] as canEditRunAttendence

			,evt.[EventPriceForExtras] as eventPriceForExtras
			,evt.[ExtrasDescription] as extrasDescription
			,evt.[DoTrackHashCash] as doTrackHashCash
			
			---- FB run details flag
			--,CASE WHEN (evt.UseFbRunDetails = 1 AND evt.FbEventImage IS NOT NULL) THEN evt.FbEventImage ELSE evt.EventImage END AS eventImage
			--,CASE WHEN (evt.UseFbRunDetails = 1 AND evt.FbEventName IS NOT NULL) THEN evt.FbEventName ELSE evt.EventName END AS eventName
			--,CASE WHEN (evt.UseFbRunDetails = 1 AND evt.FbEventStartDatetime IS NOT NULL) THEN convert(datetime2,evt.FbEventStartDatetime) ELSE convert(datetime2,evt.EventStartDatetime) END AS eventStartDatetime -- This is a bit of a hack, force conversion into local time prior to sending over the wire. TODO: Eventually send over the event UTC and a separate time offset
			--,CASE WHEN (evt.UseFbRunDetails = 1 AND evt.FbEventDescription IS NOT NULL) THEN evt.FbEventDescription ELSE evt.EventDescription END AS eventDescription

			---- FB lat/lon flag
			--,CASE WHEN (evt.UseFbLatLon = 1 AND evt.fbLatitude IS NOT NULL) THEN evt.[fbLatitude] ELSE coalesce(evt.[Latitude],ken.Latitude) END AS narrowEventLatitude
			--,CASE WHEN (evt.UseFbLatLon = 1 AND evt.fbLongitude IS NOT NULL) THEN evt.[fbLongitude] ELSE coalesce(evt.[Longitude],ken.Longitude) END AS narrowEventLongitude

			---- FB location flag
			--,CASE WHEN (evt.UseFbLocation = 1 AND evt.FbLocationOneLineDesc IS NOT NULL) THEN evt.FbLocationOneLineDesc ELSE evt.LocationOneLineDesc END AS locationOneLineDesc
			--,CASE WHEN (evt.UseFbLocation = 1 AND evt.FbLocationPostCode IS NOT NULL) THEN evt.FbLocationPostCode ELSE evt.LocationPostCode END AS locationPostCode
			--,CASE WHEN (evt.UseFbLocation = 1 AND evt.FbLocationCity IS NOT NULL) THEN evt.FbLocationCity ELSE evt.LocationCity END AS locationCity
			--,CASE WHEN (evt.UseFbLocation = 1 AND evt.FbLocationStreet IS NOT NULL) THEN evt.FbLocationStreet ELSE evt.LocationStreet END AS locationStreet
			--,CASE WHEN (evt.UseFbLocation = 1 AND evt.FbLocationCountry IS NOT NULL) THEN evt.FbLocationCountry ELSE evt.LocationCountry END AS locationCountry
			--,CASE WHEN (evt.UseFbLocation = 1 AND evt.FbLocationRegion IS NOT NULL) THEN evt.FbLocationRegion ELSE evt.LocationRegion END AS locationRegion
			--,CASE WHEN (evt.UseFbLocation = 1 AND evt.FbLocationSubRegion IS NOT NULL) THEN evt.FbLocationSubRegion ELSE evt.LocationSubRegion END AS locationSubRegion


			
			-- FB run details flag
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventImage ELSE evt.EventImage END AS eventImage
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventName ELSE evt.EventName END AS eventName
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN convert(datetime2,evt.FbEventStartDatetime) ELSE convert(datetime2,evt.EventStartDatetime) END AS eventStartDatetime -- This is a bit of a hack, force conversion into local time prior to sending over the wire. TODO: Eventually send over the event UTC and a separate time offset
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventDescription ELSE evt.EventDescription END AS eventDescription

			-- FB lat/lon flag
			,CASE WHEN (evt.UseFbLatLon = 1 AND evt.fbLatitude IS NOT NULL) THEN evt.[fbLatitude] ELSE coalesce(evt.[Latitude],ken.Latitude) END AS narrowEventLatitude
			,CASE WHEN (evt.UseFbLatLon = 1 AND evt.fbLongitude IS NOT NULL) THEN evt.[fbLongitude] ELSE coalesce(evt.[Longitude],ken.Longitude) END AS narrowEventLongitude

			-- FB location flag
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationOneLineDesc ELSE evt.LocationOneLineDesc END AS locationOneLineDesc
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationPostCode ELSE evt.LocationPostCode END AS locationPostCode
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationCity ELSE evt.LocationCity END AS locationCity
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationStreet ELSE evt.LocationStreet END AS locationStreet
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationCountry ELSE evt.LocationCountry END AS locationCountry
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationRegion ELSE evt.LocationRegion END AS locationRegion
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationSubRegion ELSE evt.LocationSubRegion END AS locationSubRegion



			,evt.Hares as hares
			,evt.EventPaymentScheme as eventPaymentScheme
			,evt.EventPaymentUrl as eventPaymentUrl
			,evt.EventPaymentUrlExpires as eventPaymentUrlExpires
			,evt.UnconfirmedBankXferCount as unconfirmedBankXferCount

			,evt.[Tags1] as tags1
			,evt.[Tags2] as tags2
			,evt.[Tags3] as tags3

			,evt.[removed] as removed
			,evt.[updatedAt] as updatedAt

		FROM HC.Event evt inner join HC.Kennel ken on evt.KennelId = ken.id
		where evt.updatedAt > @ua
		AND evt.id = @eventId
	END

	if (LOWER(@paymentsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@paymentsUpdatedAfter as datetimeoffset(7))
		SELECT 
			 [id] as paymentId
			,[KennelId] as kennelId
			,[UserId] as paidBy
			,[HasherEventMapId] as hemId
			,[EventId] as eventId
			,[PaymentProcessedBy_userId] as paidTo
			,[CreditAmount] as creditAmount
			,[DebitAmount] as debitAmount
			,[PaidDate] as paidDate
			,[PaymentType] as paymentType
			,[ProductType] as productType
			,[CancelledDate] as cancelledDate
			,[CancelledBy_UserId] as cancelledBy
			,[ConfirmedDate] as confirmedDate
			,[ConfirmedBy_UserId] as confirmedBy
			,[PaymentReference] as paymentReference
			,[Notes] as notes
			,[DoPayForExtras] as doPayForExtras
			,[Surcharge] as surcharge
			,[PaymentProvider] as paymentProvider

			,[removed] as removed
			,[updatedAt] as updatedAt

		FROM HC.Payment pmt
		where pmt.updatedAt > @ua
		AND pmt.EventId = @eventId
	END

	if (LOWER(@receiptsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@receiptsUpdatedAfter as datetimeoffset(7))
		SELECT 
			 [id] as receiptId
			,[EventId] as eventId
			,[UserId] as userId
			,[ReceiptAmount] as receiptAmount
			,[CostCategory] as costCategory
			,[DateUploaded] as dateUploaded
			,[ImageUrl] as imageUrl
			,[ReceiptShortDesc] as receiptShortDesc
			,[Notes] as notes
			,[ReimbursedBy] as reimbursedBy
			,[ReimbursedOn] as reimbursedOn
			,[ReimbursedAmount] as reimbursedAmount
			,[ReimbursedNotes] as reimbursedNotes
			,[removed] as removed
			,[updatedAt] as updatedAt

		FROM HC.Receipt rec
		where rec.updatedAt > @ua
		AND rec.EventId = @eventId
	END

	if (LOWER(@kennelCreditsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@kennelCreditsUpdatedAfter as datetimeoffset(7))
		SELECT 
			 kcred.[id] as kennelCreditId
			,[userId] as userId
			,kcred.[kennelId] as kennelId
			,kcred.[currentBalance] as currentBalance
			,kcred.[balanceAsOfEventId] as balanceAsOfEventId
			,kcred.[updatedAt] as updatedAt
			,kcred.[removed] as removed
		FROM HC.KennelCredit kcred 
		INNER JOIN HC.Event evt on kcred.kennelId = evt.KennelId
		where kcred.updatedAt > @ua
		AND evt.id = @eventId
	END

END

GO
/****** Object:  StoredProcedure [HC3].[syncKennelAdminData]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[syncKennelAdminData]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[syncKennelAdminData] AS' 
END
GO

ALTER PROCEDURE [HC3].[syncKennelAdminData]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @kennelId uniqueidentifier,
 @hashersUpdatedAfter nvarchar(50) = 'ignore',
 @kennelsUpdatedAfter nvarchar(50) = 'ignore',
 @hasherKennelMapUpdatedAfter nvarchar(50) = 'ignore',
 @procName nvarchar(100) = NULL,
 @param nvarchar(500) = NULL

AS

BEGIN

SET NOCOUNT ON

	DECLARE @errorId uniqueidentifier

	IF (@userId IS NULL) OR (@userId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF (@kennelId IS NULL) OR (@kennelId = '00000000-0000-0000-0000-000000000000')
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty EventId','A null or empty eventId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty eventId' as errorTitle
		,'A null or empty value was passed as the eventId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,coalesce(@procName,OBJECT_NAME(@@PROCID)),@accessToken,@param) = 0 
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	if ((@hashersUpdatedAfter IS NULL) OR (@hashersUpdatedAfter <= '2000-01-01 00:00:00')) SET @hashersUpdatedAfter = 'ignore'
	if ((@kennelsUpdatedAfter IS NULL) OR (@kennelsUpdatedAfter <= '2000-01-01 00:00:00')) SET @kennelsUpdatedAfter = 'ignore'
	if ((@hasherKennelMapUpdatedAfter IS NULL) OR (@hasherKennelMapUpdatedAfter <= '2000-01-01 00:00:00')) SET @hasherKennelMapUpdatedAfter = 'ignore'
	
	
	--if ((@kennelsUpdatedAfter IS NULL) ) SET @kennelsUpdatedAfter = 'ignore'
	--if ((@hasherKennelMapUpdatedAfter IS NULL) ) SET @hasherKennelMapUpdatedAfter = 'ignore'


	DECLARE @ua datetimeoffset(7)

	if (LOWER(@kennelsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@kennelsUpdatedAfter as datetimeoffset(7))
		SELECT
			-- GUIDs
			 k.[id] as kennelId
			,[CityId] as cityId
			,[ProvinceStateId] as regionId
			,[CountryId] as countryId

			-- Strings
			,[KennelName] as kennelName
			,[KennelShortName] as kennelShortName
			,[KennelDescription] as kennelDescription
			,[KennelLogo] as kennelLogo
			,[KennelPinColor] as kennelPinColor
			,[KennelCoverPhoto] as kennelCoverPhoto
			,[KennelWebsiteUrl] as kennelWebsiteUrl
			,coalesce([KennelMismanagementTeam],'') as kennelMismanagementTeam
			,[DefaultEventCurrencyType] as defaultEventCurrencyType

			-- Ints / Smallints
			,[KennelStatus] as kennelStatus
			,[AllowNegativeCredit] as allowNegativeCredit
			,[AllowSelfPayment] as allowSelfPayment
			,[MembershipDurationInMonths] as membershipDurationInMonths
			,[DistancePreference] as distancePreference

			-- Doubles
			,coalesce(k.[Latitude],c.[Latitude]) as kennelLatitude
			,coalesce(k.[Longitude],c.[Longitude]) as kennelLongitude
			,[DefaultEventPriceForMembers] as defaultPriceForMembers
			,[DefaultEventPriceForNonMembers] as defaultPriceForNonMembers

			-- DateTimes
			,[DefaultRunStartTime] as defaultRunStartTime
			,[RunCountStartDate] as runCountStartDate

			-- Banking info

			,[CurrencyCode] as currencyCode
			,[PrimaryCultureCode] as primaryCultureCode
			,[CurrencySymbol] as currencySymbol
			,[DigitsAfterDecimal] as digitsAfterDecimal
			,[BankScheme] as bankScheme
			,[BankAccountNumber] as bankAccountNumber
			,[BankBic] as bankBic
			,[BankBeneficiary] as bankBeneficiary

			,[KennelPaymentScheme] as kennelPaymentScheme
			,[KennelPaymentUrl] as kennelPaymentUrl
			,[KennelPaymentUrlExpires] as kennelPaymentUrlExpires
			,[KennelPaymentMemberSurcharge] as kennelPaymentMemberSurcharge
			,[KennelPaymentNonMemberSurcharge] as kennelPaymentNonMemberSurcharge

			,[KennelPaymentScheme2] as kennelPaymentScheme2
			,[KennelPaymentUrl2] as kennelPaymentUrl2
			,[KennelPaymentUrlExpires2] as kennelPaymentUrlExpires2
			,[KennelPaymentMemberSurcharge2] as kennelPaymentMemberSurcharge2
			,[KennelPaymentNonMemberSurcharge2] as kennelPaymentNonMemberSurcharge2

			,[KennelPaymentScheme3] as kennelPaymentScheme3
			,[KennelPaymentUrl3] as kennelPaymentUrl3
			,[KennelPaymentUrlExpires3] as kennelPaymentUrlExpires3
			,[KennelPaymentMemberSurcharge3] as kennelPaymentMemberSurcharge3
			,[KennelPaymentNonMemberSurcharge3] as kennelPaymentNonMemberSurcharge3

			,k.[removed] as removed
			,k.[updatedAt]

	  FROM [HC].[Kennel] k
	  INNER JOIN [HC].[City] c on c.id = k.CityId
	  
	  where k.updatedAt > @ua
  END

  	if (LOWER(@hasherKennelMapUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@hasherKennelMapUpdatedAfter as datetimeoffset(7))
		SELECT 
		   [id] as hkmId
		  ,[UserId] as userId
		  ,[KennelId] as kennelId

		  ,[Following] as following
		  ,CASE WHEN coalesce(MembershipExpirationDate,'1/1/2000') > getdate() THEN 1 ELSE 0 END as isMember
		  ,[IsKennelFollowing] as isKennelFollowing
		  ,[IsHomeKennel] as isHomeKennel
		  ,[KennelNotificationPreference] as kennelNotificationPreference
		  ,[KennelEmailAlertPreference] as kennelEmailAlertPreference
		  ,[MismanagementRoleFlags] as mismanagementRoleFlags
		  ,[MismanagementRoles] as mismanagementRoles
		  ,[UserRoleFlags] as userRoleFlags
		  ,[AppAccessFlags] as appAccessFlags
		  -- comment next two out
		  ,[CurrentPackRunCount] as currentPackRunCount
		  ,[CurrentHaringCount] as currentHaringCount
		  ,[HistoricalPackRunCount] as historicalPackRunCount
		  ,[HistoricalHaringCount] as historicalHaringCount
		  ,[HistoricalCountIsEstimate] as historicalCountIsEstimate
		  ,[MembershipExpirationDate] as membershipExpirationDate
		  ,[MemberSince] as memberSince
		  ,[DateOfLastRun] as dateOfLastRun

		  ,[removed] as removed
		  ,[updatedAt] as updatedAt
		FROM HC.HasherKennelMap where updatedAt > @ua and KennelId = @kennelId
	END

	if (LOWER(@hashersUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@hashersUpdatedAfter as datetimeoffset(7))
		SELECT 
			h.id as hasherId,
			h.HomeKennelId as homeKennelId,
			coalesce(h.FirstName,'') as firstName,
			coalesce(h.LastName,'') as lastName,
			coalesce(h.DisplayName,'') as dispName,
			coalesce(h.HashName,'') as hashName,
			coalesce(h.Photo,'') as photo,
			coalesce(h.NameDisplayPreference,0) as dispPref,
			coalesce(h.ResetCode,'') as resetCode,
			coalesce(h.QR_code,'') as qrCode,
			coalesce(h.IncludeInGlobalHashDirectory,0) as includeInGlobalHashDirectory,
			coalesce(h.Preferences,0) as preferences,
			coalesce(h.updatedAt,getdate()) as updatedAt,
			coalesce(h.Removed,0) as removed
		FROM HC.Hasher h where updatedAt >= @ua
	END

END

GO
/****** Object:  StoredProcedure [HC3].[syncUserData]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[syncUserData]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[syncUserData] AS' 
END
GO

ALTER PROCEDURE [HC3].[syncUserData]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @hashersUpdatedAfter nvarchar(50) = 'ignore',
 @citiesUpdatedAfter nvarchar(50) = 'ignore',
 @regionsUpdatedAfter nvarchar(50) = 'ignore',
 @countriesUpdatedAfter nvarchar(50) = 'ignore',
 @kennelsUpdatedAfter nvarchar(50) = 'ignore',
 @hasherKennelMapUpdatedAfter nvarchar(50) = 'ignore',
 @hasherEventMapUpdatedAfter nvarchar(50) = 'ignore',
 @narrowEventsUpdatedAfter nvarchar(50) = 'ignore',
 --@hasherOwnEventUpdatedAfter nvarchar(50) = 'ignore',
 @paymentsUpdatedAfter nvarchar(50) = 'ignore',
 @procName nvarchar(100) = NULL,
 @param nvarchar(500) = NULL

AS

BEGIN

SET NOCOUNT ON

	DECLARE @errorId uniqueidentifier

	-- If targetUserId is not equal to ignore then we are processing a new user, so a null or empty UserId is acceptable
	IF ((@userId IS NULL) OR (@userId = '00000000-0000-0000-0000-000000000000'))
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId) VALUES (@errorId,'<unknown>','Null or Empty UserID','A null or empty userId was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId)
		
		SELECT 
		@errorId as errorId,
		cast (2 as int) as errorType 
		,'Null or empty userId' as errorTitle
		,'A null or empty value was passed as the userId to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,coalesce(@procName,OBJECT_NAME(@@PROCID)),@accessToken,@param) = 0 
	BEGIN

		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId, string_1) VALUES (@errorId,'<unknown>','Invalid access token','An invalid access token was passed to ' + OBJECT_NAME(@@PROCID),OBJECT_NAME(@@PROCID),@userId,@accessToken)

		SELECT 
		@errorId as errorId,
		cast (3 as int) as errorType 
		,'Invalid access token' as errorTitle
		,'An invalid access token was passed to '+ OBJECT_NAME(@@PROCID) as errorUserMessage
		,'This error should not occur, please contact us at connect@harriercentral.com' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	if ((@hashersUpdatedAfter IS NULL) OR (@hashersUpdatedAfter <= '2000-01-01 00:00:00')) SET @hashersUpdatedAfter = 'ignore'
	if ((@citiesUpdatedAfter IS NULL) OR (@citiesUpdatedAfter <= '2000-01-01 00:00:00')) SET @citiesUpdatedAfter = 'ignore'
	if ((@regionsUpdatedAfter IS NULL) OR (@regionsUpdatedAfter <= '2000-01-01 00:00:00')) SET @regionsUpdatedAfter = 'ignore'
	if ((@countriesUpdatedAfter IS NULL) OR (@countriesUpdatedAfter <= '2000-01-01 00:00:00')) SET @countriesUpdatedAfter = 'ignore'
	if ((@kennelsUpdatedAfter IS NULL) OR (@kennelsUpdatedAfter <= '2000-01-01 00:00:00')) SET @kennelsUpdatedAfter = 'ignore'
	if ((@hasherKennelMapUpdatedAfter IS NULL) OR (@hasherKennelMapUpdatedAfter <= '2000-01-01 00:00:00')) SET @hasherKennelMapUpdatedAfter = 'ignore'
	if ((@narrowEventsUpdatedAfter IS NULL) OR (@narrowEventsUpdatedAfter <= '2000-01-01 00:00:00')) SET @narrowEventsUpdatedAfter = 'ignore'
	--if ((@hasherOwnEventUpdatedAfter IS NULL) OR (@hasherOwnEventUpdatedAfter <= '2000-01-01 00:00:00')) SET @hasherOwnEventUpdatedAfter = 'ignore'
	if ((@paymentsUpdatedAfter IS NULL) OR (@paymentsUpdatedAfter <= '2000-01-01 00:00:00')) SET @paymentsUpdatedAfter = 'ignore'

	--if ((@hashersUpdatedAfter IS NULL) ) SET @hashersUpdatedAfter = 'ignore'
	--if ((@citiesUpdatedAfter IS NULL) ) SET @citiesUpdatedAfter = 'ignore'
	--if ((@regionsUpdatedAfter IS NULL) ) SET @regionsUpdatedAfter = 'ignore'
	--if ((@countriesUpdatedAfter IS NULL) ) SET @countriesUpdatedAfter = 'ignore'
	--if ((@kennelsUpdatedAfter IS NULL) ) SET @kennelsUpdatedAfter = 'ignore'
	--if ((@hasherKennelMapUpdatedAfter IS NULL) ) SET @hasherKennelMapUpdatedAfter = 'ignore'
	--if ((@narrowEventsUpdatedAfter IS NULL) ) SET @narrowEventsUpdatedAfter = 'ignore'
	--if ((@hasherOwnEventUpdatedAfter IS NULL) ) SET @hasherOwnEventUpdatedAfter = 'ignore'

	DECLARE @ua datetimeoffset(7)

	if (LOWER(@hashersUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@hashersUpdatedAfter as datetimeoffset(7))
		SELECT 
			h.id as hasherId,
			h.HomeKennelId as homeKennelId,
			coalesce(h.FirstName,'') as firstName,
			coalesce(h.LastName,'') as lastName,
			coalesce(h.DisplayName,'') as dispName,
			coalesce(h.HashName,'') as hashName,
			coalesce(h.Photo,'') as photo,
			coalesce(h.NameDisplayPreference,0) as dispPref,
			coalesce(h.ResetCode,'') as resetCode,
			coalesce(h.QR_code,'') as qrCode,
			coalesce(h.IncludeInGlobalHashDirectory,0) as includeInGlobalHashDirectory,
			coalesce(h.Preferences,0) as preferences,
			coalesce(h.updatedAt,getdate()) as updatedAt,
			coalesce(h.Removed,0) as removed
		FROM HC.Hasher h where updatedAt >= @ua
	END

	if (LOWER(@citiesUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@citiesUpdatedAfter as datetimeoffset(7))
		SELECT DISTINCT
			c.id as cityId
		  ,[CityName] as cityName
		  ,[RegionId] as regionId
		  ,c.[Latitude] as latitude
		  ,c.[Longitude] as longitude
		  ,[City_ASCII] as cityAscii
		  ,[FlagFile] as flagFile
		  ,c.[Removed] as removed
		  ,c.[updatedAt] as updatedAt
		FROM HC.City c 
		INNER JOIN HC.Kennel k on c.id = k.CityId
		where c.updatedAt > @ua
	END

	if (LOWER(@regionsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@regionsUpdatedAfter as datetimeoffset(7))
		SELECT DISTINCT
		   r.[id] as regionId
		  ,r.[RegionName] as regionName
		  ,r.[CountryId] as countryId
		  ,r.[FlagFile] as flagFile
		  ,r.[Removed] as removed
		  ,r.[updatedAt] as updatedAt
		FROM HC.Region r
		INNER JOIN HC.Kennel k on r.id = k.ProvinceStateId
		where r.updatedAt > @ua
	END

	if (LOWER(@countriesUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@countriesUpdatedAfter as datetimeoffset(7))
		SELECT DISTINCT
		   c.[id] as countryId
		  ,c.[CountryCode] as countryCode
		  ,c.[Latitude] as latitude
		  ,c.[Longitude] as longitude
		  ,c.[CountryName] as countryName
		  ,c.[ContinentCode] as continentCode
		  ,c.[FlagFile] as flagFile
		  ,c.[CurrencyCode] as currencyCode
		  ,c.[PrimaryCultureCode] as primaryCultureCode
		  ,c.[ShowRegion] as showRegion
		  ,c.[CurrencySymbol] as currencySymbol
		  ,c.[DigitsAfterDecimal] as digitsAfterDecimal
		  ,c.[DistancePreference] as distancePreference
		  ,c.[Removed] as removed
		  ,c.[updatedAt] as updatedAt
		FROM HC.Country c
		INNER JOIN HC.Kennel k on c.id = k.CountryId
		where c.updatedAt > @ua
	END

	if (LOWER(@kennelsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@kennelsUpdatedAfter as datetimeoffset(7))
		SELECT
			-- GUIDs
			 k.[id] as kennelId
			,[CityId] as cityId
			,[ProvinceStateId] as regionId
			,[CountryId] as countryId

			-- Strings
			,[KennelName] as kennelName
			,[KennelShortName] as kennelShortName
			,[KennelDescription] as kennelDescription
			,[KennelLogo] as kennelLogo
			,[KennelCoverPhoto] as kennelCoverPhoto
			,[KennelWebsiteUrl] as kennelWebsiteUrl
			,[KennelMismanagementTeam] as kennelMismanagementTeam
			,[DefaultEventCurrencyType] as defaultEventCurrencyType

			-- Ints / Smallints
			,[KennelStatus] as kennelStatus
			,[AllowNegativeCredit] as allowNegativeCredit
			,[AllowSelfPayment] as allowSelfPayment
			,[MembershipDurationInMonths] as membershipDurationInMonths
			,[DistancePreference] as distancePreference
			,[KennelPinColor] as kennelPinColor

			-- Doubles
			,coalesce(k.[Latitude],c.[Latitude]) as kennelLatitude
			,coalesce(k.[Longitude],c.[Longitude]) as kennelLongitude
			,[DefaultEventPriceForMembers] as defaultPriceForMembers
			,[DefaultEventPriceForNonMembers] as defaultPriceForNonMembers

			-- DateTimes
			,[DefaultRunStartTime] as defaultRunStartTime
			,[RunCountStartDate] as runCountStartDate

			-- Banking info

			,[CurrencyCode] as currencyCode
			,[PrimaryCultureCode] as primaryCultureCode
			,[CurrencySymbol] as currencySymbol
			,[DigitsAfterDecimal] as digitsAfterDecimal
			,[BankScheme] as bankScheme
			,[BankAccountNumber] as bankAccountNumber
			,[BankBic] as bankBic
			,[BankBeneficiary] as bankBeneficiary

			,[KennelPaymentScheme] as kennelPaymentScheme
			,[KennelPaymentUrl] as kennelPaymentUrl
			,[KennelPaymentUrlExpires] as kennelPaymentUrlExpires
			,[KennelPaymentMemberSurcharge] as kennelPaymentMemberSurcharge
			,[KennelPaymentNonMemberSurcharge] as kennelPaymentNonMemberSurcharge

			,[KennelPaymentScheme2] as kennelPaymentScheme2
			,[KennelPaymentUrl2] as kennelPaymentUrl2
			,[KennelPaymentUrlExpires2] as kennelPaymentUrlExpires2
			,[KennelPaymentMemberSurcharge2] as kennelPaymentMemberSurcharge2
			,[KennelPaymentNonMemberSurcharge2] as kennelPaymentNonMemberSurcharge2

			,[KennelPaymentScheme3] as kennelPaymentScheme3
			,[KennelPaymentUrl3] as kennelPaymentUrl3
			,[KennelPaymentUrlExpires3] as kennelPaymentUrlExpires3
			,[KennelPaymentMemberSurcharge3] as kennelPaymentMemberSurcharge3
			,[KennelPaymentNonMemberSurcharge3] as kennelPaymentNonMemberSurcharge3

			,k.[removed] as removed
			,k.[updatedAt]

	  FROM [HC].[Kennel] k
	  INNER JOIN [HC].[City] c on k.CityId = c.id
	  
	  where k.updatedAt > @ua
  END

  	if (LOWER(@hasherKennelMapUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@hasherKennelMapUpdatedAfter as datetimeoffset(7))
		SELECT 
		   [id] as hkmId
		  ,[UserId] as userId
		  ,[KennelId] as kennelId

		  ,[Following] as following
		  ,[IsMember] as isMember
		  ,[IsHomeKennel] as isHomeKennel
		  ,[IsKennelFollowing] as isKennelFollowing
		  ,[KennelNotificationPreference] as kennelNotificationPreference
		  ,[KennelEmailAlertPreference] as kennelEmailAlertPreference
		  ,[MismanagementRoleFlags] as mismanagementRoleFlags
		  ,[MismanagementRoles] as mismanagementRoles
		  ,[UserRoleFlags] as userRoleFlags
		  ,[AppAccessFlags] as appAccessFlags
		  -- comment next two out
		  ,[CurrentPackRunCount] as currentPackRunCount
		  ,[CurrentHaringCount] as currentHaringCount
		  ,[HistoricalPackRunCount] as historicalPackRunCount
		  ,[HistoricalHaringCount] as historicalHaringCount
		  ,[HistoricalCountIsEstimate] as historicalCountIsEstimate
		  ,[MembershipExpirationDate] as membershipExpirationDate
		  ,[MemberSince] as memberSince
		  ,[DateOfLastRun] as dateOfLastRun

		  ,[removed] as removed
		  ,[updatedAt] as updatedAt
		FROM HC.HasherKennelMap where updatedAt > @ua and UserId = @userId
	END

	if (LOWER(@hasherEventMapUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@hasherEventMapUpdatedAfter as datetimeoffset(7))
		SELECT 
			 [id] as hemId

			,[UserId] as userId
			,[EventId] as eventId
			-- comment out
			,[HasherOwnEventId] as hasherOwnEventId
			,[UserStartEvent] as userStartEvent
			,[UserEndEvent] as userEndEvent
			,[RsvpState] as rsvpState
			,[AttendenceState] as attendenceState
			,[IsHare] as isHare
			,[EventNotificationPreference] as eventNotificationPreference
			,[EventEmailAlertPreference] as eventEmailAlertPreference
			,[EventCountOverride] as eventCountOverride
			,[VirginVisitorType] as virginVisitorType
			,[DisplayName] as displayName
			,[Email] as email
			,[PhoneNumber] as phoneNumber
			,[removed] as removed
			,[updatedAt] as updatedAt
		FROM HC.HasherEventMap where updatedAt > @ua and UserId = @userId
	END


	if (LOWER(@narrowEventsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@narrowEventsUpdatedAfter as datetimeoffset(7))
		SELECT 
			 evt.[id] as eventId
			,[KennelId] as kennelId
			,[IsVisible] as isVisible
			,[IsCountedRun] as isCountedRun
			,[EventGeographicScope] as eventGeographicScope
			,[EventNumber] as eventNumber
			,evt.[EventPriceForMembers] as eventPriceForMembers
			,evt.[EventPriceForNonMembers] as eventPriceForNonMembers

			,evt.[EventPriceForExtras] as eventPriceForExtras
			,evt.[ExtrasDescription] as extrasDescription
			,evt.[DoTrackHashCash] as doTrackHashCash

			,[EventFacebookId] as eventFacebookId
			,[AbsoluteEventNumber] as absoluteEventNumber
			,evt.[CanEditRunAttendence] as canEditRunAttendence

			,evt.Hares as hares
			,evt.EventPaymentScheme as eventPaymentScheme
			,evt.EventPaymentUrl as eventPaymentUrl
			,evt.EventPaymentUrlExpires as eventPaymentUrlExpires
			,evt.UnconfirmedBankXferCount as unconfirmedBankXferCount

			,evt.[Tags1] as tags1
			,evt.[Tags2] as tags2
			,evt.[Tags3] as tags3

			
			-- FB run details flag
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventImage ELSE evt.EventImage END AS eventImage
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventName ELSE evt.EventName END AS eventName
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN convert(datetime2,evt.FbEventStartDatetime) ELSE convert(datetime2,evt.EventStartDatetime) END AS eventStartDatetime -- This is a bit of a hack, force conversion into local time prior to sending over the wire. TODO: Eventually send over the event UTC and a separate time offset
			,CASE WHEN (evt.UseFbRunDetails = 1) THEN evt.FbEventDescription ELSE evt.EventDescription END AS eventDescription

			-- FB lat/lon flag
			,CASE WHEN (evt.UseFbLatLon = 1 AND evt.fbLatitude IS NOT NULL) THEN evt.[fbLatitude] ELSE coalesce(evt.[Latitude],ken.Latitude,52.3791) END AS narrowEventLatitude
			,CASE WHEN (evt.UseFbLatLon = 1 AND evt.fbLongitude IS NOT NULL) THEN evt.[fbLongitude] ELSE coalesce(evt.[Longitude],ken.Longitude,4.9003) END AS narrowEventLongitude

			-- FB location flag
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationOneLineDesc ELSE evt.LocationOneLineDesc END AS locationOneLineDesc
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationPostCode ELSE evt.LocationPostCode END AS locationPostCode
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationCity ELSE evt.LocationCity END AS locationCity
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationStreet ELSE evt.LocationStreet END AS locationStreet
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationCountry ELSE evt.LocationCountry END AS locationCountry
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationRegion ELSE evt.LocationRegion END AS locationRegion
			,CASE WHEN (evt.UseFbLocation = 1) THEN evt.FbLocationSubRegion ELSE evt.LocationSubRegion END AS locationSubRegion


			,evt.[removed] as removed
			,evt.[updatedAt] as updatedAt

		FROM HC.Event evt inner join HC.Kennel ken on evt.KennelId = ken.id
		where evt.updatedAt > @ua
	END

	--if (LOWER(@hasherOwnEventUpdatedAfter) != 'ignore')
	--BEGIN
	--	SET @ua = CAST(@hasherOwnEventUpdatedAfter as datetimeoffset(7))
	--	SELECT 
	--		 [id] as hoeId

	--		,[KennelId] as kennelId
	--		,[EventId] as eventId
	--		,[EventStartDatetime] as eventStartDatetime
	--		,[IsVisible] as isVisible
	--		,[IsCountedRun] as isCountedRun
	--		,[EventNumber] as eventNumber
	--		,[EventName] as eventName
	--		,[EventDescription] as eventDescription
	--		,[LocationOneLineDesc] as locationOneLineDesc
	--		,[LocationCity] as locationCity
	--		,[LocationStreet] as locationStreet
	--		,[LocationPostCode] as locationPostCode
	--		,[LocationCountry] as locationCountry
	--		,[Latitude] as latitude
	--		,[Longitude] as longitude
	--		,[EventGeolocation] as eventLocation
	--		,[Hares] as hares

	--		,[removed] as removed
	--		,[updatedAt] as updatedAt
	--	FROM HC.[HasherOwnEvent] where updatedAt > @ua and UserId = @userId
	--END



	if (LOWER(@paymentsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@paymentsUpdatedAfter as datetimeoffset(7))
		SELECT 
			 [id] as paymentId
			,[KennelId] as kennelId
			,[UserId] as paidBy
			,[HasherEventMapId] as hemId
			,[EventId] as eventId
			,[PaymentProcessedBy_userId] as paidTo
			,[CreditAmount] as creditAmount
			,[DebitAmount] as debitAmount
			,[PaidDate] as paidDate
			,[PaymentType] as paymentType
			,[ProductType] as productType
			,[CancelledDate] as cancelledDate
			,[CancelledBy_UserId] as cancelledBy
			,[ConfirmedDate] as confirmedDate
			,[ConfirmedBy_UserId] as confirmedBy
			,[PaymentReference] as paymentReference
			,[Notes] as notes
			,[DoPayForExtras] as doPayForExtras
			,[Surcharge] as surcharge
			,[PaymentProvider] as paymentProvider

			,[removed] as removed
			,[updatedAt] as updatedAt

		FROM HC.Payment pmt
		where pmt.updatedAt > @ua
		AND pmt.UserId = @userId
	END


END





GO
/****** Object:  StoredProcedure [HC3].[utilApi_mergeUsers]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3].[utilApi_mergeUsers]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3].[utilApi_mergeUsers] AS' 
END
GO
ALTER PROCEDURE [HC3].[utilApi_mergeUsers]

	 @keep uniqueidentifier,
	 @merge uniqueidentifier

	 AS

-- EXEC HC3.utilApi_mergeUsers @keep = '98A552D3-DEEA-4A22-B38A-12AAC6FFEF99', @merge = '1A481C54-83BF-4905-B582-4A0795A11491'

SET NOCOUNT ON

BEGIN TRANSACTION Tran1

BEGIN TRY

-- Delete all cancelled transactions for the two user IDs
delete from HC.Payment 
where CancelledBy_UserId is not null 
and (UserId = @keep OR UserId = @merge)

-- Now delete all hem records where the user was not at the event for both user IDs
delete from HC.HasherEventMap where id in
(select hem.id from HC.HasherEventMap hem
inner join HC.Event evt on hem.EventId = evt.id
where (UserId = @keep OR UserId = @merge)
and AttendenceState < 20
and evt.EventStartDatetime < GETDATE())

-- Next, find any cases where both users have paid for the same
-- event. This should not normally happen, but we have to plan
-- for it anyway and clean up the data

delete from HC.Payment where EventId in
(select p.EventId
from HC.Payment p 
where p.userId = @keep or p.userId = @merge
group by p.EventId
having count(*) > 1) AND UserId = @merge

-- Find cases where both users were at the same
-- run and both have payment. Delete the payment
-- only for the @merge Hasher

DELETE FROM HC.Payment where HasherEventMapId in
(SELECT id from HC.HasherEventMap where EventId in
(select hem.EventId
from HC.HasherEventMap hem
where hem.userId = @keep or hem.userId = @merge
group by hem.EventId
having count(*) > 1) AND UserId = @merge)


-- Now find any cases where both users were at the same
-- event. This should not normally happen, but we have to plan
-- for it anyway and clean up the data

delete from HC.HasherEventMap where EventId in
(select hem.EventId
from HC.HasherEventMap hem
where hem.userId = @keep or hem.userId = @merge
group by hem.EventId
having count(*) > 1) AND UserId = @merge


-- Now find any cases where both users were following the same
-- kennel. This is very possible. Go ahead and delete the 
-- record for the merge user. Keep in mind we may lose some
-- data such as the historical run count settings if they
-- were only entered for the merged user.

delete from HC.HasherKennelMap where KennelId in
(select hkm.KennelId
from HC.HasherKennelMap hkm
where hkm.userId = @keep or hkm.userId = @merge
group by hkm.KennelId
having count(*) > 1) AND UserId = @merge

-- Now find any cases where both users have the same
-- friend. This is very possible. Go ahead and delete the 
-- record for the merge user

delete from HC.HasherFriendMap where Friend_UserId in
(select f.Friend_UserId
from HC.HasherFriendMap f
where f.userId = @keep or f.userId = @merge
group by f.Friend_UserId
having count(*) > 1) AND UserId = @merge


-- now move the remaining records for the merge user
-- to the new User Id
UPDATE HC.Payment set UserId = @keep, updatedAt = getdate() where UserId = @merge
UPDATE HC.HasherEventMap set UserId = @keep, updatedAt = getdate() where UserId = @merge
UPDATE HC.HasherKennelMap set UserId = @keep, updatedAt = getdate() where UserId = @merge
UPDATE HC.HasherOwnEvent set UserId = @keep, updatedAt = getdate() where UserId = @merge
--UPDATE HC.HasherFriendMap set UserId = @keep, updatedAt = getdate() where UserId = @merge
UPDATE HC.LaunchAndLogin set UserId = @keep where UserId = @merge
UPDATE HC.Receipt set UserId = @keep, updatedAt = getdate() where UserId = @merge
UPDATE HC.ErrorLog set userId = @keep where userid = @merge

-- Delete from Kennel Credit. Keep in mind, since we are deleting and not setting
-- the removed flag, this record will stay on phones, but only while the end user
-- of the device is in the admin screen. As- soon as they exit and re-enter the 
-- admin screen, the record will be deleted from the device.
DELETE FROM HC.KennelCredit where UserId = @merge

-- This will force the record to be removed from all devices
UPDATE HC.Hasher set Removed = 1, updatedAt = getdate() where id = @merge

-- now clean up run counts
EXEC HC.nonApi_adjustHasherRunCounts @userId = @keep, @limitByUser = 3

DECLARE @kennelId uniqueidentifier
 

DECLARE xCrsr CURSOR FOR 
SELECT distinct KennelId FROM HC.HasherEventMap hem
inner join HC.Event evt on hem.EventId = evt.id where hem.UserId = @keep

OPEN xCrsr

FETCH NEXT FROM xCrsr into @kennelId

WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC HC3.nonApi_updateHasherCreditBalance @userId = @keep, @kennelId = @kennelId
	FETCH NEXT FROM xCrsr into @kennelId
END

CLOSE xCrsr
DEALLOCATE xCrsr

COMMIT TRANSACTION Tran1

SELECT 'Merge succeeded' as Message, 1 as Result

END TRY

BEGIN CATCH

ROLLBACK TRANSACTION Tran1

SELECT 'Merge failed' as Message, 0 as Result


END CATCH
















GO
/****** Object:  StoredProcedure [HC3W].[importKennel]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3W].[importKennel]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3W].[importKennel] AS' 
END
GO

ALTER PROCEDURE [HC3W].[importKennel]

 @KennelImportId uniqueidentifier

AS

BEGIN

	DECLARE @result nvarchar(250)

	IF (@KennelImportId is null)
		BEGIN
			SET @result = 'Import failed. An invalid KennelImportId was passed.'
		END
	ELSE
		BEGIN
			IF NOT EXISTS(SELECT * FROM EXT.OfficeForms_KennelImport where KennelImportId = @KennelImportId)
				BEGIN
					SET @result = 'Import failed. KennelImportId not found.'
				END
			ELSE IF EXISTS(SELECT * FROM EXT.OfficeForms_KennelImport where KennelImportId = @KennelImportId AND KennelId IS NOT NULL)
				BEGIN
					SET @result = 'Import failed. Kennel has already been imported.'
				END
			ELSE IF EXISTS(SELECT * FROM EXT.OfficeForms_KennelImport ki inner join
							HC.Kennel k on ki.KennelFacebookId = k.KennelFacebookId
							WHERE ki.KennelImportId = @KennelImportId
							AND k.KennelFacebookId IS NOT NULL
							)
				BEGIN
					SET @result = 'Import failed. A Kennel with this Facebook ID already exists'
				END
			ELSE
				BEGIN
					DECLARE @cityId uniqueidentifier,
							@regionId uniqueidentifier,
							@countryId uniqueidentifier

					SELECT 
						@cityId = CityId,
						@regionId = RegionId,
						@countryId = CountryId
					FROM EXT.OfficeForms_KennelImport where KennelImportId = @KennelImportId

					IF (@cityId is null) SET @result = 'Import failed: You must select a city.'
					IF (@regionId is null) SET @result = 'Import failed: You must select a region.'
					IF (@countryId is null) SET @result = 'Import failed: You must select a country.'

					IF (@result IS NULL) -- error checking succeeded
					BEGIN

						DECLARE @kennelId uniqueidentifier = newid()

						DECLARE @iconName nvarchar(10)
						SELECT @iconName = 'C-'+right('00' + cast((cast (rand() * 11.999 as int) * 30) as nvarchar(10)),3)
					
						INSERT INTO [HC].[Kennel]
						   (
							[id]
						   ,[KennelName]
						   ,[KennelShortName]
						   ,[KennelDescription]
						   ,[KennelLogo]
						   ,[KennelWebsiteUrl]
						   ,[DefaultEventPriceForMembers]
						   ,[DefaultEventPriceForNonMembers]
						   ,[CityId]
						   ,[ProvinceStateId]
						   ,[CountryId]
						   ,[RunCountStartDate]
						   ,[KennelFacebookId]
						   ,[KennelFacebookTokenUsername]
						   ,[KennelStatus]
						   ,[IntegrationType]
						   ,[IntegrationAutoImportEvents]
						   ,[IntegrationForceUpdatesUntil]
						   ,[KennelPinColor]
						   --,[ExtApiKey]
						   ,[removed]
						   ,[createdAt]
						   ,[updatedAt]
						   ,[deleted]
						  )
						 SELECT 
						    @kennelId
						   ,[KennelName]
						   ,[KennelShortName]
						   ,[KennelDescription]
						   ,'bundle://'+@iconName
						   ,[KennelUrl]
						   ,CAST(HashCash as decimal(10,4))
						   ,CAST(HashCash as decimal(10,4))
						   ,[CityId]
						   ,[RegionId]
						   ,[CountryId]
						   ,getdate()
						   ,[KennelFacebookId]
						   ,[KennelFacebookEmailAddress]
						   ,2
						   ,case when [KennelFacebookId] IS NOT NULL THEN 'Facebook' ELSE 'None' end
						   ,case when [KennelFacebookId] IS NOT NULL THEN 1 ELSE 0 end
						   ,dateadd(minute,30,getdate())
						   ,case 
								when KennelPinColor = 'Red' then 0
								when KennelPinColor = 'Orange' then 1
								when KennelPinColor = 'Yellow' then 2
								when KennelPinColor = 'Green' then 3
								when KennelPinColor = 'Teal' then 4
								when KennelPinColor = 'Azure' then 5
								when KennelPinColor = 'Blue' then 6
								when KennelPinColor = 'Purple' then 7
								when KennelPinColor = 'Pink' then 8
								else 0
							end
						   --,[ExtApiKey]
						   ,0
						   ,getdate()
						   ,getdate()
						   ,0
						 FROM EXT.OfficeForms_KennelImport WHERE KennelImportId = @kennelImportId

					 IF @@ROWCOUNT = 0
						 BEGIN
							SET @result = 'Kennel import failed. Kennel not created in Kennels table'
						 END
					 ELSE
						 BEGIN
	 						SET @result = 'Kennel import succeeded'
							UPDATE ki SET
								KennelId = @kennelId,
								KennelImportedOn = getdate()
							FROM EXT.OfficeForms_KennelImport ki
							WHERE ki.KennelImportId = @KennelImportId
						 END
					END
				END

		END

    -- now attempt to create a user
    IF (@result not like '%fail%')
	BEGIN
		DECLARE @firstName nvarchar(250),
				@lastName nvarchar(250),
				@email nvarchar(250)

		SELECT @firstName = FirstName,
				@lastName = LastName,
				@email = EmailAddress
			FROM EXT.OfficeForms_KennelImport 
			WHERE KennelImportId = @KennelImportId

		IF ((@firstName is null) OR (@lastName is null) OR (@email is null))
			BEGIN
				SET @result = 'Kennel created but insufficient data available to add user.'
			END
		ELSE
			BEGIN
				DECLARE @userId int,
						@userAuthToken nvarchar(1000),
						@userAuthTokenType nvarchar(100),
						@userAuthTokenUpdated datetime
						
				SELECT TOP 1 
					@userId = userId,
					@userAuthToken = u.AuthToken,
					@userAuthTokenType = u.AuthTokenType,
					@userAuthTokenUpdated = u.AuthTokenLastUpdated
				FROM dbo.Users u where u.Email = @email

				IF @userId is not null
					BEGIN
						IF (@userAuthTokenType like '%facebook%')
						BEGIN
							UPDATE k SET 
								KennelFacebookToken = coalesce(@userAuthToken,KennelFacebookToken),
								KennelFacebookTokenLastUpdated = coalesce(@userAuthTokenUpdated,KennelFacebookTokenLastUpdated)
							FROM HC.Kennel k 
							WHERE k.id = @kennelId
						END
						SET @result = 'Kennel created but user not added because user is already in database.'
					END
				ELSE
					BEGIN

						INSERT INTO [dbo].[Users]
							   ([Username]
							   ,[DisplayName]
							   ,[Email]
							   ,[Source]
							   ,[PasswordHash]
							   ,[PasswordSalt]
							   ,[LastDirectoryUpdate]
							   ,[InsertDate]
							   ,[InsertUserId]
							   ,[UpdateDate]
							   ,[UpdateUserId]
							   ,[IsActive])
						 VALUES
							   (@email 
							   ,@firstName + ' ' + @lastName 
							   ,@email 
							   ,'SITE' 
							   ,'YjOJL4ypmsWXze2Bs6yHzXu3lXKqicPeTfDzDR/zjIaIDB2MTMgQNr61xU/YjDy3f6UKZGiq+VqUevD93wlkPg' 
							   ,'_r(.4'
							   ,getdate() 
							   ,getdate() 
							   ,1 
							   ,getdate() 
							   ,1 
							   ,1)

							 IF @@ROWCOUNT = 0
								 BEGIN
									SET @result = 'Kennel created but user not inserted in the database due to unspecified error.'
								 END
							 ELSE
								 BEGIN
	 								SET @result = 'Kennel created and user added to the database.'
									SET @userId = SCOPE_IDENTITY()
									IF (@userId is not null)
									BEGIN
										-- give the user the roles needed to be a Kennel admin
										DELETE FROM dbo.UserRoles where UserId = @userId
										INSERT dbo.UserRoles (UserId,RoleId) VALUES (@userId,2)
										INSERT dbo.UserRoles (UserId,RoleId) VALUES (@userId,3)		
									END
								 END
						END
				

			END

			DECLARE @hasherId uniqueidentifier,
					@inviteCode nvarchar(250)

			SELECT 
				@hasherId = h.id,
				@inviteCode = h.ResetCode
			from HC.Hasher h where h.Email = @email

			IF ((@hasherId is not null) AND (@kennelId is not null))
			BEGIN

				UPDATE ki 
					SET ki.KennelAdminInviteCode = @inviteCode
				FROM EXT.OfficeForms_KennelImport ki
				WHERE KennelImportId = @KennelImportId

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
					,[HistoricalPackRunCount]
					,[HistoricalHaringCount]
					,[HistoricalCountIsEstimate]
					,[CurrentPackRunCount]
					,[CurrentHaringCount]
					,[DateOfLastRun]
					,[MembershipExpirationDate]
					,[MemberSince]
					,[CanEditRunAttendence]
					,[removed]
					,[updatedAt])
				VALUES
					(newid()
					,@hasherId
					,@kennelId
					,1
					,1
					,1
					,0
					,1
					,1 -- <KennelEmailAlertPreference, smallint,>
					,1 -- <MismanagementRoles, int,>
					,2047 -- <MismanagementRoleFlags, int,>
					,127 -- <HcWebPermissionFlags, int,>
					,0 -- <UserRoleFlags, int,>
					,0 -- <AppAccessFlags, int,>
					,0 --<HistoricalPackRunCount, smallint,>
					,0 -- <HistoricalHaringCount, smallint,>
					,0 --<HistoricalCountIsEstimate, smallint,>
					,0 --<CurrentPackRunCount, smallint,>
					,0 --<CurrentHaringCount, smallint,>
					,null -- <DateOfLastRun, datetimeoffset(7),>
					,null -- <MembershipExpirationDate, datetimeoffset(7),>
					,null -- <MemberSince, datetimeoffset(7),>
					,1 -- <CanEditRunAttendence, smallint,>
					,0 --<removed, smallint,>
					,getdate() -- <updatedAt, datetimeoffset(7),>
					)
			END	
	END

	SELECT @result as result
END
  
GO
/****** Object:  StoredProcedure [HC3W].[not_used_getEvents]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3W].[not_used_getEvents]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3W].[not_used_getEvents] AS' 
END
GO

ALTER PROCEDURE [HC3W].[not_used_getEvents]

 @userName nvarchar(120) = ''

AS

BEGIN

	DECLARE @userId uniqueidentifier

	SELECT @userId = HasherId from dbo.Users u where u.Username = @userName

	if (@@ROWCOUNT = 1)
	BEGIN
		IF @userName != 'admin'
		BEGIN

			SELECT e.[id]
				,[EventStartDatetime]
				,k.KennelShortName
				,FORMAT(EventStartDatetime,N'ddd, dd MMM yyyy') as [EventDate]
				,FORMAT(EventStartDatetime,N'h:mm tt') as [EventTime]
				,[IsVisible]
				,[IsCountedRun]
				,case when IsCountedRun = 1 AND IsVisible = 1 then cast(EventNumber as nvarchar(10)) else '' end as EventNumber
				,[EventName]
				,[LocationCity]
				,[Hares]
			FROM [HC].[Event] e
			INNER JOIN HC.Kennel k on e.KennelId = k.id
			INNER JOIN HC.HasherKennelMap hkm on hkm.KennelId = k.id AND hkm.UserId = @userId
			WHERE hkm.Following = 1
			ORDER BY EventStartDatetime desc
		END

		IF @userName = 'admin'
		BEGIN

			SELECT e.[id]
				,[EventStartDatetime]
				,k.KennelShortName
				,FORMAT(EventStartDatetime,N'ddd, dd MMM yyyy') as [EventDate]
				,FORMAT(EventStartDatetime,N'h:mm tt') as [EventTime]
				,[IsVisible]
				,[IsCountedRun]
				,case when IsCountedRun = 1 AND IsVisible = 1 then cast(EventNumber as nvarchar(10)) else '' end as EventNumber
				,[EventName]
				,[LocationCity]
				,[Hares]
			FROM [HC].[Event] e
			INNER JOIN HC.Kennel k on e.KennelId = k.id
			ORDER BY EventStartDatetime desc
		END
	END
	
END
  
GO
/****** Object:  StoredProcedure [HC3W].[not_used_getUsersForAdmin]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[HC3W].[not_used_getUsersForAdmin]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [HC3W].[not_used_getUsersForAdmin] AS' 
END
GO

ALTER PROCEDURE [HC3W].[not_used_getUsersForAdmin]

 @userName nvarchar(120) = ''

AS

BEGIN

	DECLARE @userId uniqueidentifier

	IF @userName = 'admin'
	BEGIN

	SELECT 

	   [id]
      ,REPLACE([SupportCode],'USC:','') as SupportCode
      ,REPLACE([ResetCode],'URC:','') as ResetCode
      ,REPLACE([QR_code],'UQR:','') as QrCode
      ,cast ([QR_secret_code] as nvarchar(50)) as QrSecretCode
      ,case when datalength(DisplayName) >= 2 THEN DisplayName ELSE CASE WHEN DATALENGTH(HashName) >= 2 THEN HashName ELSE FirstName + ' ' + LastName END END as DisplayName
      ,[HashName]
      ,[FirstName]
      ,[LastName]
      ,[Email]
      ,[Removed]
      ,[version]
      ,[createdAt]
      ,[updatedAt]
      ,[deleted]
	FROM [HC].[Hasher] h

		ORDER BY case when datalength(DisplayName) >= 2 THEN DisplayName ELSE CASE WHEN DATALENGTH(HashName) >= 2 THEN HashName ELSE FirstName + ' ' + LastName END END  asc
	END
	
END
  
GO
/****** Object:  StoredProcedure [WORDZ].[sp_ExportWordzToJson]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[WORDZ].[sp_ExportWordzToJson]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [WORDZ].[sp_ExportWordzToJson] AS' 
END
GO
ALTER PROCEDURE [WORDZ].[sp_ExportWordzToJson]

AS


select  distinct 
English as En,Dutch as Nl,coalesce(DutchFreq,9999) as R,DutchAudioFile as Af
into #temp
 from WORDZ.Wordz
--where DutchAudioFile is null
order by coalesce(DutchFreq,9999) 

select
ROW_NUMBER() OVER (ORDER BY R) AS id,
*
from #temp
FOR JSON AUTO;

drop table #temp
GO
/****** Object:  Trigger [dbo].[trgAddRoles]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trgAddRoles]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[trgAddRoles]
   ON  [dbo].[Users]
   AFTER INSERT
AS 
BEGIN

	SET NOCOUNT ON;

	-- Link web user with app user

	DECLARE @UserId int, @Email nvarchar(100)
	
	DECLARE xCrsr CURSOR FOR SELECT UserId, Email FROM inserted

	OPEN xCrsr

	FETCH NEXT FROM xCrsr INTO @UserId, @Email

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		-- assign new user to the kennel admin and user roles
		INSERT dbo.UserRoles (UserId, RoleId) VALUES (@UserId,2)
		INSERT dbo.UserRoles (UserId, RoleId) VALUES (@UserId,3)
		FETCH NEXT FROM xCrsr INTO @UserId, @Email
	END

	CLOSE xCrsr
	DEALLOCATE xCrsr

END
' 
GO
ALTER TABLE [dbo].[Users] ENABLE TRIGGER [trgAddRoles]
GO
/****** Object:  Trigger [dbo].[trgLinkToHcHasher]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[trgLinkToHcHasher]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [dbo].[trgLinkToHcHasher]
   ON  [dbo].[Users]
   AFTER INSERT, UPDATE
AS 
BEGIN

	SET NOCOUNT ON;

	-- Link web user with app user

	DECLARE @Username nvarchar(250),
			@UserId int, 
			@Email nvarchar(100),
			@AuthToken nvarchar(2000),
			@AuthTokenType nvarchar(50),
			@AuthTokenLastUpdated datetime,
			@HasherId uniqueidentifier,
			@FirstName nvarchar(100),
			@LastName nvarchar(100),
			@SingleSignOnId nvarchar(250),
			@SingleSignOnType nvarchar(50)

	DECLARE @groupId nvarchar(100), 
			@groupName nvarchar(500), 
			@groupDescription nvarchar(4000), 
			@groupCoverPhoto nvarchar(500)

	DECLARE @kennelId uniqueidentifier

	-- cycle through all users that have been updated
	-- (normally this would just be one at a time)
	DECLARE oCrsr CURSOR FOR SELECT 
		Username,
		UserId, 
		Email, 
		AuthToken, 
		AuthTokenType,
		AuthTokenLastUpdated,
		FirstName,
		LastName,
		SingleSignOnId,
		SingleSignOnType
	FROM inserted

	OPEN oCrsr

	FETCH NEXT FROM oCrsr INTO @Username, @UserId, @Email, @AuthToken, @AuthTokenType, @AuthTokenLastUpdated,@FirstName,@LastName,@SingleSignOnId,@SingleSignOnType

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF EXISTS (SELECT * FROM HC.Hasher where Email = @Email)
			BEGIN
				-- associate the Hasher portal and app accounts
				UPDATE HC.Hasher SET HcWebUserId = @UserId WHERE Email = @Email
			END
		ELSE
			BEGIN
				INSERT INTO [HC].[Hasher]
				   ([SupportCode]
				   ,[ResetCode]
				   ,[QR_code]
				   ,[QR_secret_code]
				   ,[DisplayName]
				   ,[HashName]
				   ,[FirstName]
				   ,[LastName]
				   ,[Email]
				   ,[SingleSignOnId]
				   ,[SingleSignOnType]
				   ,[FacebookId]
				   ,[FacebookAccessToken]
				   ,[FacebookAccessTokenLastUpdated]
				   ,[HcWebUserId]
				   ,[Removed]
				   ,[createdAt]
				   ,[updatedAt]
				   ,[deleted])
				 VALUES
						(
						HC.GENERATE_SIX_RANDOM_CHARACTERS(CAST( RAND() * 2147483647 as int),''USC:'',''N'')
					   ,HC.GENERATE_SIX_RANDOM_CHARACTERS(CAST( RAND() * 2147483647 as int),''URC:'',''N'')
					   ,HC.GENERATE_SIX_RANDOM_CHARACTERS(CAST( RAND() * 2147483647 as int),''UQR:'',''Y'')
					   ,newid()
					   ,coalesce(@FirstName + '' '' + @LastName,''<no name>'')
					   ,''<no Hash name>''
					   ,@FirstName
					   ,@LastName
					   ,@Email
					   ,@SingleSignOnId
					   ,@SingleSignOnType
					   ,@SingleSignOnId
					   ,@AuthToken
					   ,getdate()
					   ,@UserId
					   ,0
					   ,getdate()
					   ,getdate()
					   ,0)
			END

		-- NOTE: We need to create a user here if one does not already exist
		SELECT @HasherId = id FROM HC.Hasher where HcWebUserId = @UserId

		IF @AuthTokenType = ''Facebook''
		BEGIN
			-- for all kennels where this user is the admin, refresh the auth token
			UPDATE HC.Kennel SET KennelFacebookToken = @AuthToken, KennelFacebookTokenLastUpdated = @AuthTokenLastUpdated WHERE KennelFacebookTokenUsername = @Username
			
			-- now look through the list of Kennels to be imported from Facebook
			-- only add ones where the Kennel has not yet been added
			DECLARE iCrsr CURSOR FOR 
			with cte as (
				select ROW_NUMBER() OVER(PARTITION BY GroupId ORDER BY updatedAt desc) as RowNum,* 
				from EXT.FbAppEvent)
				SELECT 
				   [GroupId]
				  ,[GroupName]
				  ,[GroupDescription]
				  ,[GroupCoverPhoto] FROM cte 
				WHERE UserEmail = @Email 
				  AND RowNum = 1
				  AND verb = ''add''
				  AND GroupId not in (select KennelFacebookId from HC.Kennel where KennelFacebookId is not null);

			OPEN iCrsr

			FETCH NEXT FROM iCrsr INTO @GroupId, @GroupName, @GroupDescription, @GroupCoverPhoto

			WHILE(@@FETCH_STATUS = 0)
			BEGIN
				-- insert new kennels one at a time
				SET @kennelId = newid()
				DECLARE @iconName nvarchar(10)
				SELECT @iconName = ''C-''+right(''00'' + cast((cast (rand() * 11.999 as int) * 30) as nvarchar(10)),3)

				INSERT INTO [HC].[Kennel]
						   (
							[id]
						   ,[KennelName]
						   ,[KennelShortName]
						   ,[KennelDescription]
						   ,[KennelLogo]
						   ,[KennelCoverPhoto]
						   ,[KennelWebsiteUrl]
						   ,[DefaultEventPriceForMembers]
						   ,[DefaultEventPriceForNonMembers]
						   ,[CityId]
						   ,[ProvinceStateId]
						   ,[CountryId]
						   ,[RunCountStartDate]
						   ,[KennelFacebookId]
						   ,[KennelFacebookTokenUsername]
						   ,[KennelFacebookToken]
						   ,[KennelFacebookTokenLastUpdated]
						   ,[KennelStatus]
						   ,[IntegrationType]
						   ,[IntegrationAutoImportEvents]
						   ,[IntegrationForceUpdatesUntil]
						   ,[KennelPinColor]
						   --,[ExtApiKey]
						   ,[removed]
						   ,[createdAt]
						   ,[updatedAt]
						   ,[deleted]
						  )
						 SELECT 
						    @kennelId
						   ,@groupName
						   ,SUBSTRING(@groupName,1,3) + '' H3''
						   ,@groupDescription
						   ,''bundle://''+@iconName
						   ,@GroupCoverPhoto
						   ,'''' -- KennelUrl
						   ,CAST(0 as decimal(10,4))
						   ,CAST(0 as decimal(10,4))
						   ,''878FDFE9-E2BB-4D46-BB38-82DE60279A4A'' -- <unassigned> city
						   ,''269C4F82-24C7-411F-967F-3F5E61BBA599'' -- <unassigned> region
						   ,''FF2B0557-49EA-4EC3-9607-51B07606BE17'' -- <unassigned> country
						   ,getdate()
						   ,@groupId
						   ,@Email
						   ,@AuthToken
						   ,@AuthTokenLastUpdated
						   ,2
						   ,''Facebook'' -- integration type
						   ,1 -- autoImportEvents
						   ,dateadd(minute,30,getdate()) -- force Facebook updates for next 30 minutes
						   ,cast (rand() * 8.9999 as int) -- KennelPinColor = red
						   --,[ExtApiKey]
						   ,0
						   ,getdate()
						   ,getdate()
						   ,0

				IF (@HasherId is not null)
				BEGIN
					-- now set the user to follow the new kennel
					-- so it shows up on the users portal page
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
						,[HistoricalPackRunCount]
						,[HistoricalHaringCount]
						,[HistoricalCountIsEstimate]
						,[CurrentPackRunCount]
						,[CurrentHaringCount]
						,[DateOfLastRun]
						,[MembershipExpirationDate]
						,[MemberSince]
						,[CanEditRunAttendence]
						,[removed]
						,[updatedAt])
					VALUES
						(newid()
						,@hasherId
						,@kennelId
						,1
						,1
						,1
						,0
						,1
						,1 -- <KennelEmailAlertPreference, smallint,>
						,1 -- <MismanagementRoles, int,>
						,2047 -- <MismanagementRoleFlags, int,>
						,127 -- <HcWebPermissionFlags, int,>
						,0 -- <UserRoleFlags, int,>
						,0 -- <AppAccessFlags, int,>
						,0 --<HistoricalPackRunCount, smallint,>
						,0 -- <HistoricalHaringCount, smallint,>
						,0 --<HistoricalCountIsEstimate, smallint,>
						,0 --<CurrentPackRunCount, smallint,>
						,0 --<CurrentHaringCount, smallint,>
						,null -- <DateOfLastRun, datetimeoffset(7),>
						,null -- <MembershipExpirationDate, datetimeoffset(7),>
						,null -- <MemberSince, datetimeoffset(7),>
						,1 -- <CanEditRunAttendence, smallint,>
						,0 --<removed, smallint,>
						,getdate() -- <updatedAt, datetimeoffset(7),>
						)
				END

				FETCH NEXT FROM iCrsr INTO @GroupId, @GroupName, @GroupDescription, @GroupCoverPhoto
			END

			CLOSE iCrsr
			DEALLOCATE iCrsr

		END

		FETCH NEXT FROM oCrsr INTO @Username, @UserId, @Email, @AuthToken, @AuthTokenType, @AuthTokenLastUpdated,@FirstName,@LastName,@SingleSignOnId,@SingleSignOnType

	END

	CLOSE oCrsr
	DEALLOCATE oCrsr

END
' 
GO
ALTER TABLE [dbo].[Users] ENABLE TRIGGER [trgLinkToHcHasher]
GO
/****** Object:  Trigger [Hashers].[TR_HasherEventMap_InsertUpdateDelete]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[Hashers].[TR_HasherEventMap_InsertUpdateDelete]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [Hashers].[TR_HasherEventMap_InsertUpdateDelete] ON [Hashers].[HasherEventMap] AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON; IF TRIGGER_NESTLEVEL() > 3 RETURN; UPDATE [Hashers].[HasherEventMap] SET [updatedAt] = CONVERT (DATETIMEOFFSET(7), SYSUTCDATETIME()) FROM INSERTED WHERE INSERTED.id = [Hashers].[HasherEventMap].[id] END' 
GO
ALTER TABLE [Hashers].[HasherEventMap] ENABLE TRIGGER [TR_HasherEventMap_InsertUpdateDelete]
GO
/****** Object:  Trigger [Hashers].[TR_HasherFriendMap_InsertUpdateDelete]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[Hashers].[TR_HasherFriendMap_InsertUpdateDelete]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [Hashers].[TR_HasherFriendMap_InsertUpdateDelete] ON [Hashers].[HasherFriendMap] AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON; IF TRIGGER_NESTLEVEL() > 3 RETURN; UPDATE [Hashers].[HasherFriendMap] SET [updatedAt] = CONVERT (DATETIMEOFFSET(7), SYSUTCDATETIME()) FROM INSERTED WHERE INSERTED.id = [Hashers].[HasherFriendMap].[id] END' 
GO
ALTER TABLE [Hashers].[HasherFriendMap] ENABLE TRIGGER [TR_HasherFriendMap_InsertUpdateDelete]
GO
/****** Object:  Trigger [HC].[TR_BusinessUnits_InsertUpdateDelete]    Script Date: 7/2/2021 4:18:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[TR_BusinessUnits_InsertUpdateDelete]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[TR_BusinessUnits_InsertUpdateDelete] ON [HC].[BusinessUnits] AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON; IF TRIGGER_NESTLEVEL() > 3 RETURN; UPDATE [HC].[BusinessUnits] SET [updatedAt] = CONVERT (DATETIMEOFFSET(7), SYSUTCDATETIME()) FROM INSERTED WHERE INSERTED.id = [HC].[BusinessUnits].[id] END' 
GO
ALTER TABLE [HC].[BusinessUnits] ENABLE TRIGGER [TR_BusinessUnits_InsertUpdateDelete]
GO
/****** Object:  Trigger [HC].[trgUpdateGeolocation]    Script Date: 7/2/2021 4:18:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgUpdateGeolocation]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[trgUpdateGeolocation]
   ON  [HC].[City]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;

	IF UPDATE(Latitude) OR UPDATE(Longitude)
	BEGIN

		declare @cityId uniqueidentifier
		declare @latitude decimal(12,9)
		declare @longitude decimal (13,9)

		declare xCrsr CURSOR FOR
			select id,Latitude,Longitude from INSERTED where ((Latitude is not null AND Longitude is not null))

		OPEN xCrsr

		FETCH NEXT FROM xCrsr into @cityId,@latitude,@longitude

		WHILE @@Fetch_status = 0
		BEGIN
			IF (@latitude is not null and @longitude is not null)
				BEGIN
					UPDATE HC.City SET CityGeolocation = geography::Point(@latitude,@longitude,4326) WHERE id = @cityId
				END
			FETCH NEXT FROM xCrsr into @cityId,@latitude,@longitude
		END

		CLOSE xCrsr
		DEALLOCATE xCrsr
	END

END
' 
GO
ALTER TABLE [HC].[City] ENABLE TRIGGER [trgUpdateGeolocation]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForCity]    Script Date: 7/2/2021 4:18:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgUpdateModifiedOnDateForCity]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForCity]
   ON  [HC].[City]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (NOT UPDATE(updatedAt))
	BEGIN
		UPDATE HC.City Set updatedAt = GETDATE() FROM HC.City
			WHERE id in (SELECT id from INSERTED)
	END

END
' 
GO
ALTER TABLE [HC].[City] ENABLE TRIGGER [trgUpdateModifiedOnDateForCity]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForCountry]    Script Date: 7/2/2021 4:18:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgUpdateModifiedOnDateForCountry]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForCountry]
   ON  [HC].[Country]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (NOT UPDATE(updatedAt))
	BEGIN
		UPDATE HC.Country Set updatedAt = GETDATE() FROM HC.Country
			WHERE id in (SELECT id from INSERTED)
	END

END
' 
GO
ALTER TABLE [HC].[Country] ENABLE TRIGGER [trgUpdateModifiedOnDateForCountry]
GO
/****** Object:  Trigger [HC].[trgRecalculateRunCounts]    Script Date: 7/2/2021 4:18:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgRecalculateRunCounts]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[trgRecalculateRunCounts]
   ON  [HC].[Event]
   AFTER INSERT,UPDATE,DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (UPDATE(IsCountedRun) OR UPDATE(AbsoluteEventNumber)) --AND NOT UPDATE(updatedAt)
	BEGIN
		DECLARE @eid uniqueidentifier

		SELECT top 1 @eid = id from inserted order by EventStartDatetime asc

		EXEC [HC].[nonApi_updateRunNumbers] @eventId = @eid


	END

END
' 
GO
ALTER TABLE [HC].[Event] ENABLE TRIGGER [trgRecalculateRunCounts]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForEvent]    Script Date: 7/2/2021 4:18:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgUpdateModifiedOnDateForEvent]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForEvent]
   ON  [HC].[Event]
   AFTER INSERT, UPDATE
AS 
BEGIN

	SET NOCOUNT ON;

	IF (NOT UPDATE(updatedAt))
	BEGIN
		UPDATE HC.Event Set updatedAt = GETDATE() FROM HC.Event
			WHERE id in (SELECT id from INSERTED)
	END

END
' 
GO
ALTER TABLE [HC].[Event] ENABLE TRIGGER [trgUpdateModifiedOnDateForEvent]
GO
/****** Object:  Trigger [HC].[trgCalculateHasherGeolocation]    Script Date: 7/2/2021 4:18:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgCalculateHasherGeolocation]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[trgCalculateHasherGeolocation]
   ON  [HC].[Hasher]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF (UPDATE(HomeLatitude) OR UPDATE(HomeLongitude))
	BEGIN
		UPDATE HC.Hasher Set HomeGeolocation = geography::Point(HomeLatitude, HomeLongitude, 4326) FROM HC.Hasher 
			WHERE id in (SELECT id from INSERTED)
	END

END
' 
GO
ALTER TABLE [HC].[Hasher] ENABLE TRIGGER [trgCalculateHasherGeolocation]
GO
/****** Object:  Trigger [HC].[trgGenerateQrCode]    Script Date: 7/2/2021 4:18:15 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgGenerateQrCode]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[trgGenerateQrCode]
   ON  [HC].[Hasher]
   AFTER INSERT, UPDATE
AS 
BEGIN

	SET NOCOUNT ON;

	DECLARE @id uniqueidentifier
	DECLARE @Loop nvarchar(5)
	DECLARE @QR nvarchar(50)
	DECLARE @EmergencyStop int


	DECLARE @InsertedQr nvarchar(50)
	DECLARE @ResetCode nvarchar(50)
	DECLARE @SupportCode nvarchar(50)

	IF TRIGGER_NESTLEVEL(OBJECT_ID(''HC.trgGenerateQrCode'')) > 1
	BEGIN
		PRINT ''mytrigger exiting because TRIGGER_NESTLEVEL > 1 '';
		RETURN;
	END;

	IF (UPDATE(QR_Code) OR UPDATE(ResetCode) OR UPDATE(SupportCode))
	BEGIN

	DECLARE xCrsr CURSOR  
		FOR SELECT id,QR_code, ResetCode, SupportCode FROM INSERTED 
	OPEN xCrsr 
	FETCH NEXT FROM xCrsr INTO @id, @InsertedQr, @ResetCode, @SupportCode
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
			
		-- First check the QR_Code
		SET @Loop = ''Yes''
		SET @EmergencyStop = 0

		IF ((SELECT count(*) from HC.Hasher WHERE QR_code = @InsertedQr and id <> @id) > 0) OR (@InsertedQr not like ''UQR:%'')
		BEGIN
			-- attempt to insert a duplicate QR was detected or the QR being inserted is invalid
			-- in these cases, create a new QR and insert that instead
			WHILE (@Loop = ''Yes'')
			BEGIN
				SET @EmergencyStop = @EmergencyStop + 1
				IF @EmergencyStop > 10 SET @Loop = ''No''
				SET @QR = ''UQR:''+HC.NUMBER_TO_STR_BASE (36,(RAND() * (2147483647 - 60466177)) + 60466176)
				-- if the QR code is unique, go ahead and insert it
				IF (SELECT count(*) FROM HC.Hasher WHERE QR_code = @QR) = 0
				BEGIN
					SET @Loop = ''No''
					UPDATE HC.Hasher set QR_code = @QR WHERE id = @id
				END
			END
		END

		-- Now check the ResetCode
		SET @Loop = ''Yes''
		SET @EmergencyStop = 0

		IF ((SELECT count(*) from HC.Hasher WHERE ResetCode = @ResetCode and id <> @id) > 0) OR (@ResetCode not like ''URC:%'')
		BEGIN
			-- attempt to insert a duplicate QR was detected or the QR being inserted is invalid
			-- in these cases, create a new QR and insert that instead
			WHILE (@Loop = ''Yes'')
			BEGIN
				SET @EmergencyStop = @EmergencyStop + 1
				IF @EmergencyStop > 10 SET @Loop = ''No''
				SET @QR = ''URC:''+SUBSTRING(TRIM(HC.NUMBER_TO_STR_BASE (25,(RAND() * (2147483647 - 91466177)) + 91466177)),0,7)
				-- if the QR code is unique, go ahead and insert it
				IF (SELECT count(*) FROM HC.Hasher WHERE ResetCode = @QR) = 0
				BEGIN
					SET @Loop = ''No''
					UPDATE HC.Hasher set ResetCode = @QR WHERE id = @id
				END
			END
		END

		-- Now check the SupportCode
		SET @Loop = ''Yes''
		SET @EmergencyStop = 0

		IF ((SELECT count(*) from HC.Hasher WHERE SupportCode = @SupportCode and id <> @id) > 0) OR (@SupportCode not like ''USC:%'')
		BEGIN
			-- attempt to insert a duplicate QR was detected or the QR being inserted is invalid
			-- in these cases, create a new QR and insert that instead
			WHILE (@Loop = ''Yes'')
			BEGIN
				SET @EmergencyStop = @EmergencyStop + 1
				IF @EmergencyStop > 10 SET @Loop = ''No''
				SET @QR = ''USC:''+SUBSTRING(TRIM(HC.NUMBER_TO_STR_BASE (25,(RAND() * (2147483647 - 91466177)) + 91466177)),0,7)
				-- if the QR code is unique, go ahead and insert it
				IF (SELECT count(*) FROM HC.Hasher WHERE SupportCode = @QR) = 0
				BEGIN
					SET @Loop = ''No''
					UPDATE HC.Hasher set SupportCode = @QR WHERE id = @id
				END
			END
		END

		FETCH NEXT FROM xCrsr INTO @id, @InsertedQr, @ResetCode, @SupportCode
	END

	CLOSE xCrsr
	DEALLOCATE xCrsr

	END

	

	--DECLARE xCrsr CURSOR  
	--FOR SELECT id,ResetCode FROM INSERTED 
	--OPEN xCrsr 
	--FETCH NEXT FROM xCrsr INTO @id, @ResetCode
	
	--WHILE @@FETCH_STATUS = 0
	--BEGIN
			
	--	SET @Loop = ''Yes''
	--	SET @EmergencyStop = 0

	--	IF ((SELECT count(*) from HC.Hasher WHERE ResetCode = @ResetCode and id <> @id) > 0) OR (@ResetCode not like ''RC:%'')
	--	BEGIN
	--		-- attempt to insert a duplicate QR was detected or the QR being inserted is invalid
	--		-- in these cases, create a new QR and insert that instead
	--		WHILE (@Loop = ''Yes'')
	--		BEGIN
	--			SET @EmergencyStop = @EmergencyStop + 1
	--			IF @EmergencyStop > 10 SET @Loop = ''No''
	--			SET @QR = ''RC:''+ SUBSTRING(TRIM(HC.NUMBER_TO_STR_BASE (25,(RAND() * (2147483647 - 91466177)) + 91466177)),0,7)
	--			-- if the QR code is unique, go ahead and insert it
	--			IF (SELECT count(*) FROM HC.Hasher WHERE ResetCode = @QR) = 0
	--			BEGIN
	--				SET @Loop = ''No''
	--				UPDATE HC.Hasher set ResetCode = @QR WHERE id = @id
	--			END
	--		END
	--	END

	--	FETCH NEXT FROM xCrsr INTO @id, @ResetCode
	--END

	--CLOSE xCrsr
	--DEALLOCATE xCrsr

END
' 
GO
ALTER TABLE [HC].[Hasher] ENABLE TRIGGER [trgGenerateQrCode]
GO
/****** Object:  Trigger [HC].[trgInsertHkmRecordForHomeHash]    Script Date: 7/2/2021 4:18:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgInsertHkmRecordForHomeHash]'))
EXEC dbo.sp_executesql @statement = N'
CREATE TRIGGER [HC].[trgInsertHkmRecordForHomeHash]
   ON  [HC].[Hasher]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF (UPDATE(HomeKennelId))
	BEGIN
		DECLARE @homeKennelId uniqueidentifier,
				@userId uniqueidentifier
		

		SELECT @homeKennelId = homeKennelId,@userId = id from INSERTED

		IF (@homeKennelId IS NOT NULL)
		BEGIN
		SET NOCOUNT ON
			IF (select count(*) from HC.HasherKennelMap hkm where hkm.UserId = @userId AND hkm.KennelId = @homeKennelId) = 0 
			BEGIN
			INSERT INTO [HC].[HasherKennelMap]
			   ([UserId]
			   ,[KennelId]
			   ,[Following]
			   ,[IsKennelFollowing]
			   ,[IsHomeKennel])
			SELECT 
				
				@userId,  -- userId
				@homeKennelId,  -- kennelId
				1, -- following
				1, -- isKennelFollowing
				1  -- isHomeKennel
			END

		--	select id into #temp
		--	from HC.Hasher h
		--	where h.HomeKennelId = @homeKennelId
		--	AND
		--	(select count(*) from HC.HasherKennelMap hkm where hkm.UserId = h.id AND hkm.KennelId = h.HomeKennelId) = 0 

		--	INSERT INTO [HC].[HasherKennelMap]
  --         ([id]
  --         ,[UserId]
  --         ,[KennelId]
  --         ,[Following]
  --         ,[IsKennelFollowing]
  --         ,[IsHomeKennel])
		--SELECT 
		--	newid(), -- id
		--	t.id,  -- userId
		--	@homeKennelId,  -- kennelId
		--	1, -- following
		--	1, -- isKennelFollowing
		--	1  -- isHomeKennel
		--from #temp t

		--DROP TABLE #temp


		END
	END
END
' 
GO
ALTER TABLE [HC].[Hasher] DISABLE TRIGGER [trgInsertHkmRecordForHomeHash]
GO
/****** Object:  Trigger [HC].[trgLinkToDboUsers]    Script Date: 7/2/2021 4:18:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgLinkToDboUsers]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[trgLinkToDboUsers]
   ON  [HC].[Hasher]
   AFTER INSERT, UPDATE
AS 
BEGIN

	IF UPDATE(Email)
	BEGIN

		SET NOCOUNT ON;

		-- Link web user with app user

		DECLARE @Email nvarchar(100)
	
		DECLARE xCrsr CURSOR FOR SELECT Email FROM inserted

		OPEN xCrsr

		FETCH NEXT FROM xCrsr INTO @Email

		WHILE(@@FETCH_STATUS = 0)
		BEGIN
			UPDATE HC.Hasher SET HcWebUserId = (SELECT UserId FROM dbo.Users WHERE Email = @Email) WHERE Email = @Email
			FETCH NEXT FROM xCrsr INTO @Email
		END

		CLOSE xCrsr
		DEALLOCATE xCrsr
	END

END
' 
GO
ALTER TABLE [HC].[Hasher] ENABLE TRIGGER [trgLinkToDboUsers]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForNames]    Script Date: 7/2/2021 4:18:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgUpdateModifiedOnDateForNames]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForNames]
   ON  [HC].[Hasher]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    IF (UPDATE(FirstName) OR UPDATE(LastName) OR UPDATE(DisplayName) OR UPDATE(NameDisplayPreference) OR UPDATE(HashName) OR UPDATE(Removed) OR UPDATE(Photo))
	BEGIN
		UPDATE HC.Hasher Set updatedAt = GETDATE() FROM HC.Hasher 
			WHERE id in (SELECT id from INSERTED)
	END

END
' 
GO
ALTER TABLE [HC].[Hasher] ENABLE TRIGGER [trgUpdateModifiedOnDateForNames]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForHasherEventMap]    Script Date: 7/2/2021 4:18:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgUpdateModifiedOnDateForHasherEventMap]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForHasherEventMap]
   ON  [HC].[HasherEventMap]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (NOT UPDATE(updatedAt))
	BEGIN
		UPDATE HC.HasherEventMap Set updatedAt = GETDATE() FROM HC.HasherEventMap 
			WHERE id in (SELECT id from INSERTED)
	END

END
' 
GO
ALTER TABLE [HC].[HasherEventMap] ENABLE TRIGGER [trgUpdateModifiedOnDateForHasherEventMap]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForHasherKennelMap]    Script Date: 7/2/2021 4:18:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgUpdateModifiedOnDateForHasherKennelMap]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForHasherKennelMap]
   ON  [HC].[HasherKennelMap]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (NOT UPDATE(updatedAt))
	BEGIN
		UPDATE HC.HasherKennelMap Set updatedAt = GETDATE() FROM HC.HasherKennelMap 
			WHERE id in (SELECT id from INSERTED)
	END

END
' 
GO
ALTER TABLE [HC].[HasherKennelMap] ENABLE TRIGGER [trgUpdateModifiedOnDateForHasherKennelMap]
GO
/****** Object:  Trigger [HC].[GenerateExtApiKey]    Script Date: 7/2/2021 4:18:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[GenerateExtApiKey]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[GenerateExtApiKey]
ON [HC].[Kennel] AFTER INSERT
AS
BEGIN

DECLARE @id uniqueidentifier

DECLARE xCrsr CURSOR FOR
SELECT ID FROM INSERTED

OPEN xCrsr

FETCH NEXT from xCrsr INTO @id
  
WHILE @@FETCH_STATUS = 0
	BEGIN

	DECLARE	@BinaryData varbinary(max) = crypt_gen_random (150) 
	DECLARE @randText nvarchar(1000)
	SELECT @randText = LEFT(REPLACE(REPLACE(cast('''' as xml).value(''xs:base64Binary(sql:variable("@BinaryData"))'', ''varchar(max)''),''+'',''''),''/'',''''),75)
	  UPDATE   HC.Kennel
	  SET      ExtApiKey = @randText
		WHERE id = @id

		FETCH NEXT from xCrsr INTO @id
	END

CLOSE xCrsr
DEALLOCATE xCrsr

END
' 
GO
ALTER TABLE [HC].[Kennel] ENABLE TRIGGER [GenerateExtApiKey]
GO
/****** Object:  Trigger [HC].[trgUpdateKennelGeolocation]    Script Date: 7/2/2021 4:18:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgUpdateKennelGeolocation]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[trgUpdateKennelGeolocation]
   ON  [HC].[Kennel]
   AFTER INSERT,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF UPDATE(CityId) OR UPDATE(Latitude) OR UPDATE(Longitude)
	BEGIN

		declare @kennelId uniqueidentifier,
				@cityId uniqueidentifier,
				@regionId uniqueidentifier,
				@countryId uniqueidentifier,
				@oldCityId uniqueidentifier,
				@oldRegionId uniqueidentifier,
				@oldCountryId uniqueidentifier,
				@latitude decimal(12,9),
				@longitude decimal (13,9)

		declare xCrsr CURSOR FOR
			select id,CityId,ProvinceStateId,CountryId,Latitude,Longitude from INSERTED where ((CityId is not null) OR (Latitude is not null AND Longitude is not null))

		OPEN xCrsr

		FETCH NEXT FROM xCrsr into @kennelId,@cityId,@regionId,@countryId,@latitude,@longitude

		WHILE @@Fetch_status = 0
		BEGIN
			IF (@latitude is not null and @longitude is not null)
				BEGIN
					UPDATE HC.Kennel SET KennelGeolocation = geography::Point(@latitude,@longitude,4326) WHERE id = @kennelId
				END
			ELSE
				IF (@cityId is not null)
					BEGIN
						UPDATE HC.Kennel SET KennelGeolocation = city.CityGeolocation FROM HC.Kennel k,
						HC.City city where city.id = @cityId and k.id = @kennelId
					END
				ELSE
					UPDATE HC.Kennel SET KennelGeolocation = null WHERE id = @kennelId

			-- we want to force city,region and country to replicate after any changes to Kennels
			-- to ensure that the records are replicated to mobile devices
			SELECT @oldCityId = CityId, @oldRegionId = ProvinceStateId, @oldCountryId = CountryId FROM DELETED WHERE id = @kennelId
			
			IF (@oldCityId IS NULL OR @cityId != @oldCityId) UPDATE HC.City SET updatedAt = getdate() where id = @cityId
			IF (@oldRegionId IS NULL OR @regionId != @oldRegionId) UPDATE HC.Region SET updatedAt = getdate() where id = @regionId
			IF (@oldCountryId IS NULL OR @countryId != @oldCountryId) UPDATE HC.Country SET updatedAt = getdate() where id = @countryId

			FETCH NEXT FROM xCrsr into @kennelId,@cityId,@regionId,@countryId,@latitude,@longitude
		END

		CLOSE xCrsr
		DEALLOCATE xCrsr
	END

END
' 
GO
ALTER TABLE [HC].[Kennel] ENABLE TRIGGER [trgUpdateKennelGeolocation]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForKennels]    Script Date: 7/2/2021 4:18:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgUpdateModifiedOnDateForKennels]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForKennels]
   ON  [HC].[Kennel]
   AFTER INSERT, UPDATE
AS 
BEGIN

	SET NOCOUNT ON;

	IF (NOT UPDATE(updatedAt))
	BEGIN
		UPDATE HC.Kennel Set updatedAt = GETDATE() FROM HC.Kennel 
			WHERE id in (SELECT id from INSERTED)
	END

END
' 
GO
ALTER TABLE [HC].[Kennel] ENABLE TRIGGER [trgUpdateModifiedOnDateForKennels]
GO
/****** Object:  Trigger [HC].[trgLocateLogin]    Script Date: 7/2/2021 4:18:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgLocateLogin]'))
EXEC dbo.sp_executesql @statement = N'
CREATE TRIGGER [HC].[trgLocateLogin]
   ON  [HC].[LaunchAndLogin]
   AFTER INSERT,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF UPDATE(Latitude) OR UPDATE(Longitude)
	BEGIN

		declare @cityId uniqueidentifier
		declare @cityFullName nvarchar(250)
		declare @id uniqueidentifier
		declare @latitude decimal(12,9)
		declare @longitude decimal (13,9)
		DECLARE @origin geography

		declare xCrsr CURSOR FOR
			select id,Latitude,Longitude from INSERTED where ((Latitude is not null AND Longitude is not null))

		OPEN xCrsr

		FETCH NEXT FROM xCrsr into @id,@latitude,@longitude

		WHILE @@Fetch_status = 0
		BEGIN
			SET @origin = geography::Point(@latitude, @longitude, 4326);


		select top 1 @cityId = id, @cityFullName = c.CityFullName from HC.City c
			ORDER BY @origin.STDistance(c.CityGeolocation)
		
			UPDATE HC.LaunchAndLogin SET CityId = @cityId where id = @id

			FETCH NEXT FROM xCrsr into @id,@latitude,@longitude
		END

		CLOSE xCrsr
		DEALLOCATE xCrsr
	END

END
' 
GO
ALTER TABLE [HC].[LaunchAndLogin] ENABLE TRIGGER [trgLocateLogin]
GO
/****** Object:  Trigger [HC].[TR_Meetings_InsertUpdateDelete]    Script Date: 7/2/2021 4:18:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[TR_Meetings_InsertUpdateDelete]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[TR_Meetings_InsertUpdateDelete] ON [HC].[Meetings] AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON; IF TRIGGER_NESTLEVEL() > 3 RETURN; UPDATE [HC].[Meetings] SET [updatedAt] = CONVERT (DATETIMEOFFSET(7), SYSUTCDATETIME()) FROM INSERTED WHERE INSERTED.id = [HC].[Meetings].[id] END' 
GO
ALTER TABLE [HC].[Meetings] ENABLE TRIGGER [TR_Meetings_InsertUpdateDelete]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForRegion]    Script Date: 7/2/2021 4:18:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC].[trgUpdateModifiedOnDateForRegion]'))
EXEC dbo.sp_executesql @statement = N'CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForRegion]
   ON  [HC].[Region]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (NOT UPDATE(updatedAt))
	BEGIN
		UPDATE HC.Region Set updatedAt = GETDATE() FROM HC.Region
			WHERE id in (SELECT id from INSERTED)
	END

END
' 
GO
ALTER TABLE [HC].[Region] ENABLE TRIGGER [trgUpdateModifiedOnDateForRegion]
GO
/****** Object:  Trigger [HC3W].[tgDeleteAdEmailTemplateList]    Script Date: 7/2/2021 4:18:17 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC3W].[tgDeleteAdEmailTemplateList]'))
EXEC dbo.sp_executesql @statement = N'

CREATE TRIGGER [HC3W].[tgDeleteAdEmailTemplateList] ON [HC3W].[vwAdEmailTemplateList]
INSTEAD OF DELETE AS
BEGIN

SET NOCOUNT ON

		 DECLARE @emailTemplateId uniqueidentifier

		 DECLARE xCrsr CURSOR FOR
		 SELECT id FROM deleted

		 OPEN xCrsr

		 FETCH NEXT FROM xCrsr INTO @emailTemplateId

		 WHILE @@FETCH_STATUS = 0
		 BEGIN
			DELETE FROM HC.EmailTemplate where id = @emailTemplateId
			FETCH NEXT FROM xCrsr INTO @emailTemplateId
		 END

		 CLOSE xCrsr
		 DEALLOCATE xCrsr
END;
' 
GO
/****** Object:  Trigger [HC3W].[tgInsertVwAdEmailTemplateList]    Script Date: 7/2/2021 4:18:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC3W].[tgInsertVwAdEmailTemplateList]'))
EXEC dbo.sp_executesql @statement = N'

CREATE TRIGGER [HC3W].[tgInsertVwAdEmailTemplateList] ON [HC3W].[vwAdEmailTemplateList]
INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;


	IF ((SELECT COUNT(*) 
	FROM 
	inserted i 
	INNER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = i.KennelId
	INNER JOIN HC.Hasher h ON hkm.UserId = h.id AND h.HcWebUserId = i.HcWebUserId
	WHERE ((hkm.HcWebPermissionFlags & 0x0005) = 0x0005) OR (h.HcWebUserId < 10)) = 0)
	BEGIN
		DECLARE @errorId uniqueidentifier
		SET @errorId = newid()

		INSERT HC.ErrorLog (
			id, 
			HcVersion, 
			ErrorName,
			ErrorDescription,
			ProcName,
			userId) 
		VALUES (
			@errorId,
			''Attempt to insert email template into unauthorized kennel'',
			''A user attempted to insert an email template into a kennel they were not authorized to access'',
			'''',
			'''',
			''00000000-0000-0000-0000-000000000000'')

		DECLARE @error nvarchar(200)
		DECLARE @i int
		SELECT @i = i.HcWebUserId from inserted i

		SET @error = ''You are not authorized to insert an email template for this Kennel (WebUserId = '' + CAST(coalesce(@i,-1) as NVARCHAR(50)) + '')''
		
		RAISERROR (@error, 16, 1);
	END
	ELSE
		BEGIN

			INSERT [HC].[EmailTemplate]
			  (
				[KennelId]
				,[EventId]
				,[Description]
				,[Subject]
				,[Template]
				,[HoursBeforeRun]
				,[DaysBeforeRun]
				,[SendToAll]
				,[SendToMembers]
				,[SendToMismanagement]
				,[SendWhenHareAssigned]
			   )
		SELECT
				KennelId
				,[EventId]
				,[Description]
				,[Subject]
				,[Template]
				,[HoursBeforeRun]
				,[DaysBeforeRun]
				,[SendToAll]
				,[SendToMembers]
				,[SendToMismanagement]
				,[SendWhenHareAssigned]
		FROM
			inserted
	END

END
' 
GO
/****** Object:  Trigger [HC3W].[tgUpdateAdEvent]    Script Date: 7/2/2021 4:18:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC3W].[tgUpdateAdEvent]'))
EXEC dbo.sp_executesql @statement = N'
CREATE TRIGGER [HC3W].[tgUpdateAdEvent] ON [HC3W].[vwAdEvent]
INSTEAD OF UPDATE AS
BEGIN

SET NOCOUNT ON

UPDATE [HC].[Event]
   SET [EventStartDatetime] = i.EventStartDatetime, 
      [EventEndDatetime] = i.EventEndDatetime, 
      [KennelId] = i.KennelId, 
      [IsVisible] = i.IsVisible,
      [IsCountedRun] = i.IsCountedRun,
      [IsPromotedEvent] = i.IsPromotedEvent,
      [EventGeographicScope] = i.EventGeographicScope,
      -- [ThemeRunType] = i.ThemeRunType,  DEPRECATED
	  [Tags1] = i.Tags1,
	  [Tags2] = i.Tags2,
	  [Tags3] = i.Tags3,
      [AbsoluteEventNumber] = i.AbsoluteEventNumber,
      [EventNumber] = i.EventNumber,
      [EventNumberIncrement] = i.EventNumberIncrement,
      [DoTrackHashCash] = i.DoTrackHashCash,
      [EventPriceForMembers] = i.EventPriceForMembers, 
      [EventPriceForNonMembers] = i.EventPriceForNonMembers, 
      [EventPriceForExtras] = i.EventPriceForExtras,
      [ExtrasDescription] = i.ExtrasDescription, 
      [EventCurrencyType] = i.EventCurrencyType,
      [BankScheme] = i.BankScheme,
      [BankAccountNumber] = i.BankAccountNumber,
      [BankBic] = i.BankBic,
      [BankBeneficiary] = i.BankBeneficiary,
	  [EventPaymentScheme] = i.EventPaymentScheme,
      [EventPaymentUrl] = i.EventPaymentUrl, 
      [EventPaymentUrlExpires] = i.EventPaymentUrlExpires, 
      [UnconfirmedBankXferCount] = i.UnconfirmedBankXferCount, 
      [UserEventCounterIncrement] = i.UserEventCounterIncrement,
      [EventName] = i.EventName, 
      [EventDescription] = i.EventDescription,
      [EventImage] = i.EventImage, 
      [EventImageOffsetX] = i.EventImageOffsetX,
      [EventImageOffsetY] = i.EventImageOffsetY,
      [LocationOneLineDesc] = i.LocationOneLineDesc, 
      [LocationCity] = i.LocationCity, 
      [LocationStreet] = i.LocationStreet, 
	  [LocationRegion] = i.LocationRegion,
	  [LocationSubRegion] = i.LocationSubRegion,
      [LocationPostCode] = i.LocationPostCode, 
      [LocationCountry] = i.LocationCountry, 
      [Latitude] = i.Latitude, 
      [Longitude] = i.Longitude, 
     -- [EventGeolocation] = i.EventGeolocation, 
      [MinimumParticipantsRequired] = i.MinimumParticipantsRequired,
      [MaximumParticipantsAllowed] = i.MaximumParticipantsAllowed,
      [Organizer_HasherId] = i.Organizer_HasherId, 
      [CanEditRunAttendence] = i.CanEditRunAttendence,
      [Hares] = i.Hares, 
      [UseFbRunDetails] = i.UseFbRunDetails,
      [UseFbLocation] = i.UseFbLocation,
      [UseFbLatLon] = i.UseFbLatLon,
      [UpdateDataFromFacebook] = i.UpdateDataFromFacebook,
      --[EventFacebookId] = i.EventFacebookId, 
      --[FacebookRecordLastUpdated] = i.FacebookRecordLastUpdated, 
      --[FbEventName] = i.FbEventName, 
      --[FbEventDescription] = i.FbEventDescription,
      --[FbEventStartDatetime] = i.FbEventStartDatetime, 
      --[FbEventImage] = i.FbEventImage, 
      --[FbEventImageOffsetX] = i.FbEventImageOffsetX,
      --[FbEventImageOffsetY] = i.FbEventImageOffsetY,
      --[FbLocationOneLineDesc] = i.FbLocationOneLineDesc, 
      --[FbLocationCity] = i.FbLocationCity, 
      --[FbLocationStreet] = i.FbLocationStreet, 
      --[FbLocationPostCode] = i.FbLocationPostCode, 
      --[FbLocationCountry] = i.FbLocationCountry, 
      --[FbLatitude] = i.FbLatitude, 
      --[FbLongitude] = i.FbLongitude, 
      --[FbEventGeoLocation] = i.FbEventGeoLocation,
      --[removed] = i.removed,
      --[deleted] = i.deleted, 
      --[lastModified] = i.lastModified, 
      --[createdAt] = i.createdAt, 
      [updatedAt] = getdate()
 FROM HC.Event evt
 inner join inserted i on i.id = evt.id


END
' 
GO
/****** Object:  Trigger [HC3W].[tgInsertVwAdEventList]    Script Date: 7/2/2021 4:18:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC3W].[tgInsertVwAdEventList]'))
EXEC dbo.sp_executesql @statement = N'


CREATE TRIGGER [HC3W].[tgInsertVwAdEventList] ON [HC3W].[vwAdEventList]
INSTEAD OF INSERT AS
BEGIN
    SET NOCOUNT ON;


	IF ((SELECT COUNT(*) 
	FROM 
	inserted i 
	INNER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = i.KennelId
	INNER JOIN HC.Hasher h ON hkm.UserId = h.id AND h.HcWebUserId = i.HcWebUserId
	WHERE ((hkm.HcWebPermissionFlags & 0x0005) = 0x0005) OR (h.HcWebUserId < 10)) = 0)
	BEGIN
		DECLARE @errorId uniqueidentifier
		SET @errorId = newid()

		INSERT HC.ErrorLog (
			id, 
			HcVersion, 
			ErrorName,
			ErrorDescription,
			ProcName,
			userId) 
		VALUES (
			@errorId,
			''Attempt to insert event into unauthorized kennel'',
			''A user attempted to insert an event into a kennel they were not authorized to access'',
			'''',
			'''',
			''00000000-0000-0000-0000-000000000000'')

		DECLARE @error nvarchar(200)
		DECLARE @i int
		SELECT @i = i.HcWebUserId from inserted i

		SET @error = ''You are not authorized to insert a run for this Kennel (WebUserId = '' + CAST(coalesce(@i,-1) as NVARCHAR(50)) + '')''
		
		RAISERROR (@error, 16, 1);
	END
	ELSE
		BEGIN

			INSERT [HC].[Event]
			  (
				[KennelId]
				,[EventName]
				,[EventStartDatetime] 
				,[AbsoluteEventNumber]
				,[EventDescription] 
				,[LocationOneLineDesc] 
				,[LocationCity] 
				,[LocationStreet] 
				,[LocationPostCode] 
				,[LocationRegion]
				,[LocationSubRegion]
				,[LocationCountry]
				,[Latitude] 
				,[Longitude]  
				,[IsCountedRun]
				,[IsVisible]
				,[Hares]
			   )
		SELECT
				KennelId
				,EventNameForInsert
				,EventStartDateTimeForInsert
				,AbsoluteEventNumberForInsert
				,EventDescriptionForInsert
				,LocationOneLineDescriptionForInsert
				,LocationCityForInsert
				,LocationStreetForInsert
				,LocationPostCodeForInsert
				,LocationRegionForInsert
				,LocationSubRegionForInsert
				,LocationCountryForInsert
				,LatitudeForInsert
				,LongitudeForInsert
				,IsCountedRun
				,IsVisible
				,Hares
		FROM
			inserted
	END

END
' 
GO
/****** Object:  Trigger [HC3W].[tgUpdateAdHasher]    Script Date: 7/2/2021 4:18:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC3W].[tgUpdateAdHasher]'))
EXEC dbo.sp_executesql @statement = N'



CREATE TRIGGER [HC3W].[tgUpdateAdHasher] ON [HC3W].[vwAdHasher]
INSTEAD OF UPDATE AS
BEGIN

SET NOCOUNT ON
	 if(UPDATE([distancePreference]) OR UPDATE([HomeKennelId])  OR UPDATE([displayName]) OR UPDATE([hashName]) OR UPDATE([firstName]) OR UPDATE([lastName]) OR UPDATE([email]) OR UPDATE([photo]) OR UPDATE([nameDisplayPreference]))
	 BEGIN
		UPDATE HC.Hasher SET 
		 [displayName] = i.displayName
		,[hashName] = i.hashName
		,[firstName] = i.firstName
		,[lastName] = i.lastName
		,[email] = i.email
		,[photo] = i.photo
		,[nameDisplayPreference] = i.nameDisplayPreference
		,[HomeKennelId] = i.homeKennelId
		,[Preferences] = ((h.[Preferences] & 0xFFFFFFFC) | (i.[distancePreference] & 0x00000003))
	  FROM HC.Hasher h, inserted i where h.id = i.userId
	 END


	 IF (UPDATE(HomeKennelId))
	BEGIN
		DECLARE @homeKennelId uniqueidentifier,
				@userId uniqueidentifier
		

		SELECT @homeKennelId = homeKennelId,@userId = userId from INSERTED

		IF (@homeKennelId IS NOT NULL)
		BEGIN
		SET NOCOUNT ON
			IF (select count(*) from HC.HasherKennelMap hkm where hkm.UserId = @userId AND hkm.KennelId = @homeKennelId) = 0 
			BEGIN
			INSERT INTO [HC].[HasherKennelMap]
			   ([UserId]
			   ,[KennelId]
			   ,[Following]
			   ,[IsKennelFollowing]
			   ,[IsHomeKennel])
			SELECT 
				
				@userId,  -- userId
				@homeKennelId,  -- kennelId
				1, -- following
				1, -- isKennelFollowing
				1  -- isHomeKennel
			END
		END
	END



	 if(UPDATE([following]) OR UPDATE([isKennelFollowing]) OR UPDATE([kennelNotificationPreference]) OR UPDATE([kennelEmailPreference]) OR UPDATE([historicalPackRunCount]) 
	 OR UPDATE([historicalHaringCount]) OR UPDATE([historicalCountIsEstimate]) OR UPDATE([membershipExpirationDate]) OR UPDATE([memberSince]))
	 BEGIN
		UPDATE HC.HasherKennelMap SET 
      [following] = i.following
      ,[isKennelFollowing] = i.isKennelFollowing
      ,[kennelNotificationPreference] = i.kennelNotificationPreference
      ,[KennelEmailAlertPreference] = i.kennelEmailPreference
      ,[historicalPackRunCount] = i.historicalPackRunCount
      ,[historicalHaringCount] = i.historicalHaringCount
      ,[historicalCountIsEstimate] = i.historicalCountIsEstimate
      ,[membershipExpirationDate] = i.membershipExpirationDate
      ,[memberSince] = i.memberSince
	  FROM HC.HasherKennelMap hkm, inserted i where hkm.id = i.hkmId
	 END

	 if(UPDATE([Email]))
	 BEGIN
		DECLARE @email nvarchar(250)
		SELECT @email = i.email, @userId = i.userId from inserted i

		if (@email = ''default'')
		BEGIN
			UPDATE HC.Hasher SET [email] = REPLACE(h.QR_code,''UQR:'','''') + ''@harriercentral.com''
			--UPDATE HC.Hasher SET [email] = ''test123@harriercentral.com''
				FROM HC.Hasher h where h.id = @userId
		END ELSE if (@email not like ''%*%'')
		BEGIN
			UPDATE HC.Hasher SET [email] = @email
			FROM HC.Hasher h where h.id = @userId
		END
	 END
END;
' 
GO
/****** Object:  Trigger [HC3W].[tgUpdateAdHasherList]    Script Date: 7/2/2021 4:18:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC3W].[tgUpdateAdHasherList]'))
EXEC dbo.sp_executesql @statement = N'






CREATE TRIGGER [HC3W].[tgUpdateAdHasherList] ON [HC3W].[vwAdHasherList]
INSTEAD OF UPDATE AS
BEGIN

SET NOCOUNT ON

	

	 if(Update(MismanagementRoleFlags) OR UPDATE(HcWebPermissionFlags) OR UPDATE(MismanagementRoles))
	 BEGIN

		 DECLARE @hkmId uniqueidentifier
		 DECLARE @mmRoleFlags int
		 DECLARE @mmRoles int
		 DECLARE @hcWebPermissionFlags int
		 DECLARE @kennelEmailPrefs smallint

		 DECLARE xCrsr CURSOR FOR
		 SELECT id FROM inserted

		 OPEN xCrsr

		 FETCH NEXT FROM xCrsr INTO @hkmId

		 WHILE @@FETCH_STATUS = 0
		 BEGIN
			SELECT 
				@mmRoleFlags = MismanagementRoleFlags, 
				@hcWebPermissionFlags = HcWebPermissionFlags,
				@mmRoles = MismanagementRoles
				from inserted where id = @hkmId
			UPDATE HC.HasherKennelMap SET 
				MismanagementRoleFlags = @mmRoleFlags, 
				HcWebPermissionFlags = @hcWebPermissionFlags,
				MismanagementRoles = @mmRoles
				WHERE id = @hkmId
			FETCH NEXT FROM xCrsr INTO @hkmId
		 END

		 CLOSE xCrsr
		 DEALLOCATE xCrsr

	 END

	 DECLARE @kennelEmailAlertPrefs smallint

	 if(Update(KennelEmailAlertPreference))
	 BEGIN


		 DECLARE xCrsr CURSOR FOR
		 SELECT id FROM inserted

		 OPEN xCrsr

		 FETCH NEXT FROM xCrsr INTO @hkmId

		 WHILE @@FETCH_STATUS = 0
		 BEGIN
			SELECT @kennelEmailAlertPrefs = KennelEmailAlertPreference from inserted where id = @hkmId
			UPDATE HC.HasherKennelMap SET KennelEmailAlertPreference = @kennelEmailAlertPrefs WHERE id = @hkmId
			FETCH NEXT FROM xCrsr INTO @hkmId
		 END

		 CLOSE xCrsr
		 DEALLOCATE xCrsr

	 END

	 DECLARE @isKennelFollowing smallint

	 if(Update(isKennelFollowing))
	 BEGIN

		 DECLARE xCrsr CURSOR FOR
		 SELECT id FROM inserted

		 OPEN xCrsr

		 FETCH NEXT FROM xCrsr INTO @hkmId

		 WHILE @@FETCH_STATUS = 0
		 BEGIN
			SELECT @isKennelFollowing = isKennelFollowing from inserted where id = @hkmId
			UPDATE HC.HasherKennelMap SET isKennelFollowing = @isKennelFollowing WHERE id = @hkmId
			FETCH NEXT FROM xCrsr INTO @hkmId
		 END

		 CLOSE xCrsr
		 DEALLOCATE xCrsr

	 END

	 IF(Update(MismanagementRoles))
	 BEGIN
		 DECLARE @kennelId uniqueidentifier

		 DECLARE xCrsr CURSOR FOR
		 SELECT distinct(kennelId) as kennelId FROM inserted

		 OPEN xCrsr

		 FETCH NEXT FROM xCrsr INTO @kennelId

		 WHILE @@FETCH_STATUS = 0
		 BEGIN
			UPDATE HC.Kennel SET KennelMismanagementTeam = coalesce(mm.MmRoles,''''), updatedAt = getdate() FROM HC.Kennel k LEFT OUTER JOIN
			HC3.vwMmByKennel mm on mm.KennelId = k.id
			where k.id = @kennelId

			FETCH NEXT FROM xCrsr INTO @kennelId
		 END

		 CLOSE xCrsr
		 DEALLOCATE xCrsr

	 END

END;
' 
GO
/****** Object:  Trigger [HC3W].[tgUpdateSaHasher]    Script Date: 7/2/2021 4:18:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC3W].[tgUpdateSaHasher]'))
EXEC dbo.sp_executesql @statement = N'




CREATE TRIGGER [HC3W].[tgUpdateSaHasher] ON [HC3W].[vwSaHasher]
INSTEAD OF UPDATE AS
BEGIN
   SET NOCOUNT ON

   UPDATE [HC].[Hasher]
   SET 
      [HomeKennelId] = i.HomeKennelId
      --,[MotherKennelId] = i.MotherKennelId
      ,[SupportCode] = i.SupportCode
      ,[ResetCode] = i.ResetCode
      ,[QR_code] = i.QR_code
      ,[QR_secret_code] = i.QR_secret_code
      ,[DisplayName] = i.DisplayName
      ,[HashName] = i.HashName
      ,[FirstName] = i.FirstName
      ,[LastName] = i.LastName
      ,[Email] = i.Email
      ,[Photo] = i.Photo
      --,[Gender] = i.Gender
      ,[FacebookId] = i.FacebookId
      ,[Locale] = i.Locale
      ,[Description] = i.Description
      ,[HomeLatitude] = i.HomeLatitude
      ,[HomeLongitude] = i.HomeLongitude
      ,[HomeGeolocation] = i.HomeGeolocation
      ,[NameDisplayPreference] = i.NameDisplayPreference
      --,[Preferences] = i.pref
      ,[HcWebUserId] = i.HcWebUserId
      --,[IncludeInGlobalHashDirectory] = i.includ
    FROM HC.Hasher h inner join INSERTED i on h.id = i.id


	IF UPDATE(HomeKennelId)
	BEGIN

		-- find all records where a home kennel is being set
		-- but 
	    select i.id, i.HomeKennelId into #temp
			from inserted i 
			where 
			i.HomeKennelId IS NOT NULL AND
			(select count(*) from HC.HasherKennelMap hkm where hkm.UserId = i.id AND hkm.KennelId = i.HomeKennelId) = 0 

			INSERT INTO [HC].[HasherKennelMap]
           ([id]
           ,[UserId]
           ,[KennelId]
           ,[Following]
           ,[IsKennelFollowing]
           ,[IsHomeKennel]
		   ,[updatedAt])
		SELECT 
			newid(), -- id
			t.id,  -- userId
			t.HomeKennelId,  -- kennelId
			1, -- following
			1, -- isKennelFollowing
			1,  -- isHomeKennel
			getdate()
		from #temp t

		UPDATE HC.HasherKennelMap SET [Following] = 1 
		FROM HC.HasherKennelMap hkm INNER JOIN inserted i on hkm.UserId = i.id and hkm.KennelId = i.HomeKennelId
		WHERE hkm.[Following] != 1

		DROP TABLE #temp

	END


END;
' 
GO
/****** Object:  Trigger [HC3W].[tgUpdate]    Script Date: 7/2/2021 4:18:20 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[HC3W].[tgUpdate]'))
EXEC dbo.sp_executesql @statement = N'
CREATE TRIGGER [HC3W].[tgUpdate] ON [HC3W].[vwSaHasherPermissions]
INSTEAD OF UPDATE AS
BEGIN

SET NOCOUNT ON

	 if(Update(MismanagementRoleFlags) OR UPDATE(HcWebPermissionFlags))
	 BEGIN

		 DECLARE @hkmId uniqueidentifier
		 DECLARE @mmRoleFlags int
		 DECLARE @hcWebPermissionFlags int

		 DECLARE xCrsr CURSOR FOR
		 SELECT HkmId FROM inserted

		 OPEN xCrsr

		 FETCH NEXT FROM xCrsr INTO @hkmId

		 WHILE @@FETCH_STATUS = 0
		 BEGIN
			SELECT @mmRoleFlags = MismanagementRoleFlags, @hcWebPermissionFlags = HcWebPermissionFlags from inserted where HkmId = @hkmId
			UPDATE HC.HasherKennelMap SET MismanagementRoleFlags = @mmRoleFlags, HcWebPermissionFlags = @hcWebPermissionFlags WHERE id = @hkmId
			FETCH NEXT FROM xCrsr INTO @hkmId
		 END

		 CLOSE xCrsr
		 DEALLOCATE xCrsr

	 END

END;
' 
GO
IF NOT EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'microsoft_database_tools_support' , N'SCHEMA',N'dbo', N'TABLE',N'sysdiagrams', NULL,NULL))
	EXEC sys.sp_addextendedproperty @name=N'microsoft_database_tools_support', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'sysdiagrams'
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF
GO
/****** Object:  Index [IX_City_SpatialLocation]    Script Date: 7/2/2021 4:18:20 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[HC].[City]') AND name = N'IX_City_SpatialLocation')
CREATE SPATIAL INDEX [IX_City_SpatialLocation] ON [HC].[City]
(
	[CityGeolocation]
)USING  GEOGRAPHY_AUTO_GRID 
WITH (
CELLS_PER_OBJECT = 12, STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO
SET ARITHABORT ON
SET CONCAT_NULL_YIELDS_NULL ON
SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
SET NUMERIC_ROUNDABORT OFF
GO
/****** Object:  Index [IX_KennelSpatialIndex]    Script Date: 7/2/2021 4:18:20 AM ******/
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[HC].[Kennel]') AND name = N'IX_KennelSpatialIndex')
CREATE SPATIAL INDEX [IX_KennelSpatialIndex] ON [HC].[Kennel]
(
	[KennelGeolocation]
)USING  GEOGRAPHY_AUTO_GRID 
WITH (
CELLS_PER_OBJECT = 12, STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF) ON [PRIMARY]
GO
ALTER DATABASE [HarrierCentralWebDb] SET  READ_WRITE 
GO
