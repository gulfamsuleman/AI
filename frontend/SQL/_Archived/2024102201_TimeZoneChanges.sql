ALTER TABLE dbo.QCheck_Users ADD LastTimeZone VARCHAR(255) NULL;
ALTER TABLE dbo.QCheck_Users ADD TimeZoneOverride VARCHAR(255) NULL;
ALTER TABLE dbo.QCheck_Schedule ADD TimeZone VARCHAR(255) NULL;
ALTER TABLE dbo.QCheck_ScheduleArchive ADD TimeZone VARCHAR(255) NULL;
ALTER TABLE dbo.QCheck_Approval_Schedule ADD TimeZone VARCHAR(255) NULL;
ALTER TABLE dbo.QCheck_AppSettings ADD SystemTimeZone varchar(255) NULL;
ALTER TABLE dbo.TaskSearchCache ALTER COLUMN Due varchar(50) NULL;
GO

UPDATE dbo.QCheck_AppSettings SET 
	SystemTimeZone = 
		CASE datediff(hour, GETUTCDATE(), GETDATE())
			WHEN -7 THEN 'America/Phoenix'
			ELSE 'America/Chicago'
		END
GO

CREATE TYPE dbo.TimeZoneType AS TABLE
(
    Timezone varchar(255) NOT NULL
)
GO

UPDATE QCheck_Users SET LastTimeZone = 'America/Chicago'
UPDATE QCheck_Users SET LastTimeZone = 'America/Phoenix'
	where email LIKE '%@phiairmedical.com%'
UPDATE QCheck_Users SET LastTimeZone = 'Australia/Perth' 
	where email LIKE '%@phi-int.com%'
	AND email NOT IN (
		'jbarclay@phi-int.com',
		'rpendle@phi-int.com',
		'slewis@phi-int.com',
		'kpetsas@phi-int.com',
		'jsifers@phi-int.com'
	)
UPDATE QCheck_Users SET LastTimeZone = 'Europe/London' 
	where email LIKE '%@phi-int.com%'
	AND email IN (
		'jbarclay@phi-int.com',
		'rpendle@phi-int.com',
		'slewis@phi-int.com'		
	)
UPDATE QCheck_Users SET LastTimeZone = 'Asia/Nicosia' 
	where email LIKE '%@phi-int.com%'
	AND email IN (
		'kpetsas@phi-int.com'		
	)
UPDATE QCheck_Users SET LastTimeZone = 'Asia/Bangkok' 
	where email LIKE '%@phi-int.com%'
	AND email IN (		
		'jsifers@phi-int.com'		
	)
UPDATE QCheck_Users SET LastTimeZone = 'America/Port_of_Spain' 
	where email IN (		
		'sreid@phihelico.com'		
	)
UPDATE QCheck_Users SET LastTimeZone = 'America/New_York' 
	where email LIKE '%@phi-int.com%'
	AND email IN (		
		'jsifers@phi-int.com'		
	)
GO

CREATE OR ALTER FUNCTION dbo.ConvertTimeToUtc (
	@date nvarchar(255),
	@srcTz nvarchar(255)
) RETURNS NVARCHAR(255)   
AS BEGIN
	RETURN _Util.dbo.ConvertTimeToUtc(@date, @srcTz);   
END
GO

CREATE OR ALTER FUNCTION dbo.ConvertTimeFromUtc (
	@date nvarchar(255),
	@dstTz nvarchar(255)
) RETURNS NVARCHAR(255)   
AS BEGIN
	RETURN _Util.dbo.ConvertTimeFromUtc(@date, @dstTz);   
END
GO

CREATE OR ALTER FUNCTION dbo.ConvertTime (
	@date nvarchar(255),
	@srcTz nvarchar(255),
	@dstTz nvarchar(255)
) RETURNS NVARCHAR(255)   
AS BEGIN
	RETURN _Util.dbo.ConvertTime(@date, @srcTz, @dstTz);   
END
GO

CREATE OR ALTER FUNCTION dbo.FormatTime (
	@date nvarchar(255),
	@localTz nvarchar(255),
	@timezones nvarchar(4000)
) RETURNS NVARCHAR(4000)   
AS BEGIN
	RETURN _Util.dbo.FormatTime(@date, @localTz, @timezones);   
END
GO


select GETUTCDATE() Expected, dbo.ConvertTimeToUtc(GETDATE(), 'America/Chicago') Actual
UNION ALL
select GETDATE(), dbo.ConvertTimeFromUtc(GETUTCDATE(), 'America/Chicago')
UNION ALL
select DateAdd(hour, 1, GETDATE()), dbo.ConvertTime(GETDATE(), 'America/Chicago', 'America/New_York')
UNION ALL
select DateAdd(hour, -1, GETDATE()), dbo.ConvertTime(GETDATE(), 'America/Chicago', 'America/Denver')
UNION ALL
select GETDATE(), dbo.FormatTime(GETUTCDATE(), N'America/Chicago', N'America/New_York,America/Chicago,America/Denver,America/Phoenix,America/Los_Angeles,Europe/London,Europe/Rome,Australia/Perth')


/****** Object:  Trigger [dbo].[trg_QCheck_ActiveChecklists_UPDATE]    Script Date: 11/15/2024 6:09:23 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER TRIGGER [dbo].[trg_QCheck_ActiveChecklists_UPDATE]
ON [dbo].[QCheck_ActiveChecklists]
FOR UPDATE AS

BEGIN

	UPDATE 
		QCheck_ActiveChecklists
	SET 
		ReminderDate = i.DueTime
	FROM
		QCheck_ActiveChecklists ac
		INNER JOIN INSERTED i
			ON ac.[ID] = i.[ID]
		INNER JOIN DELETED d
			ON ac.[ID] = d.[ID]
	WHERE
		-- Times were the same before the update
		CONVERT(VARCHAR(10), d.ReminderDate, 101) = CONVERT(VARCHAR(10), d.DueTime, 101)
		-- Soft due was not updated
		AND CONVERT(VARCHAR(10), i.ReminderDate, 101) = CONVERT(VARCHAR(10), d.ReminderDate, 101)
END
GO

CREATE OR ALTER PROC dbo.UserTimeZone_GET
	@userId int = null,
	@shortName varchar(50) = null,
	@email varchar(100) = null
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @DueTime INT
	SELECT @DueTime = duetime FROM QCheck_UserDefaultTimes WHERE UserID = @userId

	IF @DueTime IS NULL
		SELECT @DueTime = duetime from QCheck_UserDefaultTimes WHERE UserID = -1

	SELECT TOP 1 LastTimeZone, TimeZoneOverride, DueTime = @DueTime
	FROM dbo.QCheck_Users
	WHERE 1 = 1
		AND ID = ISNULL(@userId, ID)
		AND ShortName = ISNULL(@shortName, ShortName)
		AND Email = ISNULL(@email, Email)
END
GO

CREATE OR ALTER PROC dbo.UserTimeZone_SET
	@userId int = null,
	@shortName varchar(50) = null,
	@email varchar(100) = null,
	@lastTimeZone varchar(255) = null,
	@timeZoneOverride varchar(255) = null
AS
BEGIN
	SET NOCOUNT ON

	IF (COALESCE(CAST(@userID as varchar(10)), @shortName, @email) IS NULL)
		THROW 50001, 'At least one of @userID, @shortName or @email must have a value.', 0

	UPDATE dbo.QCheck_Users
	SET  LastTimeZone = ISNULL(@lastTimeZone, LastTimeZone)
		--If user is setting their time zone override to their last reported zone,
		--clear the override (otherwise it will never automatically change)
		,TimeZoneOverride = CASE WHEN @timeZoneOverride = @lastTimeZone THEN NULL			
			ELSE ISNULL(@timeZoneOverride, TimeZoneOverride) END
	WHERE 1 = 1
		AND ID = ISNULL(@userId, ID)
		AND ShortName = ISNULL(@shortName, ShortName)
		AND Email = ISNULL(@email, Email)
END
GO

CREATE OR ALTER PROC dbo.UserTimeZones_GET
	@userIds varchar(8000) = null,
	@shortNames varchar(8000) = null,
	@emails varchar(8000) = null
AS
BEGIN
	SET NOCOUNT ON

	SELECT STRING_AGG(TimeZone, ',') FROM (
		SELECT DISTINCT ISNULL(TimeZoneOverride, LastTimeZone) TimeZone
		FROM QCheck_Users
		WHERE ',' + @userIds + ',' LIKE '%,' + CAST(ID as varchar) + ',%'
			OR ',' + @shortnames + ',' LIKE '%,' + ShortName + ',%'
			OR ',' + @emails + ',' LIKE '%,' + Email + ',%'
	) x

END
GO

CREATE OR ALTER FUNCTION dbo.ToUtc(
	@date DATETIME
)
RETURNS DATETIME
WITH SCHEMABINDING
AS
BEGIN
	DECLARE @dstTz VARCHAR(255) = 'UTC'
	DECLARE @srcTz VARCHAR(255) = 'Central Standard Time'

	SET @date = (@date AT TIME ZONE @srcTz) AT TIME ZONE @dstTz
	RETURN @date
END
GO

sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Ole Automation Procedures', 1;
GO
RECONFIGURE;
GO

CREATE OR ALTER PROCEDURE dbo.CallWebApi 
	@url varchar(1000) = '',
	@method varchar(50) = 'POST',
	@param varchar(8000) = '',
	@ResponseText varchar(8000) OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @Object INT
    
	IF ISNULL(@url, '') = '' RETURN

	IF @method = 'GET'
	    SET @url = @url + @param

    EXEC sp_OACreate 'WinHttp.WinHttpRequest.5.1', @Object OUT;
    EXEC sp_OAMethod @Object, 'Open', NULL, @method, @url, 'false'
    EXEC sp_OAMethod @Object, 'setRequestHeader', NULL, 'Content-Type', 'application/json'

	IF @method = 'POST'
		EXEC sp_OAMethod @Object, 'send', null, @param
    ELSE
		EXEC sp_OAMethod @Object, 'send'

	EXEC sp_OAMethod @Object, 'responseText', @ResponseText OUTPUT
    EXEC sp_OADestroy @Object
END
GO

CREATE OR ALTER FUNCTION dbo.GetWsUrl()
RETURNS VARCHAR(8000)
WITH SCHEMABINDING
AS
BEGIN
	RETURN 'https://qprocess.beta.acmewidget.com/Services/ControlService.asmx/'
END
GO

CREATE OR ALTER   PROC [dbo].[QCheck_FormatTime] (
	@date DATETIME,
	@localTz VARCHAR(255),
	@tzTable dbo.TimeZoneType READONLY,
	@result VARCHAR(8000) OUTPUT
) 
AS
BEGIN
	SET NOCOUNT ON 

	/*SELECT @result = STRING_AGG('"' + CAST(Timezone AS VARCHAR(8000)) + '"', ', ') FROM @tzTable
	DECLARE @url VARCHAR(8000) = dbo.GetWsUrl() + 'FormatTime'

	DECLARE @param VARCHAR(8000) = '
	{ 
		"date": "' + CONVERT(VARCHAR(20), @date, 22) + '",
		"localTz": "' + @localTz + '",
		"timezone": [' + @result + ']
	}'

	EXEC dbo.CallWebApi 
	@url = @url,
	@param = @param,
	@ResponseText = @result OUTPUT

	SET @result = SUBSTRING(@result, 7, LEN(@result) - 8)
	*/

	SELECT @result = dbo.FormatTime(@date, @localTz, STRING_AGG('"' + CAST(Timezone AS VARCHAR(8000)) + '"', ', ')) FROM @tzTable
END

GO
/*
-- EXAMPLE OF USING QCheck_FormatTime

DECLARE @localTz VARCHAR(255) = 'America/Chicago'
DECLARE @date DATETIME = GETUTCDATE()
DECLARE @result VARCHAR(8000)

DECLARE @tz AS TimeZoneType
INSERT INTO @tz (Timezone) VALUES ('America/Phoenix'), ('America/Denver'), ('America/Chicago')

EXEC dbo.QCheck_FormatTime @date, 'America/Chicago', @tz, @result OUTPUT
SELECT @result

*/

GO

CREATE OR ALTER   PROC [dbo].[QCheck_ConvertToTimeZone]
	@date datetime,
	@localTz varchar(255),
	@result datetime OUTPUT
AS
BEGIN
SET NOCOUNT ON
/*
	DECLARE @url VARCHAR(8000) = dbo.GetWsUrl() + 'ConvertTimeFromUtc'		

	DECLARE @param varchar(8000) = '
	{ 
		"date": "' + CONVERT(VARCHAR(20), @date, 22) + '",
		"dstTz": "' + @localTz + '"
	}'

	DECLARE @response varchar(8000)

	EXEC dbo.CallWebApi 
		@url = @url,
		@param = @param,
		@ResponseText = @response OUTPUT

	SET @result = CAST(SUBSTRING(@response, 7, LEN(@response) - 8) AS DATETIME)
	*/
	SELECT @result = dbo.ConvertTimeFromUtc(@date, @localTz)
END
GO

CREATE OR ALTER   PROC [dbo].[QCheck_ConvertFromTimeZone]
	@date datetime,
	@localTz varchar(255),
	@result datetime OUTPUT
AS
BEGIN
SET NOCOUNT ON
/*
	DECLARE @url VARCHAR(8000) = dbo.GetWsUrl() + 'ConvertTimeToUtc'		

	DECLARE @param varchar(8000) = '
	{ 
		"date": "' + CONVERT(VARCHAR(20), @date, 22) + '",
		"srcTz": "' + @localTz + '"
	}'

	DECLARE @response varchar(8000)

	EXEC dbo.CallWebApi 
		@url = @url,
		@param = @param,
		@ResponseText = @response OUTPUT

	SET @result = CAST(SUBSTRING(@response, 7, LEN(@response) - 8) AS DATETIME)
	*/
	SELECT @result = dbo.ConvertTimeToUtc(@date, @localTz)

END
GO

DISABLE TRIGGER [dbo].[trg_QCheck_ActiveChecklists_UPDATE]
ON [dbo].[QCheck_ActiveChecklists]

PRINT '[dbo].[Audit_ActiveChecklist]'
UPDATE [dbo].[Audit_ActiveChecklist] SET [AuditDt] = dbo.ToUtc([AuditDt])
GO
PRINT '[dbo].[QCheck_GroupMembership]'
UPDATE [dbo].[QCheck_GroupMembership] SET [AsOf] = dbo.ToUtc([AsOf])
GO
PRINT '[dbo].[QCheck_GroupOwnerAudit]'
UPDATE [dbo].[QCheck_GroupOwnerAudit] SET [ChangeDt] = dbo.ToUtc([ChangeDt])
GO
PRINT '[dbo].[QCheck_InstanceStops]'
UPDATE [dbo].[QCheck_InstanceStops] SET [stoppedDt] = dbo.ToUtc([stoppedDt])
GO
PRINT '[dbo].[QCheck_ItemArchive]'
UPDATE [dbo].[QCheck_ItemArchive] SET [ArchiveDate] = dbo.ToUtc([ArchiveDate])
GO
PRINT '[dbo].[QCheck_LateFee]'
UPDATE [dbo].[QCheck_LateFee] SET [StartDate] = dbo.ToUtc([StartDate]), [EndDate] = dbo.ToUtc([EndDate])
GO
PRINT '[dbo].[QCheck_LinkedDeadlines]'
UPDATE [dbo].[QCheck_LinkedDeadlines] SET [CreatedDt] = dbo.ToUtc([CreatedDt]), [ModifiedBy] = dbo.ToUtc([ModifiedBy])
GO
PRINT '[dbo].[QCheck_GroupChanges]'
UPDATE [dbo].[QCheck_GroupChanges] SET [dt] = dbo.ToUtc([dt])
GO
PRINT '[dbo].[QCheck_LoadTimes]'
UPDATE [dbo].[QCheck_LoadTimes] SET [Dt] = dbo.ToUtc([dt]), [LastOpened] = dbo.ToUtc([LastOpened])
GO
PRINT '[dbo].[QCheck_PagesLoaded_BonusUsers]'
UPDATE [dbo].[QCheck_PagesLoaded_BonusUsers] SET [Dt] = dbo.ToUtc([dt])
GO
PRINT '[dbo].[QCheck_Reassign_History]'
UPDATE [dbo].[QCheck_Reassign_History] SET [ViewDate] = dbo.ToUtc([ViewDate])
GO
PRINT '[dbo].[QCheck_ReminderTasksReport]'
UPDATE [dbo].[QCheck_ReminderTasksReport] SET [ReportTime] = dbo.ToUtc([ReportTime])
GO
PRINT '[dbo].[QCheck_Schedule]'
UPDATE [dbo].[QCheck_Schedule] SET TimeZone = 'America/Chicago'--[firstDueDate] = dbo.ToUtc([firstDueDate]), [lastDueDate] = dbo.ToUtc([lastDueDate])
GO
PRINT '[dbo].[QCheck_ScheduleArchive]'
UPDATE [dbo].[QCheck_ScheduleArchive] SET TimeZone = 'America/Chicago'--[firstDueDate] = dbo.ToUtc([firstDueDate]),[lastDueDate] = dbo.ToUtc([lastDueDate]),[ArchiveDate] = dbo.ToUtc([ArchiveDate])
GO
PRINT '[dbo].[QCheck_SetUpcomingTiming]'
UPDATE [dbo].[QCheck_SetUpcomingTiming] SET [startdt] = dbo.ToUtc([startdt]),[enddt] = dbo.ToUtc([enddt])
GO
PRINT '[dbo].[QCheck_Log_Emails]'
UPDATE [dbo].[QCheck_Log_Emails] SET [Sent] = dbo.ToUtc([Sent])
GO
PRINT '[dbo].[QCheck_Suggestions]'
UPDATE [dbo].[QCheck_Suggestions] SET [Dt] = dbo.ToUtc([dt])
GO
PRINT '[dbo].[QCheck_BonusTasks]'
UPDATE [dbo].[QCheck_BonusTasks] SET [Dt] = dbo.ToUtc([dt])
GO
PRINT '[dbo].[QCheck_BonusUsers]'
UPDATE [dbo].[QCheck_BonusUsers] SET [startdt] = dbo.ToUtc([startdt]),[enddt] = dbo.ToUtc([enddt])
GO
PRINT '[dbo].[QCheck_BulkAssigned]'
UPDATE [dbo].[QCheck_BulkAssigned] SET [RequesteDate] = dbo.ToUtc([RequesteDate])
GO
PRINT '[dbo].[QCheck_ChecklistArchive]'
UPDATE [dbo].[QCheck_ChecklistArchive] SET [CreateDate] = dbo.ToUtc([CreateDate]),[ArchiveDate] = dbo.ToUtc([ArchiveDate])
GO
PRINT '[dbo].[QCheck_ChecklistInstanceArchive]'
UPDATE [dbo].[QCheck_ChecklistInstanceArchive] SET [ArchiveDate] = dbo.ToUtc([ArchiveDate])
GO
PRINT '[dbo].[QCheck_ChecklistManagerArchive]'
UPDATE [dbo].[QCheck_ChecklistManagerArchive] SET [ArchiveDate] = dbo.ToUtc([ArchiveDate])
GO
PRINT '[dbo].[QCheck_ChecklistManagers]'
UPDATE [dbo].[QCheck_ChecklistManagers] SET [CreateDate] = dbo.ToUtc([CreateDate])
GO
PRINT '[dbo].[QCheck_ChecklistManagers_Temp]'
UPDATE [dbo].[QCheck_ChecklistManagers_Temp] SET [Expires] = dbo.ToUtc([Expires])
GO
PRINT '[dbo].[QCheck_Checklists]'
UPDATE [dbo].[QCheck_Checklists] SET [CreateDate] = dbo.ToUtc([CreateDate])
GO
PRINT '[dbo].[QCheck_Emails]'
UPDATE [dbo].[QCheck_Emails] SET [Sent] = dbo.ToUtc([Sent])
GO
PRINT '[dbo].[QCheck_EmailsReport]'
UPDATE [dbo].[QCheck_EmailsReport] SET [Sent] = dbo.ToUtc([Sent])
GO
PRINT '[dbo].[QCheck_EmailTasks]'
UPDATE [dbo].[QCheck_EmailTasks] SET [CreatedDt] = dbo.ToUtc([CreatedDt])
GO
PRINT '[dbo].[QCheck_EventLog]'
UPDATE [dbo].[QCheck_EventLog] SET [EventDateTime] = dbo.ToUtc([EventDateTime])
GO
PRINT '[dbo].[QCheck_ExtendedTasksWarningEmail_Queue]'
UPDATE [dbo].[QCheck_ExtendedTasksWarningEmail_Queue] SET [emailSent] = dbo.ToUtc([emailSent])
GO
PRINT '[dbo].[QCheck_CompletionPopupLog]'
UPDATE [dbo].[QCheck_CompletionPopupLog] SET [popupdt] = dbo.ToUtc([popupdt])
GO
PRINT '[dbo].[QCheck_BonusStatusEmails]'
UPDATE [dbo].[QCheck_BonusStatusEmails] SET [SentDt] = dbo.ToUtc([SentDt])
GO
PRINT '[dbo].[QCheck_Suggestions_Archive]'
UPDATE [dbo].[QCheck_Suggestions_Archive] SET [Dt] = dbo.ToUtc([dt])
GO
PRINT '[dbo].[QStatus_PriorityChanges]'
UPDATE [dbo].[QStatus_PriorityChanges] SET [Updatedt] = dbo.ToUtc([Updatedt])
GO
PRINT '[dbo].[QStatus_Report]'
UPDATE [dbo].[QStatus_Report] SET [LastReportDate] = dbo.ToUtc([LastReportDate])
GO
PRINT '[dbo].[QStatus_ReportLastestComments]'
UPDATE [dbo].[QStatus_ReportLastestComments] SET [Commentdt] = dbo.ToUtc([Commentdt])
GO
PRINT '[dbo].[QStatus_SpecialTasks]'
UPDATE [dbo].[QStatus_SpecialTasks] SET [UpdatedDate] = dbo.ToUtc([UpdatedDate])
GO
PRINT '[dbo].[QStatus_Supervisors]'
UPDATE [dbo].[QStatus_Supervisors] SET [AsOf] = dbo.ToUtc([AsOf])
GO
PRINT '[dbo].[QStatus_TaskNameChanges]'
UPDATE [dbo].[QStatus_TaskNameChanges] SET [UpdateDt] = dbo.ToUtc([UpdateDt])
GO
PRINT '[dbo].[QStatus_TempTasks]'
UPDATE [dbo].[QStatus_TempTasks] SET [input_date] = dbo.ToUtc([input_date])
--UPDATE [dbo].[Schedule_PriorityList] SET [CreatedDate] = dbo.ToUtc([CreatedDate]),[ModifiedDate] = dbo.ToUtc([ModifiedDate])
--UPDATE [dbo].[Schedule_PriorityList_Exclude] SET [ExcludedDate] = dbo.ToUtc([ExcludedDate]),[CreatedDate] = dbo.ToUtc([CreatedDate])
GO
PRINT '[dbo].[Supervisor_PriorityList_Report_Schedule]'
UPDATE [dbo].[Supervisor_PriorityList_Report_Schedule] SET [CreatedDate] = dbo.ToUtc([CreatedDate]),[ModifiedDate] = dbo.ToUtc([ModifiedDate])
GO
PRINT '[dbo].[QStatus_SupervisorsLastViewed]'
UPDATE [dbo].[QStatus_SupervisorsLastViewed] SET [LastViewed] = dbo.ToUtc([LastViewed])
GO
PRINT '[dbo].[QStatus_OnHold]'
UPDATE [dbo].[QStatus_OnHold] SET [StartDt] = dbo.ToUtc([StartDt]),[Enddt] = dbo.ToUtc([Enddt])
GO
PRINT '[dbo].[QStatus_GroupReport]'
UPDATE [dbo].[QStatus_GroupReport] SET [AsOf] = dbo.ToUtc([AsOf])
GO
PRINT '[dbo].[QCheck_UpcomingDueTimes]'
UPDATE [dbo].[QCheck_UpcomingDueTimes] SET [DueTime] = dbo.ToUtc([DueTime]),[RelativeDueTime] = dbo.ToUtc([RelativeDueTime])
GO
PRINT '[dbo].[QStatus_ActiveChecklistTaskType]'
UPDATE [dbo].[QStatus_ActiveChecklistTaskType] SET [CreateDt] = dbo.ToUtc([CreateDt])
GO
PRINT '[dbo].[QStatus_ActiveChecklistTaskTypeArchive]'
UPDATE [dbo].[QStatus_ActiveChecklistTaskTypeArchive] SET [CreateDt] = dbo.ToUtc([CreateDt]),[ArchiveDt] = dbo.ToUtc([ArchiveDt])
GO
PRINT '[dbo].[QStatus_CommentArchive]'
UPDATE [dbo].[QStatus_CommentArchive] SET [CommentDt] = dbo.ToUtc([CommentDt]),[AsOfDate] = dbo.ToUtc([AsOfDate])
GO
PRINT '[dbo].[QStatus_Comments]'
UPDATE [dbo].[QStatus_Comments] SET [CommentDt] = dbo.ToUtc([CommentDt])
GO
PRINT '[dbo].[QStatus_DueDateChanges]'
UPDATE [dbo].[QStatus_DueDateChanges] SET [DueDateOld] = dbo.ToUtc([DueDateOld]),[UpdateDt] = dbo.ToUtc([UpdateDt])
GO
PRINT '[dbo].[Temp_UpdateSchedule]'
UPDATE [dbo].[Temp_UpdateSchedule] SET [Dt] = dbo.ToUtc([dt])
GO
PRINT '[dbo].[QCheck_BonusesPaid]'
UPDATE [dbo].[QCheck_BonusesPaid] SET [dt] = dbo.ToUtc([dt])
--UPDATE [dbo].[QCheck_BonusCommentsLog] SET [Dt] = dbo.ToUtc([dt])
GO
PRINT '[dbo].[Grading_Daily]'
UPDATE [dbo].[Grading_Daily] SET [dt] = dbo.ToUtc([dt])
GO
PRINT '[dbo].[Grading_Daily_Comments]'
UPDATE [dbo].[Grading_Daily_Comments] SET [CommentDt] = dbo.ToUtc([CommentDt])
GO
PRINT '[dbo].[Grading_Daily_Final]'
UPDATE [dbo].[Grading_Daily_Final] SET [dt] = dbo.ToUtc([dt])
GO
PRINT '[dbo].[Grading_Daily_Final_Deleted]'
UPDATE [dbo].[Grading_Daily_Final_Deleted] SET [dt] = dbo.ToUtc([dt])
GO
PRINT '[dbo].[Grading_Daily_GradingPeriod]'
UPDATE [dbo].[Grading_Daily_GradingPeriod] SET [StartDt] = dbo.ToUtc([StartDt]),[EndDt] = dbo.ToUtc([EndDt])
GO
PRINT '[dbo].[Grading_Daily_UserReport]'
UPDATE [dbo].[Grading_Daily_UserReport] SET [dt] = dbo.ToUtc([dt])
GO
PRINT '[dbo].[Grading_OnHold]'
UPDATE [dbo].[Grading_OnHold] SET [StartDt] = dbo.ToUtc([StartDt]),[EndDt] = dbo.ToUtc([EndDt])
GO
PRINT '[dbo].[Grading_QProcessTests]'
UPDATE [dbo].[Grading_QProcessTests] SET [gradeddt] = dbo.ToUtc([gradeddt])
GO
PRINT '[dbo].[Grading_Vacations]'
UPDATE [dbo].[Grading_Vacations] SET [StartDt] = dbo.ToUtc([StartDt]),[EndDt] = dbo.ToUtc([EndDt])
GO
PRINT '[dbo].[JB_Tasks_Archive_Full]'
UPDATE [dbo].[JB_Tasks_Archive_Full] SET [duetime] = dbo.ToUtc([duetime]),[Commentdt] = dbo.ToUtc([Commentdt])
GO
PRINT '[dbo].[OverDueTasks_LateFee_Log]'
UPDATE [dbo].[OverDueTasks_LateFee_Log] SET [DueDate] = dbo.ToUtc([DueDate]),[CompletedDate] = dbo.ToUtc([CompletedDate]),[AsOfDate] = dbo.ToUtc([AsOfDate]),[RunDate] = dbo.ToUtc([RunDate]),[ExcusedDt] = dbo.ToUtc([ExcusedDt])
GO
PRINT '[dbo].[OverDueTasks_LateFee_Log_bkup]'
UPDATE [dbo].[OverDueTasks_LateFee_Log_bkup] SET [DueDate] = dbo.ToUtc([DueDate]),[CompletedDate] = dbo.ToUtc([CompletedDate]),[AsOfDate] = dbo.ToUtc([AsOfDate]),[RunDate] = dbo.ToUtc([RunDate])
GO
PRINT '[dbo].[OverDueTasks_LateFee_Log_bkup_03052018]'
UPDATE [dbo].[OverDueTasks_LateFee_Log_bkup_03052018] SET [DueDate] = dbo.ToUtc([DueDate]),[CompletedDate] = dbo.ToUtc([CompletedDate]),[AsOfDate] = dbo.ToUtc([AsOfDate]),[RunDate] = dbo.ToUtc([RunDate]),[ExcusedDt] = dbo.ToUtc([ExcusedDt])
--UPDATE [dbo].[QCheck_BonusEmailTasks] SET [dt] = dbo.ToUtc([dt])
--UPDATE [dbo].[PFS_SupervisorTasks] SET [Dt] = dbo.ToUtc([dt])
GO
PRINT '[dbo].[Email2dbImageChecklists_Archive]'
UPDATE [dbo].[Email2dbImageChecklists_Archive] SET [archivedt] = dbo.ToUtc([archivedt])
GO
PRINT '[dbo].[Audit_ActiveItem]'
UPDATE [dbo].[Audit_ActiveItem] SET [AuditDt] = dbo.ToUtc([AuditDt])
GO
PRINT '[dbo].[Audit_ApprovalChecklist]'
UPDATE [dbo].[Audit_ApprovalChecklist] SET [AuditDt] = dbo.ToUtc([AuditDt])
GO
PRINT '[dbo].[Audit_ApprovalItem]'
UPDATE [dbo].[Audit_ApprovalItem] SET [AuditDt] = dbo.ToUtc([AuditDt])
GO
PRINT '[dbo].[Audit_ArchiveActiveChecklist]'
UPDATE [dbo].[Audit_ArchiveActiveChecklist] SET [ArchiveDt] = dbo.ToUtc([ArchiveDt]),[DueTime] = dbo.ToUtc([DueTime]),[OrigDueTime] = dbo.ToUtc([OrigDueTime]),[ReminderDate] = dbo.ToUtc([ReminderDate]),[CompletedDate] = dbo.ToUtc([CompletedDate])
GO
PRINT '[dbo].[Audit_ArchiveActiveItem]'
UPDATE [dbo].[Audit_ArchiveActiveItem] SET [ArchiveDt] = dbo.ToUtc([ArchiveDt])
GO
PRINT '[dbo].[Audit_ArchiveApprovalChecklist]'
UPDATE [dbo].[Audit_ArchiveApprovalChecklist] SET [ArchiveDt] = dbo.ToUtc([ArchiveDt])
GO
PRINT '[dbo].[Audit_ArchiveApprovalItem]'
UPDATE [dbo].[Audit_ArchiveApprovalItem] SET [ArchiveDt] = dbo.ToUtc([ArchiveDt])
GO
PRINT '[dbo].[Audit_ArchiveChecklist]'
UPDATE [dbo].[Audit_ArchiveChecklist] SET [ArchiveDt] = dbo.ToUtc([ArchiveDt]),[CreateDate] = dbo.ToUtc([CreateDate])
GO
PRINT '[dbo].[Audit_ArchiveComment]'
UPDATE [dbo].[Audit_ArchiveComment] SET [ArchiveDt] = dbo.ToUtc([ArchiveDt]),[CommentDt] = dbo.ToUtc([CommentDt])
GO
PRINT '[dbo].[Audit_ArchiveItem]'
UPDATE [dbo].[Audit_ArchiveItem] SET [ArchiveDt] = dbo.ToUtc([ArchiveDt])
GO
PRINT '[dbo].[Audit_ChangeRequest]'
UPDATE [dbo].[Audit_ChangeRequest] SET [AuditDt] = dbo.ToUtc([AuditDt])
GO
PRINT '[dbo].[Audit_Checklist]'
UPDATE [dbo].[Audit_Checklist] SET [AuditDt] = dbo.ToUtc([AuditDt])
GO
PRINT '[dbo].[Audit_Comment]'
UPDATE [dbo].[Audit_Comment] SET [AuditDt] = dbo.ToUtc([AuditDt])
GO
PRINT '[dbo].[Audit_CommentArchived]'
UPDATE [dbo].[Audit_CommentArchived] SET [AuditDt] = dbo.ToUtc([AuditDt])
GO
PRINT '[dbo].[Audit_Item]'
UPDATE [dbo].[Audit_Item] SET [AuditDt] = dbo.ToUtc([AuditDt])
GO
PRINT '[dbo].[Audit_PageVisit]'
UPDATE [dbo].[Audit_PageVisit] SET [AuditDt] = dbo.ToUtc([AuditDt])
GO
PRINT '[dbo].[Audit_PriorityListSet]'
UPDATE [dbo].[Audit_PriorityListSet] SET [AuditDt] = dbo.ToUtc([AuditDt])
GO
PRINT '[dbo].[Audit_Report]'
UPDATE [dbo].[Audit_Report] SET [AuditDt] = dbo.ToUtc([AuditDt])
GO
PRINT '[dbo].[Audit_TaskType]'
UPDATE [dbo].[Audit_TaskType] SET [AuditDt] = dbo.ToUtc([AuditDt])
--UPDATE [dbo].[PFS_SupervisorUserNames] SET [Dt] = dbo.ToUtc([dt])
--UPDATE [dbo].[PFS_BonusDatesAmounts] SET [Dt] = dbo.ToUtc([dt])
GO
PRINT '[dbo].[QCheck_ActiveItems]'
UPDATE [dbo].[QCheck_ActiveItems] SET [CompletedDate] = dbo.ToUtc([CompletedDate])
GO
PRINT '[dbo].[QCheck_AlertArchive]'
UPDATE [dbo].[QCheck_AlertArchive] SET [SentTime] = dbo.ToUtc([SentTime]),[ArchiveDate] = dbo.ToUtc([ArchiveDate])
GO
PRINT '[dbo].[QCheck_AlertEmailWork]'
UPDATE [dbo].[QCheck_AlertEmailWork] SET [DueTime] = dbo.ToUtc([DueTime])
GO
PRINT '[dbo].[QCheck_Alerts]'
UPDATE [dbo].[QCheck_Alerts] SET [SentTime] = dbo.ToUtc([SentTime])
GO
PRINT '[dbo].[QCheck_Approval_ActiveChecklists]'
UPDATE [dbo].[QCheck_Approval_ActiveChecklists] SET
	[DueTime] = dbo.ToUtc([DueTime]),
	[OrigDueTime] = dbo.ToUtc([OrigDueTime]),
	[ReminderDate] = dbo.ToUtc([ReminderDate]),
	[CompletedDate] = dbo.ToUtc([CompletedDate])
