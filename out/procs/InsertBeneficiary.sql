-- Source: fixtures/synthetic-demo/procs/InsertBeneficiary.sql lines 1-23 (GREEN)
-- MIGRATION-REVIEW: source used LEN() to reject blank names. LEN ignores
-- trailing spaces, LENGTH does not -- a name of all-spaces would pass
-- this LENGTH check in PostgreSQL but fail LEN's check in SQL Server.
-- Confirm whether that edge case matters for this data.
-- MIGRATION-REVIEW: call-site change -- original proc returned a result
-- set (SELECT SCOPE_IDENTITY() AS NewBeneficiaryID). This is now a
-- scalar-returning function; callers must switch from EXEC + read
-- result set to `SELECT app.insertbeneficiary(...)`.
CREATE OR REPLACE FUNCTION app.insertbeneficiary(
    p_firstname       VARCHAR(50),
    p_lastname        VARCHAR(50),
    p_dateofbirth     TIMESTAMP,
    p_eligibilitytier SMALLINT DEFAULT 1
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_id INTEGER;
BEGIN
    IF LENGTH(p_firstname) = 0 OR LENGTH(p_lastname) = 0 THEN
        RAISE EXCEPTION 'First and last name are required.';
    END IF;

    INSERT INTO app.beneficiary
        (firstname, lastname, dateofbirth, eligibilitytier, isactive, createdat)
    VALUES
        (p_firstname, p_lastname, p_dateofbirth, COALESCE(p_eligibilitytier, 1), TRUE, CURRENT_TIMESTAMP)
    RETURNING beneficiaryid INTO v_new_id;

    RETURN v_new_id;
END;
$$;