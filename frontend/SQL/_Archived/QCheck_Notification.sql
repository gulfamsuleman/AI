DROP TABLE IF EXISTS dbo.QCheck_Notifications;
DROP TABLE IF EXISTS dbo.QCheck_NotificationArchive;

GO
CREATE TABLE dbo.QCheck_Notifications (
	UserId INT NOT NULL,
	CreatedDate DATETIME NOT NULL DEFAULT(GETUTCDATE()),
	ListDate DATETIME NULL,
	ReadDate DATETIME NULL,
	[Subject] VARCHAR(255) NOT NULL,
	[Detail] VARCHAR(MAX) NULL,
	[Url] VARCHAR(255) NULL,
	[UrlText] VARCHAR(50) NULL,
	[Id] UNIQUEIDENTIFIER NOT NULL DEFAULT(NEWSEQUENTIALID()),
	CONSTRAINT PK_QCheck_Notifications PRIMARY KEY CLUSTERED (
		UserId ASC,
		CreatedDate ASC
	)
)
GO
CREATE UNIQUE NONCLUSTERED INDEX ixId ON dbo.QCheck_Notifications ( Id ASC)
GO
CREATE TABLE dbo.QCheck_NotificationArchive (
	-- allows appending to archive table without fragmentation
	[UID] UNIQUEIDENTIFIER NOT NULL DEFAULT(NEWSEQUENTIALID()),
	ArchiveDate DATETIME NOT NULL DEFAULT(GETDATE()),
	UserId INT NOT NULL,
	CreatedDate DATETIME NOT NULL,
	ListDate DATETIME NULL,
	ReadDate DATETIME NULL,
	[Subject] VARCHAR(255) NOT NULL,
	[Detail] VARCHAR(MAX) NULL,
	[Url] VARCHAR(255) NULL,
	[UrlText] VARCHAR(50) NULL,
	[Id] UNIQUEIDENTIFIER NOT NULL,
	CONSTRAINT PK_QCheck_NotificationArchive PRIMARY KEY CLUSTERED (
		[UID] ASC
	)
)
GO
CREATE   PROC [dbo].[QCheck_Notification_GET]
	@userId INT,
	@countOnly BIT = 1,
	@maxItem INT = 10
AS
BEGIN
	SET NOCOUNT ON
	IF @countOnly = 1 BEGIN
		SELECT COUNT(Id) as ListCount
		FROM dbo.QCheck_Notifications
		WHERE UserId = @userId AND ListDate IS NULL AND CreatedDate > DateAdd(day, -30, getutcdate())

	END ELSE BEGIN
		
		SELECT UserID, CreatedDate, ListDate, ReadDate, Subject, Detail, Url, UrlText, Id
		FROM dbo.QCheck_Notifications
		WHERE UserId = @userId
			AND (ListDate IS NULL OR ListDate > DateAdd(day, -7, getutcdate())) 
			AND CreatedDate > DateAdd(day, -30, getutcdate())
		ORDER BY CreatedDate DESC
		FOR JSON PATH
	END
END
GO
CREATE OR ALTER PROC QCheck_Notification_SET
	@userId INT = NULL,
	@subject VARCHAR(255) = NULL,
	@detail VARCHAR(MAX) = NULL,
	@url VARCHAR(255) = NULL,
	@urlText VARCHAR(50) = NULL,
	@id UNIQUEIDENTIFIER = NULL,
	@isClear BIT = NULL,
	@isDeleted BIT = NULL
AS
BEGIN
	SET NOCOUNT ON

	IF @isDeleted = 1 BEGIN
		INSERT INTO dbo.QCheck_NotificationArchive (
			 [UserId]
			,[CreatedDate]
			,[ListDate]
			,[ReadDate]
			,[Subject]
			,[Detail]
			,[Url]
			,[UrlText]
			,[Id]
		)
		SELECT [UserId]
			  ,[CreatedDate]
			  ,[ListDate]
			  ,[ReadDate]
			  ,[Subject]
			  ,[Detail]
			  ,[Url]
			  ,[UrlText]
			  ,[Id]
		FROM dbo.QCheck_Notifications
		WHERE Id = @id

		DELETE dbo.QCheck_Notifications
		WHERE Id = @id
	END ELSE IF @isClear = 1 BEGIN
		-- user clicked on the bell icon
		UPDATE dbo.QCheck_Notifications
		SET ListDate = GETUTCDATE()
		WHERE UserId = @userId
	END ELSE IF @id IS NOT NULL BEGIN
		-- user clicked on notification
		UPDATE dbo.QCheck_Notifications
		SET ReadDate = ISNULL(ReadDate, GETUTCDATE())
		WHERE Id = @id
	END ELSE BEGIN
		-- create notification from other stored procedures
		INSERT INTO dbo.QCheck_Notifications (UserId, [Subject], Detail, [Url], UrlText)
		VALUES (@userId, @subject, @detail, @url, @urlText)
	END
END
GO
-- get count
EXEC QCheck_Notification_GET
	@userId = 74
-- top n recent
EXEC QCheck_Notification_GET
	@userId = 74,
	@countOnly = 0
-- simulate clicking on bell icon
EXEC QCheck_Notification_SET
	@userId = 74,
	@isClear = 1
-- simulate clicking on notification to mark it as read
EXEC QCheck_Notification_SET
	@id = '0173E43C-A895-4CEA-82F9-215B0E2D5F29'
-- simulate deleting single notification
EXEC QCheck_Notification_SET
	@id = '0173E43C-A895-4CEA-82F9-215B0E2D5F29',
	@isDeleted = 1
-- simulate clicking on notification to mark it as read
EXEC QCheck_Notification_SET
	@userId = 74,
	@subject = 'Doe, Jane replied to your comment',
	@url = 'MyStatus.aspx?ReportID=10133',
	@urlText = 'View Status Report',
	@detail = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'

EXEC QCheck_Notification_SET
	@userId = 74,
	@subject = 'New task assigned: text complex 7',
	@url = 'ManageTasks.aspx?checklistid=154550',
	@urlText = 'Manage Task',
	@detail = 'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.'

