-- =====================================================================
-- Run-once migration: add SenderUserId and FcmResult to HC.PushLog
--
-- SenderUserId: the hasher who triggered the push.
--   For sendEventMessage: the chat message author (stored as PublicHasherId).
--   For selectSong / markEventChatRead: NULL (no meaningful sender).
--
-- FcmResult: outcome of the FCM dispatch call.
--   Values: 'success', 'token_error', 'error', 'exception', or NULL
--   (NULL = logged before result-capture was implemented).
--
-- After executing, move this file to archive/.
-- =====================================================================

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'HC' AND TABLE_NAME = 'PushLog' AND COLUMN_NAME = 'SenderUserId'
)
BEGIN
    ALTER TABLE [HC].[PushLog]
    ADD [SenderUserId] UNIQUEIDENTIFIER NULL;
    PRINT 'HC.PushLog.SenderUserId added.';
END
ELSE
BEGIN
    PRINT 'HC.PushLog.SenderUserId already exists — skipped.';
END

IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'HC' AND TABLE_NAME = 'PushLog' AND COLUMN_NAME = 'FcmResult'
)
BEGIN
    ALTER TABLE [HC].[PushLog]
    ADD [FcmResult] NVARCHAR(50) NULL;
    PRINT 'HC.PushLog.FcmResult added.';
END
ELSE
BEGIN
    PRINT 'HC.PushLog.FcmResult already exists — skipped.';
END
