-- Run-once (James, 2026-10-17): retire HC6.hcapp_logAppError. Nothing calls the HC6 copy
-- (the 2.x app calls its HC5 copy, which stays until the 2.x clean-up,
-- E16.F2.S5). The source and contract are kept in db/deprecated/.
IF OBJECT_ID('HC6.hcapp_logAppError', 'P') IS NOT NULL DROP PROCEDURE HC6.hcapp_logAppError;
SELECT CASE WHEN OBJECT_ID('HC6.hcapp_logAppError', 'P') IS NULL THEN 'dropped' ELSE 'STILL THERE' END AS result;
