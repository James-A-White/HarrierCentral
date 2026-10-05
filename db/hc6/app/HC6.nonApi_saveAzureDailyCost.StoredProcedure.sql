CREATE OR ALTER PROCEDURE [HC6].[nonApi_saveAzureDailyCost]
    @costsJson NVARCHAR(MAX) = NULL   -- [{"date":"2026-10-04","service":"SQL Database","cost":0.8310,"currency":"GBP"}, …]
AS
-- =====================================================================
-- Procedure: HC6.nonApi_saveAzureDailyCost
-- Description: Upserts Azure cost per UTC day per service into
--   LOG.AzureDailyCost (2026-10-05). The API's AzureDailyCost timer reads
--   Azure Cost Management every six hours and re-sends the last week,
--   because a day's figure keeps settling for about a day after it ends;
--   every row sent gets a fresh RetrievedAt, which is how the monitor
--   tells a settled day from one still filling in.
-- Returns: rowset 0 — { daysSaved, rowsSaved, firstDate, lastDate }
-- Author: Harrier Central
-- Created: 2026-10-05
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF @costsJson IS NULL OR ISJSON(@costsJson) = 0
BEGIN
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Azure cost save refused', 'costsJson missing or not JSON', OBJECT_NAME(@@PROCID), NULL);
    SELECT 0 AS daysSaved, 0 AS rowsSaved, NULL AS firstDate, NULL AS lastDate;
    RETURN;
END

BEGIN TRY
    DECLARE @rows TABLE (CostDate DATE NOT NULL, ServiceName NVARCHAR(100) NOT NULL,
                         Cost DECIMAL(10,4) NOT NULL, Currency CHAR(3) NOT NULL,
                         PRIMARY KEY (CostDate, ServiceName));
    -- Sum duplicates (Cost Management can split one service across rows).
    INSERT @rows (CostDate, ServiceName, Cost, Currency)
    SELECT j.[date], LEFT(COALESCE(NULLIF(j.service, ''), 'Unassigned'), 100),
           CAST(SUM(j.cost) AS DECIMAL(10,4)), MAX(LEFT(COALESCE(j.currency, '???'), 3))
    FROM OPENJSON(@costsJson)
         WITH ([date] DATE '$.date', service NVARCHAR(200) '$.service',
               cost FLOAT '$.cost', currency NVARCHAR(10) '$.currency') j
    WHERE j.[date] IS NOT NULL AND j.cost IS NOT NULL
    GROUP BY j.[date], LEFT(COALESCE(NULLIF(j.service, ''), 'Unassigned'), 100);

    BEGIN TRANSACTION;
    MERGE LOG.AzureDailyCost WITH (HOLDLOCK) AS t
    USING @rows AS s ON t.CostDate = s.CostDate AND t.ServiceName = s.ServiceName
    WHEN MATCHED THEN
        UPDATE SET Cost = s.Cost, Currency = s.Currency, RetrievedAt = SYSUTCDATETIME()
    WHEN NOT MATCHED THEN
        INSERT (CostDate, ServiceName, Cost, Currency) VALUES (s.CostDate, s.ServiceName, s.Cost, s.Currency);
    COMMIT TRANSACTION;

    SELECT COUNT(DISTINCT CostDate) AS daysSaved, COUNT(*) AS rowsSaved,
           MIN(CostDate) AS firstDate, MAX(CostDate) AS lastDate
    FROM @rows;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Unhandled error in saveAzureDailyCost', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), NULL);
    THROW;
END CATCH
GO
