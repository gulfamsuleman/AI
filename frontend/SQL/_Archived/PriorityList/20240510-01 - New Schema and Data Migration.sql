--ALTER TABLE Grading_QProcessTests ADD
--gradeddt datetime DEFAULT GETDATE()

/************************************************************************************************
    DROP NEW TABLES
************************************************************************************************/

IF (SELECT OBJECT_ID('dbo.Priorities_Lists')) IS NOT NULL
	DROP TABLE dbo.Priorities_Lists

IF (SELECT OBJECT_ID('dbo.Priorities_ListItems')) IS NOT NULL
	DROP TABLE dbo.Priorities_ListItems

IF (SELECT OBJECT_ID('dbo.Priorities_List_CrossReference')) IS NOT NULL
	DROP TABLE dbo.Priorities_List_CrossReference

IF (SELECT OBJECT_ID('dbo.Priorities_ListSets')) IS NOT NULL
	DROP TABLE dbo.Priorities_ListSets

IF (SELECT OBJECT_ID('dbo.Priorities_ListSetLists')) IS NOT NULL
	DROP TABLE dbo.Priorities_ListSetLists

IF (SELECT OBJECT_ID('dbo.Priorities_ListExclude')) IS NOT NULL
	DROP TABLE dbo.Priorities_ListExclude

IF (SELECT OBJECT_ID('dbo.Priorities_Schedule')) IS NOT NULL
	DROP TABLE dbo.Priorities_Schedule

IF (SELECT OBJECT_ID('dbo.Priorities_ScheduleExclude')) IS NOT NULL
	DROP TABLE dbo.Priorities_ScheduleExclude

IF (SELECT OBJECT_ID('dbo.Priorities_ScheduleSupervisors')) IS NOT NULL
	DROP TABLE dbo.Priorities_ScheduleSupervisors



/************************************************************************************************
    DEFINE NEW TABLES
************************************************************************************************/

/****** Object:  Table [dbo].[PriorityList]    Script Date: 5/10/2024 8:46:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Priorities_Lists](
	[ID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[UserID] [int] NOT NULL,
	[IsDefaultList] bit NOT NULL DEFAULT 0,
	[UpdatedDate] datetime NOT NULL DEFAULT GETDATE()
	CONSTRAINT [PK_Priorities_List] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PriorityList]    Script Date: 5/10/2024 8:46:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Priorities_ListItems](
	[ID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[ListID] [int] NOT NULL,
	[ActiveChecklistID] [int] NOT NULL,
	[Priority] [int] NOT NULL,
	 CONSTRAINT [PK_Priorities_ListItems] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PriorityListCrossReference]    Script Date: 5/10/2024 8:46:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Priorities_List_CrossReference](
	[UserID] [int] NOT NULL,
	[CrossReferenceID] [int] NOT NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PriorityListSet]    Script Date: 5/10/2024 8:46:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Priorities_ListSets](
	[ID] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[UserID] [int] NOT NULL,
	[PersonalSet] [bit] NOT NULL DEFAULT 0,
	[UpdatedDate] [datetime] NOT NULL DEFAULT GETDATE(),
 CONSTRAINT [PK_Priorities_ListSets] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PriorityListUsers]    Script Date: 5/10/2024 8:46:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Priorities_ListSetLists](
	[SetID] [int] NOT NULL,
	[ListID] [int] NOT NULL,
	[DisplayOrder] [int] NOT NULL,
 CONSTRAINT [PK_Priorities_ListSetLists] PRIMARY KEY CLUSTERED 
(
	[SetID] ASC,
	[ListID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PriorityList_Exclude]    Script Date: 5/10/2024 8:46:38 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Priorities_ListExclude](
	[UserID] [int] NOT NULL,
	[ForUserID] [int] NOT NULL,
	[ActiveChecklistID] [int] NOT NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Schedule_PriorityList]    Script Date: 5/10/2024 9:44:25 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Priorities_Schedule](
	[ScheduleID] [int] IDENTITY(1,1) NOT NULL PRIMARY KEY,
	[SupervisorID] [int] NOT NULL,
	[UserID] [int] NOT NULL,
	[ListID] [int] NULL,
	[DaysOfWeek] [varchar](10) NOT NULL,
	[ReportDay] [varchar](10) NOT NULL,
	[TimesOfDay] [varchar](250) NULL,
	[CreatedDate] [datetime] NULL,
	[CreatedBy] [varchar](50) NULL,
	[ModifiedDate] [datetime] NULL,
	[ModifiedBy] [varchar](50) NULL,
	[IsActive] [bit] NOT NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Schedule_PriorityList_Exclude]    Script Date: 5/10/2024 9:44:25 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Priorities_ScheduleExclude](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[UserID] [int] NOT NULL,
	[ListID] [int] NULL,
	[ExcludedDate] [datetime] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[SupervisorId] [int] NULL,
	[IsActive] [bit] NOT NULL DEFAULT 1,
 CONSTRAINT [PK_Priorities_ScheduleExclude] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/************************************************************************************************
    INITIAL POPULATION/DATA MIGRATION
************************************************************************************************/

