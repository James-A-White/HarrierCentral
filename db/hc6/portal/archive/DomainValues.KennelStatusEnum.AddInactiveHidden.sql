-- Run-once: Rename KennelStatusEnum labels to operational status model
--           and add 'Inactive - Hidden' (value 4).
--
-- Before:  -1=Disabled, 0=Mismanagement Only, 1=Members Only, 2=Public
-- After:   -1=Defunct, 0=Mismanagement Only (unchanged), 1=Inactive-Visible, 2=Active, 4=Inactive-Hidden
--
-- Mobile app Kennel screen hides status -1 (Defunct) and 4 (Inactive-Hidden).
-- Existing kennels at status=2 automatically become "Active" — no data change.
-- Existing kennels at status=1 automatically become "Inactive - Visible" — no data change.
-- Default constraint updated from 1 to 2 so new kennels default to Active.
--
-- Executed: 2026-05-27
-- File already moved to archive/ (run-once).

UPDATE DomainValues.KennelStatusEnum
SET    KennelStatusEnumName = N'Active'
WHERE  KennelStatusEnumId = 2;

UPDATE DomainValues.KennelStatusEnum
SET    KennelStatusEnumName = N'Inactive - Visible'
WHERE  KennelStatusEnumId = 1;

UPDATE DomainValues.KennelStatusEnum
SET    KennelStatusEnumName = N'Defunct'
WHERE  KennelStatusEnumId = -1;

INSERT INTO DomainValues.KennelStatusEnum (KennelStatusEnumId, KennelStatusEnumName)
VALUES (4, N'Inactive - Hidden');
GO

-- Update default for new kennels from 1 (now Inactive-Visible) to 2 (Active)
ALTER TABLE HC.Kennel DROP CONSTRAINT DF_Kennel_KennelStatus;
GO
ALTER TABLE HC.Kennel ADD CONSTRAINT DF_Kennel_KennelStatus DEFAULT 2 FOR KennelStatus;
GO
