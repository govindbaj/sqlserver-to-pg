-- Source: fixtures/synthetic-demo/procs/UpsertProviderEnrollment.sql lines 1-41 (AMBER)
-- MIGRATION-REVIEW: MERGE -> INSERT ... ON CONFLICT. Requires a unique
-- constraint/index on providernpi to target (uq_provider_npi from
-- out/tables.sql already provides this).
-- MIGRATION-REVIEW: source wrapped the MERGE in its own
-- BEGIN TRANSACTION/COMMIT/ROLLBACK with an unnamed ROLLBACK TRANSACTION
-- in the CATCH block. In SQL Server, an unnamed ROLLBACK rolls back to
-- the outermost transaction -- if this proc were ever called from
-- within a caller's own transaction, a failure here would roll back the
-- CALLER's work too, not just this upsert. The rewrite below uses a
-- PL/pgSQL EXCEPTION block instead, which only creates an implicit
-- savepoint around this statement -- a failure here does NOT roll back
-- any outer transaction the caller has open. Confirm this narrower
-- blast radius is acceptable, or that callers never invoke this inside
-- their own transaction.
-- MIGRATION-REVIEW: call-site change -- callers switch from
-- `EXEC dbo.UpsertProviderEnrollment ...` to `CALL app.upsertproviderenrollment(...)`.
CREATE OR REPLACE PROCEDURE app.upsertproviderenrollment(
    p_providernpi  VARCHAR(10),
    p_providername VARCHAR(100),
    p_taxonomycode VARCHAR(20) DEFAULT NULL,
    p_isactive     BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO app.provider (providernpi, providername, taxonomycode, isactive, enrolleddate)
    VALUES (p_providernpi, p_providername, p_taxonomycode, p_isactive, CURRENT_TIMESTAMP)
    ON CONFLICT (providernpi) DO UPDATE SET
        providername = EXCLUDED.providername,
        taxonomycode = EXCLUDED.taxonomycode,
        isactive     = EXCLUDED.isactive;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'UpsertProviderEnrollment failed for NPI %: %', p_providernpi, SQLERRM;
END;
$$;