-- =====================================================================
-- Function: HC6.ClientLogAppError
-- Description: The single definition of "this uploaded client session
--   contained an APP error", shared by the Usage Data dashboard row
--   (hcportal_getUsageData) and its drill-down (hcportal_getCategoryDetail2).
--   Returns the first qualifying line, or NULL when the session has none.
--
--   Counts as an app error:
--     • an [ERROR][ASYNC] entry — an uncaught Dart exception;
--     • an [ERROR][FLUTTER] entry that is not a transport exception — a
--       framework error in our widgets. HttpException / ClientException /
--       SocketException / DioException [connection error] are the image
--       loader or an upload failing on the network, not the app;
--     • a MetricKit payload whose "kind" is anything but the routine
--       "metric" (crash, hang, diskWriteException…).
--   Deliberately NOT counted: [ERROR][HTTP] timeouts / 599 / transport
--   failures, [TRACE] breadcrumbs, and controller-tagged network timeouts
--   that happen to carry a stack. Those are the phone's connection.
--
--   MetricKit payloads from builds before 1292 arrive as fragments, so
--   a [METRICKIT] row without a "kind" is an old fragment and is ignored.
-- Parameters: @log - HC.ClientErrorLog.ErrorLog
-- Returns: NVARCHAR(300) first app-error line, or NULL
-- Author: Harrier Central
-- Created: 2026-09-09
-- =====================================================================
CREATE OR ALTER FUNCTION [HC6].[ClientLogAppError] (@log NVARCHAR(MAX))
RETURNS NVARCHAR(300)
WITH SCHEMABINDING
AS
BEGIN
    IF @log IS NULL RETURN NULL;

    -- MetricKit diagnostic
    IF LEFT(@log, 11) = '[METRICKIT]'
    BEGIN
        DECLARE @k INT = CHARINDEX('"kind"', @log);
        IF @k = 0 RETURN NULL;                                   -- pre-1292 fragment
        DECLARE @q1 INT = CHARINDEX('"', @log, @k + 6);          -- opening quote of the value
        DECLARE @q2 INT = CHARINDEX('"', @log, @q1 + 1);
        IF @q1 = 0 OR @q2 = 0 RETURN NULL;
        DECLARE @kind NVARCHAR(50) = SUBSTRING(@log, @q1 + 1, @q2 - @q1 - 1);
        IF @kind = 'metric' RETURN NULL;
        RETURN 'MetricKit ' + @kind;
    END

    -- Session log: walk the [ERROR][…] lines
    DECLARE @len INT = LEN(@log);
    DECLARE @pos INT = CHARINDEX('[ERROR][', @log);
    DECLARE @eol INT;
    DECLARE @line NVARCHAR(4000);
    WHILE @pos > 0
    BEGIN
        SET @eol = CHARINDEX(CHAR(10), @log, @pos);
        IF @eol = 0 SET @eol = @len + 1;
        SET @line = SUBSTRING(@log, @pos, @eol - @pos);
        IF @line LIKE '[[]ERROR][[]ASYNC]%'
           OR (@line LIKE '[[]ERROR][[]FLUTTER]%'
               AND @line NOT LIKE '[[]ERROR][[]FLUTTER] HttpException%'
               AND @line NOT LIKE '[[]ERROR][[]FLUTTER] ClientException%'
               AND @line NOT LIKE '[[]ERROR][[]FLUTTER] SocketException%'
               AND @line NOT LIKE '[[]ERROR][[]FLUTTER] DioException [[]connection error]%')
            RETURN LEFT(@line, 300);
        SET @pos = CHARINDEX('[ERROR][', @log, @eol);
    END
    RETURN NULL;
END
GO
