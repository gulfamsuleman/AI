SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****** Object:  Table [dbo].[TaskContent]    Script Date: 7/11/2025 10:59:27 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TaskContent]') AND type in (N'U'))
	DROP TABLE [dbo].[TaskContent]
GO

CREATE TABLE [dbo].[TaskContent] (
	[ChecklistId] [int] NOT NULL,
	[Content] [varchar](max) NULL,
	CONSTRAINT [PK_TaskContent] PRIMARY KEY CLUSTERED 
	(
		[ChecklistId] ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) 
		ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE FULLTEXT INDEX ON [dbo].[TaskContent] ([Content]) KEY INDEX PK_TaskContent
GO

/****** Object:  Table [dbo].[TaskContentArchive]    Script Date: 7/11/2025 11:07:21 AM ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TaskContentArchive]') AND type in (N'U'))
DROP TABLE [dbo].[TaskContentArchive]
GO

CREATE TABLE [dbo].[TaskContentArchive](
	[ChecklistId] [int] NOT NULL,
	[Content] [varchar](max) NULL,
	CONSTRAINT [PK_TaskContentArchive] PRIMARY KEY CLUSTERED 
	(
		[ChecklistId] ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) 
		ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE FULLTEXT INDEX ON [dbo].[TaskContentArchive] ([Content]) KEY INDEX [PK_TaskContentArchive]
GO

CREATE OR ALTER PROCEDURE QStatus_RebuildTaskContent AS
BEGIN

	DROP TABLE IF EXISTS #taskContent

	SELECT 
		c.ID,
		Content = c.[Name] + ISNULL('|' + string_agg(CONVERT(VARCHAR(MAX), ca.Comments), '|'), '') + isnull('|' + it.txt, '')
	INTO #taskContent
	FROM 
		dbo.QCheck_ChecklistInstances i 
		INNER JOIN dbo.QCheck_ActiveChecklists aa ON i.ID = aa.InstanceID
		INNER JOIN dbo.QCheck_Checklists c ON i.ChecklistID = c.ID
		LEFT OUTER JOIN dbo.QStatus_Comments_All ca ON ca.ForeignKeyID = aa.ID and ca.specialtask = 0 and len(ca.comments) < 5000
		OUTER APPLY (
			SELECT ISNULL('|' + string_agg(i.[text], '|'),'') as txt
			FROM QCheck_Items i
			WHERE i.ChecklistID = c.ID
			AND len(i.[text]) < 5000
		) it
	GROUP BY c.ID, c.[Name], it.txt

	BEGIN TRANSACTION
		EXEC sp_getapplock @Resource = 'TaskContentLock', @LockMode = 'Exclusive', @LockOwner = 'Transaction';
		
		TRUNCATE TABLE dbo.TaskContent

		INSERT INTO dbo.TaskContent  (ChecklistId, Content)
		SELECT ID, Content FROM #taskContent

	COMMIT TRANSACTION

END
GO

CREATE OR ALTER PROCEDURE QStatus_RebuildTaskContentArchive AS
BEGIN
	BEGIN TRANSACTION
		EXEC sp_getapplock @Resource = 'TaskContentLock', @LockMode = 'Exclusive', @LockOwner = 'Transaction';

		TRUNCATE TABLE dbo.TaskContentArchive 

		INSERT INTO dbo.TaskContentArchive  (ChecklistId, Content)
			SELECT 
				c.ID,
				Content = c.[Name] + ISNULL('|' + string_agg(CONVERT(VARCHAR(MAX), ca.Comments), '|'), '') + isnull('|' + it.txt, '')
			FROM 
				dbo.QCheck_ChecklistInstances_all i 
				INNER JOIN dbo.QCheck_ActiveChecklistArchive aa ON i.ID = aa.InstanceID
				INNER JOIN dbo.QCheck_Checklists_all c ON i.ChecklistID = c.ID
				LEFT OUTER JOIN dbo.QStatus_Comments_All ca ON ca.ForeignKeyID = aa.ID and ca.specialtask = 0 and len(ca.comments) < 5000
				OUTER APPLY (
					SELECT ISNULL('|' + string_agg(i.[text], '|'),'') as txt
					FROM QCheck_Items_all i
					WHERE i.ChecklistID = c.ID
					AND len(i.[text]) < 5000
				) it
			GROUP BY c.ID, c.[Name], it.txt
	COMMIT TRANSACTION
END
GO
 