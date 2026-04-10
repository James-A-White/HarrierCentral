# SQL / Stored Procedure Style and Conventions

## HC6 SP Template

```sql
CREATE OR ALTER PROCEDURE [HC6].[hcportal_yourProcName]
-- =====================================================================
-- Procedure: HC6.hcportal_yourProcName
-- Description: What this SP does
-- Parameters: List key params
-- Returns: Describe rowsets
-- Author: Harrier Central
-- Created: YYYY-MM-DD
-- HC5 Source: HC5.hcportal_yourProcName
-- Breaking Changes: List any vs HC5
-- =====================================================================
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        -- logic here
        COMMIT TRANSACTION;
        SELECT 1 AS Success, NULL AS ErrorMessage;  -- standard success envelope
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END
```

## Must Use
- `LEN()` for string length (never `DATALENGTH`)
- `DECIMAL(10,4)` for monetary values (never `FLOAT`)
- `CREATE OR ALTER PROCEDURE` (never `CREATE` or `ALTER` alone)
- `BIT` for boolean columns (match table definition exactly)

## Code Smells to Flag
- Sentinel magic values (`-1`, `-2`, `'<null>'`, `-99.0`, `-999.0`)
- Inconsistent sentinels across parameters in the same SP
- Parameters accepted but never used (dead inputs)
- Logic outside transaction that could leave data inconsistent
- Stub logic (deletion path that does nothing)
- Wrong SP name in log/error messages
- `FLOAT` for money, `DATALENGTH` for string checks
- Type/length mismatches between SP params and base table columns

## StandardErrorResult Rowset
Shared across all portal SPs. Use `"ref": "StandardErrorResult"` in contracts.

| Column | Type |
|--------|------|
| `errorId` | `UNIQUEIDENTIFIER` |
| `errorType` | `INT` (2=validation, 3=auth/notfound, 4=concurrent, 5=unhandled) |
| `errorTitle` | `NVARCHAR(500)` |
| `errorUserMessage` | `NVARCHAR(MAX)` |
| `debugMessage` | `NVARCHAR(MAX)` |
| `errorProc` | `NVARCHAR(128)` |

## SP Naming
- Portal SPs: `HC6.hcportal_*` in `/db/hc6/portal/`
- Public web SPs: `HC6.publicWeb_*` in `/db/hc6/public-web/`
