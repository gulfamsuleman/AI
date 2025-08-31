USE [PFSProcess]
GO

exec QCheck_AddUser 'q-graynor', 'Geoffrey Raynor', 'graynor1@acmewidget.com', '', 0, 0
exec QCheck_AddUser 'q-smccarty', 'Scott McCarty', 'smccarty@acmewidget.com', '', 0, 0
exec QCheck_AddUser 'phi-mleighton', 'Mark Leighton', 'mleighton@phiairmedical.com', '', 0, 0
--exec QCheck_AddUser 'phi-kcroft', 'Ken Croft', 'kcroft@phiairmedical.com', '', 0, 0
GO

INSERT INTO dbo.Audit_Type ([Name])
VALUES ('CREATE'), ('READ'), ('UPDATE'), ('DELETE')
GO

INSERT INTO [dbo].[QCheck_UserDefaultTimes] ([UserID],[DueTime]) VALUES (-1, 19)
GO

INSERT [dbo].[QCheck_AppSettings] ([ID], 
[AppURL], 
[ImagesURL], 
[ExternalURL], 
[BaseDomain], 
[FilterToDomain], 
[FromAddress], 
[AppName], 
[GradingAddress], 
[AutomationAddress], 
[DeveloperAddress], 
[ITAddress], 
[MailServer], 
[GPRUserID], 
[CommentsAddress], 
[PopupMessage], 
[PopupShort], 
[EntityToAddress], 
[EntityFromAddress], 
[OverdueExcusedAddress], 
[GradingBCCAddress], 
[PriorityExcusedAddress], 
[StatusListNotUpdatedToAddress], 
[Email2DBFromAddress], 
[ExtendedTasksWarningFromAddress], 
[ExtendedTasksWarningFromName], 
[ExtendedTasksWarningCCAddress]) VALUES (1, 
N'http://processpfs.phiairmedical.com', 
N'', 
N'http://processpfs.phiairmedical.com', 
N'phiairmedical.com', 
1, 
N'processpfs@phiairmedical.com', 
N'ProcessPFS', 
N'processpfsgrading@phiairmedical.com', 
N'ProcessPFS@phiairmedical.com', 
N'developers@acmewidget.com', 
N'dstradling@phiairmedical.com', 
N'phxmail.phiairmedical.com', 
1, 
N'processpfs-comments@phiairmedical.com', 
N'', 
N'', 
N'', 
N'', 
N'overdueExcused@phiairmedical.com', 
N'graynor1@acmewidget.com', 
N'PriorityExcused@phiairmedical.com', 
N'kcroft@acmewidget.com', 
N'processpfs-tasks@phiairmedical.com', 
N'mleighton@phiairmedical.com', 
N'Mark Leighton', 
N'mleighton@phiairmedical.com')
GO

SET IDENTITY_INSERT [dbo].[QCheck_ItemTypes] ON 
GO

INSERT [dbo].[QCheck_ItemTypes] ([ID], [Name], [NativeType]) 
VALUES 
 (1, N'Checkbox', 1)
,(2, N'Heading', 0)
,(3, N'Sub Heading', 0)
,(4, N'Spacer', 0)
,(5, N'Notes', 0)

SET IDENTITY_INSERT [dbo].[QCheck_ItemTypes] OFF
GO

DBCC CHECKIDENT('QCheck_ItemTypes', RESEED)
GO

INSERT [dbo].[QStatus_TaskTypesTemplate] ([Description], [DisplayOrder], [NativeType])
VALUES 
  (N'General Comments', 1, 5)
, (N'Questions', 2, 1)
, (N'Current', 3, 0)
, (N'Future', 4, 0)
, (N'On Hold', 5, 0)
, (N'Recurring', 6, 0)
, (N'Completed', 7, 2)
GO

INSERT INTO QStatus_SupervisorOverride (UserID, SupervisorID)
SELECT ID, ID
FROM QCheck_Users
WHERE ShortName LIKE '%graynor%'

use [master]
GO
