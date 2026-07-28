CREATE PROCEDURE [dbo].[GetTopRecentClaimsForBeneficiary]
    @BeneficiaryID INT,
    @MaxRows       INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@MaxRows)
        c.ClaimID,
        c.ClaimGuid,
        c.ServiceDate,
        c.BilledAmount,
        ISNULL(c.AllowedAmount, 0) AS AllowedAmount,
        c.ClaimStatus,
        p.ProviderName
    FROM [dbo].[Claim] c
    INNER JOIN [dbo].[Provider] p ON p.ProviderID = c.ProviderID
    WHERE c.BeneficiaryID = @BeneficiaryID
    ORDER BY c.ServiceDate DESC;
END
GO
