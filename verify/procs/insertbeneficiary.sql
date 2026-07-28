-- =========================================================================
-- Verification harness: dbo.InsertBeneficiary -> app.insertbeneficiary
-- (GREEN, translated in out/procs/InsertBeneficiary.sql)
--
-- For each test case: run the SQL Server block, run the PostgreSQL
-- block, then diff the captured result / error against "Expected".
-- =========================================================================

-- Test 1: normal insert
-- Expected: both sides insert a new row and return a new integer id.
-- SQL Server:
EXEC dbo.InsertBeneficiary
    @FirstName = 'Jordan', @LastName = 'Alvarez',
    @DateOfBirth = '1988-03-14', @EligibilityTier = 2;
-- PostgreSQL:
SELECT app.insertbeneficiary('Jordan', 'Alvarez', '1988-03-14', 2);


-- Test 2: default EligibilityTier (omit / NULL -> should default to 1)
-- Expected: both sides insert a row with eligibilitytier = 1.
-- SQL Server:
EXEC dbo.InsertBeneficiary
    @FirstName = 'Priya', @LastName = 'Natarajan',
    @DateOfBirth = '1975-11-02', @EligibilityTier = NULL;
-- PostgreSQL:
SELECT app.insertbeneficiary('Priya', 'Natarajan', '1975-11-02', NULL);


-- Test 3: blank first name
-- Expected: both sides reject the insert with an error
-- (SQL Server RAISERROR / PostgreSQL RAISE EXCEPTION).
-- SQL Server:
EXEC dbo.InsertBeneficiary
    @FirstName = '', @LastName = 'Alvarez',
    @DateOfBirth = '1988-03-14', @EligibilityTier = 1;
-- PostgreSQL:
SELECT app.insertbeneficiary('', 'Alvarez', '1988-03-14', 1);


-- Test 4: all-spaces first name
-- MIGRATION-REVIEW (carried from out/procs/InsertBeneficiary.sql):
-- SQL Server's LEN('   ') = 0, so the source proc REJECTS this input.
-- PostgreSQL's LENGTH('   ') = 3, so the translated function ACCEPTS it.
-- Expected divergence -- do not treat this as a harness failure; it is
-- the known, already-flagged behavior gap. Confirm with the business
-- owner whether an all-whitespace name is acceptable data before this
-- fixture pattern is reused on the real engagement.
-- SQL Server:
EXEC dbo.InsertBeneficiary
    @FirstName = '   ', @LastName = 'Alvarez',
    @DateOfBirth = '1988-03-14', @EligibilityTier = 1;
-- Expect: error
-- PostgreSQL:
SELECT app.insertbeneficiary('   ', 'Alvarez', '1988-03-14', 1);
-- Expect: succeeds, returns a new id (this is the divergence)