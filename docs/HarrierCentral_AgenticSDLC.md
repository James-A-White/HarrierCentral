# Harrier Central — Agentic SDLC Design
**Version 1.2 | Solo Dev | Nights & Weekends**

---

## The North Star

This is not just a refactor project. It is a personal software laboratory designed to:
1. Modernise Harrier Central's portal layer (HC5 → HC6)
2. Build real-world agentic AI development skills
3. Establish professional engineering habits that scale

Every decision below is made with those three goals in mind.

---

## Architecture Layers (Reminder)

```
Next.js Portal (Admin + Public)
        ↓
Azure Function .NET Shim (stable, rarely changes)
        ↓
SQL Server Stored Procedures (domain logic lives here)
        ↓
SQL Server Tables
```

**Key insight:** The database IS the application. All agent work must centre on the SP layer.

---

## Repository Structure

```
/harrier-central
  /db
    /hc5
      /portal        ← HC5 portal SPs (archived, read-only after migration)
      /app           ← HC5 app SPs (untouched for now)
      /internal      ← HC5 internal SPs (untouched for now)
    /hc6
      /portal        ← New HC6 portal SPs (built here)
    /contracts
      /hc5           ← Extracted SP contracts (JSON)
      /hc6           ← New SP contracts (JSON)
  /api               ← Azure Function .NET source
  /portal            ← Next.js source
  /docs
    /contracts       ← Auto-generated markdown from contracts
    /screens         ← Screen Behaviour Audits
  /agents
    /prompts         ← Reusable agent prompt templates
    /fixtures        ← Sample SP payloads (sanitised)
```

---

## The 5 Phases of Work

### Phase 0 — Foundations (One Evening)
Get safe before touching anything.

### Phase 1 — SP Contracts & HC5 Archive (Weekend 1)
Formalise what exists. Freeze the baseline.

### Phase 2 — HC6 SP Refactor (Weekends 2–4)
AI-assisted refactor of each portal SP into HC6.

### Phase 3 — Portal Refactor (Weekends 5–7)
Point Next.js portal at HC6. Fix admin UI issues.

### Phase 4 — Public Facing Expansion (Future)
Add Next.js SSR/SSG public club pages using the clean HC6 layer.

---

## Phase 0 — Foundations

**Goal:** Safe to start. Nothing lost. Everything visible.

### Step 0.1 — Script HC5 Portal SPs to source control

In SSMS:
1. Right-click database → Tasks → Generate Scripts
2. Select specific objects → filter to `hcportal_` procedures only
3. Script to **individual files** (one file per SP — easier to diff)
4. Save to `/db/hc5/portal/`
5. Commit with message: `chore: archive HC5 portal stored procedures (baseline)`

> 🧠 **Why:** This is called *archaeological source control* — capturing the true current state of a system before modifying it. It's a professional discipline when inheriting or modernising legacy systems. You now have an immutable record of the starting point.

### Step 0.2 — Create HC6 schema in SQL Server

```sql
CREATE SCHEMA HC6;
```

That's it. Empty for now. HC5 is untouched.

### Step 0.3 — Add schema config to Azure Function

Add an environment variable to your Azure Function configuration:

```
HC_PORTAL_SCHEMA = HC5
```

When HC6 is ready to go live, you change this to `HC6` — no code change required.

> 🧠 **Why:** Configuration should control environment-specific behaviour, not code. This is the *Twelve-Factor App* principle of separating config from code. It means your portal can switch schema versions with a single setting change and a redeploy — no pull request needed.

---

## Phase 1 — SP Contracts

**Goal:** Turn tribal knowledge into machine-readable truth.

> 🧠 **Why contracts?** Right now the "documentation" for your stored procedures lives in your head. Contracts externalise that knowledge into versioned files that agents, CI, and future-you can all read. This is the foundation of contract-driven development — a standard practice in distributed systems engineering.

### Contract Format

Each SP gets a JSON contract file at `/db/contracts/hc5/<sp_name>.json`:

