CREATE OR ALTER PROCEDURE [HC6].[publicWeb_confirmKennelRequest]
    @requestId UNIQUEIDENTIFIER = NULL,
    @code      NVARCHAR(MAX)    = NULL
AS
-- =====================================================================
-- Procedure:   HC6.publicWeb_confirmKennelRequest
-- Description: The second half of the hashruns.org/add-kennel form
--              (E12.F1.S8): the requester types back the six-digit code
--              emailed to them, and the request moves from awaiting email
--              (0) to new (1) — only now does it appear in the portal's
--              review queue. This is the spam wall: bots do not read mail,
--              and the address approval will make the kennel admin is
--              proven to be the requester's.
--              Five wrong codes mark the request as spam (4). A code is
--              good for 48 hours; after that the form is sent again, which
--              issues a new one on the same row. Confirming twice is
--              harmless (alreadyConfirmed = 1).
--              On success the API emails the platform admins that a
--              request is waiting (PublicWebAdminApi side effect), from
--              the reviewer list in rowset 2.
--              Reachable only through PublicWebAdminApi behind
--              HC_INTERNAL_SECRET.
-- Parameters:  @requestId (EXT.OfficeForms_KennelImport.KennelImportId),
--              @code (six digits).
-- Returns:     rowset 0 — { success, errorCode, errorType };
--              rowset 1 — on error: { errorId, errorType, errorCode,
--                errorTitle, errorUserMessage, errorProc };
--                on success: { requestId, kennelName, alreadyConfirmed };
--              rowset 2 (first confirmation only) — { reviewerEmail } for
--                every platform admin with CanEditKennel, plus
--                harriercentral@gmail.com. The API uses and
--                removes it.
-- Author:      Harrier Central
-- Created:     2026-09-28
-- HC5 Source:  none
-- =====================================================================
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @procName NVARCHAR(128) = OBJECT_NAME(@@PROCID);
DECLARE @errorId UNIQUEIDENTIFIER, @errorCode INT, @message NVARCHAR(500);

SET @code = TRIM(REPLACE(@code, N' ', N''));

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @status SMALLINT, @storedCode NVARCHAR(10), @attempts SMALLINT,
            @submittedOn DATETIME, @kennelName NVARCHAR(250);
    SELECT @status      = ki.RequestStatus,
           @storedCode  = ki.ConfirmCode,
           @attempts    = ki.ConfirmAttempts,
           @submittedOn = ki.SubmittedOn,
           @kennelName  = ki.KennelName
    FROM EXT.OfficeForms_KennelImport ki WITH (UPDLOCK, HOLDLOCK)
    WHERE ki.KennelImportId = @requestId;

    IF (@status IN (1, 2))
    BEGIN
        COMMIT TRANSACTION;
        SELECT 1 AS success, 0 AS errorCode, 0 AS errorType;
        SELECT @requestId AS requestId, @kennelName AS kennelName, 1 AS alreadyConfirmed;
        RETURN;
    END

    SELECT @errorCode = CASE
            WHEN @status IS NULL OR @status <> 0 OR @storedCode IS NULL THEN 1730
            WHEN @submittedOn < DATEADD(hour, -48, GETDATE())            THEN 1731
            WHEN @code IS NULL OR @code <> @storedCode                   THEN 1732
            ELSE NULL END;

    IF (@errorCode IS NOT NULL)
    BEGIN
        IF (@errorCode = 1732)
            UPDATE EXT.OfficeForms_KennelImport SET
                ConfirmAttempts = ConfirmAttempts + 1,
                RequestStatus   = CASE WHEN ConfirmAttempts + 1 >= 5 THEN 4 ELSE RequestStatus END,
                ConfirmCode     = CASE WHEN ConfirmAttempts + 1 >= 5 THEN NULL ELSE ConfirmCode END,
                ReviewNote      = CASE WHEN ConfirmAttempts + 1 >= 5
                                       THEN N'Marked as spam: five wrong confirmation codes' ELSE ReviewNote END,
                updatedAt       = GETDATE()
            WHERE KennelImportId = @requestId;
        COMMIT TRANSACTION;

        SET @message = CASE @errorCode
            WHEN 1730 THEN N'This request cannot be confirmed. Please fill in the form again.'
            WHEN 1731 THEN N'That code has expired. Please send the form again for a new one.'
            ELSE CASE WHEN @attempts + 1 >= 5
                      THEN N'Too many wrong codes. Please fill in the form again.'
                      ELSE N'That code is not right. Please check the email and try again.' END
            END;
        SELECT 0 AS success, @errorCode AS errorCode, 2 AS errorType;
        SELECT NEWID() AS errorId, 2 AS errorType, @errorCode AS errorCode,
               N'Code not accepted' AS errorTitle, @message AS errorUserMessage,
               @procName AS errorProc;
        RETURN;
    END

    UPDATE EXT.OfficeForms_KennelImport SET
        RequestStatus = 1,
        ConfirmedAt   = SYSDATETIMEOFFSET(),
        ConfirmCode   = NULL,
        updatedAt     = GETDATE()
    WHERE KennelImportId = @requestId;

    COMMIT TRANSACTION;

    SELECT 1 AS success, 0 AS errorCode, 0 AS errorType;
    SELECT @requestId AS requestId, @kennelName AS kennelName, 0 AS alreadyConfirmed;
    -- The platform admins' own addresses, plus the shared Harrier Central
    -- mailbox (James, 2026-09-28). The API de-duplicates.
    SELECT h.Email AS reviewerEmail
    FROM HC.PlatformAdmin pa
    JOIN HC.Hasher h ON h.id = pa.UserId AND h.Removed = 0
    WHERE pa.removed = 0 AND pa.CanEditKennel = 1
      AND LEN(COALESCE(h.Email, N'')) > 0
    UNION
    SELECT N'harriercentral@gmail.com';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SET @errorId = NEWID();
    INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId)
    VALUES (@errorId, '<web>', 'Unhandled error in publicWeb_confirmKennelRequest',
            ERROR_MESSAGE(), @procName, NULL);
    SELECT 0 AS success, 1739 AS errorCode, 5 AS errorType;
    SELECT @errorId AS errorId, 5 AS errorType, 1739 AS errorCode,
           N'Something went wrong' AS errorTitle,
           N'We could not confirm your request just now. Please try again in a few minutes.' AS errorUserMessage,
           @procName AS errorProc;
END CATCH
GO
