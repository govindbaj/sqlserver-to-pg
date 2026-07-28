-- =========================================================================
-- Verification queries for fixtures/synthetic-demo/tables.sql -> out/tables.sql
-- Run the SQL Server block against source, the PostgreSQL block against
-- target, and diff the results. All comparisons should match exactly
-- unless a MIGRATION-REVIEW note says otherwise.
--
-- Checksum method: MD5 of a canonical, explicitly-formatted string per
-- row, order-independent SUM of the first 8 bytes as a bigint. This is
-- NOT the same algorithm as SQL Server's CHECKSUM_AGG/HASHBYTES output
-- vs PostgreSQL's md5() -- the point is not to get identical numbers
-- cross-platform, but to run the SAME canonicalization logic on each
-- side and confirm the two sums land on the same value, proving no row
-- was silently altered. If the two format strings below ever drift out
-- of sync (e.g. someone changes decimal places on one side only), this
-- check will false-positive a mismatch -- keep them mirrored.
-- =========================================================================


-- =========================================================================
-- dbo.Beneficiary -> app.beneficiary
-- =========================================================================

-- 1. Row count
-- SQL Server:
SELECT COUNT(*) AS row_count FROM dbo.Beneficiary;
-- PostgreSQL:
SELECT COUNT(*) AS row_count FROM app.beneficiary;

-- 2. Column checksum (dateofbirth, eligibilitytier, createdat, modifiedat)
-- SQL Server:
SELECT SUM(CAST(CONVERT(BIGINT, CONVERT(VARBINARY(8), HASHBYTES('MD5',
    CONVERT(VARCHAR, DateOfBirth, 121) + '|' +
    CONVERT(VARCHAR, EligibilityTier) + '|' +
    CONVERT(VARCHAR, CreatedAt, 121) + '|' +
    ISNULL(CONVERT(VARCHAR, ModifiedAt, 121), 'NULL')
))) AS BIGINT)) AS row_hash_sum
FROM dbo.Beneficiary;
-- PostgreSQL:
SELECT SUM(('x' || substr(md5(
    to_char(dateofbirth, 'YYYY-MM-DD HH24:MI:SS.MS') || '|' ||
    eligibilitytier::text || '|' ||
    to_char(createdat, 'YYYY-MM-DD HH24:MI:SS.MS') || '|' ||
    COALESCE(to_char(modifiedat, 'YYYY-MM-DD HH24:MI:SS.MS'), 'NULL')
), 1, 16))::bit(64)::bigint) AS row_hash_sum
FROM app.beneficiary;

-- 3. Null counts (modifiedat, notes)
-- SQL Server:
SELECT
    COUNT(*) - COUNT(ModifiedAt) AS modifiedat_nulls,
    COUNT(*) - COUNT(Notes)      AS notes_nulls
FROM dbo.Beneficiary;
-- PostgreSQL:
SELECT
    COUNT(*) - COUNT(modifiedat) AS modifiedat_nulls,
    COUNT(*) - COUNT(notes)      AS notes_nulls
FROM app.beneficiary;

-- 4. Min/max (dateofbirth, eligibilitytier, createdat, modifiedat)
-- SQL Server:
SELECT MIN(DateOfBirth) AS min_dob, MAX(DateOfBirth) AS max_dob,
       MIN(EligibilityTier) AS min_tier, MAX(EligibilityTier) AS max_tier,
       MIN(CreatedAt) AS min_created, MAX(CreatedAt) AS max_created,
       MIN(ModifiedAt) AS min_modified, MAX(ModifiedAt) AS max_modified
FROM dbo.Beneficiary;
-- PostgreSQL:
SELECT MIN(dateofbirth) AS min_dob, MAX(dateofbirth) AS max_dob,
       MIN(eligibilitytier) AS min_tier, MAX(eligibilitytier) AS max_tier,
       MIN(createdat) AS min_created, MAX(createdat) AS max_created,
       MIN(modifiedat) AS min_modified, MAX(modifiedat) AS max_modified
FROM app.beneficiary;

