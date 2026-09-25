-- =====================================================================
-- RUN-ONCE: remove the '$^' placeholder from run descriptions (2026-09-25).
--
-- The app's Add Run page pre-filled a new run's description with '$^' (its
-- currency-symbol placeholder), which also satisfied the required-
-- description check, so it was saved: 30 live runs have '$^' as the whole
-- description, 25 more start with it before the real text. Fixed in the
-- app on dev (bcb36a03); this cleans what was already saved.
--
--   exactly '$^'       -> NULL (what the SP stores for an empty description)
--   '$^' + real text   -> the real text, leading spaces trimmed
--
-- Only HC.Event.EventDescription changes. trgUpdateModifiedOnDateForEvent
-- stamps updatedAt, so each run re-syncs to phones once with the clean
-- text (55 rows). trgRecalculateRunCounts acts only on start time,
-- IsCountedRun and AbsoluteEventNumber, so it does nothing here.
--
-- Idempotent. After running: move this file to db/hc6/app/archive/.
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;

SELECT 'before' AS stage,
       SUM(CASE WHEN EventDescription = N'$^' THEN 1 ELSE 0 END) AS exactPlaceholder,
       SUM(CASE WHEN EventDescription LIKE N'$^_%' THEN 1 ELSE 0 END) AS leadingPlaceholder,
       SUM(CASE WHEN EventDescription LIKE N'%$^%' THEN 1 ELSE 0 END) AS anyPlaceholder
FROM HC.Event;

BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE HC.Event
       SET EventDescription = NULL
     WHERE EventDescription = N'$^';
    SELECT @@ROWCOUNT AS clearedExact;

    UPDATE HC.Event
       SET EventDescription = NULLIF(LTRIM(SUBSTRING(EventDescription, 3, 4000)), N'')
     WHERE EventDescription LIKE N'$^_%';
    SELECT @@ROWCOUNT AS strippedLeading;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;   -- FIRST: the log must survive
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (NEWID(), '<unknown>', 'Run-once $^ description clean-up failed',
            ERROR_MESSAGE(), '2026-09-25_clean_dollar_caret_descriptions', NULL);
    THROW;
END CATCH

SELECT 'after' AS stage,
       SUM(CASE WHEN EventDescription LIKE N'%$^%' THEN 1 ELSE 0 END) AS anyPlaceholder
FROM HC.Event;