```json
{
  "schema": "HC5",
  "name": "hcportal_addEditEvent",
  "version": "1.0.0",
  "description": "Creates or updates an event for a kennel",
  "parameters": [
    {
      "name": "kennelId",
      "type": "INT",
      "nullable": false,
      "mapsToColumn": "HC.Kennel.Id",
      "description": "The kennel this event belongs to"
    },
    {
      "name": "eventId",
      "type": "INT",
      "nullable": true,
      "mapsToColumn": "HC.Event.Id",
      "description": "NULL for new event, existing ID for update"
    }
  ],
  "rowsets": [
    {
      "index": 0,
      "name": "Event",
      "description": "The saved event record",
      "columns": [
        { "name": "EventId", "type": "INT", "nullable": false },
        { "name": "EventName", "type": "NVARCHAR", "nullable": false }
      ]
    }
  ],
  "sideEffects": [],
  "codeSmells": [],
  "breakingChangeRules": [
    "Never remove a column from any rowset",
    "Never rename a parameter",
    "Never change a parameter type",
    "Never change a sentinel value meaning (e.g. what -1 or -2 signify)",
    "Never change errorType integer codes without updating all callers"
  ]
}
```

Note the `mapsToColumn` field on each parameter — this makes the table mapping explicit and machine-readable for future tooling such as automated mismatch detection in CI.

### Pre-extraction: Providing Base Table Schemas to the Agent

The Contract Agent needs access to your base table definitions to detect type and length mismatches between SP parameters and table columns. There are three ways to provide this context, in order of increasing sophistication.

> 🧠 **Why this matters:** When an SP parameter is a different type or length than the table column it writes to, SQL Server performs an *implicit conversion* at runtime. These are completely silent — no error, no warning — but they cause index scans instead of seeks (performance hit) and can silently truncate data. Making these visible in your contracts means HC6 fixes them before they reach production.

---

#### Option A — Claude Projects (Start here. Available today, zero setup.)

Claude Projects let you upload files that persist across every conversation in that project. You upload your table schema files once and every future conversation has access to them automatically — no pasting required.

**Setup (one-time, ~30 minutes):**

First, script all your base tables to SQL files in your repo:

In SSMS: Right-click database → Tasks → Generate Scripts → select Tables → script to individual files → save to `/db/schema/tables/`

Use VS Code find-and-replace to convert `CREATE TABLE` to `CREATE OR ALTER TABLE` across all files for idempotency.

Then:
1. Go to claude.ai → click **Projects** in the left sidebar → **New Project**
2. Name it "Harrier Central"
3. Upload all files from `/db/schema/tables/` to the project
4. Also upload your `/agents/prompts/contract_extractor.md` prompt file
5. Add a Project Instructions note (see below)

**Suggested Project Instructions:**
```
You are working on the Harrier Central project — a hash running club 
management platform.

Stack: SQL Server (stored procedures as domain logic) → .NET Azure Function 
shim → Next.js portal (admin + public) → Flutter mobile app.

The uploaded files contain the base table CREATE OR ALTER TABLE statements 
for the HC schema. When extracting SP contracts or refactoring SPs, always 
reference these table definitions to identify type mismatches, length 
mismatches, and nullability issues. Never ask me to paste table definitions 
— read them from the uploaded files.

Current work: Migrating hcportal_ stored procedures from HC5 schema to HC6.
```

**Usage:** Open your Harrier Central project, paste only the SP source, and say "extract the contract for this SP." Claude reads the table files itself.

> 🧠 **Why this is powerful:** Projects give you persistent context across sessions — like having your table schemas permanently open in your IDE. This is the foundation of a personal AI development environment tailored to your codebase.

---

#### Option B — Prompt Assembly Script (Build after validating 3–4 SPs manually)

A small script that assembles the complete prompt automatically from your repo files, so you never manually copy-paste anything.

Save to `/tools/assemble_prompt.js`:

```javascript
const fs = require('fs');
const path = require('path');

// Usage: node assemble_prompt.js <sp_filename>
// Example: node assemble_prompt.js hcportal_addEditEvent2.sql

const spFile = process.argv[2];
if (!spFile) {
  console.error('Usage: node assemble_prompt.js <sp_filename>');
  process.exit(1);
}

const spPath = path.join(__dirname, '../db/hc5/portal', spFile);
const promptPath = path.join(__dirname, '../agents/prompts/contract_extractor.md');
const tablesDir = path.join(__dirname, '../db/schema/tables');

// Read the SP source
const spSource = fs.readFileSync(spPath, 'utf8');

// Read the base prompt template
const promptTemplate = fs.readFileSync(promptPath, 'utf8');

// Read all table definition files
const tableFiles = fs.readdirSync(tablesDir).filter(f => f.endsWith('.sql'));
const tableSchemas = tableFiles
  .map(f => fs.readFileSync(path.join(tablesDir, f), 'utf8'))
  .join('\n\n');

// Assemble the final prompt
const assembled = promptTemplate
  .replace('[paste INFORMATION_SCHEMA query results here]', tableSchemas)
  .replace('[paste SP here]', spSource);

// Write to clipboard (macOS) or stdout
try {
  require('child_process').execSync('pbcopy', { input: assembled });
  console.log(`✅ Prompt for ${spFile} copied to clipboard. Paste into Claude.`);
} catch {
  // Fallback: write to file if pbcopy not available (Windows/Linux)
  const outPath = path.join(__dirname, '../agents/assembled_prompt.txt');
  fs.writeFileSync(outPath, assembled);
  console.log(`✅ Prompt written to /agents/assembled_prompt.txt`);
}
```

