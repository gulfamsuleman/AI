IF OBJECT_ID('dbo.PageUsageLog', 'U') IS NOT NULL
    DROP TABLE dbo.PageUsageLog;

CREATE TABLE dbo.PageUsageLog (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    Url VARCHAR(100) NOT NULL,
    Dt DATETIME NOT NULL DEFAULT GETDATE(),
    Browser VARCHAR(100) NULL,
    IsMobile BIT NOT NULL DEFAULT 0,
    ViewName NVARCHAR(128) NULL
);

IF OBJECT_ID('dbo.LogPageUsage', 'P') IS NOT NULL
    DROP PROCEDURE dbo.LogPageUsage;
GO

CREATE PROCEDURE dbo.LogPageUsage
    @UserId INT,
    @Url VARCHAR(100),
    @Dt DATETIME,
    @Browser VARCHAR(100),
    @IsMobile BIT,
    @ViewName NVARCHAR(128) = NULL
AS
BEGIN
    INSERT INTO dbo.PageUsageLog (UserId, Url, Dt, Browser, IsMobile, ViewName)
    VALUES (@UserId, @Url, @Dt, @Browser, @IsMobile, @ViewName)
END
GO