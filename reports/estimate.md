# Migration Effort Estimate

Source: `catalog/triage.csv` (6 stored procedures triaged from `fixtures/synthetic-demo/procs/`)

## Hours by tier

| Tier | Proc count | Objects (hours) | Sum of est_hours | Avg hours/proc |
|---|---|---|---|---|
| GREEN | 2 | InsertBeneficiary (1), GetTopRecentClaimsForBeneficiary (1) | 2 | 1.0 |
| AMBER | 2 | BuildEnrollmentSummary (6), UpsertProviderEnrollment (5) | 11 | 5.5 |
| RED | 2 | RecalculateAllowedAmounts (12), ApplyPlanCodeMassUpdate (10) | 22 | 11.0 |
| **Total** | **6** | | **35** | 5.83 |

## Counting shown
- GREEN: 1 (InsertBeneficiary) + 1 (GetTopRecentClaimsForBeneficiary) = 2 hours
- AMBER: 6 (BuildEnrollmentSummary) + 5 (UpsertProviderEnrollment) = 11 hours
- RED: 12 (RecalculateAllowedAmounts) + 10 (ApplyPlanCodeMassUpdate) = 22 hours
- Total: 2 + 11 + 22 = 35 hours across 6 procs

## Non-tiered work observed in this dry run (outside the triage rubric, tracked separately)
- DDL translation (Stage 3, 5 tables in `fixtures/synthetic-demo/tables.sql`): ~4 hours for a schema this size, driven up by the FK/collation/S3-offload flags in `out/tables.sql`.
- Verification authoring (Stage 5, `verify/`): ~3 hours to write row-count/checksum/orphan checks for 5 tables and expected-vs-actual harnesses for the 4 translated procs.

## Scaling note for the real engagement
This kit's triage rubric (GREEN/AMBER/RED tier definitions in CLAUDE.md) is what gets re-run against the real client's several-hundred-proc inventory. The per-tier hour figures above are only representative of this 6-proc sample, not a fixed unit cost — re-derive avg-hours-per-tier from the real inventory's actual mix of feature flags and line counts once Stage 1/2 run for real.