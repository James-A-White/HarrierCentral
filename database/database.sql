USE [master]
GO
/****** Object:  Database [HarrierCentralWebDb]    Script Date: 4/21/19 7:11:52 PM ******/
CREATE DATABASE [HarrierCentralWebDb]
GO
ALTER DATABASE [HarrierCentralWebDb] SET COMPATIBILITY_LEVEL = 120
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [HarrierCentralWebDb].[dbo].[sp_fulltext_database] @action = 'enable'
end
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
ALTER DATABASE [HarrierCentralWebDb] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [HarrierCentralWebDb] SET READ_COMMITTED_SNAPSHOT ON 
GO
ALTER DATABASE [HarrierCentralWebDb] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET  MULTI_USER 
GO
ALTER DATABASE [HarrierCentralWebDb] SET DB_CHAINING OFF 
GO
ALTER DATABASE [HarrierCentralWebDb] SET ENCRYPTION ON
GO
ALTER DATABASE [HarrierCentralWebDb] SET QUERY_STORE = ON
GO
ALTER DATABASE [HarrierCentralWebDb] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 7), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 10, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO)
GO
USE [HarrierCentralWebDb]
GO
/****** Object:  Schema [Admin]    Script Date: 4/21/19 7:11:53 PM ******/
CREATE SCHEMA [Admin]
GO
/****** Object:  Schema [DEV]    Script Date: 4/21/19 7:11:53 PM ******/
CREATE SCHEMA [DEV]
GO
/****** Object:  Schema [DomainValues]    Script Date: 4/21/19 7:11:53 PM ******/
CREATE SCHEMA [DomainValues]
GO
/****** Object:  Schema [Events]    Script Date: 4/21/19 7:11:54 PM ******/
CREATE SCHEMA [Events]
GO
/****** Object:  Schema [Geography]    Script Date: 4/21/19 7:11:54 PM ******/
CREATE SCHEMA [Geography]
GO
/****** Object:  Schema [Hashers]    Script Date: 4/21/19 7:11:54 PM ******/
CREATE SCHEMA [Hashers]
GO
/****** Object:  Schema [HC]    Script Date: 4/21/19 7:11:54 PM ******/
CREATE SCHEMA [HC]
GO
/****** Object:  Schema [HC2]    Script Date: 4/21/19 7:11:54 PM ******/
CREATE SCHEMA [HC2]
GO
/****** Object:  Schema [HC3]    Script Date: 4/21/19 7:11:54 PM ******/
CREATE SCHEMA [HC3]
GO
/****** Object:  Schema [Kennels]    Script Date: 4/21/19 7:11:54 PM ******/
CREATE SCHEMA [Kennels]
GO
/****** Object:  Schema [Transactions]    Script Date: 4/21/19 7:11:54 PM ******/
CREATE SCHEMA [Transactions]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_diagramobjects]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE FUNCTION [dbo].[fn_diagramobjects]() 
	RETURNS int
	WITH EXECUTE AS N'dbo'
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

		select 	@id_upgraddiagrams = object_id(N'dbo.sp_upgraddiagrams'),
			@id_sysdiagrams = object_id(N'dbo.sysdiagrams'),
			@id_helpdiagrams = object_id(N'dbo.sp_helpdiagrams'),
			@id_helpdiagramdefinition = object_id(N'dbo.sp_helpdiagramdefinition'),
			@id_creatediagram = object_id(N'dbo.sp_creatediagram'),
			@id_renamediagram = object_id(N'dbo.sp_renamediagram'),
			@id_alterdiagram = object_id(N'dbo.sp_alterdiagram'), 
			@id_dropdiagram = object_id(N'dbo.sp_dropdiagram')

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
	
GO
/****** Object:  UserDefinedFunction [HC].[CHECK_ACCESS_TOKEN]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [HC].[CHECK_ACCESS_TOKEN] (@userId uniqueidentifier, @procName nvarchar(100), @accessToken nvarchar(1000), @paramString nvarchar(500))
RETURNS int
WITH EXECUTE AS CALLER
AS
BEGIN
	DECLARE @generatedToken nvarchar(1000)
	SET @generatedToken = HC.CREATE_ACCESS_TOKEN(@userid,@procName,0,@paramString)
	if (@generatedToken <> @accessToken)
	BEGIN
		SET @generatedToken = HC.CREATE_ACCESS_TOKEN(@userid,@procName,1,@paramString)
		if (@generatedToken <> @accessToken)
		BEGIN
			SET @generatedToken = HC.CREATE_ACCESS_TOKEN(@userid,@procName,-1,@paramString)
			if (@generatedToken <> @accessToken)
			BEGIN
				RETURN 0
			END
		END
	END

	RETURN 1
END
GO
/****** Object:  UserDefinedFunction [HC].[CREATE_ACCESS_TOKEN]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [HC].[CREATE_ACCESS_TOKEN] (@userId uniqueidentifier, @procName varchar(500),@offset int,@paramString nvarchar(500))
RETURNS varchar(MAX)
WITH EXECUTE AS CALLER
AS
BEGIN
	declare @bin as varbinary(max)

	if @paramString IS NOT NULL SET @paramString = upper('#'+@paramString)

	--return upper(cast(@userId as nvarchar(50))) + '#'+@procName+'#' + cast((cast(datediff(second,'25 Jul 1993 15:00',GETUTCDATE()) / 5760 as int)+@offset) as nvarchar(50))
	DECLARE @str as varchar(1000)
	SET @str = upper(cast(@userId as varchar(50))) + '#'+@procName+'#' + cast((cast(datediff(second,'25 Jul 1993 15:00',GETUTCDATE()) / 5760 as int)+@offset) as varchar(50)) + coalesce(@paramString,'')
	SET @bin = HASHBYTES('SHA2_256',@str)
	return cast('' as xml).value('xs:hexBinary(sql:variable("@bin"))', 'varchar(max)')
END
GO
/****** Object:  UserDefinedFunction [HC].[InlineMax]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [HC].[InlineMax](@val1 int, @val2 int)
returns int
as
begin
  if @val1 > @val2
    return @val1
  return isnull(@val2,@val1)
end
GO
/****** Object:  UserDefinedFunction [HC].[NUMBER_TO_STR_BASE]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [HC].[NUMBER_TO_STR_BASE] (@base int,@number int)
RETURNS varchar(MAX)
WITH EXECUTE AS CALLER
AS
BEGIN
     DECLARE @dividend int = @number
        ,@remainder int = 0 
        ,@numberString varchar(MAX) = CASE WHEN @number = 0 THEN '0' ELSE '' END ;
     SET @base = CASE WHEN @base <= 36 THEN @base ELSE 36 END;--The max base is 36, includes the range of [0-9A-Z]
     WHILE (@dividend > 0 OR @remainder > 0)
         BEGIN
            SET @remainder = @dividend % @base ; --The reminder by the division number in base
            SET @dividend = @dividend / @base ; -- The integer part of the division, becomes the new divident for the next loop
            IF(@dividend > 0 OR @remainder > 0)--check that not correspond the last loop when quotient and reminder is 0
                SET @numberString =  CHAR( (CASE WHEN @remainder <= 25 THEN ASCII('A') ELSE ASCII('0')-26 END) + @remainder ) + @numberString;
     END;
     RETURN(@numberString);
END
GO
/****** Object:  Table [HC].[Country]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[Country](
	[id] [uniqueidentifier] NOT NULL,
	[CountryCode] [nvarchar](5) NOT NULL,
	[Latitude] [float] NOT NULL,
	[Longitude] [float] NOT NULL,
	[CountryName] [nvarchar](250) NOT NULL,
	[ContinentCode] [nvarchar](5) NOT NULL,
	[ContinentName] [nvarchar](100) NOT NULL,
	[FlagFile] [nvarchar](100) NULL,
	[CurrencyCode] [nvarchar](50) NULL,
	[PrimaryCultureCode] [nvarchar](50) NOT NULL,
	[ShowRegion] [smallint] NOT NULL,
	[CurrencySymbol] [nvarchar](5) NOT NULL,
	[DigitsAfterDecimal] [smallint] NOT NULL,
	[Removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Country] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_deleteCurrencyTest]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteCurrencyTest] as
select c.CountryName, c.CurrencySymbol, c.DigitsAfterDecimal,c.id from HC.Country c
GO
/****** Object:  Table [HC].[Hasher]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[Hasher](
	[id] [uniqueidentifier] NOT NULL,
	[Home_KennelId] [uniqueidentifier] NULL,
	[Mother_KennelId] [uniqueidentifier] NULL,
	[SupportCode] [nvarchar](50) NOT NULL,
	[ResetCode] [nvarchar](50) NOT NULL,
	[QR_code] [nvarchar](50) NOT NULL,
	[QR_secret_code] [uniqueidentifier] NOT NULL,
	[DisplayName] [nvarchar](250) NULL,
	[HashName] [nvarchar](250) NULL,
	[FirstName] [nvarchar](250) NULL,
	[LastName] [nvarchar](250) NULL,
	[Email] [nvarchar](250) NULL,
	[Photo] [nvarchar](250) NULL,
	[Gender] [nvarchar](50) NULL,
	[FacebookId] [nvarchar](250) NULL,
	[Locale] [nvarchar](50) NULL,
	[Description] [nvarchar](4000) NULL,
	[HomeLatitude] [decimal](12, 9) NULL,
	[HomeLongitude] [decimal](13, 9) NULL,
	[HomeGeolocation] [geography] NULL,
	[NameDisplayPreference] [smallint] NOT NULL,
	[Removed] [smallint] NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL,
 CONSTRAINT [PK_Hasher] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_deleteHcPhotos]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteHcPhotos] as
select Photo,id,DisplayName from HC.Hasher
where createdAt > dateadd(day,-20,getdate())
GO
/****** Object:  Table [HC].[Event]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[Event](
	[id] [uniqueidentifier] NOT NULL,
	[EventFacebookId] [nvarchar](250) NULL,
	[FacebookRecordLastUpdated] [datetime] NULL,
	[EventStartDatetime] [datetime] NULL,
	[EventEndDatetime] [datetime] NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[IsVisible] [smallint] NOT NULL,
	[IsCountedRun] [smallint] NOT NULL,
	[IsPromotedEvent] [smallint] NOT NULL,
	[EventGeographicScope] [smallint] NOT NULL,
	[ThemeRunType] [smallint] NOT NULL,
	[AbsoluteEventNumber] [smallint] NULL,
	[EventNumber] [smallint] NOT NULL,
	[EventNumberIncrement] [smallint] NOT NULL,
	[EventScope] [smallint] NOT NULL,
	[EventPriceForMembers] [smallmoney] NULL,
	[EventPriceForNonMembers] [smallmoney] NULL,
	[EventCurrencyType] [nvarchar](10) NULL,
	[UserEventCounterIncrement] [smallint] NOT NULL,
	[EventName] [nvarchar](250) NOT NULL,
	[EventDescription] [nvarchar](4000) NULL,
	[EventImage] [nvarchar](500) NULL,
	[EventImageOffsetX] [smallint] NULL,
	[EventImageOffsetY] [smallint] NULL,
	[EventShortDesc] [nvarchar](250) NULL,
	[EventFlagsA] [int] NOT NULL,
	[EventFlagsB] [int] NOT NULL,
	[EventInstructions] [nvarchar](4000) NULL,
	[EventComplete] [smallint] NOT NULL,
	[LocationOneLineDesc] [nvarchar](250) NULL,
	[LocationCity] [nvarchar](250) NULL,
	[LocationStreet] [nvarchar](250) NULL,
	[LocationPostCode] [nvarchar](250) NULL,
	[LocationCountry] [nvarchar](250) NULL,
	[LocationDescription] [nvarchar](4000) NULL,
	[MinimumParticipantsRequired] [smallint] NULL,
	[MaximumParticipantsAllowed] [smallint] NULL,
	[Organizer_HasherId] [uniqueidentifier] NULL,
	[Latitude] [decimal](18, 15) NULL,
	[Longitude] [decimal](19, 15) NULL,
	[FbLatitude] [decimal](18, 15) NULL,
	[FbLongitude] [decimal](19, 15) NULL,
	[EventGeolocation] [geography] NULL,
	[FacebookAttendingCount] [smallint] NULL,
	[FacebookMaybeCount] [smallint] NULL,
	[FacebookDeclinedCount] [smallint] NULL,
	[FacebookInterestedCount] [smallint] NULL,
	[FacebookNoReplyCount] [smallint] NULL,
	[CanEditRunAttendence] [smallint] NOT NULL,
	[deleted] [bit] NOT NULL,
	[lastModified] [datetime] NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Event] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_deleteFilthRuns]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteFilthRuns] AS
select * from HC.event  where KennelId = '5029DE3A-D231-47AA-BE72-ECE9BCCD55D1'
GO
/****** Object:  View [dbo].[vw_deleteAddHashers]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[vw_deleteAddHashers] as
select FirstName,LastName,HashName,Email from HC.Hasher 
GO
/****** Object:  Table [HC].[HasherEventMap]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[HasherEventMap](
	[id] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[RegistrationId] [uniqueidentifier] NULL,
	[UserStartEvent] [datetime] NULL,
	[UserEndEvent] [datetime] NULL,
	[EventCost] [smallmoney] NULL,
	[Rsvp] [datetime] NULL,
	[RsvpState] [smallint] NOT NULL,
	[AttendenceState] [smallint] NOT NULL,
	[IsHare] [smallint] NOT NULL,
	[EventCountOverride] [smallint] NULL,
	[VirginVisitorType] [smallint] NOT NULL,
	[DisplayName] [nvarchar](120) NULL,
	[Email] [nvarchar](120) NULL,
	[PhoneNumber] [nvarchar](120) NULL,
	[TotalHaringThisKennel] [smallint] NULL,
	[TotalPackRunsThisKennel] [smallint] NULL,
	[TotalRunsThisKennel] [smallint] NULL,
	[TotalHaringAllKennels] [smallint] NULL,
	[TotalPackRunsAllKennels] [smallint] NULL,
	[TotalRunsAllKennels] [smallint] NULL,
 CONSTRAINT [PK_HcHasherEventMap] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_deleteImportHemRecords]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteImportHemRecords] as 
select top 10 EventId,UserId,UserStartEvent,Rsvp,RsvpState,AttendenceState,IsHare,VirginVisitorType from HC.HasherEventMap
GO
/****** Object:  Table [HC].[Kennel]    Script Date: 4/21/19 7:11:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[Kennel](
	[id] [uniqueidentifier] NOT NULL,
	[KennelStatus] [smallint] NOT NULL,
	[KennelName] [nvarchar](250) NOT NULL,
	[KennelFacebookId] [nvarchar](250) NULL,
	[KennelFacebookToken] [nvarchar](1000) NULL,
	[KennelFacebookTokenUserId] [uniqueidentifier] NULL,
	[KennelFacebookTokenLastUpdated] [datetime] NULL,
	[KennelFacebookImportDaysInPast] [smallint] NOT NULL,
	[KennelFacebookImportDaysInFuture] [smallint] NOT NULL,
	[AutoImportFacebookEvents] [smallint] NOT NULL,
	[ImportOnlyTaggedEvents] [smallint] NOT NULL,
	[CanEditRunAttendence] [smallint] NOT NULL,
	[FacebookTagForImport] [nvarchar](50) NULL,
	[KennelShortName] [nvarchar](10) NULL,
	[KennelDescription] [nvarchar](4000) NULL,
	[KennelLogo] [nvarchar](500) NOT NULL,
	[KennelCoverPhoto] [nvarchar](500) NULL,
	[KennelWebsiteUrl] [nvarchar](500) NULL,
	[DefaultEventPriceForMembers] [smallmoney] NULL,
	[DefaultEventPriceForNonMembers] [smallmoney] NULL,
	[DefaultEventCurrencyType] [nvarchar](10) NULL,
	[DefaultRunStartTime] [time](7) NOT NULL,
	[DefaultCity] [nvarchar](250) NULL,
	[DefaultCountry] [nvarchar](250) NULL,
	[DefaultCitiesList] [nvarchar](1000) NULL,
	[DefaultCountriesList] [nvarchar](1000) NULL,
	[AllowNegativeCredit] [smallint] NOT NULL,
	[CityId] [uniqueidentifier] NOT NULL,
	[ProvinceStateId] [uniqueidentifier] NOT NULL,
	[CountryId] [uniqueidentifier] NOT NULL,
	[Latitude] [decimal](18, 14) NULL,
	[Longitude] [decimal](19, 15) NULL,
	[KennelGeolocation] [geography] NULL,
	[removed] [smallint] NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL,
 CONSTRAINT [PK_Kennel_1] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_deleteMe_facebookIds]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteMe_facebookIds]
as
select top 20 * from HC.Kennel where KennelFacebookId is not null
GO
/****** Object:  View [dbo].[vw_deleteMe_importEvents]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteMe_importEvents] as
select top 1 id,EventStartDatetime,KennelId,EventName,EventDescription from HC.Event
GO
/****** Object:  View [dbo].[vw_deleteEditFacebookKennels]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteEditFacebookKennels] as 
select * from HC.Kennel where KennelFacebookId is not null
GO
/****** Object:  Table [HC].[City]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[City](
	[id] [uniqueidentifier] NOT NULL,
	[CityName] [nvarchar](100) NOT NULL,
	[RegionId] [uniqueidentifier] NOT NULL,
	[Latitude] [numeric](12, 9) NULL,
	[Longitude] [numeric](13, 9) NULL,
	[City_ASCII] [nvarchar](100) NULL,
	[CityGeolocation] [geography] NULL,
	[FlagFile] [nvarchar](100) NULL,
	[Removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_City2] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [HC].[deleteTempCities]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view 

[HC].[deleteTempCities]

AS 

select * from HC.City where Latitude between 52 and 53 and Longitude  between 4 and  5
GO
/****** Object:  View [dbo].[vw_deleteEditFILTHhash]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteEditFILTHhash] as select * from HC.Kennel where KennelName like '%FILTH%'
GO
/****** Object:  View [dbo].[vw_deleteEditNetherlands]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteEditNetherlands] as select * from HC.Country h where h.CountryName like '%nether%'
GO
/****** Object:  Table [HC].[Payment]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[Payment](
	[id] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[HasherEventMapId] [uniqueidentifier] NULL,
	[EventId] [uniqueidentifier] NULL,
	[PaymentProcessedBy_userId] [uniqueidentifier] NOT NULL,
	[CreditAmount] [smallmoney] NOT NULL,
	[DebitAmount] [smallmoney] NOT NULL,
	[PaidDate] [datetime] NOT NULL,
	[PaymentType] [smallint] NOT NULL,
	[CancelledDate] [datetime] NULL,
	[CancelledBy_UserId] [uniqueidentifier] NULL,
	[PaymentReference] [nvarchar](50) NULL,
	[Notes] [nvarchar](500) NULL,
 CONSTRAINT [PK_Payment] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_deleteEditPayments]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteEditPayments] as select * from HC.Payment
GO
/****** Object:  View [dbo].[vw_deleteOpeeRuns]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view
[dbo].[vw_deleteOpeeRuns] as 
select * from HC.HasherEventMap where userId = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC'
GO
/****** Object:  View [HC].[vwEventCommonFields]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO












CREATE VIEW [HC].[vwEventCommonFields]

AS	
		
		SELECT
			  k.id as KennelId
			  ,e.[id] as EventId
			  ,e.[EventFacebookId]
			  ,e.[EventName]
			  ,e.[EventNumber]
			  ,case WHEN e.IsCountedRun = 1 THEN 'Run #'+cast(e.EventNumber as nvarchar(25)) ELSE 'n/a' END as EventNumberStr
			  ,e.[EventShortDesc]
			  ,e.[EventDescription]
			  ,coalesce(e.[EventImage],k.kennelLogo) as EventImage
			  ,e.[EventStartDatetime]
			  ,e.[EventEndDatetime]
			  ,e.[lastModified]
			  ,e.[UserEventCounterIncrement]
			  ,e.[MinimumParticipantsRequired]
			  ,e.[MaximumParticipantsAllowed]
			  ,left(datename(dw,e.[EventStartDatetime]),3) as WeekDayName
			  ,right('00' + convert(nvarchar(2),datepart(day,e.[EventStartDatetime])),2) as DayNumber
			  ,left(datename(month,e.[EventStartDatetime]),3) + CASE WHEN format(getdate(),'yy') <> format(e.[EventStartDatetime],'yy') THEN ' ''' + format(e.[EventStartDatetime],'yy') ELSE '' END as MonthNameShort
			  ,REPLACE(FORMAT(cast(e.[EventStartDatetime] as datetime),'h:mm tt'),':00','') as EventTimeFormatted
			  ,e.LocationStreet
			  ,e.LocationPostCode
			  ,e.[LocationOneLineDesc]
			  ,coalesce(e.LocationCity,c.CityName,'<no city>') as LocationCity
			  ,e.[Latitude] as PinLatitude
			  ,e.[Longitude] as PinLongitude
			  ,coalesce(e.EventCurrencyType,k.DefaultEventCurrencyType,'en-us') as CurrencyType
			  ,REPLACE(FORMAT(coalesce(e.EventPriceForMembers,k.DefaultEventPriceForMembers,e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,0),'C',coalesce(e.EventCurrencyType,k.DefaultEventCurrencyType,'en-us')),',','.') as PriceForMembers
			  ,REPLACE(FORMAT(coalesce(e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,e.EventPriceForMembers,k.DefaultEventPriceForMembers,0),'C',coalesce(e.EventCurrencyType,k.DefaultEventCurrencyType,'en-us')),',','.') as PriceForNonMembers
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
		
GO
/****** Object:  View [dbo].[vw_deleteTempKennelList]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteTempKennelList] as select * from HC.Kennel where kennelLogo like 'http%'
GO
/****** Object:  UserDefinedFunction [HC].[DelimitedSplit8K]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [HC].[DelimitedSplit8K]
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
;
GO
/****** Object:  Table [dbo].[BusinessUnits]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Contacts]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[currency]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[currency](
	[name] [nvarchar](100) NULL,
	[code] [nvarchar](100) NULL,
	[symbol] [nvarchar](100) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Exceptions]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Hasher]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Hasher](
	[id] [nvarchar](255) NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Languages]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Languages](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[LanguageId] [nvarchar](10) NOT NULL,
	[LanguageName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Languages] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MeetingAgendaRelevant]    Script Date: 4/21/19 7:11:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MeetingAgendaRelevant](
	[AgendaRelevantId] [int] IDENTITY(1,1) NOT NULL,
	[AgendaId] [int] NOT NULL,
	[ContactId] [int] NOT NULL,
 CONSTRAINT [PK_MeetingAgendaRelevant] PRIMARY KEY CLUSTERED 
(
	[AgendaRelevantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MeetingAgendas]    Script Date: 4/21/19 7:11:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MeetingAgendaTypes]    Script Date: 4/21/19 7:11:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MeetingAgendaTypes](
	[AgendaTypeId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_MeetingAgendaTypes] PRIMARY KEY CLUSTERED 
(
	[AgendaTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MeetingAttendees]    Script Date: 4/21/19 7:11:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MeetingAttendees](
	[AttendeeId] [int] IDENTITY(1,1) NOT NULL,
	[MeetingId] [int] NOT NULL,
	[ContactId] [int] NOT NULL,
	[AttendeeType] [int] NOT NULL,
	[AttendanceStatus] [int] NOT NULL,
 CONSTRAINT [PK_MeetingAttendees] PRIMARY KEY CLUSTERED 
(
	[AttendeeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MeetingDecisionRelevant]    Script Date: 4/21/19 7:11:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MeetingDecisionRelevant](
	[DecisionRelevantId] [int] IDENTITY(1,1) NOT NULL,
	[DecisionId] [int] NOT NULL,
	[ContactId] [int] NOT NULL,
 CONSTRAINT [PK_MeetingDecisionRelevant] PRIMARY KEY CLUSTERED 
(
	[DecisionRelevantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MeetingDecisions]    Script Date: 4/21/19 7:11:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MeetingLocations]    Script Date: 4/21/19 7:11:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MeetingLocations](
	[LocationId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[Address] [nvarchar](300) NULL,
	[Latitude] [float] NOT NULL,
	[Longitude] [float] NOT NULL,
 CONSTRAINT [PK_MeetingLocations] PRIMARY KEY CLUSTERED 
(
	[LocationId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Meetings]    Script Date: 4/21/19 7:11:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MeetingTypes]    Script Date: 4/21/19 7:11:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MeetingTypes](
	[MeetingTypeId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_MeetingTypes] PRIMARY KEY CLUSTERED 
(
	[MeetingTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RolePermissions]    Script Date: 4/21/19 7:11:56 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RolePermissions](
	[RolePermissionId] [bigint] IDENTITY(1,1) NOT NULL,
	[RoleId] [int] NOT NULL,
	[PermissionKey] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_RolePermissions] PRIMARY KEY CLUSTERED 
(
	[RolePermissionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Roles]    Script Date: 4/21/19 7:11:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Roles](
	[RoleId] [int] IDENTITY(1,1) NOT NULL,
	[RoleName] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_Roles] PRIMARY KEY CLUSTERED 
(
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SourceData]    Script Date: 4/21/19 7:11:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
/****** Object:  Table [dbo].[sysdiagrams]    Script Date: 4/21/19 7:11:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[sysdiagrams](
	[name] [sysname] NOT NULL,
	[principal_id] [int] NOT NULL,
	[diagram_id] [int] IDENTITY(1,1) NOT NULL,
	[version] [int] NULL,
	[definition] [varbinary](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[diagram_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UK_principal_name] UNIQUE NONCLUSTERED 
(
	[principal_id] ASC,
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[tempImport]    Script Date: 4/21/19 7:11:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tempImport](
	[userId] [uniqueidentifier] NOT NULL,
	[eventId] [uniqueidentifier] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[unused_FacebookEventImport]    Script Date: 4/21/19 7:11:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[unused_FacebookEventImport](
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
GO
/****** Object:  Table [dbo].[UserPermissions]    Script Date: 4/21/19 7:11:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserPermissions](
	[UserPermissionId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[PermissionKey] [nvarchar](100) NOT NULL,
	[Granted] [bit] NOT NULL,
 CONSTRAINT [PK_UserPermissions] PRIMARY KEY CLUSTERED 
(
	[UserPermissionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserPreferences]    Script Date: 4/21/19 7:11:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserPreferences](
	[UserPreferenceId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[PreferenceType] [nvarchar](100) NOT NULL,
	[Name] [nvarchar](200) NOT NULL,
	[Value] [nvarchar](max) NULL,
 CONSTRAINT [PK_UserPreferences] PRIMARY KEY CLUSTERED 
(
	[UserPreferenceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserRoles]    Script Date: 4/21/19 7:11:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserRoles](
	[UserRoleId] [bigint] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[RoleId] [int] NOT NULL,
 CONSTRAINT [PK_UserRoles] PRIMARY KEY CLUSTERED 
(
	[UserRoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Users]    Script Date: 4/21/19 7:11:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[UserId] [int] IDENTITY(1,1) NOT NULL,
	[Username] [nvarchar](100) NOT NULL,
	[DisplayName] [nvarchar](100) NOT NULL,
	[Email] [nvarchar](100) NULL,
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
 CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[VersionInfo]    Script Date: 4/21/19 7:11:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[VersionInfo](
	[Version] [bigint] NOT NULL,
	[AppliedOn] [datetime] NULL,
	[Description] [nvarchar](1024) NULL
) ON [PRIMARY]
GO
/****** Object:  Index [UC_Version]    Script Date: 4/21/19 7:11:58 PM ******/
CREATE UNIQUE CLUSTERED INDEX [UC_Version] ON [dbo].[VersionInfo]
(
	[Version] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[world_cities_table]    Script Date: 4/21/19 7:11:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
/****** Object:  Table [DEV].[EnumPaymentTypes]    Script Date: 4/21/19 7:11:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DEV].[EnumPaymentTypes](
	[paymentTypeId] [int] NOT NULL,
	[name] [nvarchar](50) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [DomainValues].[CurrencyCodes]    Script Date: 4/21/19 7:11:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DomainValues].[CurrencyCodes](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[Nation] [nvarchar](500) NOT NULL,
	[CurrencyName] [nvarchar](100) NOT NULL,
	[CurrencyCode] [nvarchar](50) NOT NULL,
	[CurrencyNumericCode] [nvarchar](50) NOT NULL,
	[DigitsAfterDecimal] [int] NOT NULL,
	[CultureCode] [nvarchar](50) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [DomainValues].[EventGeographicScope]    Script Date: 4/21/19 7:11:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DomainValues].[EventGeographicScope](
	[EventEnumId] [smallint] NOT NULL,
	[EventEnumName] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_EventEnum] PRIMARY KEY CLUSTERED 
(
	[EventEnumId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DomainValues].[EventRegistrationType]    Script Date: 4/21/19 7:11:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DomainValues].[EventRegistrationType](
	[EventRegistrationEnumId] [smallint] IDENTITY(1,1) NOT NULL,
	[EventRegistrationEnumName] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_EventRegistrationEnum] PRIMARY KEY CLUSTERED 
(
	[EventRegistrationEnumId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DomainValues].[KennelStatusEnum]    Script Date: 4/21/19 7:11:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DomainValues].[KennelStatusEnum](
	[KennelStatusEnumId] [smallint] NOT NULL,
	[KennelStatusEnumName] [nvarchar](250) NOT NULL,
 CONSTRAINT [PK_KennelStatusEnum] PRIMARY KEY CLUSTERED 
(
	[KennelStatusEnumId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DomainValues].[MismanagementEnum]    Script Date: 4/21/19 7:11:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DomainValues].[MismanagementEnum](
	[MismanagementEnumId] [smallint] IDENTITY(1,1) NOT NULL,
	[Title] [nvarchar](250) NOT NULL,
	[Abbreviation] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_MismanagementEnum] PRIMARY KEY CLUSTERED 
(
	[MismanagementEnumId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Hashers].[HasherEventMap]    Script Date: 4/21/19 7:11:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Hashers].[HasherEventMap](
	[id] [nvarchar](255) NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Hashers].[HasherFriendMap]    Script Date: 4/21/19 7:11:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Hashers].[HasherFriendMap](
	[id] [nvarchar](255) NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[BusinessUnits]    Script Date: 4/21/19 7:11:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[BusinessUnits](
	[id] [nvarchar](255) NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[ErrorLog]    Script Date: 4/21/19 7:11:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[FeaturedEvent]    Script Date: 4/21/19 7:11:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[FeaturedEvent](
	[id] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NOT NULL,
	[StartDate] [datetime] NOT NULL,
 CONSTRAINT [PK_FeaturedEvent] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[FeaturedKennel]    Script Date: 4/21/19 7:11:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[FeaturedKennel](
	[id] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[StartDate] [datetime] NOT NULL,
 CONSTRAINT [PK_FeaturedKennel] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[FeaturedSong]    Script Date: 4/21/19 7:12:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[FeaturedSong](
	[id] [uniqueidentifier] NOT NULL,
	[SongId] [uniqueidentifier] NOT NULL,
	[StartDate] [datetime] NOT NULL,
 CONSTRAINT [PK_FeaturedSong] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[Haberdashery]    Script Date: 4/21/19 7:12:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[Haberdashery](
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[HasherFriendMap]    Script Date: 4/21/19 7:12:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[HasherFriendMap](
	[id] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[Friend_UserId] [uniqueidentifier] NOT NULL,
	[Ignore] [smallint] NOT NULL,
	[FriendSince] [datetime] NULL,
 CONSTRAINT [PK_HasherFriendMap] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[HasherKennelMap]    Script Date: 4/21/19 7:12:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[HasherKennelMap](
	[id] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[Following] [smallint] NOT NULL,
	[IsMember] [smallint] NOT NULL,
	[MismanagementRoleFlags] [int] NOT NULL,
	[AppAccessFlags] [int] NOT NULL,
	[HistoricalPackRunCount] [smallint] NOT NULL,
	[HistoricalHaringCount] [smallint] NOT NULL,
	[CurrentPackRunCount] [smallint] NOT NULL,
	[CurrentHaringCount] [smallint] NOT NULL,
	[MemberSince] [datetime] NULL,
	[CanEditRunAttendence] [smallint] NOT NULL,
	[removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_HasherKennelMap] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[KennelAuthorization]    Script Date: 4/21/19 7:12:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[KennelSongMap]    Script Date: 4/21/19 7:12:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[KennelSongMap](
	[id] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[SongId] [uniqueidentifier] NOT NULL,
	[Following] [smallint] NOT NULL,
 CONSTRAINT [PK_KennelSongMap] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[LaunchAndLogin]    Script Date: 4/21/19 7:12:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[LaunchAndLogin](
	[id] [uniqueidentifier] NOT NULL,
	[LoginDate] [datetime] NOT NULL,
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
	[Longitude] [decimal](19, 15) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[LoginNotifications]    Script Date: 4/21/19 7:12:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[LoginNotifications](
	[id] [uniqueidentifier] NOT NULL,
	[ServerStatusCode] [smallint] NOT NULL,
	[LoginMessageTitle] [nvarchar](120) NOT NULL,
	[LoginMessage] [nvarchar](500) NOT NULL,
	[MessageWindowOpens] [datetime] NOT NULL,
	[MessageWindowCloses] [datetime] NOT NULL,
	[MessageDisplayType] [smallint] NOT NULL,
	[MessageImageUrl] [nvarchar](500) NULL,
	[CreatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_ServerMaintenanceWindow] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[Meetings]    Script Date: 4/21/19 7:12:01 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[Meetings](
	[id] [nvarchar](255) NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
	[deleted] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[Receipt]    Script Date: 4/21/19 7:12:01 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[Receipt](
	[id] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NOT NULL,
	[ReceiptAmount] [decimal](12, 4) NOT NULL,
	[CostCategory] [smallint] NOT NULL,
	[DateUploaded] [datetimeoffset](7) NOT NULL,
	[ImageUrl] [nvarchar](500) NOT NULL,
	[ReceiptShortDesc] [nvarchar](255) NULL,
 CONSTRAINT [PK_Receipt] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[Region]    Script Date: 4/21/19 7:12:01 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[ServerStatus]    Script Date: 4/21/19 7:12:01 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[ServerStatus](
	[id] [uniqueidentifier] NOT NULL,
	[ApiVersion] [nvarchar](25) NOT NULL,
	[LastGazetteerUpdate] [datetime] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_ServerStatus] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[Song]    Script Date: 4/21/19 7:12:01 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[Song](
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Kennels].[Haberdashery]    Script Date: 4/21/19 7:12:01 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Kennels].[Mismanagement]    Script Date: 4/21/19 7:12:01 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Transactions].[EventRegistration]    Script Date: 4/21/19 7:12:01 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Transactions].[HaberdasherySale]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Transactions].[HaberdasherySale](
	[HaberdasherySaleId] [uniqueidentifier] NOT NULL,
	[HaberdasheryId] [uniqueidentifier] NOT NULL,
	[HasherId] [uniqueidentifier] NULL,
	[SaleAmount] [money] NULL,
 CONSTRAINT [PK_HaberdasherySale] PRIMARY KEY CLUSTERED 
(
	[HaberdasherySaleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Exceptions_App_Del_Cre]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE NONCLUSTERED INDEX [IX_Exceptions_App_Del_Cre] ON [dbo].[Exceptions]
(
	[ApplicationName] ASC,
	[DeletionDate] ASC,
	[CreationDate] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Exceptions_GUID_App_Del_Cre]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE NONCLUSTERED INDEX [IX_Exceptions_GUID_App_Del_Cre] ON [dbo].[Exceptions]
(
	[GUID] ASC,
	[ApplicationName] ASC,
	[DeletionDate] ASC,
	[CreationDate] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Exceptions_Hash_App_Cre_Del]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE NONCLUSTERED INDEX [IX_Exceptions_Hash_App_Cre_Del] ON [dbo].[Exceptions]
(
	[ErrorHash] ASC,
	[ApplicationName] ASC,
	[CreationDate] DESC,
	[DeletionDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_RolePerm_RoleId_PermKey]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_RolePerm_RoleId_PermKey] ON [dbo].[RolePermissions]
(
	[RoleId] ASC,
	[PermissionKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_UserPerm_UserId_PermKey]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_UserPerm_UserId_PermKey] ON [dbo].[UserPermissions]
(
	[UserId] ASC,
	[PermissionKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_UserPref_UID_PrefType_Name]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_UserPref_UID_PrefType_Name] ON [dbo].[UserPreferences]
(
	[UserId] ASC,
	[PreferenceType] ASC,
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_UserRoles_RoleId_UserId]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE NONCLUSTERED INDEX [IX_UserRoles_RoleId_UserId] ON [dbo].[UserRoles]
(
	[RoleId] ASC,
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [UQ_UserRoles_UserId_RoleId]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_UserRoles_UserId_RoleId] ON [dbo].[UserRoles]
(
	[UserId] ASC,
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_CityUpdated]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE NONCLUSTERED INDEX [IX_CityUpdated] ON [HC].[City]
(
	[updatedAt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_CountryUpdated]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE NONCLUSTERED INDEX [IX_CountryUpdated] ON [HC].[Country]
(
	[updatedAt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Event_KidIsCountedDeleted2]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE NONCLUSTERED INDEX [IX_Event_KidIsCountedDeleted2] ON [HC].[Event]
(
	[KennelId] ASC,
	[IsCountedRun] ASC,
	[deleted] ASC
)
INCLUDE ( 	[AbsoluteEventNumber]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_EventByKennelIsCountedStartDateAbsEvtNum]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE NONCLUSTERED INDEX [IX_EventByKennelIsCountedStartDateAbsEvtNum] ON [HC].[Event]
(
	[KennelId] ASC,
	[IsCountedRun] ASC,
	[EventStartDatetime] ASC,
	[AbsoluteEventNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_HasherEventMap]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_HasherEventMap] ON [HC].[HasherEventMap]
(
	[EventId] ASC,
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_HasherFriendMap]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_HasherFriendMap] ON [HC].[HasherFriendMap]
(
	[UserId] ASC,
	[Friend_UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_HasherKennelMap]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_HasherKennelMap] ON [HC].[HasherKennelMap]
(
	[KennelId] ASC,
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_KennelSongMap]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_KennelSongMap] ON [HC].[KennelSongMap]
(
	[KennelId] ASC,
	[SongId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_RegionUpdated]    Script Date: 4/21/19 7:12:02 PM ******/
CREATE NONCLUSTERED INDEX [IX_RegionUpdated] ON [HC].[Region]
(
	[updatedAt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BusinessUnits] ADD  CONSTRAINT [DF_BusinessUnits_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [dbo].[BusinessUnits] ADD  CONSTRAINT [DF__BusinessU__delet__793DFFAF]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[BusinessUnits] ADD  CONSTRAINT [DF__BusinessU__creat__01D345B0]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
GO
ALTER TABLE [dbo].[BusinessUnits] ADD  CONSTRAINT [DF__BusinessU__updat__02C769E9]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
GO
ALTER TABLE [dbo].[Exceptions] ADD  CONSTRAINT [DF_Exceptions_IsProtected]  DEFAULT ((1)) FOR [IsProtected]
GO
ALTER TABLE [dbo].[Exceptions] ADD  CONSTRAINT [DF_Exceptions_DuplicateCount]  DEFAULT ((1)) FOR [DuplicateCount]
GO
ALTER TABLE [dbo].[Hasher] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
GO
ALTER TABLE [dbo].[Hasher] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
GO
ALTER TABLE [dbo].[Hasher] ADD  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[Meetings] ADD  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [dbo].[Meetings] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
GO
ALTER TABLE [dbo].[Meetings] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
GO
ALTER TABLE [dbo].[UserPermissions] ADD  CONSTRAINT [DF_UserPermissions_Grant]  DEFAULT ((1)) FOR [Granted]
GO
ALTER TABLE [dbo].[Users] ADD  CONSTRAINT [DF_Users_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [city]
GO
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [city_ascii]
GO
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [lat]
GO
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [lng]
GO
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [pop]
GO
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [country]
GO
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [iso2]
GO
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [iso3]
GO
ALTER TABLE [dbo].[world_cities_table] ADD  DEFAULT (NULL) FOR [province]
GO
ALTER TABLE [Hashers].[HasherEventMap] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
GO
ALTER TABLE [Hashers].[HasherEventMap] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
GO
ALTER TABLE [Hashers].[HasherEventMap] ADD  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [Hashers].[HasherFriendMap] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
GO
ALTER TABLE [Hashers].[HasherFriendMap] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
GO
ALTER TABLE [Hashers].[HasherFriendMap] ADD  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [HC].[BusinessUnits] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
GO
ALTER TABLE [HC].[BusinessUnits] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
GO
ALTER TABLE [HC].[BusinessUnits] ADD  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [HC].[City] ADD  CONSTRAINT [DF_City_Removed]  DEFAULT ((0)) FOR [Removed]
GO
ALTER TABLE [HC].[City] ADD  CONSTRAINT [DF_City_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
GO
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_CountryId]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_PrimaryCultureCode]  DEFAULT (N'en-US') FOR [PrimaryCultureCode]
GO
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_ShowRegion]  DEFAULT ((0)) FOR [ShowRegion]
GO
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_CurrencySymbol]  DEFAULT (' ') FOR [CurrencySymbol]
GO
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_DigitsAfterDecimal]  DEFAULT ((2)) FOR [DigitsAfterDecimal]
GO
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_Removed]  DEFAULT ((0)) FOR [Removed]
GO
ALTER TABLE [HC].[Country] ADD  CONSTRAINT [DF_Country_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
GO
ALTER TABLE [HC].[ErrorLog] ADD  CONSTRAINT [DF_ErrorLog_HasherId]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[ErrorLog] ADD  CONSTRAINT [DF_ErrorLog_HcVersion]  DEFAULT (N'pre 0.6.4') FOR [HcVersion]
GO
ALTER TABLE [HC].[ErrorLog] ADD  CONSTRAINT [DF_ErrorLog_createdA__2AC04CAA]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
GO
ALTER TABLE [HC].[ErrorLog] ADD  CONSTRAINT [DF_ErrorLog_updatedA__2BB470E3]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
GO
ALTER TABLE [HC].[ErrorLog] ADD  CONSTRAINT [DF_ErrorLog_deleted__2CA8951C]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_HC_Event_EventId]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_IsVisible]  DEFAULT ((1)) FOR [IsVisible]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_IsCountedRun]  DEFAULT ((1)) FOR [IsCountedRun]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_IsPromotedRun]  DEFAULT ((0)) FOR [IsPromotedEvent]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_EventGeographicScope]  DEFAULT ((0)) FOR [EventGeographicScope]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_HC_Event_IsThemeRun]  DEFAULT ((0)) FOR [ThemeRunType]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_EventNumber]  DEFAULT ((0)) FOR [EventNumber]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_RunCount]  DEFAULT ((1)) FOR [EventNumberIncrement]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_EventScope]  DEFAULT ((0)) FOR [EventScope]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_UserCountIncrement]  DEFAULT ((1)) FOR [UserEventCounterIncrement]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_HC_Event_EventFlags]  DEFAULT ((0)) FOR [EventFlagsA]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_HC_Event_EventFlagsB]  DEFAULT ((0)) FOR [EventFlagsB]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_EventComplete]  DEFAULT ((0)) FOR [EventComplete]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_HC_Event_MinimumRequired]  DEFAULT ((1)) FOR [MinimumParticipantsRequired]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_CanEditRunAttendence]  DEFAULT ((1)) FOR [CanEditRunAttendence]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF__Event__deleted__22CA2527]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_lastModified]  DEFAULT (getdate()) FOR [lastModified]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF__Event__createdAt__414EAC47]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF__Event__updatedAt__4242D080]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
GO
ALTER TABLE [HC].[FeaturedEvent] ADD  CONSTRAINT [DF_FeaturedEvent_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[FeaturedKennel] ADD  CONSTRAINT [DF_FeaturedKennel_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[FeaturedSong] ADD  CONSTRAINT [DF_FeaturedSong_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_Price]  DEFAULT ((0)) FOR [Price]
GO
ALTER TABLE [HC].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_InStock]  DEFAULT ((1)) FOR [InStock]
GO
ALTER TABLE [HC].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_Archive]  DEFAULT ((0)) FOR [Archive]
GO
ALTER TABLE [HC].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_ShowOnHomePage]  DEFAULT ((0)) FOR [ShowOnHomePage]
GO
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_HasherId]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_SupportCode]  DEFAULT (N'#####') FOR [SupportCode]
GO
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_ResetCode]  DEFAULT (N'######') FOR [ResetCode]
GO
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_QR_code]  DEFAULT (N'######') FOR [QR_code]
GO
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_QR_secret_code]  DEFAULT (newid()) FOR [QR_secret_code]
GO
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_HomeLatitude]  DEFAULT ((51.5033)) FOR [HomeLatitude]
GO
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_HomeLongitude]  DEFAULT ((0.1195)) FOR [HomeLongitude]
GO
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_NameDisplayPreference]  DEFAULT ((1)) FOR [NameDisplayPreference]
GO
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF_Hasher_Removed]  DEFAULT ((0)) FOR [Removed]
GO
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF__Hasher__createdA__2AC04CAA]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
GO
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF__Hasher__updatedA__2BB470E3]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
GO
ALTER TABLE [HC].[Hasher] ADD  CONSTRAINT [DF__Hasher__deleted__2CA8951C]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_HasherEventMapId]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_RsvpState]  DEFAULT ((0)) FOR [RsvpState]
GO
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_AttendenceState]  DEFAULT ((0)) FOR [AttendenceState]
GO
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF__HasherEve__IsHar__6E565CE8]  DEFAULT ((0)) FOR [IsHare]
GO
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_IsVirgin]  DEFAULT ((0)) FOR [VirginVisitorType]
GO
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_TotalHaringThisKennel]  DEFAULT ((0)) FOR [TotalHaringThisKennel]
GO
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_TotalPackRunsThisKennel]  DEFAULT ((0)) FOR [TotalPackRunsThisKennel]
GO
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_TotalRunsThisKennel]  DEFAULT ((0)) FOR [TotalRunsThisKennel]
GO
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_TotalHaringRunsAllKennels]  DEFAULT ((0)) FOR [TotalHaringAllKennels]
GO
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_TotalPackRunsAllKennels]  DEFAULT ((0)) FOR [TotalPackRunsAllKennels]
GO
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_TotalRunsAllKennels]  DEFAULT ((0)) FOR [TotalRunsAllKennels]
GO
ALTER TABLE [HC].[HasherFriendMap] ADD  CONSTRAINT [DF_HasherFriendMap_Id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[HasherFriendMap] ADD  CONSTRAINT [DF_HasherFriendMap_State]  DEFAULT ((0)) FOR [Ignore]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_HasherId]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_Following]  DEFAULT ((1)) FOR [Following]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_State]  DEFAULT ((0)) FOR [IsMember]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_IsMismanagement]  DEFAULT ((0)) FOR [MismanagementRoleFlags]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_AppAccessFlags]  DEFAULT ((0)) FOR [AppAccessFlags]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_HistoricalRunCount]  DEFAULT ((0)) FOR [HistoricalPackRunCount]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_HistoricalHaringCount]  DEFAULT ((0)) FOR [HistoricalHaringCount]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_CurrentPackRunCount]  DEFAULT ((0)) FOR [CurrentPackRunCount]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_CurrentHaringCount]  DEFAULT ((0)) FOR [CurrentHaringCount]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_MemberSince]  DEFAULT (getdate()) FOR [MemberSince]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_CanEditRunAttendence]  DEFAULT ((1)) FOR [CanEditRunAttendence]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_removed]  DEFAULT ((0)) FOR [removed]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_KennelStatus]  DEFAULT ((1)) FOR [KennelStatus]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_KennelFacebookImportDaysInPast]  DEFAULT ((4)) FOR [KennelFacebookImportDaysInPast]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_KennelFacebookImportDaysInFuture]  DEFAULT ((90)) FOR [KennelFacebookImportDaysInFuture]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_AutoImportFacebookEvents]  DEFAULT ((0)) FOR [AutoImportFacebookEvents]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_ImportOnlyTaggedEvents]  DEFAULT ((0)) FOR [ImportOnlyTaggedEvents]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_CanEditRunAttendence]  DEFAULT ((1)) FOR [CanEditRunAttendence]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_KennelLogo]  DEFAULT (N'bundle://defaultKennelLogo') FOR [KennelLogo]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_DefaultRunStartTime]  DEFAULT ('12:00:00.0000000') FOR [DefaultRunStartTime]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_AllowNegativeCredit]  DEFAULT ((0)) FOR [AllowNegativeCredit]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_removed]  DEFAULT ((0)) FOR [removed]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF__Kennel__createdA__338A9CD5]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF__Kennel__updatedA__347EC10E]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF__Kennel__deleted__3572E547]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_AutoFacebookEventImport]  DEFAULT ((0)) FOR [Auth_FacebookIntegration]
GO
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_TrackPayments]  DEFAULT ((0)) FOR [Auth_TrackPayments]
GO
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_Haberdashery]  DEFAULT ((0)) FOR [Auth_Haberdashery]
GO
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_CustomSongbook]  DEFAULT ((0)) FOR [Auth_CustomSongbook]
GO
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_WebsiteIntegration]  DEFAULT ((0)) FOR [Auth_WebsiteIntegration]
GO
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_AllowCredit]  DEFAULT ((0)) FOR [Auth_AllowCredit]
GO
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_PushNotifications]  DEFAULT ((0)) FOR [Auth_PushNotifications]
GO
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_CheckInAndOut]  DEFAULT ((0)) FOR [Auth_CheckInAndOut]
GO
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_PromoteEvents]  DEFAULT ((0)) FOR [Auth_PromoteEvents]
GO
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_CustomLogo]  DEFAULT ((0)) FOR [Auth_CustomLogo]
GO
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_AuthorizationAmount]  DEFAULT ((10)) FOR [Auth_MembersAllowed]
GO
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_HareRaisingManagement]  DEFAULT ((0)) FOR [Auth_HareRaisingManagement]
GO
ALTER TABLE [HC].[KennelAuthorization] ADD  CONSTRAINT [DF_KennelAuthorization_StartDate]  DEFAULT (getdate()) FOR [StartDate]
GO
ALTER TABLE [HC].[KennelSongMap] ADD  CONSTRAINT [DF_KennelSongMap_Id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[KennelSongMap] ADD  CONSTRAINT [DF_KennelSongMap_Following]  DEFAULT ((1)) FOR [Following]
GO
ALTER TABLE [HC].[LaunchAndLogin] ADD  CONSTRAINT [DF_LaunchAndLogin_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[LaunchAndLogin] ADD  CONSTRAINT [DF_LaunchAndLogin_DateAndTime]  DEFAULT (getdate()) FOR [LoginDate]
GO
ALTER TABLE [HC].[LaunchAndLogin] ADD  CONSTRAINT [DF_LaunchAndLogin_HcVersion]  DEFAULT (N'pre 0.6.4') FOR [HcVersion]
GO
ALTER TABLE [HC].[LoginNotifications] ADD  CONSTRAINT [DF_ServerMaintenanceWindow_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[LoginNotifications] ADD  CONSTRAINT [DF_ServerMaintenanceWindow_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [HC].[Meetings] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
GO
ALTER TABLE [HC].[Meetings] ADD  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
GO
ALTER TABLE [HC].[Meetings] ADD  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_CreditAmount]  DEFAULT ((0)) FOR [CreditAmount]
GO
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_DebitAmount]  DEFAULT ((0)) FOR [DebitAmount]
GO
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_PaidDate]  DEFAULT (getdate()) FOR [PaidDate]
GO
ALTER TABLE [HC].[Receipt] ADD  CONSTRAINT [DF_Receipt_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[Receipt] ADD  CONSTRAINT [DF_Receipt_CostCategory]  DEFAULT ((0)) FOR [CostCategory]
GO
ALTER TABLE [HC].[Receipt] ADD  CONSTRAINT [DF_Receipt_DateUploaded]  DEFAULT (getdate()) FOR [DateUploaded]
GO
ALTER TABLE [HC].[Region] ADD  CONSTRAINT [DF_Region_Removed]  DEFAULT ((0)) FOR [Removed]
GO
ALTER TABLE [HC].[Region] ADD  CONSTRAINT [DF_Region_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
GO
ALTER TABLE [HC].[ServerStatus] ADD  CONSTRAINT [DF_ServerStatus_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[ServerStatus] ADD  CONSTRAINT [DF_ServerStatus_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [HC].[Song] ADD  CONSTRAINT [DF_Song_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[Song] ADD  CONSTRAINT [DF_Song_Rating]  DEFAULT ((1)) FOR [BawdyRating]
GO
ALTER TABLE [HC].[Song] ADD  CONSTRAINT [DF_Song_AutoAddToKennel]  DEFAULT ((0)) FOR [AutoAddToKennel]
GO
ALTER TABLE [HC].[Song] ADD  CONSTRAINT [DF_Song_Rank]  DEFAULT ((0)) FOR [Rank]
GO
ALTER TABLE [Kennels].[Mismanagement] ADD  CONSTRAINT [DF_Mismanagement_MismanagementId]  DEFAULT (newid()) FOR [MismanagementId]
GO
ALTER TABLE [Transactions].[EventRegistration] ADD  CONSTRAINT [DF_EventRegistration_DateRegistered]  DEFAULT (getdate()) FOR [DateRegistered]
GO
ALTER TABLE [dbo].[Contacts]  WITH CHECK ADD  CONSTRAINT [FK_Contacts_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
GO
ALTER TABLE [dbo].[Contacts] CHECK CONSTRAINT [FK_Contacts_UserId]
GO
ALTER TABLE [dbo].[MeetingAgendaRelevant]  WITH CHECK ADD  CONSTRAINT [FK_AgendaRel_AgendaId] FOREIGN KEY([AgendaId])
REFERENCES [dbo].[MeetingAgendas] ([AgendaId])
GO
ALTER TABLE [dbo].[MeetingAgendaRelevant] CHECK CONSTRAINT [FK_AgendaRel_AgendaId]
GO
ALTER TABLE [dbo].[MeetingAgendaRelevant]  WITH CHECK ADD  CONSTRAINT [FK_AgendaRel_ContactId] FOREIGN KEY([ContactId])
REFERENCES [dbo].[Contacts] ([ContactId])
GO
ALTER TABLE [dbo].[MeetingAgendaRelevant] CHECK CONSTRAINT [FK_AgendaRel_ContactId]
GO
ALTER TABLE [dbo].[MeetingAgendas]  WITH CHECK ADD  CONSTRAINT [FK_MeetAgendas_AgendaTypeId] FOREIGN KEY([AgendaTypeId])
REFERENCES [dbo].[MeetingAgendaTypes] ([AgendaTypeId])
GO
ALTER TABLE [dbo].[MeetingAgendas] CHECK CONSTRAINT [FK_MeetAgendas_AgendaTypeId]
GO
ALTER TABLE [dbo].[MeetingAgendas]  WITH CHECK ADD  CONSTRAINT [FK_MeetAgendas_MeetingId] FOREIGN KEY([MeetingId])
REFERENCES [dbo].[Meetings] ([MeetingId])
GO
ALTER TABLE [dbo].[MeetingAgendas] CHECK CONSTRAINT [FK_MeetAgendas_MeetingId]
GO
ALTER TABLE [dbo].[MeetingAgendas]  WITH CHECK ADD  CONSTRAINT [FK_MeetAgendas_RequestedBy] FOREIGN KEY([RequestedByContactId])
REFERENCES [dbo].[Contacts] ([ContactId])
GO
ALTER TABLE [dbo].[MeetingAgendas] CHECK CONSTRAINT [FK_MeetAgendas_RequestedBy]
GO
ALTER TABLE [dbo].[MeetingAttendees]  WITH CHECK ADD  CONSTRAINT [FK_MeetAttendees_ContactId] FOREIGN KEY([ContactId])
REFERENCES [dbo].[Contacts] ([ContactId])
GO
ALTER TABLE [dbo].[MeetingAttendees] CHECK CONSTRAINT [FK_MeetAttendees_ContactId]
GO
ALTER TABLE [dbo].[MeetingAttendees]  WITH CHECK ADD  CONSTRAINT [FK_MeetAttendees_MeetingId] FOREIGN KEY([MeetingId])
REFERENCES [dbo].[Meetings] ([MeetingId])
GO
ALTER TABLE [dbo].[MeetingAttendees] CHECK CONSTRAINT [FK_MeetAttendees_MeetingId]
GO
ALTER TABLE [dbo].[MeetingDecisionRelevant]  WITH CHECK ADD  CONSTRAINT [FK_DecisionRel_ContactId] FOREIGN KEY([ContactId])
REFERENCES [dbo].[Contacts] ([ContactId])
GO
ALTER TABLE [dbo].[MeetingDecisionRelevant] CHECK CONSTRAINT [FK_DecisionRel_ContactId]
GO
ALTER TABLE [dbo].[MeetingDecisionRelevant]  WITH CHECK ADD  CONSTRAINT [FK_DecisionRel_DecisionId] FOREIGN KEY([DecisionId])
REFERENCES [dbo].[MeetingDecisions] ([DecisionId])
GO
ALTER TABLE [dbo].[MeetingDecisionRelevant] CHECK CONSTRAINT [FK_DecisionRel_DecisionId]
GO
ALTER TABLE [dbo].[MeetingDecisions]  WITH CHECK ADD  CONSTRAINT [FK_MeetDecisions_AgendaId] FOREIGN KEY([AgendaId])
REFERENCES [dbo].[MeetingAgendas] ([AgendaId])
GO
ALTER TABLE [dbo].[MeetingDecisions] CHECK CONSTRAINT [FK_MeetDecisions_AgendaId]
GO
ALTER TABLE [dbo].[MeetingDecisions]  WITH CHECK ADD  CONSTRAINT [FK_MeetDecisions_AgendaType] FOREIGN KEY([DecisionNumber])
REFERENCES [dbo].[MeetingAgendaTypes] ([AgendaTypeId])
GO
ALTER TABLE [dbo].[MeetingDecisions] CHECK CONSTRAINT [FK_MeetDecisions_AgendaType]
GO
ALTER TABLE [dbo].[MeetingDecisions]  WITH CHECK ADD  CONSTRAINT [FK_MeetDecisions_MeetingId] FOREIGN KEY([MeetingId])
REFERENCES [dbo].[Meetings] ([MeetingId])
GO
ALTER TABLE [dbo].[MeetingDecisions] CHECK CONSTRAINT [FK_MeetDecisions_MeetingId]
GO
ALTER TABLE [dbo].[MeetingDecisions]  WITH CHECK ADD  CONSTRAINT [FK_MeetDecisions_RequestedBy] FOREIGN KEY([ResponsibleContactId])
REFERENCES [dbo].[Contacts] ([ContactId])
GO
ALTER TABLE [dbo].[MeetingDecisions] CHECK CONSTRAINT [FK_MeetDecisions_RequestedBy]
GO
ALTER TABLE [dbo].[Meetings]  WITH CHECK ADD  CONSTRAINT [FK_Meetings_LocationId] FOREIGN KEY([LocationId])
REFERENCES [dbo].[MeetingLocations] ([LocationId])
GO
ALTER TABLE [dbo].[Meetings] CHECK CONSTRAINT [FK_Meetings_LocationId]
GO
ALTER TABLE [dbo].[Meetings]  WITH CHECK ADD  CONSTRAINT [FK_Meetings_Organizer] FOREIGN KEY([OrganizerContactId])
REFERENCES [dbo].[Contacts] ([ContactId])
GO
ALTER TABLE [dbo].[Meetings] CHECK CONSTRAINT [FK_Meetings_Organizer]
GO
ALTER TABLE [dbo].[Meetings]  WITH CHECK ADD  CONSTRAINT [FK_Meetings_Reporter] FOREIGN KEY([ReporterContactId])
REFERENCES [dbo].[Contacts] ([ContactId])
GO
ALTER TABLE [dbo].[Meetings] CHECK CONSTRAINT [FK_Meetings_Reporter]
GO
ALTER TABLE [dbo].[Meetings]  WITH CHECK ADD  CONSTRAINT [FK_Meetings_TypeId] FOREIGN KEY([MeetingTypeId])
REFERENCES [dbo].[MeetingTypes] ([MeetingTypeId])
GO
ALTER TABLE [dbo].[Meetings] CHECK CONSTRAINT [FK_Meetings_TypeId]
GO
ALTER TABLE [dbo].[RolePermissions]  WITH CHECK ADD  CONSTRAINT [FK_RolePermissions_RoleId] FOREIGN KEY([RoleId])
REFERENCES [dbo].[Roles] ([RoleId])
GO
ALTER TABLE [dbo].[RolePermissions] CHECK CONSTRAINT [FK_RolePermissions_RoleId]
GO
ALTER TABLE [dbo].[UserPermissions]  WITH CHECK ADD  CONSTRAINT [FK_UserPermissions_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserPermissions] CHECK CONSTRAINT [FK_UserPermissions_UserId]
GO
ALTER TABLE [dbo].[UserRoles]  WITH CHECK ADD  CONSTRAINT [FK_UserRoles_RoleId] FOREIGN KEY([RoleId])
REFERENCES [dbo].[Roles] ([RoleId])
GO
ALTER TABLE [dbo].[UserRoles] CHECK CONSTRAINT [FK_UserRoles_RoleId]
GO
ALTER TABLE [dbo].[UserRoles]  WITH CHECK ADD  CONSTRAINT [FK_UserRoles_UserId] FOREIGN KEY([UserId])
REFERENCES [dbo].[Users] ([UserId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UserRoles] CHECK CONSTRAINT [FK_UserRoles_UserId]
GO
ALTER TABLE [HC].[Kennel]  WITH CHECK ADD  CONSTRAINT [FK_Kennel_KennelStatusEnum] FOREIGN KEY([KennelStatus])
REFERENCES [DomainValues].[KennelStatusEnum] ([KennelStatusEnumId])
GO
ALTER TABLE [HC].[Kennel] CHECK CONSTRAINT [FK_Kennel_KennelStatusEnum]
GO
ALTER TABLE [Kennels].[Mismanagement]  WITH CHECK ADD  CONSTRAINT [FK_Mismanagement_Hasher] FOREIGN KEY([HasherId])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [Kennels].[Mismanagement] CHECK CONSTRAINT [FK_Mismanagement_Hasher]
GO
ALTER TABLE [Kennels].[Mismanagement]  WITH CHECK ADD  CONSTRAINT [FK_Mismanagement_MismanagementEnum] FOREIGN KEY([MismanagementEnumId])
REFERENCES [DomainValues].[MismanagementEnum] ([MismanagementEnumId])
GO
ALTER TABLE [Kennels].[Mismanagement] CHECK CONSTRAINT [FK_Mismanagement_MismanagementEnum]
GO
ALTER TABLE [Transactions].[EventRegistration]  WITH CHECK ADD  CONSTRAINT [FK_EventRegistration_Hasher] FOREIGN KEY([HasherId])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [Transactions].[EventRegistration] CHECK CONSTRAINT [FK_EventRegistration_Hasher]
GO
ALTER TABLE [Transactions].[HaberdasherySale]  WITH CHECK ADD  CONSTRAINT [FK_HaberdasherySale_Haberdashery] FOREIGN KEY([HaberdasheryId])
REFERENCES [Kennels].[Haberdashery] ([HaberdasheryId])
GO
ALTER TABLE [Transactions].[HaberdasherySale] CHECK CONSTRAINT [FK_HaberdasherySale_Haberdashery]
GO
ALTER TABLE [Transactions].[HaberdasherySale]  WITH CHECK ADD  CONSTRAINT [FK_HaberdasherySale_Hasher] FOREIGN KEY([HasherId])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [Transactions].[HaberdasherySale] CHECK CONSTRAINT [FK_HaberdasherySale_Hasher]
GO
/****** Object:  StoredProcedure [dbo].[sp_alterdiagram]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_alterdiagram]
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
/****** Object:  StoredProcedure [dbo].[sp_creatediagram]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_creatediagram]
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
/****** Object:  StoredProcedure [dbo].[sp_dropdiagram]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_dropdiagram]
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
/****** Object:  StoredProcedure [dbo].[sp_helpdiagramdefinition]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_helpdiagramdefinition]
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
/****** Object:  StoredProcedure [dbo].[sp_helpdiagrams]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_helpdiagrams]
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
/****** Object:  StoredProcedure [dbo].[sp_renamediagram]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_renamediagram]
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
/****** Object:  StoredProcedure [dbo].[sp_upgraddiagrams]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	CREATE PROCEDURE [dbo].[sp_upgraddiagrams]
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
/****** Object:  StoredProcedure [HC].[addEditEvent]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC].[addEditEvent]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @eventId uniqueidentifier = null,
 @kennelId uniqueidentifier = null,
 @startDatetime datetime = null,
 @endDatetime datetime = null,
 @isCountedRun smallint = null,
 @isVisible smallint = null,
 @isPromotedEvent smallint = null,
 @eventGeographicScope smallint = null,
 @ThemeRunType smallint = null,
 @eventName nvarchar(120) = null,
 @eventDescription nvarchar(4000) = null,
 @eventShortDescription nvarchar(250) = null,
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

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END
	
	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END




-- EXEC HC.addEditEvent @userId = '83294c62-2ffe-4fcb-a2f5-52aadd6ceaa0',@accessToken='',@eventId='00000000-0000-0000-0000-000000000000',@kennelId='5029de3a-d231-47aa-be72-ece9bccd55d1',@startDatetime='4/13/2018 12:00:00 AM',@endDatetime='',@eventName='FILTH-xx',@eventFacebookId='1234567890'



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
	if (DATALENGTH(@eventShortDescription) < 1) SET @eventShortDescription = NULL
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

	set @resultStr = '00000000-0000-0000-0000-000000000000'
	set @resultInt = -1

	if (@eventFacebookId like '%break%') SET @eventFacebookId = ''


    if ((@deleted IS NOT NULL) AND (@deleted = 1))
	BEGIN
		-- use the kennel id and date if we don't have an eventId
		if ((@eventId = '00000000-0000-0000-0000-000000000000') OR (@eventId is null))
		BEGIN
			select top 1 @eventId = id from HC.Event WHERE KennelId = @kennelId AND cast(EventStartDatetime as Date) = cast(@startDatetime as Date)
		END

		if ((@eventId is not null) AND (@eventId <> '00000000-0000-0000-0000-000000000000'))
		BEGIN
			UPDATE HC.Event SET 
			deleted = 1
			FROM HC.Event e where e.id = @eventId

			set @resultStr = @eventId
			set @resultInt = 2
		END
			
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
			EventShortDesc = coalesce(@eventShortDescription, EventShortDesc),
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
			EventPriceForMembers = coalesce(@eventPriceForMembers,EventPriceForMembers),
			EventPriceForNonMembers = coalesce(@eventPriceForNonMembers,EventPriceForNonMembers),
			AbsoluteEventNumber = case when @absoluteEventNumber = 0 then null else coalesce(@absoluteEventNumber, AbsoluteEventNumber) end,
			EventCurrencyType = coalesce(@eventCurrencyType, EventCurrencyType),
			deleted = coalesce(@deleted, deleted)
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
					DECLARE @time time(7)
					SELECT @time = DefaultRunStartTime from HC.Kennel where id = @kennelId
					if (@time is not null) SET @startDateTime = @startDatetime + cast(@time as datetime)
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
						,EventShortDesc
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
						,EventPriceForMembers
						,EventPriceForNonMembers
						,AbsoluteEventNumber
						,EventCurrencyType,deleted
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
						,@eventShortDescription
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
						,@eventPriceForMembers
						,@eventPriceForNonMembers
						,@absoluteEventNumber
						,@eventCurrencyType,coalesce(@deleted,0)
					)

				SET @resultStr = 'Insert succeeded'
				SET @resultInt = 1
			END
		END
	END

	EXEC HC.nonApi_updateRunNumbers @eventId = @eventId

	UPDATE HC.Event SET lastModified = getdate() WHERE id = @eventId

    IF ((@fbLatitude is not null and @fbLongitude is not null) OR (@latitude is not null AND @longitude is not null))
	BEGIN
		UPDATE HC.Event Set EventGeolocation = geography::Point(coalesce(@latitude,@fbLatitude), coalesce(@longitude,@fbLongitude), 4326) FROM HC.Event
			WHERE id = @eventId
	END
	
	DECLARE @resultInt2 int
	SELECT @resultInt2 = e.EventNumber, @kennelId = e.KennelId from HC.Event e where e.id = @eventId

	SELECT @resultStr as ResultStr, @resultInt as ResultInt, @resultInt2 as ResultInt2

END






GO
/****** Object:  StoredProcedure [HC].[addEditKennel]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [HC].[addEditKennel]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @kennelId uniqueidentifier,
 @cityId uniqueidentifier = null,
 @status int = null,
 @kennelName nvarchar(500) = null,
 @kennelShortName nvarchar(50) = null,
 @kennelLogo nvarchar(500) = null,
 @webUrl nvarchar(500) = null,
 @latitude float = null,
 @longitude float = null,
 @description nvarchar(2500) = null,
 @facebookId nvarchar(100) = null,
 @facebookAccessToken nvarchar(1000) = null,
 @facebookAccessTokenUserId uniqueidentifier = null,
 @autoImportFacebookEvents smallint = null,
 @importOnlyTaggedFacebookEvents smallint = null,
 @tagForFacebookImport nvarchar(50) = null,
 @memberPrice float = null,
 @nonMemberPrice float = null,
 @defaultStartTime datetime = null,
 @defaultCurrencyType nvarchar(50) = null

AS

BEGIN

SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END
	
	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END


DECLARE @resultStr nvarchar(250)
DECLARE @resultInt int

if (@kennelId = '00000000-0000-0000-0000-000000000000') SET @kennelId = NULL
if (@cityId = '00000000-0000-0000-0000-000000000000') SET @cityId = NULL
if ((@defaultStartTime IS NOT NULL) AND (@defaultStartTime <= '1/1/1901')) SET @defaultStartTime = NULL
if (@status = -1) SET @status = NULL
if (DATALENGTH(@kennelName) < 1) SET @kennelName = NULL
if (DATALENGTH(@kennelShortName) < 1) SET @kennelShortName = NULL
if (DATALENGTH(@kennelLogo) < 1) SET @kennelLogo = NULL
if (DATALENGTH(@webUrl) < 4) SET @webUrl = NULL
if (DATALENGTH(@description) < 1) SET @description = NULL
if (DATALENGTH(@facebookId) < 1) SET @facebookId = NULL
if (@latitude = -1) SET @latitude = NULL
if (@longitude = -1) SET @longitude = NULL
if (@memberPrice = -1) SET @memberPrice = NULL
if (@nonMemberPrice = -1) SET @nonMemberPrice = NULL
if (DATALENGTH(@defaultCurrencyType) < 4) SET @defaultCurrencyType = NULL
if (@facebookAccessTokenUserId = '00000000-0000-0000-0000-000000000000') SET @facebookAccessTokenUserId = null
if (@autoImportFacebookEvents = -1) SET @autoImportFacebookEvents = NULL
if (@importOnlyTaggedFacebookEvents = -1) SET @importOnlyTaggedFacebookEvents = NULL

set @resultStr = '00000000-0000-0000-0000-000000000000'
set @resultInt = -1

	-- does a record exist? If so, we are in "edit" mode
	if ((@kennelId is not null) AND ((SELECT count(*) from HC.Kennel k where k.id = @kennelId) > 0))
		BEGIN
			UPDATE HC.Kennel SET 
			   [KennelStatus] = coalesce(@status,k.KennelStatus)
			  ,[CityId] = coalesce(@cityId,k.cityId)
			  ,[KennelName] = coalesce(@kennelName,k.KennelName)
			  ,[KennelFacebookId] = case when @facebookId='<delete>' then null else coalesce(@facebookId,k.KennelFacebookId) end
			  ,[KennelFacebookToken] = coalesce(@facebookAccessToken,k.KennelFacebookToken)
			  ,[KennelFacebookTokenUserId] = coalesce(@facebookAccessTokenUserId,k.KennelFacebookTokenUserId)
			  ,[AutoImportFacebookEvents] = coalesce(@autoImportFacebookEvents,k.[AutoImportFacebookEvents])
			  ,[ImportOnlyTaggedEvents] = coalesce(@importOnlyTaggedFacebookEvents,k.[ImportOnlyTaggedEvents])
			  ,[FacebookTagForImport] = coalesce(@tagForFacebookImport,k.[FacebookTagForImport])
			  ,[KennelFacebookTokenLastUpdated] = case when @facebookAccessToken is not null then getdate() else k.[KennelFacebookTokenLastUpdated] end
			  ,[KennelShortName] = coalesce(@kennelShortName,k.KennelShortName)
			  ,[KennelLogo] = coalesce(@kennelLogo,k.KennelLogo)
			  ,[KennelDescription] = coalesce(@description,k.KennelDescription)
			  ,[KennelWebsiteUrl] = coalesce(@webUrl,KennelWebsiteUrl)
			  ,[DefaultEventPriceForMembers] = coalesce(@memberPrice,cast(k.DefaultEventPriceForMembers as smallmoney))
			  ,[DefaultEventPriceForNonMembers] = coalesce(@nonMemberPrice,cast(k.DefaultEventPriceForNonMembers as smallmoney))
			  ,[DefaultEventCurrencyType] = coalesce(@defaultCurrencyType,k.DefaultEventCurrencyType)
			  ,[DefaultRunStartTime] = coalesce(@defaultStartTime,DefaultRunStartTime)
			  ,[Latitude] = coalesce(cast(@latitude as decimal(18,15)),Latitude)
			  ,[Longitude] = coalesce(cast(@longitude as decimal(19,15)),Longitude)
			FROM HC.Kennel k where k.id = @kennelId

			set @resultStr = 'Updated record ' + cast (@kennelId as nvarchar(50)) + ' set name to: ' + coalesce(@kennelName,'oops, it is null!')
			set @resultInt = 1
		END
		ELSE
		BEGIN

			if (datalength(Trim(@kennelName)) > 0)
			BEGIN

				if (@kennelId is null) SET @kennelId = newid()



				DECLARE @regionId uniqueidentifier
				DECLARE @countryId uniqueidentifier

				if (@cityId is null)
				BEGIN
					DECLARE @g geography
					SET @g = geography::Point(@latitude,@longitude,4326)
					SELECT TOP 1 @cityId = id FROM HC.City c 
					ORDER BY c.CityGeolocation.STDistance(@g) ASC
				END

				SELECT @regionId = c.RegionId from HC.City c where c.id = @cityId
				SELECT @countryId = r.CountryId from HC.Region r where r.id = @regionId

				INSERT INTO [HC].[Kennel]
						   ([id]
						   ,[KennelStatus]
						   ,[KennelName]
						   ,[KennelShortName]
						   ,[KennelLogo]
						   ,[KennelWebsiteUrl]
						   ,[Latitude]
						   ,[Longitude]
						   ,[CityId]
						   ,[ProvinceStateId]
						   ,[CountryId]
						   ,[KennelDescription]
						   ,[KennelFacebookId]
						   ,[KennelFacebookToken]
						   ,[KennelFacebookTokenUserId]
						   ,[KennelFacebookTokenLastUpdated]
						   ,[AutoImportFacebookEvents] 
						   ,[ImportOnlyTaggedEvents] 
						   ,[FacebookTagForImport]
						   ,[DefaultEventPriceForMembers]
						   ,[DefaultEventPriceForNonMembers]
						   ,[DefaultRunStartTime]
						   ,[DefaultEventCurrencyType]
						  )
					 VALUES
						   (
						    @kennelId
						   ,coalesce(@status,0)
						   ,@kennelName
						   ,@kennelShortName
						   ,@kennelLogo
						   ,@webUrl
						   ,cast(@latitude as decimal(18,15))
						   ,cast(@longitude as decimal(19,15))
						   ,@cityId
						   ,@regionId
						   ,@countryId
						   ,@description
						   ,case when @facebookId = '<none>' then null else @facebookId end
						   ,@facebookAccessToken
						   ,@facebookAccessTokenUserId
						   ,case when @facebookAccessToken is null then null else getdate() end
						   ,@autoImportFacebookEvents
						   ,@importOnlyTaggedFacebookEvents
						   ,@tagForFacebookImport
						   ,coalesce(cast(@memberPrice as smallmoney),0)
						   ,coalesce(cast(@nonMemberPrice as smallmoney),0)
						   ,coalesce(@defaultStartTime,'1/1/2000 12:00:00')
						   ,coalesce(@defaultCurrencyType,'nl-NL')
						   )

				SET @resultStr = 'Insert succeeded'
				SET @resultInt = 1
			END
		END
	


	SELECT @resultStr as ResultStr, @resultInt as ResultInt

END






GO
/****** Object:  StoredProcedure [HC].[addRemoveSong]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [HC].[addRemoveSong]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @kennelId uniqueidentifier,
 @songId uniqueidentifier,
 @state smallint

AS

BEGIN

-- EXEC HC.addRemoveSong @kennelId = '5029DE3A-D231-47AA-BE72-ECE9BCCD55D1', @songId = '087DFB87-0701-4FC5-A8A6-009164F5038C', @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @state = '1'

	SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	DECLARE @result nvarchar(120)
	DECLARE @message nvarchar(120)
	DECLARE @songName nvarchar(120)
	DECLARE @kennelName nvarchar(120)

	SELECT @songName = SongName from HC.Song s WHERE s.id = @songId
	SELECT @kennelName = k.KennelName from HC.Kennel k where k.id = @kennelId

	SET @result = '0'

	IF @state = 1
		BEGIN
			IF NOT EXISTS(SELECT * FROM HC.KennelSongMap WHERE SongId = @songId AND KennelId = @kennelId)
			BEGIN INSERT INTO HC.KennelSongMap(SongId,KennelId,[Following]) VALUES (@songId,@kennelId,1) END
				ELSE
			BEGIN UPDATE HC.KennelSongMap SET [Following] = 1 WHERE SongId=@songId AND KennelId = @kennelId END
			SET @result = '1'
			SET @message = 'You have added ' + @songName + ' to the songbook for ' + @kennelName
		END
	ELSE 
		if @state = 0
		BEGIN
			IF EXISTS(SELECT * FROM HC.KennelSongMap WHERE SongId = @songId AND KennelId = @kennelId)
			BEGIN UPDATE HC.KennelSongMap SET [Following] = 0 WHERE SongId=@songId AND KennelId = @kennelId END
			SET @message = 'You have removed ' + @songName + ' from the songbook for ' + @kennelName
		END

		SELECT @result as [Result], @message as [Message]


END





GO
/****** Object:  StoredProcedure [HC].[addUser]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC].[addUser]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @email nvarchar(250),
 @eventId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @isNewMember int = 1,
 @firstName nvarchar(100) = null,
 @lastName nvarchar(100) = null,
 @deviceId uniqueidentifier,
 @homeLatitude decimal(18,15) = null,
 @homeLongitude decimal (19,15) = null,
 @hashHandle nvarchar(100) = null,
 @facebookId nvarchar(250) = null,
 @gender nvarchar(50) = null,
 @locale nvarchar(50) = null,
 @photo nvarchar(500) = null

AS

BEGIN

SET NOCOUNT ON


-- EXEC HC.addUser @userId = '00000000-0000-0000-0000-000000000000', @accessToken = '',@email = 'james@jamesawhite.com', @firstName = 'James', @lastName = 'White', @deviceId = '366bfe5f-9906-443d-86a4-b99c5d668db3',@hashHandle = 'Opee',@facebookId = '10214797082344406'



	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	if (SELECT count(*) from HC.Hasher h where h.Email = trim(@email) and (h.Email <> 'james@jamesawhite.com' AND h.Email <> 'melissatunawhite@gmail.com') AND h.Email <> '') > 0
	BEGIN
			select 
		5 as ErrorType 
		,'User''s e-mail already exists in the system' as ErrorTitle
		,'A user already exists with this e-mail address in the system. Please register with a different e-mail address. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	SELECT @homeLatitude = coalesce(@homeLatitude,52.1663), @homeLongitude = coalesce(@homeLongitude,4.4814) 
	SET @userId = newid()
	INSERT HC.Hasher 
		(
			Id,FirstName,LastName,Email,HashName,HomeLatitude,HomeLongitude,DisplayName,FacebookId,Gender,Locale,Photo
		) VALUES 
		(
			@userId,@firstName,@lastName,@email,@hashHandle,@homeLatitude,@homeLongitude,@hashHandle,@facebookId,@gender,@locale,@photo
		)

DECLARE @hasherKennelMapId uniqueidentifier
DECLARE @hasherEventMapId uniqueidentifier
DECLARE @memberCounter int

if @eventId <> '00000000-0000-0000-0000-000000000000'
BEGIN
	DECLARE @kennelId uniqueidentifier
	SELECT @kennelId = evt.KennelId from HC.Event evt where evt.id = @eventId
	SET @hasherKennelMapId = newid()
	INSERT HC.HasherKennelMap (id,UserId,KennelId,[Following],isMember,MemberSince) VALUES (@hasherKennelMapId, @userId, @kennelId,1,@isNewMember,GETDATE())

	SELECT @memberCounter = count(*) from HC.HasherKennelMap hkm WHERE hkm.KennelId = @kennelId AND hkm.IsMember = 1
	SET @hasherEventMapId = newid()

	INSERT HC.HasherEventMap (id,EventId,UserId,UserStartEvent,Rsvp,RsvpState) VALUES (@hasherEventMapId,@eventId,@userId,getdate(),GETDATE(),3)

END

SELECT top 1 
	h.id as userId, 
	h.qr_code, 
	'USC:' + UPPER(cast(h.QR_secret_code as nvarchar(50))) as qr_secret_code,
	coalesce(CASE 
		WHEN h.NameDisplayPreference = 1
			THEN h.HashName
		WHEN h.NameDisplayPreference = 2
			THEN h.FirstName + ' ' + h.LastName
		ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
		END,DisplayName,'<no name>')
	AS displayName,
	h.FirstName as firstName,
	h.LastName as lastName,
	h.HashName as hashName,
	h.Email as email,
	coalesce(@hasherKennelMapId,'00000000-0000-0000-0000-000000000000') as hasherKennelMapId,
	coalesce(@hasherEventMapId,'00000000-0000-0000-0000-000000000000') as hasherEventMapId,
	coalesce(@memberCounter,0) as memberCount
FROM HC.Hasher h where h.id = @userId

END





GO
/****** Object:  StoredProcedure [HC].[approveLogin]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [HC].[approveLogin]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@deviceId nvarchar(100),
@deviceType nvarchar(100),
@latitude decimal(18,15),
@longitude decimal (19,15)

AS

BEGIN

	SET NOCOUNT ON

-- EXEC HC.approveLaunch @userId = '00000000-0000-0000-0000-000000000000', @accessToken = '', @deviceId = 'TestDevice', @deviceType = 'iPhone 6s / iOS 11.4', @latitude = 52.4, @longitude = 4.4

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	INSERT HC.LaunchAndLogin 
	(
		UserId
		,DeviceType
		,MobileDeviceId
		,Latitude
		,Longitude
	)
	VALUES
	(
		@userId
		,@deviceType
		,@deviceId
		,@latitude
		,@longitude
	)

	SELECT TOP 1 svr.ApiVersion,svr.LastGazetteerUpdate,'1' AS ApprovalCode 
	FROM HC.ServerStatus svr
	ORDER BY svr.CreatedDate desc

END
GO
/****** Object:  StoredProcedure [HC].[authorizeDevice]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC].[authorizeDevice]

 @accessToken nvarchar(1000),
 @scanText nvarchar(250),
 @deviceId uniqueidentifier

AS

BEGIN

SET NOCOUNT ON
-- EXEC HC.authorizeDevice @scanText = 'USC:73b9e85c-b8e0-4edb-8a9e-ea55cdfa0de6 ', @deviceId = '0C2852D4-A60E-4BA9-8628-4B0F246034C4'

	IF HC.CHECK_ACCESS_TOKEN('00000000-0000-0000-0000-000000000000',OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

if (@scanText like 'USC:%')
BEGIN
	DECLARE @secretCode uniqueidentifier
	SET @secretCode = CAST(right(TRIM(@scanText),36) AS uniqueidentifier)

	SELECT top 1 
		h.id as userId, 
		h.QR_code, 
		'USC:' + UPPER(cast(h.QR_secret_code as nvarchar(50))) as QR_secret_code,
		coalesce(CASE 
			WHEN h.NameDisplayPreference = 1
				THEN h.HashName
			WHEN h.NameDisplayPreference = 2
				THEN h.FirstName + ' ' + h.LastName
			ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
			END,DisplayName,'<no name>')
		AS DisplayName,
		h.FirstName,
		h.LastName,
		h.HashName,
		h.Email

	FROM HC.Hasher h where h.QR_secret_code = @secretCode
END

END





GO
/****** Object:  StoredProcedure [HC].[CleanDb]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [HC].[CleanDb] AS

delete from HC.HasherEventMap where UserId not in (select id from HC.Hasher)
delete from HC.HasherKennelMap where UserId not in (select id from HC.Hasher)
delete from HC.Payment where HasherEventMapId not in (select id from HC.HasherEventMap)
GO
/****** Object:  StoredProcedure [HC].[editUser]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC].[editUser]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @email nvarchar(250) = null,
 @firstName nvarchar(100) = null,
 @lastName nvarchar(100) = null,
 @deviceId uniqueidentifier = null,
 @homeKennelId uniqueidentifier = null,
 @homeLatitude decimal(18,14) = null,
 @homeLongitude decimal (19,15) = null,
 @hashHandle nvarchar(100) = null,
 @facebookId nvarchar(250) = null,
 @locale nvarchar(50) = null,
 @gender nvarchar(50) = null,
 @photo nvarchar(500) = null


AS

BEGIN

SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	if (@email = '') SET @email = NULL
	if (@firstName = '') SET @firstName = NULL
	if (@lastName = '') SET @lastName = NULL
	if (@deviceId = '00000000-0000-0000-0000-000000000000') SET @deviceId = NULL
	if (@homeKennelId = '00000000-0000-0000-0000-000000000000') SET @homeKennelId = NULL
	if (@homeLatitude = -1) SET @homeLatitude = NULL
	if (@homeLongitude = -1) SET @homeLongitude = NULL
	if (@hashHandle = '') SET @hashHandle = NULL
	if (@facebookId = '') SET @facebookId = NULL
	if (@locale = '') SET @locale = NULL
	if (@gender = '') SET @gender = NULL
	if (@photo = '') SET @photo = NULL


	UPDATE HC.Hasher SET 
		FirstName = coalesce(@firstName,h.FirstName), 
		LastName = coalesce(@lastName,h.LastName), 
		HashName = coalesce(@hashHandle,h.HashName), 
		DisplayName = coalesce(@hashHandle,h.DisplayName), 
		Home_KennelId = coalesce(@homeKennelId,h.Home_KennelId),
		HomeLatitude = coalesce(@homeLatitude,h.HomeLatitude),
		HomeLongitude = coalesce(@homeLongitude,h.HomeLongitude),
		FacebookId = coalesce(@facebookId, h.FacebookId),
		Gender = coalesce(@gender, h.gender),
		Locale = coalesce(@locale, h.locale),
		Photo = coalesce(@photo, h.Photo)
	FROM HC.Hasher h where h.id = @userId

SELECT top 1 
	h.id as userId, 
	h.QR_code, 
	'USC:' + UPPER(cast(h.QR_secret_code as nvarchar(50))) as QR_secret_code,
	coalesce(CASE 
		WHEN h.NameDisplayPreference = 1
			THEN h.HashName
		WHEN h.NameDisplayPreference = 2
			THEN h.FirstName + ' ' + h.LastName
		ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
		END,DisplayName,'<no name>')
	AS DisplayName,
	h.FirstName,
	h.LastName,
	h.HashName,
	h.Email

FROM HC.Hasher h where h.id = @userId

END





GO
/****** Object:  StoredProcedure [HC].[getAllHashers]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC].[getAllHashers]

@userId uniqueidentifier,
@accessToken nvarchar(1000)

AS

BEGIN

SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END


	SELECT 
		id
		,HashName as HashName
		,FirstName as FirstName
		,LastName as LastName
		,NameDisplayPreference as DispPref
		,Photo as Photo
	FROM HC.Hasher
	WHERE deleted = 0
END

GO
/****** Object:  StoredProcedure [HC].[getAllKennels]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC].[getAllKennels]

 @userId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @accessToken nvarchar(1000) = 'none',
 @kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @userLatitude float = null,
 @userLongitude float = null,
 @distanceFromUserInKm float = null,
 @procName nvarchar(250) = null

AS

BEGIN

	SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,coalesce(@procName,OBJECT_NAME(@@PROCID)),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	-- EXEC HC.[getAllKennels] @userLatitude = 52.1663, @userLongitude =  4.4814, @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @accessToken = '', @distanceFromUserInKm = 250, @kennelId = '00000000-0000-0000-0000-000000000000'
	-- EXEC HC.[getAllKennels] @accessToken = '', @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @distanceFromUserInKm = 2000, @kennelId = '00000000-0000-0000-0000-000000000000'

	IF ((@userLatitude is NULL) OR (@userLongitude IS NULL))
	BEGIN
		-- Assume Leiden Centraal Station
		SET @userLatitude = 52.1663
		SET @userLongitude = 4.4814
	END

	IF (@kennelId is null) SET @kennelId = '00000000-0000-0000-0000-000000000000'

	IF ((@distanceFromUserInKm IS NULL) OR (@distanceFromUserInKm <= 0)) SET @distanceFromUserInKm = 99999

	DECLARE @geoLoc	AS GEOGRAPHY
	SET @geoloc = geography::Point(@userLatitude,@userLongitude,4326) 

		SELECT k.[id] as kennelId
			  ,cast ((@geoloc.STDistance(k.kennelGeolocation)/1000) as int) as distance
			  ,CASE WHEN coalesce (hkm.[Following],0) = 0 THEN 'off' ELSE 'on' END  as [following]
			  ,coalesce (hkm.[Following],0) as [followingBool]
			  ,[kennelStatus] 
			  ,[kennelName]
			  ,[kennelDescription]
			  ,k.cityId
			  ,k.kennelWebsiteUrl
			  ,k.kennelFacebookId
			  ,k.kennelFacebookToken
			  ,k.kennelFacebookTokenUserId
			  ,k.autoImportFacebookEvents
			  ,k.importOnlyTaggedEvents
			  ,k.facebookTagForImport
			  ,k.defaultEventCurrencyType
			  ,k.defaultEventPriceForNonMembers
			  ,k.defaultEventPriceForMembers
			  ,k.defaultRunStartTime
			  ,coalesce([KennelShortName],[KennelName],'<no name>') as [kennelShortName]
			  ,case when datalength(coalesce(KennelLogo,'')) < 4 then 'https://harriercentral.blob.core.windows.net/harrier/MissingLogo.png' else KennelLogo end as kennelLogo
			  ,k.[latitude]
			  ,k.[longitude]
			  ,(select count(*) from HC.Haberdashery hd where hd.KennelId = k.id and hd.Archive = 0) as activeHaberdasheryItems
			  ,(select count(*) from HC.Haberdashery hd where hd.KennelId = k.id and hd.Archive != 0) as archiveHaberdasheryItems
			  ,c.CityName + ', ' + r.RegionName + ', ' + n.CountryName as locationName
				,hkm.isMember  
				,hkm.mismanagementRoleFlags
				,hkm.appAccessFlags
				,CASE
					WHEN (h.id IS NOT NULL) THEN 1
					ELSE 0
					END
						as isHomeKennel
			  ,coalesce(kAuth.auth_AllowCredit,0) as authAllowCredit
			  ,coalesce(kAuth.auth_CheckInAndOut,0) as authCheckInAndOut
			  ,coalesce(kAuth.auth_CustomLogo,0) as authCustomLogo
			  ,coalesce(kAuth.auth_CustomSongbook,0) as authCustomSongbook
			  ,coalesce(kAuth.auth_FacebookIntegration,0) as authFacebookIntegration
			  ,coalesce(kAuth.auth_Haberdashery,0) as authHaberdashery
			  ,coalesce(kAuth.auth_HareRaisingManagement,0) as authHareRaisingManagement
			  ,coalesce(kAuth.auth_MembersAllowed,0) as authMembersAllowed
			  ,coalesce(kAuth.auth_PromoteEvents,0) as authPromoteEvents
			  ,coalesce(kAuth.auth_PushNotifications,0) as authPushNotifications
			  ,coalesce(kAuth.auth_TrackPayments,0) as authTrackPayments
			  ,coalesce(kAuth.auth_WebsiteIntegration,0) as authWebsiteIntegration
			  ,(select count(*) from HC.HasherKennelMap hkm2 where hkm2.KennelId = k.id and hkm2.IsMember = 1) as memberCount
		  FROM [HC].[Kennel] k 
		  LEFT OUTER JOIN HC.HasherKennelMap hkm on k.id = hkm.KennelId and hkm.UserId = @userId
		  LEFT OUTER JOIN HC.City c on c.id = k.CityId
		  LEFT OUTER JOIN HC.Region r on r.id = c.RegionId
		  LEFT OUTER JOIN HC.Country n on n.id = r.CountryId
		  LEFT OUTER JOIN HC.Hasher h on h.Home_KennelId = k.id AND h.id = @userId
		  LEFT OUTER JOIN HC.KennelAuthorization kAuth on kAuth.KennelId = k.id AND kAuth.EndDate IS NULL

		  WHERE 
		  ((@kennelId = '00000000-0000-0000-0000-000000000000') OR (k.id = @kennelId)) AND
			
				((@geoloc.STDistance(k.kennelGeolocation)/1000) <= @distanceFromUserInKm)
			
		  ORDER BY 
		    case when hkm.[Following] = 0 then 0 -- this strange case statement orders the records with the "following" items at the top
				 when hkm.[Following] = 1 then 2
				 when hkm.[Following] = 2 then 1
				end DESC,
			@geoloc.STDistance(k.kennelGeolocation)
			
END
	

  


GO
/****** Object:  StoredProcedure [HC].[getEventDetails]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [HC].[getEventDetails]


@userId uniqueidentifier,
@accessToken nvarchar(1000),
@eventId uniqueidentifier

AS

BEGIN

-- EXEC HC.getEventDetails @eventId = '7520f48f-d9be-4e76-8e23-287dc38cfb45', @userId = '624c51b3-2f64-4de5-9458-b506e75ac544'



SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

SELECT  e.[id] as EventId
	,e.[EventFacebookId]
	,e.[EventStartDatetime]
	,e.[EventEndDatetime]
	,e.[KennelId]
	,e.[IsCountedRun]
	,e.[IsVisible]
	,e.[IsPromotedEvent]
	,e.[ThemeRunType]
	,e.[EventPriceForMembers]
	,e.[EventPriceForNonMembers]
	,e.[EventCurrencyType]
	,e.[AbsoluteEventNumber]
	,e.[EventNumber]
	,e.[EventName]
	,e.[EventDescription]
	,e.[EventImage]
	,e.[EventShortDesc]
	,e.[LocationOneLineDesc]
	,e.[LocationCity]
	,e.[LocationStreet]
	,e.[LocationPostCode]
	,e.[LocationCountry]
	,e.[LocationDescription]
	,coalesce(e.[Latitude],e.[FbLatitude]) as Latitude
	,coalesce(e.[Longitude],e.[FbLongitude]) as Longitude
	,cast(e.[deleted] as smallint) as deleted
	,coalesce(k.KennelShortName,k.KennelName,'<no Kennel name>') as KennelShortName
	,k.KennelLogo
	,k.DefaultCity
	,k.DefaultCountry
	,k.DefaultCitiesList
	,k.DefaultCountriesList
	,k.DefaultEventPriceForMembers
	,k.DefaultEventPriceForNonMembers

	,coalesce(hem.IsHare,0) as IsHare
	,coalesce(hem.RsvpState,0) as RsvpState
	,coalesce(hem.TotalRunsThisKennel,0) as TotalRunsThisKennel
	,coalesce(hem.TotalHaringThisKennel,0) as TotalHaringThisKennel
	,coalesce(hem.TotalPackRunsThisKennel,0) as TotalPackRunsThisKennel
	,case WHEN hem.[UserStartEvent] IS NOT NULL AND hem.[UserEndEvent] IS NULL THEN 4 
	WHEN hem.[UserStartEvent] IS NOT NULL AND hem.[UserEndEvent] IS NOT NULL THEN 5
	ELSE coalesce(hem.RsvpState,0)
	END as UserStatus
	,(select count(hemYes.id) from HC.HasherEventMap hemYes where hemYes.EventId = e.id and hemYes.RsvpState = 3) as WillAttendCount
	,(select count(hemMaybe.id) from HC.HasherEventMap hemMaybe where hemMaybe.EventId = e.id and hemMaybe.RsvpState = 2) as MightAttendCount
	,(select count(hemNo.id) from HC.HasherEventMap hemNo where hemNo.EventId = e.id and hemNo.RsvpState = 1) as WillNotAttendCount
  FROM [HC].[Event] e INNER JOIN HC.Kennel k on e.KennelId = k.id
  LEFT OUTER JOIN HC.HasherEventMap hem on hem.EventId = e.id AND hem.UserId = @userId

  WHERE e.id = @eventId
END

GO
/****** Object:  StoredProcedure [HC].[getEventsByDistance]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC].[getEventsByDistance]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@latitude float,
@longitude float,
@startDate datetime = null,
@endDate datetime = null,
@distanceInKm float = null,
@itemsToDisplay int = 50,
@procName nvarchar(100) = null

AS

BEGIN

-- EXEC HC.getEventsByDistance @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @accessToken = '', @latitude = 51.9, @longitude = 4.4
-- EXEC HC.getEventsByDistance @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @accessToken = '', @latitude = 51.9, @longitude = 4.4, @distanceInKm = 40
-- EXEC HC.getEventsByDistance @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @accessToken = '', @latitude = 51.9, @longitude = 4.4, @distanceInKm = 100, @itemsToDisplay = 3
-- EXEC HC.getEventsByDistance @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @accessToken = '', @latitude = 51.9, @longitude = 4.4, @distanceInKm = 100, @startDate = '1/1/2018', @endDate = '3/1/2018'


SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,coalesce(@procName,OBJECT_NAME(@@PROCID)),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

IF @startDate IS NULL SET @startDate = dateadd(day,-9999,getdate())
IF @endDate IS NULL SET @endDate = dateadd(day, 9999, getdate())
IF ((@distanceInKm <= 0) OR (@distanceInKm IS NULL)) SET @distanceInKm = 50000


	DECLARE @geoLoc	AS GEOGRAPHY
	SET @geoloc = geography::Point(@latitude,@longitude,4326) 


		SELECT TOP (@itemsToDisplay)
			-- FROM HC.Event
				e.id as EventId
				,e.EventStartDatetime
				,e.EventName
				,coalesce(e.Latitude,e.FbLatitude,k.Latitude,c.Latitude) as Latitude
				,coalesce(e.Longitude,e.FbLongitude,k.Longitude,c.Longitude) as Longitude
				,(@geoloc.STDistance(coalesce(e.[EventGeolocation],k.[KennelGeoLocation],c.[CityGeoLocation]))/1000) as Distance
			-- From HC.Kennel
				,case when datalength(coalesce(k.KennelLogo,'')) < 4 then 'https://harriercentral.blob.core.windows.net/harrier/MissingLogo.png' else k.KennelLogo end as KennelLogo
			-- From HC.HasherEventMap
				,case WHEN hem.[UserStartEvent] IS NOT NULL AND hem.[UserEndEvent] IS NULL THEN 4 
					WHEN hem.[UserStartEvent] IS NOT NULL AND hem.[UserEndEvent] IS NOT NULL THEN 5
					ELSE coalesce(hem.RsvpState,0)
				 END as UserStatus
				,coalesce(e.LocationStreet,'') + '~~' + coalesce(e.LocationCity + ', ','') + coalesce(e.LocationPostCode,'') as StreetAddress
		from HC.Event e 
		INNER JOIN HC.Kennel k on e.KennelId = k.id
		INNER JOIN HC.City c on c.id = k.CityId
		LEFT OUTER JOIN HC.HasherEventMap hem on hem.EventId = e.id AND hem.UserId = @userId
		WHERE 
		e.EventStartDatetime BETWEEN @startDate AND @endDate 
		AND e.deleted = 0 AND e.IsVisible <> 0
		AND ((@distanceInKm IS NULL) OR (@geoloc.STDistance(coalesce(e.[EventGeolocation],k.[KennelGeoLocation],c.[CityGeoLocation]))/1000) <= @distanceInKm)
		--order by @geoloc.STDistance(coalesce(e.[EventGeolocation],k.[KennelGeoLocation],c.[CityGeoLocation]))/1000
		order by e.EventStartDatetime desc


END
GO
/****** Object:  StoredProcedure [HC].[getFriends]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [HC].[getFriends]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@kennelId uniqueidentifier,
@latitude float = null,
@longitude float =  null,
@distanceInKm float = null

AS

BEGIN

-- EXEC HC.getFriends @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @kennelId = '5029DE3A-D231-47AA-BE72-ECE9BCCD55D1'
-- EXEC HC.getFriends @userId ='624c51b3-2f64-4de5-9458-b506e75ac544'

SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END


	SELECT hfm.id as HasherFriendId
		,h.QR_code as Friend_UserQr
		,coalesce(CASE 
		WHEN h.NameDisplayPreference = 1
			THEN h.HashName
		WHEN h.NameDisplayPreference = 2
			THEN h.FirstName + ' ' + h.LastName
		ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
		END,DisplayName,'<no name>')
		 AS DisplayName
      ,[Photo]
      ,[Description]
	  ,hfm.FriendSince
	  ,k.KennelName
	  ,coalesce((SELECT top 1 evt.EventName FROM HC.Event evt
			INNER JOIN HC.HasherEventMap hem on hem.EventId = evt.id AND hem.UserId = h.id
			WHERE evt.EventStartDateTime >= dateadd(day,-1,GETDATE())
			AND hem.RsvpState >= 3 AND evt.deleted = 0 AND evt.isVisible <> 0
			ORDER BY evt.EventStartDateTime asc),'<no event planned>') as NextEventName
	FROM HC.Hasher h 
	INNER JOIN HC.HasherFriendMap hfm on hfm.UserId = @userId AND hfm.Friend_UserId = h.id
	LEFT OUTER JOIN HC.Kennel k on h.Home_KennelId = k.id
	WHERE h.id in
		(
			SELECT DISTINCT hfm.Friend_UserId 
				FROM HC.HasherFriendMap hfm 
				LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.UserId = hfm.Friend_UserId
				WHERE hfm.UserId = @userId
				AND ((@kennelId = '00000000-0000-0000-0000-000000000000') OR ((@kennelId = hkm.KennelId) AND ((hkm.Following = 1) OR (hkm.IsMember = 1))))
				AND hfm.Ignore = 0
		)






END
GO
/****** Object:  StoredProcedure [HC].[getGazetteer]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [HC].[getGazetteer]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@latitude float = null,
@longitude float =  null,
@distanceInKm float = null

AS

BEGIN

-- EXEC HC.getGazetteer @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @accessToken = '', @latitude = 52.5, @longitude = 4.4, @distanceInKm = 50000


SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	IF ((@distanceInKm <= 0) OR (@distanceInKm IS NULL)) SET @distanceInKm = 50000

	DECLARE @geoLoc	AS GEOGRAPHY

	-- TODO: Need to implement geo filtering
	IF ((@latitude is not null) AND (@longitude IS NOT NULL))
		SET @geoloc = geography::Point(@latitude,@longitude,4326) 

	SELECT 
		c.id as CityId
		,c.CityName
		,c.Latitude
		,c.Longitude
		,r.id as RegionId
		,r.RegionName
		,cn.id as CountryId
		,cn.CountryName
		,cn.CountryCode
		,cn.ContinentCode
		,cn.ContinentName
		,cn.CurrencyCode
		,cn.PrimaryCultureCode
		,coalesce(c.FlagFile,'') as CityFlagFile
		,coalesce(r.FlagFile,'') as RegionFlagFile
		,coalesce(cn.FlagFile,'earth.png') as CountryFlagFile
		,c.DateLastUpdated
	FROM
	HC.City c
	INNER JOIN HC.Region r on c.RegionId = r.id
	INNER JOIN HC.Country cn on r.CountryId = cn.id
	WHERE ((@distanceInKm IS NULL) OR ((@geoloc.STDistance(c.[CityGeoLocation])/1000) <= @distanceInKm))
	ORDER BY @geoloc.STDistance(c.[CityGeoLocation]) ASC

END
GO
/****** Object:  StoredProcedure [HC].[getHaberdashery]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [HC].[getHaberdashery]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@KennelId uniqueidentifier

AS

BEGIN

SET NOCOUNT ON

-- EXEC HC.[getHaberdashery] @KennelId = '6F901167-4BD3-45AF-9DA0-6AF5A1128F42'

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	SET NOCOUNT ON
	SELECT 
	   [id] as HaberdasheryId
      ,[KennelId]
      ,[ItemName]
      ,[Description]
      ,[Price]
	  ,coalesce([CurrencyCulture],'nl-NL') as CurrencyCulture
      ,[SizesAvailable]
      ,[ImageUrl]
	  ,[ReverseSideImageUrl]
      ,[InStock]
      ,[Archive]
		  FROM HC.Haberdashery h
		  WHERE h.KennelId = @KennelId 
		 

END




GO
/****** Object:  StoredProcedure [HC].[getHomePageData]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC].[getHomePageData]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@latitude decimal(17,14),
@longitude decimal(18,14),
@distanceInKm int = 200,
@itemsToDisplay int = 50,
@mapItemsOnly int = 0

AS

BEGIN

-- EXEC HC.GetHomePageData @userId = '5C4AE228-2CC1-467F-B666-F62EFEDFEE14', @accessToken = '', @distanceInKm = 100, @latitude = 51.9, @longitude = 4.4, @mapItemsOnly = 0

SET NOCOUNT ON
	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
BEGIN
	select 
	1 as ErrorType 
	,'Unauthorized Access Token' as ErrorTitle
	,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

	RETURN
END

	DECLARE @geoLoc	AS GEOGRAPHY
	SET @geoloc = geography::Point(@latitude,@longitude,4326) 


CREATE TABLE #outputTable
(
	OutputType int not null
	,OutputOrder int not null
	,OutputGuid1 uniqueidentifier null
	,OutputStr1 nvarchar(500) null
	,OutputStr2 nvarchar(500) null
	,OutputStr3 nvarchar(500) null
	,OutputInt1 int null
	,OutputInt2 int null
	,OutputLat decimal(17,14) null
	,OutputLon decimal(18,14) null
	,OutputDatetime1 datetime null
)

-- OutputTypeKey
--
-- 1 = Top 5 run counts
-- 2 = Count of Kennels followed
-- 3 = Next run for each Kennel followed or Kennel not followed but with a run with an RSVP of Yes
-- 4 = User QR Code
-- 5 = List of Kennels followed
-- 6 = List of nearby runs
-- 7 = 6 friends whose photos will show on the friends button
-- 8 = total count of friends
-- 9 = featured kennel
--10 = featured song
--11 = Haberdashery
--12 = Kennel locations

if (@mapItemsOnly = 0)
BEGIN

		CREATE TABLE #runCounts
		(
			KennelId uniqueidentifier
			,KennelLogo nvarchar(500)
			,KennelName nvarchar(500)
			,TotalRunsThisKennel int
			,TotalPackRunsThisKennel int
			,TotalHaringThisKennel int
			,[Following] int
			,KennelShortName nvarchar(50)
		)

		INSERT INTO #runCounts
		EXEC HC.getMyKennelRunTotals @userId = @userId, @accessToken = @accessToken, @procName = 'getHomePageData'

		-- get the run counts (top 5 kennels plus one record with the overall total run count)
		INSERT #outputTable (OutputType,OutputOrder,OutputGuid1,OutputInt1,OutputStr1,OutputStr2)
		select top 6 
		1 as OutputType
		,ROW_NUMBER() OVER (ORDER BY TotalRunsThisKennel desc) as OutputOrder
		,KennelId as OutputGuid1
		,TotalRunsThisKennel as OutputInt1  
		,KennelLogo as OutputStr1
		,KennelShortName as OutputStr2
		from #runCounts 
		order by TotalRunsThisKennel desc

		CREATE TABLE #nextRuns
		(
			EventId uniqueidentifier
			,EventName nvarchar(500)
			,KennelLogo nvarchar(500)
			,DaysUntilNextRun int
			,FriendsAttending int
			,UserStatus int
			,RsvpState int
			,TotalRunsThisKennel int
			,KennelId uniqueidentifier
			,KennelShortName nvarchar(50)
		)

		INSERT INTO #nextRuns
		EXEC HC.getNextRuns @userId = @userId, @accessToken = @accessToken, @procName = 'getHomePageData'

		-- get the count of kennels with next runs 
		-- NOTE: This may cause a problem in the UI if there are runs that are with kennels not
		--       followed. We will need to check this.
		INSERT #outputTable (OutputType,OutputOrder,OutputGuid1,OutputInt1,OutputStr1,OutputStr2)
		select 
		2 as OutputType
		,1 as OutputOrder
		,'00000000-0000-0000-0000-000000000000' as OutputGuid1
		,count(*) as OutputInt1  
		,'' as OutputStr1
		,'' as OutputStr2
		from #nextRuns 

		-- get the next run for each kennel followed or for kennels not followed where there has been an RSVP
		INSERT #outputTable (OutputType,OutputOrder,OutputGuid1,OutputInt1,OutputStr1,OutputInt2,OutputStr2)
		select 
		3 as OutputType
		,ROW_NUMBER() OVER (ORDER BY DaysUntilNextRun asc) as OutputOrder
		,EventId as OutputGuid1
		,DaysUntilNextRun as OutputInt1  
		,KennelLogo as OutputStr1
		,RsvpState as OutputInt2
		,KennelShortName as OutputStr2
		from #nextRuns order by DaysUntilNextRun asc

		-- Provide the User QR code to be scanned from the home page
		INSERT #outputTable (OutputType,OutputOrder,OutputGuid1,OutputInt1,OutputStr1)
		select  
		4 as OutputType
		,1 as OutputOrder
		,h.id as OutputGuid1
		,0 as OutputInt1  
		,h.QR_code as OutputStr1
		from HC.Hasher h where h.id = @userId

		-- Provide links to all of the followed kennels
		INSERT #outputTable (OutputType,OutputOrder,OutputGuid1,OutputInt1,OutputStr1,OutputStr2)
		select  
		5 as OutputType
		,ROW_NUMBER() OVER (ORDER BY hkm.MemberSince asc) as OutputOrder
		,hkm.KennelId as OutputGuid1
		,0 as OutputInt1  
		,k.KennelLogo as OutputStr1
		,k.KennelShortName as OutputStr2
		from HC.HasherKennelMap hkm
		INNER JOIN HC.Kennel k on k.id = hkm.KennelId
		where hkm.UserId = @userId
		and Following = 1

		-- Insert the top 6 friends so their photos can be displayed in the friends button on the home page
		INSERT #outputTable (OutputType,OutputOrder,OutputGuid1,OutputStr1)
		SELECT TOP 6 
		7 as OutputType
		,ROW_NUMBER() OVER (ORDER BY h.FirstName asc) as OutputOrder
		,Friend_UserId
		,h.Photo
		FROM HC.HasherFriendMap hfm
		INNER JOIN HC.Hasher h on hfm.Friend_UserId = h.id
		WHERE hfm.UserId = @userId
		AND Ignore = 0
		AND datalength(h.Photo) > 5

		-- insert a single record that has the count of friends
		INSERT #outputTable (OutputType,OutputOrder,OutputGuid1,OutputInt1)
		SELECT
		8 as OutputType
		,1 as OutputOrder
		,@userId
		,count(*)
		FROM HC.HasherFriendMap hfm
		WHERE hfm.UserId = @userId
		AND Ignore = 0

		-- insert a single record that has information on the featured Kennel
		INSERT #outputTable (OutputType,OutputOrder,OutputGuid1,OutputStr1,OutputStr2,OutputStr3)
		SELECT 9,1,id,KennelName,KennelLogo,KennelCoverPhoto FROM HC.Kennel k INNER JOIN
		(SELECT KennelId,max(StartDate) as StartDate
		FROM HC.FeaturedKennel 
		WHERE StartDate < getdate()
		GROUP BY KennelId) fk on k.id = fk.KennelId

		-- insert a single record that has information on the featured song
		INSERT #outputTable (OutputType,OutputOrder,OutputGuid1,OutputStr1,OutputStr2,OutputStr3)
		SELECT 10,1,id,ImageUrl,AudioUrl,SongName FROM HC.Song s INNER JOIN
		(SELECT SongId,max(StartDate) as StartDate
		FROM HC.FeaturedSong 
		WHERE StartDate < getdate()
		GROUP BY SongId) fs on s.id = fs.SongId

		-- Insert the top 6 haberdashery items so their photos can be displayed in the haberdashery button on the home page
		INSERT #outputTable (OutputType,OutputOrder,OutputGuid1,OutputStr1)
		SELECT TOP 6 
		11 as OutputType
		,ROW_NUMBER() OVER (ORDER BY hd.id asc) as OutputOrder
		,id
		,hd.ImageUrl
		FROM HC.Haberdashery hd
		WHERE hd.ShowOnHomePage = 1
		AND datalength(hd.ImageUrl) > 5

END

CREATE TABLE #localRuns
(
	EventId uniqueidentifier
	,EventStartDatetime datetime
	,EventName nvarchar(500)
	,Latitude decimal (12,9)
	,Longitude decimal (13,9)
	,Distance float
	,KennelLogo nvarchar(500)
	,UserStatus int
	,StreetAddress nvarchar(500)
)

INSERT INTO #localRuns
EXEC HC.getEventsByDistance @userId = @userId, @latitude = @latitude, @longitude = @longitude, @distanceInKm = @distanceInKm, @itemsToDisplay = @itemsToDisplay, @accessToken = @accessToken, @procName = 'getHomePageData'

INSERT #outputTable (OutputType,OutputOrder,OutputGuid1,OutputStr1,OutputStr2,OutputStr3,OutputInt1,OutputInt2,OutputLat,OutputLon,OutputDatetime1)
SELECT TOP 50
6 as OutputType
,ROW_NUMBER() OVER (ORDER BY Distance asc) as OutputOrder
,EventId as OutputGuid1
,EventName as OutputStr1
,KennelLogo as OutputStr2
,StreetAddress as OutputStr3
,CAST(Distance as int) as OutputInt1
,UserStatus as OutputInt2
,Latitude as OutputLat
,Longitude as OutputLon
,EventStartDatetime as OutputDatetime1
FROM #localRuns
ORDER BY ABS(DATEDIFF(DAY,EventStartDatetime,getdate())) ASC

INSERT #outputTable (OutputType,OutputOrder,OutputGuid1,OutputStr1,OutputStr2,OutputStr3,OutputInt1,OutputLat,OutputLon)
		SELECT 
		12 as OutputType
		,ROW_NUMBER() OVER (ORDER BY @geoloc.STDistance(k.KennelGeolocation) asc) as OutputOrder
		,k.[id] as KennelId
		,[KennelName] as OutputStr1
		,case when datalength(coalesce(KennelLogo,'')) < 4 then 'https://harriercentral.blob.core.windows.net/harrier/MissingLogo.png' else KennelLogo end as OutputStr2
		,coalesce([KennelShortName],[KennelName],'<no name>') as OutputStr3
	    ,cast ((@geoloc.STDistance(k.KennelGeolocation)/1000) as int) as OutputInt1
		,k.[Latitude] as OutputLat
		,k.[Longitude] as OutputLon
		FROM [HC].[Kennel] k
		WHERE ((@geoloc.STDistance(k.KennelGeolocation)/1000) <= @distanceInKm)
		ORDER BY @geoloc.STDistance(k.KennelGeolocation)

select 
	OutputType 
	,OutputOrder 
	,OutputGuid1 
	,OutputStr1 
	,OutputStr2
	,OutputStr3
	,OutputInt1 
	,OutputInt2
	,OutputLat
	,OutputLon
	,OutputDatetime1
from #outputTable order by OutputType,OutputOrder


if (@mapItemsOnly = 0)
BEGIN
	DROP TABLE #nextRuns
	DROP TABLE #runCounts
END

DROP TABLE #localRuns
DROP TABLE #outputTable

END
GO
/****** Object:  StoredProcedure [HC].[getKennelMembers]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC].[getKennelMembers]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@kennelId uniqueidentifier

AS

BEGIN

SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END


	SELECT 
		h.id
		,h.HashName as HashName
		,h.FirstName as FirstName
		,h.LastName as LastName
		,h.NameDisplayPreference as DispPref
		,h.Photo as Photo
	FROM HC.Hasher h
	INNER JOIN HC.HasherKennelMap hkm on hkm.KennelId = @kennelId and hkm.UserId = h.id
	WHERE deleted = 0 and hkm.IsMember = 1
END

GO
/****** Object:  StoredProcedure [HC].[getKennelSongCounts]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC].[getKennelSongCounts]

 @UserId uniqueidentifier,
 @accessToken nvarchar(1000),
 @showAllKennels smallint = null,
 @userLatitude float = null,
 @userLongitude float = null,
 @distanceFromUserInKm float = null

AS

BEGIN

-- EXEC HC.getKennelSongCounts @UserId = '624C51B3-2F64-4DE5-9458-B506E75AC544', @distanceFromUserInKm = 1000

SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	IF ((@userLatitude is NULL) OR (@userLongitude IS NULL))
	BEGIN
		-- Assume Leiden Centraal Station
		SET @userLatitude = 52.1663
		SET @userLongitude = 4.4814
	END

	IF ((@distanceFromUserInKm IS NULL) OR (@showAllKennels = 1)) SET @distanceFromUserInKm = 99999

	DECLARE @geoLoc	AS GEOGRAPHY
	SET @geoloc = geography::Point(@userLatitude,@userLongitude,4326) 



SELECT	
	 hkm.KennelId
	,cast ((@geoloc.STDistance(k.KennelGeolocation)/1000) as int) as Distance
	,k.KennelName
	,coalesce([KennelShortName],[KennelName],'<no name>') as [KennelShortName]
	,case when datalength(coalesce(KennelLogo,'')) < 4 then 'https://harriercentral.blob.core.windows.net/harrier/MissingLogo.png' else KennelLogo end as KennelLogo
	,(select count(ksm.id) FROM HC.KennelSongMap ksm WHERE ksm.KennelId = hkm.KennelId AND ksm.[following] = 1) as SongCount
into #temp
FROM HC.HasherKennelMap hkm
INNER JOIN HC.Kennel k on hkm.KennelId = k.id

WHERE hkm.UserId = @UserId and hkm.[Following] <> 0
ORDER BY k.KennelName ASC


	  SELECT * from #temp
	  WHERE  Distance <= @distanceFromUserInKm
	  ORDER BY 
		Distance ASC

	  DROP TABLE #temp

END
GO
/****** Object:  StoredProcedure [HC].[getMyKennelRunTotals]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC].[getMyKennelRunTotals]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
@procName nvarchar(100) = null  -- this is here to allow other stored procs to call this one and pass in their own accessTokens

AS

-- EXEC HC.getMyKennelRunTotals @userId = '5C4AE228-2CC1-467F-B666-F62EFEDFEE14',@accessToken = ''

SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,coalesce(@procName,OBJECT_NAME(@@PROCID)),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END


select k.id as KennelId
,k.KennelLogo
,k.KennelName
,hkm.CurrentPackRunCount + hkm.CurrentHaringCount as TotalRunsThisKennel
,hkm.CurrentPackRunCount as TotalPackRunsThisKennel
,hkm.CurrentHaringCount as TotalHaringThisKennel
,hkm.[Following]
,k.KennelShortName
into #temp
from HC.HasherKennelMap hkm
inner join HC.Kennel k on hkm.KennelId = k.id
where hkm.userId = @userId
and ((@kennelId = '00000000-0000-0000-0000-000000000000') OR (hkm.KennelId = @kennelId))
order by hkm.CurrentPackRunCount + hkm.CurrentHaringCount desc

-- next insert rows for kennels that we are following but that do not have any runs yet
insert #temp (KennelId,KennelLogo,KennelName,TotalRunsThisKennel,TotalPackRunsThisKennel,TotalHaringThisKennel,[Following],KennelShortName)
select k.id,k.KennelLogo,k.KennelName,0,0,0,hkm.[Following],k.KennelShortName
FROM HC.Kennel k
inner join HC.HasherKennelMap hkm on k.id = hkm.KennelId and hkm.UserId = @userId
WHERE hkm.Following = 1
AND hkm.KennelId not in (select kennelId from #temp)

declare @photo nvarchar(500)
select @photo = photo from HC.Hasher where id = @userId

select KennelId,KennelLogo,KennelName,TotalRunsThisKennel,TotalPackRunsThisKennel,TotalHaringThisKennel,[Following],KennelShortName from #temp where Following = 1 OR TotalRunsThisKennel > 0
union
select '00000000-0000-0000-0000-000000000000' as KennelId, @photo as KennelLogo,'My total run count' as KennelName,sum(TotalRunsThisKennel) as TotalRunsThisKennel,sum(TotalPackRunsThisKennel) as TotalPackRunsThisKennel, sum(TotalHaringThisKennel) as TotalHaringThisKennel, 1 as [Following],'My runs' as KennelShortName from #temp
order by TotalRunsThisKennel desc
GO
/****** Object:  StoredProcedure [HC].[getMyRuns]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC].[getMyRuns]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
@following int = -1

AS

-- EXEC HC.getMyRuns @userId = '6f901167-4bd3-45af-9da0-6af5a1128f42'
-- EXEC HC.getMyRuns @userId = '624c51b3-2f64-4de5-9458-b506e75ac544',@kennelId = '00000000-0000-0000-0000-000000000000'
-- EXEC HC.getMyRuns @userId = 'e15f27d1-1ac2-4241-a4fe-00e045cc3091',@kennelId = '6f901167-4bd3-45af-9da0-6af5a1128f42', @accessToken = '', @following = -1

SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END


select 
e.id as EventId
,e.EventStartDatetime
,e.EventEndDatetime
,e.EventName
,e.UserEventCounterIncrement
,hem.IsHare
,hem.TotalRunsThisKennel
,hem.TotalRunsAllKennels
,hem.UserStartEvent
,coalesce(hem.RsvpState,0) as RsvpState
,case WHEN hem.[UserStartEvent] IS NOT NULL AND hem.[UserEndEvent] IS NULL THEN 4 
WHEN hem.[UserStartEvent] IS NOT NULL AND hem.[UserEndEvent] IS NOT NULL THEN 5
ELSE coalesce(hem.RsvpState,0)
	END as UserStatus
FROM HC.Event e 
INNER JOIN HC.Kennel k on k.id = e.KennelId
LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.UserId = @userId AND hkm.KennelId = k.id
LEFT OUTER JOIN HC.HasherEventMap hem on hem.UserId = @userId and hem.EventId = e.id

WHERE e.deleted = 0 
AND e.IsVisible <> 0
AND e.IsCountedRun = 1
AND ((@following = -1) OR (hkm.Following = @following))
AND e.EventStartDatetime <= dateadd(day,1,getdate())
AND ((@kennelId = '00000000-0000-0000-0000-000000000000') OR (e.KennelId = @kennelId))
ORDER BY e.EventStartDatetime DESC,EventId DESC



GO
/****** Object:  StoredProcedure [HC].[getNextRuns]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC].[getNextRuns]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @procName nvarchar(100) = null -- this is here to allow other stored procs to call this one and pass in their own accessTokens

AS

BEGIN

-- EXEC HC.getNextRuns @userId = '5C4AE228-2CC1-467F-B666-F62EFEDFEE14', @accessToken = ''

	SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,coalesce(@procName,OBJECT_NAME(@@PROCID)),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

		
-- first get a list of all kennels that this user is following plus all of the
-- kennels where this user has RSVP'ed for an upcoming run in the future		
select distinct(k.id) as KennelId
into #temp
FROM HC.Kennel k 
left outer join HC.HasherKennelMap hkm on hkm.KennelId = k.id and hkm.UserId = @userId
left outer join HC.HasherEventMap hem on hem.UserId = @userId
left outer join HC.Event e on e.id = hem.EventId and e.KennelId = k.id
where (e.EventStartDatetime >= dateadd(day,-1,getdate()) AND hem.RsvpState = 3) 
OR (hkm.Following = 1)									        

-- now find the next run for each of these kennels and return the relevant information
select
	coalesce(NextRun.EventId,'00000000-0000-0000-0000-000000000000') as EventId
    ,coalesce(NextRun.EventName,'<no event planned>') as EventName
	,case when datalength(coalesce(KennelLogo,'')) < 4 then 'https://harriercentral.blob.core.windows.net/harrier/MissingLogo.png' else KennelLogo end as KennelLogo
	,coalesce(NextRun.DaysUntilNextRun,99999) as DaysUntilNextRun
	,coalesce(NextRun.FriendsAttending,0) as FriendsAttending
	,coalesce(NextRun.UserStatus,0) as UserStatus
	,coalesce(NextRun.RsvpState,0) as RsvpState
	,coalesce(NextRun.TotalRunsThisKennel,0) as TotalRunsThisKennel
	,coalesce(NextRun.KennelId,'00000000-0000-0000-0000-000000000000') as KennelId
	,coalesce(k.KennelShortName,'H3') as KennelShortName

	FROM HC.Kennel k 
			  OUTER APPLY
			  (SELECT top 1 
					   e.[id] as EventId
					  ,e.[EventName]
					  ,e.[KennelId]
					,coalesce(datediff(day,getdate(),e.EventStartDatetime),99999) as DaysUntilNextRun
					,coalesce((SELECT count(*) FROM HC.HasherEventMap hem2 INNER JOIN HC.HasherFriendMap hfm2 on hfm2.Friend_UserId = hem2.UserId WHERE hfm2.UserId = @userId AND hem2.EventId = e.id),0) as FriendsAttending
					 ,coalesce(hem.RsvpState,0) as RsvpState
					  ,case WHEN hem.[UserStartEvent] IS NOT NULL AND hem.[UserEndEvent] IS NULL THEN 4 
						WHEN hem.[UserStartEvent] IS NOT NULL AND hem.[UserEndEvent] IS NOT NULL THEN 5
						ELSE coalesce(hem.RsvpState,0)
							END as UserStatus
					  ,coalesce(hkm.CurrentHaringCount + hkm.CurrentPackRunCount,0) as TotalRunsThisKennel

				FROM HC.Event e 
				LEFT OUTER JOIN HC.HasherEventMap hem on hem.EventId = e.id and hem.UserId = @userId
				LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.UserId = @userId and hkm.KennelId = e.KennelId
				WHERE e.KennelId = k.id and CONVERT(date,e.EventStartDatetime) >= CONVERT(date,getdate()) 
				AND e.deleted = 0 AND e.IsVisible <> 0
				ORDER BY e.EventStartDatetime ASC) as NextRun

	WHERE k.id in (select KennelId from #temp) 
	ORDER BY COALESCE (NextRun.DaysUntilNextRun,99999)

	drop table #temp
			
END


GO
/****** Object:  StoredProcedure [HC].[getRunPlanner]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC].[getRunPlanner]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
@following int = -1,
@showFutureEventsOnly int = 1,
@daysInTheFuture int = 90,
@daysInThePast int = 90,
@eventFacebookIds varchar(8000) = null

AS

-- EXEC HC.getRunPlanner @userId = '624c51b3-2f64-4de5-9458-b506e75ac544',@accessToken = '', @showFutureEventsOnly = 0
-- EXEC HC.getRunPlanner @userId = '624c51b3-2f64-4de5-9458-b506e75ac544',@accessToken = '', @showFutureEventsOnly = 0, @eventFacebookIds = '772897806186271,116312275739999,1529941743966986,858993994188218,1032573993460250,1223525784326275,1026132587467299,747766582015741,176991522824124,364792883951393,1155620227798380,897298143658587,1457678761202934,1506690672957290,1216796778376177,245460299242893,138431856804849,1648948395363964,841791985977889,153299781895022,1719252245035189,1766023640392947,1657069567902747,844193005662822,114445595937988,137933936879040,1558800220798922,142246406387577,1060968960594429,477895219063585,1418741664891289,236055900207546,1384055841647943,1657660257823480,1696543923954148,272812136548037,1126900327397933,500702786968498,511384649008950,1629086347104929,666695106811059,531692237023564,1550867785234182,1816446238675037,174122366654356,794472924026914,1861197777450881,581966941969271,1651278991799772,165603920531227,1266562613387044,1589101474686972,160147214723747,1645154885754169,1152445674789214,118198022149347,320671578401864,1743270329284501,1951335348421587,1096353580453051,1317406904959173,116700815459278,1063639990399510,472896256233686,157151971594229,182507502142046,265144757185822,566388743710998,1040489456046994,458329651212699,1646143338990792,1697043933662495,1592463141035553,1749583731949038,1179337768744248,137684947024031,1682566455366331,1885080811756223,128160427716108,1877896589190654,276415756037269,1230726706992602,917267661743140,219010665163226,907627745975097,1610082172591777,1567582173560518,1647726135521069,572575506254667,1286555768125083,1884825201847220,1830186253895131,386380458238424,445330675658056,355599024845508,1594222957571760,1318095631541697,1146685588722852,524505564395253,730938587096891,1435890580067401,263620300701751,197584217480367,298389793923412,1638663579684834,1317974924998633,1439847349361824,112038429393148,1328250863918267,1627326404168987,281011812316714,245623562552997,1628059680790838,319301681843879,1946944812183827,1669515743306350,614923928715764,1691206687842550,1359639814097711,1864852533734898,199502280596571,1741505206129644,972819142825667,1095804420464533,187928161577886,733452663519884,1866425266965419,1868753310106079,2213257865565389,1982558848657613,1506093999697025,1791935794426647,1745033812409081,865660600244253,201966080230479,253201051756099,1786630241568447,1062706853845959,410525076003556,965092193525533,244068846123259,1016931461777352,1120241314730983,2058481771051493,1799403303704977,245897712599455,549926675198685,1719488111612621,1732893523696938,2103173569901505,1968556213376519,414497375423847,134444953872165,542477105907682,387611498320351,1688660268079763,1639618526357155,134043473810464,719055591628954,197440070720435,180608885765078,829493953847014,298941723846786,1740662592828616,126622551085357,403405193369614,828542320639035,1642014029344408,379613192508802,1607135286202870,649191825291680,210284546083003,920772104673995,107322872933863,166413877307417,610978115774626,1528293104149687,276528392872579,937012949697017,1521068411521335,1790087514574565,1483669221710555,196075800905014,879435922186861,238742866593038'
-- EXEC HC.getRunPlanner @userId = '624c51b3-2f64-4de5-9458-b506e75ac544',@accessToken = '', @kennelId = '6F901167-4BD3-45AF-9DA0-6AF5A1128F42', @following = -1, @showFutureEventsOnly = 0, @daysInTheFuture = 90, @daysInThePast = 365

SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

DECLARE @filterByFacebookId smallint
SET @filterByFacebookId = 0

CREATE TABLE #facebookIdTemp (itemNumber int, item varchar(500))

IF ((@eventFacebookIds is not null) AND (datalength(@eventFacebookIds) > 5))
BEGIN
	SET @filterByFacebookId = 1
	INSERT #facebookIdTemp(ItemNumber, Item) SELECT ItemNumber,TRIM(Item) FROM [HC].[DelimitedSplit8K](@eventFacebookIds,',')
END

select 
e.id as EventId
,k.KennelLogo
,k.KennelShortName
,e.EventStartDatetime
,e.EventEndDatetime
,e.EventFacebookId
,e.EventImage
,e.EventImageOffsetX
,e.EventImageOffsetY
,coalesce(e.EventNumber,0) as EventNumber
,e.AbsoluteEventNumber
,e.Latitude
,e.Longitude
,e.FbLatitude
,e.FbLongitude
,e.EventDescription
,e.EventName
,e.EventShortDesc
,e.LocationOneLineDesc
,e.IsCountedRun
,e.IsVisible
,e.IsPromotedEvent
,e.EventGeographicScope
,e.ThemeRunType
,e.deleted
,coalesce(hem.RsvpState,0) as RsvpState
,case WHEN hem.[UserStartEvent] IS NOT NULL AND hem.[UserEndEvent] IS NULL THEN 4 
WHEN hem.[UserStartEvent] IS NOT NULL AND hem.[UserEndEvent] IS NOT NULL THEN 5
ELSE coalesce(hem.RsvpState,0)
	END as UserStatus
FROM HC.Event e 
INNER JOIN HC.Kennel k on k.id = e.KennelId
LEFT OUTER JOIN HC.HasherEventMap hem on hem.UserId = @userId and hem.EventId = e.id
LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.UserId = @userId AND hkm.KennelId = e.KennelId

WHERE e.deleted = 0 
--AND e.IsVisible <> 0 -- we don't need this because the client should be able to process invisible records
AND ((@following = -1) OR (hkm.Following = @following))
AND (((@showFutureEventsOnly = 1) AND (e.EventStartDatetime >= dateadd(day,-1,getdate()))) OR (@showFutureEventsOnly <> 1))
AND ((@kennelId = '00000000-0000-0000-0000-000000000000') OR (e.KennelId = @kennelId))
AND e.EventStartDatetime <= dateadd(day,@daysInTheFuture,getdate())
AND e.EventStartDatetime >= dateadd(day,-@daysInThePast,getdate())
AND ((@filterByFacebookId = 0) OR ((@filterByFacebookId = 1) AND (TRIM(e.EventFacebookId) in (SELECT item from #facebookIdTemp))))
ORDER BY e.EventStartDatetime ASC

DROP TABLE #facebookIdTemp

GO
/****** Object:  StoredProcedure [HC].[getSongs]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [HC].[getSongs]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@KennelId uniqueidentifier = null,
@ShowAllSongs smallint = null

AS

BEGIN

SET NOCOUNT ON

-- EXEC HC.getSongs
-- EXEC HC.getSongs @ShowAllSongs = 1
-- EXEC HC.getSongs @KennelId = '5029DE3A-D231-47AA-BE72-ECE9BCCD55D1'

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END


IF (@showAllSongs IS NULL) SET @showAllSongs = 0


if (@KennelId is not null)
BEGIN
	SET NOCOUNT ON
	SELECT s.[id] as SongId
		  ,[SongName]
		  ,[Lyrics]
		  ,datalength([Lyrics]) as LyricsLength
		  ,[Rank]
		  ,case when datalength(coalesce([ImageUrl],'')) < 4 then 'https://harriercentral.blob.core.windows.net/harrier/MissingLogo.png' else [ImageUrl] end as [ImageUrl]
		  ,','+[Tags]+',' as [Tags]
		  ,case when [BawdyRating] = 0 then 'Good enough for mom'
			 when [BawdyRating] = 1 then 'Juvenile'
			 when [BawdyRating] = 2 then 'A bit naughty :-)'
			 when [BawdyRating] = 3 then 'Downright nasty !!!'
			 when [BawdyRating] = 4 then 'Can you say that in public?' end as [BawdyRatingText]
		  ,[BawdyRating] 
		  ,[AudioUrl]
		  ,[TuneOf] 
		  ,[Notes]
		  ,[Actions]
		  ,[Variants]
		  ,CASE WHEN (ksm.id is not null) THEN ksm.[Following] ELSE 0 END AS [Following]
		  ,0 as ClientSideCounter -- this is a bit of a hack we need to get the ClientSideCounter in the response so Configure.IT can access it
		  from HC.Song s
		  LEFT OUTER JOIN HC.KennelSongMap ksm on s.id = ksm.SongId and ksm.KennelId = @KennelId 
		  WHERE ((@ShowAllSongs <> 0) OR ((ksm.id IS NOT NULL)) AND (ksm.[Following] = 1))
		  ORDER BY SongName
		 

END
ELSE
BEGIN
	SELECT s.[id] as SongId
		  ,[SongName]
		  ,[Lyrics]
		  ,datalength([Lyrics]) as LyricsLength
		  ,[Rank]
		  ,case when datalength(coalesce([ImageUrl],'')) < 4 then 'https://harriercentral.blob.core.windows.net/harrier/MissingLogo.png' else [ImageUrl] end as [ImageUrl]
		  ,[Tags]
		  ,case when [BawdyRating] = 0 then 'Good enough for mom'
			 when [BawdyRating] = 1 then 'Juvenile'
			 when [BawdyRating] = 2 then 'A bit naughty :-)'
			 when [BawdyRating] = 3 then 'Downright nasty !!!'
			 when [BawdyRating] = 4 then 'Can you say that in public?' end as [BawdyRatingText]
		  ,[BawdyRating] 
		  ,[AudioUrl]
		  ,[TuneOf] 
		  ,[Notes]
		  ,[Actions]
		  ,[Variants]
		  ,[Following] = 0
		  ,0 as ClientSideCounter -- this is a bit of a hack we need to get the ClientSideCounter in the response so Configure.IT can access it
		  from HC.Song s
		  WHERE ((@ShowAllSongs = 1) OR (s.AutoAddToKennel <> 0))
		  ORDER BY SongName
END

END
GO
/****** Object:  StoredProcedure [HC].[getSuggestedEventNumber]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC].[getSuggestedEventNumber]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@kennelId uniqueidentifier,
@proposedEventDate datetime


AS
-- currently we are only supporting a single event per day per kennel which is why we are casting everything to date only

-- returns the Guid for the event in ResultStr
-- returns the proposed run number in ResultInt
-- if an event exists on the day, but has been deleted, returns -99999 in the ResultInt

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

set @proposedEventDate = cast(@proposedEventDate as Date)

-- EXEC HC.getSuggestedEventNumber @kennelId = '5029de3a-d231-47aa-be72-ece9bccd55d1', @proposedEventDate = '4/27/2018 12:00:00 AM'

DECLARE @previousEventDate datetime
DECLARE @nextEventDate datetime

SELECT @previousEventDate = dateadd(minute,2,cast(cast(max(e.EventStartDatetime) as date)as datetime)) from HC.Event e where e.KennelId = @kennelId and cast(e.EventStartDatetime as date) < @proposedEventDate and e.deleted = 0
SELECT @nextEventDate = dateadd(minute,-2,cast(cast(min(e.EventStartDatetime) as date)as datetime)) from HC.Event e where e.KennelId = @kennelId and cast(e.EventStartDatetime as date) > @proposedEventDate and e.deleted = 0

-- start by checking if there is already an event for this Kennel with this exact date and time / for now we don't allow this.

if (select count(*) from HC.Event WHERE KennelId = @kennelId AND IsCountedRun = 1 AND cast(EventStartDatetime as Date) = @proposedEventDate) <> 0
BEGIN
	-- Return -99999 if there is an event, but it has been deleted
	select top 1 e.id as ResultStr, 
	case when (e.deleted = 0 AND e.isVisible <> 0) THEN e.EventNumber ELSE -99999 END as ResultInt,
	COALESCE(@previousEventDate,'1/1/1938') as PreviousEventDate, 
	COALESCE(@nextEventDate,'1/1/2100') as NextEventDate,
	(SELECT count(*) from HC.HasherEventMap hem where hem.EventId = e.id AND hem.UserStartEvent is not null) as EventAttendeeCount
	FROM HC.Event e 
	WHERE KennelId = @kennelId AND IsCountedRun = 1 AND cast(EventStartDatetime as Date) = @proposedEventDate
END
ELSE
BEGIN

DECLARE @lastNumberedEventDate datetime
DECLARE @lastEventNumber int
DECLARE @nextNumberedEventDate datetime
DECLARE @nextEventNumber int

-- look back in time from the proposed event and find the last event with an absolute event number
-- we will count forward from there
SELECT top 1 @lastNumberedEventDate = cast(EventStartDatetime as Date), @lastEventNumber = AbsoluteEventNumber FROM HC.Event 
WHERE KennelId = @kennelId
AND deleted = 0 AND IsVisible <> 0
AND cast(EventStartDatetime as Date) < @proposedEventDate
AND AbsoluteEventNumber is not null
AND IsCountedRun = 1
ORDER BY EventStartDatetime desc

SET @lastEventNumber = COALESCE(@lastEventNumber,0)
SET @lastNumberedEventDate = COALESCE(@lastNumberedEventDate,'1/1/1900')

SELECT top 1 @nextNumberedEventDate = cast(max(EventStartDatetime) as date), @nextEventNumber = AbsoluteEventNumber FROM HC.Event 
WHERE KennelId = @kennelId
AND deleted = 0 AND IsVisible <> 0
AND cast(EventStartDatetime as Date) > @proposedEventDate
AND AbsoluteEventNumber is not null
AND IsCountedRun = 1
GROUP BY AbsoluteEventNumber
ORDER BY max(EventStartDatetime)

if (@lastEventNumber <> 0)
	BEGIN
		-- count forward from the last absolute event number to assign the new event number
		select '00000000-0000-0000-0000-000000000000' as ResultStr, sum(EventNumberIncrement)+@lastEventNumber as ResultInt, 
		COALESCE(@previousEventDate,'1/1/1938') as PreviousEventDate, 
		COALESCE(@nextEventDate,'1/1/2100') as NextEventDate,
		cast(0 as int) as EventAttendeeCount
		from HC.Event 
		WHERE KennelId = @kennelId
		AND deleted = 0 and IsVisible <> 0
		AND cast(EventStartDatetime as Date) < @proposedEventDate
		AND EventStartDatetime >= @lastNumberedEventDate
		AND IsCountedRun = 1
	END
ELSE
	-- we were unable to find a last event with an absolute number, so now look forward and see if we
	-- can find one in the future. If so, we will use this to count backward to get the
	-- proposed run number
	BEGIN


		--select @nextEventNumber, @nextNumberedEventDate

		if (@nextNumberedEventDate is not null)
		BEGIN
			select '00000000-0000-0000-0000-000000000000' as ResultStr, coalesce(@nextEventNumber,1) - sum(EventNumberIncrement) as ResultInt, 
			COALESCE(@previousEventDate,'1/1/1938') as PreviousEventDate, 
			COALESCE(@nextEventDate,'1/1/2100') as NextEventDate,
			cast(0 as int) as EventAttendeeCount
			from HC.Event 
			WHERE KennelId = @kennelId
			AND deleted = 0 and IsVisible <> 0
			AND cast (EventStartDatetime as Date) > @proposedEventDate
			AND EventStartDatetime <= @nextNumberedEventDate
			AND IsCountedRun = 1
		END
		ELSE
		BEGIN
			declare @ResultStr nvarchar(50), @ResultInt int

			SELECT @ResultInt = sum(EventNumberIncrement)+1, @ResultStr = '00000000-0000-0000-0000-000000000000'
			FROM HC.Event
			WHERE KennelId = @kennelId
			AND deleted = 0 and IsVisible <> 0
			AND cast (EventStartDatetime as Date) < @proposedEventDate
			AND IsCountedRun = 1

			SELECT coalesce(@ResultStr,'00000000-0000-0000-0000-000000000000') as ResultStr, coalesce(@ResultInt,1) as ResultInt, 
			COALESCE(@previousEventDate,'1/1/1938') as PreviousEventDate, 
			COALESCE(@nextEventDate,'1/1/2100') as NextEventDate,
			cast(0 as int) as EventAttendeeCount
		END

	END

END
GO
/****** Object:  StoredProcedure [HC].[getUsersByEventForAdmin]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [HC].[getUsersByEventForAdmin]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@EventId uniqueidentifier,
@TargetUserId uniqueidentifier = null

AS

SET NOCOUNT ON

-- exec HC.getUsersByEventForAdmin @eventId = '010AB607-BD6A-4DC7-B108-B729A76DEA85',@userId = '83294C62-2FFE-4FCB-A2F5-52AADD6CEAA0', @accessToken = ''

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END


	DECLARE @AtHashCount smallint
	DECLARE @OnInCount smallint
	DECLARE @OnTrailCount smallint
	DECLARE @PaidCount smallint
	DECLARE @WaitingForCount smallint

	IF (@TargetUserId = '00000000-0000-0000-0000-000000000000') SET @TargetUserId = null

	SELECT 
		@AtHashCount = count(hem2.UserStartEvent),
		@OnInCount = count(hem2.UserEndEvent),
		@OnTrailCount = count(hem2.UserStartEvent)-count(hem2.UserEndEvent) 
	FROM HC.HasherEventMap hem2 WHERE hem2.EventId = @EventId

	SELECT 
		@WaitingForCount = count(*)
	FROM HC.HasherEventMap hem WHERE hem.EventId = @EventId AND hem.UserStartEvent IS NULL AND hem.RsvpState = 3

	SELECT @PaidCount = count(*) from HC.Payment p where p.EventId = @EventId and p.CancelledDate is null


	SELECT coalesce(sum(p.creditAmount)-sum(p.debitAmount),0) as Credit
			,p.UserId
			,e.KennelId
	INTO #creditTemp
	FROM HC.Hasher h
	INNER JOIN HC.Event e ON e.id = @EventId
	INNER JOIN HC.Kennel k ON k.id = e.KennelId 
	INNER JOIN HC.Payment p on p.UserId = h.id
	LEFT OUTER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = k.id AND hkm.UserId = h.id
	LEFT OUTER JOIN HC.HasherEventMap hem on hem.UserId = h.id AND hem.EventId = @EventId
	WHERE (
		 ((hem.EventId = e.id) AND (hem.UserId = h.id)) OR -- this covers users who have RSVP'ed
		 ((hkm.KennelId = k.id) AND (hkm.UserId = h.id) AND ((hkm.Following = 1) OR (hkm.IsMember = 1)))  -- this covers users who are either members of a kennel or following that kennel
		)
		AND e.deleted = 0 AND e.IsVisible <> 0
		AND p.CancelledDate is null
		AND ((@TargetUserId IS NULL) OR (h.id = @TargetUserId))
	GROUP BY 
		p.UserId, e.KennelId

SELECT
	@EventId as EventId
	,h.id as UserId
	,coalesce(hkm.Following,0) as isFollowing
	,coalesce(hkm.IsMember,0) as isMember
	,case when hem.id is null then 0 else 1 end as isRsvped
	-- From HC.HasherEventMap
	 ,hem.id AS [HasherEventMapId]

	--,hem.[RegistrationId]
	,coalesce(hem.[IsHare],0) as isHare
	,coalesce(hem.[VirginVisitorType],0) as VirginVisitorType
	,hem.[UserStartEvent]
	,hem.[UserEndEvent]
	--,hem.[Rsvp]
	,CASE 
		WHEN hem.[UserStartEvent] IS NOT NULL
			AND hem.[UserEndEvent] IS NULL
			THEN 4
		WHEN hem.[UserStartEvent] IS NOT NULL
			AND hem.[UserEndEvent] IS NOT NULL
			THEN 5
		ELSE coalesce(hem.RsvpState, 0)
		END AS UserStatus

	-- From HC.Payment
	,CASE 
		WHEN (
				SELECT coalesce(count(*), 0)
				FROM HC.Payment p
				WHERE HasherEventMapId = hem.id
					AND p.CancelledDate IS NULL
				) = 0
			THEN 0
		ELSE 1
		END AS isPaid

	-- FROM HC.Hasher
	,coalesce(CASE 
		WHEN h.NameDisplayPreference = 1
			THEN h.HashName
		WHEN h.NameDisplayPreference = 2
			THEN h.FirstName + ' ' + h.LastName
		ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
		END,hem.DisplayName,'<no name>')
		 AS DisplayName
	,CASE 
		WHEN (hem.[VirginVisitorType] = 0)
			THEN h.Photo
		WHEN (hem.[VirginVisitorType] = 1)	
			THEN 'https://harriercentral.blob.core.windows.net/harrier/Virgin.png'
		WHEN (hem.[VirginVisitorType] = 2)	
			THEN 'https://harriercentral.blob.core.windows.net/harrier/Visitor.png'
		ELSE
			CASE WHEN h.Photo IS NULL THEN	
			'https://harriercentral.blob.core.windows.net/harrier/Visitor.png'
			ELSE
				h.Photo
			END
		END AS Photo

	-- Aggregates from HC.HasherEventMap
	,coalesce(CASE 
		WHEN (hem.[VirginVisitorType] <> 0)
			THEN CASE WHEN hem.UserStartEvent IS NOT NULL THEN 1 ELSE 0 END
		ELSE
			coalesce(hem.TotalRunsThisKennel,0) END,0)
		AS UserRunCount

	-- Live totals for display at top of HasherList
	,@WaitingForCount AS WaitingForCount
	,@AtHashCount AS AtHashCount
	,@OnInCount AS OnInCount
	,@OnTrailCount AS OnTrailCount
	,@PaidCount AS PaidCount
	,CASE WHEN COALESCE(hkm.IsMember, 0) = 1
							THEN coalesce(e.EventPriceForMembers, k.DefaultEventPriceForMembers, e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers, 0)
						ELSE coalesce(e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers, e.EventPriceForMembers, k.DefaultEventPriceForMembers, 0)
						END AS EventPrice
    , coalesce(e.EventCurrencyType, k.DefaultEventCurrencyType, 'en-us') as EventLocale
	, k.AllowNegativeCredit
	, coalesce(ct.Credit,0) as Credit

FROM HC.Hasher h
INNER JOIN HC.Event e ON e.id = @EventId
INNER JOIN HC.Kennel k ON k.id = e.KennelId 
LEFT OUTER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = k.id AND hkm.UserId = h.id
LEFT OUTER JOIN HC.HasherEventMap hem on hem.UserId = h.id AND hem.EventId = @EventId
LEFT OUTER JOIN #creditTemp ct ON ct.UserId = h.id and ct.KennelId = k.id

WHERE (
	 ((hem.EventId = e.id) AND (hem.UserId = h.id)) OR -- this covers users who have RSVP'ed
	 ((hkm.KennelId = k.id) AND (hkm.UserId = h.id) AND ((hkm.Following = 1) OR (hkm.IsMember = 1)))  -- this covers users who are either members of a kennel or following that kennel
	)
	AND e.deleted = 0 and e.IsVisible <> 0
	AND ((@TargetUserId IS NULL) OR (h.id = @TargetUserId))
ORDER BY 
	COALESCE(
	CASE 
		WHEN h.NameDisplayPreference = 1
			THEN h.HashName
		WHEN h.NameDisplayPreference = 2
			THEN h.FirstName + ' ' + h.LastName
		ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
		END
		,hem.DisplayName,'<no name>')





GO
/****** Object:  StoredProcedure [HC].[joinEvent]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [HC].[joinEvent]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @eventId uniqueidentifier,
 
 @state VARCHAR(10) = '-1',
 @isHare VARCHAR(10) = '-1',
 @isAttending VARCHAR(10) = '-1',

 @resultRequested nvarchar(25) = 'Attendance totals'

AS

BEGIN

-- EXEC HC.JoinEvent @eventId = '7B10155A-92D4-40D7-929A-CF2BDE968444', @userId = '624c51b3-2f64-4de5-9458-b506e75ac544'

SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

DECLARE @isHareNumeric smallint
DECLARE @rsvpState smallint
DECLARE @isAttendingNumeric smallint

SET @isHareNumeric = CAST(@isHare as smallint)
SET @isAttendingNumeric = CAST(@isAttending as smallint)
SET @rsvpState = CAST(@state as smallint)

IF NOT EXISTS(SELECT * FROM HC.HasherEventMap WHERE UserId = @userId AND EventId = @eventId)
BEGIN 
	INSERT INTO HC.HasherEventMap(UserId,EventId) VALUES (@userId,@eventId) 
END

IF @isHareNumeric <> -1
	UPDATE HC.HasherEventMap SET isHare = @isHareNumeric WHERE UserId=@userId AND EventId = @eventId 

IF @rsvpState <> -1
	UPDATE HC.HasherEventMap SET RsvpState = @rsvpState, Rsvp = getdate() WHERE UserId=@userId AND EventId = @eventId 

IF @isAttendingNumeric <> -1
BEGIN
	UPDATE HC.HasherEventMap SET RsvpState = 3, UserStartEvent = CASE WHEN @isAttendingNumeric = 0 THEN null ELSE getdate() END WHERE UserId=@userId AND EventId = @eventId 
	
	EXEC HC.nonApi_adjustHasherRunCounts @limitByUser = 1,@userId = @userId
END

	
DECLARE @attending smallint
DECLARE @notAttending smallint
DECLARE @maybe smallint

-- TODO: We may have to join on these with HC.Event to filter deleted events out of the count
IF (@resultRequested = 'Attendance totals')
BEGIN
	SELECT @attending = count(*) from HC.HasherEventMap WHERE EventId = @EventId and RsvpState = 3
	SELECT @maybe = count(*) from HC.HasherEventMap WHERE EventId = @EventId and RsvpState = 2
	SELECT @notAttending = count(*) from HC.HasherEventMap WHERE EventId = @EventId and RsvpState = 1

	SELECT @attending as AttendingEvent, @notAttending as NotAttendingEvent, @maybe as MaybeAttendingEvent
END

if (@resultRequested = 'Run counts')
BEGIN
	SELECT evt.id AS EventId, TotalRunsAllKennels,TotalRunsThisKennel FROM HC.HasherEventMap hem 
	INNER JOIN HC.Event evt ON hem.EventId = evt.id
	WHERE hem.UserId = @userId 
	AND evt.EventStartDatetime >= 
		(SELECT evt2.EventStartDatetime FROM HC.Event evt2 WHERE evt2.id = @eventId) 
END

END





GO
/****** Object:  StoredProcedure [HC].[joinEventAsVisitor]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC].[joinEventAsVisitor]  

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@eventId uniqueidentifier, 
@displayName nvarchar(250), 
@virginVisitorType smallint

AS

-- exec HC.joinEventAsVisitor @eventId = '7B10155A-92D4-40D7-929A-CF2BDE968444', @displayName = 'Stacy', @virginVisitorType = '0'

SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

DECLARE @isGenericUserPresent smallint  
DECLARE @kennelId uniqueidentifier   
DECLARE @result nvarchar(120)
DECLARE @eventPrice smallmoney

-- The segment control is 0-based, so add 1 to get our database native virginVisitorType
SET @virginVisitorType = @virginVisitorType + 1

-- only two types of Virgin/Visitors at the moment... check to make sure it's one of these
IF ((@VirginVisitorType <> 1) AND (@VirginVisitorType <> 2))   
	SET @result = 'Unrecognized VirginVisitor Type'
ELSE
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
				,[Description]       
				,[HomeLatitude]       
				,[HomeLongitude])   
				SELECT     
					k.id    
					,'Placeholder user'    
					,coalesce(k.Latitude,0)
					,coalesce(k.Longitude,0)   
				FROM HC.Event e 
				INNER JOIN HC.Kennel k 
				ON e.KennelId = k.id   
				WHERE e.id = @eventId AND e.deleted = 0 and e.IsVisible <> 0   
		
		END    

		DECLARE @hasherEventMapId uniqueidentifier
		SET @hasherEventMapId = NEWID()

		-- Now, insert a record for the visitor (virgin) into HC.HasherEventMap and return 'Success' as the result

		INSERT INTO [HC].[HasherEventMap]
				   ([id]
				   ,[EventId]
				   ,[UserId]
				   ,[UserStartEvent]
				   ,[EventCost]
				   ,[Rsvp]
				   ,[RsvpState]
				   ,[VirginVisitorType] -- 0 = HasherInSystem, 1 = Virgin, 2 = Visitor
				   ,[DisplayName])

				SELECT @hasherEventMapId
					,@eventId
					,e.KennelId 
					,getdate()
					,e.EventPriceForNonMembers
					,getdate()
					,3 -- RSVP state as 'coming'
					,@VirginVisitorType
					,@displayName
					from HC.Event e where e.id = @eventId and e.deleted = 0 and e.IsVisible <> 0

		DECLARE @locale nvarchar(25)
		DECLARE @eventPriceStr nvarchar(25)

		SELECT @eventPrice = coalesce(e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,e.EventPriceForMembers,k.DefaultEventPriceForMembers,0)
		
		,@locale = coalesce(e.EventCurrencyType,k.DefaultEventCurrencyType,'en-us')
		FROM HC.Event e
		INNER JOIN HC.Kennel k on k.id = e.KennelId
		WHERE e.id = @eventId AND e.deleted = 0 and e.IsVisible <> 0

		SET @eventPriceStr = REPLACE(FORMAT(@eventPrice,'C',@locale),',','.')
		SET @result = @displayName + ', you are registered for the Hash'

		DECLARE @actionSheetText nvarchar(120)

		-- this is the format required to pull up an action sheet in the Configure.IT mobile app
		SET @actionSheetText = 'Cancel,Not Paid,Free run,Cash ('+TRIM(@eventPriceStr)+'),Bank Transfer ('+TRIM(@eventPriceStr)+')'
		if (@actionSheetText is null) SET @actionSheetText = 'Cancel,Not Paid,Free Run,Cash,Bank Transfer'


END

SELECT @result as Result, @actionSheetText as ActionSheetText, @hasherEventMapId as HasherEventMapId

GO
/****** Object:  StoredProcedure [HC].[joinKennel]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [HC].[joinKennel]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @kennelId uniqueidentifier,
 @targetUserId uniqueidentifier,
 @isFollowing smallint = null,
 @isMember smallint = null,
 @isHomeKennel smallint = null

AS

BEGIN

	if (@isFollowing = -1) SET @isFollowing = null
	if (@isMember = -1) SET @isMember = null
	if (@isHomeKennel = -1) SET @isHomeKennel = null

-- EXEC HC.joinKennel @kennelId = '9e85d401-213d-47ad-8a6e-44e5476925f4', @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @state = '1'

	SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END


	IF @isHomeKennel = 1 SET @isFollowing = 1
	IF @isMember = 1 SET @isFollowing = 1

	-- TODO: delete this line once we have membership separate from following
	SET @isMember = @isFollowing

	if @isFollowing = 0 OR @isFollowing = 2
	BEGIN
		if ((SELECT count(*) from HC.Hasher where id = @targetUserId and Home_KennelId = @kennelId) > 0)
		BEGIN
			UPDATE HC.Hasher SET Home_KennelId = NULL WHERE id = @targetUserId and Home_KennelId = @kennelId
		END	
	END

	IF @isHomeKennel = 1
	BEGIN
		UPDATE HC.Hasher SET Home_KennelId = @kennelId WHERE id = @targetUserId
	END

	IF NOT EXISTS(SELECT * FROM HC.HasherKennelMap WHERE UserId = @targetUserId AND KennelId = @kennelId)
		BEGIN 
			INSERT INTO HC.HasherKennelMap(UserId,KennelId,[Following],[IsMember]) VALUES (@targetUserId,@kennelId,coalesce(@isFollowing,0),coalesce(@isMember,0)) 
		END
	ELSE
		BEGIN
			UPDATE HC.HasherKennelMap SET 
				[Following] = coalesce(@isFollowing,[Following]),
				[IsMember] = coalesce(@isMember,[isMember])
				FROM HC.HasherKennelMap
				WHERE UserId=@targetUserId AND KennelId = @kennelId 
		END

	DECLARE @result int
	SELECT @result = COUNT(*) FROM HC.HasherKennelMap hkm where hkm.KennelId = @kennelId AND IsMember = 1
		
	SELECT @result as [result], 'Unused' as [message]

END





GO
/****** Object:  StoredProcedure [HC].[nonApi_adjustHasherRunCounts]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC].[nonApi_adjustHasherRunCounts]

@limitByUser smallint = null,
@userId uniqueidentifier = null,
@hasherEventMapId uniqueidentifier = null

AS


BEGIN

-- EXEC HC.nonApi_adjustHasherRunCounts @userId = '624C51B3-2F64-4DE5-9458-B506E75AC544', @limitByUser = 1

SET NOCOUNT ON


SET @limitByUser = coalesce(@limitByUser,0)


-- Start by calculating the updated run counts and putting these into a temp table
SELECT 
hem.id
,evt.KennelId
,hem.UserId
,hem.VirginVisitorType
,hem.UserStartEvent
,evt.EventStartDatetime
,sum(case when ((hem.isHare = 1) AND (hem.AttendenceState >=20)) then evt.UserEventCounterIncrement else 0 end) over (PARTITION BY hem.UserId, evt.IsCountedRun, evt.KennelId order by evt.EventStartDatetime asc,evt.id) + coalesce(hkm.HistoricalHaringCount,0) as TotalHaringThisKennel
,sum(case when ((hem.isHare = 0) AND (hem.AttendenceState >=20)) then evt.UserEventCounterIncrement else 0 end) over (PARTITION BY hem.UserId, evt.IsCountedRun, evt.KennelId order by evt.EventStartDatetime asc,evt.id) + coalesce(hkm.HistoricalPackRunCount,0) as TotalPackRunsThisKennel
,sum(case when ((hem.isHare = 1) AND (hem.AttendenceState >=20)) then evt.UserEventCounterIncrement else 0 end) over (PARTITION BY hem.UserId, evt.IsCountedRun order by evt.EventStartDatetime asc,evt.id) + (select sum(hkm2.HistoricalHaringCount) from HC.HasherKennelMap hkm2 where hkm2.UserId = hem.UserId) as TotalHaringAllKennels
,sum(case when ((hem.isHare = 0) AND (hem.AttendenceState >=20)) then evt.UserEventCounterIncrement else 0 end) over (PARTITION BY hem.UserId, evt.IsCountedRun order by evt.EventStartDatetime asc,evt.id) + (select sum(hkm2.HistoricalPackRunCount) from HC.HasherKennelMap hkm2 where hkm2.UserId = hem.UserId) as TotalPackRunsAllKennels
INTO #temp
FROM HC.HasherEventMap hem
INNER JOIN HC.Event evt on hem.EventId = evt.id
LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.userId = hem.UserId and hkm.KennelId = evt.KennelId
WHERE 
--hem.VirginVisitorType = 0 -- only track run counts for non-virgins / non-visitors
 evt.deleted = 0 AND evt.IsVisible <> 0
AND (((@limitByUser = 1) AND (hem.userId = @userId)) OR ((@limitByUser = 2) AND (hem.id = @hasherEventMapId)) OR (@limitByUser = 0))
-- This line is commented out for testing, eventually add it back in for production
-- AND evt.EventStartDatetime <= dateadd(day,1,getdate())
AND evt.IsCountedRun = 1
AND evt.EventStartDatetime < dateadd(day,1,getdate())

-- now, apply updates only where they are required
UPDATE HC.HasherEventMap 
SET TotalHaringThisKennel =  t.TotalHaringThisKennel  , 
TotalPackRunsThisKennel =  t.TotalPackRunsThisKennel , 
TotalRunsThisKennel = t.TotalHaringThisKennel + t.TotalPackRunsThisKennel , 
TotalHaringAllKennels =  t.TotalHaringAllKennels , 
TotalPackRunsAllKennels =  t.TotalPackRunsAllKennels , 
TotalRunsAllKennels = t.TotalHaringAllKennels + t.TotalPackRunsAllKennels 
FROM HC.HasherEventMap hem
INNER JOIN #temp t on t.id = hem.id
WHERE (coalesce(hem.TotalHaringThisKennel,-99999) <>  t.TotalHaringThisKennel )
OR (coalesce(hem.TotalPackRunsThisKennel,-99999) <>  t.TotalPackRunsThisKennel)
OR (coalesce(hem.TotalRunsThisKennel,-99999) <>  t.TotalHaringThisKennel + t.TotalPackRunsThisKennel )
OR (coalesce(hem.TotalHaringAllKennels,-99999) <>   t.TotalHaringAllKennels )
OR (coalesce(hem.TotalPackRunsAllKennels,-99999) <>  t.TotalPackRunsAllKennels )
OR (coalesce(hem.TotalRunsAllKennels,-99999) <>  t.TotalPackRunsAllKennels + t.TotalHaringAllKennels)


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
           ,[CurrentHaringCount])
select t.UserId
		,t.KennelId
		,0 as Following
		,0 as IsMember
		,'' as MismanagementRoleFlags
		,'' as AppAccessFlags
		,0 as HistoricalPackRunCount
		,0 as HistoricalHaringCount
		,0 as CurrentPackRunCount
		,0 as CurrentHaringCount
from #temp t left outer join HC.HasherKennelMap hkm on hkm.KennelId = t.KennelId AND hkm.UserId = t.UserId
WHERE hkm.id is null AND VirginVisitorType = 0


-- now update the run counts by kennel in HasherKennelMap
update HC.HasherKennelMap SET CurrentPackRunCount = t.TotalPackRunsThisKennel,CurrentHaringCount = t.TotalHaringThisKennel FROM HC.HasherKennelMap hkm 
inner join 
	(select max(tmp.TotalPackRunsThisKennel) as TotalPackRunsThisKennel
	,max(tmp.TotalHaringThisKennel) as TotalHaringThisKennel
	,tmp.UserId
	,tmp.KennelId 
	from #temp tmp 
	group by tmp.UserId,tmp.KennelId) t 
on hkm.UserId = t.UserId and hkm.KennelId = t.KennelId

drop table #temp

END

GO
/****** Object:  StoredProcedure [HC].[nonApi_getUserResult]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC].[nonApi_getUserResult]

@callingProcType int,
@eventId uniqueidentifier = null,
@targetUserId uniqueidentifier = null,
@hasherEventMapId uniqueidentifier = null

AS

SET NOCOUNT ON

	DECLARE @AtHashCount smallint
	DECLARE @OnInCount smallint
	DECLARE @OnTrailCount smallint
	DECLARE @PaidCount smallint
	DECLARE @WaitingForCount smallint

	IF (@targetUserId = '00000000-0000-0000-0000-000000000000') SET @targetUserId = null
	IF (@eventId = '00000000-0000-0000-0000-000000000000') SET @eventId = null

	if (@eventId is not null)
	BEGIN
		SELECT 
			@AtHashCount = sum(case when hem2.AttendenceState >= 20 then 1 else 0 end),
			@OnInCount = sum(case when hem2.AttendenceState >= 30 then 1 else 0 end),
			@OnTrailCount = sum(case when hem2.AttendenceState >= 20 then 1 else 0 end)-sum(case when hem2.AttendenceState >= 30 then 1 else 0 end) 
		FROM HC.HasherEventMap hem2 WHERE hem2.EventId = @EventId

		SELECT 
			@WaitingForCount = count(*)
		FROM HC.HasherEventMap hem WHERE hem.EventId = @EventId AND hem.AttendenceState < 20 AND hem.RsvpState = 3

		SELECT @PaidCount = count(*) from HC.Payment p where p.EventId = @EventId and p.CancelledDate is null
	END

	SELECT coalesce(sum(p.creditAmount)-sum(p.debitAmount),0) as Credit
			,p.UserId
			,e.KennelId
	INTO #creditTemp
	FROM HC.Hasher h
	INNER JOIN HC.Event e ON e.id = @EventId
	INNER JOIN HC.Kennel k ON k.id = e.KennelId 
	INNER JOIN HC.Payment p on p.UserId = h.id
	LEFT OUTER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = k.id AND hkm.UserId = h.id
	LEFT OUTER JOIN HC.HasherEventMap hem on hem.UserId = h.id AND hem.EventId = @EventId
	WHERE (
		 ((hem.EventId = e.id) AND (hem.UserId = h.id)) OR -- this covers users who have RSVP'ed
		 ((hkm.KennelId = k.id) AND (hkm.UserId = h.id) AND ((hkm.Following = 1) OR (hkm.IsMember = 1)))  -- this covers users who are either members of a kennel or following that kennel
		)
		AND e.deleted = 0 AND e.IsVisible <> 0
		AND p.CancelledDate is null
		AND ((@targetUserId IS NULL) OR (h.id = @targetUserId))
	GROUP BY 
		p.UserId, e.KennelId

SELECT
	@EventId as eventId
	,h.id as userId
	,coalesce(hkm.Following,0) as isFollowing
	,coalesce(hkm.IsMember,0) as isMember
	,case when hem.id is null then 0 else 1 end as isRsvped
	-- From HC.HasherEventMap
	,hem.id AS [hasherEventMapId]

	--,hem.[RegistrationId]
	,coalesce(hem.[IsHare],0) as isHare
	,coalesce(hem.[VirginVisitorType],0) as virginVisitorType
	,hem.[UserStartEvent] as userStartEvent
	,hem.[UserEndEvent] as userEndEvent
	--,hem.[Rsvp]
	,coalesce(hem.[RsvpState],0) as rsvpState
	,coalesce(hem.[AttendenceState],0) as attendenceState


	-- From HC.Payment

	,case when pay.id is not null then 1 else 0 end as isPaid
	,coalesce(pay.PaymentType,-1) as paymentType  

	-- FROM HC.Hasher
	,coalesce(h.email,'') as eMail
	,coalesce(h.facebookId,'') as facebookId
	,coalesce(h.firstName,'') as firstName
	,coalesce(h.HashName,'') as hashName
	,coalesce(h.lastName,'') as lastName
	,h.QR_code as qrCode
	,h.SupportCode as supportCode
	,case when @eventId is not null then '00000000-0000-0000-0000-000000000000' else coalesce(h.QR_secret_code,'00000000-0000-0000-0000-000000000000') end as qrSecretCode
	,coalesce(CASE WHEN (hem.[VirginVisitorType] <> 0)	
			THEN 
			coalesce(hem.DisplayName,'<no name>') + CASE WHEN (hem.[VirginVisitorType] = 1) THEN ' (Virgin)' ELSE ' (Visitor)' END	
		WHEN h.NameDisplayPreference = 1
			THEN h.HashName
		WHEN h.NameDisplayPreference = 2
			THEN h.FirstName + ' ' + h.LastName
		ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
		END,hem.DisplayName,'<no name>')
		 AS displayName
	,CASE 
		WHEN coalesce(hem.[VirginVisitorType],0) = 0
			THEN h.Photo
		WHEN (hem.[VirginVisitorType] = 1)	
			THEN 'bundle://avatar-virgin'
		WHEN (hem.[VirginVisitorType] = 2)	
			THEN 'bundle://avatar-visitor'
		ELSE
			CASE WHEN h.Photo IS NULL THEN	
			'bundle://avatar-visitor'
			ELSE
				h.Photo
			END
		END AS photo

	-- Aggregates from HC.HasherEventMap
	,coalesce(CASE 
		WHEN coalesce(hem.[VirginVisitorType],null) <> 0
			THEN CASE WHEN hem.AttendenceState >= 20 THEN 1 ELSE 0 END
		ELSE
			coalesce(hem.TotalRunsThisKennel,0) END,0)
		AS userRunCount

	-- Live totals for display at top of HasherList
	,@WaitingForCount AS waitingForCount
	,@AtHashCount AS atHashCount
	,@OnInCount AS onInCount
	,@OnTrailCount AS onTrailCount
	,@PaidCount AS paidCount
	,CASE WHEN COALESCE(hkm.IsMember, 0) = 1
							THEN coalesce(e.EventPriceForMembers, k.DefaultEventPriceForMembers, e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers, 0)
						ELSE coalesce(e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers, e.EventPriceForMembers, k.DefaultEventPriceForMembers, 0)
						END AS eventPrice
    , coalesce(e.EventCurrencyType, k.DefaultEventCurrencyType, 'en-us') as eventLocale
	, k.AllowNegativeCredit as allowNegativeCredit
	, coalesce(ct.Credit,0) as credit
	, c.CurrencySymbol as currencySymbol
	, c.DigitsAfterDecimal as digitsAfterDecimal
	
FROM HC.Hasher h
LEFT OUTER JOIN HC.Event e ON e.id = @EventId
LEFT OUTER JOIN HC.Kennel k ON k.id = e.KennelId 
LEFT OUTER JOIN HC.Country c on c.id = k.CountryId
LEFT OUTER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = k.id AND hkm.UserId = h.id
LEFT OUTER JOIN HC.HasherEventMap hem on hem.UserId = h.id AND hem.EventId = @EventId
LEFT OUTER JOIN HC.Payment pay on pay.HasherEventMapId = hem.id and pay.CancelledDate is null 
LEFT OUTER JOIN #creditTemp ct ON ct.UserId = h.id and ct.KennelId = k.id

WHERE (
		(@eventId is null) OR (
		(
			 ((hem.EventId = e.id) AND (hem.UserId = h.id)) OR -- this covers users who have RSVP'ed
			((hkm.KennelId = k.id) AND (hkm.UserId = h.id) AND ((hkm.Following = 1) OR (hkm.IsMember = 1)))  -- this covers users who are either members of a kennel or following that kennel
			)
			AND e.deleted = 0 and e.IsVisible <> 0)
		)
	AND ((@TargetUserId IS NULL) OR (h.id = @TargetUserId))
ORDER BY 
	COALESCE(
	CASE 
		WHEN h.NameDisplayPreference = 1
			THEN h.HashName
		WHEN h.NameDisplayPreference = 2
			THEN h.FirstName + ' ' + h.LastName
		ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
		END
		,hem.DisplayName,'<no name>')

DROP TABLE #creditTemp
GO
/****** Object:  StoredProcedure [HC].[nonApi_updateEventFromFacebook]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC].[nonApi_updateEventFromFacebook]

@FacebookEventId nvarchar(250),
@KennelId uniqueidentifier,
@EventName nvarchar(250) = NULL,
@EventDescription nvarchar(4000) = NULL,
@StartTime datetimeoffset = NULL,
@EventImage nvarchar(500) = NULL,
@PlaceName nvarchar(500) = NULL,
@City nvarchar(500) = NULL,
@Country nvarchar(500) = NULL,
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

IF (SELECT COUNT(*) FROM HC.Event evt where evt.EventFacebookId = @FacebookEventId and evt.KennelId = @KennelId) > 0
BEGIN

	DECLARE @timeChanged NVARCHAR(20)
	DECLARE @nameChanged NVARCHAR(20)
	DECLARE @descChanged NVARCHAR(20)
	DECLARE @locChanged NVARCHAR(20)
	DECLARE @evtName NVARCHAR(500)
	

	SELECT 
		@timeChanged = CASE WHEN ((@StartTime IS NOT NULL) AND (cast (@StartTime as DateTime) <> evt.[EventStartDatetime])) THEN 'Time, ' ELSE '' END
		,@nameChanged = CASE WHEN ((@EventName IS NOT NULL) AND (@EventName <> evt.[EventName])) THEN 'Name, ' ELSE '' END
		,@descChanged = CASE WHEN ((@EventDescription IS NOT NULL) AND (@EventDescription <> evt.[EventDescription])) THEN 'Description, ' ELSE '' END
		,@locChanged = CASE WHEN ((@PlaceName IS NOT NULL) AND (@PlaceName <> evt.[LocationOneLineDesc])) THEN 'Location, ' ELSE '' END
		,@evtName = coalesce(@EventName,evt.[EventName])
		,@eventId = id
	FROM HC.Event evt WHERE 
	  evt.EventFacebookId = @FacebookEventId 
	  AND evt.KennelId = @KennelId

	UPDATE HC.Event SET 
      [FacebookRecordLastUpdated] = getdate()
      ,[EventStartDatetime] = coalesce(@StartTime,evt.[EventStartDatetime])
      ,[EventName] = coalesce(@EventName,evt.[EventName])
      ,[EventDescription] = coalesce(@EventDescription,evt.[EventDescription])
      ,[EventImage] = coalesce(@EventImage,evt.[EventImage])
      ,[EventImageOffsetX] = coalesce(@OffsetX,evt.[EventImageOffsetX])
      ,[EventImageOffsetY] = coalesce(@OffsetY,evt.[EventImageOffsetY])

      ,[LocationOneLineDesc] = coalesce(@PlaceName,evt.[LocationOneLineDesc])
      ,[LocationCity] = coalesce(@City,evt.[LocationCity])
      ,[LocationStreet] = coalesce(@Street,evt.[LocationStreet])
      ,[LocationPostCode] = coalesce(@Zip,evt.[LocationPostCode])
      ,[LocationCountry] = coalesce(@Country,evt.[LocationCountry])

      ,[FbLatitude] = coalesce(@Latitude,evt.[FbLatitude])
      ,[FbLongitude] = coalesce(@Longitude,evt.[FbLongitude])

      ,[AbsoluteEventNumber] = coalesce(@AbsoluteEventNumber,evt.[AbsoluteEventNumber])

	  ,[IsCountedRun] = coalesce(@IsCountedRun,evt.[IsCountedRun])
	  ,[IsVisible] = coalesce(@IsVisible,evt.[IsVisible])

	  FROM HC.Event evt WHERE id = @eventId
	  AND 
	  (
      ((@ForceUpdate IS NOT NULL) AND (@ForceUpdate = 1))
		OR ((@StartTime IS NOT NULL) AND (cast (@StartTime as DateTime) <> evt.[EventStartDatetime]))
		OR ((@EventName IS NOT NULL) AND (@EventName <> evt.[EventName]))
		OR ((@EventDescription IS NOT NULL) AND (@EventDescription <> evt.[EventDescription]))
		OR ((@EventImage IS NOT NULL) AND (@EventImage <> evt.[EventImage]))
		OR ((@OffsetX IS NOT NULL) AND (@OffsetX <> evt.[EventImageOffsetX]))
		OR ((@OffsetY IS NOT NULL) AND (@OffsetY <> evt.[EventImageOffsetY]))
		OR ((@PlaceName IS NOT NULL) AND (@PlaceName <> evt.[LocationOneLineDesc]))
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
	     SELECT 'Rows updated = 0' as Result
	  END
	  ELSE
	  BEGIN
		 
		 EXEC HC.nonApi_updateRunNumbers  @eventId = @eventId

		 UPDATE HC.Event SET lastModified = getdate() WHERE id = @eventId

		 IF (@latitude is not null AND @longitude is not null)
		 BEGIN
			UPDATE HC.Event 
			SET EventGeolocation = geography::Point(coalesce(evt.Latitude,@latitude), coalesce(evt.Longitude,@longitude), 4326) 
			FROM HC.Event evt
				WHERE id = @eventId
		 END

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
		 
		 SELECT @res AS Result

	  END

END
ELSE
BEGIN

SET @eventId = newid()

INSERT INTO [HC].[Event]
           (id
		   ,[EventFacebookId]
           ,[FacebookRecordLastUpdated]
           ,[EventStartDatetime]
           ,[KennelId]
           ,[IsCountedRun]
		   ,[IsVisible]
           ,[AbsoluteEventNumber]
           ,[EventName]
           ,[EventDescription]
           ,[EventImage]
           ,[EventImageOffsetX]
           ,[EventImageOffsetY]
           ,[LocationOneLineDesc]
           ,[LocationCity]
           ,[LocationStreet]
           ,[LocationPostCode]
           ,[LocationCountry]
           ,[FbLatitude]
           ,[FbLongitude]
			)
     VALUES
           (
		    @eventId
		   ,@FacebookEventId 
           ,getdate() -- <FacebookRecordLastUpdated, datetime,>
           ,@StartTime 
           ,@KennelId 
           ,coalesce(@IsCountedRun,1)
           ,coalesce(@IsVisible,1)
           ,@AbsoluteEventNumber
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
           ,@Latitude
           ,@Longitude)

    EXEC HC.nonApi_updateRunNumbers  @eventId = @eventId

	UPDATE HC.Event SET lastModified = getdate() WHERE id = @eventId

	IF (@latitude is not null AND @longitude is not null)
	BEGIN
		UPDATE HC.Event 
		SET EventGeolocation = geography::Point(coalesce(evt.Latitude,@latitude), coalesce(evt.Longitude,@longitude), 4326) 
		FROM HC.Event evt
			WHERE id = @eventId
	END

	SELECT 'A new event, ' + @EventName + ', has been added from Facebook' as Result
END


END
GO
/****** Object:  StoredProcedure [HC].[nonApi_updateRunNumbers]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC].[nonApi_updateRunNumbers]

-- NOTE: This procedure is never called directly by the public API, so we do not need to process tokens here.

@kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
@eventId uniqueidentifier = '00000000-0000-0000-0000-000000000000'

AS

BEGIN   

-- EXEC HC.nonApi_updateRunNumbers
-- EXEC HC.nonApi_updateRunNumbers @kennelId = '9963AD79-772C-4B56-9298-7B6E6294D131'
-- EXEC HC.nonApi_updateRunNumbers @eventId = '7747594a-d814-42be-b573-10130800f317'

SET NOCOUNT ON

	DECLARE @earliestEvent datetime
	DECLARE @latestEvent datetime
	
	-- if only one record was updated we don't have to update the run numbers for 
	-- the entire Kennel...  only those event records that are before and after this
	-- event that are bounded by event records with absolute run numbers need to be updated
	IF (@eventId <> '00000000-0000-0000-0000-000000000000')
	BEGIN
		SET NOCOUNT ON
		DECLARE @eventStartDate datetime
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
	set EventNumber = t.NewEventNumber
	--,EventName = REPLACE(EventName,'#' + CAST(t.EventNumber as nvarchar(10)),'#' + CAST(t.NewEventNumber as nvarchar(10)))
	from HC.Event e
	inner join #temp2 t on e.id = t.id 
	WHERE e.EventNumber <> t.NewEventNumber

	drop table #temp
	drop table #temp2

END
GO
/****** Object:  StoredProcedure [HC].[payForEvent]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [HC].[payForEvent]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@userIdWhoPaid uniqueidentifier,
@eventId uniqueidentifier,
@hasherEventMapId uniqueidentifier = NULL,
@paymentType smallint,
@paymentAmount decimal(12,6) = NULL

AS

BEGIN

-- exec HC.payForEvent @userId = '624C51B3-2F64-4DE5-9458-B506E75AC544', @hasherEventMapId = '0bc3a6ea-0e9f-432e-acb0-079c1557f004', @paymentType = 3

SET NOCOUNT ON

	IF (@hasherEventMapId = '00000000-0000-0000-0000-000000000000') SET @hasherEventMapId = null
	IF (@eventId = '00000000-0000-0000-0000-000000000000') SET @eventId = null
	if (@paymentAmount < 0) SET @paymentAmount = NULL

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	if (@hasherEventMapId is null)
	BEGIN
		SELECT @hasherEventMapId = id FROM HC.HasherEventMap hem where hem.UserId = @userIdWhoPaid AND hem.EventId = @eventId

		IF (@hasherEventMapId is null)
		BEGIN
			SET @hasherEventMapId = newid()
			INSERT HC.HasherEventMap (id,UserId,EventId,RsvpState,Rsvp,UserStartEvent) VALUES (@hasherEventMapId,@userIdWhoPaid,@eventId,3, getdate(),getdate())
		END
	END

	DECLARE @eventPrice money
	DECLARE @creditAmount money
	DECLARE @local nvarchar(10)
	DECLARE @kennelId uniqueidentifier
	DECLARE @result nvarchar(250)
	DECLARE @kennelName nvarchar(250)
	DECLARE @payer_userIdGuid uniqueidentifier
	DECLARE @paymentTypeStr nvarchar(120)
	DECLARE @payer_userName nvarchar(120)
	DECLARE @buttonState int

	SET @buttonState = 0

	SELECT
	@eventPrice = CASE WHEN coalesce(hkm.IsMember,0) = 1 THEN
		coalesce(e.EventPriceForMembers,k.DefaultEventPriceForMembers,e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,0)
	ELSE
		coalesce(e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,e.EventPriceForMembers,k.DefaultEventPriceForMembers,0)
	END
	,@local = coalesce(e.EventCurrencyType,k.DefaultEventCurrencyType,'en-us')
	,@kennelId = k.id
	,@kennelName = coalesce(k.KennelShortName,k.KennelName,'<No kennel name>')
	,@payer_userIdGuid = hem.UserId
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
	WHERE hem.id = @hasherEventMapId AND e.deleted = 0 AND e.IsVisible <> 0


	SET @result = 'Payment not processed'

	if (@paymentType = 1) -- handle the 'Not paid' case
	BEGIN
		UPDATE HC.Payment SET CancelledDate = getdate(), CancelledBy_UserId = @userId WHERE CancelledDate is null AND HasherEventMapId = @hasherEventMapId
		SET @result = @payer_userName + ', your payment has been cancelled'
	END

	IF (@paymentType = 2) SET @eventPrice = 0 -- in this case the run is "free"

	IF ((@paymentType >= 2) AND (@paymentType <= 7)) -- in this case the run is paid in cash, bank transfer or using credits
	BEGIN
		IF ((@paymentType = 5) OR (@paymentType = 7))
			SET @creditAmount = @paymentAmount
		ELSE
			SET @creditAmount = @eventPrice

		IF (@paymentType = 6) SET @creditAmount = 0 -- this is the case when hashers are paying using their existing 'hash credit'
		SET @paymentTypeStr = CASE 
			WHEN @paymentType = 3 
				THEN 'cash' 
			WHEN @paymentType = 4 
				THEN 'bank transfer' 
			WHEN @paymentType = 5 
				THEN 'other amount by cash' 
			WHEN @paymentType = 6 THEN 
				'hash credit' 
			WHEN @paymentType = 7 THEN 
				'other amount by bank transfer' 
			END

		-- We only allow one payment per event, so cancel any previous payments when a new payment comes in for an event that is of type "free", "cash", "bank transfer", or "credit"
		UPDATE HC.Payment SET CancelledDate = getdate(), CancelledBy_UserId = @userId WHERE CancelledDate is null AND HasherEventMapId = @hasherEventMapId

		-- Now insert a new payment record
		INSERT HC.Payment (KennelId, UserId,		    EventId, HasherEventMapId, CreditAmount,DebitAmount, PaymentProcessedBy_userId,PaidDate, PaymentType) 
				VALUES    (@kennelId,@payer_userIdGuid,@eventId,@hasherEventMapId,@creditAmount,@eventPrice,@userId,GETDATE(),@paymentType)
		
		-- Set the text result
		SET @result = @payer_userName + ', your ' + @paymentTypeStr + ' payment of ' + REPLACE(REPLACE(FORMAT(@creditAmount,'C',@local),',','.'),' ','') + ' to the ' + @kennelName + ' has been recorded'
		IF @paymentType = 2 SET @result = @payer_userName + ', congratulations, your run today was free!'

		-- if they have paid, mark them as being at the event.
		UPDATE HC.HasherEventMap set UserStartEvent = getdate() where id = @hasherEventMapId
		SET @buttonState = 1
	END

	EXEC HC.nonApi_adjustHasherRunCounts @limitByUser = 1,@userId = @userIdWhoPaid

	DECLARE @AtHashCount smallint
	DECLARE @OnInCount smallint
	DECLARE @OnTrailCount smallint
	DECLARE @PaidCount smallint
	DECLARE @WaitingForCount smallint
	DECLARE @TotalRunsThisKennel smallint

	SELECT @TotalRunsThisKennel = hem.TotalRunsThisKennel from HC.HasherEventMap hem where hem.id = @hasherEventMapId

	SELECT 
		@AtHashCount = count(hem2.UserStartEvent),
		@OnInCount = count(hem2.UserEndEvent),
		@OnTrailCount = count(hem2.UserStartEvent)-count(hem2.UserEndEvent) 
	FROM HC.HasherEventMap hem2 WHERE hem2.EventId = @EventId

	SELECT 
		@WaitingForCount = count(*)
	FROM HC.HasherEventMap hem WHERE hem.EventId = @EventId AND hem.UserStartEvent IS NULL AND hem.RsvpState = 3

	SELECT @PaidCount = count(*) from HC.Payment p where p.EventId = @EventId and p.CancelledDate is null

	SELECT @result as [Result], @WaitingForCount as waitingForCount, @AtHashCount as atHashCount, @OnInCount as onInCount, @OnTrailCount as onTrailCount, @PaidCount as paidCount, @buttonState as buttonState, @TotalRunsThisKennel as totalRunsThisKennel

END
GO
/****** Object:  StoredProcedure [HC].[processQrScan]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [HC].[processQrScan]

@userId nvarchar(120), -- this is the userId of the person who is doing the scanning, not the user being scanned
@accessToken nvarchar(1000),
@eventId nvarchar(120) = NULL,
@scanText nvarchar(500),
@context1 nvarchar(120),
@context2 nvarchar(120) = NULL,
@param1 nvarchar(120) = NULL,
@param2 nvarchar(120) = NULL

AS
BEGIN

SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

DECLARE @result nvarchar(500)
DECLARE @result2 nvarchar(500)
DECLARE @result3 nvarchar(500)
DECLARE @resultGuid1 uniqueidentifier
DECLARE @resultGuid2 uniqueidentifier
DECLARE @resultInt1 int
DECLARE @resultInt2 int
DECLARE @paramValue uniqueidentifier
DECLARE @userIdGuid uniqueidentifier
DECLARE @eventIdGuid uniqueidentifier
DECLARE @scanTextGuid uniqueidentifier
DECLARE @paymentCounter smallint
DECLARE @startTime datetime
DECLARE @endTime datetime
DECLARE @hasherEventMapId uniqueidentifier
DECLARE @startEvent datetime

DECLARE @runName nvarchar(500)


--IF (((@scanText like 'evtStart%') AND (@context1 = 'User')) OR ((@userId like 'uid%') AND (@context1 = '0')))
IF ((@context1 = 'CheckInOut') AND (@scanText like 'uqr:%')) -- this is the case where the user is checking in
BEGIN
	-- Context values
	-- @Context2 = 0 indicates run start
	-- @Context2 = 1 indicates run end
	
	-- Result values
	-- @Result1 contains the text for the action sheet for payment
	-- @Result2 contains instructions for payment
	-- @Result3 contains the user name
	-- @ResultInt1 contains the number of runs for this particular kennel for the target user
	-- @ResultGuid1 contains the target user id
	-- @ResultGuid2 contains the HasherEventMapId
	-- @ResultInt2 contains the payment counter


	-- exec HC.processQrScan @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @eventId = 'dea28bab-a30c-4a80-ac96-d0b7164551b9', @scanText = 'UQR:TEST01', @context1 = 'CheckInOut', @context2 = '0', @param1 = '', @param2 = ''


	SET @userIdGuid = CAST(right(@userId,36) AS uniqueidentifier)
	SET @eventIdGuid = CAST(right(@eventId,36) AS uniqueidentifier)
	--SET @scanTextGuid = CAST(right(@scanText,36) AS uniqueidentifier)
	SET @hasherEventMapId = newid()
	SET @startTime = getdate()
	if (@context2 <> '0') SET @endTime = getdate()
	SET @resultInt1 = -1
	SET @resultInt2 = -1


	--SET @scanTextGuid = CAST(right(@scanText,36) AS uniqueidentifier) -- the QR idf of the hasher being checked in
	DECLARE @targetUserId uniqueidentifier
	SELECT @targetUserId = id,
			@result3 = coalesce(h.HashName, h.DisplayName, h.FirstName + ' ' + h.LastName,'no name')
		from HC.Hasher h 
		where h.QR_code = @scanText

	IF (@targetUserId is null)
		BEGIN
			SET @result = 'User code not found in Harrier Central database'
		END
	ELSE
		BEGIN
		SELECT @paymentCounter = coalesce(count(*),0) from HC.Payment p WHERE p.UserId = @targetUserId AND p.EventId = @eventIdGuid AND p.CancelledDate IS NULL
		SET @resultInt2 = @paymentCounter

		IF NOT EXISTS(SELECT * FROM HC.HasherEventMap WHERE UserId = @targetUserId AND EventId = @eventIdGuid)
			-- this case is for someone who is on the run but did not RSVP, so there is no record in HEM
			BEGIN 
				INSERT INTO HC.HasherEventMap(id,UserId,EventId,RsvpState,Rsvp,UserStartEvent, UserEndEvent) VALUES (@hasherEventMapId,@targetUserId,@eventIdGuid,3,getdate(),@startTime, @endTime) 
				IF @paymentCounter = 0 SET @result2 = 'Please pay for today''s Hash.'
				IF @paymentCounter <> 0 SET @result2 = 'You have already paid. Enjoy the Hash!'
			END
		ELSE
			BEGIN
				-- This case is when a HEM record already exists
				SELECT @hasherEventMapId = id, @startEvent = UserStartEvent from HC.HasherEventMap WHERE UserId = @targetUserId AND EventId = @eventIdGuid
				IF (@startEvent is not null)
					BEGIN
						if (@context2 = '0')
						BEGIN
							-- This executes when someone has already checked in and is checking in again.
							IF @paymentCounter = 0 SET @result2 = 'You are already checked in, but you still need to pay.'
							IF @paymentCounter <> 0 SET @result2 = 'You are already checked in and paid. Enjoy the Hash!'
						END

						if (@context2 <> '0')
						BEGIN
							UPDATE HC.HasherEventMap SET UserEndEvent = @endTime WHERE id = @hasherEventMapId 
							-- This executes when someone has already checked in and is checking in again.
							IF @paymentCounter = 0 SET @result2 = 'You are recorded as "On In". Please don''t forget to pay for the Hash.'
							IF @paymentCounter <> 0 SET @result2 = 'You are recorded as "On In". Hope you enjoyed the Hash!'
						END
					END
				ELSE
					BEGIN

						IF (@context2 = '0')
						BEGIN
							-- This case is when someone has RSVP'ed but not yet checked in
							UPDATE HC.HasherEventMap SET RsvpState = 3, UserStartEvent = getdate() WHERE id = @hasherEventMapId 
							IF @paymentCounter = 0 SET @result2 = 'You are now checked in. Please pay for today''s Hash.'
							IF @paymentCounter <> 0 SET @result2 = 'You are now checked in and have paid. Enjoy the Hash!'
						END

						IF (@context2 <> '0')
						BEGIN
							-- This case is when someone has gone on the run without checking in, but they have checked in at the end
							UPDATE HC.HasherEventMap SET RsvpState = 3, UserStartEvent = @startTime, UserEndEvent = @endTime WHERE id = @hasherEventMapId 
							IF @paymentCounter = 0 SET @result2 = 'You are recorded as "On In". Please don''t forget to pay for the Hash.'
							IF @paymentCounter <> 0 SET @result2 = 'You are recorded as "On In". Hope you enjoyed the Hash!'
						END
					END
			END

			EXEC HC.nonApi_adjustHasherRunCounts @limitByUser = 1, @userId = @targetUserId

			DECLARE @remainingCreditStr nvarchar(20)
			DECLARE @eventPriceStr nvarchar(20)	
			DECLARE @local nvarchar(20)
			DECLARE @remainingCredit money
			DECLARE @eventPrice money
			DECLARE @allowNegativeCredit smallint
			DECLARE @creditStatusStr nvarchar(20)

			SELECT @resultInt1 = hem.TotalRunsThisKennel from HC.HasherEventMap hem where hem.id = @hasherEventMapId

			IF (@paymentCounter <> 0)
				SET @result = 'Already paid'
			ELSE
			BEGIN
				SELECT
				@eventPrice = CASE WHEN hkm.IsMember = 1 THEN
					coalesce(e.EventPriceForMembers,k.DefaultEventPriceForMembers,e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,0)
				ELSE
					coalesce(e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,e.EventPriceForMembers,k.DefaultEventPriceForMembers,0)
				END
				,@local = coalesce(e.EventCurrencyType,k.DefaultEventCurrencyType,'en-US')
				,@allowNegativeCredit = k.AllowNegativeCredit
				FROM HC.Event e
				INNER JOIN HC.Kennel k on k.id = e.KennelId
				INNER JOIN HC.HasherKennelMap hkm on hkm.UserId = @targetUserId and hkm.KennelId = e.KennelId
				WHERE e.id = @eventIdGuid AND e.deleted = 0 AND e.IsVisible <> 0

				SET @eventPriceStr = REPLACE(FORMAT(@eventPrice,'C',COALESCE(@local,'en-US')),',','.')

				SELECT @remainingCredit = coalesce(sum(creditAmount)-sum(debitAmount),0)
				FROM HC.Payment p 
				INNER JOIN HC.Event e on p.KennelId = e.KennelId
				WHERE p.UserId = @targetUserId AND e.id = @eventIdGuid AND p.CancelledDate is null AND e.deleted = 0 AND e.IsVisible <> 0

				SET @creditStatusStr = ' '
				if (@remainingCredit < 0) SET @creditStatusStr = '['+TRIM(@remainingCreditStr)+' owed]'
				if (@remainingCredit > 0) SET @creditStatusStr = '['+TRIM(@remainingCreditStr)+' left]'

				SET @remainingCreditStr = REPLACE(FORMAT(ABS(@remainingCredit),'C',COALESCE(@local,'en-US')),',','.')


				-- this is the format required to pull up an action sheet in the Configure.IT mobile app
				SET @result = 'Cancel,Not Paid,Free run,Cash ('+TRIM(@eventPriceStr)+'),Bank Transfer ('+TRIM(@eventPriceStr)+')'
				IF ((@remainingCredit - @eventPrice >= 0) OR (@allowNegativeCredit = 1)) SET @result = @result + ',Credit ('+TRIM(@eventPriceStr)+') ' + @creditStatusStr

				if (@result is null) SET @result = 'Cancel,Not Paid,Free Run,Cash,Bank Transfer'
			END

			SET @resultGuid2 = @hasherEventMapId
	END

END


--IF (((@scanText like 'evtStart%') AND (@context1 = 'User')) OR ((@userId like 'uid%') AND (@context1 = '0')))
ELSE IF ((@context1 = 'UserScan') AND (@scanText like 'evtStart:%')) -- this is the case where the user is checking in
	BEGIN

	-- exec HC.processQrScan @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @eventId = '', @scanText = 'evtStart:7B10155A-92D4-40D7-929A-CF2BDE968444', @context1 = 'UserScan', @context2 = '', @param1 = '', @param2 = ''
	
	SET @userIdGuid = CAST(right(@userId,36) AS uniqueidentifier)
	SET @eventIdGuid = CAST(right(@scanText,36) AS uniqueidentifier)

	SELECT @runName = e.EventName from HC.Event e where e.id = @eventIdGuid

	IF NOT EXISTS(SELECT * FROM HC.HasherEventMap WHERE UserId = @userIdGuid AND EventId = @eventIdGuid)
		BEGIN 
			INSERT INTO HC.HasherEventMap(UserId,EventId,RsvpState,Rsvp,UserStartEvent) VALUES (@userIdGuid,@eventIdGuid,3,getdate(),getdate()) 
			SET @result = 'Checked in for "'+@runName+'". Enjoy your run!'
		END
	ELSE
			IF EXISTS(SELECT * FROM HC.HasherEventMap WHERE UserId = @userIdGuid AND EventId = @eventIdGuid AND UserStartEvent IS NOT NULL)
			SET @result = 'You are already checked in for "'+@runName+'". Enjoy your run!'
		ELSE
			BEGIN
				UPDATE HC.HasherEventMap SET RsvpState = 3, UserStartEvent = coalesce(UserStartEvent,getdate()) WHERE UserId = @userIdGuid and EventId = @eventIdGuid
				SET @result = 'Checked in for "'+@runName+'". Enjoy your run!'
			END

	END

ELSE IF ((@context1 = 'UserScan') AND (@scanText like 'evtEnd:%')) -- this is the case where the user is checking in at the end of the run
	BEGIN

	-- exec HC.processQrScan @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @eventId = '', @scanText = 'evtEnd:7B10155A-92D4-40D7-929A-CF2BDE968444', @context1 = 'UserScan', @context2 = '', @param1 = '', @param2 = ''

	SET @userIdGuid = CAST(right(@userId,36) AS uniqueidentifier)
	SET @eventIdGuid = CAST(right(@scanText,36) AS uniqueidentifier)

	SELECT @runName = e.EventName from HC.Event e where e.id = @eventIdGuid

	IF NOT EXISTS(SELECT * FROM HC.HasherEventMap WHERE UserId = @userIdGuid AND EventId = @eventIdGuid)
		BEGIN 
			INSERT INTO HC.HasherEventMap(UserId,EventId,RsvpState,Rsvp,UserStartEvent,UserEndEvent) VALUES (@userIdGuid,@eventIdGuid,3,getdate(),getdate(),getdate()) 
			SET @result = 'Congratulations for finishing "'+@runName+'". Enjoy your beer!'
		END
	ELSE
			IF EXISTS(SELECT * FROM HC.HasherEventMap WHERE UserId = @userIdGuid AND EventId = @eventIdGuid AND UserStartEvent IS NOT NULL AND UserEndEvent IS NOT NULL)
			SET @result = 'You are already checked in as finished. Enjoy your beer!'
		ELSE
			BEGIN
				UPDATE HC.HasherEventMap SET RsvpState = 3, UserStartEvent = coalesce(UserStartEvent,getdate()), UserEndEvent = coalesce(UserEndEvent,getdate()) WHERE UserId = @userIdGuid and EventId = @eventIdGuid
				SET @result = 'Congratulations for finishing "'+@runName+'". Enjoy your beer!'
			END

	END

ELSE IF ((@context1 = 'UserScan') AND (@scanText like 'uqr:%')) -- this is the case where the user is checking in at the end of the run
	BEGIN

	-- exec HC.processQrScan @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @eventId = '', @scanText = 'uqr:A703DA6E-35D9-4BBC-B74B-C3AE270F16FC', @context1 = 'UserScan', @context2 = '', @param1 = '', @param2 = ''
	DECLARE @friendQrCode uniqueidentifier
	DECLARE @friendIdGuid uniqueidentifier
	DECLARE @friendName nvarchar(120)

	SET @userIdGuid = CAST(right(@userId,36) AS uniqueidentifier)
	--SET @friendQrCode = CAST(right(@scanText,36) AS uniqueidentifier)

	SELECT @friendIdGuid = id, @friendName = DisplayName from HC.Hasher h where h.QR_code = @scanText

	IF (@friendIdGuid IS NULL)
		BEGIN
			SET @result = 'QR code not recognized'
		END
	ELSE IF (@friendIdGuid = @userIdGuid)
		SET @result = 'How nice of you to want to be your own friend!'
	ELSE
		BEGIN


			IF NOT EXISTS(SELECT * FROM HC.HasherFriendMap WHERE UserId = @userIdGuid AND Friend_UserId = @friendIdGuid)
				BEGIN 
					INSERT INTO HC.HasherFriendMap(UserId,Friend_UserId,FriendSince,Ignore) VALUES (@userIdGuid,@friendIdGuid,getdate(),0) 
					SET @result = @friendName + ' has been added to your friend list'
				END
			ELSE
				IF EXISTS(SELECT * FROM HC.HasherFriendMap WHERE UserId = @userIdGuid AND Friend_UserId = @friendIdGuid AND Ignore = 0)
					SET @result = @friendName + ' is already in your friend list'
				ELSE
					BEGIN
						UPDATE HC.HasherFriendMap SET Ignore = 0 WHERE UserId = @userIdGuid AND Friend_UserId = @friendIdGuid
						SET @result = @friendName + ' has been added to your friend list'
					END

			END
		END

ELSE
BEGIN
	SET @result = 'Scanned code not recognized'
END

select	coalesce(@result,'') as [resultStr1], 
		coalesce(@result2,'') as [resultStr2], 
		coalesce(@result3,'') as [resultStr3], 
		coalesce(@targetUserId,'00000000-0000-0000-0000-000000000000') as resultGuid1, 
		coalesce(@resultGuid2,'00000000-0000-0000-0000-000000000000') as [resultGuid2], 
		coalesce(@resultInt1,-1) as [resultInt1], 
		coalesce(@resultInt2,-1) as [resultInt2]

END



GO
/****** Object:  StoredProcedure [HC].[unused_loadEvents]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC].[unused_loadEvents]

AS

BEGIN

-- NOTE: IF WE NEED TO REACTIVATE THIS, ADD IN A CALL TO HC.nonApi_updateRunNumbers

update HC.Event 
SET
EventStartDatetime = CAST(left(imp.start_time,19) as datetime),
EventEndDatetime = CAST(left(imp.end_time,19) as datetime),
EventName = imp.[name],
EventDescription = imp.[description],
FacebookRecordLastUpdated = CAST(left(imp.updated_time,19) as datetime),
LocationOneLineDesc = imp.[place.name],
LocationCity = imp.[place.location.city],
LocationCountry = imp.[place.location.country],
Latitude = imp.[place.location.latitude],
Longitude = imp.[place.location.longitude],
LocationStreet = imp.[place.location.street],
LocationPostCode = imp.[place.location.zip],
-- we don't use the FB Place.id, but it is in the FB dataset
EventImageOffsetX = CAST([cover.offset_x] as smallint),
EventImageOffsetY = CAST([cover.offset_y] as smallint),
EventImage = imp.[cover.source],
-- we don't use the FB Cover.id, but it is in the FB dataset
-- we don't use the FB Owner.name, but it is in the FB dataset
-- we don't use the FB Owner.is, but it is in the FB dataset
FacebookAttendingCount = imp.attending_count,
FacebookMaybeCount = imp.maybe_count,
FacebookDeclinedCount = imp.declined_count,
FacebookInterestedCount = imp.interested_count,
FacebookNoReplyCount = imp.noreply_count

from HC.Event evt inner join 
[HC].[FacebookEventImport] imp on evt.EventFacebookId = imp.event_id
where imp.[type] = 'group'
AND imp.event_id in (select EventFacebookId from HC.Event) 



insert HC.Event(EventFacebookId,EventStartDateTime,EventEndDatetime,EventName,EventDescription,
KennelId,FacebookRecordLastUpdated,LocationOneLineDesc,LocationCity,LocationCountry,Latitude,
Longitude,LocationStreet,LocationPostCode,EventImageOffsetX,EventImageOffsetY,EventImage,
FacebookAttendingCount,FacebookMaybeCount,FacebookDeclinedCount,FacebookInterestedCount,FacebookNoReplyCount)


select 
-- we don't save the event type, but it is used in filtering this dataset
imp.event_id as EventFacebookId,
CAST(left(imp.start_time,19) as datetime) as EventStartDatetime,
CAST(left(imp.end_time,19) as datetime) as EventEndDatetime,
imp.[name] as EventName,
imp.[description] as [EventDescription],
ken.id as [KennelId],
CAST(left(imp.updated_time,19) as datetime) as FacebookRecordLastUpdated,
imp.[place.name] as LocationOneLineDesc,
imp.[place.location.city] as LocationCity,
imp.[place.location.country] as LocationCountry,
imp.[place.location.latitude] as Latitude,
imp.[place.location.longitude] as Longitude,
imp.[place.location.street] as LocationStreet,
imp.[place.location.zip] as LocationPostCode,
-- we don't use the FB Place.id, but it is in the FB dataset
CAST([cover.offset_x] as smallint) as EventImageOffsetX,
CAST([cover.offset_y] as smallint) as EventImageOffsetY,
imp.[cover.source] as EventImage,
-- we don't use the FB Cover.id, but it is in the FB dataset
-- we don't use the FB Owner.name, but it is in the FB dataset
-- we don't use the FB Owner.is, but it is in the FB dataset
imp.attending_count as FacebookAttendingCount,
imp.maybe_count as FacebookMaybeCount,
imp.declined_count as FacebookDeclinedCount,
imp.interested_count as FacebookInterestedCount,
imp.noreply_count as FacebookNoReplyCounte



from [HC].[FacebookEventImport] imp
inner join HC.Kennel ken on imp.[parent_group.id] = ken.KennelFacebookId
where imp.[type] = 'group'
AND imp.event_id not in (select EventFacebookId from HC.Event)
order by start_time desc;

-- REMOVE AND REPLCE!
-- THIS IS DANGEROUS BECAUSE IT MIGHT DELETE THE WRONG EVENT
-- WE NEED TO ADD AN "INSTEAD OF" TRIGGER THAT WILL PREVENT DUPLICATES FROM BEING INSERTED
-- IN THE FIRST PLACE
WITH CTE AS(
   SELECT EventFacebookId,
       RN = ROW_NUMBER()OVER(PARTITION BY EventFacebookId ORDER BY EventFacebookId)
   FROM HC.Event
)
DELETE FROM CTE WHERE RN > 1


TRUNCATE TABLE [HC].[FacebookEventImport]

END

GO
/****** Object:  StoredProcedure [HC].[updateEventCountAndVisibilityStatus]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC].[updateEventCountAndVisibilityStatus]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @kennelId uniqueidentifier,
 @eventId uniqueidentifier,
 @isCountedRun smallint = NULL,
 @absoluteEventNumber smallint = NULL, -- this value set to NULL or -1 will not make any changes to the DB, set to -2 and it will cause the value in the DB to be set to NULL
 @isVisible smallint = NULL,
 @isDeleted smallint = NULL

AS

BEGIN

--  EXEC HC.updateEventCountAndVisibilityStatus @eventId = 'E9859142-669F-497A-AB60-E9CEAA44C5A5', @isVisible = 1, @isCountedRun = 0, @absoluteEventNumber = -1, @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @accessToken = '', @kennelId = '5029DE3A-D231-47AA-BE72-ECE9BCCD55D1'

	SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	declare @deleted bit
	SET @deleted = NULL
	IF (@isDeleted = 1) SET @deleted = 1
	IF (@isDeleted = 0) SET @deleted = 0
	IF (@isDeleted = -1) SET @deleted = NULL

	IF (@isCountedRun = -1) SET @isCountedRun = NULL
	IF (@isVisible = -1) SET @isVisible = NULL
	IF (@absoluteEventNumber = -1) SET @absoluteEventNumber = NULL
	

	SELECT 
	e.id,
	e.EventNumber,
	e.IsCountedRun,
	e.IsVisible,
	e.deleted
	INTO #temp
	FROM HC.Event e WHERE e.KennelId = @kennelId

	UPDATE HC.Event SET 
		IsCountedRun = coalesce(@isCountedRun,e.IsCountedRun), 
		IsVisible = coalesce(@isVisible,e.isVisible),
		deleted = coalesce(@deleted,e.deleted),
		AbsoluteEventNumber = CASE WHEN @absoluteEventNumber = -2 THEN NULL ELSE coalesce(@absoluteEventNumber,e.AbsoluteEventNumber) END 
	FROM HC.Event e WHERE e.id = @eventId

	EXEC HC.nonApi_updateRunNumbers @eventId = @eventId

	SELECT e.id as EventId, e.EventNumber, e.IsVisible, e.IsCountedRun, e.AbsoluteEventNumber, e.deleted
	FROM HC.Event e 
	INNER JOIN #temp t on e.id = t.id 
	WHERE e.EventNumber <> t.EventNumber OR e.IsCountedRun <> t.IsCountedRun OR e.IsVisible <> t.IsVisible OR e.deleted <> t.deleted
	--ORDER BY e.EventNumber

END





GO
/****** Object:  StoredProcedure [HC].[updateEventCountStatus]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC].[updateEventCountStatus]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @kennelId uniqueidentifier,
 @eventId uniqueidentifier,
 @isCountedRun smallint = NULL,
 @absoluteEventNumber smallint = NULL, -- this value set to NULL or -1 will not make any changes to the DB, set to -2 and it will cause the value in the DB to be set to NULL
 @isVisible smallint = NULL

AS

BEGIN



--  EXEC HC.updateEventCountStatus @eventId = 'E9859142-669F-497A-AB60-E9CEAA44C5A5', @isVisible = 1, @isCountedRun = 0, @absoluteEventNumber = -1, @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @accessToken = '', @kennelId = '5029DE3A-D231-47AA-BE72-ECE9BCCD55D1'

	SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	IF (@isCountedRun = -1) SET @isCountedRun = NULL
	IF (@isVisible = -1) SET @isVisible = NULL
	IF (@absoluteEventNumber = -1) SET @absoluteEventNumber = NULL

	SELECT 
	e.id,
	e.EventNumber,
	e.IsCountedRun,
	e.IsVisible
	INTO #temp
	FROM HC.Event e WHERE e.KennelId = @kennelId

	UPDATE HC.Event SET 
		IsCountedRun = coalesce(@isCountedRun,e.IsCountedRun), 
		IsVisible = coalesce(@isVisible,e.isVisible),
		AbsoluteEventNumber = CASE WHEN @absoluteEventNumber = -2 THEN NULL ELSE coalesce(@absoluteEventNumber,e.AbsoluteEventNumber) END 
	FROM HC.Event e WHERE e.id = @eventId

	UPDATE HC.Event SET lastModified = getdate() WHERE id = @eventId

	SELECT e.id as EventId, e.EventNumber, e.IsVisible, e.IsCountedRun 
	FROM HC.Event e 
	INNER JOIN #temp t on e.id = t.id 
	WHERE e.EventNumber <> t.EventNumber OR e.IsCountedRun <> t.IsCountedRun OR e.IsVisible <> t.IsVisible
	ORDER BY e.EventNumber

END

GO
/****** Object:  StoredProcedure [HC].[updateUserEventStatus]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [HC].[updateUserEventStatus]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @userToUpdateId uniqueidentifier,
 @eventId uniqueidentifier,
 @hasherEventMapId uniqueidentifier = NULL,
 @context nvarchar(120),
 @state nvarchar(10)

AS

BEGIN

-- EXEC HC.updateUserEventStatus @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @eventId = '2137af40-831b-484b-b323-85c11a4a6d60', @context = 'IsAtHash', @state = '1',@hasherEventMapId = '5f26c4ba-482c-496c-8a28-5ba2edaaeed8'

	SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error')) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	if (@hasherEventMapId = '00000000-0000-0000-0000-000000000000') SET @hasherEventMapId = null

	DECLARE @result nvarchar(120)

	DECLARE @attendDate datetime
	SET @attendDate = NULL
	if (@state = '1') SET @attendDate = getdate()

	if @context = 'IsAtHash'
	BEGIN
		
		IF @hasherEventMapId IS NOT NULL
			-- valid @hasherEventMapId was passed in
			UPDATE HC.HasherEventMap SET UserStartEvent = @attendDate, UserEndEvent = NULL WHERE id=@hasherEventMapId
		ELSE IF EXISTS(SELECT * FROM HC.HasherEventMap WHERE UserId = @userToUpdateId AND EventId = @eventId)
			-- otherwise, check userId and event to see if a record already exists
			UPDATE HC.HasherEventMap SET UserStartEvent = @attendDate, UserEndEvent = NULL WHERE UserId=@userToUpdateId AND EventId = @eventId
		ELSE
			-- no record exists, so insert a new one
			INSERT INTO HC.HasherEventMap(UserId,EventId,UserStartEvent,RsvpState,Rsvp) VALUES (@userToUpdateId,@eventId,@attendDate,3,@attendDate)	

		EXEC HC.nonApi_adjustHasherRunCounts @limitByUser = 1,@userId = @userToUpdateId

	END

	if @context = 'IsOnIn'
	BEGIN
		
		IF @hasherEventMapId IS NOT NULL
			UPDATE HC.HasherEventMap SET UserEndEvent = @attendDate, UserStartEvent = coalesce(UserStartEvent,@attendDate) WHERE id=@hasherEventMapId
		ELSE IF EXISTS(SELECT * FROM HC.HasherEventMap WHERE UserId = @userToUpdateId AND EventId = @eventId)
			UPDATE HC.HasherEventMap SET UserEndEvent = @attendDate, UserStartEvent = coalesce(UserStartEvent,@attendDate) WHERE UserId=@userToUpdateId AND EventId = @eventId
		ELSE
			INSERT INTO HC.HasherEventMap(UserId,EventId,UserStartEvent,UserEndEvent,RsvpState,Rsvp) VALUES (@userToUpdateId,@eventId,@attendDate,@attendDate,3,@attendDate)
	END

	if @hasherEventMapId IS NULL
	BEGIN
		SELECT @hasherEventMapId = id from HC.HasherEventMap WHERE UserId=@userToUpdateId AND EventId = @eventId
	END


	SET @result = 'Success'

	DECLARE @AtHashCount smallint
	DECLARE @OnInCount smallint
	DECLARE @OnTrailCount smallint
	DECLARE @PaidCount smallint
	DECLARE @WaitingForCount smallint
	DECLARE @UserRunCount smallint
	DECLARE @UserStatus smallint


	SELECT @UserRunCount = CASE 
		WHEN (hem.[VirginVisitorType] <> 0)
			THEN 
				CASE WHEN hem.UserStartEvent IS NOT NULL THEN 1 ELSE 0 END
		ELSE
			hem.TotalRunsThisKennel
		END,
		@UserStatus = CASE 
		WHEN hem.[UserStartEvent] IS NOT NULL
			AND hem.[UserEndEvent] IS NULL
			THEN 4
		WHEN hem.[UserStartEvent] IS NOT NULL
			AND hem.[UserEndEvent] IS NOT NULL
			THEN 5
		ELSE coalesce(hem.RsvpState, 0)
		END 
		
	FROM HC.HasherEventMap hem 
	WHERE (hem.VirginVisitorType <> 0 AND hem.id = @hasherEventMapId) OR (hem.VirginVisitorType = 0 AND hem.EventId = @eventId AND hem.UserId = @userToUpdateId)


	SELECT 
		@AtHashCount = count(hem2.UserStartEvent),
		@OnInCount = count(hem2.UserEndEvent),
		@OnTrailCount = count(hem2.UserStartEvent)-count(hem2.UserEndEvent) 
	FROM HC.HasherEventMap hem2 WHERE hem2.EventId = @EventId

	SELECT 
		@WaitingForCount = count(*)
	FROM HC.HasherEventMap hem WHERE hem.EventId = @EventId AND hem.UserStartEvent IS NULL AND hem.RsvpState = 3

	SELECT @PaidCount = count(*) from HC.Payment p where p.EventId = @EventId and p.CancelledDate is null

	SELECT	@result as [Result], 
			@WaitingForCount as WaitingForCount,
			@AtHashCount as AtHashCount, 
			@OnInCount as OnInCount, 
			@OnTrailCount as OnTrailCount, 
			@PaidCount as PaidCount, 
			coalesce(@UserRunCount,-33) as UserRunCount, 
			@UserStatus as UserStatus,
			@hasherEventMapId as HasherEventMapId

END





GO
/****** Object:  StoredProcedure [HC].[utilityBuildCitiesJson]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC].[utilityBuildCitiesJson]

AS

BEGIN

select cast('test' as nvarchar(max)) as line into #temp

DECLARE @json nvarchar(3500)
DECLARE @allJson nvarchar(MAX)

SET @allJson = ''

SET NOCOUNT ON;    
  
DECLARE @id uniqueidentifier 
  
DECLARE emp_cursor CURSOR FOR     
SELECT id    
FROM HC.City  
order by id;    
  
OPEN emp_cursor    
  
FETCH NEXT FROM emp_cursor     
INTO @id      
  
WHILE @@FETCH_STATUS = 0    
BEGIN    


	SET @json =
  	(SELECT
		c.id as cityId
      ,[CityName] as cityName
      ,[RegionId] as regionId
      ,[Latitude] as latitude
      ,[Longitude] as longitude
      ,[City_ASCII] as cityAscii
      ,[FlagFile] as flagFile
	  ,[Removed] as removed
      ,[updatedAt] as updatedAt
	  ,CAST(DATEDIFF (SECOND,'1/1/1970',updatedAt) as bigint) * 1000 as updatedAtValue
	FROM HC.City c where c.id = @id FOR JSON AUTO)



	SET @json = SUBSTRING(TRIM(@json),2,99999)
	SET @json = SUBSTRING(@json,0,(datalength(@json)/2)-1) + '},'

		INSERT #temp (line) VALUES (@json)

	--if (datalength(@allJson) < 10)
	--BEGIN
	--SET @allJson = @allJson + TRIM(@json)
	--END
	--ELSE
	--BEGIN
	--SET @allJson = @allJson + ',' + TRIM(@json)
	--END
      
    FETCH NEXT FROM emp_cursor     
INTO @id 
   
END     
CLOSE emp_cursor; 

DEALLOCATE emp_cursor

select * from #temp order by line
drop table #temp   

END



	
	
	
GO
/****** Object:  StoredProcedure [HC2].[_old_getMyRuns]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC2].[_old_getMyRuns]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
@following int = -1

AS

-- EXEC HC.getMyRuns @userId = '6f901167-4bd3-45af-9da0-6af5a1128f42'
-- EXEC HC.getMyRuns @userId = '624c51b3-2f64-4de5-9458-b506e75ac544',@kennelId = '00000000-0000-0000-0000-000000000000'
-- EXEC HC.getMyRuns @userId = 'e15f27d1-1ac2-4241-a4fe-00e045cc3091',@kennelId = '6f901167-4bd3-45af-9da0-6af5a1128f42', @accessToken = '', @following = -1

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


select 
e.id as eventId
,e.eventStartDatetime as eventStartDatetime
,e.eventEndDatetime as eventEndDatetime
,e.eventName as eventName
,e.EventNumber as eventNumber
,e.LocationOneLineDesc as locationOneLineDesc
,e.userEventCounterIncrement as userEventCounterIncrement
,hem.isHare as isHare
,hem.totalRunsThisKennel as totalRunsThisKennel
,hem.totalRunsAllKennels as totalRunsAllKennels
,hem.TotalHaringThisKennel as totalHaringThisKennel
,hem.userStartEvent as userStartEvent
,coalesce(hem.RsvpState,0) as rsvpState
,coalesce(hem.AttendenceState,0) as attendenceState
,e.CanEditRunAttendence * hkm.CanEditRunAttendence * k.CanEditRunAttendence as canEditRunAttendence
FROM HC.Event e 
INNER JOIN HC.Kennel k on k.id = e.KennelId
LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.UserId = @userId AND hkm.KennelId = k.id
LEFT OUTER JOIN HC.HasherEventMap hem on hem.UserId = @userId and hem.EventId = e.id

WHERE e.deleted = 0 
AND e.IsVisible <> 0
AND e.IsCountedRun = 1
AND ((@following = -1) OR (hkm.Following = @following))
AND e.EventStartDatetime <= dateadd(day,1,getdate())
AND ((@kennelId = '00000000-0000-0000-0000-000000000000') OR (e.KennelId = @kennelId))
ORDER BY e.EventStartDatetime DESC,EventId DESC



GO
/****** Object:  StoredProcedure [HC2].[addEditEvent]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC2].[addEditEvent]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @eventId uniqueidentifier = null,
 @kennelId uniqueidentifier = null,
 @startDatetime datetime = null,
 @endDatetime datetime = null,
 @isCountedRun smallint = null,
 @isVisible smallint = null,
 @isPromotedEvent smallint = null,
 @eventGeographicScope smallint = null,
 @ThemeRunType smallint = null,
 @eventName nvarchar(120) = null,
 @eventDescription nvarchar(4000) = null,
 @eventShortDescription nvarchar(250) = null,
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




-- EXEC HC.addEditEvent @userId = '83294c62-2ffe-4fcb-a2f5-52aadd6ceaa0',@accessToken='',@eventId='00000000-0000-0000-0000-000000000000',@kennelId='5029de3a-d231-47aa-be72-ece9bccd55d1',@startDatetime='4/13/2018 12:00:00 AM',@endDatetime='',@eventName='FILTH-xx',@eventFacebookId='1234567890'



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
	if (DATALENGTH(@eventShortDescription) < 1) SET @eventShortDescription = NULL
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

	set @resultStr = '00000000-0000-0000-0000-000000000000'
	set @resultInt = -1

	if (@eventFacebookId like '%break%') SET @eventFacebookId = ''


    if ((@deleted IS NOT NULL) AND (@deleted = 1))
	BEGIN
		-- use the kennel id and date if we don't have an eventId
		if ((@eventId = '00000000-0000-0000-0000-000000000000') OR (@eventId is null))
		BEGIN
			select top 1 @eventId = id from HC.Event WHERE KennelId = @kennelId AND cast(EventStartDatetime as Date) = cast(@startDatetime as Date)
		END

		if ((@eventId is not null) AND (@eventId <> '00000000-0000-0000-0000-000000000000'))
		BEGIN
			UPDATE HC.Event SET 
			deleted = 1
			FROM HC.Event e where e.id = @eventId

			set @resultStr = @eventId
			set @resultInt = 2
		END
			
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
			EventShortDesc = coalesce(@eventShortDescription, EventShortDesc),
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
			EventPriceForMembers = coalesce(@eventPriceForMembers,EventPriceForMembers),
			EventPriceForNonMembers = coalesce(@eventPriceForNonMembers,EventPriceForNonMembers),
			AbsoluteEventNumber = case when @absoluteEventNumber = 0 then null else coalesce(@absoluteEventNumber, AbsoluteEventNumber) end,
			EventCurrencyType = coalesce(@eventCurrencyType, EventCurrencyType),
			deleted = coalesce(@deleted, deleted)
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
					DECLARE @time time(7)
					SELECT @time = DefaultRunStartTime from HC.Kennel where id = @kennelId
					if (@time is not null) SET @startDateTime = @startDatetime + cast(@time as datetime)
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
						,EventShortDesc
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
						,EventPriceForMembers
						,EventPriceForNonMembers
						,AbsoluteEventNumber
						,EventCurrencyType,deleted
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
						,@eventShortDescription
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
						,@eventPriceForMembers
						,@eventPriceForNonMembers
						,@absoluteEventNumber
						,@eventCurrencyType,coalesce(@deleted,0)
					)

				SET @resultStr = 'Insert succeeded'
				SET @resultInt = 1
			END
		END
	END

	EXEC HC.nonApi_updateRunNumbers @eventId = @eventId

	UPDATE HC.Event SET lastModified = getdate() WHERE id = @eventId

    IF ((@fbLatitude is not null and @fbLongitude is not null) OR (@latitude is not null AND @longitude is not null))
	BEGIN
		UPDATE HC.Event Set EventGeolocation = geography::Point(coalesce(@latitude,@fbLatitude), coalesce(@longitude,@fbLongitude), 4326) FROM HC.Event
			WHERE id = @eventId
	END
	
	DECLARE @resultInt2 int
	SELECT @resultInt2 = e.EventNumber, @kennelId = e.KennelId from HC.Event e where e.id = @eventId

	SELECT @resultStr as result

END






GO
/****** Object:  StoredProcedure [HC2].[addUser]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC2].[addUser]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @email nvarchar(250),
 @eventId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @isNewMember int = 1,
 @firstName nvarchar(100) = null,
 @lastName nvarchar(100) = null,
 @deviceId nvarchar(250) = null,
 @memberKennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @homeLatitude decimal(18,15) = null,
 @homeLongitude decimal (19,15) = null,
 @hashHandle nvarchar(100) = null,
 @facebookId nvarchar(250) = null,
 @gender nvarchar(50) = null,
 @locale nvarchar(50) = null,
 @photo nvarchar(500) = null,
 @hasherType int = 0, -- 0 = Member, 1 = Visitor, 2 = Virgin
 @attendenceState int = 0,
 @hcVersion nvarchar(250) = null

AS

BEGIN

SET NOCOUNT ON

-- NOTES: This proc adds a new user. It can be called either to create a new user by someone who has just installed the app or by an admin.


-- EXEC HC.addUser @userId = '00000000-0000-0000-0000-000000000000', @accessToken = '',@email = 'james@jamesawhite.com', @firstName = 'James', @lastName = 'White', @deviceId = '366bfe5f-9906-443d-86a4-b99c5d668db3',@hashHandle = 'Opee',@facebookId = '10214797082344406'

	IF @hcVersion IS NULL SET @hcVersion = 'pre 0.6.4'

	IF @userId IS NULL
	BEGIN
		
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),@accessToken,NULL) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	if (SELECT count(*) from HC.Hasher h where h.Email = trim(@email) and (h.Email <> 'james@jamesawhite.com' AND h.Email <> 'melissatunawhite@gmail.com') AND h.Email <> '') > 0
	BEGIN
		DECLARE @errorId uniqueidentifier
		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,deviceId,string_1,eventId) VALUES (@errorId,@hcVersion,'Duplicate email','A new user is being registered with a duplicate e-mail address to one already in the system',OBJECT_NAME(@@PROCID),@userId,@deviceId,@email,@eventId)

		select 
		@errorId as errorId,
		cast (5 as int) as errorType 
		,'Email address already exists' as errorTitle
		,'A user already exists with this e-mail address in the system. Please register with a different e-mail address.' as errorUserMessage
		,'This is a standard error that is anticipated and does not require debugging' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
	END

	DECLARE @newHasherId uniqueidentifier
	SET @newHasherId = newid()

	-- First insert a record into HC.Hasher with the new member
	if (@isNewMember is null) SET @isNewMember = 1
	if (@attendenceState is null) SET @attendenceState = 0

	SELECT @homeLatitude = coalesce(@homeLatitude,52.1663), @homeLongitude = coalesce(@homeLongitude,4.4814) 
	INSERT HC.Hasher 
		(
			Id,FirstName,LastName,Email,HashName,HomeLatitude,HomeLongitude,DisplayName,FacebookId,Gender,Locale,Photo
		) VALUES 
		(
			@newHasherId,@firstName,@lastName,@email,@hashHandle,@homeLatitude,@homeLongitude,@hashHandle,@facebookId,@gender,@locale,@photo
		)

	DECLARE @hasherKennelMapId uniqueidentifier


	DECLARE @hasherEventMapId uniqueidentifier
	DECLARE @memberCounter int


	-- Next, insert records in HasherEventMap and HasherKennelMap if the member is being added during an event
	if @eventId <> '00000000-0000-0000-0000-000000000000'
	BEGIN

		DECLARE @kennelId uniqueidentifier
		SELECT @kennelId = evt.KennelId from HC.Event evt where evt.id = @eventId
	
		SET @hasherKennelMapId = newid()
		INSERT HC.HasherKennelMap (id,UserId,KennelId,[Following],isMember,MemberSince) VALUES (@hasherKennelMapId, @newHasherId, @kennelId,1,@isNewMember,GETDATE())

		SELECT @memberCounter = count(*) from HC.HasherKennelMap hkm WHERE hkm.KennelId = @kennelId AND hkm.IsMember = 1
		
		SET @hasherEventMapId = newid()
		INSERT HC.HasherEventMap (id,EventId,UserId,UserStartEvent,Rsvp,RsvpState,AttendenceState) VALUES (@hasherEventMapId,@eventId,@newHasherId,getdate(),GETDATE(),3,@attendenceState)

	END
	ELSE
	-- now if a kennel has been specified but an event has not been specified, sign the Hasher up to follow the kennel, and be a member if requested
	IF (coalesce(@memberKennelId,'00000000-0000-0000-0000-000000000000') <> '00000000-0000-0000-0000-000000000000')
	BEGIN
		if (@hasherKennelMapId is null) SET @hasherKennelMapId = newid()
		INSERT INTO HC.HasherKennelMap(id,UserId,KennelId,[Following],[IsMember]) VALUES (@hasherKennelMapId, @newHasherId, @memberKennelId,1,@isNewMember) 
	END

--SELECT top 1 
--	h.id as userId, 
--	h.qr_code, 
--	'USC:' + UPPER(cast(h.QR_secret_code as nvarchar(50))) as qr_secret_code,
--	coalesce(CASE 
--		WHEN h.NameDisplayPreference = 1
--			THEN h.HashName
--		WHEN h.NameDisplayPreference = 2
--			THEN h.FirstName + ' ' + h.LastName
--		ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
--		END,DisplayName,'<no name>')
--	AS displayName,
--	h.FirstName as firstName,
--	h.LastName as lastName,
--	h.HashName as hashName,
--	h.Email as email,
--	coalesce(@hasherKennelMapId,'00000000-0000-0000-0000-000000000000') as hasherKennelMapId,
--	coalesce(@hasherEventMapId, '00000000-0000-0000-0000-000000000000') as hasherEventMapId,
--	coalesce(@memberCounter,0) as memberCount
--FROM HC.Hasher h where h.id = @userId

  EXEC HC.nonApi_getUserResult @callingProcType = 0, @eventId = @eventId, @targetUserId = @newHasherId

END





GO
/****** Object:  StoredProcedure [HC2].[approveLogin]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [HC2].[approveLogin]

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
@hcVersion nvarchar(200) = 'pre 0.6.4'

AS

BEGIN

	SET NOCOUNT ON

-- EXEC HC.approveLaunch @userId = '00000000-0000-0000-0000-000000000000', @accessToken = '', @deviceId = 'TestDevice', @deviceType = 'iPhone 6s / iOS 11.4', @latitude = 52.4, @longitude = 4.4

	DECLARE @paramString nvarchar(500)
	SET @paramString = cast (@deviceId as nvarchar(50))

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error'),@paramString) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	DECLARE @userName nvarchar(250)

	SELECT @userName = coalesce(h.displayName, h.firstName + ' ' + h.lastName, '<no name>') from HC.Hasher h where h.id = @userId

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
	DECLARE @MessageEndDate datetime
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
		,svr.LastGazetteerUpdate as lastGazetteerUpdate
		,case when @ServerStatusCode = 1 then @ApprovalCode else 0 end as approvalCode
		,@LoginMessageTitle as loginMessageTitle
		,@LoginMessage as loginMessage
		,@ServerStatusCode as serverStatusCode
		,@MessageEndDate as messageEndDate
		,@MessageDisplayType as messageDisplayType
		,@MessageImageUrl as messageImageUrl
	FROM HC.ServerStatus svr
	ORDER BY svr.CreatedDate desc

END
GO
/****** Object:  StoredProcedure [HC2].[authorizeDevice]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC2].[authorizeDevice]

 @userId nvarchar(50),
 @accessToken nvarchar(1000),
 @hcVersion nvarchar(250),
 @scanText nvarchar(250),
 @deviceId nvarchar(250)

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

SET @userId = NULL
DECLARE @errorId uniqueidentifier

if (@scanText like 'USC:%')
BEGIN

	DECLARE @secretCode uniqueidentifier
	SET @secretCode = CAST(right(TRIM(@scanText),36) AS uniqueidentifier)

	SELECT top 1 
		@userId = h.id 
	FROM HC.Hasher h where h.QR_secret_code = @secretCode

	IF (@userId is not null)
		BEGIN
			EXEC HC.nonApi_getUserResult @callingProcType = 0, @eventId = '00000000-0000-0000-0000-000000000000', @targetUserId = @userId
		END
	ELSE
		BEGIN
				
		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,deviceId,string_1) VALUES (@errorId, @hcVersion, 'User secret code not found','A new user is being registered with a duplicate e-mail address to one already in the system',OBJECT_NAME(@@PROCID),@userId,@deviceId,@scanText)

		SELECT 
		@errorId as errorId,
		cast (5 as int) as errorType 
		,'User secret code not found' as errorTitle
		,'The user secret code that has been scanned was not found in the Harrier Central system. It is possible that this user has been deleted from the system. Please take a screenshot of the code and e-mail it to connect@harriercentral.com' as errorUserMessage
		,'This is a standard error that is anticipated and does not require debugging' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
		END

END

if (@scanText like 'RC:%')
BEGIN

	SELECT top 1 
		@userId = h.id 
	FROM HC.Hasher h where h.ResetCode = @scanText

	IF (@userId is not null)
		BEGIN
			EXEC HC.nonApi_getUserResult @callingProcType = 0, @eventId = '00000000-0000-0000-0000-000000000000', @targetUserId = @userId
		END
	ELSE
		BEGIN
		SET @errorId = newid()

		INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,deviceId,string_1) VALUES (@errorId,@hcVersion,'User reset code not found','A new user is being registered with a duplicate e-mail address to one already in the system',OBJECT_NAME(@@PROCID),@userId,@deviceId,@scanText)

		SELECT 
		@errorId as errorId,
		cast (5 as int) as errorType 
		,'Reset code not found' as errorTitle
		,'The reset code provided was not found in the Harrier Central system' as errorUserMessage
		,'This is a standard error that is anticipated and does not require debugging' as debugMessage
		,OBJECT_NAME(@@PROCID) as errorProc
		RETURN
		END

END

END





GO
/****** Object:  StoredProcedure [HC2].[editUser]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC2].[editUser]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @hcVersion nvarchar(250),
 @targetUserId uniqueidentifier,
 @email nvarchar(250) = null,
 @firstName nvarchar(100) = null,
 @lastName nvarchar(100) = null,
 @hashName nvarchar(100) = null,
 @photo nvarchar(500) = null

AS

BEGIN

SET NOCOUNT ON

-- NOTES: This proc edits an existing user... either the user who called it or an admin who is editing another user's record

	DECLARE @errorId uniqueidentifier

	IF @userId IS NULL
	BEGIN
		
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
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




	if (@firstName = '') SET @firstName = null
	if (@lastName = '') SET @lastName = null
	if (@photo = '') SET @photo = null
	if (@email = '') SET @email = null
	if (@hashName = '') SET @hashName = null

	IF (@email is not null)
	BEGIN
		IF (SELECT count(*) from HC.Hasher h where h.Email = trim(@email) and h.id <> @targetUserId) > 0
		BEGIN
			SET @errorId = newid()

			INSERT HC.ErrorLog (id, HcVersion, ErrorName,ErrorDescription,ProcName,userId,string_1) VALUES (@errorId,@hcVersion,'Duplicate email','A user being edited is being registered with a duplicate e-mail address to one already in the system',OBJECT_NAME(@@PROCID),@userId,@email)

			select 
			@errorId as errorId,
			cast (5 as int) as errorType 
			,'Email address already exists' as errorTitle
			,'A user already exists with this e-mail address in the system. Please register with a different e-mail address.' as errorUserMessage
			,'This is a standard error that is anticipated and does not require debugging' as debugMessage
			,OBJECT_NAME(@@PROCID) as errorProc
			RETURN
		END
	END

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
		ELSE coalesce(@hashName, h.HashName) + ' (' + coalesce(@firstName,h.FirstName) + ' ' + coalesce(@lastName,h.LastName) + ')' END
	FROM HC.Hasher h where id = @targetUserId

  EXEC HC.nonApi_getUserResult @callingProcType = 0, @eventId = null, @targetUserId = @targetUserId

END





GO
/****** Object:  StoredProcedure [HC2].[getAllHashers]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC2].[getAllHashers]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @updatedAfter nvarchar(50)

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


	DECLARE @ua datetime
	SET @ua = CAST(@updatedAfter as datetime)

	SELECT 
		h.id as ui,
		coalesce(h.FirstName,'') as fn,
		coalesce(h.LastName,'') as ln,
		coalesce(h.DisplayName,'') as dn,
		coalesce(h.HashName,'') as hn,
		coalesce(h.Photo,'') as p,
		coalesce(h.NameDisplayPreference,0) as dp,
		coalesce(h.updatedAt,getdate()) as ua,
		coalesce(h.Removed,0) as removed
	FROM HC.Hasher h where updatedAt >= @ua
END





GO
/****** Object:  StoredProcedure [HC2].[getAllKennels]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC2].[getAllKennels]

 @userId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @accessToken nvarchar(1000) = 'none',
 @kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
 @userLatitude float = null,
 @userLongitude float = null,
 @distanceFromUserInKm float = null,
 @procName nvarchar(250) = null

AS

BEGIN

	SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,coalesce(@procName,OBJECT_NAME(@@PROCID)),coalesce(@accessToken,'error'),NULL) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	-- EXEC HC.[getAllKennels] @userLatitude = 52.1663, @userLongitude =  4.4814, @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @accessToken = '', @distanceFromUserInKm = 250, @kennelId = '00000000-0000-0000-0000-000000000000'
	-- EXEC HC.[getAllKennels] @accessToken = '', @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @distanceFromUserInKm = 2000, @kennelId = '00000000-0000-0000-0000-000000000000'

	IF ((@userLatitude is NULL) OR (@userLongitude IS NULL))
	BEGIN
		-- Assume Leiden Centraal Station
		SET @userLatitude = 52.1663
		SET @userLongitude = 4.4814
	END

	IF (@kennelId is null) SET @kennelId = '00000000-0000-0000-0000-000000000000'

	IF ((@distanceFromUserInKm IS NULL) OR (@distanceFromUserInKm <= 0)) SET @distanceFromUserInKm = 99999

	DECLARE @geoLoc	AS GEOGRAPHY
	SET @geoloc = geography::Point(@userLatitude,@userLongitude,4326) 

		SELECT k.[id] as kennelId
				,cast ((@geoloc.STDistance(k.kennelGeolocation)) as int) as distance
				,CASE WHEN coalesce (hkm.[Following],0) = 0 THEN 'off' ELSE 'on' END  as [following]
				,coalesce (hkm.[Following],0) as [followingBool]
				,[kennelStatus] 
				,[kennelName]
				,[kennelDescription]
				,k.cityId
				,k.kennelWebsiteUrl
				,k.kennelFacebookId
				,k.kennelFacebookToken
				,k.kennelFacebookTokenUserId
				,k.autoImportFacebookEvents
				,k.importOnlyTaggedEvents
				,k.facebookTagForImport
				,k.defaultEventCurrencyType
				,k.defaultEventPriceForNonMembers
				,k.defaultEventPriceForMembers
				,k.defaultRunStartTime
				,coalesce([KennelShortName],[KennelName],'<no name>') as [kennelShortName]
				,case when datalength(coalesce(KennelLogo,'')) < 4 then 'https://harriercentral.blob.core.windows.net/harrier/MissingLogo.png' else KennelLogo end as kennelLogo
				,k.[latitude]
				,k.[longitude]
				,(select count(*) from HC.Haberdashery hd where hd.KennelId = k.id and hd.Archive = 0) as activeHaberdasheryItems
				,(select count(*) from HC.Haberdashery hd where hd.KennelId = k.id and hd.Archive != 0) as archiveHaberdasheryItems
				,coalesce((select top 1 evt.EventStartDatetime from HC.Event evt where evt.KennelId = k.id and evt.EventStartDatetime >= dateadd(day,-1,getdate()) ORDER BY evt.EventStartDatetime asc),'1/1/1900') as dateNextRun
				,c.CityName + ', ' + case when n.ShowRegion = 1 then r.RegionName + ', ' else '' end + n.CountryName as locationName
				,hkm.isMember  
				,hkm.mismanagementRoleFlags
				,hkm.appAccessFlags
				,CASE
				WHEN (h.id IS NOT NULL) THEN 1
					ELSE 0
				END
				as isHomeKennel
				,0 as authAllowCredit
				,0 as authCheckInAndOut
				,0 as authCustomLogo
				,0 as authCustomSongbook
				,0 as authFacebookIntegration
				,0 as authHaberdashery
				,0 as authHareRaisingManagement
				,0 as authMembersAllowed
				,0 as authPromoteEvents
				,0 as authPushNotifications
				,0 as authTrackPayments
				,0 as authWebsiteIntegration
				,(select count(*) from HC.HasherKennelMap hkm2 where hkm2.KennelId = k.id and hkm2.IsMember = 1) as memberCount
		 
		  FROM [HC].[Kennel] k 
		  LEFT OUTER JOIN HC.HasherKennelMap hkm on k.id = hkm.KennelId and hkm.UserId = @userId
		  LEFT OUTER JOIN HC.City c on c.id = k.CityId
		  LEFT OUTER JOIN HC.Region r on r.id = c.RegionId
		  LEFT OUTER JOIN HC.Country n on n.id = r.CountryId
		  LEFT OUTER JOIN HC.Hasher h on h.Home_KennelId = k.id AND h.id = @userId
		  --LEFT OUTER JOIN HC.KennelAuthorization kAuth on kAuth.KennelId = k.id AND kAuth.EndDate IS NULL

		  WHERE 
		  ((@kennelId = '00000000-0000-0000-0000-000000000000') OR (k.id = @kennelId)) AND
			
				((@geoloc.STDistance(k.kennelGeolocation)/1000) <= @distanceFromUserInKm)
			
		  ORDER BY 
		    case when hkm.[Following] = 0 then 0 -- this strange case statement orders the records with the "following" items at the top
				 when hkm.[Following] = 1 then 2
				 when hkm.[Following] = 2 then 1
				end DESC,
			@geoloc.STDistance(k.kennelGeolocation)
			
END
	

  


GO
/****** Object:  StoredProcedure [HC2].[getFutureRunsByDistance]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC2].[getFutureRunsByDistance]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @latitude decimal(18,15) = null,
 @longitude decimal (19,15) = null,
 @distanceInKm float = null,
 @procName nvarchar(100) = null -- this is here to allow other stored procs to call this one and pass in their own accessTokens

AS

BEGIN

-- EXEC HC2.getFutureRunsByDistance @userId = '052584EB-FACA-43F9-BD91-5A05AA2E7947', @accessToken = '', @distanceInKm = 500, @latitude = 52.16, @longitude = 4.49

	SET NOCOUNT ON

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,coalesce(@procName,OBJECT_NAME(@@PROCID)),coalesce(@accessToken,'error'),NULL) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	DECLARE @geoLoc	AS GEOGRAPHY
	SET @geoloc = geography::Point(@latitude,@longitude,4326) 
		
-- first get a list of all kennels that this user is following plus all of the
-- kennels where this user has RSVP'ed for an upcoming run in the future or
-- all kennels within the prescribed distance that are not being actively unfollowed
-- this allows us to show runs for nearby kennels that the user may not be aware of	
select 
	distinct(k.id) as KennelId,
	k.KennelShortName,
	k.KennelLogo,
	k.Latitude,
	k.Longitude,
	k.DefaultEventPriceForMembers,
	k.DefaultEventPriceForNonMembers,
	k.DefaultEventCurrencyType,
	c.CurrencySymbol,
	c.DigitsAfterDecimal,
	coalesce(hkm.CurrentHaringCount + hkm.CurrentPackRunCount,0) as totalRunsThisKennel,
	coalesce(hkm.MismanagementRoleFlags,0) as mismanagementRoleFlags
into #temp
FROM HC.Kennel k 
inner join HC.Country c on c.id = k.CountryId
left outer join HC.HasherKennelMap hkm on hkm.KennelId = k.id and hkm.UserId = @userId
left outer join HC.HasherEventMap hem on hem.UserId = @userId
left outer join HC.Event e on e.id = hem.EventId and e.KennelId = k.id

where (
		(hkm.Following = 1)
		or (e.EventStartDatetime >= dateadd(day,-1,getdate()) AND hem.RsvpState = 3)
	  )
OR 
	  (
	  	((@distanceInKm IS NOT NULL) AND (@geoloc.STDistance(k.[KennelGeoLocation])/1000) <= @distanceInKm)
		AND
		(coalesce(hkm.Following,0) != 2)
	  )	

--select * from #temp		

-- now find the future runs for each of these kennels and return the relevant information
select
		e.id as eventId
		,e.KennelId as kennelId
		,e.EventName as eventName
		,e.EventNumber as eventNumber
		,coalesce(e.LocationOneLineDesc,'') as locationOneLineDesc
		,e.EventDescription as eventDescription
		,coalesce(e.[EventPriceForMembers],k.DefaultEventPriceForMembers,-1) as eventPriceForMembers
		,coalesce(e.[EventPriceForNonMembers],k.DefaultEventPriceForNonMembers,-1) as eventPriceForNonMembers
		,coalesce(e.[EventCurrencyType],k.DefaultEventCurrencyType,'en-US') as eventCurrencyType

		,k.CurrencySymbol as currencySymbol
		,k.DigitsAfterDecimal as digitsAfterDecimal

		,coalesce(e.[EventImage],'') as eventImage
		,coalesce(e.[EventShortDesc],'') as eventShortDesc
		,coalesce(e.[LocationCity],'') as locationCity
		,coalesce(e.[LocationStreet],'') as locationStreet
		,coalesce(e.[LocationPostCode],'') as locationPostCode

		,(select count(*) from HC.HasherEventMap hem3 WHERE EventId = e.id and RsvpState = 3) as attendingEvent
		,(select count(*) from HC.HasherEventMap hem3 WHERE EventId = e.id and RsvpState = 2) as maybeAttendingEvent
		,(select count(*) from HC.HasherEventMap hem3 WHERE EventId = e.id and RsvpState = 1) as notAttendingEvent
		,(select count(*) from HC.HasherEventMap hem3 WHERE EventId = e.id and hem3.IsHare = 1) as haresCount

		,coalesce((select STRING_AGG(h.DisplayName,', ') from HC.HasherEventMap hem2 inner join HC.Hasher h on hem2.UserId = h.id and hem2.IsHare = 1 and hem2.EventId = e.id),'') as hareList

		,coalesce(e.Latitude,e.FbLatitude,k.Latitude) as latitude
		,coalesce(e.Longitude,e.FbLongitude,k.Longitude) as longitude
		,case when datalength(coalesce(k.KennelLogo,'')) < 4 then 'https://harriercentral.blob.core.windows.net/harrier/MissingLogo.png' else KennelLogo end as kennelLogo
		,coalesce(datediff(day,getdate(),e.EventStartDatetime),99999) as daysUntilNextRun
		,e.EventStartDatetime as eventStartDatetime
		,coalesce((SELECT count(*) FROM HC.HasherEventMap hem2 INNER JOIN HC.HasherFriendMap hfm2 on hfm2.Friend_UserId = hem2.UserId WHERE hfm2.UserId = @userId AND hem2.EventId = e.id),0) as friendsAttending
		,coalesce(hem.RsvpState,0) as rsvpState
		,coalesce(hem.AttendenceState,0) as attendenceState
		,coalesce(hem.IsHare,0) as isHare
		,k.totalRunsThisKennel
		,coalesce(k.KennelShortName,'H3') as kennelShortName
		,k.mismanagementRoleFlags as mismanagementRoleFlags
		,CAST(ROW_NUMBER() OVER (PARTITION BY e.KennelId ORDER BY e.EventStartDatetime ASC) AS INT) as runSequence
		,CAST(coalesce(@geoLoc.STDistance(e.EventGeolocation),-1) as INT) as distanceToEvent
		,e.IsVisible as isVisible
		FROM HC.Event e
		INNER JOIN #temp k on e.KennelId = k.KennelId
		LEFT OUTER JOIN HC.HasherEventMap hem on hem.UserId = @userId AND hem.EventId = e.id
		WHERE CONVERT(date,e.EventStartDatetime) >= CONVERT(date,getdate()) 
		--AND e.IsVisible <> 0
	UNION
		SELECT
		'00000000-0000-0000-0000-000000000000' as eventId
		,k.KennelId as kennelId
		,'<no planned runs>' as eventName
		,-1 as eventNumber
		,'' as locationOneLineDesc
		,'' as eventDescription

		,'' as eventPriceForMembers
		,'' as eventPriceForNonMembers
		,coalesce(k.DefaultEventCurrencyType,'en-US') as eventCurrencyType

		,k.CurrencySymbol as currencySymbol
		,k.DigitsAfterDecimal as digitsAfterDecimal

		,'' as eventImage
		,'' as eventShortDesc
		,'' as locationCity
		,'' as locationStreet
		,'' as locationPostCode

		,-1 as attendingEvent
		,-1 as maybeAttendingEvent
		,-1 as notAttendingEvent
		,-1 as haresCount

		,'' as hareList

		,k.Latitude as latitude
		,k.Longitude as longitude
		,case when datalength(coalesce(k.KennelLogo,'')) < 4 then 'https://harriercentral.blob.core.windows.net/harrier/MissingLogo.png' else KennelLogo end as kennelLogo
		,99999 as daysUntilNextRun
		,'1/1/2100' as eventStartDatetime
		,0 as friendsAttending
		,0 as rsvpState
		,0 as attendenceState
		,0 as isHare
		,0 as totalRunsThisKennel
		,coalesce(k.KennelShortName,'H3') as kennelShortName
		,0 as mismanagementRoleFlags
		,0 as runSequence
		,-1 as distanceToEvent
		,0 as isVisible
		FROM #temp k 
		WHERE (SELECT count(*) FROM HC.Event e WHERE e.KennelId = k.KennelId AND CONVERT(date,e.EventStartDatetime) >= CONVERT(date,getdate())) = 0
		
	ORDER BY eventStartDatetime ASC				       


	drop table #temp
			
END


GO
/****** Object:  StoredProcedure [HC2].[getKennelMembers]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC2].[getKennelMembers]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@kennelId uniqueidentifier

AS

BEGIN

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


	SELECT 
		h.id as hasherId
		,h.HashName as hashName
		,h.FirstName as firstName
		,h.LastName as lastName
		,h.DisplayName as displayName
		,h.NameDisplayPreference as dispPref
		,h.Photo as photo
		,h.QR_code as qr_code
		,h.QR_secret_code as qr_secret_code
	FROM HC.Hasher h
	INNER JOIN HC.HasherKennelMap hkm on hkm.KennelId = @kennelId and hkm.UserId = h.id
	WHERE deleted = 0 and hkm.IsMember = 1
END

GO
/****** Object:  StoredProcedure [HC2].[getMyKennelRunTotals]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC2].[getMyKennelRunTotals]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
@procName nvarchar(100) = null  -- this is here to allow other stored procs to call this one and pass in their own accessTokens

AS

-- EXEC HC.getMyKennelRunTotals @userId = '5C4AE228-2CC1-467F-B666-F62EFEDFEE14',@accessToken = ''

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


select k.id as KennelId
,k.KennelLogo
,k.KennelName
,hkm.CurrentPackRunCount + hkm.CurrentHaringCount as TotalRunsThisKennel
,hkm.CurrentPackRunCount as TotalPackRunsThisKennel
,hkm.CurrentHaringCount as TotalHaringThisKennel
,hkm.[Following]
,k.KennelShortName
into #temp
from HC.HasherKennelMap hkm
inner join HC.Kennel k on hkm.KennelId = k.id
where hkm.userId = @userId
and ((@kennelId = '00000000-0000-0000-0000-000000000000') OR (hkm.KennelId = @kennelId))
and (hkm.CurrentPackRunCount + hkm.CurrentHaringCount > 0) -- need to validate this through testing... we don't want to list a kennel that's not being followed and also has no runs
order by hkm.CurrentPackRunCount + hkm.CurrentHaringCount desc

-- next insert rows for kennels that we are following but that do not have any runs yet
insert #temp (KennelId,KennelLogo,KennelName,TotalRunsThisKennel,TotalPackRunsThisKennel,TotalHaringThisKennel,[Following],KennelShortName)
select k.id,k.KennelLogo,k.KennelName,0,0,0,hkm.[Following],k.KennelShortName
FROM HC.Kennel k
inner join HC.HasherKennelMap hkm on k.id = hkm.KennelId and hkm.UserId = @userId
WHERE hkm.Following = 1
AND hkm.KennelId not in (select kennelId from #temp)

declare @photo nvarchar(500)
select @photo = photo from HC.Hasher where id = @userId

select 
	KennelId as kennelId
	,KennelLogo as kennelLogo
	,KennelName as kennelName
	,TotalRunsThisKennel as totalRunsThisKennel
	,TotalPackRunsThisKennel as totalPackRunsThisKennel
	,TotalHaringThisKennel as totalHaringThisKennel
	,[Following] as [following]
	,KennelShortName as kennelShortName
	from #temp where Following = 1 OR TotalRunsThisKennel > 0
union
	select 
	'00000000-0000-0000-0000-000000000000' as kennelId
	 ,@photo as kennelLogo
	 ,'My total run count' as kennelName
	 ,sum(TotalRunsThisKennel) as totalRunsThisKennel
	 ,sum(TotalPackRunsThisKennel) as totalPackRunsThisKennel
	 ,sum(TotalHaringThisKennel) as totalHaringThisKennel
	 ,1 as [Following]
	 ,'My runs' as kennelShortName from #temp

order by TotalRunsThisKennel desc
GO
/****** Object:  StoredProcedure [HC2].[getPaymentReport]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC2].[getPaymentReport]

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
/****** Object:  StoredProcedure [HC2].[getResetCode]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [HC2].[getResetCode]

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
/****** Object:  StoredProcedure [HC2].[getRuns]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC2].[getRuns]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@kennelId uniqueidentifier = '00000000-0000-0000-0000-000000000000',
@following smallint = -1,
@filterByUser smallint = 1,
@includeHidden smallint = 0,
@includeFuture smallint = 0

AS

-- EXEC HC.getMyRuns @userId = '6f901167-4bd3-45af-9da0-6af5a1128f42'
-- EXEC HC.getMyRuns @userId = '624c51b3-2f64-4de5-9458-b506e75ac544',@kennelId = '00000000-0000-0000-0000-000000000000'
-- EXEC HC.getMyRuns @userId = 'e15f27d1-1ac2-4241-a4fe-00e045cc3091',@kennelId = '6f901167-4bd3-45af-9da0-6af5a1128f42', @accessToken = '', @following = -1

SET NOCOUNT ON

	--DECLARE @paramString nvarchar(500)
	--SET @paramString = cast(coalesce(@kennelId,'00000000-0000-0000-0000-000000000000') as nvarchar(50)) + '#' + cast(@filterByUser as nvarchar(50))
	

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

	DECLARE @userId_internal uniqueidentifier
	if (@filterByUser = 1) SET @userId_internal = @userId

select 
e.id as eventId
,e.eventStartDatetime as eventStartDatetime
,e.eventEndDatetime as eventEndDatetime
,e.eventName as eventName
,e.EventNumber as eventNumber
,e.LocationOneLineDesc as locationOneLineDesc
,e.userEventCounterIncrement as userEventCounterIncrement
,e.EventFacebookId as eventFacebookId
,e.IsVisible as isVisible
,e.IsCountedRun as isCountedRun
,e.AbsoluteEventNumber as absoluteEventNumber
,hem.isHare as isHare
,hem.totalRunsThisKennel as totalRunsThisKennel
,hem.totalRunsAllKennels as totalRunsAllKennels
,hem.TotalHaringThisKennel as totalHaringThisKennel
,hem.userStartEvent as userStartEvent
,coalesce(hem.RsvpState,0) as rsvpState
,coalesce(hem.AttendenceState,0) as attendenceState
,e.CanEditRunAttendence * hkm.CanEditRunAttendence * k.CanEditRunAttendence as canEditRunAttendence
,coalesce(hkm.MismanagementRoleFlags,0) as mismanagementRoleFlags
FROM HC.Event e 
INNER JOIN HC.Kennel k on k.id = e.KennelId
LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.UserId = @userId_internal AND hkm.KennelId = k.id
LEFT OUTER JOIN HC.HasherEventMap hem on hem.UserId = @userId_internal and hem.EventId = e.id

WHERE e.deleted = 0 
AND ((@includeHidden = 1) OR (e.IsVisible <> 0))
AND ((@includeHidden = 1) OR (e.IsCountedRun = 1))
AND ((@following = -1) OR (hkm.Following = @following))
AND ((@includeFuture = 1) OR (e.EventStartDatetime <= dateadd(day,1,getdate())))
AND ((@kennelId = '00000000-0000-0000-0000-000000000000') OR (e.KennelId = @kennelId))
ORDER BY e.EventStartDatetime DESC,EventId DESC



GO
/****** Object:  StoredProcedure [HC2].[getUsersByEvent]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [HC2].[getUsersByEvent]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@EventId uniqueidentifier

AS

SET NOCOUNT ON

-- exec HC2.getUsersByEvent @eventId = 'E8500153-3B47-4699-9124-5CA824E956C8'
-- exec HC2.getUsersByEvent @eventId = 'a0f677e8-2f50-4483-b71e-f1138bc039fc', @userId = '', @accessToken = ''

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


SELECT

	-- From HC.HasherEventMap
	 h.id as hasherId,
	 hem.id AS [hasherEventMapId]
	 	,coalesce(hem.rsvpState,0) as rsvpState
		,coalesce(hem.attendenceState,0) as attendenceState
	 	,coalesce(CASE 
		WHEN h.NameDisplayPreference = 1
			THEN h.HashName
		WHEN h.NameDisplayPreference = 2
			THEN h.FirstName + ' ' + h.LastName
		ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
		END,hem.DisplayName,'<no name>')
		 AS displayName

	,CASE 
		WHEN (hem.[VirginVisitorType] = 0)
			THEN h.Photo
		WHEN (hem.[VirginVisitorType] = 1)	
			THEN 'https://harriercentral.blob.core.windows.net/harrier/Virgin.png'
		WHEN (hem.[VirginVisitorType] = 2)	
			THEN 'https://harriercentral.blob.core.windows.net/harrier/Visitor.png'
		ELSE
			CASE WHEN h.Photo IS NULL THEN	
			'https://harriercentral.blob.core.windows.net/harrier/Visitor.png'
			ELSE
				h.Photo
			END
		END AS photo

       ,coalesce(hem.[IsHare],0) as isHare



FROM HC.Hasher h
INNER JOIN HC.Event e ON e.id = @EventId
INNER JOIN HC.Kennel k ON k.id = e.KennelId 
INNER JOIN HC.HasherEventMap hem on hem.UserId = h.id AND hem.EventId = @EventId

WHERE (
	 hem.EventId = e.id
	)
	--AND e.deleted = 0 AND e.IsVisible <> 0
ORDER BY 
	COALESCE(
	CASE 
		WHEN h.NameDisplayPreference = 1
			THEN h.HashName
		WHEN h.NameDisplayPreference = 2
			THEN h.FirstName + ' ' + h.LastName
		ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
		END
		,hem.DisplayName,'<no name>')





GO
/****** Object:  StoredProcedure [HC2].[getUsersByEventForAdmin]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [HC2].[getUsersByEventForAdmin]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@eventId uniqueidentifier,
@targetUserId uniqueidentifier = null

AS

SET NOCOUNT ON

-- exec HC2.getUsersByEventForAdmin @userId = '052584EB-FACA-43F9-BD91-5A05AA2E7947', @accessToken = '', @eventId = '9DC22B4B-A39C-4F09-9506-1C0B0ADA75BA'

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

	EXEC HC.nonApi_getUserResult @callingProcType = 0, @eventId = @eventId, @targetUserId = @targetUserId

--	DECLARE @AtHashCount smallint
--	DECLARE @OnInCount smallint
--	DECLARE @OnTrailCount smallint
--	DECLARE @PaidCount smallint
--	DECLARE @WaitingForCount smallint

--	IF (@TargetUserId = '00000000-0000-0000-0000-000000000000') SET @TargetUserId = null

--	--SELECT 
--	--	@AtHashCount = count(hem2.UserStartEvent),
--	--	@OnInCount = count(hem2.UserEndEvent),
--	--	@OnTrailCount = count(hem2.UserStartEvent)-count(hem2.UserEndEvent) 
--	--FROM HC.HasherEventMap hem2 WHERE hem2.EventId = @EventId

--	SELECT 
--		@AtHashCount = sum(case when hem2.AttendenceState >= 20 then 1 else 0 end),
--		@OnInCount = sum(case when hem2.AttendenceState >= 30 then 1 else 0 end),
--		@OnTrailCount = sum(case when hem2.AttendenceState >= 20 then 1 else 0 end)-sum(case when hem2.AttendenceState >= 30 then 1 else 0 end) 
--	FROM HC.HasherEventMap hem2 WHERE hem2.EventId = @EventId

--	SELECT 
--		@WaitingForCount = count(*)
--	FROM HC.HasherEventMap hem WHERE hem.EventId = @EventId AND hem.AttendenceState < 20 AND hem.RsvpState = 3

--	SELECT @PaidCount = count(*) from HC.Payment p where p.EventId = @EventId and p.CancelledDate is null

--	SELECT coalesce(sum(p.creditAmount)-sum(p.debitAmount),0) as Credit
--			,p.UserId
--			,e.KennelId
--	INTO #creditTemp
--	FROM HC.Hasher h
--	INNER JOIN HC.Event e ON e.id = @EventId
--	INNER JOIN HC.Kennel k ON k.id = e.KennelId 
--	INNER JOIN HC.Payment p on p.UserId = h.id
--	LEFT OUTER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = k.id AND hkm.UserId = h.id
--	LEFT OUTER JOIN HC.HasherEventMap hem on hem.UserId = h.id AND hem.EventId = @EventId
--	WHERE (
--		 ((hem.EventId = e.id) AND (hem.UserId = h.id)) OR -- this covers users who have RSVP'ed
--		 ((hkm.KennelId = k.id) AND (hkm.UserId = h.id) AND ((hkm.Following = 1) OR (hkm.IsMember = 1)))  -- this covers users who are either members of a kennel or following that kennel
--		)
--		AND e.deleted = 0 AND e.IsVisible <> 0
--		AND p.CancelledDate is null
--		AND ((@TargetUserId IS NULL) OR (h.id = @TargetUserId))
--	GROUP BY 
--		p.UserId, e.KennelId

--SELECT
--	@EventId as eventId
--	,h.id as userId
--	,coalesce(hkm.Following,0) as isFollowing
--	,coalesce(hkm.IsMember,0) as isMember
--	,case when hem.id is null then 0 else 1 end as isRsvped
--	-- From HC.HasherEventMap
--	 ,hem.id AS [hasherEventMapId]

--	--,hem.[RegistrationId]
--	,coalesce(hem.[IsHare],0) as isHare
--	,coalesce(hem.[VirginVisitorType],0) as virginVisitorType
--	,hem.[UserStartEvent] as userStartEvent
--	,hem.[UserEndEvent] as userEndEvent
--	--,hem.[Rsvp]
--	,coalesce(hem.[RsvpState],0) as rsvpState
--	,coalesce(hem.[AttendenceState],0) as attendenceState


--	-- From HC.Payment

--	,case when pay.id is not null then 1 else 0 end as isPaid
--	,coalesce(pay.PaymentType,-1) as paymentType  

--	-- FROM HC.Hasher
--	,coalesce(h.email,'') as eMail
--	,coalesce(h.facebookId,'') as facebookId
--	,coalesce(h.firstName,'') as firstName
--	,coalesce(h.HashName,'') as hashName
--	,coalesce(h.lastName,'') as lastName
--	,coalesce(h.QR_code,'') as qrCode
--	,'**********' as qrSecretCode
--	,coalesce(CASE 
--		WHEN h.NameDisplayPreference = 1
--			THEN h.HashName
--		WHEN h.NameDisplayPreference = 2
--			THEN h.FirstName + ' ' + h.LastName
--		ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
--		END,hem.DisplayName,'<no name>')
--		 AS displayName
--	,CASE 
--		WHEN (hem.[VirginVisitorType] = 0)
--			THEN h.Photo
--		WHEN (hem.[VirginVisitorType] = 1)	
--			THEN 'bundle://avatar-virgin'
--		WHEN (hem.[VirginVisitorType] = 2)	
--			THEN 'bundle://avatar-visitor'
--		ELSE
--			CASE WHEN h.Photo IS NULL THEN	
--			'bundle://avatar-visitor'
--			ELSE
--				h.Photo
--			END
--		END AS photo

--	-- Aggregates from HC.HasherEventMap
--	,coalesce(CASE 
--		WHEN (hem.[VirginVisitorType] <> 0)
--			THEN CASE WHEN hem.AttendenceState >= 20 THEN 1 ELSE 0 END
--		ELSE
--			coalesce(hem.TotalRunsThisKennel,0) END,0)
--		AS userRunCount

--	-- Live totals for display at top of HasherList
--	,@WaitingForCount AS waitingForCount
--	,@AtHashCount AS atHashCount
--	,@OnInCount AS onInCount
--	,@OnTrailCount AS onTrailCount
--	,@PaidCount AS paidCount
--	,CASE WHEN COALESCE(hkm.IsMember, 0) = 1
--							THEN coalesce(e.EventPriceForMembers, k.DefaultEventPriceForMembers, e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers, 0)
--						ELSE coalesce(e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers, e.EventPriceForMembers, k.DefaultEventPriceForMembers, 0)
--						END AS eventPrice
--    , coalesce(e.EventCurrencyType, k.DefaultEventCurrencyType, 'en-us') as eventLocale
--	, k.AllowNegativeCredit as allowNegativeCredit
--	, coalesce(ct.Credit,0) as credit
--	, c.CurrencySymbol as currencySymbol
--	, c.DigitsAfterDecimal as digitsAfterDecimal
	
--FROM HC.Hasher h
--INNER JOIN HC.Event e ON e.id = @EventId
--INNER JOIN HC.Kennel k ON k.id = e.KennelId 
--INNER JOIN HC.Country c on c.id = k.CountryId
--LEFT OUTER JOIN HC.HasherKennelMap hkm ON hkm.KennelId = k.id AND hkm.UserId = h.id
--LEFT OUTER JOIN HC.HasherEventMap hem on hem.UserId = h.id AND hem.EventId = @EventId
--LEFT OUTER JOIN HC.Payment pay on pay.HasherEventMapId = hem.id and pay.CancelledDate is null 
--LEFT OUTER JOIN #creditTemp ct ON ct.UserId = h.id and ct.KennelId = k.id

--WHERE (
--	 ((hem.EventId = e.id) AND (hem.UserId = h.id)) OR -- this covers users who have RSVP'ed
--	 ((hkm.KennelId = k.id) AND (hkm.UserId = h.id) AND ((hkm.Following = 1) OR (hkm.IsMember = 1)))  -- this covers users who are either members of a kennel or following that kennel
--	)
--	AND e.deleted = 0 and e.IsVisible <> 0
--	AND ((@TargetUserId IS NULL) OR (h.id = @TargetUserId))
--ORDER BY 
--	COALESCE(
--	CASE 
--		WHEN h.NameDisplayPreference = 1
--			THEN h.HashName
--		WHEN h.NameDisplayPreference = 2
--			THEN h.FirstName + ' ' + h.LastName
--		ELSE h.HashName + ' (' + h.FirstName + ' ' + h.LastName + ')'
--		END
--		,hem.DisplayName,'<no name>')





GO
/****** Object:  StoredProcedure [HC2].[joinEvent]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [HC2].[joinEvent]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @eventId uniqueidentifier,
 @hasherId uniqueidentifier,
 @hasherEventMapId uniqueidentifier,
 
 @isHare VARCHAR(10) = '-1',
 @rsvpState VARCHAR(10) = '-1',
 @attendenceState VARCHAR(10) = '-1',

 @resultsRequested nvarchar(25) = 'Attendance totals'

AS

BEGIN

-- EXEC HC.JoinEvent @eventId = '7B10155A-92D4-40D7-929A-CF2BDE968444', @userId = '624c51b3-2f64-4de5-9458-b506e75ac544'

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

DECLARE @isHareNumeric smallint
DECLARE @rsvpStateNumeric smallint
DECLARE @attendenceStateNumeric smallint

SET @isHareNumeric = CAST(@isHare as smallint)
SET @rsvpStateNumeric = CAST(@rsvpState as smallint)
SET @attendenceStateNumeric = CAST(@attendenceState as smallint)

if (@hasherEventMapId = '00000000-0000-0000-0000-000000000000') SET @hasherEventMapId = null

-- There are three cases where this can be called
-- Case #1: HasherId and HasherEventMapId are null... this is when the user is RSVP'ing themselves
-- Case #2: HasherEventMapId is null but HasherId is not null... this is where an admin is RSVP'ing another Hasher who has a record in HC.Hasher
-- Case #3: HasherEventMapId is not null, but HasherId is null... this is where an admin is RSVP'ing a Visitor or Virgin who does not have a record in HC.Hasher


if ((@hasherId is null) AND (@hasherEventMapId is null)) -- CASE #1
BEGIN
	SET @hasherId = @userId
END

if (@hasherEventMapId is null) -- Handle CASE #1 and #2
BEGIN
	SELECT @hasherEventMapId = id from HC.HasherEventMap WHERE UserId = @hasherId AND EventId = @eventId

	IF (@hasherEventMapId is null)
	BEGIN 
		SET @hasherEventMapId = newid()
		INSERT INTO HC.HasherEventMap(id,UserId,EventId) VALUES (@hasherEventMapId,@hasherId,@eventId) 
	END
END


UPDATE HC.HasherEventMap SET 
	IsHare = case when @isHareNumeric <> -1 then @isHareNumeric else IsHare end,
	RsvpState = case when @rsvpStateNumeric <> -1 then @rsvpStateNumeric else RsvpState end,
	Rsvp = case when @rsvpState <> -1 then getdate() else Rsvp end,
	AttendenceState = case when @attendenceStateNumeric <> -1 then @attendenceStateNumeric else AttendenceState end
	WHERE id = @hasherEventMapId


IF @attendenceStateNumeric <> -1 OR @rsvpStateNumeric <> -1
BEGIN
	IF (@hasherId is not null)
		BEGIN
			-- Handle CASES #1 & #2
			EXEC HC.nonApi_adjustHasherRunCounts @limitByUser = 1,@userId = @hasherId
		END
	ELSE
		BEGIN
			-- Handle CASE #3
			EXEC HC.nonApi_adjustHasherRunCounts @limitByUser = 2,@hasherEventMapId = @hasherEventMapId
		END
END

DECLARE @rsvpYes smallint
DECLARE @rsvpNo smallint
DECLARE @rsvpMaybe smallint
DECLARE @hares smallint
DECLARE @totalRunsThisKennsl smallint
DECLARE @totalRunsAllKennels smallint


-- TODO: We may have to join on these with HC.Event to filter deleted events out of the count
IF (@resultsRequested = 'Attendance totals')
BEGIN
	SELECT @rsvpYes = count(*) from HC.HasherEventMap WHERE EventId = @EventId and RsvpState = 3
	SELECT @rsvpMaybe = count(*) from HC.HasherEventMap WHERE EventId = @EventId and RsvpState = 2
	SELECT @rsvpNo = count(*) from HC.HasherEventMap WHERE EventId = @EventId and RsvpState = 1
	SELECT @hares = count(*) from HC.HasherEventMap WHERE EventId = @EventId and IsHare = 1

	SELECT top 1 @rsvpYes as rsvpYesCount, @rsvpNo as rsvpNoCount, @rsvpMaybe as rsvpMaybeCount, @hares as haresCount, 
		hem.TotalRunsThisKennel as totalRunsThisKennel, 
		hem.TotalRunsAllKennels as totalRunsAllKennels,
		hem.id as hasherEventMapId
	FROM HC.HasherEventMap hem
	WHERE id=@hasherEventMapId 
END

if (@resultsRequested = 'Run counts')
BEGIN
	SELECT evt.id AS EventId, TotalRunsAllKennels,TotalRunsThisKennel FROM HC.HasherEventMap hem 
	INNER JOIN HC.Event evt ON hem.EventId = evt.id
	WHERE hem.UserId = @hasherId 
	AND evt.EventStartDatetime >= 
		(SELECT evt2.EventStartDatetime FROM HC.Event evt2 WHERE evt2.id = @eventId) 
END

END





GO
/****** Object:  StoredProcedure [HC2].[joinEventAsVisitor]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC2].[joinEventAsVisitor]  

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@eventId uniqueidentifier, 
@displayName nvarchar(250), 
@virginVisitorType smallint,
@attendenceState smallint,
@email nvarchar(250),
@phoneNumber nvarchar(250)

AS

-- exec HC.joinEventAsVisitor @eventId = '7B10155A-92D4-40D7-929A-CF2BDE968444', @displayName = 'Stacy', @virginVisitorType = '0'
BEGIN

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

		INSERT INTO [HC].[HasherEventMap]
				   ([id]
				   ,[EventId]
				   ,[UserId]
				   ,[UserStartEvent]
				   ,[EventCost]
				   ,[Rsvp]
				   ,[RsvpState]
				   ,[AttendenceState]
				   ,[VirginVisitorType] -- 0 = HasherInSystem, 1 = Virgin, 2 = Visitor
				   ,[DisplayName]
				   ,[Email]
				   ,[PhoneNumber])

				SELECT @hasherEventMapId
					,@eventId
					,e.KennelId 
					,getdate()
					,e.EventPriceForNonMembers
					,getdate()
					,3 -- RSVP state as 'coming'
					,@attendenceState
					,@virginVisitorType
					,@displayName
					,@email
					,@phoneNumber
					from HC.Event e where e.id = @eventId and e.deleted = 0 and e.IsVisible <> 0


	--DECLARE @rsvpYes smallint
	--DECLARE @rsvpNo smallint
	--DECLARE @rsvpMaybe smallint
	--DECLARE @hares smallint

	--				-- TODO: We may have to join on these with HC.Event to filter deleted events out of the count

	--SELECT @rsvpYes = count(*) from HC.HasherEventMap WHERE EventId = @EventId and RsvpState = 3
	--SELECT @rsvpMaybe = count(*) from HC.HasherEventMap WHERE EventId = @EventId and RsvpState = 2
	--SELECT @rsvpNo = count(*) from HC.HasherEventMap WHERE EventId = @EventId and RsvpState = 1
	--SELECT @hares = count(*) from HC.HasherEventMap WHERE EventId = @EventId and IsHare = 1

	-- The following query below maps to the UserModel of the app
	SELECT
	@EventId as eventId
	,'00000000-0000-0000-0000-000000000000' as hasherId
	,0 as isFollowing
	,0 as isMember

	-- From HC.HasherEventMap
	,hem.id AS [hasherEventMapId]
	,coalesce(hem.[IsHare],0) as isHare
	,coalesce(hem.[VirginVisitorType],0) as virginVisitorType
	,hem.[UserStartEvent] as userStartEvent
	,hem.[UserEndEvent] as userEndEvent
	,coalesce(hem.[RsvpState],0) as rsvpState
	,coalesce(hem.[AttendenceState],0) as attendenceState

	-- From HC.Payment
	,0 as isPaid
	,-1 as paymentType  


	,coalesce(hem.DisplayName,'<no name>') AS displayName
	,CASE 
		WHEN (hem.[VirginVisitorType] = 1)	
			THEN 'bundle://avatar-virgin'
		WHEN (hem.[VirginVisitorType] = 2)	
			THEN 'bundle://avatar-visitor'
		ELSE
			'bundle://avatar-visitor'
		END AS photo

	-- Aggregates from HC.HasherEventMap
	,coalesce(CASE 
		WHEN (hem.[VirginVisitorType] <> 0)
			THEN CASE WHEN hem.AttendenceState >= 20 THEN 1 ELSE 0 END
		ELSE
			coalesce(hem.TotalRunsThisKennel,0) END,0)
		AS userRunCount


	
	-- FROM HC.Hasher (the table does not exist in this query, so we send blanks)
	,'' as eMail
	,'' as facebookId
	,'' as firstName
	,'' as hashName
	,'' as lastName
	,'' as qrCode
	,'*********' as qrSecretCode

	-- Live totals for display at top of HasherList
	,0 AS waitingForCount
	,0 AS atHashCount
	,0 AS onInCount
	,0 AS onTrailCount
	,0 AS paidCount
	,coalesce(e.EventPriceForNonMembers, k.DefaultEventPriceForNonMembers, e.EventPriceForMembers, k.DefaultEventPriceForMembers, 0) AS eventPrice
    , coalesce(e.EventCurrencyType, k.DefaultEventCurrencyType, 'en-us') as eventLocale
	, k.AllowNegativeCredit as allowNegativeCredit
	, 0 as credit
	, c.CurrencySymbol as currencySymbol
	, c.DigitsAfterDecimal as digitsAfterDecimal
	
FROM HC.HasherEventMap hem
INNER JOIN HC.Event e ON e.id = @EventId
INNER JOIN HC.Kennel k ON k.id = e.KennelId 
INNER JOIN HC.Country c on c.id = k.CountryId

WHERE hem.id = @hasherEventMapId
ORDER BY COALESCE(hem.DisplayName,'<no name>')

END

END


GO
/****** Object:  StoredProcedure [HC2].[joinKennel]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [HC2].[joinKennel]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @kennelId uniqueidentifier,
 @targetUserId uniqueidentifier,
 @isFollowing smallint = null,
 @isMember smallint = null,
 @isHomeKennel smallint = null

AS

BEGIN

	if (@isFollowing = -1) SET @isFollowing = null
	if (@isMember = -1) SET @isMember = null
	if (@isHomeKennel = -1) SET @isHomeKennel = null

-- EXEC HC.joinKennel @kennelId = '9e85d401-213d-47ad-8a6e-44e5476925f4', @userId = '624c51b3-2f64-4de5-9458-b506e75ac544', @state = '1'

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


	IF @isHomeKennel = 1 SET @isFollowing = 1
	IF @isMember = 1 SET @isFollowing = 1

	if @isFollowing = 0 OR @isFollowing = 2
	BEGIN
		if ((SELECT count(*) from HC.Hasher where id = @targetUserId and Home_KennelId = @kennelId) > 0)
		BEGIN
			UPDATE HC.Hasher SET Home_KennelId = NULL WHERE id = @targetUserId and Home_KennelId = @kennelId
		END	
	END

	IF @isHomeKennel = 1
	BEGIN
		UPDATE HC.Hasher SET Home_KennelId = @kennelId WHERE id = @targetUserId
	END

	IF NOT EXISTS(SELECT * FROM HC.HasherKennelMap WHERE UserId = @targetUserId AND KennelId = @kennelId)
		BEGIN 
			INSERT INTO HC.HasherKennelMap(UserId,KennelId,[Following],[IsMember]) VALUES (@targetUserId,@kennelId,coalesce(@isFollowing,0),coalesce(@isMember,0)) 
		END
	ELSE
		BEGIN
			UPDATE HC.HasherKennelMap SET 
				[Following] = coalesce(@isFollowing,[Following]),
				[IsMember] = coalesce(@isMember,[isMember])
				FROM HC.HasherKennelMap
				WHERE UserId=@targetUserId AND KennelId = @kennelId 
		END

	DECLARE @result int
	SELECT @result = COUNT(*) FROM HC.HasherKennelMap hkm where hkm.KennelId = @kennelId AND IsMember = 1
		
	SELECT @result as [result], 'Unused' as [message]

END





GO
/****** Object:  StoredProcedure [HC2].[payForEvent]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [HC2].[payForEvent]

@userId uniqueidentifier,
@accessToken nvarchar(1000),
@userIdWhoPaid uniqueidentifier = NULL,
@eventId uniqueidentifier,
@hasherEventMapId uniqueidentifier = NULL,
@paymentType smallint,
@paymentAmount decimal(12,6) = NULL,
@minimumAttendenceValue smallint = NULL

AS

BEGIN

-- payment type codes:
--   1 = not paid
--   2 = free run
--   3 = cash
--   4 = bank transfer
--   5 = cash (other amount)
--   6 = hash credit
--   7 = bank transfer (other amount)

-- exec HC.payForEvent @userId = '624C51B3-2F64-4DE5-9458-B506E75AC544', @hasherEventMapId = '0bc3a6ea-0e9f-432e-acb0-079c1557f004', @paymentType = 3

SET NOCOUNT ON

	DECLARE @paramString nvarchar(500)

	SET @paramString = cast(coalesce(@hasherEventMapId,'00000000-0000-0000-0000-000000000000') as nvarchar(50)) + '#' + cast(coalesce(@userIdWhoPaid,'00000000-0000-0000-0000-000000000000') as nvarchar(50)) + '#' + cast(cast(@paymentAmount as int) as nvarchar(50)) + '#' + cast(@eventId as nvarchar(50))
	--SET @paramString = ''

	IF @userId IS NULL
	BEGIN
		select 
		2 as ErrorType 
		,'No user ID provided' as ErrorTitle
		,'The API was called without a valid userId. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription
		RETURN
	END

	IF HC.CHECK_ACCESS_TOKEN(@userId,OBJECT_NAME(@@PROCID),coalesce(@accessToken,'error'),@paramString) = 0 
	BEGIN
		select 
		1 as ErrorType 
		,'Unauthorized Access Token' as ErrorTitle
		,'An invalid Access Token was received. Please go to www.harriercentral.com for support. (Function = ' + OBJECT_NAME(@@PROCID) + ')' as ErrorDescription

		RETURN
	END

	IF (@hasherEventMapId = '00000000-0000-0000-0000-000000000000') SET @hasherEventMapId = null
	IF (@userIdWhoPaid = '00000000-0000-0000-0000-000000000000') SET @userIdWhoPaid = null
	IF (@eventId = '00000000-0000-0000-0000-000000000000') SET @eventId = null
	if (@paymentAmount < 0) SET @paymentAmount = NULL
	if (@minimumAttendenceValue < 0) SET @minimumAttendenceValue = NULL

	if (@hasherEventMapId is null)
	BEGIN
		SELECT @hasherEventMapId = id FROM HC.HasherEventMap hem where hem.UserId = @userIdWhoPaid AND hem.EventId = @eventId

		IF (@hasherEventMapId is null)
		BEGIN
			SET @hasherEventMapId = newid()
			INSERT HC.HasherEventMap (id,UserId,EventId,RsvpState,Rsvp,UserStartEvent,AttendenceState) VALUES (@hasherEventMapId,@userIdWhoPaid,@eventId,3, getdate(),getdate(),coalesce(@minimumAttendenceValue,0))
		END
	END

	DECLARE @eventPrice money
	DECLARE @creditAmount money
	DECLARE @local nvarchar(10)
	DECLARE @kennelId uniqueidentifier
	DECLARE @result nvarchar(250)
	DECLARE @kennelName nvarchar(250)
	DECLARE @payer_userIdGuid uniqueidentifier
	DECLARE @paymentTypeStr nvarchar(120)
	DECLARE @payer_userName nvarchar(120)
	DECLARE @buttonState int
	DECLARE @isPaid int

	SET @isPaid = 0
	SET @result = 'Error in database function <payForEvent>'

	SET @buttonState = 0

	SELECT
	@eventPrice = CASE WHEN coalesce(hkm.IsMember,0) = 1 THEN
		coalesce(e.EventPriceForMembers,k.DefaultEventPriceForMembers,e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,0)
	ELSE
		coalesce(e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,e.EventPriceForMembers,k.DefaultEventPriceForMembers,0)
	END
	,@local = coalesce(e.EventCurrencyType,k.DefaultEventCurrencyType,'en-us')
	,@kennelId = k.id
	,@kennelName = coalesce(k.KennelShortName,k.KennelName,'<No kennel name>')
	,@payer_userIdGuid = hem.UserId
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


	SET @result = 'Payment not processed'

	if (@paymentType = 1) -- handle the 'Not paid' case
	BEGIN
		UPDATE HC.Payment SET CancelledDate = getdate(), CancelledBy_UserId = @userId WHERE CancelledDate is null AND HasherEventMapId = @hasherEventMapId
		SET @result = @payer_userName + ', your payment has been cancelled'
	END

	IF (@paymentType = 2) SET @eventPrice = 0 -- in this case the run is "free"

	IF ((@paymentType >= 2) AND (@paymentType <= 7)) -- in this case the run is paid in cash, bank transfer or using credits
	BEGIN
		IF ((@paymentType = 5) OR (@paymentType = 7))
			SET @creditAmount = @paymentAmount
		ELSE
			SET @creditAmount = @eventPrice

		IF (@paymentType = 6) SET @creditAmount = 0 -- this is the case when hashers are paying using their existing 'hash credit'
		SET @paymentTypeStr = CASE 
			WHEN @paymentType = 3 
				THEN 'cash' 
			WHEN @paymentType = 4 
				THEN 'bank transfer' 
			WHEN @paymentType = 5 
				THEN 'other amount by cash' 
			WHEN @paymentType = 6 THEN 
				'hash credit' 
			WHEN @paymentType = 7 THEN 
				'other amount by bank transfer' 
			END

		-- We only allow one payment per event, so cancel any previous payments when a new payment comes in for an event that is of type "free", "cash", "bank transfer", or "credit"
		UPDATE HC.Payment SET CancelledDate = getdate(), CancelledBy_UserId = @userId WHERE CancelledDate is null AND HasherEventMapId = @hasherEventMapId

		-- Now insert a new payment record
		INSERT HC.Payment (KennelId, UserId, EventId, HasherEventMapId, CreditAmount,DebitAmount, PaymentProcessedBy_userId,PaidDate, PaymentType, PaymentReference) 
				VALUES (@kennelId,@payer_userIdGuid,@eventId,@hasherEventMapId,@creditAmount,@eventPrice,@userId,GETDATE(),@paymentType, HC.NUMBER_TO_STR_BASE (36,(RAND() * (2147483647 - 60466177)) + 60466176))
		
		-- Set the text result
		SET @result = @payer_userName + ', your ' + @paymentTypeStr + ' payment of ' + REPLACE(REPLACE(FORMAT(@eventPrice,'C',@local),',','.'),' ','') + ' to the ' + @kennelName + ' has been recorded'
		IF @paymentType = 2 SET @result = @payer_userName + ', congratulations, your run today was free!'

		-- if they have paid, mark them as being at the event.
		UPDATE HC.HasherEventMap set UserStartEvent = getdate(), AttendenceState = CASE when AttendenceState < @minimumAttendenceValue then @minimumAttendenceValue else AttendenceState end where id = @hasherEventMapId
		SET @buttonState = 1
		SET @isPaid = 1
	END

	IF (@userIdWhoPaid IS NOT NULL)
		BEGIN
			EXEC HC.nonApi_adjustHasherRunCounts @limitByUser = 1,@userId = @userIdWhoPaid
		END
	ELSE
		BEGIN
			EXEC HC.nonApi_adjustHasherRunCounts @limitByUser = 2,@hasherEventMapId = @hasherEventMapId
		END

	DECLARE @AtHashCount smallint
	DECLARE @OnInCount smallint
	DECLARE @OnTrailCount smallint
	DECLARE @PaidCount smallint
	DECLARE @WaitingForCount smallint
	DECLARE @TotalRunsThisKennel smallint

	SELECT @TotalRunsThisKennel = hem.TotalRunsThisKennel from HC.HasherEventMap hem where hem.id = @hasherEventMapId

	-- TODO: Update these to use AttendenceState
	SELECT 
		@AtHashCount = count(hem2.UserStartEvent),
		@OnInCount = count(hem2.UserEndEvent),
		@OnTrailCount = count(hem2.UserStartEvent)-count(hem2.UserEndEvent) 
	FROM HC.HasherEventMap hem2 WHERE hem2.EventId = @EventId

	SELECT 
		@WaitingForCount = count(*)
	FROM HC.HasherEventMap hem WHERE hem.EventId = @EventId AND hem.UserStartEvent IS NULL AND hem.RsvpState = 3

	SELECT @PaidCount = count(*) from HC.Payment p where p.EventId = @EventId and p.CancelledDate is null

	SELECT 
		@result as [result], 
		@WaitingForCount as waitingForCount, 
		@AtHashCount as atHashCount, 
		@OnInCount as onInCount, 
		@OnTrailCount as onTrailCount, 
		@PaidCount as paidCount, 
		@buttonState as buttonState, 
		@TotalRunsThisKennel as totalRunsThisKennel, 
		@isPaid as isPaid,
		@hasherEventMapId as hasherEventMapId

END
GO
/****** Object:  StoredProcedure [HC2].[processQrScan]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [HC2].[processQrScan]

@userId nvarchar(120), -- this is the userId of the person who is doing the scanning, not the user being scanned
@accessToken nvarchar(1000),
@eventId nvarchar(120) = NULL,
@scanText nvarchar(500),
@context1 nvarchar(120),
@context2 nvarchar(120) = NULL,
@param1 nvarchar(120) = NULL,
@param2 nvarchar(120) = NULL

AS
BEGIN

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

	-- TODO: Replace checks on startDate and endDate with checks on AttendenceState

DECLARE @result nvarchar(500)
DECLARE @result2 nvarchar(500)
DECLARE @result3 nvarchar(500)
DECLARE @resultGuid1 uniqueidentifier
DECLARE @resultGuid2 uniqueidentifier
DECLARE @resultInt1 int
DECLARE @resultInt2 int
DECLARE @resultInt3 int
DECLARE @resultInt4 int
DECLARE @resultDecimal1 decimal
DECLARE @resultDecimal2 decimal
DECLARE @paramValue uniqueidentifier
DECLARE @userIdGuid uniqueidentifier
DECLARE @eventIdGuid uniqueidentifier
DECLARE @scanTextGuid uniqueidentifier
DECLARE @paymentCounter smallint
DECLARE @startTime datetime
DECLARE @endTime datetime
DECLARE @hasherEventMapId uniqueidentifier
DECLARE @startEvent datetime

DECLARE @runName nvarchar(500)


--IF (((@scanText like 'evtStart%') AND (@context1 = 'User')) OR ((@userId like 'uid%') AND (@context1 = '0')))
IF ((@context1 = 'CheckInOut') AND (@scanText like 'UQR:%')) -- this is the case where the user is checking in
BEGIN
	-- Context values
	-- @Context2 = 0 indicates run start
	-- @Context2 = 1 indicates run end

	-- Param values
	-- @param1 = 'user' means the user is scanning themselves
	-- @param1 = 'admin' means an admin is scanning a user
	
	-- Result values
	-- @Result1 contains the currency symbol
	-- @Result2 contains instructions for payment
	-- @Result3 contains the user name
	-- @Result4 contains the number of digits after the decimal for currencies
	-- @ResultInt1 contains the number of runs for this particular kennel for the target user
	-- @ResultInt2 contains the payment counter
	-- @ResultInt3 contains 0 if credit is not allowed or 1 if credit is allowed
	-- @ResultGuid1 contains the target user id
	-- @ResultGuid2 contains the HasherEventMapId
	-- @ResultDecimal1 contains the run price
	-- @ResultDecimal2 contains the outstanding credit or debit


	-- exec HC.processQrScan @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @eventId = 'dea28bab-a30c-4a80-ac96-d0b7164551b9', @scanText = 'UQR:TEST01', @context1 = 'CheckInOut', @context2 = '0', @param1 = '', @param2 = ''


	SET @userIdGuid = CAST(right(@userId,36) AS uniqueidentifier)
	SET @eventIdGuid = CAST(right(@eventId,36) AS uniqueidentifier)
	SET @hasherEventMapId = newid()
	SET @startTime = getdate()
	if (@context2 <> '0') SET @endTime = getdate()
	SET @resultInt1 = -1
	SET @resultInt2 = -1
	SET @resultInt3 = -1
	SET @resultInt4 = -1
	SET @resultDecimal1 = -99999
	SET @resultDecimal2 = -99999

	DECLARE @attendenceState int
	SET @attendenceState = 20 -- this is the code for 'at the Hash'
	IF @context2 != 0
	BEGIN
		SET @attendenceState = 30 -- this corresponds to 'on in'
	END

	--SET @scanTextGuid = CAST(right(@scanText,36) AS uniqueidentifier) -- the QR id of the hasher being checked in
	DECLARE @targetUserId uniqueidentifier
	SELECT @targetUserId = id,
			@result3 = coalesce(h.HashName, h.DisplayName, h.FirstName + ' ' + h.LastName,'no name')
		from HC.Hasher h 
		where h.QR_code = @scanText

	IF (@targetUserId is null)
		BEGIN
			SET @result = 'User code not found in Harrier Central database'
		END
	ELSE


		BEGIN
		SELECT @paymentCounter = coalesce(count(*),0) from HC.Payment p WHERE p.UserId = @targetUserId AND p.EventId = @eventIdGuid AND p.CancelledDate IS NULL
		SET @resultInt2 = @paymentCounter

		IF NOT EXISTS(SELECT * FROM HC.HasherEventMap WHERE UserId = @targetUserId AND EventId = @eventIdGuid)
			-- this case is for someone who is on the run but did not RSVP, so there is no record in HEM
			BEGIN 
				INSERT INTO HC.HasherEventMap(id,UserId,EventId,RsvpState,Rsvp,AttendenceState,UserStartEvent, UserEndEvent) VALUES (@hasherEventMapId,@targetUserId,@eventIdGuid,3,getdate(),@attendenceState,@startTime, @endTime) 
				IF @paymentCounter = 0 SET @result2 = case when @param1 = 'user' then 'You have been checked in. Please pay for today''s Hash.' else @result3 + ' has been checked in, but needs to pay for the Hash' end
				IF @paymentCounter <> 0 SET @result2 = case when @param1 = 'user' then 'You have already paid. Enjoy the Hash!' else @result3 + ' has checked in and paid.' end
			END
		ELSE
			BEGIN
				-- This case is when a HEM record already exists
				SELECT @hasherEventMapId = id, @startEvent = UserStartEvent from HC.HasherEventMap WHERE UserId = @targetUserId AND EventId = @eventIdGuid
				IF (@startEvent is not null)
					BEGIN
						if (@context2 = '0')
						BEGIN
							-- This executes when someone has already checked in and is checking in again.
							IF @paymentCounter = 0 SET @result2 = case when @param1 = 'user' then 'You are already checked in. Please pay for today''s Hash.' else @result3 + ' is already checked in, but needs to pay for the Hash' end
							IF @paymentCounter <> 0 SET @result2 = case when @param1 = 'user' then 'You are already checked in and paid. Enjoy the Hash!' else @result3 + ' has checked in and paid.' end
						END

						if (@context2 <> '0')
						BEGIN
							UPDATE HC.HasherEventMap SET UserEndEvent = @endTime WHERE id = @hasherEventMapId 
							-- This executes when someone has already checked in and is checking in again.
							IF @paymentCounter = 0 SET @result2 = 'You are recorded as "On In". Please don''t forget to pay for the Hash.'
							IF @paymentCounter <> 0 SET @result2 = 'You are recorded as "On In". Hope you enjoyed the Hash!'
						END
					END
				ELSE
					BEGIN

						IF (@context2 = '0')
						BEGIN
							-- This case is when someone has RSVP'ed but not yet checked in
							UPDATE HC.HasherEventMap SET RsvpState = 3, AttendenceState = 20, UserStartEvent = getdate() WHERE id = @hasherEventMapId 
							IF @paymentCounter = 0 SET @result2 = case when @param1 = 'user' then 'You are now checked in. Please pay for today''s Hash.' else @result3 + ' has been checked in, but needs to pay for the Hash' end
							IF @paymentCounter <> 0 SET @result2 = case when @param1 = 'user' then 'You are now checked in and paid. Enjoy the Hash!' else @result3 + ' has checked in and paid.' end
						END

						IF (@context2 <> '0')
						BEGIN
							-- This case is when someone has gone on the run without checking in, but they have checked in at the end
							UPDATE HC.HasherEventMap SET RsvpState = 3, AttendenceState = 30, UserStartEvent = @startTime, UserEndEvent = @endTime WHERE id = @hasherEventMapId 
							IF @paymentCounter = 0 SET @result2 = 'You are recorded as "On In". Please don''t forget to pay for the Hash.'
							IF @paymentCounter <> 0 SET @result2 = 'You are recorded as "On In". Hope you enjoyed the Hash!'
						END
					END
			END

		END

		EXEC HC.nonApi_adjustHasherRunCounts @limitByUser = 1, @userId = @targetUserId

		DECLARE @remainingCreditStr nvarchar(20)
		DECLARE @eventPriceStr nvarchar(20)	
		DECLARE @local nvarchar(20)
		DECLARE @remainingCredit money
		DECLARE @eventPrice money
		DECLARE @creditStatusStr nvarchar(20)

		SELECT @resultInt1 = hem.TotalRunsThisKennel from HC.HasherEventMap hem where hem.id = @hasherEventMapId

		IF (@paymentCounter = 0)
		BEGIN
			SELECT
			@eventPrice = CASE WHEN hkm.IsMember = 1 THEN
				coalesce(e.EventPriceForMembers,k.DefaultEventPriceForMembers,e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,0)
			ELSE
				coalesce(e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,e.EventPriceForMembers,k.DefaultEventPriceForMembers,0)
			END
			,@result = coalesce(cn.CurrencySymbol,'xxx') -- TODO: Optimize this by de-normalizing the currency symbol down to Kennel and Event
			,@resultInt3 = k.AllowNegativeCredit
			,@resultInt4 = cn.DigitsAfterDecimal
			FROM HC.Event e
			INNER JOIN HC.Kennel k on k.id = e.KennelId
			INNER JOIN HC.Country cn on cn.id = k.CountryId
			INNER JOIN HC.HasherKennelMap hkm on hkm.UserId = @targetUserId and hkm.KennelId = e.KennelId
			WHERE e.id = @eventIdGuid --AND e.deleted = 0 AND e.IsVisible <> 0

			SET @resultDecimal1 = @eventPrice

			SELECT @remainingCredit = coalesce(sum(creditAmount)-sum(debitAmount),0)
			FROM HC.Payment p 
			INNER JOIN HC.Event e on p.KennelId = e.KennelId
			WHERE p.UserId = @targetUserId AND e.id = @eventIdGuid AND p.CancelledDate is null --AND e.deleted = 0 AND e.IsVisible <> 0

			SET @resultDecimal2 = @remainingCredit

		END

		SET @resultGuid2 = @hasherEventMapId
	

END


--IF (((@scanText like 'evtStart%') AND (@context1 = 'User')) OR ((@userId like 'uid%') AND (@context1 = '0')))
ELSE IF ((@context1 = 'UserScan') AND (@scanText like 'evtStart:%')) -- this is the case where the user is checking in
	BEGIN

	-- exec HC.processQrScan @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @eventId = '', @scanText = 'evtStart:7B10155A-92D4-40D7-929A-CF2BDE968444', @context1 = 'UserScan', @context2 = '', @param1 = '', @param2 = ''
	
	SET @userIdGuid = CAST(right(@userId,36) AS uniqueidentifier)
	SET @eventIdGuid = CAST(right(@scanText,36) AS uniqueidentifier)

	SELECT @runName = e.EventName from HC.Event e where e.id = @eventIdGuid

	IF NOT EXISTS(SELECT * FROM HC.HasherEventMap WHERE UserId = @userIdGuid AND EventId = @eventIdGuid)
		BEGIN 
			INSERT INTO HC.HasherEventMap(UserId,EventId,RsvpState,Rsvp, AttendenceState, UserStartEvent) VALUES (@userIdGuid,@eventIdGuid,3,getdate(),20,getdate()) 
			SET @result = 'Checked in for "'+@runName+'". Enjoy your run!'
		END
	ELSE
			IF EXISTS(SELECT * FROM HC.HasherEventMap WHERE UserId = @userIdGuid AND EventId = @eventIdGuid AND UserStartEvent IS NOT NULL)
			SET @result = 'You are already checked in for "'+@runName+'". Enjoy your run!'
		ELSE
			BEGIN
				UPDATE HC.HasherEventMap SET RsvpState = 3, AttendenceState = 20, UserStartEvent = coalesce(UserStartEvent,getdate()) WHERE UserId = @userIdGuid and EventId = @eventIdGuid
				SET @result = 'Checked in for "'+@runName+'". Enjoy your run!'
			END

	END

ELSE IF ((@context1 = 'UserScan') AND (@scanText like 'evtEnd:%')) -- this is the case where the user is checking in at the end of the run
	BEGIN

	-- exec HC.processQrScan @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @eventId = '', @scanText = 'evtEnd:7B10155A-92D4-40D7-929A-CF2BDE968444', @context1 = 'UserScan', @context2 = '', @param1 = '', @param2 = ''
	
	SET @userIdGuid = CAST(right(@userId,36) AS uniqueidentifier)
	SET @eventIdGuid = CAST(right(@scanText,36) AS uniqueidentifier)

	SELECT @runName = e.EventName from HC.Event e where e.id = @eventIdGuid

	
	IF NOT EXISTS(SELECT * FROM HC.HasherEventMap WHERE UserId = @userIdGuid AND EventId = @eventIdGuid)
		BEGIN 
			INSERT INTO HC.HasherEventMap(UserId,EventId,RsvpState,Rsvp,AttendenceState,UserStartEvent,UserEndEvent) VALUES (@userIdGuid,@eventIdGuid,3,getdate(),30,getdate(),getdate()) 
			SET @result = 'Congratulations for finishing "'+@runName+'". Enjoy your beer!'
		END
	ELSE
			IF EXISTS(SELECT * FROM HC.HasherEventMap WHERE UserId = @userIdGuid AND EventId = @eventIdGuid AND UserStartEvent IS NOT NULL AND UserEndEvent IS NOT NULL)
			SET @result = 'You are already checked in as finished. Enjoy your beer!'
		ELSE
			BEGIN
				UPDATE HC.HasherEventMap SET RsvpState = 3, AttendenceState = 30, UserStartEvent = coalesce(UserStartEvent,getdate()), UserEndEvent = coalesce(UserEndEvent,getdate()) WHERE UserId = @userIdGuid and EventId = @eventIdGuid
				SET @result = 'Congratulations for finishing "'+@runName+'". Enjoy your beer!'
			END

	END

ELSE IF ((@context1 = 'UserScan') AND (@scanText like 'uqr:%')) -- this is the case where the user is checking in at the end of the run
	BEGIN

	-- exec HC.processQrScan @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @eventId = '', @scanText = 'uqr:A703DA6E-35D9-4BBC-B74B-C3AE270F16FC', @context1 = 'UserScan', @context2 = '', @param1 = '', @param2 = ''
	DECLARE @friendQrCode uniqueidentifier
	DECLARE @friendIdGuid uniqueidentifier
	DECLARE @friendName nvarchar(120)

	SET @userIdGuid = CAST(right(@userId,36) AS uniqueidentifier)
	--SET @friendQrCode = CAST(right(@scanText,36) AS uniqueidentifier)

	SELECT @friendIdGuid = id, @friendName = DisplayName from HC.Hasher h where h.QR_code = @scanText

	IF (@friendIdGuid IS NULL)
		BEGIN
			SET @result = 'QR code not recognized'
		END
	ELSE IF (@friendIdGuid = @userIdGuid)
		SET @result = 'How nice of you to want to be your own friend!'
	ELSE
		BEGIN


			IF NOT EXISTS(SELECT * FROM HC.HasherFriendMap WHERE UserId = @userIdGuid AND Friend_UserId = @friendIdGuid)
				BEGIN 
					INSERT INTO HC.HasherFriendMap(UserId,Friend_UserId,FriendSince,Ignore) VALUES (@userIdGuid,@friendIdGuid,getdate(),0) 
					SET @result = @friendName + ' has been added to your friend list'
				END
			ELSE
				IF EXISTS(SELECT * FROM HC.HasherFriendMap WHERE UserId = @userIdGuid AND Friend_UserId = @friendIdGuid AND Ignore = 0)
					SET @result = @friendName + ' is already in your friend list'
				ELSE
					BEGIN
						UPDATE HC.HasherFriendMap SET Ignore = 0 WHERE UserId = @userIdGuid AND Friend_UserId = @friendIdGuid
						SET @result = @friendName + ' has been added to your friend list'
					END

			END
		END

ELSE
BEGIN
	SET @result = 'Scanned code not recognized'
END

select	coalesce(@result,'') as [resultStr1], 
		coalesce(@result2,'') as [resultStr2], 
		coalesce(@result3,'') as [resultStr3], 
		coalesce(@targetUserId,'00000000-0000-0000-0000-000000000000') as resultGuid1, 
		coalesce(@resultGuid2,'00000000-0000-0000-0000-000000000000') as [resultGuid2], 
		coalesce(@resultInt1,-1) as [resultInt1], 
		coalesce(@resultInt2,-1) as [resultInt2],
		coalesce(@resultInt3,-1) as [resultInt3],
		coalesce(@resultInt4,-1) as [resultInt4],
		coalesce(@resultDecimal1,-9999999) as [resultDecimal1],
		coalesce(@resultDecimal2,-9999999) as [resultDecimal2]

END



GO
/****** Object:  StoredProcedure [HC2].[processQrScanForCheckin]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [HC2].[processQrScanForCheckin]

@userId nvarchar(120), -- this is the userId of the person who is doing the scanning, not the user being scanned
@accessToken nvarchar(1000),
@eventId nvarchar(120) = NULL,
@scanText nvarchar(500),
@runStartOrEnd smallint = NULL,
@selfScan smallint = NULL

AS
BEGIN

SET @runStartOrEnd = coalesce(@runStartOrEnd,0)

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

	-- TODO: Replace checks on startDate and endDate with checks on AttendenceState

DECLARE @resultStr nvarchar(500)
DECLARE @result int
DECLARE @currencySymbol nvarchar(25)
DECLARE @paymentInstructions nvarchar(500)
DECLARE @scannedUserName nvarchar(500)
DECLARE @hasherEventMapId uniqueidentifier
DECLARE @isPaid smallint
DECLARE @paymentType smallint
DECLARE @isCreditAllowed int
DECLARE @currencyDigitsAfterDecimal int
DECLARE @runPriceThisUser decimal
DECLARE @remainingCredit decimal
DECLARE @paramValue uniqueidentifier
DECLARE @userIdGuid uniqueidentifier
DECLARE @eventIdGuid uniqueidentifier
DECLARE @scanTextGuid uniqueidentifier
DECLARE @startTime datetime
DECLARE @endTime datetime
DECLARE @startEvent datetime

DECLARE @runName nvarchar(500)


--IF (((@scanText like 'evtStart%') AND (@checkInOrOut = 'User')) OR ((@userId like 'uid%') AND (@checkInOrOut = '0')))
IF (@scanText not like 'UQR:%') -- this is the case where the user is checking in
BEGIN
	SET @result = 0
	SET @resultStr = 'QR code has an unknown format'
END
ELSE
BEGIN
	-- Context values
	-- @runStartOrEnd = 0 indicates run start
	-- @runStartOrEnd = 1 indicates run end

	-- Param values
	-- @selfScan = '1' means the user is scanning themselves
	-- @selfScan = '0' means an admin is scanning another user
	
	-- Result values
	-- @Result1 contains the currency symbol
	-- @paymentInstructions contains instructions for payment
	-- @scannedUserName contains the user name
	-- @Result4 contains the number of digits after the decimal for currencies
	-- @isCreditAllowed contains 0 if credit is not allowed or 1 if credit is allowed
	-- @ResultGuid1 contains the target user id
	-- @hasherEventMapId contains the HasherEventMapId
	-- @runPriceThisUser contains the run price
	-- @remainingCredit contains the outstanding credit or debit


	-- exec HC.processQrScan @userId ='624c51b3-2f64-4de5-9458-b506e75ac544', @eventId = 'dea28bab-a30c-4a80-ac96-d0b7164551b9', @scanText = 'UQR:TEST01', @checkInOrOut = 'CheckInOut', @runStartOrEnd = '0', @selfScan = '', @param2 = ''

	SET @result = 0
	SET @resultStr = 'Scanned code not recognized'

	SET @userIdGuid = CAST(right(@userId,36) AS uniqueidentifier)
	SET @eventIdGuid = CAST(right(@eventId,36) AS uniqueidentifier)
	SET @hasherEventMapId = newid()
	SET @startTime = getdate()
	if (@runStartOrEnd <> 0) SET @endTime = getdate()
	SET @isPaid = 0
	SET @paymentType = -1
	SET @isCreditAllowed = -1
	SET @currencyDigitsAfterDecimal = -1
	SET @runPriceThisUser = -99999
	SET @remainingCredit = -99999

	DECLARE @attendenceState int
	SET @attendenceState = 20 -- this is the code for 'at the Hash'
	IF @runStartOrEnd != 0
	BEGIN
		SET @attendenceState = 30 -- this corresponds to 'on in'
	END

	--SET @scanTextGuid = CAST(right(@scanText,36) AS uniqueidentifier) -- the QR id of the hasher being checked in
	DECLARE @targetUserId uniqueidentifier
	SELECT @targetUserId = id,
			@scannedUserName = coalesce(h.HashName, h.DisplayName, h.FirstName + ' ' + h.LastName,'no name')
		from HC.Hasher h 
		where h.QR_code = @scanText

	IF (@targetUserId is null)
		BEGIN
			SET @result = 'User code not found in Harrier Central database'
		END
	ELSE


		BEGIN

		SET @result = 1

		SELECT top 1 @isPaid = 1, @paymentType = p.PaymentType from HC.Payment p WHERE p.UserId = @targetUserId AND p.EventId = @eventIdGuid AND p.CancelledDate IS NULL order by p.PaidDate desc
		
		IF NOT EXISTS(SELECT * FROM HC.HasherEventMap WHERE UserId = @targetUserId AND EventId = @eventIdGuid)
			-- this case is for someone who is on the run but did not RSVP, so there is no record in HEM
			BEGIN 
				INSERT INTO HC.HasherEventMap(id,UserId,EventId,RsvpState,Rsvp,AttendenceState,UserStartEvent, UserEndEvent) VALUES (@hasherEventMapId,@targetUserId,@eventIdGuid,3,getdate(),@attendenceState,@startTime, @endTime) 
				IF @isPaid = 0 SET @paymentInstructions = case when @selfScan = 1 then 'You have been checked in. Please pay for today''s Hash.' else @scannedUserName + ' has been checked in, but needs to pay for the Hash' end
				IF @isPaid <> 0 SET @paymentInstructions = case when @selfScan = 1 then 'You have already paid. Enjoy the Hash!' else @scannedUserName + ' has checked in and paid.' end
			END
		ELSE
			BEGIN
				-- This case is when a HEM record already exists
				SELECT @hasherEventMapId = id, @startEvent = UserStartEvent from HC.HasherEventMap WHERE UserId = @targetUserId AND EventId = @eventIdGuid
				IF (@startEvent is not null)
					BEGIN
						if (@runStartOrEnd = 0)
						BEGIN
							-- This executes when someone has already checked in and is checking in again.
							IF @isPaid = 0 SET @paymentInstructions = case when @selfScan = 1 then 'You are already checked in. Please pay for today''s Hash.' else @scannedUserName + ' is already checked in, but needs to pay for the Hash' end
							IF @isPaid <> 0 SET @paymentInstructions = case when @selfScan = 1 then 'You are already checked in and paid. Enjoy the Hash!' else @scannedUserName + ' has checked in and paid.' end
						END

						if (@runStartOrEnd <> 0)
						BEGIN
							UPDATE HC.HasherEventMap SET UserEndEvent = @endTime WHERE id = @hasherEventMapId 
							-- This executes when someone has already checked in and is checking in again.
							IF @isPaid = 0 SET @paymentInstructions = 'You are recorded as "On In". Please don''t forget to pay for the Hash.'
							IF @isPaid <> 0 SET @paymentInstructions = 'You are recorded as "On In". Hope you enjoyed the Hash!'
						END
					END
				ELSE
					BEGIN

						IF (@runStartOrEnd = 0)
						BEGIN
							-- This case is when someone has RSVP'ed but not yet checked in
							UPDATE HC.HasherEventMap SET RsvpState = 3, AttendenceState = 20, UserStartEvent = getdate() WHERE id = @hasherEventMapId 
							IF @isPaid = 0 SET @paymentInstructions = case when @selfScan = 1 then 'You are now checked in. Please pay for today''s Hash.' else @scannedUserName + ' has been checked in, but needs to pay for the Hash' end
							IF @isPaid <> 0 SET @paymentInstructions = case when @selfScan = 1 then 'You are now checked in and paid. Enjoy the Hash!' else @scannedUserName + ' has checked in and paid.' end
						END

						IF (@runStartOrEnd <> 0)
						BEGIN
							-- This case is when someone has gone on the run without checking in, but they have checked in at the end
							UPDATE HC.HasherEventMap SET RsvpState = 3, AttendenceState = 30, UserStartEvent = @startTime, UserEndEvent = @endTime WHERE id = @hasherEventMapId 
							IF @isPaid = 0 SET @paymentInstructions = 'You are recorded as "On In". Please don''t forget to pay for the Hash.'
							IF @isPaid <> 0 SET @paymentInstructions = 'You are recorded as "On In". Hope you enjoyed the Hash!'
						END
					END
			END

		END

		EXEC HC.nonApi_adjustHasherRunCounts @limitByUser = 1, @userId = @targetUserId

		DECLARE @remainingCreditStr nvarchar(20)
		DECLARE @eventPriceStr nvarchar(20)	
		DECLARE @local nvarchar(20)
		DECLARE @eventPrice money
		DECLARE @creditStatusStr nvarchar(20)

		IF (@isPaid = 0)
		BEGIN
			SELECT
			@eventPrice = CASE WHEN hkm.IsMember = 1 THEN
				coalesce(e.EventPriceForMembers,k.DefaultEventPriceForMembers,e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,0)
			ELSE
				coalesce(e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,e.EventPriceForMembers,k.DefaultEventPriceForMembers,0)
			END
			,@currencySymbol = coalesce(cn.CurrencySymbol,'xxx') -- TODO: Optimize this by de-normalizing the currency symbol down to Kennel and Event
			,@isCreditAllowed = k.AllowNegativeCredit
			,@currencyDigitsAfterDecimal = cn.DigitsAfterDecimal
			FROM HC.Event e
			INNER JOIN HC.Kennel k on k.id = e.KennelId
			INNER JOIN HC.Country cn on cn.id = k.CountryId
			INNER JOIN HC.HasherKennelMap hkm on hkm.UserId = @targetUserId and hkm.KennelId = e.KennelId
			WHERE e.id = @eventIdGuid --AND e.deleted = 0 AND e.IsVisible <> 0

			SET @runPriceThisUser = @eventPrice

			SELECT @remainingCredit = coalesce(sum(creditAmount)-sum(debitAmount),0)
			FROM HC.Payment p 
			INNER JOIN HC.Event e on p.KennelId = e.KennelId
			WHERE p.UserId = @targetUserId AND e.id = @eventIdGuid AND p.CancelledDate is null --AND e.deleted = 0 AND e.IsVisible <> 0

			SET @remainingCredit = @remainingCredit

		END

		SET @hasherEventMapId = @hasherEventMapId
	

END


select	coalesce(@result,0) as result, 
		coalesce(@resultStr,'Unknown error processing QR code') as resultStr,
		coalesce(@currencySymbol,'') as currencySymbol,
		coalesce(@paymentInstructions,'') as paymentInstructions, 
		coalesce(@scannedUserName,'') as scannedUserName, 
		coalesce(@targetUserId,'00000000-0000-0000-0000-000000000000') as targetUserId, 
		coalesce(@hasherEventMapId,'00000000-0000-0000-0000-000000000000') as hasherEventMapId, 
		coalesce(@isPaid,0) as isPaid,
		coalesce(@paymentType,-1) as paymentType,
		coalesce(@isCreditAllowed,-1) as isCreditAllowed,
		coalesce(@currencyDigitsAfterDecimal,-1) as currencyDigitsAfterDecimal,
		coalesce(@runPriceThisUser,-9999999) as runPriceThisUser,
		coalesce(@remainingCredit,-9999999) as remainingCredit,
		coalesce(hem.TotalRunsThisKennel,0) as userRunCountThisKennel, 
		h.Photo as photo,
		hem.AttendenceState as attendenceState,
		hem.RsvpState as rsvpState,
		hem.IsHare as isHare,
		hem.VirginVisitorType as virginVisitorType,
		hem.UserStartEvent as userStartEvent,
		hem.UserEndEvent as userEndEvent,
		hkm.IsMember as isMember,
		hkm.Following as isFollowing,
		coalesce(k.AllowNegativeCredit,0) as allowNegativeCredit
		
		FROM HC.HasherEventMap hem 
		INNER JOIN HC.Hasher h on h.id = hem.UserId
		INNER JOIN HC.Event evt on evt.id = hem.EventId
		INNER JOIN HC.HasherKennelMap hkm on hkm.KennelId = evt.KennelId and hkm.UserId = h.id
		INNER JOIN HC.Kennel k on k.id = evt.KennelId
		WHERE hem.id = @hasherEventMapId
		

END



GO
/****** Object:  StoredProcedure [HC2].[updateAvatar]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [HC2].[updateAvatar]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @avatarUrl nvarchar(1000),
 @avatarUserId uniqueidentifier

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
SET @result = 'User not found'

IF EXISTS(SELECT * FROM HC.Hasher WHERE id = @avatarUserId)
BEGIN 
	UPDATE HC.Hasher set Photo = @avatarUrl FROM HC.Hasher h where h.id = @avatarUserId
	SET @result = 'Success'
END

SELECT @result as result

END





GO
/****** Object:  StoredProcedure [HC3].[getCitiesMd]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC3].[getCitiesMd]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @updatedAfter nvarchar(50)

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


	DECLARE @ua datetime
	SET @ua = CAST(@updatedAfter as datetime)

	SELECT 
		c.id as cityId
      ,[CityName] as cityName
      ,[RegionId] as regionId
      ,[Latitude] as latitude
      ,[Longitude] as longitude
      ,[City_ASCII] as cityAscii
      ,[FlagFile] as flagFile
	  ,[Removed] as removed
      ,[updatedAt] as updatedAt
	FROM HC.City c where updatedAt > @ua
END





GO
/****** Object:  StoredProcedure [HC3].[getCountriesMd]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC3].[getCountriesMd]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @updatedAfter nvarchar(50)

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


	DECLARE @ua datetime
	SET @ua = CAST(@updatedAfter as datetime)

	SELECT 
	  [id] as countryId
      ,[CountryCode] as countryCode
      ,[Latitude] as latitude
      ,[Longitude] as longitude
      ,[CountryName] as countryName
      ,[ContinentCode] as continentCode
      ,[FlagFile] as flagFile
      ,[CurrencyCode] as currencyCode
      ,[PrimaryCultureCode] as primaryCultureCode
      ,[ShowRegion] as showRegion
      ,[CurrencySymbol] as currencySymbol
      ,[DigitsAfterDecimal] as digitsAfterDecimal
	  ,[Removed] as removed
      ,[updatedAt] as updatedAt
	FROM HC.Country where updatedAt > @ua
END





GO
/****** Object:  StoredProcedure [HC3].[getKennelsMd]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC3].[getKennelsMd]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @updatedAfter nvarchar(50)

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


	DECLARE @ua datetime
	SET @ua = CAST(@updatedAfter as datetime)


SELECT 
	  -- GUIDs
	   [id] as kennelId
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
      ,[DefaultEventCurrencyType] as defaultEventCurrencyType

	  -- Ints / Smallints
      ,[KennelStatus] as kennelStatus
	  ,[AllowNegativeCredit] as allowNegativeCredit

	  -- Doubles
      ,[Latitude] as latitude
      ,[Longitude] as longitude
	  ,[DefaultEventPriceForMembers] as defaultPriceForMembers
      ,[DefaultEventPriceForNonMembers] as defaultPriceForNonMembers

	  -- DateTimes
      ,[DefaultRunStartTime] as defaultRunStartTime

	  ,[removed] as removed
      ,[updatedAt]

	  --,[KennelFacebookId]
   --   ,[KennelFacebookToken]
   --   ,[KennelFacebookTokenUserId]
   --   ,[KennelFacebookTokenLastUpdated]
   --   ,[KennelFacebookImportDaysInPast]
   --   ,[KennelFacebookImportDaysInFuture]
   --   ,[AutoImportFacebookEvents]
	  --,[ImportOnlyTaggedEvents]
	  --,[CanEditRunAttendence]
	  --,[FacebookTagForImport]
	  --,[DefaultCity]
   --   ,[DefaultCountry]
   --   ,[DefaultCitiesList]
   --   ,[DefaultCountriesList]
	  --,[KennelGeolocation]
	  --,[deleted]
	  --,[version]
   --   ,[createdAt]

  FROM [HC].[Kennel] where updatedAt > @ua


END





GO
/****** Object:  StoredProcedure [HC3].[getRegionsMd]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC3].[getRegionsMd]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @updatedAfter nvarchar(50)

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


	DECLARE @ua datetime
	SET @ua = CAST(@updatedAfter as datetime)


	SELECT 
		[id] as regionId
      ,[RegionName] as regionName
      ,[CountryId] as countryId
      ,[FlagFile] as flagFile
	  ,[Removed] as removed
      ,[updatedAt] as updatedAt
	FROM HC.Region where updatedAt > @ua


END





GO
/****** Object:  StoredProcedure [HC3].[syncMasterData]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC3].[syncMasterData]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @citiesUpdatedAfter nvarchar(50),
 @regionsUpdatedAfter nvarchar(50),
 @countriesUpdatedAfter nvarchar(50),
 @kennelsUpdatedAfter nvarchar(50)

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

	DECLARE @ua datetime
	SET @ua = CAST(@citiesUpdatedAfter as datetime)

	SELECT 
		c.id as cityId
      ,[CityName] as cityName
      ,[RegionId] as regionId
      ,[Latitude] as latitude
      ,[Longitude] as longitude
      ,[City_ASCII] as cityAscii
      ,[FlagFile] as flagFile
	  ,[Removed] as removed
      ,[updatedAt] as updatedAt
	FROM HC.City c where updatedAt > @ua

	SET @ua = CAST(@regionsUpdatedAfter as datetime)

	SELECT 
		[id] as regionId
      ,[RegionName] as regionName
      ,[CountryId] as countryId
      ,[FlagFile] as flagFile
	  ,[Removed] as removed
      ,[updatedAt] as updatedAt
	FROM HC.Region where updatedAt > @ua

	SET @ua = CAST(@countriesUpdatedAfter as datetime)

	SELECT 
	  [id] as countryId
      ,[CountryCode] as countryCode
      ,[Latitude] as latitude
      ,[Longitude] as longitude
      ,[CountryName] as countryName
      ,[ContinentCode] as continentCode
      ,[FlagFile] as flagFile
      ,[CurrencyCode] as currencyCode
      ,[PrimaryCultureCode] as primaryCultureCode
      ,[ShowRegion] as showRegion
      ,[CurrencySymbol] as currencySymbol
      ,[DigitsAfterDecimal] as digitsAfterDecimal
	  ,[Removed] as removed
      ,[updatedAt] as updatedAt
	FROM HC.Country where updatedAt > @ua

	SET @ua = CAST(@kennelsUpdatedAfter as datetime)

	SELECT
	   -- GUIDs
	   [id] as kennelId
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
      ,[DefaultEventCurrencyType] as defaultEventCurrencyType

	  -- Ints / Smallints
      ,[KennelStatus] as kennelStatus
	  ,[AllowNegativeCredit] as allowNegativeCredit

	  -- Doubles
      ,[Latitude] as latitude
      ,[Longitude] as longitude
	  ,[DefaultEventPriceForMembers] as defaultPriceForMembers
      ,[DefaultEventPriceForNonMembers] as defaultPriceForNonMembers

	  -- DateTimes
      ,[DefaultRunStartTime] as defaultRunStartTime

	  ,[removed] as removed
      ,[updatedAt]

  FROM [HC].[Kennel] where updatedAt > @ua

END





GO
/****** Object:  Trigger [dbo].[TR_Hasher_InsertUpdateDelete]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TR_Hasher_InsertUpdateDelete] ON [dbo].[Hasher] AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON; IF TRIGGER_NESTLEVEL() > 3 RETURN; UPDATE [dbo].[Hasher] SET [updatedAt] = CONVERT (DATETIMEOFFSET(7), SYSUTCDATETIME()) FROM INSERTED WHERE INSERTED.id = [dbo].[Hasher].[id] END
GO
ALTER TABLE [dbo].[Hasher] ENABLE TRIGGER [TR_Hasher_InsertUpdateDelete]
GO
/****** Object:  Trigger [dbo].[trgLoadFacebookEvents]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE TRIGGER [dbo].[trgLoadFacebookEvents]
   ON  [dbo].[unused_FacebookEventImport]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC HC.loadEvents

END
GO
ALTER TABLE [dbo].[unused_FacebookEventImport] DISABLE TRIGGER [trgLoadFacebookEvents]
GO
/****** Object:  Trigger [dbo].[trgCreateHasherRecord]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE TRIGGER [dbo].[trgCreateHasherRecord]
   ON  [dbo].[Users]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN

	SET NOCOUNT ON;

	INSERT Hashers.Hasher (UserId, DisplayName,Photo)
		SELECT u.UserId,u.DisplayName,u.UserImage
		FROM dbo.Users u 
		LEFT OUTER JOIN Hashers.Hasher h 
		ON u.UserId = h.UserId 
		WHERE h.UserId is null

	INSERT dbo.UserRoles (UserId,RoleId)
		SELECT u.UserId,r.RoleId
		FROM dbo.Users u 
		INNER JOIN dbo.Roles r on r.RoleName = 'Everyone'
		LEFT OUTER JOIN dbo.UserRoles ur on ur.UserId = u.UserId and ur.RoleId = r.RoleId
		WHERE ur.UserId is null

END








GO
ALTER TABLE [dbo].[Users] ENABLE TRIGGER [trgCreateHasherRecord]
GO
/****** Object:  Trigger [Hashers].[TR_HasherEventMap_InsertUpdateDelete]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [Hashers].[TR_HasherEventMap_InsertUpdateDelete] ON [Hashers].[HasherEventMap] AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON; IF TRIGGER_NESTLEVEL() > 3 RETURN; UPDATE [Hashers].[HasherEventMap] SET [updatedAt] = CONVERT (DATETIMEOFFSET(7), SYSUTCDATETIME()) FROM INSERTED WHERE INSERTED.id = [Hashers].[HasherEventMap].[id] END
GO
ALTER TABLE [Hashers].[HasherEventMap] ENABLE TRIGGER [TR_HasherEventMap_InsertUpdateDelete]
GO
/****** Object:  Trigger [Hashers].[TR_HasherFriendMap_InsertUpdateDelete]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [Hashers].[TR_HasherFriendMap_InsertUpdateDelete] ON [Hashers].[HasherFriendMap] AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON; IF TRIGGER_NESTLEVEL() > 3 RETURN; UPDATE [Hashers].[HasherFriendMap] SET [updatedAt] = CONVERT (DATETIMEOFFSET(7), SYSUTCDATETIME()) FROM INSERTED WHERE INSERTED.id = [Hashers].[HasherFriendMap].[id] END
GO
ALTER TABLE [Hashers].[HasherFriendMap] ENABLE TRIGGER [TR_HasherFriendMap_InsertUpdateDelete]
GO
/****** Object:  Trigger [HC].[TR_BusinessUnits_InsertUpdateDelete]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[TR_BusinessUnits_InsertUpdateDelete] ON [HC].[BusinessUnits] AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON; IF TRIGGER_NESTLEVEL() > 3 RETURN; UPDATE [HC].[BusinessUnits] SET [updatedAt] = CONVERT (DATETIMEOFFSET(7), SYSUTCDATETIME()) FROM INSERTED WHERE INSERTED.id = [HC].[BusinessUnits].[id] END
GO
ALTER TABLE [HC].[BusinessUnits] ENABLE TRIGGER [TR_BusinessUnits_InsertUpdateDelete]
GO
/****** Object:  Trigger [HC].[trgSetDirtyFlag]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgSetDirtyFlag]
   ON  [HC].[City]
   AFTER INSERT, UPDATE, DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON

	UPDATE HC.ServerStatus SET LastGazetteerUpdate = getdate()

END
GO
ALTER TABLE [HC].[City] ENABLE TRIGGER [trgSetDirtyFlag]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForCity]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForCity]
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
GO
ALTER TABLE [HC].[City] ENABLE TRIGGER [trgUpdateModifiedOnDateForCity]
GO
/****** Object:  Trigger [HC].[trgSetDirtyFlagCountry]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgSetDirtyFlagCountry]
   ON  [HC].[Country]
   AFTER INSERT, UPDATE, DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON

	UPDATE HC.ServerStatus SET LastGazetteerUpdate = getdate()

END
GO
ALTER TABLE [HC].[Country] ENABLE TRIGGER [trgSetDirtyFlagCountry]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForCountry]    Script Date: 4/21/19 7:12:02 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForCountry]
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
GO
ALTER TABLE [HC].[Country] ENABLE TRIGGER [trgUpdateModifiedOnDateForCountry]
GO
/****** Object:  Trigger [HC].[trgCalculateEventGeolocation]    Script Date: 4/21/19 7:12:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgCalculateEventGeolocation]
   ON  [HC].[Event]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	UPDATE HC.Event SET lastModified = getdate() WHERE id in (SELECT id from INSERTED)

    IF (UPDATE(Latitude) OR UPDATE(Longitude) OR UPDATE(FbLatitude) OR UPDATE(FbLongitude))
	BEGIN
		UPDATE HC.Event Set EventGeolocation = geography::Point(coalesce(Latitude,FbLatitude), coalesce(Longitude,FbLongitude), 4326) FROM HC.Event
			WHERE id in (SELECT id from INSERTED) AND coalesce(Latitude,FbLatitude) IS NOT NULL AND coalesce(Longitude,FbLongitude) IS NOT NULL
	END

END
GO
ALTER TABLE [HC].[Event] ENABLE TRIGGER [trgCalculateEventGeolocation]
GO
/****** Object:  Trigger [HC].[trgUpdateEventCounts]    Script Date: 4/21/19 7:12:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgUpdateEventCounts]
   ON  [HC].[Event]
   AFTER INSERT, UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF TRIGGER_NESTLEVEL(OBJECT_ID('HC.trgUpdateEventCounts')) > 1
    BEGIN
        PRINT 'mytrigger exiting because TRIGGER_NESTLEVEL > 1 ';
        RETURN;
	END;

IF UPDATE(AbsoluteEventNumber) OR UPDATE(EventNumberIncrement) OR UPDATE(IsCountedRun) OR UPDATE(deleted)
BEGIN

	DECLARE @eventId uniqueidentifier
	DECLARE @kennelId uniqueidentifier

	-- OK follow this logic....
	-- If there is only one record in INSERTED (which will normally be the case)....
	IF ((SELECT COUNT(*) FROM INSERTED) = 1)
		BEGIN
			-- ... we want to pass both the eventId and KennelId to the StoredProc
			SELECT @eventId = id, @kennelId = KennelId FROM INSERTED
			EXEC HC.nonApi_updateRunNumbers @kennelId = @kennelId, @eventId = @eventId
		END
	ELSE
		-- otherwise, if there is more than one record that has been updated
		BEGIN
			-- loop through one Kennel at a time
			DECLARE xCrsr CURSOR FOR SELECT DISTINCT(KennelId) FROM INSERTED
			
			OPEN xCrsr

			FETCH NEXT FROM xCrsr into @kennelId

			WHILE @@FETCH_STATUS = 0
			BEGIN
				-- and update all the runs for that particular kennel
				EXEC HC.nonApi_updateRunNumbers @kennelId = @kennelId, @eventId = '00000000-0000-0000-0000-000000000000'
				FETCH NEXT FROM xCrsr into @kennelId
			END

			CLOSE xCrsr
			DEALLOCATE xCrsr
		END

END

END
GO
ALTER TABLE [HC].[Event] ENABLE TRIGGER [trgUpdateEventCounts]
GO
/****** Object:  Trigger [HC].[trgCalculateHasherGeolocation]    Script Date: 4/21/19 7:12:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgCalculateHasherGeolocation]
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
GO
ALTER TABLE [HC].[Hasher] ENABLE TRIGGER [trgCalculateHasherGeolocation]
GO
/****** Object:  Trigger [HC].[trgGenerateQrCode]    Script Date: 4/21/19 7:12:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgGenerateQrCode]
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

	IF TRIGGER_NESTLEVEL(OBJECT_ID('HC.trgGenerateQrCode')) > 1
	BEGIN
		PRINT 'mytrigger exiting because TRIGGER_NESTLEVEL > 1 ';
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
		SET @Loop = 'Yes'
		SET @EmergencyStop = 0

		IF ((SELECT count(*) from HC.Hasher WHERE QR_code = @InsertedQr and id <> @id) > 0) OR (@InsertedQr not like 'UQR:%')
		BEGIN
			-- attempt to insert a duplicate QR was detected or the QR being inserted is invalid
			-- in these cases, create a new QR and insert that instead
			WHILE (@Loop = 'Yes')
			BEGIN
				SET @EmergencyStop = @EmergencyStop + 1
				IF @EmergencyStop > 10 SET @Loop = 'No'
				SET @QR = 'UQR:'+HC.NUMBER_TO_STR_BASE (36,(RAND() * (2147483647 - 60466177)) + 60466176)
				-- if the QR code is unique, go ahead and insert it
				IF (SELECT count(*) FROM HC.Hasher WHERE QR_code = @QR) = 0
				BEGIN
					SET @Loop = 'No'
					UPDATE HC.Hasher set QR_code = @QR WHERE id = @id
				END
			END
		END

		-- Now check the ResetCode
		SET @Loop = 'Yes'
		SET @EmergencyStop = 0

		IF ((SELECT count(*) from HC.Hasher WHERE ResetCode = @ResetCode and id <> @id) > 0) OR (@ResetCode not like 'RC:%')
		BEGIN
			-- attempt to insert a duplicate QR was detected or the QR being inserted is invalid
			-- in these cases, create a new QR and insert that instead
			WHILE (@Loop = 'Yes')
			BEGIN
				SET @EmergencyStop = @EmergencyStop + 1
				IF @EmergencyStop > 10 SET @Loop = 'No'
				SET @QR = 'RC:'+SUBSTRING(TRIM(HC.NUMBER_TO_STR_BASE (25,(RAND() * (2147483647 - 91466177)) + 91466177)),0,7)
				-- if the QR code is unique, go ahead and insert it
				IF (SELECT count(*) FROM HC.Hasher WHERE ResetCode = @QR) = 0
				BEGIN
					SET @Loop = 'No'
					UPDATE HC.Hasher set ResetCode = @QR WHERE id = @id
				END
			END
		END

		-- Now check the SupportCode
		SET @Loop = 'Yes'
		SET @EmergencyStop = 0

		IF ((SELECT count(*) from HC.Hasher WHERE SupportCode = @SupportCode and id <> @id) > 0) OR (@SupportCode not like 'SC:%')
		BEGIN
			-- attempt to insert a duplicate QR was detected or the QR being inserted is invalid
			-- in these cases, create a new QR and insert that instead
			WHILE (@Loop = 'Yes')
			BEGIN
				SET @EmergencyStop = @EmergencyStop + 1
				IF @EmergencyStop > 10 SET @Loop = 'No'
				SET @QR = 'SC:'+SUBSTRING(TRIM(HC.NUMBER_TO_STR_BASE (25,(RAND() * (2147483647 - 91466177)) + 91466177)),0,7)
				-- if the QR code is unique, go ahead and insert it
				IF (SELECT count(*) FROM HC.Hasher WHERE SupportCode = @QR) = 0
				BEGIN
					SET @Loop = 'No'
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
			
	--	SET @Loop = 'Yes'
	--	SET @EmergencyStop = 0

	--	IF ((SELECT count(*) from HC.Hasher WHERE ResetCode = @ResetCode and id <> @id) > 0) OR (@ResetCode not like 'RC:%')
	--	BEGIN
	--		-- attempt to insert a duplicate QR was detected or the QR being inserted is invalid
	--		-- in these cases, create a new QR and insert that instead
	--		WHILE (@Loop = 'Yes')
	--		BEGIN
	--			SET @EmergencyStop = @EmergencyStop + 1
	--			IF @EmergencyStop > 10 SET @Loop = 'No'
	--			SET @QR = 'RC:'+ SUBSTRING(TRIM(HC.NUMBER_TO_STR_BASE (25,(RAND() * (2147483647 - 91466177)) + 91466177)),0,7)
	--			-- if the QR code is unique, go ahead and insert it
	--			IF (SELECT count(*) FROM HC.Hasher WHERE ResetCode = @QR) = 0
	--			BEGIN
	--				SET @Loop = 'No'
	--				UPDATE HC.Hasher set ResetCode = @QR WHERE id = @id
	--			END
	--		END
	--	END

	--	FETCH NEXT FROM xCrsr INTO @id, @ResetCode
	--END

	--CLOSE xCrsr
	--DEALLOCATE xCrsr

END
GO
ALTER TABLE [HC].[Hasher] ENABLE TRIGGER [trgGenerateQrCode]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForNames]    Script Date: 4/21/19 7:12:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForNames]
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
GO
ALTER TABLE [HC].[Hasher] ENABLE TRIGGER [trgUpdateModifiedOnDateForNames]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForHasherKennelMap]    Script Date: 4/21/19 7:12:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForHasherKennelMap]
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
GO
ALTER TABLE [HC].[HasherKennelMap] ENABLE TRIGGER [trgUpdateModifiedOnDateForHasherKennelMap]
GO
/****** Object:  Trigger [HC].[trgUpdateKennelGeolocation]    Script Date: 4/21/19 7:12:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgUpdateKennelGeolocation]
   ON  [HC].[Kennel]
   AFTER INSERT,UPDATE
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF UPDATE(CityId) OR UPDATE(Latitude) OR UPDATE(Longitude)
	BEGIN

		declare @kennelId uniqueidentifier
		declare @cityId uniqueidentifier
		declare @latitude decimal(12,9)
		declare @longitude decimal (13,9)

		declare xCrsr CURSOR FOR
			select id,CityId,Latitude,Longitude from INSERTED where ((CityId is not null) OR (Latitude is not null AND Longitude is not null))

		OPEN xCrsr

		FETCH NEXT FROM xCrsr into @kennelId,@cityId,@latitude,@longitude

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


			FETCH NEXT FROM xCrsr into @kennelId,@cityId,@latitude,@longitude
		END

		CLOSE xCrsr
		DEALLOCATE xCrsr
	END

END
GO
ALTER TABLE [HC].[Kennel] ENABLE TRIGGER [trgUpdateKennelGeolocation]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForKennels]    Script Date: 4/21/19 7:12:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForKennels]
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
GO
ALTER TABLE [HC].[Kennel] ENABLE TRIGGER [trgUpdateModifiedOnDateForKennels]
GO
/****** Object:  Trigger [HC].[TR_Meetings_InsertUpdateDelete]    Script Date: 4/21/19 7:12:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[TR_Meetings_InsertUpdateDelete] ON [HC].[Meetings] AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON; IF TRIGGER_NESTLEVEL() > 3 RETURN; UPDATE [HC].[Meetings] SET [updatedAt] = CONVERT (DATETIMEOFFSET(7), SYSUTCDATETIME()) FROM INSERTED WHERE INSERTED.id = [HC].[Meetings].[id] END
GO
ALTER TABLE [HC].[Meetings] ENABLE TRIGGER [TR_Meetings_InsertUpdateDelete]
GO
/****** Object:  Trigger [HC].[trgSetDirtyFlagRegion]    Script Date: 4/21/19 7:12:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgSetDirtyFlagRegion]
   ON  [HC].[Region]
   AFTER INSERT, UPDATE, DELETE
AS 
BEGIN
	-- SET NOCOUNT ON added to prHasher extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON

	UPDATE HC.ServerStatus SET LastGazetteerUpdate = getdate()

END
GO
ALTER TABLE [HC].[Region] ENABLE TRIGGER [trgSetDirtyFlagRegion]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForRegion]    Script Date: 4/21/19 7:12:03 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForRegion]
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
GO
ALTER TABLE [HC].[Region] ENABLE TRIGGER [trgUpdateModifiedOnDateForRegion]
GO
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
/****** Object:  Index [IX_KennelSpatialIndex]    Script Date: 4/21/19 7:12:03 PM ******/
CREATE SPATIAL INDEX [IX_KennelSpatialIndex] ON [HC].[Kennel]
(
	[KennelGeolocation]
)USING  GEOGRAPHY_AUTO_GRID 
WITH (
CELLS_PER_OBJECT = 12, PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
USE [master]
GO
ALTER DATABASE [HarrierCentralWebDb] SET  READ_WRITE 
GO
