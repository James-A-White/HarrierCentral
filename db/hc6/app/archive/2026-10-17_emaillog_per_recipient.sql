-- Run-once schema change (James, 2026-10-17: "modify the email table to
-- accept non run emails"; columns agreed one by one). HC.EmailLog becomes the
-- log of emails Harrier Central sends: one row per RECIPIENT for new kinds
-- (first: the app-version upgrade email, E19.F3.S3). The 8 legacy rows
-- (HC3 run emails, 2020-2021, one row per send) keep their shape: UserId NULL,
-- NumberSent = the count. Rules about repeats (e.g. "not within 30 days") are
-- NOT in the table — each kind applies its own in its queries.
-- Not a synced table (no trigger), so no trigger dance. Idempotent.
SET NOCOUNT ON;

ALTER TABLE HC.EmailLog ALTER COLUMN EventId UNIQUEIDENTIFIER NULL;
ALTER TABLE HC.EmailLog ALTER COLUMN EmailTemplaterId UNIQUEIDENTIFIER NULL;

IF COL_LENGTH('HC.EmailLog', 'SendId')       IS NULL ALTER TABLE HC.EmailLog ADD SendId UNIQUEIDENTIFIER NULL;
IF COL_LENGTH('HC.EmailLog', 'UserId')       IS NULL ALTER TABLE HC.EmailLog ADD UserId UNIQUEIDENTIFIER NULL;
IF COL_LENGTH('HC.EmailLog', 'EmailKind')    IS NULL ALTER TABLE HC.EmailLog ADD EmailKind SMALLINT NULL;
IF COL_LENGTH('HC.EmailLog', 'Status')       IS NULL ALTER TABLE HC.EmailLog ADD Status SMALLINT NULL;
IF COL_LENGTH('HC.EmailLog', 'Subject')      IS NULL ALTER TABLE HC.EmailLog ADD Subject NVARCHAR(250) NULL;
IF COL_LENGTH('HC.EmailLog', 'SentByUserId') IS NULL ALTER TABLE HC.EmailLog ADD SentByUserId UNIQUEIDENTIFIER NULL;
IF COL_LENGTH('HC.EmailLog', 'AuditPath')    IS NULL ALTER TABLE HC.EmailLog ADD AuditPath NVARCHAR(400) NULL;
GO

IF OBJECT_ID('HC.FK_EmailLog_Hasher') IS NULL
    ALTER TABLE HC.EmailLog ADD CONSTRAINT FK_EmailLog_Hasher FOREIGN KEY (UserId) REFERENCES HC.Hasher (id);
IF OBJECT_ID('HC.FK_EmailLog_SentBy') IS NULL
    ALTER TABLE HC.EmailLog ADD CONSTRAINT FK_EmailLog_SentBy FOREIGN KEY (SentByUserId) REFERENCES HC.Hasher (id);

-- One send records a person once: a retry or a double click finds the row.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_EmailLog_Send_User' AND object_id = OBJECT_ID('HC.EmailLog'))
    CREATE UNIQUE NONCLUSTERED INDEX UQ_EmailLog_Send_User ON HC.EmailLog (SendId, UserId)
        WHERE SendId IS NOT NULL AND UserId IS NOT NULL;
-- What has this person been sent, of what kind, and when.
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_EmailLog_Kind_User_Date' AND object_id = OBJECT_ID('HC.EmailLog'))
    CREATE NONCLUSTERED INDEX IX_EmailLog_Kind_User_Date ON HC.EmailLog (EmailKind, UserId, DateSent) INCLUDE (Status);
GO

-- Column notes live in the database (MS_Description), not the schema file.
DECLARE @d TABLE (col SYSNAME, txt NVARCHAR(500));
INSERT @d VALUES
 ('EventId',          N'The run, for a run email; NULL for other kinds (since 2026-10-17).'),
 ('EmailTemplaterId', N'The HC.EmailTemplate used (legacy HC3 run emails); NULL for other kinds (since 2026-10-17).'),
 ('NumberSent',       N'Legacy rows: how many the send reached. Per-recipient rows: 1.'),
 ('SendId',           N'Client-minted id of one press of Send; with UserId unique, so a retried send never mails a person twice.'),
 ('UserId',           N'The recipient (one row per recipient). NULL on the legacy one-row-per-send HC3 rows.'),
 ('EmailKind',        N'What was sent: 2 = app version upgrade (E19.F3.S3). Each kind applies its own repeat rules in its queries, never here.'),
 ('Status',           N'0 queued (recorded before the send), 1 sent, 2 failed (reason in ServerReply).'),
 ('Subject',          N'The subject as sent.'),
 ('SentByUserId',     N'The admin who pressed Send.'),
 ('AuditPath',        N'Path of the full email (HTML, text, recipients) in the private email-audit blob container.');
DECLARE @c SYSNAME, @t NVARCHAR(500);
DECLARE cur CURSOR LOCAL FAST_FORWARD FOR SELECT col, txt FROM @d;
OPEN cur; FETCH NEXT FROM cur INTO @c, @t;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE major_id = OBJECT_ID('HC.EmailLog') AND name = 'MS_Description'
               AND minor_id = COLUMNPROPERTY(OBJECT_ID('HC.EmailLog'), @c, 'ColumnId'))
        EXEC sp_updateextendedproperty 'MS_Description', @t, 'SCHEMA', 'HC', 'TABLE', 'EmailLog', 'COLUMN', @c;
    ELSE
        EXEC sp_addextendedproperty 'MS_Description', @t, 'SCHEMA', 'HC', 'TABLE', 'EmailLog', 'COLUMN', @c;
    FETCH NEXT FROM cur INTO @c, @t;
END
CLOSE cur; DEALLOCATE cur;
SELECT COUNT(*) AS legacyRows FROM HC.EmailLog;
