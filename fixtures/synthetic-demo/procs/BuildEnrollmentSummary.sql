/*
    Builds a per-beneficiary enrollment summary, pulling in the most recent
    claim activity for each active plan enrollment via CROSS APPLY so the
    result set stays one row per enrollment even when claim history is deep.
*/
CREATE PROCEDURE [dbo].[BuildEnrollmentSummary]
    @AsOfDate DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @AsOfDate IS NULL
        SET @AsOfDate = GETDATE();

    IF OBJECT_ID('tempdb..#ActiveEnrollment') IS NOT NULL
        DROP TABLE #ActiveEnrollment;

    CREATE TABLE #ActiveEnrollment (
        EnrollmentID    INT PRIMARY KEY,
        BeneficiaryID   INT NOT NULL,
        PlanCode        NVARCHAR(20) NOT NULL,
        MonthlyPremium  MONEY NOT NULL
    );

    INSERT INTO #ActiveEnrollment (EnrollmentID, BeneficiaryID, PlanCode, MonthlyPremium)
    SELECT e.EnrollmentID, e.BeneficiaryID, e.PlanCode, e.MonthlyPremium
    FROM [dbo].[Enrollment] e
    WHERE e.EffectiveDate <= @AsOfDate
      AND (e.TerminationDate IS NULL OR e.TerminationDate > @AsOfDate);

    SELECT
        ae.EnrollmentID,
        ae.BeneficiaryID,
        ae.PlanCode,
        ae.MonthlyPremium,
        b.LastName,
        b.FirstName,
        lastClaim.ClaimID       AS MostRecentClaimID,
        lastClaim.ServiceDate   AS MostRecentServiceDate,
        lastClaim.BilledAmount  AS MostRecentBilledAmount
    FROM #ActiveEnrollment ae
    INNER JOIN [dbo].[Beneficiary] b ON b.BeneficiaryID = ae.BeneficiaryID
    CROSS APPLY (
        SELECT TOP (1) c.ClaimID, c.ServiceDate, c.BilledAmount
        FROM [dbo].[Claim] c
        WHERE c.BeneficiaryID = ae.BeneficiaryID
        ORDER BY c.ServiceDate DESC
    ) AS lastClaim;

    DROP TABLE #ActiveEnrollment;
END
GO
