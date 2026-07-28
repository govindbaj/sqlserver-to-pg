-- =========================================================================
-- Verification harness: dbo.UpsertProviderEnrollment -> app.upsertproviderenrollment
-- (AMBER, translated in out/procs/UpsertProviderEnrollment.sql)
--
-- For each test case: run the SQL Server block, run the PostgreSQL
-- block, then diff the resulting dbo.Provider / app.provider row.
-- =========================================================================

-- Test 1: insert path -- brand-new ProviderNPI
-- Expected: both sides insert one new row with matching column values.
-- SQL Server:
EXEC dbo.UpsertProviderEnrollment
    @ProviderNPI = '1234567890', @ProviderName = 'Newline Health',
    @TaxonomyCode = '207Q00000X', @IsActive = 1;
SELECT * FROM dbo.Provider WHERE ProviderNPI = '1234567890';
-- PostgreSQL:
CALL app.upsertproviderenrollment('1234567890', 'Newline Health', '207Q00000X', TRUE);
SELECT * FROM app.provider WHERE providernpi = '1234567890';


-- Test 2: update path -- existing ProviderNPI, changed fields
-- Expected: both sides update the SAME row (no duplicate), with the
-- new ProviderName/TaxonomyCode/IsActive values, EnrolledDate unchanged.
-- SQL Server:
EXEC dbo.UpsertProviderEnrollment
    @ProviderNPI = '1234567890', @ProviderName = 'Newline Health Group',
    @TaxonomyCode = '207R00000X', @IsActive = 0;
SELECT * FROM dbo.Provider WHERE ProviderNPI = '1234567890';
-- PostgreSQL:
CALL app.upsertproviderenrollment('1234567890', 'Newline Health Group', '207R00000X', FALSE);
SELECT * FROM app.provider WHERE providernpi = '1234567890';


-- Test 3: idempotency -- call twice in a row with identical arguments
-- Expected: both sides end up with exactly one row for this NPI, not two.
-- SQL Server:
EXEC dbo.UpsertProviderEnrollment
    @ProviderNPI = '5550001234', @ProviderName = 'Riverside Clinic',
    @TaxonomyCode = NULL, @IsActive = 1;
EXEC dbo.UpsertProviderEnrollment
    @ProviderNPI = '5550001234', @ProviderName = 'Riverside Clinic',
    @TaxonomyCode = NULL, @IsActive = 1;
SELECT COUNT(*) AS row_count FROM dbo.Provider WHERE ProviderNPI = '5550001234';
-- PostgreSQL:
CALL app.upsertproviderenrollment('5550001234', 'Riverside Clinic', NULL, TRUE);
CALL app.upsertproviderenrollment('5550001234', 'Riverside Clinic', NULL, TRUE);
SELECT COUNT(*) AS row_count FROM app.provider WHERE providernpi = '5550001234';


-- Test 4 (manual review only, not a plain assert): transaction blast radius
-- MIGRATION-REVIEW (carried from out/procs/UpsertProviderEnrollment.sql):
-- Call this proc from inside an outer transaction that you then force to
-- fail on the NEXT statement after the call. On SQL Server, the source's
-- unnamed ROLLBACK TRANSACTION (if it ever fired) would have rolled back
-- the caller's outer transaction too. On PostgreSQL, the EXCEPTION block
-- only creates an implicit savepoint around this statement -- the
-- caller's outer transaction survives. This is an intentional, already-
-- flagged behavior change, not a harness bug -- confirm with the
-- reviewer that no caller relies on the old all-or-nothing rollback.