INSERT INTO dbo.Priorities_Lists (
	 [Name]
	,[UserID]
	,[IsDefaultList]
	,[UpdatedDate]
)
SELECT DISTINCT u.FullName, l.UserID, 1, ls.UpdatedDate
FROM dbo.PriorityList l
JOIN dbo.QCheck_Users u 
	ON u.ID = l.UserID
JOIN dbo.PriorityListSet ls 
	ON ls.UserID = l.UserID 
	AND ls.PersonalSet = 1



INSERT INTO dbo.Priorities_ListItems (
	[ListID]
	,[ActiveChecklistID]
	,[Priority]
)
SELECT l.ID, ol.ActiveChecklistID, ol.Priority
FROM dbo.PriorityList ol
JOIN dbo.Priorities_Lists l 
	ON l.UserID = ol.UserID 
	AND l.IsDefaultList = 1



SET IDENTITY_INSERT dbo.Priorities_ListSets ON

INSERT INTO Priorities_ListSets (
	[ID]
	,[Name]
	,[UserID]
	,[PersonalSet]
	,[UpdatedDate]
)
SELECT ID, Name, UserID, PersonalSet, UpdatedDate
FROM dbo.PriorityListSet

SET IDENTITY_INSERT dbo.Priorities_ListSets OFF
DBCC CHECKIDENT('dbo.Priorities_ListSets', RESEED)



INSERT INTO [dbo].[Priorities_ListSetLists](
	[SetID]
	,[ListID]
	,[DisplayOrder]
)
SELECT s.ID, l.ID, olu.DisplayOrder
FROM dbo.PriorityListUsers olu
JOIN dbo.Priorities_ListSets s 
	ON s.ID = olu.SetID
JOIN dbo.Priorities_Lists l 
	ON l.UserID = olu.UserID 
	AND l.IsDefaultList = 1



SET IDENTITY_INSERT dbo.[Priorities_Schedule] ON

INSERT INTO [dbo].[Priorities_Schedule](
	[ScheduleID],
	[SupervisorID],
	[UserID],
	[ListID],
	[DaysOfWeek],
	[ReportDay],
	[TimesOfDay],
	[CreatedDate],
	[CreatedBy],
	[ModifiedDate],
	[ModifiedBy],
	[IsActive]
)
SELECT [ScheduleID],
	[SupervisorID],
	spl.[EmployeeID],
	pl.[ID],
	[DaysOfWeek],
	[ReportDay],
	[TimesOfDay],
	[CreatedDate],
	[CreatedBy],
	[ModifiedDate],
	[ModifiedBy],
	[IsActive]
FROM dbo.Schedule_PriorityList spl
JOIN dbo.Priorities_Lists pl 
	ON pl.UserID = spl.EmployeeID --not actually employee ID, thanks Venkat
	and pl.IsDefaultList = 1

SET IDENTITY_INSERT dbo.[Priorities_Schedule] OFF
DBCC CHECKIDENT('dbo.Priorities_Schedule', RESEED)



INSERT INTO [dbo].[Priorities_ScheduleExclude](
	[UserID],
	[ListID],
	[ExcludedDate],
	[CreatedDate],
	[SupervisorId],
	[IsActive]
)
SELECT 
	sple.[EmpID],
	pl.[ID],
	[ExcludedDate],
	[CreatedDate],
	[SupervisorId],
	[IsActive]
FROM dbo.Schedule_PriorityList_Exclude sple
JOIN dbo.Priorities_Lists pl 
	ON pl.UserID = sple.EmpID --not actually employee ID, thanks Venkat
	and pl.IsDefaultList = 1



