CREATE OR ALTER PROCEDURE [HC6].[hcportal_regenerateExtApiKey]

	-- required parameters
	@publicHasherId UNIQUEIDENTIFIER = NULL,
	@accessToken NVARCHAR(1000) = NULL,
	@publicKennelId UNIQUEIDENTIFIER = NULL,
	@currentExtApiKey NVARCHAR(120) = NULL

AS
-- =====================================================================
-- Procedure: HC6.hcportal_regenerateExtApiKey
-- Description: Regenerates the external API key (ExtApiKey) for a kennel.
--              Requires the current API key for security verification.
--              Only users with appropriate AppAccessFlags (0x40000019) can
--              regenerate. Generates a 75-character cryptographically random
--              key using CRYPT_GEN_RANDOM and base64 encoding.
-- Parameters: @publicHasherId, @accessToken (auth)
--             @publicKennelId (target kennel)
--             @currentExtApiKey (current key for verification)
-- Returns: Success: newExtApiKey column
--          Failure: standard HC6 error envelope (Success, ErrorMessage)
-- Author: Harrier Central
-- Created: 2026-03-15
-- HC5 Source: HC5.hcportal_regenerateExtApiKey
-- Breaking Changes:
--   - Error rowset shape changed from multi-column HC5 error format
--     to standard HC6 envelope (Success, ErrorMessage)
--   - Validation now short-circuits on first error (HC5 could return
--     multiple error rowsets)
--   - @publicKennelId type changed: NVARCHAR(250) -> UNIQUEIDENTIFIER
--   - @currentExtApiKey type narrowed: NVARCHAR(1000) -> NVARCHAR(120)
--     to match Kennel.ExtApiKey column
--   - DATALENGTH(@publicHasherId) != 16 replaced with @publicHasherId IS NULL
--   - DATALENGTH(@publicKennelId) != 72 replaced with @publicKennelId IS NULL
--   - Removed commented-out dead code (hasher lookup block)
--   - Added SET XACT_ABORT ON
--   - Added TRY/CATCH error handling
--   - UPDATE wrapped in explicit transaction
--   - Auth validated via HC6.ValidatePortalAuth helper SP
--   - Removed @ipAddress, @ipGeoDetails (logging moved to API shim)
--   - Removed ErrorLog inserts (error logging moved to API shim)
--   - Removed GeneralLog inserts (request logging moved to API shim)
-- =====================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

	-- Auth validation
	DECLARE @authError NVARCHAR(255);
	EXEC HC6.ValidatePortalAuth @publicHasherId, @accessToken, OBJECT_NAME(@@PROCID), @publicKennelId, @authError OUTPUT;
	IF @authError IS NOT NULL
	BEGIN
		SELECT 0 AS Success, @authError AS ErrorMessage;
		RETURN;
	END

	-- Validation: publicKennelId
	IF @publicKennelId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Null or invalid publicKennelId' AS ErrorMessage;
		RETURN;
	END

	-- Resolve kennelId from publicKennelId
	DECLARE @kennelId UNIQUEIDENTIFIER
	SELECT @kennelId = id FROM HC.Kennel WHERE PublicKennelId = @publicKennelId

	IF @kennelId IS NULL
	BEGIN
		SELECT 0 AS Success, 'Kennel not found for provided publicKennelId' AS ErrorMessage;
		RETURN;
	END

	-- Validation: currentExtApiKey must match existing key
	DECLARE @apiKeyExists SMALLINT
	SELECT @apiKeyExists = COUNT(*) FROM HC.Kennel WHERE PublicKennelId = @publicKennelId AND ExtApiKey = @currentExtApiKey

	IF @apiKeyExists = 0
	BEGIN
		SELECT 0 AS Success, 'An invalid public API key was provided. You cannot reset an API key without the current API key.' AS ErrorMessage;
		RETURN;
	END

	-- Authorization: check permission bitmask
	DECLARE @appAccessFlags INT,
			@kennelName NVARCHAR(200)

	SELECT
		@appAccessFlags = hkm.AppAccessFlags,
		@kennelName = k.KennelName
	FROM HC.HasherKennelMap hkm
	INNER JOIN HC.Kennel k ON hkm.KennelId = k.id
	INNER JOIN HC.Hasher h ON hkm.UserId = h.id
	WHERE h.PublicHasherId = @publicHasherId
	AND k.PublicKennelId = @publicKennelId

	IF @appAccessFlags IS NULL OR (@appAccessFlags & 0x40000019) = 0
	BEGIN
		SELECT 0 AS Success, 'You are not authorized to access Hasher information for ' + @kennelName AS ErrorMessage;
		RETURN;
	END

	-- Generate new API key
	DECLARE @BinaryData VARBINARY(MAX) = CRYPT_GEN_RANDOM(150)
	DECLARE @randText NVARCHAR(1000)
	SELECT @randText = LEFT(REPLACE(REPLACE(CAST('' AS XML).value('xs:base64Binary(sql:variable("@BinaryData"))', 'varchar(max)'), '+', ''), '/', ''), 75)

	-- Write: wrap UPDATE in transaction
	BEGIN TRANSACTION;

		UPDATE HC.Kennel
		SET ExtApiKey = @randText
		WHERE id = @kennelId

	COMMIT TRANSACTION;

	-- Return new key
	SELECT @randText AS newExtApiKey

END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
