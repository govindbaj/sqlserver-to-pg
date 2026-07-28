# Redesign note: dbo.ApplyPlanCodeMassUpdate (RED)

Source: fixtures/synthetic-demo/procs/ApplyPlanCodeMassUpdate.sql (47 lines)
Triage: RED — dynamic SQL built from a caller-supplied column name, plus nested/named transactions (catalog/triage.csv row 6)

## Why this wasn't auto-translated
- Dynamic SQL assembled from a runtime-supplied identifier (`@FilterColumn`
  via `QUOTENAME`) is a SQL-injection-shaped construct even though it's
  quoted. PostgreSQL has no equivalent "safe dynamic identifier" shortcut
  — a human needs to decide whether the filter column should become a
  fixed allowlist instead of fully dynamic.
- Named/nested transactions (`BEGIN TRANSACTION OuterUpdate` +
  `SAVE TRANSACTION AuditPoint`) don't map cleanly onto PostgreSQL, which
  has no true nested transactions and no transaction *names* at all —
  only `SAVEPOINT` within a single transaction.
- Also writes to `dbo.PlanCodeAudit`, a table with no definition anywhere
  in the source tree (flagged as an unresolved dependency in
  `catalog/inventory.json`). Can't safely translate a write into a table
  whose shape is unknown.

## What the source does
- Renames a plan code across `dbo.Enrollment` rows, optionally filtered
  to one additional caller-chosen column/value pair, built via
  `QUOTENAME` + `sp_executesql`.
- Wraps the update in `BEGIN TRANSACTION OuterUpdate`.
- Takes `SAVE TRANSACTION AuditPoint` before inserting an audit row into
  `dbo.PlanCodeAudit`; if the audit insert fails, rolls back only to that
  savepoint (leaving the enrollment update intact), then commits the
  outer transaction regardless.

## Suggested redesign direction (unverified — for reviewer to validate)
- Replace the caller-supplied `@FilterColumn` with a small fixed set of
  named optional parameters (e.g. `p_filter_plan_type`,
  `p_filter_region`) so the WHERE clause is static SQL with optional AND
  branches, not string-built. If the filterable-column set is genuinely
  open-ended in the real system, an allowlist keyed by a short code is
  safer than a free-text column name passed through `QUOTENAME`.
- Get (or write) the DDL for `dbo.PlanCodeAudit` before attempting a
  translation — it doesn't exist anywhere in this source tree.
- Use a single PL/pgSQL procedure with one nested `BEGIN...EXCEPTION`
  block as the `SAVEPOINT` equivalent for the audit insert, since
  PostgreSQL only needs one real transaction here, not named nesting.
- Confirm the original intent: the source commits the enrollment update
  unconditionally even if the audit insert fails silently. That's worth
  flagging to the business owner as a compliance question, since this is
  an audit trail for plan-code changes.

## Open questions for the reviewer
- What is the real, bounded set of filterable columns? (Determines
  whether dynamic SQL is avoidable entirely.)
- Where is `dbo.PlanCodeAudit` defined? Needs its own DDL before this can
  be translated.
- Is silently swallowing a failed audit insert acceptable, or should the
  whole operation fail if the audit can't be written?

## Estimated effort
10 hours (per catalog/triage.csv)