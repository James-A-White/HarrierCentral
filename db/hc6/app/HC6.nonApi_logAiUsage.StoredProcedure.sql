CREATE OR ALTER PROCEDURE [HC6].[nonApi_logAiUsage]
    @sessionId        UNIQUEIDENTIFIER = NULL,
    @feature          NVARCHAR(MAX)    = NULL,
    @kennelId         UNIQUEIDENTIFIER = NULL,
    @model            NVARCHAR(MAX)    = NULL,
    @promptTokens     INT              = 0,
    @completionTokens INT              = 0,
    @costUsd          DECIMAL(12,8)    = NULL,
    @durationMs       INT              = NULL,
    @outcome          NVARCHAR(MAX)    = NULL,
    @detail           NVARCHAR(MAX)    = NULL
AS
-- =====================================================================
-- Procedure: HC6.nonApi_logAiUsage
-- Description: Records one AI model call in LOG.AiUsage (2026-10-05) —
--   tokens, USD cost, time taken and outcome — so AI spend can be tracked
--   per call, per session (@sessionId: one timer run or one portal Test)
--   and on the portal's Usage Data monitor ('AI Tokens'). Failed calls are
--   logged too, with whatever tokens were billed (usually 0).
--   Called by the API (RunsPageImport). Text parameters are NVARCHAR(MAX)
--   and cut to the column here, so an over-long value is trimmed rather
--   than refused.
-- Returns: nothing.
-- Author: Harrier Central
-- Created: 2026-10-05
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    INSERT LOG.AiUsage (SessionId, Feature, KennelId, Model, PromptTokens, CompletionTokens,
                        CostUsd, DurationMs, Outcome, Detail)
    VALUES (@sessionId,
            LEFT(COALESCE(NULLIF(@feature, ''), 'unknown'), 50),
            @kennelId,
            LEFT(COALESCE(NULLIF(@model, ''), 'unknown'), 100),
            COALESCE(@promptTokens, 0),
            COALESCE(@completionTokens, 0),
            @costUsd,
            @durationMs,
            LEFT(COALESCE(NULLIF(@outcome, ''), 'unknown'), 50),
            LEFT(@detail, 500));
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<api>', 'Unhandled error in logAiUsage', ERROR_MESSAGE(), OBJECT_NAME(@@PROCID), NULL);
    THROW;
END CATCH
GO
