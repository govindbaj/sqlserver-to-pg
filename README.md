# SQL Server → PostgreSQL Migration Kit

## Folders

- `config/` — Engagement-specific settings (`project.yaml`): client, source/target platforms, scale. Edit this per engagement; the rest of the kit shouldn't need to change.
- `src/` — Read-only source SQL Server artifacts (schema DDL) for the real client engagement. Empty until the real extracts are dropped in. Never edited by tooling.
- `src/procs/` — Source stored procedures for the real engagement, one file per proc. Empty until real extracts are dropped in.
- `fixtures/synthetic-demo/` — Fully synthetic sample schema + procs used to dry-run and validate the kit's stages. Not real client data.
- `catalog/` — Inventory (`inventory.json`) and triage (`triage.csv`) output from Stages 1–2.
- `out/` — Generated PostgreSQL DDL/DML/functions produced by the translation stage. Never hand-edited.
- `verify/` — Row-count, checksum, and referential-integrity verification queries for migrated tables and procs.
- `reports/` — Exception log (`exceptions.md`) and hour estimates (`estimate.md`) rolled up from the migration.