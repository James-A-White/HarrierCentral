USE [master]
GO
/****** Object:  Database [HarrierCentralWebDb]    Script Date: 11/26/19 8:01:54 AM ******/
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
/****** Object:  Schema [Admin]    Script Date: 11/26/19 8:01:56 AM ******/
CREATE SCHEMA [Admin]
GO
/****** Object:  Schema [DEV]    Script Date: 11/26/19 8:01:56 AM ******/
CREATE SCHEMA [DEV]
GO
/****** Object:  Schema [DomainValues]    Script Date: 11/26/19 8:01:56 AM ******/
CREATE SCHEMA [DomainValues]
GO
/****** Object:  Schema [Events]    Script Date: 11/26/19 8:01:56 AM ******/
CREATE SCHEMA [Events]
GO
/****** Object:  Schema [Geography]    Script Date: 11/26/19 8:01:56 AM ******/
CREATE SCHEMA [Geography]
GO
/****** Object:  Schema [Hashers]    Script Date: 11/26/19 8:01:56 AM ******/
CREATE SCHEMA [Hashers]
GO
/****** Object:  Schema [HC]    Script Date: 11/26/19 8:01:56 AM ******/
CREATE SCHEMA [HC]
GO
/****** Object:  Schema [HC2]    Script Date: 11/26/19 8:01:56 AM ******/
CREATE SCHEMA [HC2]
GO
/****** Object:  Schema [HC3]    Script Date: 11/26/19 8:01:56 AM ******/
CREATE SCHEMA [HC3]
GO
/****** Object:  Schema [Kennels]    Script Date: 11/26/19 8:01:56 AM ******/
CREATE SCHEMA [Kennels]
GO
/****** Object:  Schema [Transactions]    Script Date: 11/26/19 8:01:57 AM ******/
CREATE SCHEMA [Transactions]
GO
/****** Object:  Schema [UNUSED]    Script Date: 11/26/19 8:01:57 AM ******/
CREATE SCHEMA [UNUSED]
GO
/****** Object:  UserDefinedFunction [dbo].[fn_diagramobjects]    Script Date: 11/26/19 8:01:57 AM ******/
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
/****** Object:  UserDefinedFunction [HC].[CHECK_ACCESS_TOKEN]    Script Date: 11/26/19 8:01:57 AM ******/
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
/****** Object:  UserDefinedFunction [HC].[CREATE_ACCESS_TOKEN]    Script Date: 11/26/19 8:01:57 AM ******/
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
/****** Object:  UserDefinedFunction [HC].[InlineMax]    Script Date: 11/26/19 8:01:57 AM ******/
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
/****** Object:  UserDefinedFunction [HC].[NUMBER_TO_STR_BASE]    Script Date: 11/26/19 8:01:57 AM ******/
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
/****** Object:  Table [HC].[Country]    Script Date: 11/26/19 8:01:57 AM ******/
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
	[CurrencyCode] [nvarchar](5) NOT NULL,
	[PrimaryCultureCode] [nvarchar](10) NOT NULL,
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
/****** Object:  View [dbo].[vw_deleteCurrencyTest]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteCurrencyTest] as
select c.CountryName, c.CurrencySymbol, c.DigitsAfterDecimal,c.id from HC.Country c
GO
/****** Object:  Table [HC].[Hasher]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[Hasher](
	[id] [uniqueidentifier] NOT NULL,
	[HomeKennelId] [uniqueidentifier] NULL,
	[MotherKennelId] [uniqueidentifier] NULL,
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
/****** Object:  View [dbo].[vw_deleteHcPhotos]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteHcPhotos] as
select Photo,id,DisplayName from HC.Hasher
where createdAt > dateadd(day,-20,getdate())
GO
/****** Object:  Table [HC].[Event]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[Event](
	[id] [uniqueidentifier] NOT NULL,
	[EventFacebookId] [nvarchar](250) NULL,
	[FacebookRecordLastUpdated] [datetimeoffset](7) NULL,
	[EventStartDatetime] [datetimeoffset](7) NULL,
	[EventEndDatetime] [datetimeoffset](7) NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[IsVisible] [smallint] NOT NULL,
	[IsCountedRun] [smallint] NOT NULL,
	[IsPromotedEvent] [smallint] NOT NULL,
	[EventGeographicScope] [smallint] NOT NULL,
	[ThemeRunType] [smallint] NOT NULL,
	[AbsoluteEventNumber] [smallint] NULL,
	[EventNumber] [smallint] NOT NULL,
	[EventNumberIncrement] [smallint] NOT NULL,
	[EventPriceForMembers] [smallmoney] NULL,
	[EventPriceForNonMembers] [smallmoney] NULL,
	[EventCurrencyType] [nvarchar](10) NULL,
	[EventPaymentUrl] [nvarchar](2000) NULL,
	[EventPaymentUrlExpires] [datetimeoffset](7) NULL,
	[UnconfirmedBankXferCount] [int] NOT NULL,
	[UserEventCounterIncrement] [smallint] NOT NULL,
	[EventName] [nvarchar](250) NOT NULL,
	[EventDescription] [nvarchar](4000) NULL,
	[EventImage] [nvarchar](500) NULL,
	[EventImageOffsetX] [smallint] NULL,
	[EventImageOffsetY] [smallint] NULL,
	[EventShortDesc] [nvarchar](250) NULL,
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
	[CanEditRunAttendence] [smallint] NOT NULL,
	[Hares] [nvarchar](2500) NULL,
	[removed] [smallint] NOT NULL,
	[deleted] [bit] NOT NULL,
	[lastModified] [datetimeoffset](7) NOT NULL,
	[version] [timestamp] NOT NULL,
	[createdAt] [datetimeoffset](7) NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Event] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_deleteFilthRuns]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteFilthRuns] AS
select * from HC.event  where KennelId = '5029DE3A-D231-47AA-BE72-ECE9BCCD55D1'
GO
/****** Object:  View [dbo].[vw_deleteAddHashers]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[vw_deleteAddHashers] as
select FirstName,LastName,HashName,Email from HC.Hasher 
GO
/****** Object:  Table [HC].[HasherEventMap]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_deleteImportHemRecords]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteImportHemRecords] as 
select top 10 EventId,UserId,UserStartEvent,Rsvp,RsvpState,AttendenceState,IsHare,VirginVisitorType from HC.HasherEventMap
GO
/****** Object:  Table [HC].[Kennel]    Script Date: 11/26/19 8:02:03 AM ******/
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
	[KennelFacebookTokenLastUpdated] [datetimeoffset](7) NULL,
	[KennelFacebookImportDaysInPast] [smallint] NOT NULL,
	[KennelFacebookImportDaysInFuture] [smallint] NOT NULL,
	[KennelFacebookForceUpdatesUntil] [datetimeoffset](7) NULL,
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
	[ExtApiKey] [nvarchar](120) NULL,
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
/****** Object:  View [dbo].[vw_deleteMe_facebookIds]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteMe_facebookIds]
as
select top 20 * from HC.Kennel where KennelFacebookId is not null
GO
/****** Object:  View [dbo].[vw_deleteMe_importEvents]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteMe_importEvents] as
select top 1 id,EventStartDatetime,KennelId,EventName,EventDescription from HC.Event
GO
/****** Object:  View [dbo].[vw_deleteEditFacebookKennels]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteEditFacebookKennels] as 
select * from HC.Kennel where KennelFacebookId is not null
GO
/****** Object:  Table [HC].[HasherKennelMap]    Script Date: 11/26/19 8:02:03 AM ******/
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
	[IsHomeKennel] [smallint] NOT NULL,
	[KennelNotificationPreference] [smallint] NOT NULL,
	[KennelEmailAlertPreference] [smallint] NOT NULL,
	[MismanagementRoleFlags] [int] NOT NULL,
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_dev_kennelMembership]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
GO
/****** Object:  Table [HC].[City]    Script Date: 11/26/19 8:02:03 AM ******/
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
	[Timezone] [nvarchar](150) NULL,
	[WindowsTimezone] [nvarchar](150) NULL,
	[Removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_City2] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  View [HC].[deleteTempCities]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view 

[HC].[deleteTempCities]

AS 

