-- =====================================================================
-- Run-once: Create TSA schema
-- Run this BEFORE deploying tables and stored procedures.
-- =====================================================================

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'TSA')
BEGIN
    EXEC('CREATE SCHEMA [TSA]')
    PRINT 'Schema [TSA] created.'
END
ELSE
BEGIN
    PRINT 'Schema [TSA] already exists — skipped.'
END
