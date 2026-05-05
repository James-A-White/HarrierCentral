-- Run-once migration: create HC.PublicWebAdminToken
-- Short-lived one-time tokens that the Flutter portal generates and passes
-- to the Next.js admin UI via URL parameter.
CREATE TABLE [HC].[PublicWebAdminToken] (
    [Id]         UNIQUEIDENTIFIER NOT NULL CONSTRAINT [DF_PublicWebAdminToken_Id] DEFAULT NEWID(),
    [HasherId]   UNIQUEIDENTIFIER NOT NULL,
    [KennelSlug] NVARCHAR(100)   NOT NULL,
    [ExpiresAt]  DATETIMEOFFSET(7) NOT NULL,
    [CreatedAt]  DATETIMEOFFSET(7) NOT NULL CONSTRAINT [DF_PublicWebAdminToken_CreatedAt] DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT [PK_PublicWebAdminToken] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_PublicWebAdminToken_Hasher] FOREIGN KEY ([HasherId]) REFERENCES [HC].[Hasher] ([id])
);
GO