select * from HC.City where Latitude between 52 and 53 and Longitude  between 4 and  5
GO
/****** Object:  View [dbo].[vw_deleteEditFILTHhash]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteEditFILTHhash] as select * from HC.Kennel where KennelName like '%FILTH%'
GO
/****** Object:  View [dbo].[vw_deleteEditNetherlands]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteEditNetherlands] as select * from HC.Country h where h.CountryName like '%nether%'
GO
/****** Object:  Table [HC].[Payment]    Script Date: 11/26/19 8:02:03 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[Payment](
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
	[Notes] [nvarchar](500) NULL,
	[removed] [smallint] NOT NULL,
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_Payment] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  View [dbo].[vw_deleteEditPayments]    Script Date: 11/26/19 8:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteEditPayments] as select * from HC.Payment
GO
/****** Object:  View [dbo].[vw_insertHashers]    Script Date: 11/26/19 8:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vw_insertHashers] AS 
SELECT 
      [DisplayName]
      ,[HashName]
      ,[FirstName]
      ,[LastName]
      ,[Email]
  FROM [HC].[Hasher]
GO
/****** Object:  View [dbo].[vw_insertHkmRecords]    Script Date: 11/26/19 8:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_insertHkmRecords] as 
select userId, kennelId from HC.HasherKennelMap
GO
/****** Object:  View [dbo].[vw_deleteOpeeRuns]    Script Date: 11/26/19 8:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view
[dbo].[vw_deleteOpeeRuns] as 
select * from HC.HasherEventMap where userId = '0CDBB109-215E-4B5F-A405-F6C9FBCB18EC'
GO
/****** Object:  View [HC].[vwEventCommonFields]    Script Date: 11/26/19 8:02:04 AM ******/
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
/****** Object:  View [dbo].[vw_deleteTempKennelList]    Script Date: 11/26/19 8:02:04 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create view [dbo].[vw_deleteTempKennelList] as select * from HC.Kennel where kennelLogo like 'http%'
GO
/****** Object:  UserDefinedFunction [HC].[DelimitedSplit8K]    Script Date: 11/26/19 8:02:04 AM ******/
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
/****** Object:  Table [dbo].[BusinessUnits]    Script Date: 11/26/19 8:02:04 AM ******/
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
/****** Object:  Table [dbo].[Contacts]    Script Date: 11/26/19 8:02:04 AM ******/
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
/****** Object:  Table [dbo].[currency]    Script Date: 11/26/19 8:02:04 AM ******/
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
/****** Object:  Table [dbo].[Exceptions]    Script Date: 11/26/19 8:02:04 AM ******/
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
/****** Object:  Table [dbo].[Hasher]    Script Date: 11/26/19 8:02:04 AM ******/
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
/****** Object:  Table [dbo].[Languages]    Script Date: 11/26/19 8:02:04 AM ******/
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
/****** Object:  Table [dbo].[MeetingAgendaRelevant]    Script Date: 11/26/19 8:02:04 AM ******/
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
/****** Object:  Table [dbo].[MeetingAgendas]    Script Date: 11/26/19 8:02:05 AM ******/
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
/****** Object:  Table [dbo].[MeetingAgendaTypes]    Script Date: 11/26/19 8:02:05 AM ******/
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
/****** Object:  Table [dbo].[MeetingAttendees]    Script Date: 11/26/19 8:02:05 AM ******/
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
/****** Object:  Table [dbo].[MeetingDecisionRelevant]    Script Date: 11/26/19 8:02:05 AM ******/
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
/****** Object:  Table [dbo].[MeetingDecisions]    Script Date: 11/26/19 8:02:05 AM ******/
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
/****** Object:  Table [dbo].[MeetingLocations]    Script Date: 11/26/19 8:02:05 AM ******/
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
/****** Object:  Table [dbo].[Meetings]    Script Date: 11/26/19 8:02:05 AM ******/
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
/****** Object:  Table [dbo].[MeetingTypes]    Script Date: 11/26/19 8:02:06 AM ******/
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
/****** Object:  Table [dbo].[RolePermissions]    Script Date: 11/26/19 8:02:06 AM ******/
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
/****** Object:  Table [dbo].[Roles]    Script Date: 11/26/19 8:02:06 AM ******/
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
/****** Object:  Table [dbo].[SourceData]    Script Date: 11/26/19 8:02:06 AM ******/
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
/****** Object:  Table [dbo].[sysdiagrams]    Script Date: 11/26/19 8:02:06 AM ******/
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
/****** Object:  Table [dbo].[tempImport]    Script Date: 11/26/19 8:02:06 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[tempImport](
	[userId] [uniqueidentifier] NOT NULL,
	[eventId] [uniqueidentifier] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[unused_FacebookEventImport]    Script Date: 11/26/19 8:02:07 AM ******/
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
/****** Object:  Table [dbo].[UserPermissions]    Script Date: 11/26/19 8:02:07 AM ******/
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
/****** Object:  Table [dbo].[UserPreferences]    Script Date: 11/26/19 8:02:07 AM ******/
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
/****** Object:  Table [dbo].[UserRoles]    Script Date: 11/26/19 8:02:07 AM ******/
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
/****** Object:  Table [dbo].[Users]    Script Date: 11/26/19 8:02:07 AM ******/
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
/****** Object:  Table [dbo].[VersionInfo]    Script Date: 11/26/19 8:02:07 AM ******/
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
/****** Object:  Index [UC_Version]    Script Date: 11/26/19 8:02:07 AM ******/
CREATE UNIQUE CLUSTERED INDEX [UC_Version] ON [dbo].[VersionInfo]
(
	[Version] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[world_cities_table]    Script Date: 11/26/19 8:02:07 AM ******/
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
/****** Object:  Table [DEV].[EnumPaymentTypes]    Script Date: 11/26/19 8:02:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DEV].[EnumPaymentTypes](
	[paymentTypeId] [int] NOT NULL,
	[name] [nvarchar](50) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [DEV].[ImportHashers]    Script Date: 11/26/19 8:02:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DEV].[ImportHashers](
	[idx] [int] IDENTITY(1,1) NOT NULL,
	[HashName] [nvarchar](250) NOT NULL,
	[First] [char](1) NOT NULL,
	[Last] [char](1) NOT NULL,
 CONSTRAINT [PK_ImportHashers] PRIMARY KEY CLUSTERED 
(
	[idx] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [DEV].[timezone]    Script Date: 11/26/19 8:02:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
GO
/****** Object:  Table [DEV].[WindowsTimezoneMap]    Script Date: 11/26/19 8:02:08 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [DEV].[WindowsTimezoneMap](
	[WindowsTimezone] [nvarchar](150) NULL,
	[Region] [nvarchar](50) NULL,
	[Timezones] [nvarchar](3500) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [DomainValues].[CurrencyCodes]    Script Date: 11/26/19 8:02:08 AM ******/
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
/****** Object:  Table [DomainValues].[EventGeographicScope]    Script Date: 11/26/19 8:02:08 AM ******/
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
/****** Object:  Table [DomainValues].[EventRegistrationType]    Script Date: 11/26/19 8:02:08 AM ******/
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
/****** Object:  Table [DomainValues].[KennelStatusEnum]    Script Date: 11/26/19 8:02:08 AM ******/
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
/****** Object:  Table [DomainValues].[MismanagementEnum]    Script Date: 11/26/19 8:02:08 AM ******/
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
/****** Object:  Table [HC].[ErrorLog]    Script Date: 11/26/19 8:02:09 AM ******/
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
/****** Object:  Table [HC].[HasherFriendMap]    Script Date: 11/26/19 8:02:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[HasherOwnEvent]    Script Date: 11/26/19 8:02:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[HasherOwnEvent](
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
	[updatedAt] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_HasherOwnEvent] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [HC].[KennelAuthorization]    Script Date: 11/26/19 8:02:09 AM ******/
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
/****** Object:  Table [HC].[KennelCredit]    Script Date: 11/26/19 8:02:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[LaunchAndLogin]    Script Date: 11/26/19 8:02:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
	[Longitude] [decimal](19, 15) NULL
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[LoginNotifications]    Script Date: 11/26/19 8:02:09 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[Receipt]    Script Date: 11/26/19 8:02:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[Receipt](
	[id] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NOT NULL,
	[UserId] [uniqueidentifier] NOT NULL,
	[ReceiptAmount] [decimal](12, 4) NOT NULL,
	[CostCategory] [smallint] NOT NULL,
	[DateUploaded] [datetimeoffset](7) NOT NULL,
	[ImageUrl] [nvarchar](500) NOT NULL,
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[Region]    Script Date: 11/26/19 8:02:10 AM ******/
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
/****** Object:  Table [HC].[RunCounts]    Script Date: 11/26/19 8:02:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [HC].[ServerStatus]    Script Date: 11/26/19 8:02:10 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [HC].[ServerStatus](
	[id] [uniqueidentifier] NOT NULL,
	[ApiVersion] [nvarchar](25) NOT NULL,
	[CreatedDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_ServerStatus] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Kennels].[Haberdashery]    Script Date: 11/26/19 8:02:10 AM ******/
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
/****** Object:  Table [Kennels].[Mismanagement]    Script Date: 11/26/19 8:02:10 AM ******/
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
/****** Object:  Table [Transactions].[EventRegistration]    Script Date: 11/26/19 8:02:10 AM ******/
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
/****** Object:  Table [Transactions].[HaberdasherySale]    Script Date: 11/26/19 8:02:10 AM ******/
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
/****** Object:  Table [UNUSED].[FeaturedEvent]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [UNUSED].[FeaturedEvent](
	[id] [uniqueidentifier] NOT NULL,
	[EventId] [uniqueidentifier] NOT NULL,
	[StartDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_FeaturedEvent] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [UNUSED].[FeaturedKennel]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [UNUSED].[FeaturedKennel](
	[id] [uniqueidentifier] NOT NULL,
	[KennelId] [uniqueidentifier] NOT NULL,
	[StartDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_FeaturedKennel] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [UNUSED].[FeaturedSong]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [UNUSED].[FeaturedSong](
	[id] [uniqueidentifier] NOT NULL,
	[SongId] [uniqueidentifier] NOT NULL,
	[StartDate] [datetimeoffset](7) NOT NULL,
 CONSTRAINT [PK_FeaturedSong] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [UNUSED].[Haberdashery]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [UNUSED].[KennelSongMap]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [UNUSED].[KennelSongMap](
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
/****** Object:  Table [UNUSED].[Song]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Exceptions_App_Del_Cre]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE NONCLUSTERED INDEX [IX_Exceptions_App_Del_Cre] ON [dbo].[Exceptions]
(
	[ApplicationName] ASC,
	[DeletionDate] ASC,
	[CreationDate] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_Exceptions_GUID_App_Del_Cre]    Script Date: 11/26/19 8:02:11 AM ******/
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
/****** Object:  Index [IX_Exceptions_Hash_App_Cre_Del]    Script Date: 11/26/19 8:02:11 AM ******/
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
/****** Object:  Index [UQ_RolePerm_RoleId_PermKey]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_RolePerm_RoleId_PermKey] ON [dbo].[RolePermissions]
(
	[RoleId] ASC,
	[PermissionKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [UQ_UserPerm_UserId_PermKey]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_UserPerm_UserId_PermKey] ON [dbo].[UserPermissions]
(
	[UserId] ASC,
	[PermissionKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_UserPref_UID_PrefType_Name]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_UserPref_UID_PrefType_Name] ON [dbo].[UserPreferences]
(
	[UserId] ASC,
	[PreferenceType] ASC,
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_UserRoles_RoleId_UserId]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE NONCLUSTERED INDEX [IX_UserRoles_RoleId_UserId] ON [dbo].[UserRoles]
(
	[RoleId] ASC,
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [UQ_UserRoles_UserId_RoleId]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [UQ_UserRoles_UserId_RoleId] ON [dbo].[UserRoles]
(
	[UserId] ASC,
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_CityUpdated]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE NONCLUSTERED INDEX [IX_CityUpdated] ON [HC].[City]
(
	[updatedAt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_CountryUpdated]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE NONCLUSTERED INDEX [IX_CountryUpdated] ON [HC].[Country]
(
	[updatedAt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_Event_KidIsCountedDeleted2]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE NONCLUSTERED INDEX [IX_Event_KidIsCountedDeleted2] ON [HC].[Event]
(
	[KennelId] ASC,
	[IsCountedRun] ASC,
	[deleted] ASC
)
INCLUDE ( 	[AbsoluteEventNumber]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_EventByKennelIsCountedStartDateAbsEvtNum]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE NONCLUSTERED INDEX [IX_EventByKennelIsCountedStartDateAbsEvtNum] ON [HC].[Event]
(
	[KennelId] ASC,
	[IsCountedRun] ASC,
	[EventStartDatetime] ASC,
	[AbsoluteEventNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
/****** Object:  Index [IX_HasherEventMap]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE NONCLUSTERED INDEX [IX_HasherEventMap] ON [HC].[HasherEventMap]
(
	[EventId] ASC,
	[UserId] ASC,
	[DisplayName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_HasherFriendMap]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_HasherFriendMap] ON [HC].[HasherFriendMap]
(
	[UserId] ASC,
	[Friend_UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_HasherKennelMap]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_HasherKennelMap] ON [HC].[HasherKennelMap]
(
	[KennelId] ASC,
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_RegionUpdated]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE NONCLUSTERED INDEX [IX_RegionUpdated] ON [HC].[Region]
(
	[updatedAt] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_KennelSongMap]    Script Date: 11/26/19 8:02:11 AM ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_KennelSongMap] ON [UNUSED].[KennelSongMap]
(
	[KennelId] ASC,
	[SongId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
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
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_UnconfirmedBankXferCount]  DEFAULT ((0)) FOR [UnconfirmedBankXferCount]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_UserCountIncrement]  DEFAULT ((1)) FOR [UserEventCounterIncrement]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_HC_Event_MinimumRequired]  DEFAULT ((1)) FOR [MinimumParticipantsRequired]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_CanEditRunAttendence]  DEFAULT ((1)) FOR [CanEditRunAttendence]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_removed]  DEFAULT ((0)) FOR [removed]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF__Event__deleted__22CA2527]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF_Event_lastModified]  DEFAULT (getdate()) FOR [lastModified]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF__Event__createdAt__414EAC47]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
GO
ALTER TABLE [HC].[Event] ADD  CONSTRAINT [DF__Event__updatedAt__4242D080]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
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
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_removed]  DEFAULT ((0)) FOR [removed]
GO
ALTER TABLE [HC].[HasherEventMap] ADD  CONSTRAINT [DF_HasherEventMap_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
GO
ALTER TABLE [HC].[HasherFriendMap] ADD  CONSTRAINT [DF_HasherFriendMap_Id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[HasherFriendMap] ADD  CONSTRAINT [DF_HasherFriendMap_FriendNotificationPreference]  DEFAULT ((0)) FOR [FriendNotificationPreference]
GO
ALTER TABLE [HC].[HasherFriendMap] ADD  CONSTRAINT [DF_HasherFriendMap_State]  DEFAULT ((0)) FOR [Ignore]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_HasherId]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_Following]  DEFAULT ((1)) FOR [Following]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_State]  DEFAULT ((0)) FOR [IsMember]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_IsHomeKennel]  DEFAULT ((0)) FOR [IsHomeKennel]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_KennelNotificationPreference]  DEFAULT ((0)) FOR [KennelNotificationPreference]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_KennelEmailPreferences]  DEFAULT ((0)) FOR [KennelEmailAlertPreference]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_IsMismanagement]  DEFAULT ((0)) FOR [MismanagementRoleFlags]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_UserRoleFlags]  DEFAULT ((0)) FOR [UserRoleFlags]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_AppAccessFlags]  DEFAULT ((0)) FOR [AppAccessFlags]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_HistoricalRunCount]  DEFAULT ((0)) FOR [HistoricalPackRunCount]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_HistoricalHaringCount]  DEFAULT ((0)) FOR [HistoricalHaringCount]
GO
ALTER TABLE [HC].[HasherKennelMap] ADD  CONSTRAINT [DF_HasherKennelMap_HistoricalCountIsEstimate]  DEFAULT ((0)) FOR [HistoricalCountIsEstimate]
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
ALTER TABLE [HC].[HasherOwnEvent] ADD  CONSTRAINT [DF_HC_HasherOwnEvent_EventId]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[HasherOwnEvent] ADD  CONSTRAINT [DF_HasherOwnEvent_IsVisible]  DEFAULT ((1)) FOR [IsVisible]
GO
ALTER TABLE [HC].[HasherOwnEvent] ADD  CONSTRAINT [DF_HasherOwnEvent_IsCountedRun]  DEFAULT ((1)) FOR [IsCountedRun]
GO
ALTER TABLE [HC].[HasherOwnEvent] ADD  CONSTRAINT [DF_HasherOwnEvent_EventNumber]  DEFAULT ((0)) FOR [EventNumber]
GO
ALTER TABLE [HC].[HasherOwnEvent] ADD  CONSTRAINT [DF_HasherOwnEvent_removed]  DEFAULT ((0)) FOR [removed]
GO
ALTER TABLE [HC].[HasherOwnEvent] ADD  CONSTRAINT [DF__HasherOwnEvent__deleted__22CA2527]  DEFAULT ((0)) FOR [deleted]
GO
ALTER TABLE [HC].[HasherOwnEvent] ADD  CONSTRAINT [DF_HasherOwnEvent_lastModified]  DEFAULT (getdate()) FOR [lastModified]
GO
ALTER TABLE [HC].[HasherOwnEvent] ADD  CONSTRAINT [DF__HasherOwnEvent__createdAt__414EAC47]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [createdAt]
GO
ALTER TABLE [HC].[HasherOwnEvent] ADD  CONSTRAINT [DF__HasherOwnEvent__updatedAt__4242D080]  DEFAULT (CONVERT([datetimeoffset](7),sysutcdatetime(),(0))) FOR [updatedAt]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_id]  DEFAULT (newid()) FOR [id]
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
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_MembershipDurationInMonths]  DEFAULT ((12)) FOR [MembershipDurationInMonths]
GO
ALTER TABLE [HC].[Kennel] ADD  CONSTRAINT [DF_Kennel_removed]  DEFAULT ((12)) FOR [removed]
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
ALTER TABLE [HC].[KennelCredit] ADD  CONSTRAINT [DF_KennelCredit_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[KennelCredit] ADD  CONSTRAINT [DF_KennelCredit_removed]  DEFAULT ((0)) FOR [removed]
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
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_CreditAmount]  DEFAULT ((0)) FOR [CreditAmount]
GO
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_DebitAmount]  DEFAULT ((0)) FOR [DebitAmount]
GO
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_PaidDate]  DEFAULT (getdate()) FOR [PaidDate]
GO
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_ProductType]  DEFAULT ((1)) FOR [ProductType]
GO
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_CreditAvailable]  DEFAULT ((0)) FOR [CreditAvailable]
GO
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_removed]  DEFAULT ((0)) FOR [removed]
GO
ALTER TABLE [HC].[Payment] ADD  CONSTRAINT [DF_Payment_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
GO
ALTER TABLE [HC].[Receipt] ADD  CONSTRAINT [DF_Receipt_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[Receipt] ADD  CONSTRAINT [DF_Receipt_CostCategory]  DEFAULT ((0)) FOR [CostCategory]
GO
ALTER TABLE [HC].[Receipt] ADD  CONSTRAINT [DF_Receipt_DateUploaded]  DEFAULT (getdate()) FOR [DateUploaded]
GO
ALTER TABLE [HC].[Receipt] ADD  CONSTRAINT [DF_Receipt_removed]  DEFAULT ((0)) FOR [removed]
GO
ALTER TABLE [HC].[Receipt] ADD  CONSTRAINT [DF_Receipt_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
GO
ALTER TABLE [HC].[Region] ADD  CONSTRAINT [DF_Region_Removed]  DEFAULT ((0)) FOR [Removed]
GO
ALTER TABLE [HC].[Region] ADD  CONSTRAINT [DF_Region_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
GO
ALTER TABLE [HC].[RunCounts] ADD  CONSTRAINT [DF_RunCounts_updatedAt]  DEFAULT (getdate()) FOR [updatedAt]
GO
ALTER TABLE [HC].[ServerStatus] ADD  CONSTRAINT [DF_ServerStatus_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [HC].[ServerStatus] ADD  CONSTRAINT [DF_ServerStatus_CreatedDate]  DEFAULT (getdate()) FOR [CreatedDate]
GO
ALTER TABLE [Kennels].[Mismanagement] ADD  CONSTRAINT [DF_Mismanagement_MismanagementId]  DEFAULT (newid()) FOR [MismanagementId]
GO
ALTER TABLE [Transactions].[EventRegistration] ADD  CONSTRAINT [DF_EventRegistration_DateRegistered]  DEFAULT (getdate()) FOR [DateRegistered]
GO
ALTER TABLE [UNUSED].[FeaturedEvent] ADD  CONSTRAINT [DF_FeaturedEvent_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [UNUSED].[FeaturedKennel] ADD  CONSTRAINT [DF_FeaturedKennel_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [UNUSED].[FeaturedSong] ADD  CONSTRAINT [DF_FeaturedSong_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [UNUSED].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [UNUSED].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_Price]  DEFAULT ((0)) FOR [Price]
GO
ALTER TABLE [UNUSED].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_InStock]  DEFAULT ((1)) FOR [InStock]
GO
ALTER TABLE [UNUSED].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_Archive]  DEFAULT ((0)) FOR [Archive]
GO
ALTER TABLE [UNUSED].[Haberdashery] ADD  CONSTRAINT [DF_Haberdashery_ShowOnHomePage]  DEFAULT ((0)) FOR [ShowOnHomePage]
GO
ALTER TABLE [UNUSED].[KennelSongMap] ADD  CONSTRAINT [DF_KennelSongMap_Id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [UNUSED].[KennelSongMap] ADD  CONSTRAINT [DF_KennelSongMap_Following]  DEFAULT ((1)) FOR [Following]
GO
ALTER TABLE [UNUSED].[Song] ADD  CONSTRAINT [DF_Song_id]  DEFAULT (newid()) FOR [id]
GO
ALTER TABLE [UNUSED].[Song] ADD  CONSTRAINT [DF_Song_Rating]  DEFAULT ((1)) FOR [BawdyRating]
GO
ALTER TABLE [UNUSED].[Song] ADD  CONSTRAINT [DF_Song_AutoAddToKennel]  DEFAULT ((0)) FOR [AutoAddToKennel]
GO
ALTER TABLE [UNUSED].[Song] ADD  CONSTRAINT [DF_Song_Rank]  DEFAULT ((0)) FOR [Rank]
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
ALTER TABLE [HC].[City]  WITH CHECK ADD  CONSTRAINT [FK_City_Region] FOREIGN KEY([RegionId])
REFERENCES [HC].[Region] ([id])
GO
ALTER TABLE [HC].[City] CHECK CONSTRAINT [FK_City_Region]
GO
ALTER TABLE [HC].[HasherEventMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherEventMap_Event] FOREIGN KEY([EventId])
REFERENCES [HC].[Event] ([id])
GO
ALTER TABLE [HC].[HasherEventMap] CHECK CONSTRAINT [FK_HasherEventMap_Event]
GO
ALTER TABLE [HC].[HasherEventMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherEventMap_Hasher] FOREIGN KEY([UserId])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [HC].[HasherEventMap] CHECK CONSTRAINT [FK_HasherEventMap_Hasher]
GO
ALTER TABLE [HC].[HasherEventMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherEventMap_HasherOwnEvent] FOREIGN KEY([HasherOwnEventId])
REFERENCES [HC].[HasherOwnEvent] ([id])
GO
ALTER TABLE [HC].[HasherEventMap] CHECK CONSTRAINT [FK_HasherEventMap_HasherOwnEvent]
GO
ALTER TABLE [HC].[HasherEventMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherEventMap_RunCounts] FOREIGN KEY([RunCountId])
REFERENCES [HC].[RunCounts] ([id])
GO
ALTER TABLE [HC].[HasherEventMap] CHECK CONSTRAINT [FK_HasherEventMap_RunCounts]
GO
ALTER TABLE [HC].[HasherFriendMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherFriendMap_Hasher] FOREIGN KEY([UserId])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [HC].[HasherFriendMap] CHECK CONSTRAINT [FK_HasherFriendMap_Hasher]
GO
ALTER TABLE [HC].[HasherFriendMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherFriendMap_Hasher1] FOREIGN KEY([Friend_UserId])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [HC].[HasherFriendMap] CHECK CONSTRAINT [FK_HasherFriendMap_Hasher1]
GO
ALTER TABLE [HC].[HasherKennelMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherKennelMap_Hasher] FOREIGN KEY([UserId])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [HC].[HasherKennelMap] CHECK CONSTRAINT [FK_HasherKennelMap_Hasher]
GO
ALTER TABLE [HC].[HasherKennelMap]  WITH CHECK ADD  CONSTRAINT [FK_HasherKennelMap_Kennel] FOREIGN KEY([KennelId])
REFERENCES [HC].[Kennel] ([id])
GO
ALTER TABLE [HC].[HasherKennelMap] CHECK CONSTRAINT [FK_HasherKennelMap_Kennel]
GO
ALTER TABLE [HC].[Kennel]  WITH CHECK ADD  CONSTRAINT [FK_Kennel_City] FOREIGN KEY([CityId])
REFERENCES [HC].[City] ([id])
GO
ALTER TABLE [HC].[Kennel] CHECK CONSTRAINT [FK_Kennel_City]
GO
ALTER TABLE [HC].[Kennel]  WITH CHECK ADD  CONSTRAINT [FK_Kennel_KennelStatusEnum] FOREIGN KEY([KennelStatus])
REFERENCES [DomainValues].[KennelStatusEnum] ([KennelStatusEnumId])
GO
ALTER TABLE [HC].[Kennel] CHECK CONSTRAINT [FK_Kennel_KennelStatusEnum]
GO
ALTER TABLE [HC].[KennelAuthorization]  WITH CHECK ADD  CONSTRAINT [FK_KennelAuthorization_Kennel] FOREIGN KEY([KennelId])
REFERENCES [HC].[Kennel] ([id])
GO
ALTER TABLE [HC].[KennelAuthorization] CHECK CONSTRAINT [FK_KennelAuthorization_Kennel]
GO
ALTER TABLE [HC].[KennelCredit]  WITH CHECK ADD  CONSTRAINT [FK_KennelCredit_Hasher] FOREIGN KEY([userId])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [HC].[KennelCredit] CHECK CONSTRAINT [FK_KennelCredit_Hasher]
GO
ALTER TABLE [HC].[KennelCredit]  WITH CHECK ADD  CONSTRAINT [FK_KennelCredit_Kennel] FOREIGN KEY([kennelId])
REFERENCES [HC].[Kennel] ([id])
GO
ALTER TABLE [HC].[KennelCredit] CHECK CONSTRAINT [FK_KennelCredit_Kennel]
GO
ALTER TABLE [HC].[LaunchAndLogin]  WITH NOCHECK ADD  CONSTRAINT [FK_LaunchAndLogin_Hasher] FOREIGN KEY([UserId])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [HC].[LaunchAndLogin] NOCHECK CONSTRAINT [FK_LaunchAndLogin_Hasher]
GO
ALTER TABLE [HC].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_Event] FOREIGN KEY([EventId])
REFERENCES [HC].[Event] ([id])
GO
ALTER TABLE [HC].[Payment] CHECK CONSTRAINT [FK_Payment_Event]
GO
ALTER TABLE [HC].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_Hasher] FOREIGN KEY([UserId])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [HC].[Payment] CHECK CONSTRAINT [FK_Payment_Hasher]
GO
ALTER TABLE [HC].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_Hasher1] FOREIGN KEY([PaymentProcessedBy_userId])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [HC].[Payment] CHECK CONSTRAINT [FK_Payment_Hasher1]
GO
ALTER TABLE [HC].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_Hasher2] FOREIGN KEY([CancelledBy_UserId])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [HC].[Payment] CHECK CONSTRAINT [FK_Payment_Hasher2]
GO
ALTER TABLE [HC].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_Hasher3] FOREIGN KEY([ConfirmedBy_UserId])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [HC].[Payment] CHECK CONSTRAINT [FK_Payment_Hasher3]
GO
ALTER TABLE [HC].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_HasherEventMap] FOREIGN KEY([HasherEventMapId])
REFERENCES [HC].[HasherEventMap] ([id])
GO
ALTER TABLE [HC].[Payment] CHECK CONSTRAINT [FK_Payment_HasherEventMap]
GO
ALTER TABLE [HC].[Payment]  WITH CHECK ADD  CONSTRAINT [FK_Payment_Kennel] FOREIGN KEY([KennelId])
REFERENCES [HC].[Kennel] ([id])
GO
ALTER TABLE [HC].[Payment] CHECK CONSTRAINT [FK_Payment_Kennel]
GO
ALTER TABLE [HC].[Receipt]  WITH CHECK ADD  CONSTRAINT [FK_Receipt_Event] FOREIGN KEY([EventId])
REFERENCES [HC].[Event] ([id])
GO
ALTER TABLE [HC].[Receipt] CHECK CONSTRAINT [FK_Receipt_Event]
GO
ALTER TABLE [HC].[Receipt]  WITH CHECK ADD  CONSTRAINT [FK_Receipt_Hasher] FOREIGN KEY([UserId])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [HC].[Receipt] CHECK CONSTRAINT [FK_Receipt_Hasher]
GO
ALTER TABLE [HC].[Receipt]  WITH CHECK ADD  CONSTRAINT [FK_Receipt_Hasher1] FOREIGN KEY([ReimbursedBy])
REFERENCES [HC].[Hasher] ([id])
GO
ALTER TABLE [HC].[Receipt] CHECK CONSTRAINT [FK_Receipt_Hasher1]
GO
ALTER TABLE [HC].[Region]  WITH CHECK ADD  CONSTRAINT [FK_Region_Country] FOREIGN KEY([CountryId])
REFERENCES [HC].[Country] ([id])
GO
ALTER TABLE [HC].[Region] CHECK CONSTRAINT [FK_Region_Country]
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
/****** Object:  StoredProcedure [dbo].[sp_alterdiagram]    Script Date: 11/26/19 8:02:11 AM ******/
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
/****** Object:  StoredProcedure [dbo].[sp_creatediagram]    Script Date: 11/26/19 8:02:11 AM ******/
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
/****** Object:  StoredProcedure [dbo].[sp_dropdiagram]    Script Date: 11/26/19 8:02:11 AM ******/
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
/****** Object:  StoredProcedure [dbo].[sp_helpdiagramdefinition]    Script Date: 11/26/19 8:02:11 AM ******/
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
/****** Object:  StoredProcedure [dbo].[sp_helpdiagrams]    Script Date: 11/26/19 8:02:11 AM ******/
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
/****** Object:  StoredProcedure [dbo].[sp_renamediagram]    Script Date: 11/26/19 8:02:11 AM ******/
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
/****** Object:  StoredProcedure [dbo].[sp_upgraddiagrams]    Script Date: 11/26/19 8:02:11 AM ******/
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
/****** Object:  StoredProcedure [DEV].[CleanDb]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [DEV].[CleanDb] AS

delete from HC.HasherEventMap where EventId not in (select id from HC.Event)
delete from HC.HasherEventMap where UserId not in (select id from HC.Hasher)
delete from HC.HasherKennelMap where UserId not in (select id from HC.Hasher)
delete from HC.HasherKennelMap where KennelId not in (select id from HC.Kennel)
delete from HC.Payment where HasherEventMapId not in (select id from HC.HasherEventMap)
delete from HC.RunCounts where id not in (select RunCountId from HC.HasherEventMap)
GO
/****** Object:  StoredProcedure [DEV].[RecompileHc2AndHc3]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [DEV].[RecompileHc2AndHc3]

AS

DECLARE @sql NVARCHAR(MAX) = '';
SELECT @sql += 'EXEC sp_recompile ''HC2.'+[name]+''''+CHAR(10) FROM sys.objects WHERE [type] IN ('P') and schema_id = 13 and parent_object_id = 0 and type_desc = 'SQL_STORED_PROCEDURE'
EXEC (@sql);

SET @sql = ''
SELECT @sql += 'EXEC sp_recompile ''HC3.'+[name]+''''+CHAR(10) FROM sys.objects WHERE [type] IN ('P') and schema_id = 15 and parent_object_id = 0 and type_desc = 'SQL_STORED_PROCEDURE'
EXEC (@sql);


GO
/****** Object:  StoredProcedure [HC].[nonApi_adjustHasherRunCounts]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC].[nonApi_adjustHasherRunCounts]

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
AND (((@limitByUser = 1) AND (hem.userId = @userId) AND evt.KennelId = @kennelId) OR ((@limitByUser = 2) AND (hem.id = @hasherEventMapId)) OR (@limitByUser = 0))
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
/****** Object:  StoredProcedure [HC].[nonApi_rptKennelRunStats]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [HC].[nonApi_rptKennelRunStats]

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
/****** Object:  StoredProcedure [HC].[nonApi_updateEventFromFacebook]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





--EXEC [HC].[nonApi_updateEventFromFacebook]


----@FacebookEventId = '2405453486398316',
--@FacebookEventId = '2405453486398316',
--@KennelId = '9963AD79-772C-4B56-9298-7B6E6294D131',
--@EventName = 'Pet a feel ya run',
--@EventDescription = 'Come and pet a pet.   And you can do it at: https://goo.gl/maps/QXf1fvPXM732kmVf8 where all the excitement will happen! Wahoo!',
--@StartTime ='2019-06-29 15:00:00.000',
--@EventImage = 'https://scontent.xx.fbcdn.net/v/t1.0-9/s720x720/61709911_10219492799694405_1398371932021194752_o.jpg?_nc_cat=106&_nc_ht=scontent.xx&oh=b55129f1a8145f05468500dc4da06542&oe=5DBA91C7',
--@PlaceName = '52.1209664,4.4405331',
--@City = 'Voorschoten',
--@Country = 'Nederland',
--@Latitude = -1,
--@Longitude = -1,
--@Street = '42 Veurseweg',
--@Zip = '2252AB',
--@OffsetX = 50,
--@OffsetY = 50,
--@AbsoluteEventNumber = -1,
--@IsCountedRun = -1,
--@IsVisible = -1,
--@ForceUpdate = 0


--ALTER PROCEDURE [HC].[nonApi_updateEventFromFacebook]


--@FacebookEventId nvarchar(250),
--@KennelId uniqueidentifier,
--@EventName nvarchar(250) = NULL,
--@EventDescription nvarchar(4000) = NULL,
--@StartTime datetimeoffset(7) = NULL,
--@EventImage nvarchar(500) = NULL,
--@PlaceName nvarchar(500) = NULL,
--@City nvarchar(500) = NULL,
--@Country nvarchar(500) = NULL,
--@Latitude decimal (18,15) = NULL,
--@Longitude decimal (19,15) = NULL,
--@Street nvarchar(500) = NULL,
--@Zip nvarchar(100) = NULL,
--@OffsetX int = NULL,
--@OffsetY int = NULL,
--@AbsoluteEventNumber int = NULL,
--@IsCountedRun int = NULL,
--@IsVisible int = NULL,
--@ForceUpdate int = NULL

--AS

---- NOTE: This is a non-API stored procedure not publicly available so we do not need to process tokens.

--BEGIN

--if (@Latitude = -1) SET @Latitude = NULL
--if (@Longitude = -1) SET @Longitude  = NULL
--if (@StartTime < '1900-01-01 00:00:00') SET @StartTime = NULL
--if (@AbsoluteEventNumber = -1) SET @AbsoluteEventNumber = NULL
--if (@IsCountedRun = -1) SET @IsCountedRun = NULL
--if (@IsVisible = -1) SET @IsVisible = NULL

--DECLARE @eventId UNIQUEIDENTIFIER

--	DECLARE @lat DECIMAL(18,15)
--	DECLARE @lon DECIMAL(19,15)
--	DECLARE @geo GEOGRAPHY

----IF (SELECT COUNT(*) FROM HC.Event evt where evt.KennelId = @KennelId AND ((coalesce(evt.EventFacebookId,'') = @FacebookEventId) OR ((evt.EventStartDatetime = @StartTime) AND (evt.EventFacebookId is null)))) > 0
----IF (SELECT COUNT(*) FROM HC.Event evt where evt.KennelId = @KennelId AND evt.EventFacebookId = @FacebookEventId) > 0
----IF (SELECT COUNT(*) FROM HC.Event evt where evt.KennelId = @KennelId AND (coalesce(evt.EventFacebookId,'') = @FacebookEventId)) > 0
--IF (SELECT COUNT(*) FROM HC.Event evt where evt.EventFacebookId = @FacebookEventId and evt.KennelId = @KennelId) > 0
--BEGIN

--	DECLARE @timeChanged NVARCHAR(20)
--	DECLARE @nameChanged NVARCHAR(20)
--	DECLARE @descChanged NVARCHAR(20)
--	DECLARE @locChanged NVARCHAR(20)
--	DECLARE @evtName NVARCHAR(500)
--	DECLARE @serverLat DECIMAL(18,15)
--	DECLARE @serverLon DECIMAL(19,15)
	
--	SELECT 
--		@timeChanged = CASE WHEN ((@StartTime IS NOT NULL) AND (cast (@StartTime as DateTime) <> evt.[EventStartDatetime])) THEN 'Time, ' ELSE '' END
--		,@nameChanged = CASE WHEN ((@EventName IS NOT NULL) AND (@EventName <> evt.[EventName])) THEN 'Name, ' ELSE '' END
--		,@descChanged = CASE WHEN ((@EventDescription IS NOT NULL) AND (@EventDescription <> evt.[EventDescription])) THEN 'Description, ' ELSE '' END
--		,@locChanged = CASE WHEN ((@PlaceName IS NOT NULL) AND (@PlaceName <> evt.[LocationOneLineDesc])) THEN 'Location, ' ELSE '' END
--		,@evtName = coalesce(@EventName,evt.[EventName])
--		,@eventId = id
--		,@serverLat = Latitude
--		,@serverLon = Longitude
--	--FROM HC.Event evt WHERE evt.KennelId = @KennelId AND ((coalesce(evt.EventFacebookId,'') = @FacebookEventId) OR ((evt.EventStartDatetime = @StartTime) AND (evt.EventFacebookId is null)))
--	--FROM HC.Event evt WHERE evt.KennelId = @KennelId AND (coalesce(evt.EventFacebookId,'') = @FacebookEventId)
--		FROM HC.Event evt WHERE 
--		evt.EventFacebookId = @FacebookEventId 
--		AND evt.KennelId = @KennelId

--	SELECT @lat = coalesce(@serverLat,@latitude)
--	SELECT @lon = coalesce(@serverLon,@longitude)

--	IF ((@lat IS NOT NULL) AND (@lon IS NOT NULL))
--	BEGIN
--		SET @geo = geography::Point(@lat, @lon, 4326)
--	END

--	UPDATE HC.Event SET 
--      [FacebookRecordLastUpdated] = getdate()
--	  ,[EventFacebookId] = coalesce(@FacebookEventId,evt.[EventFacebookId])
--      ,[EventStartDatetime] = coalesce(@StartTime,evt.[EventStartDatetime])
--      ,[EventName] = coalesce(@EventName,evt.[EventName])
--      ,[EventDescription] = coalesce(@EventDescription,evt.[EventDescription])
--      ,[EventImage] = coalesce(@EventImage,evt.[EventImage])
--      ,[EventImageOffsetX] = coalesce(@OffsetX,evt.[EventImageOffsetX])
--      ,[EventImageOffsetY] = coalesce(@OffsetY,evt.[EventImageOffsetY])

--      ,[LocationOneLineDesc] = coalesce(@PlaceName,evt.[LocationOneLineDesc])
--      ,[LocationCity] = coalesce(@City,evt.[LocationCity])
--      ,[LocationStreet] = coalesce(@Street,evt.[LocationStreet])
--      ,[LocationPostCode] = coalesce(@Zip,evt.[LocationPostCode])
--      ,[LocationCountry] = coalesce(@Country,evt.[LocationCountry])

--      ,[FbLatitude] = coalesce(@Latitude,evt.[FbLatitude])
--      ,[FbLongitude] = coalesce(@Longitude,evt.[FbLongitude])
--	  ,[EventGeolocation] = coalesce(@geo,evt.[EventGeolocation])

--      ,[AbsoluteEventNumber] = coalesce(@AbsoluteEventNumber,evt.[AbsoluteEventNumber])

--	  ,[IsCountedRun] = coalesce(@IsCountedRun,evt.[IsCountedRun])
--	  ,[IsVisible] = coalesce(@IsVisible,evt.[IsVisible])
--	  ,[updatedAt] = getdate()

--	  FROM HC.Event evt WHERE id = @eventId
--	  AND 
--	  (
--      ((@ForceUpdate IS NOT NULL) AND (@ForceUpdate = 1))
--		OR ((@StartTime IS NOT NULL) AND (cast (@StartTime as DateTime) <> evt.[EventStartDatetime]))
--		OR ((@EventName IS NOT NULL) AND (@EventName <> evt.[EventName]))
--		OR ((@EventDescription IS NOT NULL) AND (@EventDescription <> evt.[EventDescription]))
--		OR ((@EventImage IS NOT NULL) AND (@EventImage <> evt.[EventImage]))
--		OR ((@OffsetX IS NOT NULL) AND (@OffsetX <> evt.[EventImageOffsetX]))
--		OR ((@OffsetY IS NOT NULL) AND (@OffsetY <> evt.[EventImageOffsetY]))
--		OR ((@PlaceName IS NOT NULL) AND (@PlaceName <> evt.[LocationOneLineDesc]))
--		OR ((@FacebookEventId IS NOT NULL) AND (@FacebookEventId <> coalesce(evt.[EventFacebookId],'')))
--		--OR ((@City IS NOT NULL) AND (@City <> evt.[LocationCity]))
--		--OR ((@Street IS NOT NULL) AND (@Street <> evt.[LocationStreet]))
--		--OR ((@Zip IS NOT NULL) AND (@Zip <> evt.[LocationPostCode]))
--		--OR ((@Country IS NOT NULL) AND (@Country <> evt.[LocationCountry]))
--		--OR ((@Latitude IS NOT NULL) AND (@Latitude <> coalesce(evt.[FbLatitude],-999)))
--		--OR ((@Longitude IS NOT NULL) AND (@Longitude <> coalesce(evt.[FbLongitude],-999)))
--		OR ((@AbsoluteEventNumber IS NOT NULL) AND (@AbsoluteEventNumber <> coalesce(evt.[AbsoluteEventNumber],-999)))
--		OR ((@IsCountedRun IS NOT NULL) AND (@IsCountedRun <> coalesce(evt.[IsCountedRun],-999)))
--		OR ((@IsVisible IS NOT NULL) AND (@IsVisible <> coalesce(evt.[IsVisible],-999)))
--	  )

--	  IF (@@ROWCOUNT = 0)
--	  BEGIN
--		  --SELECT @eventId, @@ROWCOUNT, @FacebookEventId
--	     SELECT 'Rows updated = 0' as Result, '00000000-0000-0000-0000-000000000000' as EventId
--	  END
--	  ELSE
--	  BEGIN
--		 --SELECT @eventId, @@ROWCOUNT, @FacebookEventId
--		 EXEC HC.nonApi_updateRunNumbers  @eventId = @eventId

--		 -- Format the text string that will be sent as a notification to mobile devices
--		 DECLARE @res NVARCHAR(500)

--	     SELECT @res = 'The event, ' + @evtName + ', has been updated. '

--		 if (datalength (@timeChanged + @locChanged +  @descChanged + @nameChanged) > 0)
--		 BEGIN
--			DECLARE @changedAttributes nvarchar(150)
--			SELECT @changedAttributes = @nameChanged + @timeChanged + @locChanged + @descChanged
--			SELECT @changedAttributes = LEFT(@changedAttributes,(datalength(@changedAttributes) / 2) - 2) + ' '

--			SELECT @res = @res + @changedAttributes + 'changed.'
--		 END
		 
--		 SELECT @res AS Result, @eventId as EventId

--	  END

--END
--ELSE
--BEGIN

--SET @eventId = newid()

--	IF ((@latitude IS NOT NULL) AND (@longitude IS NOT NULL))
--	BEGIN
--		SET @geo = geography::Point(@latitude, @longitude, 4326)
--	END

--INSERT INTO [HC].[Event]
--           (id
--		   ,[EventFacebookId]
--           ,[FacebookRecordLastUpdated]
--           ,[EventStartDatetime]
--           ,[KennelId]
--           ,[IsCountedRun]
--		   ,[IsVisible]
--           ,[AbsoluteEventNumber]
--           ,[EventName]
--           ,[EventDescription]
--           ,[EventImage]
--           ,[EventImageOffsetX]
--           ,[EventImageOffsetY]
--           ,[LocationOneLineDesc]
--           ,[LocationCity]
--           ,[LocationStreet]
--           ,[LocationPostCode]
--           ,[LocationCountry]
--           ,[FbLatitude]
--           ,[FbLongitude]
--		   ,[EventGeolocation]
--		   ,[updatedAt]
--			)
--     VALUES
--           (
--		    @eventId
--		   ,@FacebookEventId 
--           ,getdate() -- <FacebookRecordLastUpdated, datetimeoffset(7),>
--           ,@StartTime 
--           ,@KennelId 
--           ,coalesce(@IsCountedRun,1)
--           ,coalesce(@IsVisible,1)
--           ,@AbsoluteEventNumber
--           ,@EventName
--           ,@EventDescription
--           ,@EventImage
--           ,@OffsetX
--           ,@OffsetY
--           ,@PlaceName
--           ,@City
--           ,@Street
--           ,@Zip
--           ,@Country
--           ,@Latitude
--           ,@Longitude
--		   ,@geo
--		   ,getdate())

--    EXEC HC.nonApi_updateRunNumbers  @eventId = @eventId

--	SELECT 'A new event, ' + @EventName + ', has been added from Facebook' as Result, @eventId as EventId
--END

--END








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

	DECLARE @lat DECIMAL(18,15)
	DECLARE @lon DECIMAL(19,15)
	DECLARE @geo GEOGRAPHY

--IF (SELECT COUNT(*) FROM HC.Event evt where evt.EventFacebookId = @FacebookEventId and evt.KennelId = @KennelId) > 0
IF (SELECT COUNT(*) FROM HC.Event evt where evt.KennelId = @KennelId AND ((coalesce(evt.EventFacebookId,'') = @FacebookEventId) OR ((evt.EventStartDatetime = cast (@StartTime as DateTime)) AND (evt.EventFacebookId is null)))) > 0
BEGIN

	DECLARE @timeChanged NVARCHAR(20)
	DECLARE @nameChanged NVARCHAR(20)
	DECLARE @descChanged NVARCHAR(20)
	DECLARE @locChanged NVARCHAR(20)
	DECLARE @evtName NVARCHAR(500)
	DECLARE @serverLat DECIMAL(18,15)
	DECLARE @serverLon DECIMAL(19,15)
	
	SELECT 
		@timeChanged = CASE WHEN ((@StartTime IS NOT NULL) AND (cast (@StartTime as DateTime) <> evt.[EventStartDatetime])) THEN 'Time, ' ELSE '' END
		,@nameChanged = CASE WHEN ((@EventName IS NOT NULL) AND (@EventName <> evt.[EventName])) THEN 'Name, ' ELSE '' END
		,@descChanged = CASE WHEN ((@EventDescription IS NOT NULL) AND (@EventDescription <> evt.[EventDescription])) THEN 'Description, ' ELSE '' END
		,@locChanged = CASE WHEN ((@PlaceName IS NOT NULL) AND (@PlaceName <> evt.[LocationOneLineDesc])) THEN 'Location, ' ELSE '' END
		,@evtName = coalesce(@EventName,evt.[EventName])
		,@eventId = id
		,@serverLat = Latitude
		,@serverLon = Longitude
		FROM HC.Event evt WHERE evt.KennelId = @KennelId AND ((coalesce(evt.EventFacebookId,'') = @FacebookEventId) OR ((evt.EventStartDatetime = cast (@StartTime as DateTime)) AND (evt.EventFacebookId is null)))
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
      [FacebookRecordLastUpdated] = getdate()
	  ,[EventFacebookId] = coalesce(@FacebookEventId,evt.[EventFacebookId])
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
	  ,[EventGeolocation] = coalesce(@geo,evt.[EventGeolocation])

      ,[AbsoluteEventNumber] = coalesce(@AbsoluteEventNumber,evt.[AbsoluteEventNumber])

	  ,[IsCountedRun] = coalesce(@IsCountedRun,evt.[IsCountedRun])
	  ,[IsVisible] = coalesce(@IsVisible,evt.[IsVisible])
	  ,[updatedAt] = getdate()

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
		OR ((@FacebookEventId IS NOT NULL) AND (@FacebookEventId <> coalesce(evt.[EventFacebookId],'')))
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
		   ,[EventGeolocation]
		   ,[updatedAt]
			)
     VALUES
           (
		    @eventId
		   ,@FacebookEventId 
           ,getdate() -- <FacebookRecordLastUpdated, datetimeoffset(7),>
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
           ,@Longitude
		   ,@geo
		   ,getdate())

    EXEC HC.nonApi_updateRunNumbers  @eventId = @eventId

	SELECT 'A new event, ' + @EventName + ', has been added from Facebook' as Result, @eventId as EventId
END


END
GO
/****** Object:  StoredProcedure [HC].[nonApi_updateRunNumbers]    Script Date: 11/26/19 8:02:11 AM ******/
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
/****** Object:  StoredProcedure [HC2].[getPaymentReport]    Script Date: 11/26/19 8:02:11 AM ******/
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
/****** Object:  StoredProcedure [HC3].[addEditEvent]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC3].[addEditEvent]

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
/****** Object:  StoredProcedure [HC3].[addEditReceipt]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [HC3].[addEditReceipt]

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
/****** Object:  StoredProcedure [HC3].[addEditUser]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC3].[addEditUser]

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
/****** Object:  StoredProcedure [HC3].[approveLogin]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [HC3].[approveLogin]

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
	FROM HC.ServerStatus svr
	ORDER BY svr.CreatedDate desc

END
GO
/****** Object:  StoredProcedure [HC3].[authorizeDevice]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC3].[authorizeDevice]

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

if (@scanText like 'URC:%')
BEGIN
	SELECT top 1 
		@userId = h.id 
	FROM HC.Hasher h where h.ResetCode = @scanText

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
				h.ResetCode as resetCode
			FROM HC.Hasher h where h.id = @userId
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
/****** Object:  StoredProcedure [HC3].[extApi_getKennelEmailList]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC3].[extApi_getKennelEmailList]

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
/****** Object:  StoredProcedure [HC3].[extApi_getKennelMembers]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC3].[extApi_getKennelMembers]

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
/****** Object:  StoredProcedure [HC3].[extApi_getKennelPayments]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC3].[extApi_getKennelPayments]

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
/****** Object:  StoredProcedure [HC3].[getPaymentReport]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC3].[getPaymentReport]

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
/****** Object:  StoredProcedure [HC3].[getResetCode]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [HC3].[getResetCode]

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
/****** Object:  StoredProcedure [HC3].[joinEvent]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [HC3].[joinEvent]

 @userId uniqueidentifier,
 @accessToken nvarchar(1000),
 @eventId uniqueidentifier,
 @hasherId uniqueidentifier,
 @hasherEventMapId uniqueidentifier,
 
 @isHare VARCHAR(10) = '-1',
 @rsvpState VARCHAR(10) = '-1',
 @attendenceState VARCHAR(10) = '-1',
 @virginVisitorType VARCHAR(10) = '-1',
 @notificationState VARCHAR(10) = '-1',
 @emailAlertState VARCHAR(10) = '-1',

 @hasherEventMapUpdatedAfter nvarchar(50),
 @hasherKennelMapUpdatedAfter nvarchar(50) = null,
 @paymentsUpdatedAfter nvarchar(50)

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
			@isMember = case when coalesce(hkm.MembershipExpirationDate,'1/1/2000') > getdate() then 1 else 0 end, -- memvership determination required for payment popup 
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
		@ahd_currentHaringCount int

		SELECT 
		@ahd_hasherId = hem.UserId,
		@ahd_notificationPrefs = coalesce(hem.EventNotificationPreference,hkm.KennelNotificationPreference),
		@ahd_emailAlertPrefs = coalesce(hem.EventEmailAlertPreference,hkm.KennelEmailAlertPreference),
		@ahd_currentPackRunCount = coalesce(hkm.CurrentPackRunCount,-1),
		@ahd_currentHaringCount = coalesce(hkm.CurrentHaringCount,-1)
		FROM HC.HasherEventMap hem
		LEFT OUTER JOIN HC.HasherKennelMap hkm on hkm.kennelId = @kennelId AND hkm.userId = hem.userId
		WHERE hem.id = @hasherEventMapId

SELECT
		1 as adHocDataId,
		@serverMessage as userMessage,
		coalesce(@payCount,0) as isPaid,
		@isMember as isMember,  -- this is "safe" as we are checking the membership date directly, may need to adjust for timezones though in the future
		@hasherEventMapId as hasherEventMapId,
		coalesce(@ahd_hasherId,@hasherId) as hasherId,
		@ahd_notificationPrefs as notificationPreference,
		@ahd_emailAlertPrefs as emailAlertPreference,
		@ahd_currentHaringCount as currentHaringCount,
		@ahd_currentPackRunCount as currentPackRunCount


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
@receiptsUpdatedAfter = 'ignore',
@procName = @procName,
@param = NULL


END





GO
/****** Object:  StoredProcedure [HC3].[joinEventAsVisitor]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC3].[joinEventAsVisitor]  

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
/****** Object:  StoredProcedure [HC3].[joinKennel]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [HC3].[joinKennel]

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
/****** Object:  StoredProcedure [HC3].[processPayment]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC3].[processPayment]

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
@paymentsUpdatedAfter nvarchar(50) = 'ignore',
@kennelCreditsUpdatedAfter nvarchar(50) = 'ignore'

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

-- exec HC.payForEvent @userId = '624C51B3-2F64-4DE5-9458-B506E75AC544', @hasherEventMapId = '0bc3a6ea-0e9f-432e-acb0-079c1557f004', @paymentType = 3

SET NOCOUNT ON

	IF (@productType is null) SET @productType = 1

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

			DECLARE
				 @eventPrice money,
				 @creditAmount money,
				 @kennelId uniqueidentifier,
				 @kennelName nvarchar(250),
				 @payer_userIdGuid uniqueidentifier,
				 @attendenceState int,
				 @payer_userName nvarchar(120),
				 @buttonState int,
				 @isPaid int

			SET @isPaid = 0

			SET @buttonState = 0

			SELECT
			@eventPrice = CASE WHEN coalesce(hkm.MembershipExpirationDate,'1/1/2000') > getdate() THEN
				coalesce(e.EventPriceForMembers,k.DefaultEventPriceForMembers,e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,0)
			ELSE
				coalesce(e.EventPriceForNonMembers,k.DefaultEventPriceForNonMembers,e.EventPriceForMembers,k.DefaultEventPriceForMembers,0)
			END
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


			if (@paymentType = 1) -- handle the 'Not paid' case
			BEGIN
				UPDATE HC.Payment SET CancelledDate = getdate(), CancelledBy_UserId = @userId, updatedAt = getdate() WHERE CancelledDate is null AND HasherEventMapId = @hasherEventMapId
			END

			IF (@paymentType = 2) 
			BEGIN
				SET @eventPrice = 0 -- in this case the run is "free"
			END

			DECLARE @paymentReference NVARCHAR(50)
			SET @paymentReference = 'NONE'

			IF ((@paymentType >= 2) AND (@paymentType <= 7)) -- in this case the run is paid in cash, bank transfer or using credits or was free
			BEGIN

				SET @paymentReference = HC.NUMBER_TO_STR_BASE (36,(RAND() * (2147483647 - 60466177)) + 60466176)
		
				IF ((@paymentType = 5) OR (@paymentType = 7))
					SET @creditAmount = @paymentAmount
				ELSE
					SET @creditAmount = @eventPrice

				IF (@paymentType = 6) SET @creditAmount = 0 -- this is the case when hashers are paying using their existing 'hash credit'


				-- We only allow one payment per event, so cancel any previous payments when a new payment comes in for an event that is of type "free", "cash", "bank transfer", or "credit"
				UPDATE HC.Payment SET CancelledDate = getdate(), CancelledBy_UserId = @userId, updatedAt = getdate() WHERE CancelledDate is null AND HasherEventMapId = @hasherEventMapId

				-- Now insert a new payment record
				INSERT HC.Payment (KennelId, UserId, EventId, HasherEventMapId, CreditAmount,DebitAmount,CreditAvailable,PaymentProcessedBy_userId,PaidDate, PaymentType, ProductType, PaymentReference, updatedAt) 
						VALUES (@kennelId,@payer_userIdGuid,@eventId,@hasherEventMapId,@creditAmount,@eventPrice,0,@userId,GETDATE(),@paymentType, @productType, @paymentReference,getdate())



				-- if they have paid, mark them as being at the event.
				UPDATE HC.HasherEventMap set UserStartEvent = getdate(), RsvpState = 3, AttendenceState = CASE when AttendenceState < @minimumAttendenceValue then @minimumAttendenceValue else AttendenceState end, updatedAt = getdate() where id = @hasherEventMapId
				SET @buttonState = 1
				SET @isPaid = 1
			END

				-- Update the Kennel Credit table if necessary
			DECLARE @creditAvailable smallmoney
			SELECT @creditAvailable = SUM(pay.creditAmount) - SUM(pay.debitAmount) FROM HC.Payment pay WHERE pay.KennelId = @kennelId AND pay.UserId = @payer_userIdGuid AND pay.CancelledDate IS NULL AND pay.PaymentType BETWEEN 5 AND 7 
			if (@creditAvailable IS NOT NULL)
			BEGIN
				MERGE HC.KennelCredit AS [Target] 
				USING (SELECT @payer_userIdGuid AS userId, @kennelId AS kennelId) AS [Source] ON [Target].kennelId = [Source].kennelId AND [Target].userId = [Source].userId 
				WHEN MATCHED THEN UPDATE SET [Target].currentBalance = @creditAvailable, [Target].balanceAsOfEventId = @eventId, [Target].updatedAt = getdate() 
				WHEN NOT MATCHED THEN INSERT (userId, kennelId,currentBalance,balanceAsOfEventId,updatedAt) VALUES (@payer_userIdGuid, @kennelId,@creditAvailable,@eventId,getdate());
			END


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
		@paymentType as paymentType,
		@productType as productType,
		@eventPrice as debitAmount,
		@creditAmount as creditAmount,
		@paymentAmount as paymentAmount,
		@creditAvailable as creditAvailable,
		@paymentReference as paymentReference


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
		@kennelCreditsUpdatedAfter = @kennelCreditsUpdatedAfter,
		@receiptsUpdatedAfter = 'ignore',
		@procName = @procName,
		@param = @paramString

END
GO
/****** Object:  StoredProcedure [HC3].[rptApi_emailRunDetails]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [HC3].[rptApi_emailRunDetails]

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
/****** Object:  StoredProcedure [HC3].[rptKennelRunStats]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC3].[rptKennelRunStats]

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
/****** Object:  StoredProcedure [HC3].[syncEventAdminData]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [HC3].[syncEventAdminData]

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
		  ,[IsMember] as isMember
		  ,[IsHomeKennel] as isHomeKennel
		  ,[KennelNotificationPreference] as kennelNotificationPreference
		  ,[KennelEmailAlertPreference] as kennelEmailAlertPreference
		  ,[MismanagementRoleFlags] as mismanagementRoleFlags
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
			,convert(datetime2,[EventStartDatetime]) as eventStartDatetime -- This is a bit of a hack, force conversion into local time prior to sending over the wire. TODO: Eventually send over the event UTC and a separate time offset
			,[KennelId] as kennelId
			,[IsVisible] as isVisible
			,[IsCountedRun] as isCountedRun
			,[EventNumber] as eventNumber
			,[EventName] as eventName
			,evt.[EventPriceForMembers] as eventPriceForMembers
			,evt.[EventPriceForNonMembers] as eventPriceForNonMembers
			,coalesce(evt.[Latitude],[fbLatitude],ken.Latitude) as narrowEventLatitude
			,coalesce(evt.[Longitude],[fbLongitude],ken.Longitude) as narrowEventLongitude
			,[EventFacebookId] as eventFacebookId
			,[AbsoluteEventNumber] as absoluteEventNumber
			,evt.[CanEditRunAttendence] as canEditRunAttendence
			,evt.EventImage as eventImage
			,evt.EventDescription as eventDescription
			,evt.LocationOneLineDesc as locationOneLineDesc
			,evt.LocationPostCode as locationPostCode
			,evt.LocationCity as locationCity
			,evt.LocationStreet as locationStreet
			,evt.Hares as hares
			,evt.EventPaymentUrl as eventPaymentUrl
			,evt.EventPaymentUrlExpires as eventPaymentUrlExpires
			,evt.UnconfirmedBankXferCount as unconfirmedBankXferCount

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
/****** Object:  StoredProcedure [HC3].[syncKennelAdminData]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC3].[syncKennelAdminData]

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
			,[MembershipDurationInMonths] as membershipDurationInMonths

			-- Doubles
			,[Latitude] as kennelLatitude
			,[Longitude] as kennelLongitude
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
			,[KennelPaymentUrl] as kennelPaymentUrl
			,[KennelPaymentUrlExpires] as kennelPaymentUrlExpires

			,[removed] as removed
			,[updatedAt]

	  FROM [HC].[Kennel] where updatedAt > @ua
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
		  ,[KennelNotificationPreference] as kennelNotificationPreference
		  ,[KennelEmailAlertPreference] as kennelEmailAlertPreference
		  ,[MismanagementRoleFlags] as mismanagementRoleFlags
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
			coalesce(h.updatedAt,getdate()) as updatedAt,
			coalesce(h.Removed,0) as removed
		FROM HC.Hasher h where updatedAt >= @ua
	END

END

GO
/****** Object:  StoredProcedure [HC3].[syncUserData]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [HC3].[syncUserData]

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
 @hasherOwnEventUpdatedAfter nvarchar(50) = 'ignore',
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
	if ((@hasherOwnEventUpdatedAfter IS NULL) OR (@hasherOwnEventUpdatedAfter <= '2000-01-01 00:00:00')) SET @hasherOwnEventUpdatedAfter = 'ignore'

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
			coalesce(h.updatedAt,getdate()) as updatedAt,
			coalesce(h.Removed,0) as removed
		FROM HC.Hasher h where updatedAt >= @ua
	END

	if (LOWER(@citiesUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@citiesUpdatedAfter as datetimeoffset(7))
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

	if (LOWER(@regionsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@regionsUpdatedAfter as datetimeoffset(7))
		SELECT 
			[id] as regionId
		  ,[RegionName] as regionName
		  ,[CountryId] as countryId
		  ,[FlagFile] as flagFile
		  ,[Removed] as removed
		  ,[updatedAt] as updatedAt
		FROM HC.Region where updatedAt > @ua
	END

	if (LOWER(@countriesUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@countriesUpdatedAfter as datetimeoffset(7))
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

	if (LOWER(@kennelsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@kennelsUpdatedAfter as datetimeoffset(7))
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
			,[MembershipDurationInMonths] as membershipDurationInMonths

			-- Doubles
			,[Latitude] as kennelLatitude
			,[Longitude] as kennelLongitude
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
			,[KennelPaymentUrl] as kennelPaymentUrl
			,[KennelPaymentUrlExpires] as kennelPaymentUrlExpires

			,[removed] as removed
			,[updatedAt]

	  FROM [HC].[Kennel] where updatedAt > @ua
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
		  ,[KennelNotificationPreference] as kennelNotificationPreference
		  ,[KennelEmailAlertPreference] as kennelEmailAlertPreference
		  ,[MismanagementRoleFlags] as mismanagementRoleFlags
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
			-- comment out one line below
			,[HasherOwnEventId] as hasherOwnEventId
			,[UserStartEvent] as userStartEvent
			,[UserEndEvent] as userEndEvent
			,[RsvpState] as rsvpState
			,[AttendenceState] as attendenceState
			,[IsHare] as isHare
			,[EventNotificationPreference] as eventNotificationPreference
			,[EventEmailAlertPreference] as eventEmailAlertPreference
			,[EventCountOverride] as eventCountOverride

			,[removed] as removed
			,[updatedAt] as updatedAt
		FROM HC.HasherEventMap where updatedAt > @ua and UserId = @userId
	END


	if (LOWER(@narrowEventsUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@narrowEventsUpdatedAfter as datetimeoffset(7))
		SELECT 
			 evt.[id] as eventId
			,convert(datetime2,[EventStartDatetime]) as eventStartDatetime -- This is a bit of a hack, force conversion into local time prior to sending over the wire. TODO: Eventually send over the event UTC and a separate time offset
			,[KennelId] as kennelId
			,[IsVisible] as isVisible
			,[IsCountedRun] as isCountedRun
			,[EventNumber] as eventNumber
			,[EventName] as eventName
			,evt.[EventPriceForMembers] as eventPriceForMembers
			,evt.[EventPriceForNonMembers] as eventPriceForNonMembers
			,coalesce(evt.[Latitude],[fbLatitude],ken.Latitude) as narrowEventlatitude
			,coalesce(evt.[Longitude],[fbLongitude],ken.Longitude) as narrowEventLongitude
			,[EventFacebookId] as eventFacebookId
			,[AbsoluteEventNumber] as absoluteEventNumber
			,evt.[CanEditRunAttendence] as canEditRunAttendence
			,evt.EventImage as eventImage
			,evt.EventDescription as eventDescription
			,evt.LocationOneLineDesc as locationOneLineDesc
			,evt.LocationPostCode as locationPostCode
			,evt.LocationCity as locationCity
			,evt.LocationStreet as locationStreet
			,evt.Hares as hares
			,evt.EventPaymentUrl as eventPaymentUrl
			,evt.EventPaymentUrlExpires as eventPaymentUrlExpires
			,evt.UnconfirmedBankXferCount as unconfirmedBankXferCount

			,evt.[removed] as removed
			,evt.[updatedAt] as updatedAt

		FROM HC.Event evt inner join HC.Kennel ken on evt.KennelId = ken.id
		where evt.updatedAt > @ua
	END

	if (LOWER(@hasherOwnEventUpdatedAfter) != 'ignore')
	BEGIN
		SET @ua = CAST(@hasherOwnEventUpdatedAfter as datetimeoffset(7))
		SELECT 
			 [id] as hoeId

			,[KennelId] as kennelId
			,[EventId] as eventId
			,[EventStartDatetime] as eventStartDatetime
			,[IsVisible] as isVisible
			,[IsCountedRun] as isCountedRun
			,[EventNumber] as eventNumber
			,[EventName] as eventName
			,[EventDescription] as eventDescription
			,[LocationOneLineDesc] as locationOneLineDesc
			,[LocationCity] as locationCity
			,[LocationStreet] as locationStreet
			,[LocationPostCode] as locationPostCode
			,[LocationCountry] as locationCountry
			,[Latitude] as latitude
			,[Longitude] as longitude
			,[EventGeolocation] as eventLocation
			,[Hares] as hares

			,[removed] as removed
			,[updatedAt] as updatedAt
		FROM HC.[HasherOwnEvent] where updatedAt > @ua and UserId = @userId
	END


END





GO
/****** Object:  Trigger [dbo].[TR_Hasher_InsertUpdateDelete]    Script Date: 11/26/19 8:02:11 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [dbo].[TR_Hasher_InsertUpdateDelete] ON [dbo].[Hasher] AFTER INSERT, UPDATE, DELETE AS BEGIN SET NOCOUNT ON; IF TRIGGER_NESTLEVEL() > 3 RETURN; UPDATE [dbo].[Hasher] SET [updatedAt] = CONVERT (DATETIMEOFFSET(7), SYSUTCDATETIME()) FROM INSERTED WHERE INSERTED.id = [dbo].[Hasher].[id] END
GO
ALTER TABLE [dbo].[Hasher] ENABLE TRIGGER [TR_Hasher_InsertUpdateDelete]
GO
/****** Object:  Trigger [dbo].[trgLoadFacebookEvents]    Script Date: 11/26/19 8:02:13 AM ******/
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
/****** Object:  Trigger [dbo].[trgCreateHasherRecord]    Script Date: 11/26/19 8:02:13 AM ******/
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
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForCountry]    Script Date: 11/26/19 8:02:13 AM ******/
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
/****** Object:  Trigger [HC].[trgCalculateHasherGeolocation]    Script Date: 11/26/19 8:02:13 AM ******/
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
/****** Object:  Trigger [HC].[trgGenerateQrCode]    Script Date: 11/26/19 8:02:13 AM ******/
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

		IF ((SELECT count(*) from HC.Hasher WHERE ResetCode = @ResetCode and id <> @id) > 0) OR (@ResetCode not like 'URC:%')
		BEGIN
			-- attempt to insert a duplicate QR was detected or the QR being inserted is invalid
			-- in these cases, create a new QR and insert that instead
			WHILE (@Loop = 'Yes')
			BEGIN
				SET @EmergencyStop = @EmergencyStop + 1
				IF @EmergencyStop > 10 SET @Loop = 'No'
				SET @QR = 'URC:'+SUBSTRING(TRIM(HC.NUMBER_TO_STR_BASE (25,(RAND() * (2147483647 - 91466177)) + 91466177)),0,7)
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

		IF ((SELECT count(*) from HC.Hasher WHERE SupportCode = @SupportCode and id <> @id) > 0) OR (@SupportCode not like 'USC:%')
		BEGIN
			-- attempt to insert a duplicate QR was detected or the QR being inserted is invalid
			-- in these cases, create a new QR and insert that instead
			WHILE (@Loop = 'Yes')
			BEGIN
				SET @EmergencyStop = @EmergencyStop + 1
				IF @EmergencyStop > 10 SET @Loop = 'No'
				SET @QR = 'USC:'+SUBSTRING(TRIM(HC.NUMBER_TO_STR_BASE (25,(RAND() * (2147483647 - 91466177)) + 91466177)),0,7)
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
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForNames]    Script Date: 11/26/19 8:02:13 AM ******/
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
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForHasherEventMap]    Script Date: 11/26/19 8:02:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TRIGGER [HC].[trgUpdateModifiedOnDateForHasherEventMap]
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
GO
ALTER TABLE [HC].[HasherEventMap] DISABLE TRIGGER [trgUpdateModifiedOnDateForHasherEventMap]
GO
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForHasherKennelMap]    Script Date: 11/26/19 8:02:14 AM ******/
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
/****** Object:  Trigger [HC].[GenerateExtApiKey]    Script Date: 11/26/19 8:02:14 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [HC].[GenerateExtApiKey]
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
	  UPDATE   HC.Kennel
	  SET      ExtApiKey = 
		HC.NUMBER_TO_STR_BASE(36,FLOOR(RAND()*2147483640))+HC.NUMBER_TO_STR_BASE(36,FLOOR(RAND()*2147483640))+HC.NUMBER_TO_STR_BASE(36,FLOOR(RAND()*2147483640))+
		HC.NUMBER_TO_STR_BASE(36,FLOOR(RAND()*2147483640))+HC.NUMBER_TO_STR_BASE(36,FLOOR(RAND()*2147483640))+HC.NUMBER_TO_STR_BASE(36,FLOOR(RAND()*2147483640))+
		HC.NUMBER_TO_STR_BASE(36,FLOOR(RAND()*2147483640))+HC.NUMBER_TO_STR_BASE(36,FLOOR(RAND()*2147483640))+HC.NUMBER_TO_STR_BASE(36,FLOOR(RAND()*2147483640))+
		HC.NUMBER_TO_STR_BASE(36,FLOOR(RAND()*2147483640))+HC.NUMBER_TO_STR_BASE(36,FLOOR(RAND()*2147483640))+HC.NUMBER_TO_STR_BASE(36,FLOOR(RAND()*2147483640))
		WHERE id = @id

		FETCH NEXT from xCrsr INTO @id
	END

CLOSE xCrsr
DEALLOCATE xCrsr

END


GO
ALTER TABLE [HC].[Kennel] ENABLE TRIGGER [GenerateExtApiKey]
GO
/****** Object:  Trigger [HC].[trgUpdateKennelGeolocation]    Script Date: 11/26/19 8:02:14 AM ******/
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
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForKennels]    Script Date: 11/26/19 8:02:14 AM ******/
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
/****** Object:  Trigger [HC].[trgUpdateModifiedOnDateForRegion]    Script Date: 11/26/19 8:02:14 AM ******/
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
/****** Object:  Index [IX_KennelSpatialIndex]    Script Date: 11/26/19 8:02:14 AM ******/
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
