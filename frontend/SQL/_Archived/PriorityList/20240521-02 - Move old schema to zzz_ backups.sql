
/************************************************************************************************
    DROP NEW TABLES
************************************************************************************************/
/*
IF (SELECT OBJECT_ID('dbo.zzz_PriorityList')) IS NOT NULL
	DROP TABLE dbo.zzz_PriorityList

IF (SELECT OBJECT_ID('dbo.zzz_PriorityList_Exclude')) IS NOT NULL
	DROP TABLE dbo.zzz_PriorityList_Exclude

IF (SELECT OBJECT_ID('dbo.zzz_PriorityListCrossReference')) IS NOT NULL
	DROP TABLE dbo.zzz_PriorityListCrossReference

IF (SELECT OBJECT_ID('dbo.zzz_PriorityListSet')) IS NOT NULL
	DROP TABLE dbo.zzz_PriorityListSet

IF (SELECT OBJECT_ID('dbo.zzz_PriorityListUsers')) IS NOT NULL
	DROP TABLE dbo.zzz_PriorityListUsers

IF (SELECT OBJECT_ID('dbo.zzz_Schedule_PriorityList')) IS NOT NULL
	DROP TABLE dbo.zzz_Schedule_PriorityList

IF (SELECT OBJECT_ID('dbo.zzz_Schedule_PriorityList_Exclude')) IS NOT NULL
	DROP TABLE dbo.zzz_Schedule_PriorityList_Exclude

IF (SELECT OBJECT_ID('dbo.zzz_Supervisor_PriorityList_Report_Schedule')) IS NOT NULL
	DROP TABLE dbo.zzz_Supervisor_PriorityList_Report_Schedule
*/

/************************************************************************************************
    DEFINE NEW TABLES
************************************************************************************************/

CREATE TABLE [dbo].[zzz_PriorityList](
	[ID] [int] NOT NULL,
	[UserID] [int] NOT NULL,
	[ActiveChecklistID] [int] NOT NULL,
	[Priority] [int] NOT NULL,
 CONSTRAINT [PK_zzz_PriorityList] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PriorityList_Exclude]    Script Date: 5/21/2024 4:07:28 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[zzz_PriorityList_Exclude](
	[UserID] [int] NOT NULL,
	[ForUserID] [int] NOT NULL,
	[ActiveChecklistID] [int] NOT NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PriorityListCrossReference]    Script Date: 5/21/2024 4:07:28 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[zzz_PriorityListCrossReference](
	[UserID] [int] NOT NULL,
	[CrossReferenceID] [int] NOT NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PriorityListSet]    Script Date: 5/21/2024 4:07:28 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[zzz_PriorityListSet](
	[ID] [int] NOT NULL,
	[Name] [varchar](50) NOT NULL,
	[UserID] [int] NOT NULL,
	[PersonalSet] [bit] NOT NULL,
	[UpdatedDate] [datetime] NOT NULL,
 CONSTRAINT [PK_zzz_PriorityListSet] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[PriorityListUsers]    Script Date: 5/21/2024 4:07:28 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[zzz_PriorityListUsers](
	[SetID] [int] NOT NULL,
	[UserID] [int] NOT NULL,
	[DisplayOrder] [int] NOT NULL,
 CONSTRAINT [PK_zzz_PriorityListUsers] PRIMARY KEY CLUSTERED 
(
	[SetID] ASC,
	[UserID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Schedule_PriorityList]    Script Date: 5/21/2024 4:10:07 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[zzz_Schedule_PriorityList](
	[ScheduleID] [int] NOT NULL,
	[SupervisorID] [int] NOT NULL,
	[EmployeeID] [int] NOT NULL,
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

/****** Object:  Table [dbo].[Schedule_PriorityList_Exclude]    Script Date: 5/21/2024 4:10:07 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[zzz_Schedule_PriorityList_Exclude](
	[Id] [int] NOT NULL,
	[EmpID] [int] NOT NULL,
	[ExcludedDate] [datetime] NOT NULL,
	[CreatedDate] [datetime] NOT NULL,
	[SupervisorId] [int] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_zzz_Schedule_PriorityList_Exclude] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Supervisor_PriorityList_Report_Schedule]    Script Date: 5/21/2024 4:10:07 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[zzz_Supervisor_PriorityList_Report_Schedule](
	[ScheduleID] [int] NOT NULL,
	[SupervisorID] [int] NOT NULL,
	[DaysOfWeek] [varchar](10) NOT NULL,
	[DaysOffset] [int] NOT NULL,
	[CreatedDate] [datetime] NULL,
	[CreatedBy] [varchar](50) NULL,
	[ModifiedDate] [datetime] NULL,
	[ModifiedBy] [varchar](50) NULL,
	[IsActive] [bit] NOT NULL
) ON [PRIMARY]
GO

/************************************************************************************************
    INITIAL POPULATION/DATA MIGRATION
************************************************************************************************/

INSERT INTO zzz_PriorityList SELECT * FROM PriorityList
INSERT INTO zzz_PriorityList_Exclude SELECT * FROM PriorityList_Exclude
INSERT INTO zzz_PriorityListCrossReference SELECT * FROM PriorityListCrossReference
INSERT INTO zzz_PriorityListSet SELECT * FROM PriorityListSet
INSERT INTO zzz_PriorityListUsers SELECT * FROM PriorityListUsers
INSERT INTO zzz_Schedule_PriorityList SELECT * FROM Schedule_PriorityList
INSERT INTO zzz_Schedule_PriorityList_Exclude SELECT * FROM Schedule_PriorityList_Exclude
INSERT INTO zzz_Supervisor_PriorityList_Report_Schedule SELECT * FROM Supervisor_PriorityList_Report_Schedule


/************************************************************************************************
    DROP OLD TABLES
************************************************************************************************/
/*

-- ARE YOU SURE??
DROP TABLE PriorityList
DROP TABLE PriorityList_Exclude
DROP TABLE PriorityListCrossReference
DROP TABLE PriorityListSet
DROP TABLE PriorityListUsers
DROP TABLE Schedule_PriorityList
DROP TABLE Schedule_PriorityList_Exclude
DROP TABLE Supervisor_PriorityList_Report_Schedule

*/