-- 5. Referential integrity: Beneficiary is a base table with no outgoing
-- FK. Orphan checks for its children (Enrollment, Claim) appear below.


-- =========================================================================
-- dbo.Provider -> app.provider
-- =========================================================================

-- 1. Row count
-- SQL Server:
SELECT COUNT(*) AS row_count FROM dbo.Provider;
-- PostgreSQL:
SELECT COUNT(*) AS row_count FROM app.provider;

-- 2. Column checksum (enrolleddate -- the only numeric/date column here)
-- SQL Server:
SELECT SUM(CAST(CONVERT(BIGINT, CONVERT(VARBINARY(8), HASHBYTES('MD5',
    CONVERT(VARCHAR, EnrolledDate, 121)
))) AS BIGINT)) AS row_hash_sum
FROM dbo.Provider;
-- PostgreSQL:
SELECT SUM(('x' || substr(md5(
    to_char(enrolleddate, 'YYYY-MM-DD HH24:MI:SS.MS')
), 1, 16))::bit(64)::bigint) AS row_hash_sum
FROM app.provider;

-- 3. Null counts (taxonomycode)
-- SQL Server:
SELECT COUNT(*) - COUNT(TaxonomyCode) AS taxonomycode_nulls FROM dbo.Provider;
-- PostgreSQL:
SELECT COUNT(*) - COUNT(taxonomycode) AS taxonomycode_nulls FROM app.provider;

-- 4. Min/max (enrolleddate)
-- SQL Server:
SELECT MIN(EnrolledDate) AS min_enrolled, MAX(EnrolledDate) AS max_enrolled FROM dbo.Provider;
-- PostgreSQL:
SELECT MIN(enrolleddate) AS min_enrolled, MAX(enrolleddate) AS max_enrolled FROM app.provider;

-- 5. Referential integrity: Provider is a base table with no outgoing
-- FK. Orphan check for its child (Claim) appears below.


-- =========================================================================
-- dbo.Enrollment -> app.enrollment
-- =========================================================================

-- 1. Row count
-- SQL Server:
SELECT COUNT(*) AS row_count FROM dbo.Enrollment;
-- PostgreSQL:
SELECT COUNT(*) AS row_count FROM app.enrollment;

-- 2. Column checksum (effectivedate, terminationdate, monthlypremium, createdat)
-- SQL Server:
SELECT SUM(CAST(CONVERT(BIGINT, CONVERT(VARBINARY(8), HASHBYTES('MD5',
    CONVERT(VARCHAR, EffectiveDate, 121) + '|' +
    ISNULL(CONVERT(VARCHAR, TerminationDate, 121), 'NULL') + '|' +
    CONVERT(VARCHAR, MonthlyPremium) + '|' +
    CONVERT(VARCHAR, CreatedAt, 121)
))) AS BIGINT)) AS row_hash_sum
FROM dbo.Enrollment;
-- PostgreSQL:
SELECT SUM(('x' || substr(md5(
    to_char(effectivedate, 'YYYY-MM-DD HH24:MI:SS.MS') || '|' ||
    COALESCE(to_char(terminationdate, 'YYYY-MM-DD HH24:MI:SS.MS'), 'NULL') || '|' ||
    to_char(monthlypremium, 'FM999999999999999990.0000') || '|' ||
    to_char(createdat, 'YYYY-MM-DD HH24:MI:SS.MS')
), 1, 16))::bit(64)::bigint) AS row_hash_sum
FROM app.enrollment;

-- 3. Null counts (terminationdate)
-- SQL Server:
SELECT COUNT(*) - COUNT(TerminationDate) AS terminationdate_nulls FROM dbo.Enrollment;
-- PostgreSQL:
SELECT COUNT(*) - COUNT(terminationdate) AS terminationdate_nulls FROM app.enrollment;

-- 4. Min/max
-- SQL Server:
SELECT MIN(EffectiveDate) AS min_effective, MAX(EffectiveDate) AS max_effective,
       MIN(TerminationDate) AS min_term, MAX(TerminationDate) AS max_term,
       MIN(MonthlyPremium) AS min_premium, MAX(MonthlyPremium) AS max_premium,
       MIN(CreatedAt) AS min_created, MAX(CreatedAt) AS max_created
