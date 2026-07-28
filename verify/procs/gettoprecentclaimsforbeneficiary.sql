-- =========================================================================
-- Verification harness: dbo.GetTopRecentClaimsForBeneficiary
--                     -> app.gettoprecentclaimsforbeneficiary
-- (GREEN, translated in out/procs/GetTopRecentClaimsForBeneficiary.sql)
--
-- For each test case: run the SQL Server block, run the PostgreSQL
-- block, then diff row count, column values, and ordering.
-- =========================================================================

-- Test 1: beneficiary with more claims than MaxRows
-- Expected: both sides return exactly 2 rows, the 2 most recent by
-- ServiceDate descending, with matching ClaimID/BilledAmount/ProviderName.
-- SQL Server:
EXEC dbo.GetTopRecentClaimsForBeneficiary @BeneficiaryID = 101, @MaxRows = 2;
-- PostgreSQL:
SELECT * FROM app.gettoprecentclaimsforbeneficiary(101, 2);


-- Test 2: beneficiary with no claims
-- Expected: both sides return 0 rows, no error.
-- SQL Server:
EXEC dbo.GetTopRecentClaimsForBeneficiary @BeneficiaryID = 999, @MaxRows = 5;
-- PostgreSQL:
SELECT * FROM app.gettoprecentclaimsforbeneficiary(999, 5);


-- Test 3: default MaxRows (omitted -> should default to 10)
-- Expected: both sides cap the result at 10 rows even if more claims exist.
-- SQL Server:
EXEC dbo.GetTopRecentClaimsForBeneficiary @BeneficiaryID = 101;
-- PostgreSQL:
SELECT * FROM app.gettoprecentclaimsforbeneficiary(101);


-- Test 4: NULL AllowedAmount
-- Expected: both sides coalesce NULL AllowedAmount to 0
-- (ISNULL vs COALESCE), not a blank/NULL value in the result.
-- SQL Server:
EXEC dbo.GetTopRecentClaimsForBeneficiary @BeneficiaryID = 102, @MaxRows = 10;
-- PostgreSQL:
SELECT * FROM app.gettoprecentclaimsforbeneficiary(102, 10);