-- Source: fixtures/synthetic-demo/procs/BuildEnrollmentSummary.sql lines 1-52 (AMBER)
-- MIGRATION-REVIEW: #ActiveEnrollment temp table replaced with a CTE
-- (source data volume didn't warrant a real temp table).
-- MIGRATION-REVIEW: CROSS APPLY -> JOIN LATERAL ... ON TRUE preserves the
-- INNER JOIN semantics of CROSS APPLY -- enrollments with no claim
-- history are dropped from the result, same as the source. If the
-- intent was ever "show the enrollment even with no claims yet", this
-- needs LEFT JOIN LATERAL (OUTER APPLY equivalent) instead.
-- MIGRATION-REVIEW: call-site change -- callers switch from
-- EXEC + read result set to `SELECT * FROM app.buildenrollmentsummary(...)`.
CREATE OR REPLACE FUNCTION app.buildenrollmentsummary(
    p_asofdate TIMESTAMP DEFAULT NULL
)
RETURNS TABLE (
    enrollmentid           INTEGER,
    beneficiaryid          INTEGER,
    plancode               VARCHAR(20),
    monthlypremium         NUMERIC(19,4),
    lastname               VARCHAR(50),
    firstname              VARCHAR(50),
    mostrecentclaimid      BIGINT,
    mostrecentservicedate  TIMESTAMP,
    mostrecentbilledamount NUMERIC(19,4)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_asofdate TIMESTAMP := COALESCE(p_asofdate, CURRENT_TIMESTAMP);
BEGIN
    RETURN QUERY
    WITH active_enrollment AS (
        SELECT e.enrollmentid, e.beneficiaryid, e.plancode, e.monthlypremium
        FROM app.enrollment e
        WHERE e.effectivedate <= v_asofdate
          AND (e.terminationdate IS NULL OR e.terminationdate > v_asofdate)
    )
    SELECT
        ae.enrollmentid,
        ae.beneficiaryid,
        ae.plancode,
        ae.monthlypremium,
        b.lastname,
        b.firstname,
        lastclaim.claimid,
        lastclaim.servicedate,
        lastclaim.billedamount
    FROM active_enrollment ae
    INNER JOIN app.beneficiary b ON b.beneficiaryid = ae.beneficiaryid
    JOIN LATERAL (
        SELECT c.claimid, c.servicedate, c.billedamount
        FROM app.claim c
        WHERE c.beneficiaryid = ae.beneficiaryid
        ORDER BY c.servicedate DESC
        LIMIT 1
    ) AS lastclaim ON TRUE;
END;
$$;