# Migration Exceptions Report

Source: MIGRATION-REVIEW comments in `out/` (fixtures/synthetic-demo dry run)

## Theme: Engagement configuration placeholders
- `out/tables.sql:4` — target schema name (`app`) is a placeholder for this dry run; a real engagement must use `config/project.yaml`'s `target.schema` instead.

## Theme: Target-platform extension/version dependencies
- `out/tables.sql:26` — `gen_random_uuid()` requires the pgcrypto extension on PostgreSQL <13; confirm the target Aurora PostgreSQL version before relying on it being built in.

## Theme: Collation / case-sensitivity risk (SQL Server CI vs PostgreSQL case-sensitive)
- `out/tables.sql:41` — `uq_provider_npi`'s unique constraint on a text column may disagree between SQL Server's default case-insensitive collation and PostgreSQL's case-sensitive comparison if NPI values ever contain letters.

## Theme: Implicit domain enforcement gaps
- `out/tables.sql:80` — `claimstatus` is a bare SMALLINT status code with no CHECK constraint or lookup table; SQL Server left this enforcement to application code, and the translation carries that gap forward as-is.

## Theme: Large object / storage strategy
- `out/tables.sql:97` — `filebytes` (VARBINARY(MAX) -> BYTEA) is a candidate for S3 offload rather than in-database BYTEA storage; needs an attachment-size-distribution review before committing to either approach.

## Theme: Call-site changes (proc -> function/procedure)
- `out/procs/InsertBeneficiary.sql:6` — callers switch from EXEC + read result set to `SELECT app.insertbeneficiary(...)`.
- `out/procs/GetTopRecentClaimsForBeneficiary.sql:2` — callers switch to `SELECT * FROM app.gettoprecentclaimsforbeneficiary(...)`.
- `out/procs/BuildEnrollmentSummary.sql:9` — callers switch to `SELECT * FROM app.buildenrollmentsummary(...)`.
- `out/procs/UpsertProviderEnrollment.sql:16` — callers switch from EXEC to `CALL app.upsertproviderenrollment(...)`.

## Theme: Construct-substitution semantics (temp table, CROSS APPLY, MERGE)
- `out/procs/BuildEnrollmentSummary.sql:2` — `#ActiveEnrollment` temp table replaced with a CTE.
- `out/procs/BuildEnrollmentSummary.sql:4` — CROSS APPLY -> JOIN LATERAL ... ON TRUE preserves INNER JOIN semantics (claim-less enrollments are dropped on both sides); confirm that's still the intended behavior.
- `out/procs/UpsertProviderEnrollment.sql:2` — MERGE -> INSERT ... ON CONFLICT, requires a unique constraint/index on `providernpi` (already provided by `uq_provider_npi`).

## Theme: Transaction/error-handling semantics change
- `out/procs/UpsertProviderEnrollment.sql:5` — source's unnamed `ROLLBACK TRANSACTION` would roll back a caller's outer transaction too; the PL/pgSQL `EXCEPTION` block rewrite only creates an implicit savepoint, so a failure here no longer takes down the caller's transaction. Confirm no caller relied on the old all-or-nothing rollback.

## Theme: String-length semantics (LEN vs LENGTH)
- `out/procs/InsertBeneficiary.sql:2` — `LEN()` ignores trailing spaces, `LENGTH()` does not; an all-whitespace first name is rejected by the source but accepted by the translation.

## Objects not translated at all (RED tier — redesign notes, not MIGRATION-REVIEW comments)
These don't appear in the grep above because they were never auto-translated in the first place, per CLAUDE.md's RED-tier rule:
- `out/procs/RecalculateAllowedAmounts.redesign.md` — cursor-based running-total pricing; needs a human-verified window-function rewrite.
- `out/procs/ApplyPlanCodeMassUpdate.redesign.md` — dynamic SQL from a caller-supplied column name, named/nested transactions, and a write to an undefined table (`dbo.PlanCodeAudit`).