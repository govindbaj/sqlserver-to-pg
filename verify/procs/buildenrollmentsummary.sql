-- =========================================================================
-- Verification harness: dbo.BuildEnrollmentSummary -> app.buildenrollmentsummary
-- (AMBER, translated in out/procs/BuildEnrollmentSummary.sql)
--
-- For each test case: run the SQL Server block, run the PostgreSQL
-- block, then diff row count and column values keyed on EnrollmentID.
-- =========================================================================

-- Test 1: default AsOfDate (omitted -> "now")
-- Expected: both sides use the current timestamp as the cutoff and
-- return the same set of active enrollments. Run both blocks back-to-
-- back in the same test window to avoid a clock-skew false mismatch.
-- SQL Server:
EXEC dbo.BuildEnrollmentSummary;
-- PostgreSQL:
SELECT * FROM app.buildenrollmentsummary();


-- Test 2: AsOfDate before any enrollment's EffectiveDate
-- Expected: both sides return 0 rows.
-- SQL Server:
EXEC dbo.BuildEnrollmentSummary @AsOfDate = '2000-01-01';
-- PostgreSQL:
SELECT * FROM app.buildenrollmentsummary('2000-01-01');


-- Test 3: AsOfDate with an active enrollment that has NO claim history yet
-- MIGRATION-REVIEW (carried from out/procs/BuildEnrollmentSummary.sql):
-- CROSS APPLY (source) and JOIN LATERAL ... ON TRUE (target) both use
-- INNER JOIN semantics -- an active enrollment with zero claims is
-- DROPPED from the result on both sides, not shown with NULL claim
-- columns. Confirm this test returns the SAME row count (excluding the
-- claim-less enrollment) on both sides -- if either side ever shows it,
-- that's a real bug, not the documented divergence.
-- SQL Server:
EXEC dbo.BuildEnrollmentSummary @AsOfDate = '2026-06-01';
-- PostgreSQL:
SELECT * FROM app.buildenrollmentsummary('2026-06-01');


-- Test 4: AsOfDate exactly on an enrollment's TerminationDate
-- Expected: both sides EXCLUDE the enrollment (source's
-- `TerminationDate > @AsOfDate` and target's
-- `terminationdate > v_asofdate` are both strict greater-than).
-- SQL Server:
EXEC dbo.BuildEnrollmentSummary @AsOfDate = '2026-03-31';
-- PostgreSQL:
SELECT * FROM app.buildenrollmentsummary('2026-03-31');