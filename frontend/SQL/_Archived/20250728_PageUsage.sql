IF OBJECT_ID('dbo.PageUsageLog', 'U') IS NULL
    
    CREATE TABLE [dbo].[PageUsageLog](
        [Id] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [UserId] [int] NOT NULL,
        [Dt] [datetime] NOT NULL CONSTRAINT DF_PageUsageLog_Dt DEFAULT (getdate()),
        [Browser] [varchar](100) NULL,
        [IsMobile] [bit] NOT NULL CONSTRAINT DF_PageUsageLog_IsMobile DEFAULT ((0)),
        [Activity] [nvarchar](128) NULL
    )

GO

CREATE OR ALTER PROCEDURE [dbo].[LogPageUsage]
    @UserId INT,
    @Dt DATETIME,
    @Browser VARCHAR(100),
    @IsMobile BIT,
    @Activity NVARCHAR(128) = NULL
AS
BEGIN
    INSERT INTO dbo.PageUsageLog (UserId, Dt, Browser, IsMobile, Activity)
    VALUES (@UserId, @Dt, @Browser, @IsMobile, @Activity)
END
GO