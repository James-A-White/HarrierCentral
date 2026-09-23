-- =====================================================================
-- Run-once: widen HC.EventMessage.MessageContent from NVARCHAR(500) to
-- NVARCHAR(4000). 2026-09-23.
--
-- Why: the first announcement in the Harrier Central Admins room was cut at
-- exactly 500 characters. Every send SP declared @messageContent
-- NVARCHAR(500) — and SQL Server silently truncates a parameter to its
-- declared width, so nothing failed and nothing was logged. The SPs now take
-- NVARCHAR(MAX) and REFUSE anything over 4,000 with an error envelope; this
-- script makes the column match. Run it BEFORE deploying the SPs (an insert
-- longer than the column would throw "string or binary data would be
-- truncated" — an error at least, but an ugly one).
--
-- Widening an NVARCHAR column is a metadata-only change: no rewrite, no
-- lock of consequence. HC.EventMessage has no UpdatedAt trigger, and its two
-- triggers are DML (insert/update/delete) — ALTER TABLE does not fire them.
-- Archive to db/hc6/app/archive/ once run.
-- =====================================================================
ALTER TABLE HC.EventMessage ALTER COLUMN MessageContent NVARCHAR(4000) NOT NULL;
GO
SELECT COLUMNPROPERTY(OBJECT_ID('HC.EventMessage'), 'MessageContent', 'charmaxlen') AS MessageContentMaxLen; -- expect 4000
GO
