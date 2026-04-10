# What to Do When a Task is Completed

## SP Migration Task (hcportal_* or publicWeb_*)

1. Read HC5 SP from `/db/hc5/portal/<sp_name>.sql`
2. Read relevant table definitions from `/db/schema/tables/`
3. Extract HC5 contract JSON → `/db/contracts/hc5/<sp_name>.json`
4. Write HC6 SP to `/db/hc6/portal/<sp_name>.sql` (or `public-web/`)
5. Write HC6 contract → `/db/contracts/hc6/<sp_name>.json`
6. Flag all code smells in contracts under `codeSmells[]`
7. Document all breaking changes in the HC6 SP header and contract
8. Propose commit — **wait for James to review and approve before committing**

## Public Web Feature Task (Next.js)

1. Make code changes only — do NOT run build or deploy
2. If possible, test via `npm run dev` and report what was verified
3. Verify both light and dark mode rendering if UI changes
4. Check no horizontal scrolling introduced
5. Confirm all new components use `var(--color-primary)` not hardcoded colours
6. Run `npm run lint` — fix any errors before reporting done

## General Rules

- **Never deploy to production autonomously** — not the public web, not the API, not SPs
- **Agents propose. James decides.** Never treat output as ready to commit without review
- One SP per commit — no batch refactors
- Contracts before code — extract HC5 contract before writing HC6
- Every breaking change must be deliberate and documented
- When in doubt, flag it — don't fix it
