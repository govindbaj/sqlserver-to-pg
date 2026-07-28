/*
    Nightly batch job: re-runs the allowed-amount pricing logic for every
    submitted claim against the current fee schedule. Pricing depends on
    the running total already accumulated for the beneficiary this plan
    year (capitation offsets), so claims must be priced in service-date
    order rather than as a single set-based update.
*/
CREATE PROCEDURE [dbo].[RecalculateAllowedAmounts]
    @PlanYearStart DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ClaimID INT;
    DECLARE @BeneficiaryID INT;
    DECLARE @BilledAmount MONEY;
    DECLARE @RunningTotal MONEY;
    DECLARE @PriorBeneficiaryID INT = -1;
    DECLARE @AllowedAmount MONEY;

    DECLARE claim_cursor CURSOR FOR
        SELECT ClaimID, BeneficiaryID, BilledAmount
        FROM [dbo].[Claim]
        WHERE ServiceDate >= @PlanYearStart
          AND ClaimStatus = 0
        ORDER BY BeneficiaryID, ServiceDate;

    OPEN claim_cursor;
    FETCH NEXT FROM claim_cursor INTO @ClaimID, @BeneficiaryID, @BilledAmount;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @BeneficiaryID <> @PriorBeneficiaryID
        BEGIN
            SET @RunningTotal = 0;
            SET @PriorBeneficiaryID = @BeneficiaryID;
        END

        SET @RunningTotal = @RunningTotal + @BilledAmount;

        IF @RunningTotal <= 5000.00
            SET @AllowedAmount = @BilledAmount;
        ELSE IF @RunningTotal - @BilledAmount >= 5000.00
            SET @AllowedAmount = @BilledAmount * 0.8;
        ELSE
            SET @AllowedAmount = (5000.00 - (@RunningTotal - @BilledAmount))
                                  + (@RunningTotal - 5000.00) * 0.8;

        UPDATE [dbo].[Claim]
        SET AllowedAmount = @AllowedAmount,
            ClaimStatus = 1
        WHERE ClaimID = @ClaimID;

        FETCH NEXT FROM claim_cursor INTO @ClaimID, @BeneficiaryID, @BilledAmount;
    END

    CLOSE claim_cursor;
    DEALLOCATE claim_cursor;
END
GO