**Usage:**
```bash
node tools/assemble_prompt.js hcportal_addEditEvent2.sql
# Prompt is ready to paste into Claude
```

> 🧠 **What you're learning here:** This is prompt engineering as code. The script is a simple form of an *agent orchestrator* — software that assembles context and coordinates AI calls. This pattern scales into the full automation in Option C.

---

#### Option C — Full Claude API Automation (Build after Option B is working)

Extend the Option B script to call the Claude API directly and write the contract JSON to your repo automatically. Run one command, process all SPs, done.

Save to `/tools/extract_all_contracts.js`:

```javascript
const fs = require('fs');
const path = require('path');
const Anthropic = require('@anthropic-ai/sdk');

const client = new Anthropic(); // reads ANTHROPIC_API_KEY from environment

const portalDir = path.join(__dirname, '../db/hc5/portal');
const contractsDir = path.join(__dirname, '../db/contracts/hc5');
const promptPath = path.join(__dirname, '../agents/prompts/contract_extractor.md');
const tablesDir = path.join(__dirname, '../db/schema/tables');

async function extractContract(spFile) {
  const spSource = fs.readFileSync(path.join(portalDir, spFile), 'utf8');
  const promptTemplate = fs.readFileSync(promptPath, 'utf8');
  const tableSchemas = fs.readdirSync(tablesDir)
    .filter(f => f.endsWith('.sql'))
    .map(f => fs.readFileSync(path.join(tablesDir, f), 'utf8'))
    .join('\n\n');

  const prompt = promptTemplate
    .replace('[paste INFORMATION_SCHEMA query results here]', tableSchemas)
    .replace('[paste SP here]', spSource);

  console.log(`Extracting contract for ${spFile}...`);

  const response = await client.messages.create({
    model: 'claude-opus-4-6',
    max_tokens: 4000,
    messages: [{ role: 'user', content: prompt }]
  });

  const contractJson = response.content[0].text;

  // Validate it's parseable JSON before writing
  JSON.parse(contractJson);

  const outFile = path.join(contractsDir, spFile.replace('.sql', '.json'));
  fs.writeFileSync(outFile, contractJson, 'utf8');
  console.log(`  ✅ Contract written to ${outFile}`);
}

async function main() {
  const spFiles = fs.readdirSync(portalDir).filter(f => f.endsWith('.sql'));
  console.log(`Found ${spFiles.length} portal SPs to process.\n`);

  for (const spFile of spFiles) {
    await extractContract(spFile);
  }

  console.log('\n✅ All contracts extracted.');
}

main().catch(console.error);
```

**Usage:**
```bash
export ANTHROPIC_API_KEY=your_key_here
node tools/extract_all_contracts.js
# Processes all portal SPs and writes contract JSON files
```

> 🧠 **What you're learning here:** This is a real agentic pipeline — a script that orchestrates an AI model to perform a repeatable task across a codebase. The pattern here (read files → assemble prompt → call API → write output → commit) is the foundation of every serious agentic SDLC workflow. You're not just using AI; you're building infrastructure that uses AI.

**Important:** Run Option C only after you've validated prompt quality manually (Option A) and via clipboard assembly (Option B). Automating a flawed prompt produces flawed contracts at scale.

---

#### Table Schema Setup (required for all three options)

Script all base tables from SSMS to individual files:

1. SSMS → Right-click database → Tasks → Generate Scripts
2. Select Tables → script to individual files
3. Save to `/db/schema/tables/`
4. VS Code find-and-replace across files: `CREATE TABLE` → `CREATE OR ALTER TABLE`
5. Commit with message: `chore: archive base table schemas (baseline)`

This is a one-time setup. After this, your table definitions are versioned in Git alongside your SPs — changes to table structure are now visible in pull request diffs.

### The Contract Agent Prompt (reusable)

