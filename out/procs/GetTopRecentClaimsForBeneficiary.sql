-- Source: fixtures/synthetic-demo/procs/GetTopRecentClaimsForBeneficiary.sql lines 1-21 (GREEN)
-- MIGRATION-REVIEW: call-site change -- callers switch from
-- EXEC + read result set to `SELECT * FROM app.gettoprecentclaimsforbeneficiary(...)`.
CREATE OR REPLACE FUNCTION app.gettoprecentclaimsforbeneficiary(
    p_beneficiaryid INTEGER,
    p_maxrows       INTEGER DEFAULT 10
)
RETURNS TABLE (
    claimid       BIGINT,
    claimguid     UUID,
    servicedate   TIMESTAMP,
    billedamount  NUMERIC(19,4),
    allowedamount NUMERIC(19,4),
    claimstatus   SMALLINT,
    providername  VARCHAR(100)
)
LANGUAGE sql
AS $$
    SELECT
        c.claimid,
        c.claimguid,
        c.servicedate,
        c.billedamount,
        COALESCE(c.allowedamount, 0) AS allowedamount,
        c.claimstatus,
        p.providername
    FROM app.claim c
    INNER JOIN app.provider p ON p.providerid = c.providerid
    WHERE c.beneficiaryid = p_beneficiaryid
    ORDER BY c.servicedate DESC
    LIMIT p_maxrows;
$$;