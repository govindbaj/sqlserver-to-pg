/*
    Idempotent load of a provider roster feed. Source system periodically
    resends full provider records; existing rows are updated in place and
    new NPIs are inserted. Wrapped in TRY/CATCH so a bad row in the feed
    rolls back cleanly instead of leaving a half-applied batch.
*/
CREATE PROCEDURE [dbo].[UpsertProviderEnrollment]
    @ProviderNPI  VARCHAR(10),
    @ProviderName NVARCHAR(100),
    @TaxonomyCode VARCHAR(20) = NULL,
    @IsActive     BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        MERGE [dbo].[Provider] AS target
        USING (SELECT @ProviderNPI AS ProviderNPI) AS src
            ON target.ProviderNPI = src.ProviderNPI
        WHEN MATCHED THEN
            UPDATE SET
                ProviderName = @ProviderName,
                TaxonomyCode = @TaxonomyCode,
                IsActive     = @IsActive
        WHEN NOT MATCHED THEN
            INSERT (ProviderNPI, ProviderName, TaxonomyCode, IsActive, EnrolledDate)
            VALUES (@ProviderNPI, @ProviderName, @TaxonomyCode, @IsActive, GETDATE());

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrMsg NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR('UpsertProviderEnrollment failed for NPI %s: %s', 16, 1, @ProviderNPI, @ErrMsg);
    END CATCH
END
GO
