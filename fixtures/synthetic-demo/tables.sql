/* =========================================================================
   Synthetic Medicaid-like schema — FICTIONAL data model for migration
   tooling development. No real client tables, columns, or PHI.
   ========================================================================= */

CREATE TABLE [dbo].[Beneficiary] (
    [BeneficiaryID]     INT IDENTITY(1,1) NOT NULL,
    [MemberID]          UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    [FirstName]         NVARCHAR(50) NOT NULL,
    [LastName]          NVARCHAR(50) NOT NULL,
    [DateOfBirth]       DATETIME NOT NULL,
    [IsActive]          BIT NOT NULL DEFAULT 1,
    [EligibilityTier]   TINYINT NOT NULL DEFAULT 1,
    [CreatedAt]         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    [ModifiedAt]        DATETIME2 NULL,
    [Notes]             NVARCHAR(MAX) NULL,
    CONSTRAINT [PK_Beneficiary] PRIMARY KEY CLUSTERED ([BeneficiaryID]),
    CONSTRAINT [UQ_Beneficiary_MemberID] UNIQUE ([MemberID])
);
GO

CREATE TABLE [dbo].[Provider] (
    [ProviderID]        INT IDENTITY(1,1) NOT NULL,
    [ProviderNPI]       VARCHAR(10) NOT NULL,
    [ProviderName]      NVARCHAR(100) NOT NULL,
    [TaxonomyCode]      VARCHAR(20) NULL,
    [IsActive]          BIT NOT NULL DEFAULT 1,
    [EnrolledDate]      DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT [PK_Provider] PRIMARY KEY CLUSTERED ([ProviderID]),
    CONSTRAINT [UQ_Provider_NPI] UNIQUE ([ProviderNPI])
);
GO

CREATE TABLE [dbo].[Enrollment] (
    [EnrollmentID]      INT IDENTITY(1,1) NOT NULL,
    [BeneficiaryID]     INT NOT NULL,
    [PlanCode]          NVARCHAR(20) NOT NULL,
    [EffectiveDate]     DATETIME NOT NULL,
    [TerminationDate]   DATETIME NULL,
    [MonthlyPremium]    MONEY NOT NULL DEFAULT 0,
    [IsCapitated]       BIT NOT NULL DEFAULT 0,
    [CreatedAt]         DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_Enrollment] PRIMARY KEY CLUSTERED ([EnrollmentID]),
    CONSTRAINT [FK_Enrollment_Beneficiary]
        FOREIGN KEY ([BeneficiaryID]) REFERENCES [dbo].[Beneficiary]([BeneficiaryID])
);
GO

CREATE TABLE [dbo].[Claim] (
    [ClaimID]           BIGINT IDENTITY(1,1) NOT NULL,
    [ClaimGuid]         UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
    [BeneficiaryID]     INT NOT NULL,
    [ProviderID]        INT NOT NULL,
    [ServiceDate]       DATETIME NOT NULL,
    [SubmittedDate]     DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    [BilledAmount]      MONEY NOT NULL,
    [AllowedAmount]     MONEY NULL,
    [ClaimStatus]       TINYINT NOT NULL DEFAULT 0, -- 0=Submitted,1=Adjudicated,2=Paid,3=Denied
    [DenialReason]      NVARCHAR(200) NULL,
    CONSTRAINT [PK_Claim] PRIMARY KEY CLUSTERED ([ClaimID]),
    CONSTRAINT [FK_Claim_Beneficiary]
        FOREIGN KEY ([BeneficiaryID]) REFERENCES [dbo].[Beneficiary]([BeneficiaryID]),
    CONSTRAINT [FK_Claim_Provider]
        FOREIGN KEY ([ProviderID]) REFERENCES [dbo].[Provider]([ProviderID])
);
GO

CREATE TABLE [dbo].[ClaimAttachment] (
    [AttachmentID]      INT IDENTITY(1,1) NOT NULL,
    [ClaimID]           BIGINT NOT NULL,
    [FileName]          NVARCHAR(255) NOT NULL,
    [ContentType]       VARCHAR(100) NOT NULL DEFAULT 'application/octet-stream',
    [FileBytes]         VARBINARY(MAX) NOT NULL,
    [UploadedAt]        DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT [PK_ClaimAttachment] PRIMARY KEY CLUSTERED ([AttachmentID]),
    CONSTRAINT [FK_ClaimAttachment_Claim]
        FOREIGN KEY ([ClaimID]) REFERENCES [dbo].[Claim]([ClaimID])
);
GO
