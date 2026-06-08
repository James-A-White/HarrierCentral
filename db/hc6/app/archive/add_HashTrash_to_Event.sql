-- =====================================================================
-- Run-once: Add HashTrash columns to HC.Event
-- Description: Adds HashTrashHeadline, HashTrashContent, HashTrashStatus
--   to HC.Event for the HashTrash feature. Both triggers are disabled
--   before the ALTER to prevent them from stamping updatedAt on every
--   existing row and forcing a full client re-sync.
-- Author: Harrier Central
-- Created: 2026-06-08
-- ARCHIVE AFTER RUNNING — do not leave alongside deployable SPs.
-- =====================================================================

DISABLE TRIGGER [HC].[trgRecalculateRunCounts] ON [HC].[Event];
DISABLE TRIGGER [HC].[trgReplaceBrackets]       ON [HC].[Event];

ALTER TABLE [HC].[Event]
    ADD [HashTrashHeadline] NVARCHAR(500) NULL,
        [HashTrashContent]  NVARCHAR(MAX) NULL,
        [HashTrashStatus]   SMALLINT      NULL;
-- HashTrashStatus: NULL = no content, 0 = draft, 1 = published

ENABLE TRIGGER [HC].[trgRecalculateRunCounts] ON [HC].[Event];
ENABLE TRIGGER [HC].[trgReplaceBrackets]       ON [HC].[Event];