FROM dbo.Enrollment;
-- PostgreSQL:
SELECT MIN(effectivedate) AS min_effective, MAX(effectivedate) AS max_effective,
       MIN(terminationdate) AS min_term, MAX(terminationdate) AS max_term,
       MIN(monthlypremium) AS min_premium, MAX(monthlypremium) AS max_premium,
       MIN(createdat) AS min_created, MAX(createdat) AS max_created
FROM app.enrollment;

-- 5. Referential integrity (orphan detection): enrollment -> beneficiary
-- Expected result: 0 rows on both sides.
-- SQL Server:
SELECT COUNT(*) AS orphaned_enrollments
FROM dbo.Enrollment e
LEFT JOIN dbo.Beneficiary b ON b.BeneficiaryID = e.BeneficiaryID
WHERE b.BeneficiaryID IS NULL;
-- PostgreSQL:
SELECT COUNT(*) AS orphaned_enrollments
FROM app.enrollment e
LEFT JOIN app.beneficiary b ON b.beneficiaryid = e.beneficiaryid
WHERE b.beneficiaryid IS NULL;


-- =========================================================================
-- dbo.Claim -> app.claim
-- =========================================================================

-- 1. Row count
-- SQL Server:
SELECT COUNT(*) AS row_count FROM dbo.Claim;
-- PostgreSQL:
SELECT COUNT(*) AS row_count FROM app.claim;

-- 2. Column checksum (servicedate, submitteddate, billedamount, allowedamount)
-- SQL Server:
SELECT SUM(CAST(CONVERT(BIGINT, CONVERT(VARBINARY(8), HASHBYTES('MD5',
    CONVERT(VARCHAR, ServiceDate, 121) + '|' +
    CONVERT(VARCHAR, SubmittedDate, 121) + '|' +
    CONVERT(VARCHAR, BilledAmount) + '|' +
    ISNULL(CONVERT(VARCHAR, AllowedAmount), 'NULL')
))) AS BIGINT)) AS row_hash_sum
FROM dbo.Claim;
-- PostgreSQL:
SELECT SUM(('x' || substr(md5(
    to_char(servicedate, 'YYYY-MM-DD HH24:MI:SS.MS') || '|' ||
    to_char(submitteddate, 'YYYY-MM-DD HH24:MI:SS.MS') || '|' ||
    to_char(billedamount, 'FM999999999999999990.0000') || '|' ||
    COALESCE(to_char(allowedamount, 'FM999999999999999990.0000'), 'NULL')
), 1, 16))::bit(64)::bigint) AS row_hash_sum
FROM app.claim;

-- 3. Null counts (allowedamount, denialreason)
-- SQL Server:
SELECT COUNT(*) - COUNT(AllowedAmount) AS allowedamount_nulls,
       COUNT(*) - COUNT(DenialReason) AS denialreason_nulls
FROM dbo.Claim;
-- PostgreSQL:
SELECT COUNT(*) - COUNT(allowedamount) AS allowedamount_nulls,
       COUNT(*) - COUNT(denialreason) AS denialreason_nulls
FROM app.claim;

-- 4. Min/max
-- SQL Server:
SELECT MIN(ServiceDate) AS min_service, MAX(ServiceDate) AS max_service,
       MIN(SubmittedDate) AS min_submitted, MAX(SubmittedDate) AS max_submitted,
       MIN(BilledAmount) AS min_billed, MAX(BilledAmount) AS max_billed,
       MIN(AllowedAmount) AS min_allowed, MAX(AllowedAmount) AS max_allowed
FROM dbo.Claim;
-- PostgreSQL:
SELECT MIN(servicedate) AS min_service, MAX(servicedate) AS max_service,
       MIN(submitteddate) AS min_submitted, MAX(submitteddate) AS max_submitted,
       MIN(billedamount) AS min_billed, MAX(billedamount) AS max_billed,
       MIN(allowedamount) AS min_allowed, MAX(allowedamount) AS max_allowed
