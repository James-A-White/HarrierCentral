---
paths:
  - "db/contracts/**"
  - "agents/prompts/**"
---

# SP Contracts

Moved verbatim from the root `CLAUDE.md` in October 2026 (see `docs/history/claude-md-restructure-2026-10.md`).
Loads when you read a contract or an agent prompt template.

---

## Contract Format

Every SP must have a contract JSON file. Use this schema:

```json
{
  "schema": "HC5",
  "name": "sp_name_here",
  "version": "1.0.0",
  "description": "What this SP does",
  "parameters": [
    {
      "name": "paramName",
      "type": "SQL_TYPE",
      "nullable": true,
      "mapsToColumn": "TableName.ColumnName",
      "description": "What this parameter is for",
      "typeMismatch": "Optional: describe mismatch vs table column"
    }
  ],
  "rowsets": [
    {
      "index": 0,
      "ref": "StandardErrorResult",
      "description": "Optional SP-specific notes about the error rowset"
    },
    {
      "index": 0,
      "name": "CustomRowsetName",
      "description": "What these rows represent",
      "columns": [
        {
          "name": "ColumnName",
          "type": "SQL_TYPE",
          "nullable": false,
          "description": "What this column means"
        }
      ]
    }
  ],
  "sideEffects": [],
  "codeSmells": [
    {
      "severity": "high | medium | low",
      "issue": "Short label for the smell",
      "detail": "Full explanation with line numbers and context"
    }
  ],
  "breakingChangeRules": [
    "Never remove a column from any rowset",
    "Never rename a parameter",
    "Never change a parameter type",
    "Never change a sentinel value meaning",
    "Never change errorType integer codes without updating all callers"
  ]
}
```

**mapsToColumn format:** `"TableName.ColumnName"` — no schema prefix, no
brackets. Use `null` for auth/routing parameters that don't map to a column.

### Standard Rowsets

Use `"ref": "StandardErrorResult"` in a rowset entry instead of defining
columns inline. The standard error rowset is shared across all portal SPs.

**StandardErrorResult** — returned on any validation, auth, or runtime error:

| Column | Type | Description |
|--------|------|-------------|
| `errorId` | `UNIQUEIDENTIFIER` | Unique ID of the HC.ErrorLog entry |
| `errorType` | `INT` | Error classification code (see below) |
| `errorTitle` | `NVARCHAR(500)` | Short error title for display |
| `errorUserMessage` | `NVARCHAR(MAX)` | User-facing error message |
| `debugMessage` | `NVARCHAR(MAX)` | Developer-only debug message |
| `errorProc` | `NVARCHAR(128)` | SP name via `OBJECT_NAME(@@PROCID)` |

**errorType codes:**

| Code | Meaning |
|------|---------|
| 2 | Validation error (bad input) |
| 3 | Auth failure or entity not found |
| 4 | Concurrent modification detected |
| 5 | Unhandled database error (from CATCH block) |

When referencing in a contract, add SP-specific notes in the `description`
field (e.g. "Multiple error rowsets possible if validation doesn't
short-circuit").
