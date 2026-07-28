CREATE PROCEDURE [dbo].[InsertBeneficiary]
    @FirstName       NVARCHAR(50),
    @LastName        NVARCHAR(50),
    @DateOfBirth     DATETIME,
    @EligibilityTier TINYINT = 1
AS
BEGIN
    SET NOCOUNT ON;

    IF LEN(@FirstName) = 0 OR LEN(@LastName) = 0
    BEGIN
        RAISERROR('First and last name are required.', 16, 1);
        RETURN;
    END

    INSERT INTO [dbo].[Beneficiary]
        (FirstName, LastName, DateOfBirth, EligibilityTier, IsActive, CreatedAt)
    VALUES
        (@FirstName, @LastName, @DateOfBirth, ISNULL(@EligibilityTier, 1), 1, GETDATE());

    SELECT SCOPE_IDENTITY() AS NewBeneficiaryID;
END
GO
