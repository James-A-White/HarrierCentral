CREATE OR ALTER PROCEDURE [HC6].[nonApi_logPushBatch]
    @batchId         UNIQUEIDENTIFIER,
    @sentAt          DATETIMEOFFSET(7),
    @queryType       NVARCHAR(100),
    @eventId         UNIQUEIDENTIFIER = NULL,
    @recipientUserId UNIQUEIDENTIFIER = NULL,
    @fcmToken        NVARCHAR(500),
    @isVisible       SMALLINT,
    @summary         NVARCHAR(500)    = NULL,
    @senderUserId    UNIQUEIDENTIFIER = NULL,
    @fcmResult       NVARCHAR(50)     = NULL
AS
-- =====================================================================
-- Procedure: HC6.nonApi_logPushBatch
-- Description: Inserts a single FCM push audit entry into HC.PushLog.
--   AppApiHC6.LogPushBatchAsync calls this once per recipient per push
--   batch. Non-fatal — callers swallow errors from this SP.
--   HC.PushLog.IsVisible is BIT; @isVisible is SMALLINT per the
--   no-BIT-parameters rule; SQL Server converts implicitly.
-- Parameters:
--   @batchId         - Shared GUID for all entries in this push batch.
--   @sentAt          - UTC timestamp when the batch was dispatched.
--   @queryType       - HC6 queryType that triggered the push batch.
--   @eventId         - Event UUID associated with the push (nullable).
--   @recipientUserId - Recipient hasher UUID (nullable).
--   @fcmToken        - FCM registration token used for this push.
--   @isVisible       - 1 = visible push (alert), 0 = data-only silent push.
--   @summary         - Short description for dashboard review (nullable).
--   @senderUserId    - Sending hasher UUID (nullable).
--   @fcmResult       - FCM HTTP API result string (nullable).
-- Returns: Nothing. Fire-and-forget helper.
-- Author: Harrier Central
-- Created: 2026-06-15
-- HC5 Source: AppApiHC6.LogPushBatchAsync inline SQL
-- =====================================================================
SET NOCOUNT ON;

INSERT INTO HC.PushLog
    (Id, BatchId, SentAt, QueryType, EventId, RecipientUserId,
     FcmToken, IsVisible, Summary, SenderUserId, FcmResult)
VALUES
    (NEWID(), @batchId, @sentAt, @queryType, @eventId, @recipientUserId,
     @fcmToken, @isVisible, @summary, @senderUserId, @fcmResult);
