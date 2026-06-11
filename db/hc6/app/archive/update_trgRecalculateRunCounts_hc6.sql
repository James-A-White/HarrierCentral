-- =====================================================================
-- Run-once migration: point trgRecalculateRunCounts at HC6.nonApi_updateRunNumbers
--
-- Run this AFTER deploying HC6.nonApi_updateRunNumbers via deploy_hc6.sh.
-- Archive this file to db/hc6/app/archive/ once executed.
-- =====================================================================

ALTER TRIGGER [HC].[trgRecalculateRunCounts] ON [HC].[Event]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Set EventStartDatetimeIndexed based on which datetime is active for the run.
    -- This must run before the run-number recalculation below.
    IF (UPDATE(UseFbRunDetails) OR UPDATE(EventStartDateTime) OR UPDATE(FbEventStartDateTime))
    BEGIN
        SET NOCOUNT ON;
        UPDATE evt
            SET EventStartDatetimeIndexed =
                CASE WHEN (ins.UseFbRunDetails = 1)
                     THEN CONVERT(datetime2, ins.FbEventStartDatetime)
                     ELSE CONVERT(datetime2, ins.EventStartDatetime)
                END
            FROM HC.Event evt
            INNER JOIN Inserted ins ON evt.id = ins.id;
    END

    IF (UPDATE(IsCountedRun) OR UPDATE(AbsoluteEventNumber))
    BEGIN
        DECLARE @eid UNIQUEIDENTIFIER;
        SELECT TOP 1 @eid = id FROM inserted ORDER BY EventStartDatetime ASC;
        EXEC [HC6].[nonApi_updateRunNumbers] @eventId = @eid;
    END

END
GO