GO
PRINT '[dbo].[QCheck_Approval_Alerts]'
UPDATE [dbo].[QCheck_Approval_Alerts] SET [SentTime] = dbo.ToUtc([SentTime])
GO
PRINT '[dbo].[QCheck_Approval_Assignments]'
UPDATE [dbo].[QCheck_Approval_Assignments] SET [DtAssigned] = dbo.ToUtc([DtAssigned])
GO
PRINT '[dbo].[QCheck_Approval_ChangeRequests]'
UPDATE [dbo].[QCheck_Approval_ChangeRequests] SET [RequestDate] = dbo.ToUtc([RequestDate]),[ApprovedDate] = dbo.ToUtc([ApprovedDate]),[RejectedDate] = dbo.ToUtc([RejectedDate])
GO
PRINT '[dbo].[QCheck_Approval_ChangeRequests_Archive]'
UPDATE [dbo].[QCheck_Approval_ChangeRequests_Archive] SET [RequestDate] = dbo.ToUtc([RequestDate]),[ApprovedDate] = dbo.ToUtc([ApprovedDate]),[RejectedDate] = dbo.ToUtc([RejectedDate]),[ArchiveDt] = dbo.ToUtc([ArchiveDt])
GO
PRINT '[dbo].[QCheck_ActiveItemArchive]'
UPDATE [dbo].[QCheck_ActiveItemArchive] SET [CompletedDate] = dbo.ToUtc([CompletedDate]),[ArchiveDate] = dbo.ToUtc([ArchiveDate])
GO
PRINT '[dbo].[QCheck_Approval_Schedule]'
UPDATE [dbo].[QCheck_Approval_Schedule] SET TimeZone = 'America/Chicago'
--[firstDueDate] = dbo.ToUtc([firstDueDate]),[lastDueDate] = dbo.ToUtc([lastDueDate])
GO
PRINT '[dbo].[QCheck_AssignedEmail_Queue]'
UPDATE [dbo].[QCheck_AssignedEmail_Queue] SET [AssignedDt] = dbo.ToUtc([AssignedDt]),[SentDt] = dbo.ToUtc([SentDt])
GO
PRINT '[dbo].[QCheck_AssignmentArchive]'
UPDATE [dbo].[QCheck_AssignmentArchive] SET [DtAssigned] = dbo.ToUtc([DtAssigned]),[ArchiveDate] = dbo.ToUtc([ArchiveDate])
GO
PRINT '[dbo].[QCheck_Assignments]'
UPDATE [dbo].[QCheck_Assignments] SET [DtAssigned] = dbo.ToUtc([DtAssigned])
GO
PRINT '[dbo].[QCheck_AssignmentsTemporary]'
UPDATE [dbo].[QCheck_AssignmentsTemporary] SET 
	[TempAssignmentStart] = dbo.ToUtc([TempAssignmentStart]),
	[TempAssignmentEnd] = dbo.ToUtc([TempAssignmentEnd]),
	[CreatedDt] = dbo.ToUtc([CreatedDt])
GO
PRINT '[dbo].[QCheck_AssignmentsTemporary_History]'
UPDATE [dbo].[QCheck_AssignmentsTemporary_History] SET [TempAssignmentStart] = dbo.ToUtc([TempAssignmentStart]),[TempAssignmentEnd] = dbo.ToUtc([TempAssignmentEnd]),[CreatedDt] = dbo.ToUtc([CreatedDt]),[ArchiveDt] = dbo.ToUtc([ArchiveDt])
GO
PRINT '[dbo].[QCheck_BonusChangeRequests]'
UPDATE [dbo].[QCheck_BonusChangeRequests] SET [Dt] = dbo.ToUtc([dt])
--UPDATE [dbo].[PFS_UserList] SET [StartDt] = dbo.ToUtc([StartDt]),[Enddt] = dbo.ToUtc([Enddt])
GO
PRINT '[dbo].[QCheck_ActiveChecklists]'
UPDATE [dbo].[QCheck_ActiveChecklists] SET 
	[DueTime] = dbo.ToUtc([DueTime]),
	[OrigDueTime] = dbo.ToUtc([OrigDueTime]),
	[ReminderDate] = dbo.ToUtc([ReminderDate]),
	[CompletedDate] = dbo.ToUtc([CompletedDate])
GO
PRINT '[dbo].[Priorities_Lists]'
UPDATE [dbo].[Priorities_Lists] SET [UpdatedDate] = dbo.ToUtc([UpdatedDate])
GO
PRINT '[dbo].[Priorities_ListSets]'
UPDATE [dbo].[Priorities_ListSets] SET [UpdatedDate] = dbo.ToUtc([UpdatedDate])
GO
PRINT '[dbo].[Priorities_Schedule]'
UPDATE [dbo].[Priorities_Schedule] SET [CreatedDate] = dbo.ToUtc([CreatedDate]),[ModifiedDate] = dbo.ToUtc([ModifiedDate])
GO
PRINT '[dbo].[Priorities_ScheduleExclude]'
UPDATE [dbo].[Priorities_ScheduleExclude] SET [ExcludedDate] = dbo.ToUtc([ExcludedDate]),[CreatedDate] = dbo.ToUtc([CreatedDate])
GO
PRINT '[dbo].[PriorityList_BonusSend]'
UPDATE [dbo].[PriorityList_BonusSend] SET [Dt] = dbo.ToUtc([dt])
GO
PRINT '[dbo].[PriorityList_LateFee_Log]'
UPDATE [dbo].[PriorityList_LateFee_Log] SET [LateDate] = dbo.ToUtc([LateDate])
GO
PRINT '[dbo].[PriorityListSet]'
UPDATE [dbo].[PriorityListSet] SET [UpdatedDate] = dbo.ToUtc([UpdatedDate])
GO
PRINT '[dbo].[QCheck_ActiveAlertArchive]'
UPDATE [dbo].[QCheck_ActiveAlertArchive] SET [SentTime] = dbo.ToUtc([SentTime]),[ArchiveDate] = dbo.ToUtc([ArchiveDate])
GO
PRINT '[dbo].[QCheck_ActiveAlerts]'
UPDATE [dbo].[QCheck_ActiveAlerts] SET [SentTime] = dbo.ToUtc([SentTime])
--UPDATE [dbo].[PFSData_BonusTests] SET [firstTestDt] = dbo.ToUtc([firstTestDt]),[finalTestDt] = dbo.ToUtc([finalTestDt])
GO
PRINT '[dbo].[QCheck_ActiveAssignmentArchive]'
UPDATE [dbo].[QCheck_ActiveAssignmentArchive] SET [ArchiveDate] = dbo.ToUtc([ArchiveDate])
GO
PRINT '[dbo].[QCheck_ActiveChecklistArchive]'
UPDATE [dbo].[QCheck_ActiveChecklistArchive] SET [DueTime] = dbo.ToUtc([DueTime]),[OrigDueTime] = dbo.ToUtc([OrigDueTime]),[ReminderDate] = dbo.ToUtc([ReminderDate]),[CompletedDate] = dbo.ToUtc([CompletedDate]),[ArchiveDate] = dbo.ToUtc([ArchiveDate])
GO
PRINT '[dbo].[PriorityList_LateFee_Log_Bkup]'
UPDATE [dbo].[PriorityList_LateFee_Log_Bkup] SET [LateDate] = dbo.ToUtc([LateDate])
GO

SELECT
    default_constraints.object_id ConstraintID, tables.name TableName, all_columns.name ColumnName, 
	default_constraints.name ConstraintName, default_constraints.definition ConstraintDefinition
INTO #getDateConstraints
FROM sys.all_columns
INNER JOIN sys.tables
	ON all_columns.object_id = tables.object_id
INNER JOIN sys.schemas
	ON tables.schema_id = schemas.schema_id
INNER JOIN sys.default_constraints
	ON all_columns.default_object_id = default_constraints.object_id
WHERE schemas.name = 'dbo'
    AND default_constraints.definition LIKE '%get%date()%'
ORDER BY tables.name, all_columns.name

SELECT * FROM #getDateConstraints

DECLARE @constraintID bigint

SELECT TOP 1 @constraintID = ConstraintID 
FROM #getDateConstraints 
ORDER BY TableName, ColumnName

DECLARE @sql nvarchar(max)

WHILE @constraintID IS NOT NULL
BEGIN

	SELECT @sql = 'ALTER TABLE [' + TableName + '] DROP CONSTRAINT [' + ConstraintName + ']' 
		FROM #getDateConstraints WHERE ConstraintID = @constraintID

	PRINT @sql
	EXEC (@sql)

	SELECT @sql = 'ALTER TABLE [dbo].['+TableName+'] ADD CONSTRAINT [DF_'+TableName+'_'+ColumnName+'] DEFAULT '+REPLACE(ConstraintDefinition, 'getdate()', 'getutcdate()')+' FOR ['+ColumnName+']'
		FROM #getDateConstraints WHERE ConstraintID = @constraintID
	PRINT @sql
	EXEC (@sql)	

	DELETE FROM #getDateConstraints WHERE ConstraintID = @constraintID
	
	SET @constraintID = null

	SELECT TOP 1 @constraintID = ConstraintID FROM #getDateConstraints
		ORDER BY TableName, ColumnName
END

DROP TABLE #getDateConstraints
GO

ALTER TRIGGER [dbo].[trg_QCheck_ActiveChecklists_UPDATE]
ON [dbo].[QCheck_ActiveChecklists]
FOR UPDATE AS

BEGIN

	UPDATE 
		QCheck_ActiveChecklists
	SET 
		ReminderDate = i.DueTime
	FROM
		QCheck_ActiveChecklists ac
		INNER JOIN INSERTED i
			ON ac.[ID] = i.[ID]
		INNER JOIN DELETED d
			ON ac.[ID] = d.[ID]
	WHERE
		-- Times were the same before the update
		CONVERT(VARCHAR(10), d.ReminderDate, 101) = CONVERT(VARCHAR(10), d.DueTime, 101)
		-- Soft due was not updated
		AND CONVERT(VARCHAR(10), i.ReminderDate, 101) = CONVERT(VARCHAR(10), d.ReminderDate, 101)
END
GO

ENABLE TRIGGER [dbo].[trg_QCheck_ActiveChecklists_UPDATE]
ON [dbo].[QCheck_ActiveChecklists]
GO

ALTER PROC [dbo].[QCheck_CreateSimple_part1]
	@ID INT OUTPUT,
	@Name varchar(500),
	@Priority int = 1,
	@DueDate datetime,
	@CreatedBy int,
	@TaskType int = null,
	@PrevFreqType int = 0 output,
	@RowsUpdated int = 0 output,
	@NewInstanceID int output,
	@NewActiveID int output,
	@GroupID int,
	@Activate bit = 1,
	@IsReminder bit = 0,
	@ReminderDate datetime = NULL,
	@AddToPriorityList bit=0,--added by venkat 04/20/2017
	@DueTime int = NULL,
	@TimeZone varchar(255) = NULL
