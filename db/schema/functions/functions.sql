/****** Object:  UserDefinedFunction [HC].[CHECK_ACCESS_TOKEN_V2]    Script Date: 3/15/2026 8:40:34 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [HC].[CHECK_ACCESS_TOKEN_V2] 
	(
		@userId uniqueidentifier, 
		@procName nvarchar(100), 
		@accessToken nvarchar(1000), 
		@paramString nvarchar(500),
		@timeWindow int
	)
RETURNS int
WITH EXECUTE AS CALLER
AS
BEGIN  
 -- Check three tokens... the one generated for this point in time and the previous and next codes.   
 -- This allows the clock on the user's phone to be off by a small bit of time and yet still   
 -- produce a good access code. It also covers the case where an access code takes time to travel   
 -- through the network to reach the server and may be expired by the time it arrives. This also   
 -- helps cover cases where the division and rounding to INT on the server produces a different  
 -- number than the division that occurs on the client.  
 DECLARE @generatedToken nvarchar(2000)  
 DECLARE @try5760 int = 0
 
 -- Uncomment the lines below to disable access token checks  
 -- SELECT GETDATE()
 IF (DATEADD(minute,-120,getdate()) < '2025-11-24 20:34:47.850') 
 BEGIN
	RETURN 1
 END
 
 IF ((@accessToken is null) OR (datalength(@accessToken) < 50))   
 BEGIN  
  -- fail if Access token is null or does not have the correct amount of characters  
  -- return 0 to indicate failure  
  RETURN 0 
 END  

 DECLARE @baseDate datetime = '25 Jul 1993 15:00'
   
 SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,0,@paramString,@timeWindow,@baseDate)  
 if @generatedToken != @accessToken  
 BEGIN  
  SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,1,@paramString,@timeWindow,@baseDate)  
  if @generatedToken != @accessToken  
  BEGIN  
   SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,-1,@paramString,@timeWindow,@baseDate)    
   if @generatedToken != @accessToken  
   BEGIN  
    SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,2,@paramString,@timeWindow,@baseDate)    
    if @generatedToken != @accessToken  
    BEGIN  
     SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,-2,@paramString,@timeWindow,@baseDate)    
     if @generatedToken != @accessToken  
     BEGIN  
		RETURN 0
	 END  
    END  
   END  
  END  
 END  

 RETURN 1  
END  
GO
/****** Object:  UserDefinedFunction [HC].[CHECK_PORTAL_ACCESS_TOKEN]    Script Date: 3/15/2026 8:40:34 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [HC].[CHECK_PORTAL_ACCESS_TOKEN] 
	(
		@userId uniqueidentifier, 
		@procName nvarchar(100), 
		@accessToken nvarchar(1000), 
		@paramString nvarchar(500)
	)
RETURNS int
WITH EXECUTE AS CALLER
AS
BEGIN  
 -- Check three tokens... the one generated for this point in time and the previous and next codes.   
 -- This allows the clock on the user's phone to be off by a small bit of time and yet still   
 -- produce a good access code. It also covers the case where an access code takes time to travel   
 -- through the network to reach the server and may be expired by the time it arrives. This also   
 -- helps cover cases where the division and rounding to INT on the server produces a different  
 -- number than the division that occurs on the client.  
 DECLARE @generatedToken nvarchar(2000)  
 DECLARE @try69 int = 0

 -- SELECT getdate()
 -- Uncomment the lines below to disable access token checks  SELECT GETDATE()
 IF (DATEADD(minute,-120,getdate()) < '2026-02-08 07:31:57.930') 
 BEGIN
	RETURN 1
 END
 
 IF ((@accessToken is null) OR (datalength(@accessToken) < 50))   
 BEGIN  
  -- fail if Access token is null or does not have the correct amount of characters  
  -- return 0 to indicate failure  
  RETURN 0 
 END  

 DECLARE @baseDate datetime = '15 AUG 1963 9:52:28 AM'
 DECLARE @timeWindow int = 86469
   
 SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,0,@paramString,@timeWindow,@baseDate)  
 if @generatedToken != @accessToken  
 BEGIN  
  SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,1,@paramString,@timeWindow,@baseDate)  
  if @generatedToken != @accessToken  
  BEGIN  
   SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,-1,@paramString,@timeWindow,@baseDate)    
   if @generatedToken != @accessToken  
   BEGIN  
    SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,2,@paramString,@timeWindow,@baseDate)    
    if @generatedToken != @accessToken  
    BEGIN  
     SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,-2,@paramString,@timeWindow,@baseDate)    
     if @generatedToken != @accessToken  
     BEGIN  
		SET @try69 = 1
     END  
    END  
   END  
  END  
 END  

 SET @timeWindow = 69

 IF (@try69 = 1)
 BEGIN
  SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,0,@paramString,@timeWindow,@baseDate)  
	 if @generatedToken != @accessToken  
	 BEGIN  
	  SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,1,@paramString,@timeWindow,@baseDate)  
	  if @generatedToken != @accessToken  
	  BEGIN  
	   SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,-1,@paramString,@timeWindow,@baseDate)    
	   if @generatedToken != @accessToken  
	   BEGIN  
		SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,2,@paramString,@timeWindow,@baseDate)    
		if @generatedToken != @accessToken  
		BEGIN  
		 SET @generatedToken = HC.CREATE_ACCESS_TOKEN_V2(@userid,@procName,-2,@paramString,@timeWindow,@baseDate)    
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
GO
/****** Object:  UserDefinedFunction [HC].[CREATE_ACCESS_TOKEN_V2]    Script Date: 3/15/2026 8:40:34 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [HC].[CREATE_ACCESS_TOKEN_V2] 
	(
		 @userId uniqueidentifier
		,@procName varchar(500)
		,@offset int
		,@paramString nvarchar(500)
		,@timeWindow int
		,@baseDate datetime
	)
RETURNS varchar(MAX)
WITH EXECUTE AS CALLER
AS
BEGIN
	declare @bin as varbinary(max)

	if @paramString IS NOT NULL SET @paramString = upper('#'+@paramString)

	--return upper(cast(@userId as nvarchar(50))) + '#'+@procName+'#' + cast((cast(datediff(second,'25 Jul 1993 15:00',GETUTCDATE()) / 5760 as int)+@offset) as nvarchar(50))
	DECLARE @str as varchar(2000)
	--SET @str = upper(cast(@userId as varchar(50))) + '#'+@procName+'#' + cast((cast(datediff(second,'25 Jul 1993 15:00',GETUTCDATE()) / @timeWindow as int)+@offset) as varchar(50)) + coalesce(@paramString,'')
	SET @str = upper(cast(@userId as varchar(50)) + '#'+@procName+'#' + cast((cast(datediff(second,@baseDate,GETUTCDATE()) / @timeWindow as int)+@offset) as varchar(50)) + coalesce(@paramString,''))
	SET @bin = HASHBYTES('SHA2_256',@str)
	return cast('' as xml).value('xs:hexBinary(sql:variable("@bin"))', 'varchar(max)')
END


GO
