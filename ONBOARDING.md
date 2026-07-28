# Onboarding: Using This Migration Kit

## Before you start
1. Fill in `config/project.yaml` with this engagement's client, source/target platforms, hosting, and scale. Do not edit CLAUDE.md itself — its rules are meant to stay the same across engagements.
2. Confirm you're not connecting this kit to any production database. It only ever reads/writes files; a human runs any generated DDL against a real environment (see Guardrails in CLAUDE.md).
3. Drop your extracted SQL Server DDL into `src/tables.sql` (or one file per table/view, your choice) and one file per stored procedure into `src/procs/`. `fixtures/synthetic-demo/` is a self-test fixture, not real source — leave it alone.

## The six stages (see CLAUDE.md for the exact rules)
Run these in order, against `src/`, not `fixtures/`:
1. **Inventory** — catalog every object into `catalog/inventory.json`.
2. **Triage** — classify every proc GREEN/AMBER/RED into `catalog/triage.csv`.
3. **Type mapping (DDL)** — translate table/view DDL into `out/`.
4. **Proc translation** — translate GREEN/AMBER procs into `out/`; write a redesign note (`.redesign.md`) for every RED proc instead of translating it.
5. **Verification** — generate row-count/checksum/null/min-max/orphan queries and proc test harnesses into `verify/`.
6. **Reporting** — roll up `MIGRATION-REVIEW` comments into `reports/exceptions.md` and hours-by-tier into `reports/estimate.md`.

## How this scales past a handful of objects
The synthetic-demo dry run walked through every file one at a time so it could be reviewed and copy-pasted by hand — that was for validating the kit itself, not the intended workflow for several hundred procs. At real scale:
- **GREEN procs**: translate in batches (the agent writes directly into `out/` for many files in one pass); spot-check a sample rather than reviewing every line.
- **AMBER procs**: translate in batches too, but every file requires a human sign-off before merging — route each through a normal PR/code review, using the `MIGRATION-REVIEW` comments as the reviewer's checklist.
- **RED procs**: no batch translation. Each gets its own redesign note, and each redesign note becomes its own ticket/conversation with a human architect — this is deliberately slow because CLAUDE.md says these need a human, not because the tooling can't go faster.
- Prefer several small PRs (e.g. one per batch of related procs) over one giant PR — easier for reviewers to actually read the `MIGRATION-REVIEW` flags instead of skimming past them.

## Completeness check before calling a batch "done"
Before signing off on any batch, confirm every row in `catalog/triage.csv` has a matching artifact:
- GREEN/AMBER row → a translated file exists under `out/procs/`.
- RED row → a `*.redesign.md` file exists under `out/procs/`.
- Every table/view in `catalog/inventory.json` → a corresponding block in `out/tables.sql` (or its own file).

A row with neither is a silent gap — exactly what CLAUDE.md's prime directive says never to allow.