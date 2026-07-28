# Adjacent Workstreams (Out of Scope for This Kit)

This kit translates schema and code (Stages 1-6 in CLAUDE.md). Two
related workstreams are NOT covered here and should be tracked
separately by the client project team.

## 1. Data movement / cutover
This kit produces DDL and verification *queries* — it does not move
actual row data from SQL Server to Aurora PostgreSQL. That's a separate
workstream, typically:
- AWS DMS (Database Migration Service) for bulk copy + ongoing
  replication during a phased cutover, or
- A custom ETL/bulk-export-and-load process if DMS doesn't handle a
  given type mapping cleanly (e.g. SQL_VARIANT, HIERARCHYID columns
  flagged RED in Stage 3).

Whichever approach is chosen, the queries generated in `verify/` by
this kit are exactly what should run against the migrated data to
confirm the copy succeeded — but someone still has to build and run
the copy itself.

## 2. Compliance / PHI review
CLAUDE.md's triage rubric flags "anything touching PHI in an unusual
way" as RED, but this kit does not perform a compliance review — it
only surfaces the flag. Any RED item flagged for PHI reasons should go
to the client's compliance/security team, not just an engineering
reviewer, before a redesign is implemented.

## 3. Cutover rehearsal
Once verification queries in `verify/` pass against a staging copy of
the migrated data, plan at least one full rehearsal of the cutover
(schema + data + app config switch) in a non-production environment
before doing it for real. This kit doesn't generate a rehearsal plan —
that's engagement-specific (traffic patterns, rollback plan,
maintenance window).