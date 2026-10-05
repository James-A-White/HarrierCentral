CREATE OR ALTER PROCEDURE [HC6].[nonApi_recordRunsPageJob]
    @startedAt            DATETIMEOFFSET(7) = NULL,
    @runsFound            INT               = 0,   -- runs the model read off the pages
    @runsInserted         INT               = 0,   -- new HC runs
    @runsUpdated          INT               = 0,   -- imported runs refreshed
    @errorCount           INT               = 0,
    @errorInfo            NVARCHAR(MAX)     = NULL,
    @kennelsSucceeded     INT               = 0,
    @kennelsSucceededInfo NVARCHAR(MAX)     = NULL,
    @kennelsFailed        INT               = 0,
    @kennelsFailedInfo    NVARCHAR(MAX)     = NULL
AS
-- =====================================================================
-- Procedure: HC6.nonApi_recordRunsPageJob
-- Description: One HC.IntegrationJob row (IntegrationId 6, "Runs page")
--   per runs-page import — a timer run, an "import now", or a portal Test
--   that imported (2026-10-05). It feeds the AI tile on the portal's Usage
--   Data monitor, which replaced the Facebook tile (James, 2026-10-05).
--
--   For integration 6 the columns mean:
--     RecordsRead        runs the model found
--     RecordsWritten     runs inserted + runs updated
--     RecordsSuccessInfo '<inserted>|<updated>' — machine-read by
--                        hcportal_getUsageData for the 14-day split. This
--                        SP is the only writer; change both together.
-- Returns: nothing.
-- Author: Harrier Central
-- Created: 2026-10-05
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @seq INT = (SELECT COALESCE(MAX(SequenceNumber), 0) + 1
                        FROM HC.IntegrationJob WITH (UPDLOCK, HOLDLOCK) WHERE IntegrationId = 6);
    -- RecordsRead/Written etc. are SMALLINT on HC.IntegrationJob.
    INSERT HC.IntegrationJob (IntegrationId, SequenceNumber, RecordsRead, RecordsWritten,
                              RecordsSuccessInfo, RecordsFailedInfo, ErrorCount, ErrorInfo,
                              KennelsSucceeded, KennelsSucceededInfo, KennelsFailed, KennelsFailedInfo,
                              startedAt, endedAt)
    VALUES (6, @seq,
            CAST(LEAST(COALESCE(@runsFound, 0), 32767) AS SMALLINT),
            CAST(LEAST(COALESCE(@runsInserted, 0) + COALESCE(@runsUpdated, 0), 32767) AS SMALLINT),
            CONCAT(COALESCE(@runsInserted, 0), '|', COALESCE(@runsUpdated, 0)),
            NULL,
            CAST(LEAST(COALESCE(@errorCount, 0), 32767) AS SMALLINT),
            LEFT(@errorInfo, 4000),
            CAST(LEAST(COALESCE(@kennelsSucceeded, 0), 32767) AS SMALLINT),
            LEFT(@kennelsSucceededInfo, 4000),
            CAST(LEAST(COALESCE(@kennelsFailed, 0), 32767) AS SMALLINT),
            LEFT(@kennelsFailedInfo, 4000),
            COALESCE(@startedAt, SYSDATETIMEOFFSET()),
            SYSDATETIMEOFFSET());
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Unhandled error in recordRunsPageJob', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), NULL);
    THROW;
END CATCH
GO
