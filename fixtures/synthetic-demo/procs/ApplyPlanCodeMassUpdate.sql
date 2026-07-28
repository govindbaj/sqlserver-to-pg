/*
    Admin utility invoked when a plan is renamed/merged mid-year. Updates
    Enrollment rows to the new plan code and writes an audit row, wrapped
    in a named savepoint so the audit insert can be independently rolled
    back if it fails without undoing the enrollment update. Table/column
    to filter on is chosen by the caller at runtime, so the WHERE clause
    is assembled dynamically.
*/
CREATE PROCEDURE [dbo].[ApplyPlanCodeMassUpdate]
    @OldPlanCode   NVARCHAR(20),
    @NewPlanCode   NVARCHAR(20),
    @FilterColumn  SYSNAME = NULL,
    @FilterValue   NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION OuterUpdate;

    DECLARE @Sql NVARCHAR(MAX) = N'
        UPDATE [dbo].[Enrollment]
        SET PlanCode = @NewPlanCode
        WHERE PlanCode = @OldPlanCode';

    IF @FilterColumn IS NOT NULL
        SET @Sql = @Sql + N' AND ' + QUOTENAME(@FilterColumn) + N' = @FilterValue';

    EXEC sp_executesql
        @Sql,
        N'@OldPlanCode NVARCHAR(20), @NewPlanCode NVARCHAR(20), @FilterValue NVARCHAR(100)',
        @OldPlanCode = @OldPlanCode,
        @NewPlanCode = @NewPlanCode,
        @FilterValue = @FilterValue;

    SAVE TRANSACTION AuditPoint;

    BEGIN TRY
        INSERT INTO [dbo].[PlanCodeAudit] (OldPlanCode, NewPlanCode, ChangedAt)
        VALUES (@OldPlanCode, @NewPlanCode, GETDATE());
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION AuditPoint;
    END CATCH

    COMMIT TRANSACTION OuterUpdate;
END
GO