FROM app.claim;

-- 5. Referential integrity (orphan detection): claim -> beneficiary, claim -> provider
-- Expected result: 0 rows on both sides, for both checks.
-- SQL Server:
SELECT COUNT(*) AS orphaned_claims_beneficiary
FROM dbo.Claim c
LEFT JOIN dbo.Beneficiary b ON b.BeneficiaryID = c.BeneficiaryID
WHERE b.BeneficiaryID IS NULL;

SELECT COUNT(*) AS orphaned_claims_provider
FROM dbo.Claim c
LEFT JOIN dbo.Provider p ON p.ProviderID = c.ProviderID
WHERE p.ProviderID IS NULL;
-- PostgreSQL:
SELECT COUNT(*) AS orphaned_claims_beneficiary
FROM app.claim c
LEFT JOIN app.beneficiary b ON b.beneficiaryid = c.beneficiaryid
WHERE b.beneficiaryid IS NULL;

SELECT COUNT(*) AS orphaned_claims_provider
FROM app.claim c
LEFT JOIN app.provider p ON p.providerid = c.providerid
WHERE p.providerid IS NULL;


-- =========================================================================
-- dbo.ClaimAttachment -> app.claimattachment
-- =========================================================================

-- 1. Row count
-- SQL Server:
SELECT COUNT(*) AS row_count FROM dbo.ClaimAttachment;
-- PostgreSQL:
SELECT COUNT(*) AS row_count FROM app.claimattachment;

-- 2. Column checksum (uploadedat -- the only numeric/date column here)
-- SQL Server:
SELECT SUM(CAST(CONVERT(BIGINT, CONVERT(VARBINARY(8), HASHBYTES('MD5',
    CONVERT(VARCHAR, UploadedAt, 121)
))) AS BIGINT)) AS row_hash_sum
FROM dbo.ClaimAttachment;
-- PostgreSQL:
SELECT SUM(('x' || substr(md5(
    to_char(uploadedat, 'YYYY-MM-DD HH24:MI:SS.MS')
), 1, 16))::bit(64)::bigint) AS row_hash_sum
FROM app.claimattachment;

-- MIGRATION-REVIEW: filebytes (VARBINARY(MAX) -> BYTEA) is a binary blob,
-- out of scope for the numeric/date checksum above by design, but is
-- exactly the kind of column silent corruption/truncation would hit
-- hardest. Optional addendum -- hash the binary content directly:
-- SQL Server:
SELECT SUM(CAST(CONVERT(BIGINT, CONVERT(VARBINARY(8), HASHBYTES('MD5', FileBytes))) AS BIGINT)) AS filebytes_hash_sum
FROM dbo.ClaimAttachment;
-- PostgreSQL:
SELECT SUM(('x' || substr(md5(filebytes), 1, 16))::bit(64)::bigint) AS filebytes_hash_sum
FROM app.claimattachment;

-- 3. Null counts: no nullable columns in this table (all NOT NULL) --
-- null-count check intentionally omitted.

-- 4. Min/max (uploadedat)
-- SQL Server:
SELECT MIN(UploadedAt) AS min_uploaded, MAX(UploadedAt) AS max_uploaded FROM dbo.ClaimAttachment;
-- PostgreSQL:
SELECT MIN(uploadedat) AS min_uploaded, MAX(uploadedat) AS max_uploaded FROM app.claimattachment;

-- 5. Referential integrity (orphan detection): claimattachment -> claim
-- Expected result: 0 rows on both sides.
-- SQL Server:
SELECT COUNT(*) AS orphaned_attachments
FROM dbo.ClaimAttachment a
LEFT JOIN dbo.Claim c ON c.ClaimID = a.ClaimID
WHERE c.ClaimID IS NULL;
-- PostgreSQL:
SELECT COUNT(*) AS orphaned_attachments
FROM app.claimattachment a
LEFT JOIN app.claim c ON c.claimid = a.claimid
WHERE c.claimid IS NULL;