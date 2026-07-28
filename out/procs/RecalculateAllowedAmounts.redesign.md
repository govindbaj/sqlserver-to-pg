# Redesign note: dbo.RecalculateAllowedAmounts (RED)

Source: fixtures/synthetic-demo/procs/RecalculateAllowedAmounts.sql (60 lines)
Triage: RED — cursor with order-dependent running total (catalog/triage.csv row 5)

## Why this wasn't auto-translated
Cursors are almost always rewritable set-based, but the rewrite changes
how the running total is computed and needs a human to verify the result
matches row-for-row, not just "looks equivalent."

## What the source does
- Iterates unpriced claims (`ClaimStatus = 0`) per beneficiary, ordered by
  `ServiceDate`.
- Accumulates a running total of `BilledAmount` per beneficiary across the
  plan year.
- Prices each claim on a tiered schedule against that running total: full
  price under $5000 cumulative, 80% above it, and a split rate for the
  claim that straddles the $5000 threshold.
- Updates `AllowedAmount` and sets `ClaimStatus = 1` (Adjudicated).

## Suggested set-based direction (unverified — for reviewer to validate)
Replace the cursor with window functions:
- `SUM(billedamount) OVER (PARTITION BY beneficiaryid ORDER BY servicedate, claimid ROWS UNBOUNDED PRECEDING)` for the running total.
- Subtract `billedamount` from that to get the prior total (equivalent to
  `@RunningTotal - @BilledAmount` in the source).
- Apply the same tiered `CASE` logic against those two values.
- Drive the update from a single `UPDATE ... FROM` (or `UPDATE` against a
  CTE) instead of a per-row loop.

## Open questions for the reviewer
- Is $5000 a hardcoded plan-year threshold, or should it live in a
  config/lookup table?
- The source's `ORDER BY BeneficiaryID, ServiceDate` doesn't fully
  disambiguate same-day claims. A window function needs an explicit
  deterministic tiebreaker (e.g. add `ClaimID`) to guarantee it prices
  claims in the same order the cursor did.
- The cursor processes rows sequentially with no explicit locking; the
  set-based version needs to confirm no concurrent writer changes
  `ClaimStatus` mid-run.

## Estimated effort
12 hours (per catalog/triage.csv)