AS
BEGIN
	SET NOCOUNT ON
	
	IF @ReminderDate IS NULL SET @ReminderDate = @DueDate

	DECLARE @UserID int,
			@FolderID int,
			@FolderName varchar(50),
			@recordIds AS RecordId,
			@PrevSchedule bit = 0,
			@ReportID int = 0

	IF @TimeZone IS NULL BEGIN
		SELECT @TimeZone = ISNULL(TimeZoneOverride, LastTimeZone) FROM QCheck_Users WHERE ID = @CreatedBy
	END

	IF @DueTime IS NULL BEGIN
		SELECT @DueTime = duetime FROM QCheck_UserDefaultTimes WHERE UserID = @CreatedBy

		IF @DueTime IS NULL
			SELECT @DueTime = duetime from QCheck_UserDefaultTimes WHERE UserID = -1
	END

	SELECT @ReportID = reportID
	FROM QStatus_TaskTypes
	WHERE ID = @TaskType

	INSERT INTO QCheck_Checklists ([Name], Owner) VALUES (@Name, @CreatedBy)
	SELECT @ID = SCOPE_IDENTITY()	

	INSERT INTO @recordIds VALUES(@ID)
	EXEC dbo.Audit_Set @CreatedBy, @recordIds, 'Checklist', 1

	-- 2011 dalvarado
	-- Changed up the rules a bit. Before, if this task was created from a status
	-- report then all report controllers were controllers of the task. Now, the
	-- rules are the same no matter where a task was created. The task creator is
	-- always the controller. If this is a supervisor controlled task, then the 
	-- task controller will be overridden by whoever was chosen in the interface.

	-- Creator is the controller
	DECLARE @ControllerGroupID int
	SELECT @ControllerGroupID = ID
	FROM QCheck_Groups
	WHERE owner = @CreatedBy
	AND SingleMemberGroup = 1

	INSERT INTO QCheck_ChecklistManagers
	(ChecklistID, ManagerGroupID)
	VALUES (@ID, @ControllerGroupID)

	-- Do the report stuff if this task was created from a status report
	IF @ReportID > 0 BEGIN

		DELETE FROM QStatus_ReportFolders
		WHERE folderid not in (SELECT ID FROM QCheck_Folders)

		DECLARE FOLDERCREATE CURSOR FOR 	
			SELECT DISTINCT 
				u.ID, 
				CASE 
					WHEN len(r.Name) > 41 THEN 'Status - ' + LEFT(r.Name, 38)+'...'
					ELSE 'Status - ' + r.Name
				END
			FROM 
				QStatus_GroupReport gr
				INNER JOIN QCheck_Groups g
					ON g.ID = gr.GroupID
				INNER JOIN QCheck_Groupmembership gm
					ON gm.GroupID = g.ID
				INNER JOIN Qstatus_Report r
					ON gr.ReportID = r.ID
					AND r.ID = @ReportID
				INNER JOIN QCheck_Users u
					ON u.ID = gm.UserID 
					AND u.IsDeleted = 0
				LEFT OUTER JOIN (
					SELECT f.UserID, rf.ReportID
					FROM QCheck_Folders f
					INNER JOIN QStatus_ReportFolders rf
					ON f.ID = rf.FolderID
				) folders
					ON folders.reportID = r.ID
				AND folders.UserID = u.ID
			WHERE 
				folders.UserID is null 
		
		OPEN FOLDERCREATE

		FETCH NEXT FROM FOLDERCREATE INTO @UserID, @FolderName
		WHILE @@FETCH_STATUS = 0 BEGIN
			INSERT INTO QCheck_Folders
			SELECT @UserID, @FolderName, 0
			
			SELECT @FolderID = SCOPE_IDENTITY()

			INSERT INTO QStatus_ReportFolders
			SELECT @ReportID, @FolderID

			FETCH NEXT FROM FOLDERCREATE INTO @UserID, @FolderName
		END
		CLOSE FOLDERCREATE
		DEALLOCATE FOLDERCREATE

		INSERT INTO QCheck_FolderChecklists
			SELECT 
				@ID, rf.FolderID
			FROM 
				QStatus_ReportFolders rf
				INNER JOIN QCheck_Folders f
					ON rf.FolderID = f.ID
				INNER JOIN QCheck_Users u
					ON u.ID = f.UserID
					AND u.IsDeleted = 0
			WHERE 
				rf.ReportID = @ReportID
		
	END	

	EXEC QCheck_AddItem @ID, null, 1, @Name, '', @CreatedBy

	EXEC QCheck_CreateInstance @ID = @NewInstanceID output, @ChecklistID = @ID, @Name = '', @CreatedBy = @CreatedBy, @TimeZone = @TimeZone

	EXEC QCheck_AddAssignedTo @NewInstanceID, @GroupID, @CreatedBy

	---- KVS 2017-09-26 - Removing these default alerts per GPR/Nelson;
	----	Users who want them can add them manually
	---- Reminder 1 day before due
	--EXEC QCheck_AddAlert
	--		@InstanceID = @NewInstanceID, 
	--		@nagBeforeDays = 1,
	--		@nagTime = 17,
	--		@alertType = 'Reminder'
			
	---- 2/11/2014 dalvarado - Also set a reminder for 1 hour before due
	--EXEC QCheck_AddAlert
	--		@InstanceID = @NewInstanceID, 
	--		@nagBeforeDays = NULL,
	--		@nagTime = -1,
	--		@alertType = 'Reminder'
	

	EXEC QCheck_UpdateSchedule_part1 
			@InstanceID = @NewInstanceID, 
			@firstDueDate = @DueDate,
			@freqType = 1, 
			@dueTime = @DueTime,
			@PrevFreqType = @PrevFreqType output,
			@RowsUpdated = @RowsUpdated output,
			@Activate = @Activate,
			@TimeZone = @TimeZone

	DECLARE @SoftDueOffsetDays INT = 0
	IF @DueDate <> ISNULL(@ReminderDate, @DueDate) BEGIN	
		
		SELECT @SoftDueOffsetDays = DATEDIFF(DAY, @ReminderDate, @DueDate)
		
		IF @SoftDueOffsetDays > 0 BEGIN
		
			UPDATE QCheck_Schedule
			SET SoftDueOffsetDays = @SoftDueOffsetDays
			WHERE ID = (
				SELECT ScheduleID
				FROM QCheck_ChecklistInstances 
				WHERE ID = @NewInstanceID
			)
			
		END
	
	END

	SELECT @NewActiveID = ID
	FROM QCheck_ActiveChecklists
	WHERE InstanceID = @NewInstanceID

	IF @NewActiveID IS NOT NULL 
	BEGIN
		DELETE @recordIds
		INSERT INTO @recordIds VALUES(@NewActiveID)
		EXEC dbo.Audit_Set @CreatedBy, @recordIds, 'ActiveChecklist', 3
	END

	-- Set the reminder date to whatever was passed in, if it's not past the due time
	UPDATE QCheck_ActiveChecklists
	SET ReminderDate = @ReminderDate
	WHERE 
		[ID] = @NewActiveID
		AND @ReminderDate <= DueTime

	IF @TaskType IS NOT NULL BEGIN
		DECLARE @NewTaskTypeID int
		EXEC QCheck_AddInstanceTaskType @NewInstanceID, @TaskType, @Priority, @NewTaskTypeID OUTPUT
	END 
	

	if (@AddToPriorityList=1)
	Begin
	 
		IF OBJECT_ID('tempdb.dbo.#UserList', 'U') IS NOT NULL
		DROP TABLE #UserList;

		Create table #UserList
		(
			seq INT IDENTITY(1,1),
			UserID int	
		)
	
		Insert into #UserList
		select UserID From QCheck_GroupMembership where GroupID=@GroupID

		Declare @userListCount int
		
		SELECT @userListCount = Count(*) FROM #UserList
		
		Declare @counter int=1
		Declare @AssignedToUserID int
		
		WHILE @counter <= @userListCount
		BEGIN
			set @AssignedToUserID=(select UserID from #UserList where seq=@counter)
			exec PriorityList_AddTask @UserID=@AssignedToUserID,@ActiveChecklistID=@NewActiveID
	 		
			SET @counter=@counter+1
		End		
	End
	----If the task isn't going on every assignee's priority list, if Brandon is an assignee, put it on his.
	--ELSE IF EXISTS (
	--		SELECT 'Y' from QCheck_Users u 
	--			JOIN QCheck_GroupMembership gm ON gm.UserID = u.ID AND gm.GroupID = @GroupID
	--		WHERE u.ID = 10
	--	) AND @NewActiveID IS NOT NULL
	--BEGIN
	--	exec PriorityList_AddTask @UserID=10, ActiveChecklistID=@NewActiveID
	--END
	
	-- rebuild cache
 EXEC QCheck_ChecklistControllersList_Refresh @ID
END
GO


ALTER PROCEDURE [dbo].[QCheck_CalculateNextDueTime]
      @InstanceID INT,
      @AsOfDate datetime,
      @DueDate datetime output,
      @RelativeDueDate datetime output
AS
BEGIN
	SET NOCOUNT ON
	DECLARE 
	   @param VARCHAR(8000)
	  ,@result VARCHAR(8000)
	  
	  ,@freqType int
	  ,@freqInterval int
	  ,@firstDueDate datetime
	  ,@lastDueDate datetime
	  ,@dueTime float
	  ,@freqRecurrance int
	  ,@ONCE int = 1
	  ,@DAILY int = 2
	  ,@WEEKLY int = 3
	  ,@MONTHLY int = 4
	  ,@YEARLY int = 5
	  ,@busDayBehavior int
	  ,@busDayValue int
	
	  ,@comparedate datetime
	  ,@tmpInt int
	  ,@tmpDate datetime
	  ,@tmpDate2 datetime
	  ,@tmpstr varchar(50)
	  ,@tmpstr2 varchar(50)
	  ,@timeZone varchar(255)
                  
    --get all the data from the schedule table based on the id passed in
    SELECT @freqType = s.freqType, 
        @dueTime = s.dueTime,
        @freqRecurrance = s.freqRecurrance,
        @firstDueDate = s.firstDueDate, 
        @freqInterval= s.freqInterval, 
        @lastDueDate = s.lastDueDate,
        @busDayBehavior = s.busDayBehavior,
        @busDayValue = s.busDayValue,
		@timeZone = s.TimeZone
    FROM 
    QCheck_Schedule s with (nolock)
    INNER JOIN QCheck_ChecklistInstances ci with (nolock)
    ON s.ID = ci.ScheduleID
    AND ci.[ID] = @InstanceID

	IF @AsOfDate IS NULL SET @AsOfDate = GETUTCDATE()
			
	--PRINT 'AS OF DATE   : ' + FORMAT(@AsOfDate, 'yyyy/MM/dd HH:mm:ss')
	--PRINT 'FRST DUE DATE: ' + FORMAT(@firstDueDate, 'yyyy/MM/dd HH:mm:ss')

	IF @AsOfDate <= dbo.ConvertTimeToUtc(CAST(@firstDueDate as date), @timeZone)
	BEGIN
		SET @AsOfDate = dbo.ConvertTimeToUtc(CAST(@firstDueDate as date), @timeZone)		
	END

	-- @CompareDate is compared to schedule dates and times (which are local), while @AsOfDate is UTC
	SET @comparedate = dbo.ConvertTimeFromUtc(@AsOfDate, @timeZone)
	--PRINT 'COMPARE  DATE: ' + FORMAT(@compareDate, 'yyyy/MM/dd HH:mm:ss')
    -- one time schedule
    IF (@freqType = @ONCE) BEGIN
        -- this one is easy. we just concatenate the start date and the end time and voila. Converting to just the date because
        -- we're going to add the hours back in later.
        SET @DueDate = CAST(@firstDueDate as date)
	END
    --daily schedule
    ELSE IF (@freqType = @DAILY) BEGIN
        --if we havent come to the time of day this checklist is due, we treat it as yesterday
        If (DatePart(hh, @compareDate)) + (DatePart(mi, @compareDate)/60.0) < @dueTime
            SET @compareDate = @compareDate - 1
        --PRINT 'COMPARE2 DATE: ' + FORMAT(@compareDate, 'yyyy/MM/dd HH:mm:ss')
		
        SET @tmpInt = 0
        --find out how many times this has occurred since it started, add one, and multiply by the number of days per occurance
        IF @compareDate > @firstDueDate
            SET @tmpInt = ((DateDiff(day, @firstDueDate, @compareDate)/@freqRecurrance) + 1)*@freqRecurrance
                  
        --add that to the start date, and we get the last time it was due
        SET @DueDate = DateAdd(day, @tmpInt, @firstDueDate)
		--PRINT 'PREV DUE DATE: ' + FORMAT(@DueDate, 'yyyy/MM/dd HH:mm:ss')
		
		while @dueDate < dbo.ConvertTimeFromUtc(@AsOfDate, @timeZone)
			SET @DueDate = DateAdd(day, @freqRecurrance, @DueDate)
    END
    --weekly schedule
    ELSE IF (@freqType = @WEEKLY) BEGIN
                  --if we have an interval, use the complex scheduling
                  IF (@freqInterval is not null and @freqInterval > 0)
                  BEGIN
                        
                        --declare temps
                        DECLARE @tbldays Table (daysFromNow int, dayint int)
                        DECLARE @iDay int, @daysFromNow int, @DAYOFWEEK int
                        DECLARE @totDaysFromNow int

                        
                        --if we havent come to the time of day this checklist occurs on, we treat it as yesterday
                        If (DatePart(hh, @compareDate) + DatePart(mi, @compareDate)/60.0) < @DueTime 
                              SET @compareDate = @compareDate - 1

                        SET @tmpInt = 0
                        --determine the correct week offset for this period
                        --IF @compareDate > @firstDueDate
                        SET @tmpInt = ((DateDiff(day, @firstDueDate, @compareDate)/(@freqRecurrance*7)))*@freqRecurrance*7
                        
                        if @compareDate<@firstDueDate
                              set @tmpInt = @freqRecurrance*-7
      
                        SET @tmpdate = DateAdd(day, @tmpInt, @firstDueDate)
                        SET @tmpInt = DateDiff(day, @tmpdate, @compareDate)/7 * 7

                        --day of week for today
                        SET @DAYOFWEEK = DATEPART(dw,@compareDate)      
                        
                        SET @iDay=1
                        select @daysFromNow = ((@iDay-@DAYOFWEEK) + 6)%7 + 1 - 7 - @tmpInt
                        
                        WHILE @iDay<=7
                        BEGIN
                              if (@daysFromNow > 0)
                                    SET @daysFromNow = @daysFromNow - ((@freqRecurrance) * 7)
                              INSERT INTO @tbldays VALUES(@daysFromNow, Power(2,@iDay-1))
                              SET @iDay = @iDay + 1
                              SET @daysFromNow = @daysFromNow + 1
                        END
                              
                        --get the max value that does not return a 0 bitwise
                        SELECT @totDaysFromNow = MAX(daysFromNow) 
                        FROM @tbldays 
                        WHERE @freqInterval & dayint > 0                        

                        --clean out the table
                        delete from @tbldays
      
                        --subtract number of days from today to get last due date
                        SET @DueDate = DateAdd(day, @totDaysFromNow, @compareDate)
                        SET @DueDate = DateAdd(hh, -1 * datepart(hour,@compareDate), @DueDate)
                        SET @DueDate = DateAdd(mi, -1 * datepart(minute,@compareDate), @DueDate)
                        SET @DueDate = DateAdd(second, -1 * datepart(second,@compareDate), @DueDate)
                        SET @DueDate = DateAdd(millisecond, -1 * datepart(millisecond,@compareDate), @DueDate)

						--PRINT 'PREV DUE DATE: ' + FORMAT(@DueDate, 'yyyy/MM/dd HH:mm:ss')
						--PRINT 'LOC ASOF DATE: ' + FORMAT(CAST(dbo.ConvertTimeFromUtc(@AsOfDate, @timeZone) as datetime), 'yyyy/MM/dd HH:mm:ss')
						--DECLARE @first bit = 1

						WHILE (@DueDate < CAST(@firstDueDate as DATE))
							OR (@DueDate < dbo.ConvertTimeFromUtc(@AsOfDate, @timeZone))
						BEGIN
							--day of week for last due date
							SET @DAYOFWEEK = DATEPART(dw,@DueDate)
							
							DELETE FROM @tblDays
							--insert a 'power' row for each day of the week
							SET @iDay=1
							WHILE @iDay<=7
							BEGIN
								  IF (@iDay > @DAYOFWEEK)
										SET @daysFromNow = ((@iDay-@DAYOFWEEK) + 6)%7 + 1
								  ELSE
										SET @daysFromNow = ((@iDay-@DAYOFWEEK) + 6)%7 + 1 + (7 * (@freqRecurrance - 1))

								  INSERT INTO @tbldays VALUES(@daysFromNow, Power(2,@iDay-1))
								  SET @iDay = @iDay + 1
							END

							--select * from @tbldays
                        
							--get the min value that does not return a 0 bitwise
							SELECT @totDaysFromNow = MIN(daysFromNow) 
							FROM @tbldays 
							WHERE @freqInterval & dayint > 0
                        
							--add number of days to last start date
							SET @DueDate = DateAdd(day, @totDaysFromNow, @DueDate)
							--PRINT 'CALC DUE DATE: ' + FORMAT(@DueDate, 'yyyy/MM/dd HH:mm:ss')

							--SET @first = 0
						END

                  END
                  --oherwise use the simple version and just add a number of weeks
                  ELSE 
                  BEGIN
                        --if we havent come to the time of day this checklist occurs on, we treat it as yesterday
                        If (DatePart(hh, @compareDate)) + (DatePart(mi, @compareDate)/60.0) < @DueTime 
                              SET @compareDate = @compareDate - 1

                        SET @tmpInt = 0
                        --find how many week periods have passed since we started - multiply by 7 to find number of days
                        IF @compareDate > @firstDueDate
                              SET @tmpInt = ((DateDiff(day, @firstDueDate, @compareDate)/(@freqRecurrance*7)) + 1)*@freqRecurrance*7
                        
                        --add that number of days to the start date and you get the last time it should have started
                        SET @DueDate = DateAdd(day, @tmpInt, @firstDueDate)
                  END
            END
      --monthly schedule
      Else If (@freqType = @MONTHLY)
            BEGIN

                  --if we are before the day specified or on the day but before the hour then subtract one month
                  SET @tmpstr = CAST(MONTH(@compareDate) as varchar)+'/1/'+CAST(YEAR(@compareDate)as varchar) 
                  SET @tmpdate = CAST(@tmpstr as datetime)
                  SET @tmpstr = CAST(MONTH(Dateadd(m,1,@compareDate)) as varchar)+'/1/'+CAST(YEAR(Dateadd(m,1,@compareDate))as varchar) 
                  SET @tmpdate2 = CAST(@tmpstr as datetime)
                        
                  If Not (DatePart(day, @firstDueDate) > DateDiff(d, @tmpdate, @tmpdate2) AND DatePart(day, @compareDate) = DateDiff(d, @tmpdate, @tmpdate2))
                  BEGIN
                        If DatePart(day, @compareDate) < DatePart(day, @firstDueDate) or (DatePart(day, @compareDate) = DatePart(day, @firstDueDate) and (DatePart(hh, @compareDate)) + (DatePart(mi, @compareDate)/60.0) < @DueTime)
                        BEGIN
                              SET @compareDate = dateadd(mm, -1, @compareDate)
                        END   
                  END

                  SET @tmpInt = 0
                  --find out how many times this has occurred since it started and multiply by the number of months per occurrance
                  IF @compareDate > @firstDueDate
                        SET @tmpInt = ((DateDiff(month, @firstDueDate, @compareDate)/@freqRecurrance)+1)*@freqRecurrance
                  
                  --add this number to the start date and you get the last occurrance
                  SET @DueDate = DateAdd(month, @tmpInt, @firstDueDate)

				  while @dueDate < dbo.ConvertTimeFromUtc(@AsOfDate, @timeZone)
			SET @DueDate = DateAdd(month, @freqRecurrance, @DueDate)
            END
      --yearly schedule
      Else If (@freqType = @YEARLY)
            BEGIN
                  IF (@freqInterval is not null and @freqInterval > 0)
                  BEGIN
                        --declare temps
                        DECLARE @tmpMonths Table (monthsFromNow int, monthInt int)
                        DECLARE @iMonth int, @monthsFromNow int, @month int
                        DECLARE @totMonthsFromNow int
                        DECLARE @tmpDay int, @iter int, @tmpMonth int, @tmpDateString varchar(50)
                        set @iter = 0
                        
                        SET @tmpDay = DAY(@firstDueDate)
                        SET @tmpDateString = CAST(MONTH(@compareDate) as varchar)+'/'+CAST(@tmpDay as varchar)+'/'+CAST(YEAR(@compareDate) as varchar)+ ' ' + CAST(CAST(@dueTime as int) as varchar)+':00:00'
                        
                        while ((isdate(@tmpDateString) = 0) and (@iter < 5))
                        BEGIN
                              set @tmpDay = DAY(@firstDueDate) - @iter
                              SET @tmpDateString = CAST(MONTH(@compareDate) as varchar)+'/'+CAST(@tmpDay as varchar)+'/'+CAST(YEAR(@compareDate) as varchar)+ ' ' + CAST(CAST(@DueTime as int) as varchar)+':00:00'
                              set @iter = @iter + 1
                        END

                        
                        
                        SET @compareDate = CAST(@tmpDateString as datetime)
                        --SET @compareDate = CAST(CAST(MONTH(@compareDate) as varchar)+'/'+CAST(DAY(@firstDueDate)as varchar)+'/'+CAST(YEAR(@compareDate) as varchar)+ ' ' + CAST(CAST(@startTime as int) as varchar)+':00:00' as datetime)
                        
                        if (@compareDate > @AsOfDate) 
                                    SET @compareDate = DateAdd(month, -1, @compareDate)
                        
                        SET @tmpInt = 0
                        --determine the correct month offset for this period
                        IF @compareDate > @firstDueDate
                              SET @tmpInt = ((DateDiff(month, @firstDueDate, @compareDate)/(@freqRecurrance*12)))*@freqRecurrance*12
                        
                        SET @tmpdate = DateAdd(month, @tmpInt, @firstDueDate)
                        SET @tmpInt = DateDiff(month, @tmpdate, @compareDate)/12 * 12
                        
                        --month for today
                        SET @month = DATEPART(m, @compareDate)
      
                        --insert a 'power' row for each month
                        SET @iMonth=1
                        SET @monthsFromNow = @iMonth - @month - @tmpInt
                        WHILE @iMonth<=12
                        BEGIN
                              if @monthsFromNow > 0 
                                    SET @monthsFromNow = @monthsFromNow - ((@freqRecurrance) * 12)
                              INSERT INTO @tmpMonths VALUES(@monthsFromNow, Power(2,@iMonth-1))
                              SET @iMonth = @iMonth + 1
                              SET @monthsFromNow = @monthsFromNow + 1
                        END

                        --get the max value that does not return a 0 bitwise
                        SELECT @totMonthsFromNow = MAX(monthsFromNow) 
                        FROM @tmpMonths 
                        WHERE @freqInterval & monthInt > 0
                        
                        delete from @tmpMonths

                        --subtract number of months from today
                        SET @tmpdate = DateAdd(month, @totMonthsFromNow, @compareDate)
                        SET @tmpstr = CAST(MONTH(@tmpdate) as varchar)+'/'+CAST(DAY(@firstDueDate)as varchar)+'/'+CAST(YEAR(@tmpdate)as varchar) + ' ' + CAST(CAST(@DueTime as int) as varchar)+':00:00'
                        
                        SET @iter = 1
                        while ((isdate(@tmpstr) = 0) and (@iter < 5))
                        BEGIN
                              set @tmpDay = DAY(@firstDueDate) - @iter
                              SET @tmpstr = CAST(MONTH(@tmpdate) as varchar)+'/'+CAST(@tmpDay as varchar)+'/'+CAST(YEAR(@tmpdate)as varchar) + ' ' + CAST(CAST(@DueTime as int) as varchar)+':00:00'
                              set @iter = @iter + 1
                        END
                        
                        SET @DueDate = CAST(@tmpstr as datetime)


                        
                        --month for last due time
                        SET @month = DATEPART(m,@DueDate)
      
                        --insert a 'power' row for each month
                        SET @iMonth=1
                        WHILE @iMonth<=12
                        BEGIN
                              IF (@iMonth > @month)
                                    SET @monthsFromNow = ((@iMonth-@month) + 11)%12 + 1
                              ELSE
                                    SET @monthsFromNow = ((@iMonth-@month) + 11)%12 + 1 + (12 * (@freqRecurrance - 1))

                              INSERT INTO @tmpMonths VALUES(@monthsFromNow, Power(2,@iMonth-1))
                              SET @iMonth = @iMonth + 1
                        END

                        --get the min value that does not return a 0 bitwise
                        SELECT @totMonthsFromNow = MIN(monthsFromNow) 
                        FROM @tmpMonths 
                        WHERE @freqInterval & monthInt > 0
                        
                        --add number of months to last start date
                        SET @tmpdate = DateAdd(month, @totMonthsFromNow, @DueDate)
      
                        --set the time
                        SET @tmpstr = CAST(MONTH(@tmpdate) as varchar)+'/'+CAST(DAY(@firstDueDate)as varchar)+'/'+CAST(YEAR(@tmpdate)as varchar) 
                        SET @iter = 1
                        while ((isdate(@tmpstr) = 0) and (@iter < 5))
                        BEGIN
                              set @tmpDay = DAY(@firstDueDate) - @iter
                              SET @tmpstr = CAST(MONTH(@tmpdate) as varchar)+'/'+CAST(@tmpDay as varchar)+'/'+CAST(YEAR(@tmpdate)as varchar)
                              set @iter = @iter + 1
                        END

                        
                        SET @DueDate = CAST(@tmpstr as datetime)
                  END
                  ELSE 
                  BEGIN
                        If DatePart(month,@compareDate) < DatePart(month, @firstDueDate) or (DatePart(month,@compareDate) = DatePart(month, @firstDueDate) and DatePart(day, @compareDate) < DatePart(day, @firstDueDate)) or (DatePart(month,@compareDate) = DatePart(month, @firstDueDate) and DatePart(day, @compareDate) = DatePart(day, @firstDueDate) and (DatePart(hh, @compareDate)) + (DatePart(mi, @compareDate)/60.0) < @DueTime)
                        BEGIN
                              SET @compareDate = DateAdd(yy, -1, @compareDate)
                        END
                        SET @tmpInt = 0
                        IF @compareDate > @firstDueDate
                              SET @tmpInt = ((DateDiff(year, @firstDueDate, @compareDate)/@freqRecurrance)+1)*@freqRecurrance
                        
                        SET @DueDate = DateAdd(year, @tmpInt, @firstDueDate)
                  END
            END
	  
      --make sure its after the first date
      if @DueDate <= @firstDueDate
		SET @DueDate = CAST(@firstDueDate as DATE)

      --set time
      SET @DueDate = DateAdd(hh, @DueTime, @DueDate)
      
      --add minutes
      If @DueTime - cast(@DueTime as int) > 0
      BEGIN
            SET @DueDate = DATEADD(mi, 30, @DueDate)
      END

	  --PRINT 'LOCL DUE DATE: ' + FORMAT(@DueDate, 'yyyy/MM/dd HH:mm:ss')

	  --Declaring here to use as input
	  DECLARE @DueDateOrig Datetime

	  SET @DueDateOrig = @DueDate	  

      SET @RelativeDueDate = NULL
      
      --check for after lastDueDate
      If @DueDate > dateadd(day, 1, @lastDueDate) --or  @DueDate < @AsOfDate or @DueDate < @firstDueDate 
		BEGIN
				--PRINT 'AFTER LAST DUE'
				SET @DueDate = null
				SET @RelativeDueDate = null
				SET @DueDateOrig = null
		END

      --if its not a business day, skip it
      IF @busDayBehavior = 1 
      BEGIN 
            IF dbo.Util_IsOfficeDay(@DueDate) = 0 
            BEGIN
				--PRINT 'NON-OFFICE DAY'
                  SET @DueDate = null
            END
      END

      IF @busDayBehavior = 2 
      BEGIN
            --move due date back to the previous business day
            IF dbo.Util_IsOfficeDay(@DueDate) = 0 
            BEGIN
                  SET @DueDate = dbo.Util_PriorOfficeDayMaintainTime(@DueDate)
            END 
      END

      IF @busDayBehavior = 3 
      BEGIN
            --move due date to the next business day
            IF dbo.Util_IsOfficeDay(@DueDate) = 0 
            BEGIN
                  SET @DueDate = dbo.Util_NextOfficeDayMaintainTime(@DueDate)
            END 
      END
      
      -- for Mandi IP, must happen on a specific business day, e.g., 5th business day
      IF @busDayBehavior = 4
      BEGIN
            SET @DueDate = CAST(MONTH(@DueDate) as varchar)+'/1/'+CAST(YEAR(@DueDate)as varchar) 
            --move due date to the first business day
            IF dbo.Util_IsOfficeDay(@DueDate) = 0 
            BEGIN
                  SET @DueDate = dbo.Util_NextOfficeDayMaintainTime(@DueDate)
            END 
            
            -- @DueDate currently now holds the 1st business day of the month, add more days if needed
            IF @busDayValue > 1
                  BEGIN
                        SET @DueDate = dbo.Util_AddBusinessDays(@DueDate, @busDayValue - 1)
                  END
            
            --set time
            SET @DueDate = DateAdd(hh, @DueTime, @DueDate)

            
            --add minutes
            If @DueTime - cast(@DueTime as int) > 0
            BEGIN
                  SET @DueDate = DATEADD(mi, 30, @DueDate)
            END
      END

	  -- convert back to UTC time	  
	  IF @timeZone IS NOT NULL AND @DueDate IS NOT NULL BEGIN
		EXEC QCheck_ConvertFromTimeZone @DueDate, @timeZone, @DueDate OUTPUT		
		EXEC QCheck_ConvertFromTimeZone @DueDateOrig, @timeZone, @DueDateOrig OUTPUT
		--PRINT 'UTC  DUE DATE: ' + FORMAT(@DueDate, 'yyyy/MM/dd HH:mm:ss')
	  END  

      If IsNull(@DueDate, 0) <> IsNull(@DueDateOrig, 0) SET @RelativeDueDate = @DueDateOrig
	  --PRINT ''
	  --PRINT 'DUE DATE: ' + ISNULL(FORMAT(@DueDate, 'yyyy/MM/dd HH:mm:ss'), 'NULL')
	  --PRINT 'REL DUE DATE: ' + ISNULL(FORMAT(@RelativeDueDate, 'yyyy/MM/dd HH:mm:ss'), 'NULL')
	  --PRINT ''
END
GO

-- This stored procedure will Activate a Checklist Instance by creating records in the 
-- Active checklist and Active Assignments tables
ALTER PROCEDURE [dbo].[QCheck_ActivateInstance](
	@InstanceID INT,
	@AsOfDate datetime
)
 AS

BEGIN
	
	SET NOCOUNT ON
	
	DECLARE @dueDate datetime 
	DECLARE @relativeDue datetime
	DECLARE @count int
	DECLARE @assignmentID int
	DECLARE @iRow int
	DECLARE @ID int
	
	--Calculate the relevant dates through this sp
	EXEC [QCheck_CalculateNextDueTime]  @InstanceID, @AsofDate, @dueDate output, @relativeDue output

	
	If IsNull(@dueDate, 0) > GETUTCDATE()
	and not exists (
			select 1 from QCheck_ActiveChecklists 
			where instanceID = @InstanceID
			and OrigDueTime = @dueDate
			and DueTime = @dueDate
	)
	BEGIN
	
		DECLARE @tmptbl TABLE(	
		  RowID INT IDENTITY(1, 1),
	          assignmentID Int)
	
		
		--activate the checklist
		INSERT INTO QCheck_ActiveChecklists
		(InstanceID, DueTime, OrigDueTime)
		VALUES
		(@InstanceID, @dueDate, @dueDate)
	
		SELECT @ID = SCOPE_IDENTITY()	

		-- gather the assignments
		INSERT INTO @tmptbl
		SELECT [ID]
		FROM QCheck_Assignments
		WHERE InstanceID = @InstanceID
		AND IsDeleted = 0
			
		SET @count = @@ROWCOUNT
		--initialize index counter
		SET @iRow = 1
		--establish loop structure
		WHILE @iRow <= @count
		BEGIN
			--get row values
			SELECT @assignmentID = assignmentID
			FROM @tmptbl
			WHERE RowID = @iRow
		
			
			
			--activate the assignment
			INSERT INTO QCheck_ActiveAssignments
			(ActiveChecklistID, AssignmentsID)
			VALUES
			(@ID, @assignmentID)
			
			Set @iRow = @iRow + 1
	
		END

		EXEC QCheck_ActivateStatus @InstanceID, @ID
	
		exec QCheck_CreateActiveAlerts @InstanceID

		EXEC QCheck_ActiveInstanceAlert @ID, 'Start'
	END


	SET NOCOUNT OFF

END
GO


ALTER     PROC [dbo].[QStatus_GetReport] (
--DECLARE
	@UserID int,
	@ReportID int,
	@deletedDate datetime = null,
	@MoveCompleted bit = 0,
	@DueFilter datetime = null,
	@AssignedTo int = -1,
	@PriorityListSetID INT = -1

) AS
BEGIN
	
	--exec sp_recompile 'QStatus_GetReport'
 
	SET NOCOUNT ON
	
	DECLARE @ReportUserID int
	DECLARE @LastReadDate datetime
	DECLARE @CompletedType varchar(50)
	DECLARE @CompletedOrder int
	DECLARE @Seed int
	DECLARE @PriorityListSetName VARCHAR(50)
	
	INSERT INTO QStatus_Seed
		SELECT 1

	SELECT @Seed = scope_identity()

	DELETE FROM QStatus_Seed
	--find all the tasks

	DECLARE @ForeignKeyIDs TABLE (
		ForeignKeyID INT PRIMARY KEY
	)

	INSERT INTO @ForeignKeyIDs 
		SELECT distinct activechecklistid 
		FROM qstatus_commentedreporttasks
		WHERE reportID = @reportID 

	--add a day to whatever was passed in (takes care of default to midnight)
	IF @DueFilter is not null
		SET @DueFilter = DateAdd(day, 1, @DueFilter)
	
	SELECT @CompletedType = 'Completed'
	--find out if they are a user or supervisor/ip

	SET @ReportUserID = 0

	SELECT 
		@ReportUserID = UserID
	FROM
		QStatus_GroupReport gr
		INNER JOIN QCheck_Groups g
			ON g.ID = gr.GroupID
		INNER JOIN QCheck_GroupMembership gm
			ON gm.GroupID = g.ID
			AND gr.ReportID = @ReportID
			AND gm.UserID = @UserID

	--default to 60 days ago
	SELECT @LastReadDate = getdate() - 60
	
	--find last time it was marked read by you if you are supervisor/ip
	SELECT 
		@LastReadDate = LastViewed
	FROM 
		QStatus_SupervisorsLastViewed
	WHERE
		ReportID = @ReportID 
		AND SupervisorUserID = @UserID
	
	--if it is your report, just use yesterday
	IF @ReportUserID = @UserID
		SELECT @LastReadDate = dateadd(day, -1, getdate())

	DECLARE @tasks table(
		ID int PRIMARY KEY,
		DueTime datetime,
		ReminderDate datetime,
		InstanceID int,
		assignees varchar(1000),
		controllers VARCHAR(1000),
		tasktype int,
		taskdescription varchar(1000),
		nativetype int,
		tasktypeorder int,
		priority int,
		prioritychanged bit,
		duedatechanged bit,
		newtask bit,
		CompletedDate datetime,
		Archived bit,
		description varchar(1000),
		tasknamechanged bit,
		isDeleted bit,
		isRecurring bit,
		isPriority bit,
		isDaily bit
	)

	declare @instances table(
		ID int PRIMARY KEY,
		ChecklistID int,
		isRecurring bit
	)

	declare @checklists table(
		ID int PRIMARY KEY,
		Description varchar(1000),
		tasknamechanged bit
	)

	-- 02/23/2011 dalvarado - priorities section
	declare @priorities table (
		ID int PRIMARY KEY IDENTITY(1,1),
		ListID int,
		InstanceID INT,
		Priority INT
	)

	INSERT INTO @priorities (
		ListID,
		InstanceID,
		Priority
	)
		SELECT 
			pl.ID,
			ac.InstanceID,
			pli.Priority
		FROM
			Priorities_ListSetLists plsl
			INNER JOIN Priorities_Lists pl
				ON plsl.ListID = pl.ID
			INNER JOIN Priorities_ListItems pli
				ON pli.ListID = pl.ID
			INNER JOIN QCheck_ActiveChecklists ac
				ON pli.ActiveChecklistID = ac.[ID]
		WHERE 
			plsl.SetID = @PriorityListSetID

	SELECT @PriorityListSetName = [Name]
	FROM Priorities_ListSets
	WHERE [ID] = @PriorityListSetID

	insert into @tasks (
		ID ,
		DueTime,
		ReminderDate,
		InstanceID ,
		assignees ,
		controllers,
		tasktype ,
		taskdescription ,
		nativetype ,
		tasktypeorder ,
		priority ,
		prioritychanged ,
		duedatechanged ,
		newtask ,
		CompletedDate ,
		Archived,
		IsDeleted,
		IsPriority,
		IsDaily
	)
		SELECT distinct
			ac.ID, 
			ac.DueTime,
			CASE WHEN CONVERT(VARCHAR(10), ac.ReminderDate, 101) <> CONVERT(VARCHAR(10), ac.DueTime, 101) 
				THEN ac.ReminderDate 
				ELSE NULL END,
			ac.InstanceID,
			isnull(al.assignees, ''),
			isnull(dbo.QCheck_ManagersList(c.[id]), ''),
			--dbo.QCheck_FullAssigneesList(ac.instanceid),
			tt.ID,
			tt.Description,
			tt.NativeType,
			tt.DisplayOrder,
			actt.Priority,
			0 as PriorityChanged,
			0 as DueDateChanged,
			CASE WHEN actt.CreateDt > @deletedDate THEN 1 ELSE 0 END as NewTask,
			CompletedDate, 
			0,
			c.IsDeleted,
			CASE WHEN p.InstanceID IS NULL THEN 0 ELSE 1 END AS IsPriority,
			CASE WHEN (freqType = 2 AND freqRecurrance = 1) OR (freqType = 3 AND freqRecurrance = 1 AND (freqInterval & 62) = 62) THEN 1 ELSE 0 END as IsDaily
		FROM
			QStatus_ActiveChecklistTaskType actt
			INNER JOIN QStatus_TaskTypes	tt
				ON actt.TaskType = tt.ID
				AND
					tt.IsDeleted = 0
			INNER JOIN QCheck_ActiveChecklists ac
				ON ac.ID = actt.ActiveChecklistID
			INNER JOIN qcheck_checklistinstances ci
				ON ci.ID = ac.InstanceID
			INNER JOIN qcheck_checklists c
				ON ci.ChecklistID = c.ID
			INNER JOIN QCheck_Assignments a
				ON a.instanceID = ci.ID
				AND (
					a.GroupID = @AssignedTo 
					or @AssignedTo = -1
				)
				AND a.IsDeleted = 0
			left outer join qcheck_assigneelookup al
				on al.instanceid = ac.instanceid
			left outer join QCheck_Schedule s 
				ON ci.ScheduleID = s.ID 
			left outer join @Priorities p
				ON ac.InstanceID = p.InstanceID			
		WHERE
			tt.ReportID = @ReportID
			AND (
				@DueFilter is null 
				OR ac.DueTime < @DueFilter
				OR isnull(ac.ReminderDate, ac.DueTime) < @DueFilter
				OR ac.ID in (
					SELECT ForeignKeyID 
					FROM @ForeignKeyIDs
				)
			)

	insert into @tasks (
		ID ,
		DueTime,
		ReminderDate,
		InstanceID ,
		assignees ,
		controllers,
		tasktype ,
		taskdescription ,
		nativetype ,
		tasktypeorder ,
		priority ,
		prioritychanged ,
		duedatechanged ,
		newtask ,
		CompletedDate ,
		Archived ,
		IsPriority,
		IsDaily
	)
		SELECT distinct 
			ac.ID, 
			ac.DueTime,
			CASE WHEN CONVERT(VARCHAR(10), ac.ReminderDate, 101) <> CONVERT(VARCHAR(10), ac.DueTime, 101) 
				THEN ac.ReminderDate 
				ELSE NULL END,
			ac.InstanceID, 
			isnull(al.assignees, ''),
			isnull(dbo.QCheck_ManagersList(ISNULL(cia.ChecklistID, ci.ChecklistID)), ''),
			--dbo.QCheck_FullAssigneesList(ac.instanceid),
			tt.ID,
			tt.Description,
			tt.NativeType,
			tt.DisplayOrder,
			actt.Priority,
			0 as PriorityChanged,
			0 as DueDateChanged,
			CASE WHEN actt.CreateDt > @deletedDate THEN 1 ELSE 0 END as NewTask,
			CompletedDate, 
			1,
			0,
			0
		FROM
			QStatus_ActiveChecklistTaskType actt
			INNER JOIN QStatus_TaskTypes	tt
				ON actt.TaskType = tt.ID
				AND tt.IsDeleted = 0
			INNER JOIN QCheck_ActiveChecklistArchive ac
				ON ac.ID = actt.ActiveChecklistID
				AND ac.archivedate > @deleteddate 
				AND @deleteddate is not null
			INNER JOIN QCheck_ActiveAssignmentArchive aa
				ON aa.ActiveChecklistID = ac.ID
			LEFT OUTER JOIN QCheck_ChecklistInstanceArchive cia
				ON ac.InstanceID = cia.[ID]
			-- 2/26/2013 dalvarado - found cases where the instance wasn't archived with the active checklist, so need to look
			-- in both checklistinstances and checklistinstancearchive.
			left outer join qcheck_checklistinstances ci
				ON ac.InstanceID = ci.ID
			left outer join qcheck_assigneelookup al
				on al.instanceid = ac.instanceid
		WHERE
			tt.ReportID = @ReportID
			AND (
				@DueFilter is null 
				OR ac.DueTime < @DueFilter 
				OR isnull(ac.ReminderDate, ac.DueTime) < @DueFilter 
				OR ac.ID in (
					SELECT ForeignKeyID 
					FROM @ForeignKeyIDs
				)
			)
			AND (
				@AssignedTo = -1
				OR aa.AssignmentsID in (
					SELECT ID 
					FROM QCheck_Assignments
					WHERE 
						GroupID = @AssignedTo 
						and isdeleted = 0
				)
				OR aa.AssignmentsID in (
					SELECT ID 
					FROM QCheck_AssignmentArchive
					WHERE 
						GroupID = @AssignedTo 
						and isdeleted = 0
				)
			)

	update 
		@tasks
	set 
		DueDateChanged = 1
	from 
		@tasks t
		inner join QStatus_DueDateChanges ddc
			on ddc.ActiveChecklistID =t.ID
			AND ddc.UpdateDt > @deletedDate
	
	update 
		@tasks
	set 
		PriorityChanged = 1
	from 
		@tasks t
		inner join QStatus_PriorityChanges pc
			on pc.ActiveChecklistID =t.ID
			AND pc.UpdateDt > @deletedDate

	-- 02/23/2011 dalvarado
	IF @PriorityListSetID <> -1 BEGIN

		UPDATE 
			@tasks
		SET 
			TaskType = -1000,
			TaskDescription = 'Top Priorities' + ISNULL(' - ' + @PriorityListSetName, ''),
			TaskTypeOrder = 10,
			Priority = p.Priority
		FROM 
			@tasks t
			inner join @priorities p
				on t.InstanceID = p.InstanceID

	END

	insert into @instances

		SELECT distinct
			ci.ID,
			ci.ChecklistID,
			CASE 
				WHEN s.freqType > 1 THEN 1 
				ELSE 0 
			END as isRecurring
		FROM 
			QCheck_ChecklistInstances ci
			INNER JOIN @tasks t
				ON t.InstanceID = ci.ID
			LEFT OUTER JOIN QCheck_Schedule s 
				ON ci.ScheduleID = s.ID 
		WHERE
			ci.IsDeleted = 0 
			OR @deleteddate is not null

		UNION ALL

		SELECT distinct
			ci.ID,
			ci.ChecklistID,
			CASE 
				WHEN s.freqType > 1 THEN 1 
				ELSE 0 
			END as isRecurring
		FROM 
			QCheck_ChecklistInstanceArchive ci
			INNER JOIN @tasks t
				ON t.InstanceID = ci.ID
			LEFT OUTER JOIN QCheck_Schedule s 
				ON ci.ScheduleID = s.ID 
		WHERE
			(
				ci.IsDeleted = 0 
				OR @deleteddate is not null
			)
			AND ci.archivedate > @deleteddate 
			AND @deleteddate is not null
	

	insert into @checklists

		SELECT DISTINCT
			c.ID,
			c.Name,
			CASE 
				WHEN tnc.ChecklistID IS NULL THEN 0 
				ELSE 1 
			END as TaskNameChanged
		FROM 
			QCheck_Checklists c
			INNER JOIN @instances ci
				ON c.ID = ci.ChecklistID
			LEFT OUTER JOIN QStatus_TaskNameChanges tnc
				ON tnc.ChecklistID = c.ID
				AND tnc.UpdateDt > @deletedDate
		WHERE
			c.IsDeleted = 0 
			OR @deleteddate is not null

		UNION ALL

		SELECT DISTINCT
			c.ID,
			c.Name,
			CASE 
				WHEN tnc.ChecklistID IS NULL THEN 0 
				ELSE 1 
			END as TaskNameChanged
		FROM 
			QCheck_ChecklistArchive c
			INNER JOIN @instances ci
				ON c.ID = ci.ChecklistID
			LEFT OUTER JOIN QStatus_TaskNameChanges tnc
				ON tnc.ChecklistID = c.ID
				AND tnc.UpdateDt > @deletedDate
		WHERE
			(
				c.IsDeleted = 0 
				OR @deleteddate is not null
			)
			AND c.archivedate > @deleteddate 
			AND @deleteddate is not null

	DELETE FROM @instances where checklistid not in (select id from @checklists)
	DELETE FROM @tasks where instanceid not in (select id from @instances)

	update @tasks
	set 
		description = c.description,
		tasknamechanged = c.tasknamechanged,
		isRecurring = i.isRecurring
	from 
		@tasks t
		inner join @instances i
			on i.id = t.instanceid
		inner join @checklists c
			on c.id = i.checklistid

	INSERT INTO QStatus_TempTasks (
		ID, 
		keyID, 
		specialTask
	)
		SELECT 
			@Seed, 
			id, 
			0
		FROM 
			@Tasks
	
	INSERT INTO QStatus_TempTasks (
		ID, 
		keyID, 
		specialTask
	)
		SELECT 
			@Seed, 
			-1 * st.id, 
			1
		FROM
			QStatus_SpecialTasks st
			INNER JOIN QStatus_TaskTypes tt
				ON st.TaskType = tt.ID
				AND tt.IsDeleted = 0
				AND tt.ReportID = @ReportID
				AND st.IsDeleted = 0

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ID FROM @checklists

	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	--START HEADER
	SELECT
		null as ID, 
		dbo.QStatus_GetUserNames(r.ID) + 
			r.Name + ' - Status Report - '
			+ CASE 
				WHEN r.LastReportDate = 0 THEN 
					'No Status'
				ELSE 
					ISNULL(datename(dw, r.LastReportDate) + ' ', '') 
					+ ISNULL(CONVERT(varchar, r.LastReportDate, 101) + ' ', '') 
					+ ltrim(isnull(right(convert(varchar, r.LastReportDate, 100), 7), ''))
			END as Description,
		@LastReadDate as DueDate,
		@LastReadDate AS ReminderDate,
		@LastReadDate AS SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Header Row' as Type,
		-1 As NativeType,
		null as IsDeleted,
		1 As ReturnOrder,
		'0' as TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		QStatus_Report r
	WHERE
		r.ID = @ReportID
	--END OF HEADER
	
	UNION ALL

	SELECT DISTINCT
		null as ID, 
		null as Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		-1,
		null as IsDeleted,
		2 As ReturnOrder, 
		'0' As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as isDaily

	UNION ALL

	-- SECTION HEADS
	SELECT DISTINCT
		CASE WHEN t.CompletedDate IS Not Null then Null ELSE t.TaskType END AS ID, 
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType +' - '+ taskdescription ELSE taskdescription END AS Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeorder * 1000 * 2 + 1000 Else t.tasktypeorder * 1000 * 2 END As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(t.tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		@tasks t
			
	UNION ALL

	--START SECTION HEADINGS
	SELECT DISTINCT
		null as ID, 
		null as Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Headings Row' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeorder * 1000 * 2 + 1000 Else t.tasktypeorder * 1000 * 2 END + 1 As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(t.tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		@tasks t
		
	UNION ALL

	--START SECTION ENDERS
	SELECT DISTINCT
		null as ID, 
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType else t.taskdescription end as Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END + 999 As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		@tasks t
		
	UNION ALL
	
	--START SECTION
	SELECT 
		DISTINCT
		t.ID, 
		t.description + 
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				' (DELETED)'
			ELSE
				''
			END
		ELSE
			''
		END as Description,
		Convert(varchar, t.DueTime, 120) as DueDate,
		Convert(varchar, t.ReminderDate, 120) as ReminderDate,
		Convert(varchar, ISNULL(t.ReminderDate, t.DueTime), 120) as SortDate,
		t.Priority,
		CAST(t.ID as varchar) As Comments,
		0 as UpdatedDate,
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType else t.taskDescription end As Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else
			CASE WHEN t.archived = 1 THEN
				3
			ELSE
				t.NativeType
			END
		END as NativeType,
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				1
			ELSE
				IsDeleted
			END
		ELSE
			IsDeleted
		END as IsDeleted,
		--0 as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END + 100 + t.Priority As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		PriorityChanged,
		DueDateChanged,
		TaskNameChanged,
		NewTask,
		Assignees as AssignedTo,
		Controllers,
		t.isRecurring as isRecurring,
		t.IsDaily as isDaily
	FROM
		@tasks t
		
	UNION ALL

	SELECT 
		DISTINCT
		t.ID, 
		t.description + 
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				' (DELETED)'
			ELSE
				''
			END
		ELSE
			''
		END as Description,
		Convert(varchar, t.DueTime, 120) as DueDate,
		Convert(varchar, t.ReminderDate, 120) as ReminderDate,
		Convert(varchar, ISNULL(t.ReminderDate, t.DueTime), 120) as SortDate,
		t.Priority,
		CAST(t.ID as varchar) As Comments,
		0 as UpdatedDate,
		'Comments' As Type,
		999 as NativeType,
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				1
			ELSE
				IsDeleted
			END
		ELSE
			IsDeleted
		END as IsDeleted,
		--0 as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END + 100 + t.Priority As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		PriorityChanged,
		DueDateChanged,
		TaskNameChanged,
		NewTask,
		Assignees as AssignedTo,
		Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		@tasks t
		
	UNION ALL
 
	-- SECTION HEADS SPECIAL (General Comments, etc)
	SELECT DISTINCT
		null as ID, 
		tt.Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		tt.NativeType ,
		null as IsDeleted,
		tt.DisplayOrder * 1000 * 2 As ReturnOrder,
		CAST(tt.ID As varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		QStatus_SpecialTasks st
		INNER JOIN QStatus_TaskTypes	tt
			ON st.TaskType = tt.ID
			AND tt.IsDeleted = 0
			AND tt.ReportID = @ReportID
			AND st.IsDeleted = 0
	--END SECTION HEADS SPECIAL 

	UNION ALL

	-- SECTION ENDERS SPECIAL (General Comments, etc)
	SELECT DISTINCT
		null as ID, 
		tt.Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		tt.NativeType ,
		null as IsDeleted,
		tt.DisplayOrder * 1000 * 2 + 999 As ReturnOrder,
		CAST(tt.ID AS varchar) AS TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring, 
		null as IsDaily
	FROM
		QStatus_SpecialTasks st
		INNER JOIN QStatus_TaskTypes	tt
			ON st.TaskType = tt.ID
			AND tt.IsDeleted = 0
			AND tt.ReportID = @ReportID
			AND st.IsDeleted = 0
	--END SECTION ENDERS SPECIAL 
	
	UNION ALL

	-- SECTION SPECIAL (General Comments, etc)
	SELECT DISTINCT
		st.ID * -1 as ID, -- negative for special sections
		tt.Description,
		0 as DueDate,
		0 as ReminderDate,
		0 as SortDate,
		st.Priority as Priority,
		CAST((st.ID * -1) as varchar) As Comments,
		0 as UpdatedDate,
		tt.Description as Type,
		tt.NativeType ,
		0 as IsDeleted,
		tt.DisplayOrder * 1000 * 2 + 100 + st.Priority As ReturnOrder,
		CAST(tt.ID AS varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
		--0 As ShowSupervisor
	FROM
		QStatus_SpecialTasks st
		INNER JOIN QStatus_TaskTypes	tt
			ON st.TaskType = tt.ID
			AND tt.IsDeleted = 0
			AND tt.ReportID = @ReportID
			AND st.IsDeleted = 0
	--END SECTION SPECIAL 
	
	ORDER BY 
		ReturnOrder,
		SortDate asc,
		ReminderDate asc, 
		DueDate asc, 
		description, 
		NativeType asc

	SELECT 
		IsConfidential 
	FROM
		QStatus_Report
	WHERE
		ID = @ReportID

	SELECT @Seed
	SET NOCOUNT OFF
END
GO

ALTER  FUNCTION [dbo].[QCheck_ScheduleString] (
	
	@ScheduleID INT
) RETURNS VARCHAR(500) AS

BEGIN

	DECLARE @out VARCHAR(500)
	
	SELECT @out =
		CASE
			WHEN FreqType = 1 THEN 'One Time'
			ELSE
				CASE
					WHEN FreqType = 2 THEN 'Every ' + CONVERT(VARCHAR(5), FreqRecurrance) + ' day(s)'
					WHEN FreqType = 3 THEN 'Every ' + CONVERT(VARCHAR(5), FreqRecurrance) + ' week(s) on ' + dbo.QCheck_WeeklyIntervalString(FreqInterval)
					WHEN FreqType = 4 THEN 
						CASE
							WHEN FreqRecurrance = 3 THEN 'Quarterly'
							ELSE 'Every ' + CONVERT(VARCHAR(5), FreqRecurrance) + ' month(s)'
						END
					WHEN FreqType = 5 THEN 'Yearly in ' + dbo.QCheck_YearlyIntervalString(FreqInterval)
				END
		END +
		CASE
			WHEN LastDueDate IS NULL THEN CASE WHEN FreqType <> 1 THEN ' starting' ELSE '' END + ' on ' + CONVERT(VARCHAR(10), FirstDueDate, 101) 
			ELSE ' from ' + CONVERT(VARCHAR(10), FirstDueDate, 101) + ' to ' + CONVERT(VARCHAR(10), LastDueDate, 101)
		END +
		' at ' + dbo.FloatToTime(DueTime) + ' (' + ISNULL(TimeZone, 'UTC') + ')' + 
		CASE
			WHEN BusDayBehavior = 0 AND FreqType <> 1 THEN ', due weekends/holidays'
			WHEN BusDayBehavior = 1 AND FreqType <> 1 THEN ', skip weekends/holidays'
			WHEN BusDayBehavior = 2 AND FreqType <> 1 THEN ', prev bus. day for weekends/holidays'
			WHEN BusDayBehavior = 3 AND FreqType <> 1 THEN ', next bus. day for weekends/holidays'
			ELSE ''
		END +
		CASE
			WHEN ISNULL(SoftDueOffsetDays, 0) > 0 THEN ', soft due ' + CONVERT(VARCHAR(5), SoftDueOffsetDays) + ' days before deadline'
			ELSE ''
		END
	FROM 
		QCheck_Schedule
	WHERE
		[ID] = @ScheduleID
	
	RETURN @out

END
GO

ALTER  FUNCTION [dbo].[QCheck_Approval_ScheduleString] (
	@ChangeID INT,
	@ScheduleID INT, 
	@InstanceID INT = NULL
) RETURNS VARCHAR(500) AS
BEGIN

	DECLARE @out VARCHAR(500)
	
	SELECT @out =
		CASE
			WHEN FreqType = 1 THEN 'One Time'
			ELSE
				CASE
					WHEN FreqType = 2 THEN 'Every ' + CONVERT(VARCHAR(5), FreqRecurrance) + ' day(s)'
					WHEN FreqType = 3 THEN 'Every ' + CONVERT(VARCHAR(5), FreqRecurrance) + ' week(s) on ' + dbo.QCheck_WeeklyIntervalString(FreqInterval)
					WHEN FreqType = 4 THEN 
						CASE
							WHEN FreqRecurrance = 3 THEN 'Quarterly'
							ELSE 'Every ' + CONVERT(VARCHAR(5), FreqRecurrance) + ' month(s)'
						END
					WHEN FreqType = 5 THEN 'Yearly in ' + dbo.QCheck_YearlyIntervalString(FreqInterval)
				END
		END +
		CASE
			WHEN LastDueDate IS NULL THEN CASE WHEN FreqType <> 1 THEN ' starting' ELSE '' END + ' on ' + CONVERT(VARCHAR(10), FirstDueDate, 101) 
			ELSE ' from ' + CONVERT(VARCHAR(10), FirstDueDate, 101) + ' to ' + CONVERT(VARCHAR(10), LastDueDate, 101)
		END +
		' at ' + dbo.FloatToTime(DueTime) + ' (' + ISNULL(s.TimeZone,'UTC') + ')' + 
		CASE
			WHEN BusDayBehavior = 0 AND FreqType <> 1 THEN ', due weekends/holidays'
			WHEN BusDayBehavior = 1 AND FreqType <> 1 THEN ', skip weekends/holidays'
			WHEN BusDayBehavior = 2 AND FreqType <> 1 THEN ', prev bus. day for weekends/holidays'
			WHEN BusDayBehavior = 3 AND FreqType <> 1 THEN ', next bus. day for weekends/holidays'
			ELSE ''
		END +
		CASE
			WHEN ISNULL(SoftDueOffsetDays, 0) > 0 THEN ', soft due ' + CONVERT(VARCHAR(5), SoftDueOffsetDays) + ' days before deadline'
			ELSE ''
		END
	FROM 
		QCheck_Approval_Schedule s
	WHERE
		ChangeRequestID = @ChangeID
		AND ScheduleID = @ScheduleID
		AND (InstanceID = @InstanceID OR @InstanceID IS NULL OR @ScheduleID <> -1)
	RETURN @out

END
GO


ALTER PROCEDURE [dbo].[QCheck_CreateInstance](
	@ID INT = NULL OUTPUT,
	@ChecklistID INT,
	@Name VARCHAR(500) = '',
	@CreatedBy INT,
	@ChangeID INT = -1,
	@TimeZone varchar(255) = NULL
) AS
BEGIN
	SET NOCOUNT ON
	DECLARE @ScheduleID INT
	--DECLARE @TimeZone varchar(255)

	SELECT @TimeZone = COALESCE(@TimeZone, TimeZoneOverride, LastTimeZone) FROM QCheck_Users where ID = @CreatedBy

	BEGIN TRAN
	
	--simple insert
	INSERT INTO QCheck_ChecklistInstances (
		[Name], 
		ChecklistID, 
		CreatedBy
	) VALUES (
		@Name, 
		@ChecklistID, 
		@CreatedBy
	)

	SET @ID = SCOPE_IDENTITY()
	-- If this is a requested change, we need to mark the "live" instance as deleted and
	-- put an instance into the Approval table.  Also need to create a schedule for the
	-- new instance.
	IF @ChangeID <> -1 BEGIN
		UPDATE QCheck_ChecklistInstances
		SET IsDeleted = 1
		WHERE [ID] = @ID

		INSERT INTO QCheck_Schedule (
			firstDueDate,
			lastDueDate,
			freqType,
			freqInterval,
			freqRecurrance,
			dueTime,
			busDayBehavior,
			TimeZone
		) VALUES (
			dbo.ConvertTimeFromUtc(DATEADD(DAY, 1, GETUTCDATE()), @TimeZone),
			NULL,
			1,
			NULL,
			NULL,
			19.0,
			0,
			@TimeZone
		)

		SELECT @ScheduleID = SCOPE_IDENTITY()
		
		UPDATE QCheck_ChecklistInstances 
		SET ScheduleID = @ScheduleID
		WHERE [ID] = @ID
		
		INSERT INTO QCheck_Approval_ChecklistInstances (
			ChangeRequestID,
			InstanceID,
			[Name],
			ChecklistID,
			ScheduleID,
			IsDeleted,
			CreatedBy
		)
			SELECT
				@ChangeID,
				@ID,
				[Name],
				ChecklistID,
				ScheduleID,
				0,
				CreatedBy
			FROM
				QCheck_ChecklistInstances
			WHERE
				[ID] = @ID
		
		INSERT INTO QCheck_Approval_Schedule (
			ChangeRequestID,
			ScheduleID,
			FirstDueDate,
			LastDueDate,
			FreqType,
			FreqInterval,
			FreqRecurrance,
			DueTime,
			BusDayBehavior,
			TimeZone
		)
			SELECT
				@ChangeID,
				@ScheduleID,
				FirstDueDate,
				LastDueDate,
				FreqType,
				FreqInterval,
				FreqRecurrance,
				DueTime,
				BusDayBehavior,
				TimeZone
			FROM
				QCheck_Schedule
			WHERE
				[ID] = @ScheduleID
	END
	COMMIT TRAN
	SET NOCOUNT OFF
END
GO


ALTER PROCEDURE [dbo].[QCheck_UpdateSchedule_Part1](
      @InstanceID INT,
      @firstDueDate datetime,
      @lastDueDate datetime = null,
      @freqType int,
      @freqInterval int = null,
      @freqRecurrance int = null,
      @dueTime float = null,	  
      @busDayBehavior int = 0,
      @PrevFreqType int = 0 output,
      @RowsUpdated int = 0 output,
      @Activate bit = 1,
      @SoftDueOffsetDays int = null,
      @BusDayValue int = null,
	  @TimeZone varchar(255) = null
) AS

BEGIN

      SET NOCOUNT ON

	  --if no timezone default to the creator
	  if @timezone is null
	  begin
			declare @CreatedBy int = 0

			select @CreatedBy = CreatedBy from qcheck_checklistinstances
			where id = @InstanceID

			SELECT @TimeZone = COALESCE(TimeZoneOverride, LastTimeZone) FROM QCheck_Users where ID = @CreatedBy
	  end

	  --if no duetime passed in, get the default
	  IF @dueTime is NULL
	  BEGIN
			DECLARE @UserID int

			SELECT @UserID = CreatedBy
			FROM qcheck_checklistinstances ci
			INNER JOIN qcheck_checklists c
				ON ci.ChecklistID = c.id

			SELECT @DueTime = duetime from QCheck_UserDefaultTimes
			WHERE UserID = @UserID

			IF @DueTime is null 
			BEGIN
				SELECT @DueTime = duetime from QCheck_UserDefaultTimes
				WHERE UserID = -1
			END
	  END

      set @firstDueDate = convert(varchar, @firstDueDate, 101)
      
      if @freqtype = 1 set @lastDueDate = null
      
      DECLARE @ScheduleID int
      
      -- make sure we dont already have a schedule

      SELECT @ScheduleID = ScheduleID 
      FROM QCheck_ChecklistInstances
      WHERE [ID] = @InstanceID
      
      If @ScheduleID is null
      BEGIN
      
            INSERT INTO QCheck_Schedule (
                  firstDueDate,
                  lastDueDate,
                  freqType,
                  freqInterval,
                  freqRecurrance,
                  dueTime,
                  busDayBehavior,
                  SoftDueOffsetDays,
                  busDayValue,
				  TimeZone
            ) VALUES (
                  @firstDueDate,
                  @lastDueDate,
                  @freqType,
                  @freqInterval,
                  @freqRecurrance,
                  @dueTime,
                  @busDayBehavior,
                  @SoftDueOffsetDays,
                  @BusDayValue,
				  @TimeZone
            )
      
			SET @RowsUpdated = @@ROWCOUNT
            SET @ScheduleID = SCOPE_IDENTITY()            

            -- update instances with the schedule we just inserted
            UPDATE QCheck_ChecklistInstances
            SET ScheduleID = @ScheduleID
            WHERE [ID] = @InstanceID

      END

      ELSE

      BEGIN

            -- otherwise just update
            SELECT 
                  @PrevFreqType = FreqType
            FROM
                  QCheck_Schedule
            WHERE
                  [ID] = @ScheduleID

            UPDATE QCheck_Schedule
            SET 
                  firstduedate = @firstduedate,
                  lastduedate = @lastduedate,
                  freqType = @freqType,
                  freqInterval = @freqInterval,
                  freqRecurrance = @freqRecurrance,
                  dueTime = @dueTime,
                  busDayBehavior = @busDayBehavior,
                  SoftDueOffsetDays = ISNULL(@SoftDueOffsetDays, SoftDueOffsetDays),
                  busDayValue = @BusDayValue,
				  TimeZone = @TimeZone
            WHERE 
                  [ID] = @ScheduleID
                  AND (
                        firstduedate <> @firstduedate 
                        OR isnull(lastduedate, getdate()) <> isnull(@lastduedate, getdate()) 
                        OR freqType <> @freqType 
                        OR isNull(freqInterval,0) <> isNull(@freqInterval,0) 
                        OR isNull(freqRecurrance,0) <> isNull(@freqRecurrance,0) 
                        OR dueTime <> @dueTime 
                        OR busDayBehavior <> @busDayBehavior
                        OR SoftDueOffsetDays <> ISNULL(@SoftDueOffsetDays, SoftDueOffsetDays)
                        OR busDayValue <> ISNULL(@busDayValue, busDayValue)
                        OR ISNULL(TimeZone, '(NONE)') <> COALESCE(@TimeZone, TimeZone, '(NONE)')
					)
            
            SET @RowsUpdated = @@ROWCOUNT

      END

      --EXEC QCheck_SetUpcomingInstance @InstanceID, @ScheduleID
      if @Activate = 1 exec QCheck_ActivateSchedule @InstanceID, @PrevFreqType


      SET NOCOUNT OFF
END
GO

ALTER TRIGGER [dbo].[tr_QCheck_Approval_Schedule_INSERT]
ON [dbo].[QCheck_Approval_Schedule]
INSTEAD OF INSERT AS

BEGIN

	DECLARE @CRItemID INT,
		@ID INT,
		@ChangeID INT,
		@i INT,
		@count INT

	DECLARE @Inserted TABLE (
		Seq INT IDENTITY(1,1),
		ChangeRequestID int,
		ScheduleID int,
		firstDueDate datetime,
		lastDueDate datetime,
		freqType int,
		freqInterval int,
		freqRecurrance int,
		dueTime float,
		busDayBehavior int,
		SoftDueOffsetDays int,
		CRItemID int,
		busDayValue int,
		InstanceID int,
		TimeZone varchar(255)
	)

	INSERT INTO @Inserted (
		ChangeRequestID,
		ScheduleID,
		firstDueDate,
		lastDueDate,
		freqType,
		freqInterval,
		freqRecurrance,
		dueTime,
		busDayBehavior,
		SoftDueOffsetDays,
		CRItemID,
		busDayValue,
		InstanceID,
		TimeZone
	)
		SELECT 
			ChangeRequestID,
			ScheduleID,
			firstDueDate,
			lastDueDate,
			freqType,
			freqInterval,
			freqRecurrance,
			dueTime,
			busDayBehavior,
			SoftDueOffsetDays,
			CRItemID,
			busDayValue,
			InstanceID,
			TimeZone
		FROM 
			INSERTED

	SELECT @count = MAX(seq) FROM @Inserted
	SET @i = 1
	WHILE @i <= @count BEGIN

		SELECT @ChangeID = ChangeRequestID FROM @Inserted WHERE Seq = @i
		EXEC QCheck_Approval_NewChangeRequestItem @ChangeID, @CRItemID OUTPUT
		UPDATE @Inserted SET CRItemID = @CRItemID WHERE Seq = @i
		SET @i = @i + 1

	END

	INSERT INTO QCheck_Approval_Schedule
		SELECT 
			ChangeRequestID,
			ScheduleID,
			firstDueDate,
			lastDueDate,
			freqType,
			freqInterval,
			freqRecurrance,
			dueTime,
			busDayBehavior,
			SoftDueOffsetDays,
			CRItemID,
			busDayValue,
			InstanceID,
			TimeZone
		FROM 
			@Inserted

END
GO


ALTER  PROCEDURE [dbo].[QCheck_Approval_Schedule_UPDATE] (
	@InstanceID INT,
	@FirstDueDate DATETIME,
	@LastDueDate DATETIME = NULL,
	@FreqType INT,
	@FreqInterval INT = NULL,
	@FreqRecurrance INT = NULL,
	@DueTime FLOAT,
	@TimeZone varchar(255),
	@BusDayBehavior INT = 0,
	@SoftDueOffsetDays INT = 0,
	@ChangeID INT = NULL
) AS

BEGIN
	UPDATE
		QCheck_Approval_Schedule
	SET
		FirstDueDate = @FirstDueDate,
		LastDueDate = @LastDueDate,
		FreqType = @FreqType,
		FreqInterval = @FreqInterval,
		FreqRecurrance = @FreqRecurrance,
		DueTime = @DueTime,
		TimeZone = @TimeZone,
		BusDayBehavior = @BusDayBehavior,
		SoftDueOffsetDays = @SoftDueOffsetDays
	FROM
		QCheck_Approval_Schedule S
		INNER JOIN QCheck_ChecklistInstances CI
			ON S.ScheduleID = CI.ScheduleID
	WHERE
		CI.[ID] = @InstanceID
		
	IF @@rowcount = 0
	BEGIN
		UPDATE QCheck_Approval_Schedule
		SET
		FirstDueDate = @FirstDueDate,
		LastDueDate = @LastDueDate,
		FreqType = @FreqType,
		FreqInterval = @FreqInterval,
		FreqRecurrance = @FreqRecurrance,
		DueTime = @DueTime,
		TimeZone = @TimeZone,
		BusDayBehavior = @BusDayBehavior,
		SoftDueOffsetDays = @SoftDueOffsetDays
		WHERE ChangeRequestID = @ChangeID
			AND InstanceID = @InstanceID
		
		IF @@rowcount = 0
		BEGIN
			INSERT INTO QCheck_Approval_Schedule (
				ChangeRequestID, 
				scheduleID, 
				firstduedate, 
				lastduedate, 
				freqtype, 
				freqinterval, 
				freqrecurrance, 
				duetime, 
				TimeZone, 
				busdaybehavior, 
				softdueoffsetdays, 
				instanceID
			)
			SELECT 
				@ChangeID, 
				-1, 
				@FirstDueDate, 
				@LastDueDate, 
				@FreqType, 
				@FreqInterval, 
				@FreqRecurrance, 
				@DueTime, 
				@TimeZone,
				@BusDayBehavior, 
				@SoftDueOffsetDays, 
				@InstanceID
		END
	END

END
GO


ALTER PROCEDURE [dbo].[QCheck_Approval_CopyInstance] (
	@ChangeID INT,
	@InstanceID INT
) AS
BEGIN
	
	DECLARE @NewInstanceID INT
	DECLARE @ScheduleID INT
	DECLARE @NewScheduleID INT
	DECLARE @NowDate DATETIME
	DECLARE @ChecklistID INT
	DECLARE @FreqType INT
	
	SELECT @NowDate = GetDate()

	-- Get the checklist and schedule from the current instance
	SELECT 
		@ScheduleID = ScheduleID, 
		@ChecklistID = ChecklistID
	FROM 
		QCheck_ChecklistInstances
	WHERE
		[ID] = @InstanceID

	-- Create a new schedule
	INSERT INTO QCheck_Schedule (
		firstDueDate, 
		lastDueDate, 
		freqType, 
		freqInterval, 
		freqRecurrance, 
		dueTime, 
		busDayBehavior,
		SoftDueOffsetDays,
		TimeZone
	)
	SELECT 
		firstDueDate, 
		lastDueDate, 
		freqType, 
		freqInterval, 
		freqRecurrance, 
		dueTime, 
		busDayBehavior,
		SoftDueOffsetDays,
		TimeZone
	FROM 
		QCheck_Schedule
	WHERE
		ID = @ScheduleID

	SELECT @NewScheduleID = SCOPE_IDENTITY()

	-- Create the new instance linked to the new schedule
	INSERT INTO QCheck_ChecklistInstances (
		[Name], 
		ChecklistID, 
		ScheduleID, 
		IsDeleted, 
		CreatedBy
	)
	SELECT 
		[Name], 
		@ChecklistID, 
		@NewScheduleID,  
		1, 
		CreatedBy
	FROM 
		QCheck_ChecklistInstances
	WHERE
		[ID] = @InstanceID
		AND IsDeleted = 0

	SELECT @NewInstanceID = SCOPE_IDENTITY()

	-- Create the approval instance linked to the new schedule
	INSERT INTO QCheck_Approval_ChecklistInstances (
		ChangeRequestID,
		InstanceID,
		[Name], 
		ChecklistID, 
		ScheduleID, 
		IsDeleted, 
		CreatedBy
	)
	SELECT 
		@ChangeID,
		@NewInstanceID,
		[Name], 
		@ChecklistID, 
		@NewScheduleID,  
		0, 
		CreatedBy
	FROM 
		QCheck_ChecklistInstances
	WHERE
		[ID] = @InstanceID
		AND IsDeleted = 0

	-- Create the approval schedule
	INSERT INTO QCheck_Approval_Schedule (
		ChangeRequestID,
		ScheduleID,
		FirstDueDate,
		LastDueDate,
		FreqType,
		FreqInterval,
		FreqRecurrance,
		DueTime,
		BusDayBehavior,
		SoftDueOffsetDays,
		TimeZone
	)
	SELECT
		@ChangeID,
		@NewScheduleID,
		FirstDueDate,
		LastDueDate,
		FreqType,
		FreqInterval,
		FreqRecurrance,
		DueTime,
		BusDayBehavior,
		SoftDueOffsetDays,
		TimeZone
	FROM
		QCheck_Schedule
	WHERE
		[ID] = @NewScheduleID

	-- Copy the assignments
	INSERT INTO QCheck_Approval_Assignments (
		ChangeRequestID,
		AssignmentID,
		InstanceID, 
		GroupID, 
		IsDeleted
	)
	SELECT 
		@ChangeID,
		-1,
		@NewInstanceID, 
		GroupID, 
		0
	FROM 
		QCheck_Assignments
	WHERE
		InstanceID = @InstanceID
		AND IsDeleted = 0

	-- Copy to any status reports
	INSERT INTO QStatus_InstanceTaskType (
		InstanceID, 
		TaskType
	)
	SELECT 
		@NewInstanceID, 
		TaskType
	FROM 
		QStatus_InstanceTaskType
	WHERE 
		InstanceID = @InstanceID
	

	-- Copy alerts
	INSERT INTO QCheck_Approval_Alerts (
		ChangeRequestID,
		AlertID,
		InstanceID, 
		DaysBefore, 
		AlertTime, 
		AlertType, 
		AlertText, 
		SentTime, 
		IsDeleted, 
		AlerteeGroupID
	)
	SELECT 
		@ChangeID,
		-1,
		@NewInstanceID, 
		DaysBefore, 
		AlertTime, 
		AlertType, 
		AlertText, 
		Null, 
		0, 
		AlerteeGroupID
	FROM 
		QCheck_Alerts
	WHERE
		InstanceID = @InstanceID
		AND IsDeleted = 0
	
END
GO


ALTER   PROCEDURE [dbo].[QCheck_Approval_ApplyChange] (
	@ChangeID INT
) AS
BEGIN

	BEGIN TRAN

	DECLARE 
		@UserID INT,
		@InstanceID INT,
		@GroupID INT,
		@ID INT,
		@FirstDueDate DATETIME,
		@LastDueDate DATETIME,
		@FreqType INT,
		@FreqInterval INT,
		@FreqRecurrance INT,
		@DueTime FLOAT,
		@BusDayBehavior INT,
		@PrevFreqType INT,
		@RowsUpdated INT,
		@Activate BIT,
		@SoftDueOffsetDays INT,
		@TimeZone VARCHAR(255),
		@ApproverUserName VARCHAR(100)
	
	SELECT @UserID = cr.RequestingUser, @ApproverUserName = isnull(u.shortname, '')
	FROM QCheck_Approval_ChangeRequests cr
		LEFT OUTER JOIN QCheck_Users u
			on u.id = cr.ApprovedUser
	WHERE cr.[ID] = @ChangeID

	-- ============================================================================
	-- Active Checklists
	DECLARE @ActiveChecklistID int
	SELECT @ActiveChecklistID = c.ID
	FROM 	
		QCheck_Approval_ActiveChecklists R
		INNER JOIN QCheck_ActiveChecklists C
			ON R.ActiveChecklistID = C.[ID]
 		INNER JOIN QCheck_Approval_ChangeRequestItems cri
	 		ON R.CRItemID = cri.[ID]
	WHERE	
		R.ChangeRequestID = @ChangeID
		AND cri.Approved = 1
		AND CONVERT(VARCHAR(10), C.DueTime, 101) <> CONVERT(VARCHAR(10), R.DueTime, 101)

	-- Needed for grading--this logs due date changes
	INSERT INTO QStatus_DueDateChanges (
		ActiveChecklistID, 
		DueDateOld, 
		UpdateDT,
		changedBy
	)
		SELECT
			C.ID,
			C.DueTime,
			GETDATE(),
			@ApproverUserName
		FROM 	
			QCheck_Approval_ActiveChecklists R
			INNER JOIN QCheck_ActiveChecklists C
				ON R.ActiveChecklistID = C.[ID]
 			INNER JOIN QCheck_Approval_ChangeRequestItems cri
	 			ON R.CRItemID = cri.[ID]
		WHERE	
			R.ChangeRequestID = @ChangeID
			AND cri.Approved = 1
			AND CONVERT(VARCHAR(10), C.DueTime, 101) <> CONVERT(VARCHAR(10), R.DueTime, 101)
	
	UPDATE 	
		QCheck_ActiveChecklists
	SET	
		DueTime =case when Getdate()>R.DueTime 
		         then dateadd(hour, datepart(hour,R.DueTime), dbo.Util_addofficedays(getdate(), 1)) 
				 else R.DueTime 
				 End
	FROM 	
		QCheck_Approval_ActiveChecklists R
		INNER JOIN QCheck_ActiveChecklists C
			ON R.ActiveChecklistID = C.[ID]
 		INNER JOIN QCheck_Approval_ChangeRequestItems cri
 			ON R.CRItemID = cri.[ID]
	WHERE	
		R.ChangeRequestID = @ChangeID
		AND cri.Approved = 1

	IF @ActiveChecklistID in (select sourceactivechecklist from QCheck_LinkedDeadlines where isdeleted = 0)
	begin
		exec [dbo].[QCheck_LinkedDeadlines_Process] @ActiveChecklistID, 'CHANGE'
	end
	
	INSERT INTO QCheck_ActiveChecklists (
		InstanceID,
		DueTime,
		OrigDueTime,
		ReminderDate,
		CompletedDate,
		HasNaggedDue,
		CompletedBy
	)
		SELECT
			InstanceID,
			DueTime,
			OrigDueTime,
			ReminderDate,
			CompletedDate,
			HasNaggedDue,
			CompletedBy
		FROM
			QCheck_Approval_ActiveChecklists R
			INNER JOIN QCheck_Approval_ChangeRequestItems cri
				ON R.CRItemID = cri.[ID]
		WHERE
			R.ChangeRequestID = @ChangeID
			AND R.ActiveChecklistID = -1
			AND cri.Approved = 1
		
	
	-- ============================================================================
	-- Alerts
	
	UPDATE 	
		QCheck_Alerts
	SET	
		InstanceID = R.InstanceID,
		DaysBefore = R.DaysBefore,
		AlertTime = R.AlertTime,
		AlertType = R.AlertType,
		AlertText = R.AlertText,
		SentTime = R.SentTime,
		IsDeleted = R.IsDeleted,
		AlerteeGroupID = R.AlerteeGroupID
	FROM	
		QCheck_Approval_Alerts R
		INNER JOIN QCheck_Alerts C
			ON R.AlertID = C.[ID]
		INNER JOIN QCheck_Approval_ChangeRequestItems cri
			ON R.CRItemID = cri.[ID]
	WHERE	
		R.ChangeRequestID = @ChangeID
		AND cri.Approved = 1
	
	INSERT INTO QCheck_Alerts (
		InstanceID,
		DaysBefore,
		AlertTime,
		AlertType,
		AlertText,
		SentTime,		
		IsDeleted,
		AlerteeGroupID
	)
		SELECT
			InstanceID,
			DaysBefore,
			AlertTime,
			AlertType,
			AlertText,
			SentTime,
			IsDeleted,
			AlerteeGroupID
		FROM
			QCheck_Approval_Alerts R
			INNER JOIN QCheck_Approval_ChangeRequestItems cri
				ON R.CRItemID = cri.[ID]
		WHERE
			R.ChangeRequestID = @ChangeID
			AND AlertID = -1
			AND cri.Approved = 1
	
	-- ============================================================================
	-- Asignments
	
	-- Deletes
	DECLARE cAssignD CURSOR FOR 
		SELECT 
			C.[ID]
		FROM
			QCheck_Assignments C
			INNER JOIN QCheck_Approval_Assignments R
				ON C.[ID] = R.AssignmentID
			INNER JOIN QCheck_Approval_ChangeRequestItems cri
				ON R.CRItemID = cri.[ID]
		WHERE
			R.ChangeRequestID = @ChangeID
			AND C.IsDeleted = 0
			AND R.IsDeleted = 1
			AND cri.Approved = 1
	OPEN cAssignD
	FETCH NEXT FROM cAssignD INTO @ID
	WHILE @@FETCH_STATUS = 0 BEGIN
		EXEC QCheck_DeleteAssignedTo @ID
		FETCH NEXT FROM cAssignD INTO @ID
	END
	CLOSE cAssignD
	DEALLOCATE cAssignD
	

	-- New Assignments	
	DECLARE cAssign CURSOR FOR 
		SELECT
			InstanceID,
			GroupID
		FROM
			QCheck_Approval_Assignments R
			INNER JOIN QCheck_Approval_ChangeRequestItems cri
				ON R.CRItemID = cri.[ID]
		WHERE
			R.ChangeRequestID = @ChangeID
			AND AssignmentID = -1
			AND cri.Approved = 1
	OPEN cAssign
	FETCH NEXT FROM cAssign INTO @InstanceID, @GroupID
	WHILE @@FETCH_STATUS = 0 BEGIN
		EXEC QCheck_AddAssignedTo @InstanceID, @GroupID, @UserID
		FETCH NEXT FROM cAssign INTO @InstanceID, @GroupID
	END
	CLOSE cAssign
	DEALLOCATE cAssign
	
	-- ============================================================================
	-- Checklist Instances
	
	UPDATE 
		QCheck_ChecklistInstances
	SET
		[Name] = R.[Name],
		ChecklistID = R.ChecklistID,
		ScheduleID = R.ScheduleID,
		IsDeleted = R.IsDeleted,
		CreatedBy = R.CreatedBy
	FROM
		QCheck_ChecklistInstances C
		INNER JOIN QCheck_Approval_ChecklistInstances R
			ON C.[ID] = R.InstanceID
		INNER JOIN QCheck_Approval_ChangeRequestItems cri
			ON R.CRItemID = cri.[ID]
	WHERE
		R.ChangeRequestID = @ChangeID
		AND cri.Approved = 1
	
	INSERT INTO QCheck_ChecklistInstances (
		[Name],
		ChecklistID,
		ScheduleID,
		IsDeleted,
		CreatedBy
	)
		SELECT
			[Name],
			ChecklistID,
			ScheduleID,
			IsDeleted,
			CreatedBy
		FROM
			QCheck_Approval_ChecklistInstances R
			INNER JOIN QCheck_Approval_ChangeRequestItems cri
				ON R.CRItemID = cri.[ID]
		WHERE
			R.ChangeRequestID = @ChangeID
			AND InstanceID = -1
			AND cri.Approved = 1
	
	-- ============================================================================
	-- Checklist Managers
	
	UPDATE 
		QCheck_ChecklistManagers
	SET
		ManagerGroupID = R.ManagerGroupID,
		ChecklistID = R.ChecklistID,
		IsDeleted = R.IsDeleted
	FROM
		QCheck_ChecklistManagers C
		INNER JOIN QCheck_Approval_ChecklistManagers R
			ON C.[ID] = R.ChecklistManagerID
		INNER JOIN QCheck_Approval_ChangeRequestItems cri
			ON R.CRItemID = cri.[ID]
	WHERE
		R.ChangeRequestID = @ChangeID
		AND cri.Approved = 1
	
	INSERT INTO QCheck_ChecklistManagers (
		ManagerGroupID,
		ChecklistID,
		IsDeleted
	)
		SELECT
			ManagerGroupID,
			ChecklistID,
			IsDeleted
		FROM
			QCheck_Approval_ChecklistManagers R
			INNER JOIN QCheck_Approval_ChangeRequestItems cri
				ON R.CRItemID = cri.[ID]
		WHERE
			R.ChangeRequestID = @ChangeID
			AND ChecklistManagerID = -1
			AND cri.Approved = 1
	
	-- ============================================================================
	-- Checklists
	
	UPDATE
		QCheck_Checklists
	SET
		[Name] = R.[Name],
		IsDeleted = R.IsDeleted,
		Owner = R.Owner,
		Template = R.Template
	FROM
		QCheck_Checklists C
		INNER JOIN QCheck_Approval_Checklists R
			ON C.[ID] = R.ChecklistID
		INNER JOIN QCheck_Approval_ChangeRequestItems cri
			ON R.CRItemID = cri.[ID]
	WHERE
		R.ChangeRequestID = @ChangeID
		AND cri.Approved = 1
	
	INSERT INTO QCheck_Checklists (
		[Name],
		IsDeleted,
		Owner,
		Template
	)
		SELECT
			[Name],
			IsDeleted,
			Owner,
			Template
		FROM
			QCheck_Approval_Checklists R
			INNER JOIN QCheck_Approval_ChangeRequestItems cri
				ON R.CRItemID = cri.[ID]
		WHERE
			R.ChangeRequestID = @ChangeID
			AND ChecklistID = -1
			AND cri.Approved = 1
	
	
	-- ============================================================================
	-- Items
	
	UPDATE 
		QCheck_Items
	SET
		ChecklistID = R.ChecklistID,
		SequenceNum = R.SequenceNum,
		ItemTypeID = R.ItemTypeID,
		[Text] = R.[Text],
		URL = R.URL,
		IsDeleted = R.IsDeleted
	FROM
		QCheck_Items C
		INNER JOIN QCheck_Approval_Items R
			ON C.[ID] = R.ItemID
		INNER JOIN QCheck_Approval_ChangeRequestItems cri
			ON R.CRItemID = cri.[ID]
	WHERE
		R.ChangeRequestID = @ChangeID
		AND cri.Approved = 1
	
	INSERT INTO QCheck_Items (
		ChecklistID,
		SequenceNum,	
		ItemTypeID,
		[Text],
		URL,
		IsDeleted
	)
		SELECT
			ChecklistID,
			SequenceNum,	
			ItemTypeID,
			[Text],
			URL,
			IsDeleted
		FROM
			QCheck_Approval_Items R
			INNER JOIN QCheck_Approval_ChangeRequestItems cri
				ON R.CRItemID = cri.[ID]
		WHERE
			R.ChangeRequestID = @ChangeID
			AND ItemID = -1
			AND cri.Approved = 1
	
	
	-- ============================================================================
	-- Schedule
	DECLARE cSch CURSOR FOR 
		SELECT 
			CI.[ID] AS InstanceID,
			S.FirstDueDate,
			S.LastDueDate,
			S.FreqType,
			S.FreqInterval,
			S.FreqRecurrance,
			S.DueTime,
			S.TimeZone,
			S.BusDayBehavior,
			S.SoftDueOffsetDays
		FROM 
			QCheck_ChecklistInstances CI
			INNER JOIN QCheck_Approval_Schedule S
				ON (
						CI.ScheduleID = S.ScheduleID OR 
						(
							S.ScheduleID = -1
							AND S.InstanceID = CI.ID
						)
					)
			INNER JOIN QCheck_Approval_ChangeRequestItems cri
				ON S.CRItemID = cri.[ID]
		WHERE
			S.ChangeRequestID = @ChangeID
			AND cri.Approved = 1
	OPEN cSch
	FETCH NEXT FROM cSch INTO 
		@InstanceID, @FirstDueDate, @LastDueDate, @FreqType, @FreqInterval, 
		@FreqRecurrance, @DueTime, @TimeZone, @BusDayBehavior, @SoftDueOffsetDays
	WHILE @@FETCH_STATUS = 0 BEGIN
		EXEC QCheck_UpdateSchedule_Part1 
			@InstanceID = @InstanceID, 
			@FirstDueDate = @FirstDueDate, 
			@LastDueDate = @LastDueDate, 
			@FreqType = @FreqType, 
			@FreqInterval = @FreqInterval, 
			@FreqRecurrance = @FreqRecurrance, 
			@DueTime = @DueTime, 
			@BusDayBehavior = @BusDayBehavior, 
			@PrevFreqType = @PrevFreqType OUTPUT, 
			@RowsUpdated = @RowsUpdated OUTPUT, 
			@Activate = 1, 
			@SoftDueOffsetDays = @SoftDueOffsetDays,
			@TimeZone = @TimeZone
		IF @RowsUpdated > 0 BEGIN
			EXEC QCheck_UpdateSchedule_Part2 
				@InstanceID = @InstanceID, 
				@PrevFreqType = @PrevFreqType, 
				@Activate = 1
		END
		FETCH NEXT FROM cSch INTO 
			@InstanceID, @FirstDueDate, @LastDueDate, @FreqType, @FreqInterval, 
			@FreqRecurrance, @DueTime, @TimeZone, @BusDayBehavior, @SoftDueOffsetDays
	END
	CLOSE cSch
	DEALLOCATE cSch
	
	-- ============================================================================
	-- Mark any affected status reports as dirty
	UPDATE
		QStatus_Report
	SET
		IsDirty = 1
	FROM 
		QStatus_Report r
		INNER JOIN QStatus_TaskTypes tt
			ON r.ID = tt.ReportID
		INNER JOIN QStatus_ActiveChecklistTaskType actt
			ON tt.ID = actt.TaskType
		INNER JOIN QCheck_ActiveChecklists_All  ac
			ON ac.ID = actt.ActiveChecklistID
		INNER JOIN QCheck_ChecklistInstances_All ci
			ON ci.ID = ac.InstanceID
	WHERE
		ci.ChecklistID = dbo.QCheck_Approval_CRChecklistID(@ChangeID)
	
	

	COMMIT TRAN

END
GO


ALTER PROCEDURE [dbo].[QCheck_Archive]
	@DeleteCompletedChecklists bit = 1
AS
BEGIN

	SET NOCOUNT ON
	
	SET DEADLOCK_PRIORITY 10

	DECLARE @maintainDays int
	SET @maintainDays = 7

	IF @DeleteCompletedChecklists = 1
		--inserts on completeddate
		INSERT INTO QCheck_ActiveChecklistArchive
			SELECT a.*, getDate() FROM QCheck_ActiveChecklists a
			LEFT OUTER JOIN QCheck_ActiveChecklistArchive b
				ON a.[ID] = b.[ID]
			WHERE a.CompletedDate < getDate() - @maintainDays
			AND b.[ID] IS NULL
			AND a.DueTime < GETDATE()
	
	INSERT INTO QCheck_ActiveChecklistArchive
		SELECT a.*, getDate() FROM QCheck_ActiveChecklists a
		LEFT OUTER JOIN QCheck_ActiveChecklistArchive b
			ON a.[ID] = b.[ID]
		LEFT OUTER JOIN QCheck_Assignments c
			ON a.InstanceID = c.InstanceID
		WHERE 
		b.[ID] IS NULL
		AND c.[ID] IS NULL
		AND a.DueTime < GETDATE()

	INSERT INTO QCheck_ActiveChecklistArchive
		SELECT a.*, getDate() FROM QCheck_ActiveChecklists a
		LEFT OUTER JOIN QCheck_ActiveChecklistArchive b
			ON a.[ID] = b.[ID]
		LEFT OUTER JOIN QCheck_ActiveAssignments c
			ON a.ID = c.ActiveChecklistID
		WHERE 
		b.[ID] IS NULL
		AND c.[ID] IS NULL
		AND a.DueTime < GETDATE()


	INSERT INTO QCheck_ActiveChecklistArchive
		SELECT a.*, getDate() FROM QCheck_ActiveChecklists a
		LEFT OUTER JOIN QCheck_ActiveChecklistArchive b
			ON a.[ID] = b.[ID]
		LEFT OUTER JOIN QCheck_ChecklistInstances c
			ON a.InstanceID = c.ID
		WHERE 
		b.[ID] IS NULL
		AND c.[ID] IS NULL
		AND a.DueTime < GETDATE()

	UPDATE QCheck_Checklists
		SET IsDeleted = 1
		WHERE Template = 0
		AND --not active
			ID not in 
				(SELECT ci.ChecklistID
				FROM QCheck_ActiveChecklists ac
				INNER JOIN QCheck_ChecklistInstances ci
				ON ac.InstanceID = ci.ID)
		AND --end date in the past
			(
				ID in
				(
					select c.id
					from qcheck_checklists c
					inner join qcheck_checklistinstances ci
					on ci.checklistid = c.id
					inner join qcheck_schedule s
					on s.id = ci.scheduleid
					group by c.id
					having  max(
							CASE WHEN freqType = 1 then isnull(firstduedate, getdate() + 1)
							ELSE isnull(lastduedate, getdate() + 1)
							END
							) 
						 < getdate()
				
				)
				OR
				-- or no schedule
				ID in
				(
					select c.id
					from qcheck_checklists c
					left outer join qcheck_checklistinstances ci
					on ci.checklistid = c.id
					and ci.isdeleted = 0
					left outer join qcheck_schedule s
					on s.id = ci.scheduleid
					group by c.id, c.name
					having count(s.id) = 0
			
				)
			
			)
		AND --nothing completed in the last month
			ID not in
				(
					SELECT ci.ChecklistID
					FROM QCheck_ActiveChecklistArchive ac
					INNER JOIN QCheck_ChecklistInstances ci
					ON ac.InstanceID = ci.ID
					WHERE completedDate > DateAdd(month, -1, getdate())
				
				)
			and isdeleted = 0


	--inserts on isdeleted
	INSERT INTO QCheck_ChecklistArchive
		SELECT a.*, getDate() FROM QCheck_Checklists a
		LEFT OUTER JOIN QCheck_ChecklistArchive b
			ON a.[ID] = b.[ID]
		WHERE a.IsDeleted = 1
		AND b.[ID] IS NULL

	--inserts on isdeleted or checklist has been archived
	INSERT INTO QCheck_ChecklistInstanceArchive
		SELECT a.*, getDate() FROM QCheck_ChecklistInstances a
		LEFT OUTER JOIN QCheck_ChecklistInstanceArchive b
			ON a.[ID] = b.[ID]
		LEFT OUTER JOIN QCheck_ChecklistArchive c
			ON a.ChecklistID = c.[ID]
		LEFT OUTER JOIN QCheck_Checklists c2
			ON a.ChecklistID = c2.[ID]
		WHERE (a.IsDeleted = 1 or c.[ID] IS NOT NULL OR c2.ID is null)
		AND b.[ID] IS NULL

	--inserts if instance has been archived
	INSERT INTO QCheck_ActiveChecklistArchive
		SELECT a.*, getDate() FROM QCheck_ActiveChecklists a
		LEFT OUTER JOIN QCheck_ActiveChecklistArchive b
			ON a.[ID] = b.[ID]
		LEFT OUTER JOIN QCheck_ChecklistInstanceArchive c
			ON a.InstanceID = c.[ID]
		WHERE (c.[ID] IS NOT NULL)
		AND b.[ID] IS NULL
		AND a.DueTime < GETDATE()


	--inserts on isdeleted or instance is archived
	INSERT INTO QCheck_AssignmentArchive
		SELECT a.*, getDate() FROM QCheck_Assignments a
		LEFT OUTER JOIN QCheck_AssignmentArchive b
			ON a.[ID] = b.[ID]
		LEFT OUTER JOIN QCheck_ChecklistInstanceArchive d
			ON a.InstanceID = d.[ID]
		WHERE 
			(a.IsDeleted = 1 or d.[ID] IS NOT NULL)
		AND b.[ID] IS NULL
		AND a.ID not in (
			select ReplacingID from QCheck_AssignmentsTemporary where TempAssignmentEnd > (getdate() - @maintainDays)
		)

	--inserts on isdeleted or checklists is archived
	INSERT INTO QCheck_ItemArchive
		SELECT a.*, getDate() FROM QCheck_Items a
		LEFT OUTER JOIN QCheck_ItemArchive b
			ON a.[ID] = b.[ID]
		LEFT OUTER JOIN QCheck_ChecklistArchive c
			ON a.ChecklistID = c.[ID]
		WHERE (a.IsDeleted = 1 or c.[ID] IS NOT NULL)
		AND b.[ID] IS NULL

	--inserts on isdeleted or instance is archived
	INSERT INTO QCheck_ScheduleArchive
		SELECT a.[ID]
		  ,a.[firstDueDate]
		  ,a.[lastDueDate]
		  ,a.[freqType]
		  ,a.[freqInterval]
		  ,a.[freqRecurrance]
		  ,a.[dueTime]
		  ,a.[busDayBehavior]
		  ,a.[SoftDueOffsetDays]
		  ,a.[busDayValue]
		  ,getDate()
		  ,a.[TimeZone] 
		FROM QCheck_Schedule a
		LEFT OUTER JOIN QCheck_ScheduleArchive b
			ON a.[ID] = b.[ID]
		INNER JOIN QCheck_ChecklistInstanceArchive c	
			ON a.[ID] = c.ScheduleID
		WHERE b.[ID] IS NULL


	--inserts on activechecklist archived or assignment archived
	INSERT INTO QCheck_ActiveAssignmentArchive
		SELECT a.*, getDate() FROM QCheck_ActiveAssignments a
		LEFT OUTER JOIN QCheck_ActiveAssignmentArchive b
			ON a.[ID] = b.[ID]
		LEFT OUTER JOIN QCheck_ActiveChecklistArchive c	
			ON a.ActiveChecklistID = c.[ID]
		LEFT OUTER JOIN QCheck_AssignmentArchive d	
			ON a.AssignmentsID = d.[ID]
		WHERE 
		(c.[ID] IS NOT NULL or d.[ID] IS NOT NULL)
		AND b.[ID] IS NULL

	--inserts on activechecklist archived or item archived
	INSERT INTO QCheck_ActiveItemArchive
		SELECT a.*, getDate() FROM QCheck_ActiveItems a
		LEFT OUTER JOIN QCheck_ActiveItemArchive b
			ON a.[ID] = b.[ID]
		LEFT OUTER JOIN QCheck_ActiveChecklistArchive c	
			ON a.ActiveChecklistID = c.[ID]
		LEFT OUTER JOIN QCheck_ItemArchive d	
			ON a.ChecklistItemID = d.[ID]
		WHERE 
		(c.[ID] IS NOT NULL or d.[ID] IS NOT NULL)
		AND b.[ID] IS NULL

	--inserts on isdeleted or instance archived
	INSERT INTO QCheck_AlertArchive
		SELECT a.*, getDate() FROM QCheck_Alerts a
		LEFT OUTER JOIN QCheck_AlertArchive b
			ON a.[ID] = b.[ID]
		LEFT OUTER JOIN QCheck_ChecklistInstanceArchive c	
			ON a.InstanceID = c.[ID]
		WHERE 
		(a.IsDeleted = 1 OR c.[ID] IS NOT NULL)
		AND b.[ID] IS NULL

	--inserts on activechecklist archived or alert archived
	INSERT INTO QCheck_ActiveAlertArchive
		SELECT a.*, getDate() FROM QCheck_ActiveAlerts a
		LEFT OUTER JOIN QCheck_ActiveAlertArchive b
			ON a.[ID] = b.[ID]
		LEFT OUTER JOIN QCheck_ActiveChecklistArchive c	
			ON a.ActiveChecklistID = c.[ID]
		LEFT OUTER JOIN QCheck_AlertArchive d	
			ON a.AlertID = d.[ID]
		WHERE 
		(c.[ID] IS NOT NULL or d.[ID] IS NOT NULL)
		AND b.[ID] IS NULL

	DELETE FROM QCheck_ActiveAssignments
		FROM QCheck_ActiveAssignmentArchive
		WHERE QCheck_ActiveAssignments.[ID] = QCheck_ActiveAssignmentArchive.[ID]

	DELETE FROM QCheck_ActiveChecklists
		FROM QCheck_ActiveChecklistArchive
		WHERE QCheck_ActiveChecklists.[ID] = QCheck_ActiveChecklistArchive.[ID]

	DELETE FROM QCheck_ActiveItems
		FROM QCheck_ActiveItemArchive
		WHERE QCheck_ActiveItems.[ID] = QCheck_ActiveItemArchive.[ID]

	DELETE FROM QCheck_Assignments
		FROM QCheck_AssignmentArchive
		WHERE QCheck_Assignments.[ID] = QCheck_AssignmentArchive.[ID]

	DELETE FROM QCheck_Checklists
		FROM QCheck_ChecklistArchive
		WHERE QCheck_Checklists.[ID] = QCheck_ChecklistArchive.[ID]

	DELETE FROM QCheck_ChecklistInstances
		FROM QCheck_ChecklistInstanceArchive
		WHERE QCheck_ChecklistInstances.[ID] = QCheck_ChecklistInstanceArchive.[ID]

	DELETE FROM QCheck_Items
		FROM QCheck_ItemArchive
		WHERE QCheck_Items.[ID] = QCheck_ItemArchive.[ID]

	DELETE FROM QCheck_Schedule
		FROM QCheck_ScheduleArchive
		WHERE QCheck_Schedule.[ID] = QCheck_ScheduleArchive.[ID]

	DELETE FROM QCheck_Alerts
		FROM QCheck_AlertArchive
		WHERE QCheck_Alerts.[ID] = QCheck_AlertArchive.[ID]


	DELETE FROM QCheck_ActiveAlerts
		FROM QCheck_ActiveAlertArchive
		WHERE QCheck_ActiveAlerts.[ID] = QCheck_ActiveAlertArchive.[ID]




	insert into QStatus_ActiveChecklistTaskTypeArchive
		(activechecklistid, tasktype, priority, createdt)
	SELECT actt.* FROM
		qstatus_activechecklisttasktype actt
	inner join 
		qcheck_activechecklistarchive ac
	on
		ac.id = actt.activechecklistid
	and
		ac.completeddate < getdate() - 100

	delete from qstatus_activechecklisttasktype
		where activechecklistid in
			(select activechecklistid from 
			qstatus_activechecklisttasktypearchive)





	insert into qstatus_commentarchive
	(id, foreignkeyid, comments, displayorder,
	tabin, commentdt, initials, userid, replyid, specialtask, asofdate)
	select distinct c.*, getdate() from qstatus_comments c
	inner join 
	(select distinct c.id from qstatus_comments c
	where specialtask = 0
	and foreignkeyid not in
	(select id from
	qcheck_activechecklists)
	) c2
	on c.id = c2.id

	delete from qstatus_comments 
	where id in
	(select id from qstatus_commentarchive)


	exec JB_Tasks_Archive_Full_Populate


	truncate table qstatus_commentedreporttasks
	insert into qstatus_commentedreporttasks
		SELECT actt.activechecklistid, tt.reportID
			FROM QStatus_ActiveChecklistTaskType actt
			inner join qstatus_tasktypes tt
			on tt.id = actt.tasktype
			inner join qstatus_comments c
			on c.foreignkeyid = actt.activechecklistid
			WHERE 
			c.specialtask = 0

	SET NOCOUNT OFF

END
GO

ALTER  PROCEDURE [dbo].[QCheck_RestoreInstance](
	@InstanceID int
) AS

BEGIN

	SET NOCOUNT ON
	

	IF @instanceID is not null
	BEGIN
		--restore instance
		set identity_insert qcheck_checklistinstances on
		insert into qcheck_checklistinstances 
			(id, name, checklistID, scheduleid, isdeleted, createdby)
		select id, name, checklistID, scheduleid, 0, createdby
		from qcheck_checklistinstancearchive
		where id = @instanceID
		set identity_insert qcheck_checklistinstances off

		delete from qcheck_checklistinstancearchive
		where id = @instanceID

		--restore alerts
		set identity_insert qcheck_alerts on
		insert into qcheck_alerts
			(id, instanceid, daysbefore, alerttime, alerttext, 
			alerttype, senttime, isdeleted, alerteeGroupID)
		select id, instanceid, daysbefore, alerttime, alerttext, 
			alerttype, senttime, isdeleted, alerteeGroupID
		from qcheck_alertarchive
		where instanceid = @instanceID and isdeleted = 0
		set identity_insert qcheck_alerts off

		delete from qcheck_alertarchive
		where instanceid = @instanceID and isdeleted = 0

		--restore assignments
		set identity_insert qcheck_assignments on
		insert into qcheck_assignments
			(id, instanceid, groupid, isdeleted)
		select 
			id, instanceid, groupid, isdeleted
		from 
		 	qcheck_assignmentarchive
		where instanceid = @instanceID and isdeleted = 0
		set identity_insert qcheck_assignments off

		delete from qcheck_assignmentarchive
		where instanceid = @instanceID and isdeleted = 0

		DECLARE @ScheduleID int
		SELECT @ScheduleID = ScheduleID 
		FROM qcheck_checklistinstances
		WHERE ID = @InstanceID
		
		IF @ScheduleID is not null
		BEGIN
			set identity_insert qcheck_schedule on
			insert into qcheck_schedule
				(id, firstduedate,lastduedate, freqtype,
				freqinterval, freqrecurrance, duetime,
				busdaybehavior, softdueoffsetdays, TimeZone)
			select 
				id, firstduedate, lastduedate, freqtype,
				freqinterval, freqrecurrance, duetime,
				busdaybehavior, softdueoffsetdays, TimeZone
			from 
			 	qcheck_schedulearchive
			where id = @ScheduleID
			set identity_insert qcheck_schedule off

			delete from qcheck_schedulearchive
			where  id = @ScheduleID

		END
	
		DECLARE @ChecklistID int
		SELECT @ChecklistID = ChecklistID
		FROM qcheck_checklistinstances
		WHERE ID = @InstanceID

		IF @ChecklistID is not null
		BEGIN
			set identity_insert qcheck_checklists on
			insert into qcheck_checklists
				(id, name, isdeleted, owner)
			select 
				id, name, 0, owner
			from 
			 	qcheck_checklistarchive
			where id = @ChecklistID
			set identity_insert qcheck_checklists off
	
			delete from qcheck_checklistarchive
			where  id = @ChecklistID

			set identity_insert qcheck_items on
			insert into qcheck_items
				(id, checklistid, sequencenum, itemtypeid,
				text, url, isdeleted)
			select 
				id, checklistid, sequencenum, itemtypeid,
				text, url, isdeleted
			from 
			 	qcheck_itemarchive
			where checklistid = @ChecklistID and isdeleted = 0
			set identity_insert qcheck_checklists off
	
			delete from qcheck_itemarchive
			where  checklistid = @ChecklistID and isdeleted = 0

		END
		
	END
	

	SET NOCOUNT OFF

END
GO

ALTER PROCEDURE [dbo].[QStatus_MarkRead]
	@ReportID int,
	@SupervisorID int
AS
BEGIN

	UPDATE QStatus_SupervisorsLastViewed
	SET LastViewed = getUtcDate()
	WHERE
		ReportID = @ReportID
	AND
		SupervisorUserID = @SupervisorID

	IF @@Rowcount = 0

	INSERT INTO QStatus_SupervisorsLastViewed
		(LastViewed, ReportID, SupervisorUserID)
	SELECT
		getUtcDate(), @ReportID, @SupervisorID
	
END
GO

ALTER	PROCEDURE [dbo].[QStatus_GetReportTimeline]
	@ReportID int,
	@UserID int
AS
BEGIN
	SET NOCOUNT ON
	
	IF @ReportID > 0
		SELECT 
			DISTINCT 
			
			tt.Description + ' - ' +c.Name as [Description],
			Convert(varchar, ac.DueTime, 121) as DueDate,
			1 as Type,
			CASE WHEN DueTime < GetUtcDate() Then
				1
			Else
				0
			END As Overdue,
			DueTime as dt
		FROM  QStatus_Report r
		INNER JOIN Qstatus_TaskTypes tt
			ON tt.ReportID = r.ID
			AND tt.IsDeleted = 0
			AND tt.NativeType = 0
			AND r.ID = @ReportID
		INNER JOIN QStatus_ActiveChecklistTaskType actt
			ON actt.taskType = tt.ID
		INNER JOIN QCheck_ActiveChecklists ac
			ON ac.ID = actt.ActiveChecklistID
			AND ac.completedDate is null
		INNER JOIN QCheck_ChecklistInstances ci
			ON ci.ID = ac.InstanceID
			AND ci.IsDeleted = 0
		INNER JOIN QCheck_Checklists c
			ON c.ID = ci.ChecklistID 
			AND c.IsDeleted = 0
		ORDER By dt
	ELSE
		SELECT 
			DISTINCT 
			r.Name + ' : ' + 
			tt.Description + ' - ' +c.Name as [Description],
			Convert(varchar, ac.DueTime, 121) as DueDate,
			1 as Type,
			CASE WHEN DueTime < GetUtcDate() Then
				1
			Else
				0
			END As Overdue,
			DueTime as dt
		FROM QCheck_GroupMembership gm
		INNER JOIN QCheck_Groups g
			ON g.ID = gm.GroupID
			AND gm.UserID = @UserID
		INNER JOIN QStatus_GroupReport ur
			ON ur.GroupID = g.ID
		INNER JOIN QStatus_Report r
			ON (r.ID = @ReportID OR @ReportID = 0)
			AND ur.ReportID = r.ID
			AND r.IsDeleted = 0
		INNER JOIN Qstatus_TaskTypes tt
			ON tt.ReportID = r.ID
			AND tt.IsDeleted = 0
			AND tt.NativeType = 0
		INNER JOIN QStatus_ActiveChecklistTaskType actt
			ON actt.taskType = tt.ID
		INNER JOIN QCheck_ActiveChecklists ac
			ON ac.ID = actt.ActiveChecklistID
			AND ac.completedDate is null
		INNER JOIN QCheck_ChecklistInstances ci
			ON ci.ID = ac.InstanceID
			AND ci.IsDeleted = 0
		INNER JOIN QCheck_Checklists c
			ON c.ID = ci.ChecklistID 
			AND c.IsDeleted = 0
		ORDER By dt

	SET NOCOUNT OFF
END
GO

ALTER    PROCEDURE [dbo].[AirQ_GetDates]
(
	@DEAL VARCHAR(50),
	@PLANE VARCHAR(50) = NULL,
	@TYPE VARCHAR(20)
) AS
BEGIN

	DECLARE @TASKTYPE int

	SELECT @TASKTYPE = CASE @TYPE
		WHEN 'RENT' THEN 101603 
		WHEN 'MAINTENANCE' THEN 101602
		WHEN 'FINANCIAL' THEN 101604 
		WHEN 'LETTER' THEN 101605 
		WHEN 'INSURANCE' THEN 101601 
		WHEN 'WAR' THEN 101607
		WHEN 'SWAP' THEN 101610
		WHEN 'EXTENSION' THEN 101609
		WHEN 'LESSEETERM' THEN 101611
		WHEN 'LESSORTERM' THEN 101612
		WHEN 'EXPIRATION' THEN 101610
	END 

	DECLARE @NEXTDATE DATETIME

	
	SELECT 
		@NEXTDATE = MIN(DUETIME)
	FROM 
		QSTATUS_INSTANCETASKTYPE itt
	INNER JOIN
		QCHECK_CHECKLISTINSTANCES ci
	ON
		ci.ID = itt.INSTANCEID
	AND
		itt.TASKTYPE = @TASKTYPE
	INNER JOIN
		QCHECK_ACTIVECHECKLISTS ac
	ON
		ac.INSTANCEID = itt.INSTANCEID
	AND
		ac.DUETIME > GETUTCDATE()
	AND
		ac.CompletedDate IS NULL
	INNER JOIN
		QCHECK_CHECKLISTS C
	ON
		c.ID = ci.CHECKLISTID
	AND
		c.NAME LIKE '%' + @DEAL + '%'
	AND
		c.NAME LIKE '%' + @PLANE + '%'
	GROUP BY c.ID

	
	IF @NEXTDATE IS NULL BEGIN
	
		SELECT 
			@NEXTDATE = MIN(DUETIME)
		FROM 
			QSTATUS_INSTANCETASKTYPE itt
		INNER JOIN
			QCHECK_CHECKLISTINSTANCES ci
		ON
			ci.ID = itt.INSTANCEID
		AND
			itt.TASKTYPE = @TASKTYPE
		INNER JOIN
			QCHECK_UPCOMINGDUETIMES udt
		ON
			udt.INSTANCEID = itt.INSTANCEID
		INNER JOIN
			QCHECK_CHECKLISTS C
		ON
			c.ID = ci.CHECKLISTID
		AND
			c.NAME LIKE '%' + @DEAL + '%'
		AND
			c.NAME LIKE '%' + @PLANE + '%'
		GROUP BY c.ID
	
		IF @NEXTDATE IS NULL
		BEGIN

			SELECT 
				@NEXTDATE = MIN(DUETIME)
			FROM 
				QSTATUS_INSTANCETASKTYPE itt
			INNER JOIN
				QCHECK_CHECKLISTINSTANCES ci
			ON
				ci.ID = itt.INSTANCEID
			AND
				itt.TASKTYPE = @TASKTYPE
			INNER JOIN
				QCHECK_ACTIVECHECKLISTS ac
			ON
				ac.INSTANCEID = itt.INSTANCEID
			AND
				ac.DUETIME > GETUTCDATE()
			AND
				ac.CompletedDate IS NULL
			INNER JOIN
				QCHECK_CHECKLISTS C
			ON
				c.ID = ci.CHECKLISTID
			AND
				c.NAME LIKE '%' + @DEAL + '%'
			
			GROUP BY c.ID
			
		
			IF @NEXTDATE IS NULL SELECT 
				@NEXTDATE = MIN(DUETIME)
			FROM 
				QSTATUS_INSTANCETASKTYPE itt
			INNER JOIN
				QCHECK_CHECKLISTINSTANCES ci
			ON
				ci.ID = itt.INSTANCEID
			AND
				itt.TASKTYPE = @TASKTYPE
			INNER JOIN
				QCHECK_UPCOMINGDUETIMES udt
			ON
				udt.INSTANCEID = itt.INSTANCEID
			INNER JOIN
				QCHECK_CHECKLISTS C
			ON
				c.ID = ci.CHECKLISTID
			AND
				c.NAME LIKE '%' + @DEAL + '%'
			GROUP BY c.ID
		END
	END

	SELECT @NEXTDATE As NextDate

END
GO


DROP PROCEDURE [dbo].[AirQ_GetDates_bak]
GO


ALTER  PROCEDURE [dbo].[CB_QProcessComments]
	@MainID int,
	@Days int = null
AS

BEGIN

	SET ANSI_WARNINGS OFF

	SET NOCOUNT ON
	
	-- Get app configuration
	DECLARE @AppURL VARCHAR(50), @ImagesURL VARCHAR(50), @ExternalURL VARCHAR(50), @BaseDomain VARCHAR(50), @FromAddress VARCHAR(50), @AppName VARCHAR(50)		
	SELECT @AppURL = AppURL, @ImagesURL = ImagesURL, @ExternalURL = ExternalURL, @BaseDomain = BaseDomain, @FromAddress = FromAddress, @Appname = AppName FROM QCheck_AppSettings WHERE ID = 1

	DECLARE @prelimresults TABLE
	(
		ID int IDENTITY(1,1),
		ActiveChecklistID int,
		Report varchar(200),
		ReportID int,
		ChecklistName varchar(200),
		Comments varchar(7000),
		CommentDt datetime,
		DueTime datetime,
		ReplyID int,
		DisplayOrder int,
		TabIn int,
		Initials char(2),
		CommentID int
	)

	DECLARE @prelimresultscopy TABLE
	(
		ID int,
		ActiveChecklistID int,
		Report varchar(200),
		ReportID int,
		ChecklistName varchar(200),
		Comments varchar(7000),
		CommentDt datetime,
		DueTime datetime,
		ReplyID int,
		DisplayOrder int,
		TabIn int,
		Initials char(2),
		CommentID int
	)

	DECLARE @results TABLE
	(
		ID int IDENTITY(1,1),
		ActiveChecklistID int,
		Report varchar(200),
		ReportID int,
		ChecklistName varchar(200),
		Comments varchar(7000),
		CommentDt datetime,
		DueTime datetime,
		ReplyID int,
		DisplayOrder int,
		TabIn int,
		Initials char(2),
		CommentID int
	)

	DECLARE @counter int, @rowcount int, @commentcount INT

	IF @days is null or @days < 0 
		SET @days = 9999

	--pull the comments from the active tables and the archive. Set display order to 0, we'll have to recalculate that
	INSERT INTO @prelimresults
	SELECT  
		actt.activechecklistid, r.name as Report, r.id, ck.name as Checklist, 
		c.comments, c.commentdt, ac.duetime, c.replyid, 0 as displayorder, c.tabin, c.initials, c.id
	FROM 
		QStatus_ActiveChecklistTaskType actt inner join 
		qstatus_tasktypes tt on tt.id = actt.tasktype inner join 
		qstatus_comments c on c.foreignkeyid = actt.activechecklistid inner join
		qcheck_Activechecklists ac on actt.activechecklistid = ac.id inner join
		qcheck_checklistinstances ci on ac.instanceid = ci.id inner join 
		qcheck_Checklists ck on ci.checklistid = ck.id inner join
		qstatus_report r on tt.reportid = r.id inner join
		CB_Tasks cbt ON actt.ActiveChecklistID = cbt.TaskID
	WHERE
		cbt.MainID = @MainID AND
		CAST(CONVERT(varchar(10),c.CommentDt,101) AS Datetime) >= CAST(CONVERT(varchar(10),DATEADD(dd,@Days * -1,getdate()),101) AS Datetime)
		
/*
	-- 11/9/2009 dalvarado - this was copied from JB_QProcessComments but isn't needed yet
	UNION

	SELECT  
		activechecklistid, Report, id, Checklist, 
		comments, commentdt, duetime, replyid, 0 as displayorder, tabin, initials, commentID
	FROM 
		CB_Tasks_Archive_Full cbt
	WHERE
		cbt.MainID = @MainID AND
		CAST(CONVERT(varchar(10),cbt.CommentDt,101) AS Datetime) >= CAST(CONVERT(varchar(10),DATEADD(dd,@Days * -1,getdate()),101) AS Datetime)
*/
	--use a copy of the table to help performance
	insert into @prelimresultscopy 
	select * from @prelimresults

	--set the display order - this is reverse from what it is in qprocess, newer comments come first.
	--this is only the top level comments, replies come later
	--logic is to count the # of comments that are newer than said comment - this will be the order #
	UPDATE @prelimresults
	set displayorder = isnull(counts.cnt, 0) + 1
	from @prelimresults p1
	inner join
	(select p.id, count(c.ID) as cnt
	FROM @prelimresults p
	left outer join @prelimresultscopy c
	on p.activechecklistid = c.activechecklistid
	and c.CommentDt > p.CommentDt
	and c.replyid is null
	where p.replyid is null
	group by p.id) counts
	on counts.id = p1.id
 
	DECLARE REPLYCURS CURSOR
		FOR 
	SELECT ID, ReplyID, CommentDt
	FROM @prelimresults
	WHERE replyID is not null
	ORDER BY activechecklistid, tabin, commentdt desc

	DECLARE @ID int
	DECLARE @ReplyID int
	DECLARE @Display int
	DECLARE @CommentDate datetime
	
	
	OPEN REPLYCURS

	FETCH NEXT FROM REPLYCURS INTO @ID, @ReplyID, @CommentDate
	WHILE @@FETCH_STATUS = 0 BEGIN
		
		SELECT @Display = DisplayOrder
		FROM @prelimresults
		WHERE commentID = @ReplyID

		--add one for each reply thats newer than current one
		SELECT @Display = @Display + isnull(count(ID), 0)
		FROM @prelimresults
		WHERE replyID = @ReplyID
		AND commentDT > @CommentDate

		--now add one more to offset it from the previous
		SELECT @Display = @Display + 1
		
		-- move everything else up one
		UPDATE @prelimresults
		SET DisplayOrder = DisplayOrder + 1
		WHERE DisplayOrder >= @Display

		--now set the current comment's display
		UPDATE @prelimresults
		SET DisplayOrder = @Display
		WHERE ID = @ID
 

		FETCH NEXT FROM REPLYCURS INTO @ID, @ReplyID, @CommentDate
	END
	CLOSE REPLYCURS
	DEALLOCATE REPLYCURS


	--insert into the results table - this is basically just used as a cursor	
	INSERT INTO @results (activechecklistid, Report, Reportid, ChecklistName, 
		comments, commentdt, duetime, replyid, displayorder, tabin, initials, commentID)
	SELECT activechecklistid, Report, Reportid, ChecklistName, 
		comments, commentdt, duetime, replyid, displayorder, tabin, initials, commentID FROM @prelimresults
	ORDER BY duetime desc, activechecklistid, displayorder

	/*SELECT activechecklistid, Report, Reportid, ChecklistName, 
		comments, commentdt, duetime, replyid, displayorder, tabin, initials, commentID FROM @prelimresults
	ORDER BY duetime desc, activechecklistid, displayorder*/

	DECLARE @htmltable table
	(
		htmlrow varchar(8000)
	)
	
	DECLARE @html varchar(8000)

	SET @rowcount = @@ROWCOUNT
	SET @counter = 1


	IF @rowcount > 0
	BEGIN

		DECLARE @currTask varchar(200)
		SET @currTask = ''

		DECLARE @taskName varchar(200), @initials char(2), @commentDt datetime, @tabIn int, @comments varchar(7000)
		WHILE @counter <= @rowcount
		BEGIN

			SET @html = ''
	
			--grab the current row
			SELECT @taskName = ChecklistName, @initials = Initials, @commentDt = CommentDt, @tabIn = TabIn, @comments = Comments
			FROM @results
			WHERE ID = @counter

			--if its a new task, display the task name
			IF @currTask <> @taskName
			BEGIN
				IF @currTask <> '' SET @html = @html + '<br>'
				SET @currTask = @taskName
				SET @html = @html + '<strong>' + @currTask + '</strong>'
				INSERT INTO @htmltable(htmlrow) VALUES (@html)
				SET @html = ''
			END

			--now place the comment
			SET @html = @html + '<div'
			SET @html = @html + ' style="margin-left:' + cast(((@tabIn+1) * 20) as varchar) + 'px"'
			SET @html = @html + '>[' + CONVERT(varchar(10),@commentDt,101) + '] [' + @initials + '] ' + @comments + '</div>'

			SET @counter = @counter + 1

			INSERT INTO @htmltable(htmlrow) VALUES (@html)

		END

	END

	SELECT @CommentCount = COUNT(*) FROM @htmltable

	IF @CommentCount = 0 BEGIN

		INSERT INTO @htmltable (htmlrow) VALUES ('<strong>No ' + @AppName + ' comments for this bond</strong>')

	END

	INSERT INTO @htmltable (htmlrow) VALUES ('<br/><br/><b><a href="' + @AppURL + '/MyStatus.aspx?reportid=1100582">Go to ' + @AppName + '</a></b>')	

	SELECT * FROM @htmltable
	
	SET ANSI_WARNINGS ON

END
GO

ALTER   PROC [dbo].[QStatus_GetReportLatestComments]
	@UserID int,
	@ReportID int,
	@deletedDate datetime = null,
	@MoveCompleted bit = 0,
	@selectedComments varchar(1000) = null,
	@CommentsSince DATETIME = NULL,
	@IncludeAllTasks BIT = 0
/*
set @UserID = 50
set @ReportID = 1100996
set @deletedDate = null
set @MoveCompleted = 0
set @selectedComments = null
set @CommentsSince = '4/10/2016 10:00'
set @IncludeAllTasks = 1
*/
AS

BEGIN
	SET NOCOUNT ON
	
	IF @CommentsSince IS NULL SET @CommentsSince = DATEADD(HOUR, -1, GETUTCDATE())
	If @CommentsSince > GETUTCDATE() SET @CommentsSince = DATEADD(HOUR, -1, GETUTCDATE()) --time zone issue

	DECLARE @CompletedType varchar(10)
	
	SELECT @CompletedType = 'Completed'
	
	--waitfor delay '00:00:10'

	--if only specific comments were requested, parse them out into a table
	DECLARE @selectedCommentsTbl TABLE (commentID int)

	IF @selectedComments IS NOT NULL
		INSERT INTO @selectedCommentsTbl
		SELECT n from dbo.Util_fn_List_To_Table(@selectedComments,',')

	--find all the tasks
	DECLARE @ForeignKeyIDs TABLE (
		ForeignKeyID INT PRIMARY KEY,
		SpecialTask int
	)

	IF @selectedComments IS NOT NULL
	BEGIN
		INSERT INTO @ForeignKeyIDs 
			SELECT distinct 
				actt.activechecklistid, 
				specialTask 
			FROM 
				QStatus_ActiveChecklistTaskType actt
				inner join qstatus_tasktypes tt
					on tt.id = actt.tasktype
					and tt.reportID = @reportID
				inner join qstatus_comments c
					on c.foreignkeyid = actt.activechecklistid
					and c.specialtask = 0
					and c.UserID = @UserID
					AND LEN(Comments)>0 
					AND CommentDT > @CommentsSince
				INNER JOIN @selectedCommentsTbl sc 
					ON c.id = sc.commentID

		INSERT INTO @ForeignKeyIDs
			SELECT distinct 
				st.ID, 1
			FROM 
				QStatus_SpecialTasks st
				inner join qstatus_tasktypes tt
					ON tt.ID = st.TaskType
					AND tt.ReportID = @ReportID
				inner join qstatus_comments c
					on c.foreignkeyid = st.ID
					AND LEN(Comments)>0 
					AND CommentDT > @CommentsSince
					and specialtask=1
					and c.UserID = @UserID
				INNER JOIN @selectedCommentsTbl sc 
					ON c.id = sc.commentID
	END
	ELSE
	BEGIN
		INSERT INTO @ForeignKeyIDs 
			SELECT distinct 
				actt.activechecklistid, 
				ISNULL(specialTask, 0)
			FROM 
				QStatus_ActiveChecklistTaskType actt
				INNER JOIN qstatus_tasktypes tt
					ON tt.id = actt.tasktype
					AND tt.reportID = @reportID
				LEFT OUTER JOIN qstatus_comments c
					ON c.foreignkeyid = actt.activechecklistid
					AND c.specialtask = 0
			WHERE
				(c.UserID = @UserID OR @IncludeAllTasks = 1)
				AND (LEN(Comments) > 0 OR @IncludeAllTasks = 1)
				AND ISNULL(CommentDT, '12/31/2199') > @CommentsSince
				AND (c.ID IS NOT NULL OR @IncludeAllTasks = 1) --Basically want an inner join if not showing all tasks

			UNION

			-- If we're showing all tasks, make sure every task on the status report is included. The query above will only pull
			-- tasks that have active comments within the date range or don't have comments from the user at all.
			SELECT distinct 
				actt.activechecklistid,
				0
			FROM 
				QStatus_ActiveChecklistTaskType actt
				INNER JOIN qstatus_tasktypes tt
					ON tt.id = actt.tasktype
					AND tt.reportID = @reportID
			WHERE
				@IncludeAllTasks = 1 

		INSERT INTO @ForeignKeyIDs
			SELECT distinct 
				st.ID, 
				1
			FROM 
				QStatus_SpecialTasks st
				INNER JOIN qstatus_tasktypes tt
					ON tt.ID = st.TaskType
					AND tt.ReportID = @ReportID
				LEFT OUTER JOIN qstatus_comments c
					ON c.foreignkeyid = st.ID
					AND specialtask=1
			WHERE
				(LEN(Comments) > 0 OR @IncludeAllTasks = 1)
				AND ISNULL(CommentDT, '12/31/2199') > @CommentsSince
				AND (c.UserID = @UserID OR @IncludeAllTasks = 1)
				AND (c.ID IS NOT NULL OR @IncludeAllTasks = 1) --Basically want an inner join if not showing all tasks

			UNION

			SELECT distinct 
				st.ID, 
				1
			FROM 
				QStatus_SpecialTasks st
				INNER JOIN qstatus_tasktypes tt
					ON tt.ID = st.TaskType
					AND tt.ReportID = @ReportID
			WHERE
				@IncludeAllTasks = 1

	END

	DECLARE @tasks table(
		ID int PRIMARY KEY,
		DueTime datetime,
		InstanceID int,
		assignees varchar(1000),
		tasktype int,
		taskdescription varchar(1000),
		nativetype int,
		tasktypeorder int,
		priority int,
		prioritychanged bit,
		duedatechanged bit,
		newtask bit,
		CompletedDate datetime,
		Archived bit,
		description varchar(1000),
		tasknamechanged bit
	)

		
	declare @instances table(
		ID int PRIMARY KEY,
		ChecklistID int
	)
	declare @checklists table(
		ID int PRIMARY KEY,
		Description varchar(1000),
		tasknamechanged bit
	)
	
	insert into @tasks (
		ID ,
		DueTime,
		InstanceID ,
		assignees ,
		tasktype ,
		taskdescription ,
		nativetype ,
		tasktypeorder ,
		priority ,
		prioritychanged ,
		duedatechanged ,
		newtask ,
		CompletedDate ,
		Archived 
	)
		SELECT distinct
			ac.ID, 
			ac.DueTime,
			ac.InstanceID,
			isnull(REPLACE(al.assignees, '&nbsp;', ' '), ''),
			--dbo.QCheck_FullAssigneesList(ac.instanceid),
			tt.ID,
			tt.Description,
			tt.NativeType,
			tt.DisplayOrder,
			actt.Priority,
			0 as PriorityChanged,
			0 as DueDateChanged,
			CASE WHEN actt.CreateDt > @deletedDate THEN 1 ELSE 0 END as NewTask,
			CompletedDate, 
			0
		FROM
			QStatus_ActiveChecklistTaskType actt
			INNER JOIN QStatus_TaskTypes	tt
				ON actt.TaskType = tt.ID
				AND tt.IsDeleted = 0
				AND tt.ReportID = @ReportID
			INNER JOIN QCheck_ActiveChecklists ac
				ON ac.ID = actt.ActiveChecklistID
			left outer join qcheck_assigneelookup al
				on al.instanceid = ac.instanceid
			inner join @ForeignKeyIDs f
				ON f.ForeignKeyID = ac.ID
				AND f.SpecialTask = 0	

	
	insert into @tasks (
		ID ,
		DueTime,
		InstanceID ,
		assignees ,
		tasktype ,
		taskdescription ,
		nativetype ,
		tasktypeorder ,
		priority ,
		prioritychanged ,
		duedatechanged ,
		newtask ,
		CompletedDate ,
		Archived 
	)
		SELECT distinct 
			ac.ID, 
			ac.DueTime,
			ac.InstanceID, 
			isnull(REPLACE(al.assignees, '&nbsp;', ' '), ''),
			--dbo.QCheck_FullAssigneesList(ac.instanceid),
			tt.ID,
			tt.Description,
			tt.NativeType,
			tt.DisplayOrder,
			actt.Priority,
			0 as PriorityChanged,
			0 as DueDateChanged,
			CASE WHEN actt.CreateDt > @deletedDate THEN 1 ELSE 0 END as NewTask,
			CompletedDate, 
			1
		FROM
			QStatus_ActiveChecklistTaskType actt
			INNER JOIN QStatus_TaskTypes	tt
				ON actt.TaskType = tt.ID
				AND tt.ReportID = @ReportID
				AND tt.IsDeleted = 0
			INNER JOIN QCheck_ActiveChecklistArchive ac
				ON ac.ID = actt.ActiveChecklistID
				--AND ac.archivedate > @deleteddate 
				--AND @deleteddate is not null
			left outer join qcheck_assigneelookup al
				on al.instanceid = ac.instanceid
			inner join @ForeignKeyIDs f
				ON f.ForeignKeyID = ac.ID
				AND f.SpecialTask = 0	

	
	update @tasks
	set DueDateChanged = 1
	from 
		@tasks t
		inner join QStatus_DueDateChanges ddc
			on ddc.ActiveChecklistID =t.ID
			AND ddc.UpdateDt > @deletedDate

	
	update @tasks
	set PriorityChanged = 1
	from 
		@tasks t
		inner join QStatus_PriorityChanges pc
			on pc.ActiveChecklistID =t.ID
			AND pc.UpdateDt > @deletedDate
	
	insert into @instances
		SELECT distinct
			ci.ID,
			ci.ChecklistID
		FROM 
			QCheck_ChecklistInstances ci
			INNER JOIN @tasks t
			ON t.InstanceID = ci.ID
		WHERE
			ci.IsDeleted = 0 
			OR @deleteddate is not null

		UNION ALL

		SELECT distinct
			ci.ID,
			ci.ChecklistID
		FROM 
			QCheck_ChecklistInstanceArchive ci
			INNER JOIN @tasks t
			ON t.InstanceID = ci.ID
		WHERE
			(ci.IsDeleted = 0 OR @deleteddate is not null)
			AND ci.archivedate > @deleteddate 
			AND @deleteddate is not null
	
	insert into @checklists
		SELECT DISTINCT
			c.ID,
			c.Name,
			CASE WHEN tnc.ChecklistID IS NULL THEN 0 ELSE 1 END as TaskNameChanged
		FROM 
			QCheck_Checklists c
			INNER JOIN @instances ci
				ON c.ID = ci.ChecklistID
			LEFT OUTER JOIN QStatus_TaskNameChanges tnc
				ON tnc.ChecklistID = c.ID
				AND tnc.UpdateDt > @deletedDate
		WHERE
			c.IsDeleted = 0 
			OR @deleteddate is not null

		UNION ALL

		SELECT DISTINCT
			c.ID,
			c.Name,
			CASE WHEN tnc.ChecklistID IS NULL THEN 0 ELSE 1 END as TaskNameChanged
		FROM 
			QCheck_ChecklistArchive c
			INNER JOIN @instances ci
				ON c.ID = ci.ChecklistID
			LEFT OUTER JOIN QStatus_TaskNameChanges tnc
				ON tnc.ChecklistID = c.ID
				AND tnc.UpdateDt > @deletedDate
		WHERE
			(c.IsDeleted = 0 OR	@deleteddate is not null)
			AND c.archivedate > @deleteddate 
			AND @deleteddate is not null

	DELETE FROM @instances where checklistid not in (select id from @checklists)
	DELETE FROM @tasks where instanceid not in (select id from @instances)

	update @tasks
	set 
		description = c.description,
		tasknamechanged = c.tasknamechanged
	from 
		@tasks t
		inner join @instances i
			on i.id = t.instanceid
		inner join @checklists c
			on c.id = i.checklistid

	DECLARE @specialtasks table(
		ID int,
		priority int,
		tasktypeid int,
		tasktypedescription varchar(1000), 
		tasktypenativetype int,
		tasktypedisplayorder int
	)

	insert into @specialtasks
		select st.ID,
			st.priority,
			tt.id,
			tt.description,
			tt.nativetype,
			tt.displayorder
		from 
			QStatus_SpecialTasks st
			INNER JOIN QStatus_TaskTypes	tt
				ON st.TaskType = tt.ID
				AND tt.IsDeleted = 0
				AND st.IsDeleted = 0
				AND tt.ReportID = @ReportID
			INNER JOIN @ForeignKeyIDs f
				ON f.ForeignKeyID = st.ID
				AND f.SpecialTask = 1

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ID FROM @checklists

	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	--START HEADER
	SELECT
		null as ID, 
		dbo.QStatus_GetUserNames(r.ID) + r.Name + ' - Status Report - '
		+ CASE WHEN r.LastReportDate = 0 THEN
			'No Status'
		ELSE
			ISNULL(datename(dw, r.LastReportDate) + ' ', '') 
			+ ISNULL(CONVERT(varchar, r.LastReportDate, 101) + ' ', '') 
			+ ltrim(isnull(right(convert(varchar, r.LastReportDate, 100), 7), ''))
		END 
		as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Header Row' as Type,
		-1 As NativeType,
		null as IsDeleted,
		1 As ReturnOrder,
		'0' as TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		QStatus_Report r
	WHERE
		r.ID = @ReportID
	--END OF HEADER

	
	UNION ALL

	SELECT DISTINCT
		null as ID, 
		null as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		-1,
		null as IsDeleted,
		2 As ReturnOrder, 
		'0' As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo

	UNION ALL

	-- SECTION HEADS
	SELECT DISTINCT
		CASE WHEN t.CompletedDate IS Not Null then Null ELSE t.TaskType END AS ID, 
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType +' - '+ taskdescription ELSE taskdescription END AS Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeorder * 1000 * 2 + 1000 Else t.tasktypeorder * 1000 * 2 END As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(t.tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		@tasks t
		
	UNION ALL

	--START SECTION HEADINGS
	SELECT DISTINCT
		null as ID, 
		null as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Headings Row' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeorder * 1000 * 2 + 1000 Else t.tasktypeorder * 1000 * 2 END + 1 As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(t.tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		@tasks t

	UNION ALL

	--START SECTION ENDERS
	SELECT DISTINCT
		null as ID, 
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType else t.taskdescription end as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END + 999 As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		@tasks t

	--END SECTION ENDERS

	UNION ALL
	
	--START SECTION
	SELECT 
		DISTINCT
		t.ID, 
		t.description + 
		CASE WHEN t.archived = 1 THEN
			--' (DELETED)'
			''
		ELSE
			''
		END
		 as Description,
		Convert(varchar, t.DueTime, 101) as DueDate,
		t.Priority,
		CAST(t.ID as varchar) As Comments,
		0 as UpdatedDate,
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType else t.taskDescription end As Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		0 as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END + 100 + t.Priority As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		PriorityChanged,
		DueDateChanged,
		TaskNameChanged,
		NewTask,
		Assignees as AssignedTo
	FROM
		@tasks t
		
	UNION ALL

	-- SECTION HEADS SPECIAL (General Comments, etc)
	SELECT DISTINCT
		null as ID, 
		tasktypedescription as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		tasktypenativetype as NativeType ,
		null as IsDeleted,
		tasktypedisplayorder * 1000 * 2 As ReturnOrder,
		CAST(tasktypeid As varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		@specialtasks st
	--END SECTION HEADS SPECIAL 
	
	UNION ALL
	
	-- COLUMN HEADS SPECIAL (General Comments, etc)
	SELECT DISTINCT
		null as ID, 
		tasktypedescription as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Special Headings Row' as Type,
		tasktypenativetype as NativeType ,
		null as IsDeleted,
		tasktypedisplayorder * 1000 * 2 + 1 As ReturnOrder,
		CAST(tasktypeid As varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		@specialtasks st
	--END SECTION HEADS SPECIAL 

	UNION ALL

	-- SECTION ENDERS SPECIAL (General Comments, etc)
	SELECT DISTINCT
		null as ID, 
		tasktypedescription as Description,
		null as DueDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		tasktypenativetype as NativeType ,
		null as IsDeleted,
		tasktypedisplayorder * 1000 * 2 + 999 As ReturnOrder,
		CAST(tasktypeid AS varchar) AS TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		@specialtasks st
	--END SECTION ENDERS SPECIAL 
	
	
	
	UNION ALL

	-- SECTION SPECIAL (General Comments, etc)
	SELECT DISTINCT
		st.ID * -1 as ID, -- negative for special sections
		st.tasktypedescription as description,
		null as DueDate,
		st.Priority as Priority,
		CAST((st.ID * -1) as varchar) As Comments,
		0 as UpdatedDate,
		st.tasktypedescription as Type,
		st.tasktypenativetype as NativeType ,
		0 as IsDeleted,
		st.tasktypedisplayorder * 1000 * 2 + 100 + st.Priority As ReturnOrder,
		CAST(st.tasktypeid AS varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo
	FROM
		@specialtasks st
	--END SECTION SPECIAL 
	

	ORDER BY 
		ReturnOrder,
		DueDate asc, 
		description, 
		NativeType asc

	SELECT 
		IsConfidential 
	FROM
		QStatus_Report
	WHERE
		ID = @ReportID

	SET NOCOUNT OFF
END
GO

ALTER	PROCEDURE [dbo].[QStatus_UpdateTask]
	@ReportID int,
	@TaskID int,
	@UserID int,
	@Description varchar(500),
	@DueDate datetime = NULL,
	@Priority int = NULL,
	@Comments varchar(1500) = '',
	@CommentsID int = -1
AS
BEGIN

	DECLARE @PrevPriority int
	DECLARE @DueDateOld datetime,
		@NextDueDate datetime
	DECLARE @tmpstr varchar(50)
	DECLARE @tmpdt datetime
	DECLARE @CurrentDueTime datetime
	DECLARE @FreqType int
	DECLARE @SchID int
			

	declare @ChecklistID int
	SELECT @ChecklistID = ChecklistID
	FROM
		QCheck_ChecklistInstances i
	inner join
		QCheck_ActiveChecklists ac 
	on
		ac.InstanceID = i.ID
	AND
		ac.ID = @TaskID

	DECLARE @DescriptionOld varchar(100)
	SELECT @DescriptionOld = Name
	FROM QCheck_Checklists 
	WHERE [ID] = @ChecklistID

	update QCheck_Checklists 
	SET
		Name = @Description
	WHERE [ID] = @ChecklistID
	
	IF @DescriptionOld <> @Description
	BEGIN
		INSERT INTO QStatus_TaskNameChanges
		(ChecklistID, TaskOld, UpdateDT)
		VALUES
		(@ChecklistID, @DescriptionOld, GETUTCDATE())	

		DECLARE @NumItems int
		SET @NumItems = 0

		SELECT @NumItems = Count(ID)
		FROM QCheck_Items 
		WHERE ChecklistID = @ChecklistID

		IF @NumItems = 1
		BEGIN
			UPDATE QCheck_Items
			SET Text = @Description
			WHERE ChecklistID = @ChecklistID
			AND Text = @DescriptionOld
		END

	END

	SELECT @PrevPriority = actt.Priority
		FROM QStatus_ActiveChecklistTaskType actt
		inner join QStatus_TaskTypes tt
		on tt.ID = actt.TaskType
		WHERE ActiveChecklistID = @TaskID
	

	SET @PrevPriority = IsNull(@PrevPriority, 1)

	IF @Priority IS NULL OR @Priority > 500 SELECT @Priority = @PrevPriority
	
	
	IF @Priority <> @PrevPriority 
		INSERT INTO QStatus_PriorityChanges
		(ActiveChecklistID, PriorityOld, UpdateDT)
		VALUES
		(@TaskID, @PrevPriority, GETUTCDATE())	

	SELECT @DueDateOld = DueTime
	FROM QCheck_ActiveChecklists
	WHERE ID = @TaskID


	SELECT @NextDueDate = min(udt.duetime)
	from qcheck_upcomingduetimes udt
	inner join qcheck_activechecklists ac
	on ac.instanceid = udt.instanceid
	and ac.id = @TaskID

	
	IF isnull(@NextDueDate, '1/1/9999') > @DueDate
	BEGIN

		IF @DueDateOld is not null AND @DueDate is not null 
		BEGIN
			IF CONVERT(varchar, @DueDateOld, 101) <> CONVERT(varchar, @DueDate, 101) 
			BEGIN
				DECLARE @changedby varchar(100)
				SELECT @changedby = ShortName
				FROM
					QCheck_Users
				WHERE
					ID = @UserID

				INSERT INTO QStatus_DueDateChanges
				(ActiveChecklistID, DueDateOld, UpdateDT, changedby)
				VALUES
				(@TaskID, @DueDateOld, GETUTCDATE(), @changedby)	
			END	
		END
	
	END
	
	IF LEN(LTRIM(RTRIM(@Comments))) >0
		BEGIN

			DECLARE @CommentsInitials VARCHAR(2)

			SELECT @CommentsInitials = UPPER(LEFT(SUBSTRING(ShortName, CHARINDEX('-', ShortName) + 1, LEN(ShortName)), 2))
			FROM
				QCheck_Users
			WHERE
				ID = @UserID
			
			IF @CommentsID > 0
			BEGIN
				UPDATE QStatus_Comments
				SET 
					Comments = @Comments,
					CommentDt = GETUTCDATE()
				WHERE
					ID = @CommentsID
				--AND 
					--Comments <> @Comments
			END
			ELSE
			BEGIN
				DECLARE @DisplayOrder int
					SELECT 	@DisplayOrder = ISNULL(Max(DisplayOrder), 0)
					FROM
						QStatus_Comments
					WHERE 
						ForeignKeyID = ABS(@TaskID)
					AND
						(@TaskID > 0 and SpecialTask = 0)
					OR
						(@TaskID < 0 and SpecialTask = 1)

				INSERT INTO
						QStatus_Comments
				(ForeignKeyID, Comments, DisplayOrder, CommentDt, Initials, UserID, SpecialTask)
				VALUES
				(ABS(@TaskID), @Comments, @DisplayOrder + 1, GETUTCDATE(), @CommentsInitials, @UserID, CASE WHEN @taskID > 0 then 0 else 1 End)
			END
			
			
			SELECT @CurrentDueTime = DueTime
			FROM QCheck_ActiveChecklists
			WHERE ID = @TaskID
	

			SET @tmpstr = CAST(MONTH(ISNull(@DueDate, @DueDateOld)) as varchar)+'/'+CAST(DAY(ISNull(@DueDate, @DueDateOld))as varchar)+'/'+CAST(YEAR(ISNull(@DueDate, @DueDateOld))as varchar) + ' ' + CAST(DATEPART(hh, @CurrentDueTime)as varchar)+':'+CAST(DATEPART(mi,@CurrentDueTime)as varchar)+':00'
			SET @tmpdt = CAST(@tmpstr as datetime)

			SELECT @FreqType = s.FreqType, @SchID = s.ID
			FROM
				QCheck_ActiveChecklists ac
			INNER JOIN
				QCheck_ChecklistInstances i
			ON
				ac.InstanceID = i.ID
			AND
				ac.ID = @TaskID
			INNER JOIN
				QCheck_Schedule s
			ON
				s.ID = i.ScheduleID

			IF @FreqType = 1 
				BEGIN
					UPDATE QCheck_Schedule
					SET FirstDueDate = @tmpdt
					WHERE ID = @SchID
				END
			
			IF isnull(@NextDueDate, '1/1/9999') > @DueDate
			begin
				UPDATE 	QCheck_ActiveChecklists
				SET DueTime = 	@tmpdt
				WHERE ID = @TaskID

				IF @TaskID in (select sourceactivechecklist from QCheck_LinkedDeadlines where isdeleted = 0)
				begin
					exec [dbo].[QCheck_LinkedDeadlines_Process] @TaskID, 'CHANGE'
				end

			end

			UPDATE QStatus_ActiveChecklistTaskType
				SET /*[Description]=@Description, 
				[DueDate]=@DueDate, */
				[Priority]=@Priority/*, 
				[UpdatedDate]=GETUTCDATE()*/
			WHERE
				ActiveChecklistID = @TaskID
		END	
	ELSE
		BEGIN
			IF @CommentsID > 0 
			BEGIN
				DELETE FROM QStatus_Comments
				WHERE ID = @CommentsID
				AND
					LEN(Comments) > 0
			END

			SELECT @CurrentDueTime = DueTime
			FROM QCheck_ActiveChecklists
			WHERE ID = @TaskID
	

			SET @tmpstr = CAST(MONTH(ISNull(@DueDate, @DueDateOld)) as varchar)+'/'+CAST(DAY(ISNull(@DueDate, @DueDateOld))as varchar)+'/'+CAST(YEAR(ISNull(@DueDate, @DueDateOld))as varchar) + ' ' + CAST(DATEPART(hh, @CurrentDueTime)as varchar)+':'+CAST(DATEPART(mi,@CurrentDueTime)as varchar)+':00'
			SET @tmpdt = CAST(@tmpstr as datetime)

			
			SELECT @FreqType = s.FreqType, @SchID = s.ID
			FROM
				QCheck_ActiveChecklists ac
			INNER JOIN
				QCheck_ChecklistInstances i
			ON
				ac.InstanceID = i.ID
			AND
				ac.ID = @TaskID
			INNER JOIN
				QCheck_Schedule s
			ON
				s.ID = i.ScheduleID

			IF @FreqType = 1 
				BEGIN
					UPDATE QCheck_Schedule
					SET FirstDueDate = @tmpdt
					WHERE ID = @SchID
				END
			
			IF isnull(@NextDueDate, '1/1/9999') > @DueDate
			begin
				UPDATE 	QCheck_ActiveChecklists
				SET DueTime = 	@tmpdt
				WHERE ID = @TaskID

				IF @TaskID in (select sourceactivechecklist from QCheck_LinkedDeadlines where isdeleted = 0)
				begin
					exec [dbo].[QCheck_LinkedDeadlines_Process] @TaskID, 'CHANGE'
				end
			end
			/*UPDATE QStatus_Tasks
					SET [Description]=@Description, 
					[DueDate]=@DueDate, 
					[Priority]=@Priority,
					[UpdatedDate]=GETUTCDATE()
			WHERE NOT EXISTS
				(SELECT @TaskID 
				FROM QStatus_Tasks
				WHERE [Description]=@Description
				AND IsNull([DueDate],0)=IsNull(@DueDate,0) 
				AND [Priority]=@Priority
				AND ID = @TaskID)

			AND ID = @TaskID*/

			UPDATE QStatus_ActiveChecklistTaskType
				SET /*[Description]=@Description, 
				[DueDate]=@DueDate, */
				[Priority]=@Priority/*, 
				[UpdatedDate]=GETUTCDATE()*/
			WHERE
				ActiveChecklistID = @TaskID
		END


	DELETE FROM QStatus_Comments
	WHERE 
		ForeignKeyID = @TaskID
	AND
		LEN(Comments) = 0
	AND 
		ID <> @CommentsID

	UPDATE
		QStatus_Report
	SET 
		LastReportDate = GETUTCDATE()
	WHERE
		ID = @ReportID
	
	
END
GO

ALTER PROCEDURE [dbo].[XPSendEmail]
	@FROM varchar(8000),
	@FROM_NAME varchar(8000) = '',
	@TO varchar(8000),
	@subject varchar(8000),
	@message varchar(8000),
	@type varchar(8000),
	@server varchar(8000)
 AS
BEGIN
	SET NOCOUNT ON

	EXEC dbo.xp_smtp_sendmail
	    @FROM       = @FROM,
	    @FROM_NAME  = @FROM_NAME,
	    @TO         = @TO,
	    @subject    = @subject,
	    @message    = @message,
	    @type       = @type,
	    @server     = @server

	insert into qcheck_emails (EmailAddress, Subject, Sent)
	values (@to, @subject, GETUTCDATE())

	SET NOCOUNT OFF
END
GO

ALTER PROCEDURE [dbo].[WOHelp_OpenTasks_EMAIL]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	Declare @ChecklistName varchar(1000)
	Declare @SubmitDate varchar(100)
	Declare @Assignees varchar(100)
	Declare @DueDate varchar(100)
	Declare @comments varchar(max)
	declare @html varchar(max)
	DECLARE @mail_subject VARCHAR(500)
	DECLARE @mail_to VARCHAR(500)
	DECLARE @mail_from VARCHAR(500)
	DECLARE @fromname VARCHAR(100)

	-- Get app configuration
	DECLARE @AppURL VARCHAR(50), @ImagesURL VARCHAR(50), @ExternalURL VARCHAR(50), @BaseDomain VARCHAR(50), @FromAddress VARCHAR(50), @AppName VARCHAR(50), @GradingAddress VARCHAR(50), @AutomationAddress VARCHAR(50), @DeveloperAddress VARCHAR(50)
	SELECT @AppURL = AppURL, @ImagesURL = ImagesURL, @ExternalURL = ExternalURL, @BaseDomain = BaseDomain, @FromAddress = FromAddress, @Appname = AppName, @GradingAddress = GradingAddress, @AutomationAddress = AutomationAddress, @DeveloperAddress = DeveloperAddress FROM QCheck_AppSettings WHERE ID = 1

	SET @mail_from = REPLACE(@FromAddress, @AppName, @AppName + '-alert')
	--SET @fromname = @Appname + '-Alert'
	SET @fromname = 'WO OPEN Task'

	SET @mail_subject = 'WOHelp Open Tasks'

	set @mail_to = 'graynor1@acmewidget.com;montana.umbel@aol.com;tgermany@qdevelopmentgroup.com;jcolten@acmewidget.com;wdavis@qdevelopmentgroup.com;ngomes@acmewidget.com;'

	set @html = '<html><head><style>TD {border:solid 1px #000000;font-size:16pt;font-family:Times New Roman;} .hide {display:none} TH{border:solid 1px #000000;font-size:18pt;font-family:Times New Roman;font-weight:bold;background-color:#DDDDDD;}</style></head><body>'
	set @html = @html + '<h2>Open Tasks</h2>'
	set @html = @html + '<table cellspacing=0 cellpadding=13><tr><th>Task</th><th>Submitted</th><th>Days Open</th><th>Assigned To</th><th>Due Date</th><th>Days Overdue</th><th>Comments</th></tr>'

	DECLARE TASKCURS CURSOR FOR
		select '<a href="'+@ExternalURL+'/ManageSingleChecklist.aspx?&taskId='+cast(ac.id as varchar(10))+'&taskStage=Current">' + c.name + '</a>'
			, convert(varchar, c.createdate, 101) as submitted
			, dbo.QCheck_FullAssigneesListWithSpaces(ci.id) as assignees 
			, convert(varchar, ac.DueTime, 101) as duedate
			, isnull(comments2.comments + '<br>', '') + isnull(comments.comments, '') as comments
		from qcheck_checklists c
		inner join qcheck_checklistinstances ci
			on c.id = ci.checklistid
		inner join qcheck_activechecklists ac
			on ac.instanceid = ci.id
			and ac.completeddate is null
		inner join QStatus_ActiveChecklistTaskType actt
			on actt.ActiveChecklistID = ac.id
		outer apply
		(
			select top 1 '[' + convert(varchar, commentdt, 101) + '] [' + initials + '] ' + comments as comments, commentdt
			from qstatus_comments
			where specialtask = 0
			and foreignkeyid = ac.id
			order by commentdt desc
		) as comments
		outer apply
		(
			select top 1 '[' + convert(varchar, commentdt, 101) + '] [' + initials + '] ' + comments as comments
			from qstatus_comments
			where specialtask = 0
			and foreignkeyid = ac.id
			and commentdt < comments.commentdt
			order by commentdt desc
		) as comments2
		where actt.TaskType in (1147194, 1156405)
		and ac.ID not in (SELECT ID
			FROM [dbo].[PriorityList]
			where userid = 976)
		order by c.createdate

	OPEN TASKCURS
		FETCH NEXT FROM TASKCURS INTO @ChecklistName, @SubmitDate, @Assignees, @DueDate, @comments
		WHILE @@FETCH_STATUS = 0 BEGIN

			SET @html = @html + '<tr><td><span class="hide"></span>'+@ChecklistName+'<span class="hide"><br><br></span></td>'		
			SET @html = @html + '<td><span class="hide"></span>'+@SubmitDate+'<span class="hide"><br><br></span></td>'
			SET @html = @html + '<td><span class="hide"></span>'+convert(varchar(10),datediff(day, @SubmitDate, GETUTCDATE())) +'<span class="hide"><br><br></span></td>'
			SET @html = @html + '<td><span class="hide"></span>'+@Assignees+'<span class="hide"><br><br></span></td>'
			SET @html = @html + '<td><span class="hide"></span>'+@DueDate+'<span class="hide"><br><br></span></td>'
			SET @html = @html + '<td><span class="hide"></span>'+ case when convert(varchar(10),datediff(day, @DueDate, GETUTCDATE())) > 0 then convert(varchar(10),datediff(day, @DueDate, GETUTCDATE())) else '-' end +'<span class="hide"><br><br></span></td>'
			SET @html = @html + '<td><span class="hide"></span>'+ @comments +'<span class="hide"><br><br></span></td>'
			SET @html = @html + '</tr>'
		FETCH NEXT FROM TASKCURS INTO  @ChecklistName, @SubmitDate, @Assignees, @DueDate, @comments
		END
	CLOSE TASKCURS
	DEALLOCATE TASKCURS	

	set @html = @html + '</table><br/><br/>'
	set @html = @html + '<a href="' + ISNULL(@ExternalURL, '') + '">' + ISNULL(@AppURL, '') + '</a></body></html>'

	exec [dbo].[xp_smtp_sendmail]
		@to = @mail_to,
		@from = @mail_from,
		@from_name = @fromname,
		@subject = @mail_subject,
		@message = @html


END
GO

ALTER PROCEDURE [dbo].[WO_PowerOutageChecklist] AS
BEGIN

	-- Checklist instance to copy every time we need to make this checklist due.  This is a one-time task assigned 
	-- to the Westover Power Outtage group.
	DECLARE @InstanceID INT
	SET @InstanceID = 1683759
	
	DECLARE @DueTime int

	SELECT @DueTime = duetime from QCheck_UserDefaultTimes
	WHERE UserID = -1
	
	-- When the power goes out, this checklist should initially be due same-day.  The guys can push it back if they
	-- need to.
	DECLARE @DueDate DATETIME
	SET @DueDate = dbo.ConvertTimeToUtc(CONVERT(VARCHAR(10), GETDATE(), 101) + ' ' + convert(varchar(2), @DueTime) + ':00:00', 'America/Chicago')
	
	-- Copy the instance to the new due date.  Thanks Ken for the handy util stored procedure.
	EXEC Util_CopyInstanceNewDueDate @InstanceID, @DueDate

END
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[QCheck_Approval_CRChanged_Natural] (
	@ChangeID INT,
	@TimeZone varchar(255) = NULL
) AS

BEGIN

	DECLARE @Out TABLE (
		Seq INT IDENTITY(1,1),
		Item VARCHAR(max),
		Requested VARCHAR(max),
		CRItemID INT,
		Approved BIT
	)

	SELECT @TimeZone = COALESCE(@TimeZone, u.TimeZoneOverride, u.LastTimeZone)
	FROM QCheck_Users u
	JOIN QCheck_Approval_ChangeRequests cr
		ON cr.RequestingUser = u.ID
		AND cr.ID = @ChangeID

	DECLARE @CurrentButton VARCHAR(max),
		@RequestButton VARCHAR(max),
		@ReorderCount int
	
	-- ===============================================================
	-- Active Checklists			
	-- Due date
	INSERT INTO @Out (Item, Requested, CRItemID, Approved)
		SELECT 'Due Date', 'Changing Due Date from ' 
				+ dbo.ConvertTimeFromUtc(C.DueTime, @TimeZone) 
				+ ' to ' 
				+ dbo.ConvertTimeFromUtc(R.DueTime, @TimeZone)
				+ ' (' + @TimeZone + ')', 
			CRI.[ID], CRI.Approved
		FROM QCheck_Approval_ActiveChecklists R
		INNER JOIN QCheck_ActiveChecklists C
			ON R.ActiveChecklistID = C.[ID] 
			--AND R.DueTime <> C.DueTime -- Don't filter this, it needs to show in the request even if it's the current deadline
 		INNER JOIN QCheck_Approval_ChangeRequestItems cri
 			ON R.CRItemID = cri.[ID]
		WHERE R.ChangeRequestID = @ChangeID
	
	
	
	-- ===============================================================
	-- Checklists
	
	-- Checklist name
	INSERT INTO @Out (Item, Requested, CRItemID, Approved)
		SELECT 'Checklist Name', 'Changing Checklist Name from "' + C.[Name] +'" to "' + R.[Name] + '"', CRI.[ID], CRI.Approved
		FROM QCheck_Approval_Checklists R
 		INNER JOIN QCheck_Approval_ChangeRequestItems cri
 			ON R.CRItemID = cri.[ID]
		INNER JOIN QCheck_Checklists C 
			ON R.ChecklistID = C.[ID] 
			AND R.[Name] <> C.[Name]
		WHERE R.ChangeRequestID = @ChangeID AND R.IsDeleted = 0 AND C.IsDeleted = 0
	
	
	-- ===============================================================
	-- Items
	
	-- Item Type
	INSERT INTO @Out (Item, Requested, CRItemID, Approved)
		SELECT 'Checklist Item Type', 
		'Changing Item Type of checklist item "'+CASE WHEN LEN(C.[Text]) <= 20 THEN C.[Text] ELSE LEFT(C.[Text], 20) + '...' END
		+'" from ' + CT.[Name] + ' to ' + RT.[Name], CRI.[ID], CRI.Approved
		FROM QCheck_Approval_Items R
 		INNER JOIN QCheck_Approval_ChangeRequestItems cri
 			ON R.CRItemID = cri.[ID]
		INNER JOIN QCheck_Items C 
			ON R.ItemID = C.[ID] 
			AND R.ItemTypeID <> C.ItemTypeID
		INNER JOIN QCheck_ItemTypes CT
			ON C.ItemTypeID = CT.[ID]
		INNER JOIN QCheck_ItemTypes RT
			ON R.ItemTypeID = RT.[ID]
		WHERE R.ChangeRequestID = @ChangeID AND R.IsDeleted = 0 AND C.IsDeleted = 0
	
	-- Name
	INSERT INTO @Out (Item, Requested, CRItemID, Approved)
		SELECT 'Item Text', 'Changing text of checklist item "' + C.[Text] + '" to read "' + R.[Text] + '"', CRI.[ID], CRI.Approved
		FROM QCheck_Approval_Items R
 		INNER JOIN QCheck_Approval_ChangeRequestItems cri
 			ON R.CRItemID = cri.[ID]
		INNER JOIN QCheck_Items C 
			ON R.ItemID = C.[ID] 
			AND R.[Text] <> C.[Text]
		WHERE R.ChangeRequestID = @ChangeID AND R.IsDeleted = 0 AND C.IsDeleted = 0
	
	-- URL
	INSERT INTO @Out (Item, Requested, CRItemID, Approved)
		SELECT 'Item URL', 'Changing "More Info" URL of checklist item "'+CASE WHEN LEN(C.[Text]) <= 20 THEN C.[Text] ELSE LEFT(C.[Text], 20) + '...' END
		+'" from "' + C.[URL] + '" to "' + R.[URL] + '"', CRI.[ID], CRI.Approved
		FROM QCheck_Approval_Items R
 		INNER JOIN QCheck_Approval_ChangeRequestItems cri
 			ON R.CRItemID = cri.[ID]
		INNER JOIN QCheck_Items C 
			ON R.ItemID = C.[ID] 
			AND R.[URL] <> C.[URL]
		WHERE R.ChangeRequestID = @ChangeID AND R.IsDeleted = 0 AND C.IsDeleted = 0
	
	
	-- Sequence reordering
	-- Old Way - doesn't work, because sequence numbers almost always change, but the order doesn't always

	--IF EXISTS (
	--	SELECT 'Y'
	--	FROM QCheck_Approval_Items R
	--	INNER JOIN QCheck_Items C 
	--		ON R.ItemID = C.[ID] 
	--		AND R.[SequenceNum] <> C.[SequenceNum]
	--	WHERE R.ChangeRequestID = @ChangeID AND R.IsDeleted = 0 AND C.IsDeleted = 0
	--) BEGIN

		--SET @CurrentButton = '<input type="button" class="btn btn-default" value="Preview Current" onclick="DoPreview(-1, ' + CONVERT(VARCHAR(20), dbo.QCheck_Approval_CRChecklistID(@ChangeID)) + ', ''' + dbo.QCheck_Approval_CRChecklistName(@ChangeID) + ''');"/>'
		--SET @RequestButton = '<input type="button" class="btn btn-default" value="Preview Requested" onclick="DoPreview(' + CONVERT(VARCHAR(20), @ChangeID) + ', ' + CONVERT(VARCHAR(20), dbo.QCheck_Approval_CRChecklistID(@ChangeID)) + ', ''' + dbo.QCheck_Approval_CRChecklistName(@ChangeID) + ''');"/>'
		
		--SELECT @ReorderCount = COUNT(*)
		--FROM QCheck_Approval_Items R
		--INNER JOIN QCheck_Items C 
		--	ON R.ItemID = C.[ID] 
		--	AND R.[SequenceNum] <> C.[SequenceNum]
		--WHERE R.ChangeRequestID = @ChangeID AND R.IsDeleted = 0 AND C.IsDeleted = 0

		--New Way		
		--Basic idea; get all items not being added or deleted (doesn't count as a reorder),
		--then line them up row by row, and count all lines where the item IDs don't match 
		SELECT @ReorderCount = COUNT(*)
		FROM (
			SELECT ROW_NUMBER() OVER (ORDER BY i2.SequenceNum) Row, i2.ID 
				FROM QCheck_Items i2
				JOIN QCheck_Approval_Items ai2
					ON ai2.ChangeRequestID = @ChangeID
					AND ai2.ItemID = i2.ID			
				WHERE i2.IsDeleted = 0
					AND ai2.IsDeleted = 0 --no newly-deleted rows
			) i
		FULL JOIN (
			SELECT ROW_NUMBER() OVER (ORDER BY ai2.SequenceNum) Row, ai2.ItemID ID
				FROM QCheck_Approval_Items ai2
				WHERE ai2.ChangeRequestID = @ChangeID
				AND ai2.ItemID <> -1 --no newly-added rows
				AND ai2.IsDeleted = 0
			) ai
			ON ai.Row = i.Row
		WHERE ai.ID <> i.ID

		SET @ReorderCount = ISNULL(@ReorderCount, 0)

		IF(@ReorderCount > 0)
			INSERT INTO @Out (Item, Requested, CRItemID, Approved) VALUES ('Reorder', 'Reordering ' + CAST(@ReorderCount as varchar) + ' items within the checklist', -1, 1)

	--END
	
	-- ===============================================================
	-- Schedule
	
	INSERT INTO @Out (Item, Requested, CRItemID, Approved)
		SELECT 'Schedule', 'Changing schedule from "' + isnull(dbo.QCheck_ScheduleString(C.[ID]), 'no schedule') + '" to "' + dbo.QCheck_Approval_ScheduleString(@ChangeID, R.ScheduleID, CI.ID) + '"', CRI.[ID], CRI.Approved
		FROM QCheck_Approval_Schedule R
 		INNER JOIN QCheck_Approval_ChangeRequestItems cri
 			ON R.CRItemID = cri.[ID]
		INNER JOIN QCheck_Schedule C 
			ON R.ScheduleID = C.[ID] 
			AND (
				ISNULL(R.FirstDueDate,'') <> ISNULL(C.FirstDueDate,'')
				OR ISNULL(R.LastDueDate, '') <> ISNULL(C.LastDueDate, '')
				OR R.FreqType <> C.FreqType
				OR R.FreqInterval <> C.FreqInterval
				OR R.FreqRecurrance <> C.FreqRecurrance
				OR ISNULL(R.DueTime,'') <> ISNULL(C.DueTime,'')
				OR R.BusDayBehavior <> C.BusDayBehavior
				OR R.SoftDueOffsetDays <> C.SoftDueOffsetDays
				OR R.TimeZone <> C.TimeZone
			)
		INNER JOIN QCheck_ChecklistInstances CI
			ON CI.ScheduleID = R.ScheduleID 
		WHERE R.ChangeRequestID = @ChangeID
	
	
	-- ===============================================================
	-- Get the output
	SELECT 
		Seq,
		Item,
		Requested,
		CRItemID,
		Approved
	FROM 
		@Out
	WHERE Requested IS NOT NULL

END
GO


ALTER FUNCTION [dbo].[QCheck_Approval_AlertString] (
	@ID INT
) RETURNS VARCHAR(500) AS

BEGIN

	DECLARE @out VARCHAR(500)
	
	SELECT @out =
		CASE
			WHEN AlertType = 'Reminder' AND AlertTime >= 0 THEN 'Reminder to assignees ' + CONVERT(VARCHAR(10), DaysBefore) + ' day(s) before due at ' + dbo.FloatToTime(AlertTime) + ' (' + s.TimeZone + ')'
			WHEN AlertType = 'Reminder' AND AlertTime < 0 THEN 'Reminder to assignees ' + CONVERT(VARCHAR(10), AlertTime * -1) + ' hour(s) before due'
			WHEN AlertType = 'Complete' THEN 'Email ' + G.[Name] + ' when complete'
			WHEN AlertType = 'Assignment' THEN 'Email ' + G.[Name] + ' when assignments are changed'
			WHEN AlertType = 'Overdue' THEN 'Email ' + G.[Name] + ' when task goes overdue'
			WHEN AlertType = 'Hours' AND CHARINDEX('.', CONVERT(VARCHAR(20), AlertTime)) > 0 THEN 'Email ' + G.[Name] + ' every ' + CONVERT(VARCHAR(10), CONVERT(INT, AlertTime * 60)) + ' minutes after task goes overdue' + CASE WHEN LEN(ISNULL(AlertText, '')) > 0 THEN ' with the message "' + AlertText + '"' ELSE '' END
			WHEN AlertType = 'Hours' AND CHARINDEX('.', CONVERT(VARCHAR(20), AlertTime)) = 0 THEN 'Email ' + G.[Name] + ' every ' + CONVERT(VARCHAR(10), CONVERT(INT, AlertTime)) + ' hours after task goes overdue' + CASE WHEN LEN(ISNULL(AlertText, '')) > 0 THEN ' with the message "' + AlertText + '"' ELSE '' END
			WHEN AlertType = 'Schedule' THEN 'Email ' + G.[Name] + ' when the schedule is edited'
			WHEN AlertType = 'Custom' THEN 'Email ' + G.[Name] + ' ' + CONVERT(VARCHAR(10), DaysBefore) + ' day(s) before due at ' + dbo.FloatToTime(AlertTime) + ' with the message "' + ISNULL(AlertText, '') + '"'
		END
	FROM 
		QCheck_Approval_Alerts A
		LEFT OUTER JOIN QCheck_ChecklistInstances I
			ON I.ID = A.InstanceID
		LEFT OUTER JOIN QCheck_Schedule S
			ON S.ID = I.ScheduleID
		LEFT OUTER JOIN QCheck_Groups G
			ON A.AlerteeGroupID = G.[ID]
	WHERE
		A.[ID] = @ID
	
	RETURN @out

END
GO