Save this to `/agents/prompts/contract_extractor.md`:

```
You are a SQL contract extractor for the Harrier Central project.

I will paste the source of a stored procedure AND the schema of the base 
tables it touches. Your job is to produce a contract JSON file that 
documents the SP precisely.

Rules:
- Extract ALL input parameters with types and nullability
- Extract ALL output rowsets with column names, types, and nullability
- Infer descriptions from parameter names and SP logic — ask me if unclear
- Note any side effects (sends notifications, calls other SPs, etc.)
- Flag code smells as described below
- Output ONLY valid JSON matching the contract schema — no explanation, 
  no markdown fences

When identifying code smells, specifically check for:
- Parameter type mismatches vs the base table column
  (e.g. SP accepts NVARCHAR(100) but table column is NVARCHAR(250))
- Parameter length mismatches — flag both under-sized (truncation risk) 
  and over-sized (misleading contract)
- Numeric precision mismatches (e.g. FLOAT in SP vs DECIMAL(10,2) in table)
- Nullability mismatches (e.g. SP accepts NULL for a NOT NULL column 
  with no default)
- Any implicit type conversions SQL Server would silently perform
- Parameters accepted by the SP that don't map to any table column 
  (dead inputs)
- Table columns that are written to but not exposed as parameters 
  (hidden defaults worth documenting)

For each mismatch found, write the code smell in this format:
"MISMATCH: @paramName is {SP type} but {TableName}.{ColumnName} is 
{table type} — {risk description}"

Contract schema:

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
      "description": "What this parameter is for"
    }
  ],
  "rowsets": [
    {
      "index": 0,
      "name": "RowsetName",
      "description": "What these rows represent",
      "columns": [
        { "name": "ColumnName", "type": "SQL_TYPE", "nullable": false, 
          "description": "What this column means" }
      ]
    }
  ],
  "sideEffects": [],
  "codeSmells": [],
  "breakingChangeRules": [
    "Never remove a column from any rowset",
    "Never rename a parameter",
    "Never change a parameter type",
    "Never change a sentinel value meaning (e.g. what -1 or -2 signify)",
    "Never change errorType integer codes without updating all callers"
  ]
}

Here are the base table schemas:
[paste INFORMATION_SCHEMA query results here]

Here is the stored procedure:
[paste SP here]
```

> 🧠 **Why a saved prompt?** Reusable agent prompts are a core agentic SDLC practice. You're not just using AI — you're designing a repeatable workflow. Each time you run this prompt, you get consistent, structured output. This is *prompt engineering as infrastructure*.

---

## Phase 2 — HC6 SP Refactor

**Goal:** One SP at a time, produce a better, documented version in HC6.

### The SP Refactor Workflow (per SP)

This is your repeatable nightly loop:

```
1. Open existing HC5 SP
2. Run Contract Extractor Agent → save contract to /db/contracts/hc5/
3. Run SP Refactor Agent → produces HC6 version
4. Review output carefully (you are the decision maker)
5. Test HC6 SP against real data
6. Save to /db/hc6/portal/
7. Save contract to /db/contracts/hc6/
8. Commit
```

### The SP Refactor Agent Prompt

Save to `/agents/prompts/sp_refactor.md`:

```
You are a SQL Server stored procedure refactoring expert for the Harrier 
Central project.

Context:
- This SP is being migrated from schema HC5 to HC6
- HC6 is a clean, well-documented, optimised version of HC5
- The API calling this SP is a stable Azure Function shim — do not change
  its interface unless I explicitly ask
- All access is via stored procedures — no dynamic SQL, ever

Your tasks:
1. Migrate the SP to HC6 schema (change schema reference only)
2. Optimise any obvious performance issues (with explanation)
3. Add comprehensive inline documentation (header block + inline comments)
4. Standardise error handling
5. Wrap the SP body in a TRY/CATCH if not already present
6. Add a standard response envelope:
   - On success: SELECT 1 AS Success, NULL AS ErrorMessage
   - On error: SELECT 0 AS Success, ERROR_MESSAGE() AS ErrorMessage
7. Flag any business logic that seems risky or unclear (don't silently fix)

For every change you make, explain WHY in a comment or in a summary section.

Here is the HC5 stored procedure:
[paste SP here]

Here is its contract:
[paste contract JSON here]
```

> 🧠 **Why TRY/CATCH and response envelopes?** Consistent error handling is what separates amateur SQL from production SQL. Right now your shim may be getting unpredictable error behaviour from SPs. A standard envelope means your Next.js portal always knows what shape the response will be — success or failure. This is defensive programming at the data layer.

