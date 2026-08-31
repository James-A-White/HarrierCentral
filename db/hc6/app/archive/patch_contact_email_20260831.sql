-- =====================================================================
-- RUN-ONCE: connect@harriercentral.com -> harriercentral@gmail.com
--
-- The connect@ mailbox is non-functional (confirmed by James 2026-08-31),
-- and several procs tell users to write to it — including "your account
-- has been removed, contact us" paths, which strand people with no route
-- back in.
--
-- Patches each proc from its OWN LIVE DEFINITION rather than from the git
-- files: db/hc5 is an archived baseline that may have drifted from what is
-- actually deployed, and HC3/HC4/HC_BACKUP procs are not in git at all.
-- Only the email literal changes; everything else is byte-identical.
--
-- Old definitions are saved to HC.ProcBackup_20260831_ContactEmail.
-- Rollback for one proc:
--   DECLARE @s NVARCHAR(MAX) = (SELECT OldDefinition FROM
--     HC.ProcBackup_20260831_ContactEmail WHERE ProcName = '<name>');
--   -- convert leading CREATE to CREATE OR ALTER, then EXEC sp_executesql @s;
--
-- Dynamic SQL is used deliberately here. The "no dynamic SQL, ever" rule
-- governs stored procedure bodies; this is a one-off maintenance script.
-- =====================================================================
SET NOCOUNT ON;
SET LOCK_TIMEOUT 15000;

DECLARE @OLD NVARCHAR(50) = N'connect@harriercentral.com';
DECLARE @NEW NVARCHAR(50) = N'harriercentral@gmail.com';

IF OBJECT_ID('HC.ProcBackup_20260831_ContactEmail') IS NULL
    CREATE TABLE HC.ProcBackup_20260831_ContactEmail (
        object_id     INT PRIMARY KEY,
        SchemaName    SYSNAME,
        ProcName      SYSNAME,
        OldDefinition NVARCHAR(MAX),
        BackedUpAt    DATETIME2(3) NOT NULL DEFAULT SYSUTCDATETIME());

INSERT HC.ProcBackup_20260831_ContactEmail (object_id, SchemaName, ProcName, OldDefinition)
SELECT m.object_id, SCHEMA_NAME(o.schema_id), o.name, m.definition
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%' + @OLD + '%'
  AND NOT EXISTS (SELECT 1 FROM HC.ProcBackup_20260831_ContactEmail b
                  WHERE b.object_id = m.object_id);

PRINT 'Backed up: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' proc definitions.';

DECLARE @id INT, @def NVARCHAR(MAX), @newdef NVARCHAR(MAX), @nm NVARCHAR(300), @p INT;
DECLARE @objname SYSNAME, @defname SYSNAME;
DECLARE @ok INT = 0, @skipped INT = 0, @failed INT = 0;
DECLARE @problems TABLE (nm NVARCHAR(300), reason NVARCHAR(1000));

-- Snapshot FIRST. Cursoring over sys.sql_modules while altering the very
-- procs it scans makes the set shift underneath and silently skips rows.
SELECT m.object_id, m.definition AS def,
       QUOTENAME(SCHEMA_NAME(o.schema_id)) + '.' + QUOTENAME(o.name) AS nm,
       o.name AS objname
INTO #targets
FROM sys.sql_modules m
JOIN sys.objects o ON o.object_id = m.object_id
WHERE m.definition LIKE '%' + @OLD + '%' AND o.type = 'P';

DECLARE c CURSOR LOCAL FAST_FORWARD FOR
    SELECT object_id, def, nm, objname FROM #targets;

OPEN c;
FETCH NEXT FROM c INTO @id, @def, @nm, @objname;
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @newdef = REPLACE(@def, @OLD, @NEW);
    SET @p = CHARINDEX('CREATE', @newdef);

    -- Guard: the first CREATE must actually introduce the procedure.
    IF @p = 0 OR CHARINDEX('PROC', @newdef, @p) = 0 OR CHARINDEX('PROC', @newdef, @p) - @p > 40
    BEGIN
        INSERT @problems VALUES (@nm, 'Could not locate CREATE PROCEDURE header safely');
        SET @skipped += 1;
    END
    ELSE
    BEGIN
        -- sp_rename does NOT rewrite the definition text, so a renamed proc
        -- still declares its ORIGINAL name. Executing that as CREATE OR ALTER
        -- would create a stray proc under the old name and leave the real one
        -- untouched. Correct the header to the object's actual name first.
        SET @defname = PARSENAME(SUBSTRING(@newdef, CHARINDEX('PROC', @newdef),
                                           CHARINDEX(CHAR(13), @newdef + CHAR(13),
                                                     CHARINDEX('PROC', @newdef))
                                           - CHARINDEX('PROC', @newdef)), 1);
        IF @defname IS NOT NULL AND @defname <> @objname
            SET @newdef = REPLACE(@newdef, QUOTENAME(@defname), QUOTENAME(@objname));

        IF SUBSTRING(@newdef, @p, 15) <> 'CREATE OR ALTER'
            SET @newdef = STUFF(@newdef, @p, 6, 'CREATE OR ALTER');
        BEGIN TRY
            EXEC sp_executesql @newdef;
            SET @ok += 1;
        END TRY
        BEGIN CATCH
            INSERT @problems VALUES (@nm, ERROR_MESSAGE());
            SET @failed += 1;
        END CATCH
    END
    FETCH NEXT FROM c INTO @id, @def, @nm, @objname;
END
CLOSE c; DEALLOCATE c;

PRINT 'Patched: ' + CAST(@ok AS VARCHAR(10))
    + '  Skipped: ' + CAST(@skipped AS VARCHAR(10))
    + '  Failed: '  + CAST(@failed AS VARCHAR(10));

SELECT nm AS ProblemProc, reason AS Reason FROM @problems;

SELECT COUNT(*) AS ProcsStillContainingOldAddress
FROM sys.sql_modules WHERE definition LIKE '%' + @OLD + '%';