### Breaking Change Gate

Before committing any HC6 SP, run this mental check (later automated in CI):

- [ ] All parameters from HC5 contract still exist with same types?
- [ ] All rowset columns from HC5 contract still exist?
- [ ] No column renames?
- [ ] Side effects (notifications, etc.) preserved?

If any of these fail — it's a **breaking change**. That's not necessarily wrong, but it must be deliberate and documented.

---

## The Agentic Development Loop

This is what a typical night session looks like when the system is running:

```
You write a 2–3 line intent:
"Refactor hcportal_addEditEvent into HC6. 
 It should support a new optional TrailDescription field."

Agent outputs:
→ Updated contract (HC6)
→ Refactored SP with new parameter
→ Breaking change assessment
→ Notes on what the portal will need to change

You review, adjust, test, commit.
```

**You are always the decision maker.** The agent is a force multiplier, not an autopilot.

> 🧠 **This is the core of agentic development:** Structured human intent → AI-assisted execution → human review → commit. The agent handles the boilerplate and the thinking overhead. You handle the judgement calls.

---

## CI Pipeline (Minimal but Professional)

Set up in Azure DevOps. Triggered on every PR to `main`.

### Stage 1 — SQL Validation
- Run `sqlcmd` syntax check on all `.sql` files in `/db/hc6/`
- Verify every HC6 SP has a corresponding contract JSON
- Diff HC5 vs HC6 contract — flag breaking changes in PR comments

### Stage 2 — API Build
- `dotnet build` on Azure Function project
- Fail on warnings (keeps the codebase clean)

### Stage 3 — Portal
- `npm run build` on Next.js
- `npm run lint`

> 🧠 **Why CI even for a solo dev?** CI is not about catching other people's mistakes. It's about protecting tired-James-at-midnight from himself. The pipeline runs the checks you'd forget to run manually after a long day. This is called *automated guardrails* and it's how professional engineers maintain quality under time pressure.

---

## Screen Behaviour Audit Template

Before touching any portal screen, create a file at `/docs/screens/<screen_name>.md`:

```markdown
# Screen: [Name]

## Purpose
What does this screen do?

## Data Sources
Which SPs does it call?

## Non-Obvious Behaviours
- List anything subtle here (conditional UI, edge cases, etc.)

## Data States to Handle
- [ ] Loading
- [ ] Empty / no data
- [ ] Populated
- [ ] Error

## Known Issues
What's broken or needs improving?

## Refactor Notes
What needs to change in the HC6 version?
```

---

## Weekend 1 — Concrete Plan

### Friday Night (1–2 hrs)
- [ ] Create repo folder structure
- [ ] Script all `hcportal_` SPs from SSMS to individual files
- [ ] Commit to `/db/hc5/portal/` — this is your baseline
- [ ] Create HC6 schema in SQL Server
- [ ] Add `HC_PORTAL_SCHEMA` environment variable to Azure Function

### Saturday (2–3 hrs)
- [ ] Extract contracts for all `hcportal_` SPs using Contract Agent
- [ ] Save to `/db/contracts/hc5/`
- [ ] Commit all contracts
- [ ] Review contracts — does the extracted documentation match reality?

### Sunday (2–3 hrs)
- [ ] Pick the simplest `hcportal_` SP
- [ ] Run SP Refactor Agent → produce HC6 version
- [ ] Test HC6 SP against real data
- [ ] Set up Azure DevOps CI pipeline (Stages 1–3 above)
- [ ] Write Screen Behaviour Audit for one portal screen

**End of Weekend 1:** You have a versioned baseline, machine-readable contracts, one HC6 SP, and a running CI pipeline. That is a professional engineering foundation.

---

## Guiding Principles

1. **Agents propose. You decide.** Never commit AI-generated SQL without reading and understanding it.
2. **One SP at a time.** Don't batch refactors. Each SP is its own PR.
3. **Contracts before code.** Extract the contract before refactoring the SP.
4. **Break nothing silently.** Every breaking change must be deliberate and documented.
5. **Defer complexity.** Don't build tooling until the pain of not having it is real.
6. **Tired-James needs guardrails.** CI is your protection against night-time mistakes.

---

*Document version: 1.2 | Last updated: March 2026 | Changes: Added three-tier table schema context strategy (Claude Projects / prompt assembly script / full API automation); added table schema setup instructions; updated Contract Agent prompt section.*
