ALTER TABLE dbo.QCheck_Users ADD LastTimeZone VARCHAR(255) NULL;
ALTER TABLE dbo.QCheck_Users ADD TimeZoneOverride VARCHAR(255) NULL;
ALTER TABLE dbo.QCheck_Schedule ADD TimeZone VARCHAR(255) NULL
GO

CREATE TYPE dbo.TimeZoneType AS TABLE
(
    Timezone	varchar(255) NOT NULL
)
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

	UPDATE dbo.QCheck_Users
	SET  LastTimeZone = ISNULL(@lastTimeZone, LastTimeZone)
		,TimeZoneOverride = ISNULL(@timeZoneOverride, TimeZoneOverride)
	WHERE 1 = 1
		AND ID = ISNULL(@userId, ID)
		AND ShortName = ISNULL(@shortName, ShortName)
		AND Email = ISNULL(@email, Email)
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
	RETURN 'http://localhost:8080/Services/ControlService.asmx/'
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

	SELECT @result = STRING_AGG('"' + CAST(Timezone AS VARCHAR(8000)) + '"', ', ') FROM @tzTable
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
UPDATE [dbo].[Audit_ActiveChecklist] SET [AuditDt] = dbo.ToUtc([AuditDt])
UPDATE [dbo].[QCheck_GroupMembership] SET [AsOf] = dbo.ToUtc([AsOf])
UPDATE [dbo].[QCheck_GroupOwnerAudit] SET [ChangeDt] = dbo.ToUtc([ChangeDt])
UPDATE [dbo].[QCheck_InstanceStops] SET [stoppedDt] = dbo.ToUtc([stoppedDt])
UPDATE [dbo].[QCheck_ItemArchive] SET [ArchiveDate] = dbo.ToUtc([ArchiveDate])
UPDATE [dbo].[QCheck_LateFee] SET [StartDate] = dbo.ToUtc([StartDate]), [EndDate] = dbo.ToUtc([EndDate])
UPDATE [dbo].[QCheck_LinkedDeadlines] SET [CreatedDt] = dbo.ToUtc([CreatedDt]), [ModifiedBy] = dbo.ToUtc([ModifiedBy])
UPDATE [dbo].[QCheck_GroupChanges] SET [dt] = dbo.ToUtc([dt])
UPDATE [dbo].[QCheck_LoadTimes] SET [Dt] = dbo.ToUtc([dt]), [LastOpened] = dbo.ToUtc([LastOpened])
UPDATE [dbo].[QCheck_PagesLoaded_BonusUsers] SET [Dt] = dbo.ToUtc([dt])
UPDATE [dbo].[QCheck_Reassign_History] SET [ViewDate] = dbo.ToUtc([ViewDate])
UPDATE [dbo].[QCheck_ReminderTasksReport] SET [ReportTime] = dbo.ToUtc([ReportTime])
UPDATE [dbo].[QCheck_Schedule] SET [firstDueDate] = dbo.ToUtc([firstDueDate]), [lastDueDate] = dbo.ToUtc([lastDueDate])
UPDATE [dbo].[QCheck_ScheduleArchive] SET [firstDueDate] = dbo.ToUtc([firstDueDate]),[lastDueDate] = dbo.ToUtc([lastDueDate]),[ArchiveDate] = dbo.ToUtc([ArchiveDate])
UPDATE [dbo].[QCheck_SetUpcomingTiming] SET [startdt] = dbo.ToUtc([startdt]),[enddt] = dbo.ToUtc([enddt])
UPDATE [dbo].[QCheck_Log_Emails] SET [Sent] = dbo.ToUtc([Sent])
UPDATE [dbo].[QCheck_Suggestions] SET [Dt] = dbo.ToUtc([dt])
UPDATE [dbo].[QCheck_BonusTasks] SET [Dt] = dbo.ToUtc([dt])
UPDATE [dbo].[QCheck_BonusUsers] SET [startdt] = dbo.ToUtc([startdt]),[enddt] = dbo.ToUtc([enddt])
UPDATE [dbo].[QCheck_BulkAssigned] SET [RequesteDate] = dbo.ToUtc([RequesteDate])
UPDATE [dbo].[QCheck_ChecklistArchive] SET [CreateDate] = dbo.ToUtc([CreateDate]),[ArchiveDate] = dbo.ToUtc([ArchiveDate])
UPDATE [dbo].[QCheck_ChecklistInstanceArchive] SET [ArchiveDate] = dbo.ToUtc([ArchiveDate])
UPDATE [dbo].[QCheck_ChecklistManagerArchive] SET [ArchiveDate] = dbo.ToUtc([ArchiveDate])
UPDATE [dbo].[QCheck_ChecklistManagers] SET [CreateDate] = dbo.ToUtc([CreateDate])
UPDATE [dbo].[QCheck_ChecklistManagers_Temp] SET [Expires] = dbo.ToUtc([Expires])
UPDATE [dbo].[QCheck_Checklists] SET [CreateDate] = dbo.ToUtc([CreateDate])
UPDATE [dbo].[QCheck_Emails] SET [Sent] = dbo.ToUtc([Sent])
UPDATE [dbo].[QCheck_EmailsReport] SET [Sent] = dbo.ToUtc([Sent])
UPDATE [dbo].[QCheck_EmailTasks] SET [CreatedDt] = dbo.ToUtc([CreatedDt])
UPDATE [dbo].[QCheck_EventLog] SET [EventDateTime] = dbo.ToUtc([EventDateTime])
UPDATE [dbo].[QCheck_ExtendedTasksWarningEmail_Queue] SET [emailSent] = dbo.ToUtc([emailSent])
UPDATE [dbo].[QCheck_CompletionPopupLog] SET [popupdt] = dbo.ToUtc([popupdt])
UPDATE [dbo].[QCheck_BonusStatusEmails] SET [SentDt] = dbo.ToUtc([SentDt])
UPDATE [dbo].[QCheck_Suggestions_Archive] SET [Dt] = dbo.ToUtc([dt])
UPDATE [dbo].[QStatus_PriorityChanges] SET [Updatedt] = dbo.ToUtc([Updatedt])
UPDATE [dbo].[QStatus_Report] SET [LastReportDate] = dbo.ToUtc([LastReportDate])
UPDATE [dbo].[QStatus_ReportLastestComments] SET [Commentdt] = dbo.ToUtc([Commentdt])
UPDATE [dbo].[QStatus_SpecialTasks] SET [UpdatedDate] = dbo.ToUtc([UpdatedDate])
UPDATE [dbo].[QStatus_Supervisors] SET [AsOf] = dbo.ToUtc([AsOf])
UPDATE [dbo].[QStatus_TaskNameChanges] SET [UpdateDt] = dbo.ToUtc([UpdateDt])
UPDATE [dbo].[QStatus_TempTasks] SET [input_date] = dbo.ToUtc([input_date])
UPDATE [dbo].[Schedule_PriorityList] SET [CreatedDate] = dbo.ToUtc([CreatedDate]),[ModifiedDate] = dbo.ToUtc([ModifiedDate])
UPDATE [dbo].[Schedule_PriorityList_Exclude] SET [ExcludedDate] = dbo.ToUtc([ExcludedDate]),[CreatedDate] = dbo.ToUtc([CreatedDate])
UPDATE [dbo].[Supervisor_PriorityList_Report_Schedule] SET [CreatedDate] = dbo.ToUtc([CreatedDate]),[ModifiedDate] = dbo.ToUtc([ModifiedDate])
UPDATE [dbo].[QStatus_SupervisorsLastViewed] SET [LastViewed] = dbo.ToUtc([LastViewed])
UPDATE [dbo].[QStatus_OnHold] SET [StartDt] = dbo.ToUtc([StartDt]),[Enddt] = dbo.ToUtc([Enddt])
UPDATE [dbo].[QStatus_GroupReport] SET [AsOf] = dbo.ToUtc([AsOf])
UPDATE [dbo].[QCheck_UpcomingDueTimes] SET [DueTime] = dbo.ToUtc([DueTime]),[RelativeDueTime] = dbo.ToUtc([RelativeDueTime])
UPDATE [dbo].[QStatus_ActiveChecklistTaskType] SET [CreateDt] = dbo.ToUtc([CreateDt])
UPDATE [dbo].[QStatus_ActiveChecklistTaskTypeArchive] SET [CreateDt] = dbo.ToUtc([CreateDt]),[ArchiveDt] = dbo.ToUtc([ArchiveDt])
UPDATE [dbo].[QStatus_CommentArchive] SET [CommentDt] = dbo.ToUtc([CommentDt]),[AsOfDate] = dbo.ToUtc([AsOfDate])
UPDATE [dbo].[QStatus_Comments] SET [CommentDt] = dbo.ToUtc([CommentDt])
UPDATE [dbo].[QStatus_DueDateChanges] SET [DueDateOld] = dbo.ToUtc([DueDateOld]),[UpdateDt] = dbo.ToUtc([UpdateDt])
UPDATE [dbo].[Temp_UpdateSchedule] SET [Dt] = dbo.ToUtc([dt])
UPDATE [dbo].[QCheck_BonusesPaid] SET [dt] = dbo.ToUtc([dt])
UPDATE [dbo].[QCheck_BonusCommentsLog] SET [Dt] = dbo.ToUtc([dt])
UPDATE [dbo].[Grading_Daily] SET [dt] = dbo.ToUtc([dt])
UPDATE [dbo].[Grading_Daily_Comments] SET [CommentDt] = dbo.ToUtc([CommentDt])
UPDATE [dbo].[Grading_Daily_Final] SET [dt] = dbo.ToUtc([dt])
UPDATE [dbo].[Grading_Daily_Final_Deleted] SET [dt] = dbo.ToUtc([dt])
UPDATE [dbo].[Grading_Daily_GradingPeriod] SET [StartDt] = dbo.ToUtc([StartDt]),[EndDt] = dbo.ToUtc([EndDt])
UPDATE [dbo].[Grading_Daily_UserReport] SET [dt] = dbo.ToUtc([dt])
UPDATE [dbo].[Grading_OnHold] SET [StartDt] = dbo.ToUtc([StartDt]),[EndDt] = dbo.ToUtc([EndDt])
UPDATE [dbo].[Grading_QProcessTests] SET [gradeddt] = dbo.ToUtc([gradeddt])
UPDATE [dbo].[Grading_Vacations] SET [StartDt] = dbo.ToUtc([StartDt]),[EndDt] = dbo.ToUtc([EndDt])
UPDATE [dbo].[JB_Tasks_Archive_Full] SET [duetime] = dbo.ToUtc([duetime]),[Commentdt] = dbo.ToUtc([Commentdt])
UPDATE [dbo].[OverDueTasks_LateFee_Log] SET [DueDate] = dbo.ToUtc([DueDate]),[CompletedDate] = dbo.ToUtc([CompletedDate]),[AsOfDate] = dbo.ToUtc([AsOfDate]),[RunDate] = dbo.ToUtc([RunDate]),[ExcusedDt] = dbo.ToUtc([ExcusedDt])
UPDATE [dbo].[OverDueTasks_LateFee_Log_bkup] SET [DueDate] = dbo.ToUtc([DueDate]),[CompletedDate] = dbo.ToUtc([CompletedDate]),[AsOfDate] = dbo.ToUtc([AsOfDate]),[RunDate] = dbo.ToUtc([RunDate])
UPDATE [dbo].[OverDueTasks_LateFee_Log_bkup_03052018] SET [DueDate] = dbo.ToUtc([DueDate]),[CompletedDate] = dbo.ToUtc([CompletedDate]),[AsOfDate] = dbo.ToUtc([AsOfDate]),[RunDate] = dbo.ToUtc([RunDate]),[ExcusedDt] = dbo.ToUtc([ExcusedDt])
UPDATE [dbo].[QCheck_BonusEmailTasks] SET [dt] = dbo.ToUtc([dt])
UPDATE [dbo].[PFS_SupervisorTasks] SET [Dt] = dbo.ToUtc([dt])
UPDATE [dbo].[Email2dbImageChecklists_Archive] SET [archivedt] = dbo.ToUtc([archivedt])
UPDATE [dbo].[Audit_ActiveItem] SET [AuditDt] = dbo.ToUtc([AuditDt])
UPDATE [dbo].[Audit_ApprovalChecklist] SET [AuditDt] = dbo.ToUtc([AuditDt])
UPDATE [dbo].[Audit_ApprovalItem] SET [AuditDt] = dbo.ToUtc([AuditDt])
UPDATE [dbo].[Audit_ArchiveActiveChecklist] SET [ArchiveDt] = dbo.ToUtc([ArchiveDt]),[DueTime] = dbo.ToUtc([DueTime]),[OrigDueTime] = dbo.ToUtc([OrigDueTime]),[ReminderDate] = dbo.ToUtc([ReminderDate]),[CompletedDate] = dbo.ToUtc([CompletedDate])
UPDATE [dbo].[Audit_ArchiveActiveItem] SET [ArchiveDt] = dbo.ToUtc([ArchiveDt])
UPDATE [dbo].[Audit_ArchiveApprovalChecklist] SET [ArchiveDt] = dbo.ToUtc([ArchiveDt])
UPDATE [dbo].[Audit_ArchiveApprovalItem] SET [ArchiveDt] = dbo.ToUtc([ArchiveDt])
UPDATE [dbo].[Audit_ArchiveChecklist] SET [ArchiveDt] = dbo.ToUtc([ArchiveDt]),[CreateDate] = dbo.ToUtc([CreateDate])
UPDATE [dbo].[Audit_ArchiveComment] SET [ArchiveDt] = dbo.ToUtc([ArchiveDt]),[CommentDt] = dbo.ToUtc([CommentDt])
UPDATE [dbo].[Audit_ArchiveItem] SET [ArchiveDt] = dbo.ToUtc([ArchiveDt])
UPDATE [dbo].[Audit_ChangeRequest] SET [AuditDt] = dbo.ToUtc([AuditDt])
UPDATE [dbo].[Audit_Checklist] SET [AuditDt] = dbo.ToUtc([AuditDt])
UPDATE [dbo].[Audit_Comment] SET [AuditDt] = dbo.ToUtc([AuditDt])
UPDATE [dbo].[Audit_CommentArchived] SET [AuditDt] = dbo.ToUtc([AuditDt])
UPDATE [dbo].[Audit_Item] SET [AuditDt] = dbo.ToUtc([AuditDt])
UPDATE [dbo].[Audit_PageVisit] SET [AuditDt] = dbo.ToUtc([AuditDt])
UPDATE [dbo].[Audit_PriorityListSet] SET [AuditDt] = dbo.ToUtc([AuditDt])
UPDATE [dbo].[Audit_Report] SET [AuditDt] = dbo.ToUtc([AuditDt])
UPDATE [dbo].[Audit_TaskType] SET [AuditDt] = dbo.ToUtc([AuditDt])
UPDATE [dbo].[PFS_SupervisorUserNames] SET [Dt] = dbo.ToUtc([dt])
UPDATE [dbo].[PFS_BonusDatesAmounts] SET [Dt] = dbo.ToUtc([dt])
UPDATE [dbo].[QCheck_ActiveItems] SET [CompletedDate] = dbo.ToUtc([CompletedDate])
UPDATE [dbo].[QCheck_AlertArchive] SET [SentTime] = dbo.ToUtc([SentTime]),[ArchiveDate] = dbo.ToUtc([ArchiveDate])
UPDATE [dbo].[QCheck_AlertEmailWork] SET [DueTime] = dbo.ToUtc([DueTime])
UPDATE [dbo].[QCheck_Alerts] SET [SentTime] = dbo.ToUtc([SentTime])
UPDATE [dbo].[QCheck_Approval_ActiveChecklists] SET [DueTime] = dbo.ToUtc([DueTime]),[OrigDueTime] = dbo.ToUtc([OrigDueTime]),[ReminderDate] = dbo.ToUtc([ReminderDate]),[CompletedDate] = dbo.ToUtc([CompletedDate])
UPDATE [dbo].[QCheck_Approval_Alerts] SET [SentTime] = dbo.ToUtc([SentTime])
UPDATE [dbo].[QCheck_Approval_Assignments] SET [DtAssigned] = dbo.ToUtc([DtAssigned])
UPDATE [dbo].[QCheck_Approval_ChangeRequests] SET [RequestDate] = dbo.ToUtc([RequestDate]),[ApprovedDate] = dbo.ToUtc([ApprovedDate]),[RejectedDate] = dbo.ToUtc([RejectedDate])
UPDATE [dbo].[QCheck_Approval_ChangeRequests_Archive] SET [RequestDate] = dbo.ToUtc([RequestDate]),[ApprovedDate] = dbo.ToUtc([ApprovedDate]),[RejectedDate] = dbo.ToUtc([RejectedDate]),[ArchiveDt] = dbo.ToUtc([ArchiveDt])
UPDATE [dbo].[QCheck_ActiveItemArchive] SET [CompletedDate] = dbo.ToUtc([CompletedDate]),[ArchiveDate] = dbo.ToUtc([ArchiveDate])
UPDATE [dbo].[QCheck_Approval_Schedule] SET [firstDueDate] = dbo.ToUtc([firstDueDate]),[lastDueDate] = dbo.ToUtc([lastDueDate])
UPDATE [dbo].[QCheck_AssignedEmail_Queue] SET [AssignedDt] = dbo.ToUtc([AssignedDt]),[SentDt] = dbo.ToUtc([SentDt])
UPDATE [dbo].[QCheck_AssignmentArchive] SET [DtAssigned] = dbo.ToUtc([DtAssigned]),[ArchiveDate] = dbo.ToUtc([ArchiveDate])
UPDATE [dbo].[QCheck_Assignments] SET [DtAssigned] = dbo.ToUtc([DtAssigned])
UPDATE [dbo].[QCheck_AssignmentsTemporary] SET [TempAssignmentStart] = dbo.ToUtc([TempAssignmentStart]),[TempAssignmentEnd] = dbo.ToUtc([TempAssignmentEnd]),[CreatedDt] = dbo.ToUtc([CreatedDt])
UPDATE [dbo].[QCheck_AssignmentsTemporary_History] SET [TempAssignmentStart] = dbo.ToUtc([TempAssignmentStart]),[TempAssignmentEnd] = dbo.ToUtc([TempAssignmentEnd]),[CreatedDt] = dbo.ToUtc([CreatedDt]),[ArchiveDt] = dbo.ToUtc([ArchiveDt])
UPDATE [dbo].[QCheck_BonusChangeRequests] SET [Dt] = dbo.ToUtc([dt])
UPDATE [dbo].[PFS_UserList] SET [StartDt] = dbo.ToUtc([StartDt]),[Enddt] = dbo.ToUtc([Enddt])
UPDATE [dbo].[QCheck_ActiveChecklists] SET [DueTime] = dbo.ToUtc([DueTime]),[OrigDueTime] = dbo.ToUtc([OrigDueTime]),[ReminderDate] = dbo.ToUtc([ReminderDate]),[CompletedDate] = dbo.ToUtc([CompletedDate])
UPDATE [dbo].[Priorities_Lists] SET [UpdatedDate] = dbo.ToUtc([UpdatedDate])
UPDATE [dbo].[Priorities_ListSets] SET [UpdatedDate] = dbo.ToUtc([UpdatedDate])
UPDATE [dbo].[Priorities_Schedule] SET [CreatedDate] = dbo.ToUtc([CreatedDate]),[ModifiedDate] = dbo.ToUtc([ModifiedDate])
UPDATE [dbo].[Priorities_ScheduleExclude] SET [ExcludedDate] = dbo.ToUtc([ExcludedDate]),[CreatedDate] = dbo.ToUtc([CreatedDate])
UPDATE [dbo].[PriorityList_BonusSend] SET [Dt] = dbo.ToUtc([dt])
UPDATE [dbo].[PriorityList_LateFee_Log] SET [LateDate] = dbo.ToUtc([LateDate])
UPDATE [dbo].[PriorityListSet] SET [UpdatedDate] = dbo.ToUtc([UpdatedDate])
UPDATE [dbo].[QCheck_ActiveAlertArchive] SET [SentTime] = dbo.ToUtc([SentTime]),[ArchiveDate] = dbo.ToUtc([ArchiveDate])
UPDATE [dbo].[QCheck_ActiveAlerts] SET [SentTime] = dbo.ToUtc([SentTime])
UPDATE [dbo].[PFSData_BonusTests] SET [firstTestDt] = dbo.ToUtc([firstTestDt]),[finalTestDt] = dbo.ToUtc([finalTestDt])
UPDATE [dbo].[QCheck_ActiveAssignmentArchive] SET [ArchiveDate] = dbo.ToUtc([ArchiveDate])
UPDATE [dbo].[QCheck_ActiveChecklistArchive] SET [DueTime] = dbo.ToUtc([DueTime]),[OrigDueTime] = dbo.ToUtc([OrigDueTime]),[ReminderDate] = dbo.ToUtc([ReminderDate]),[CompletedDate] = dbo.ToUtc([CompletedDate]),[ArchiveDate] = dbo.ToUtc([ArchiveDate])
UPDATE [dbo].[PriorityList_LateFee_Log_Bkup] SET [LateDate] = dbo.ToUtc([LateDate])

GO
ALTER   PROC [dbo].[QCheck_CreateSimple_part1]
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
	@DueTime int = NULL
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

	IF @DueTime IS NULL BEGIN
		SELECT @DueTime = duetime FROM QCheck_UserDefaultTimes WHERE UserID = @CreatedBy

		IF @DueTime IS NULL
			SELECT @DueTime = duetime from QCheck_UserDefaultTimes WHERE UserID = -1
	END

	SELECT @ReportID = reportID
	FROM QStatus_TaskTypes
	WHERE ID = @TaskType

	INSERT INTO QCheck_Checklists ([Name], Owner) VALUES (@Name, @CreatedBy)
	SELECT @ID = @@IDENTITY	

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

	EXEC QCheck_CreateInstance @NewInstanceID output, @ID, '', @CreatedBy

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
			@Activate = @Activate

	IF @DueDate <> ISNULL(@ReminderDate, @DueDate) BEGIN
	
		DECLARE @SoftDueOffsetDays INT
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

	DELETE @recordIds
	INSERT INTO @recordIds VALUES(@NewActiveID)
	EXEC dbo.Audit_Set @CreatedBy, @recordIds, 'ActiveChecklist', 3

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
	--If the task isn't going on every assignee's priority list, if Brandon is an assignee, put it on his.
	ELSE IF EXISTS (
			SELECT 'Y' from QCheck_Users u 
				JOIN QCheck_GroupMembership gm ON gm.UserID = u.ID AND gm.GroupID = @GroupID
			WHERE u.ID = 10
		) AND @NewActiveID IS NOT NULL
	BEGIN
		exec PriorityList_AddTask 10, @NewActiveID
	END
	
	-- rebuild cache
 EXEC QCheck_ChecklistControllersList_Refresh @ID
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
      
            SET @ScheduleID = @@IDENTITY
            SET @RowsUpdated = @@ROWCOUNT

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
                        OR TimeZone <> ISNULL(@TimeZone, TimeZone)
            )
            
            SET @RowsUpdated = @@ROWCOUNT

      END

      --EXEC QCheck_SetUpcomingInstance @InstanceID, @ScheduleID
      if @Activate = 1 exec QCheck_ActivateSchedule @InstanceID, @PrevFreqType


      SET NOCOUNT OFF

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
	  ,@url VARCHAR(8000) = dbo.GetWsUrl() + 'ConvertTimeFromUtc'
		
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
	
	  ,@comparedate datetime = @AsOfDate
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

	IF @AsOfDate IS NULL BEGIN
		IF @timeZone IS NULL BEGIN
			SET @AsOfDate = GETUTCDATE()
		END ELSE BEGIN
			-- work in the task Time Zone if one is specified
			SET @param = '
			{ 
				"date": "' + CONVERT(VARCHAR(20), GETUTCDATE(), 22) + '",
				"dstTz": "' + @timeZone + '"
			}'

			EXEC dbo.CallWebApi 
				@url = @url,
				@param = @param,
				@ResponseText = @result OUTPUT

			SET @result = SUBSTRING(@result, 7, LEN(@result) - 8)

			SET @AsOfDate = @result
		END

		SET @comparedate = @AsOfDate
	END

    -- one time schedule
    IF (@freqType = @ONCE) BEGIN
        -- this one is easy. we just concatenate the start date and the end time and voila. Converting to just the date because
        -- we're going to add the hours back in later.
        SET @DueDate = @firstDueDate
	END
    --daily schedule
    ELSE IF (@freqType = @DAILY) BEGIN
        --if we havent come to the time of day this checklist is due, we treat it as yesterday
        If (DatePart(hh, @compareDate)) + (DatePart(mi, @compareDate)/60.0) < @dueTime
            SET @compareDate = @compareDate - 1
                  
        SET @tmpInt = 0
        --find out how many times this has occurred since it started, add one,  and multiply by the number of days per occurance
        IF @compareDate > @firstDueDate
            SET @tmpInt = ((DateDiff(day, @firstDueDate, @compareDate)/@freqRecurrance) + 1)*@freqRecurrance
                  
        --add that to the start date, and we have the last time it was due
        SET @DueDate = DateAdd(day, @tmpInt, @firstDueDate)
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


                        --day of week for last due date
                        SET @DAYOFWEEK = DATEPART(dw,@DueDate)
      
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
                        
                        --get the min value that does not return a 0 bitwise
                        SELECT @totDaysFromNow = MIN(daysFromNow) 
                        FROM @tbldays 
                        WHERE @freqInterval & dayint > 0
                        
                        --add number of days to last start date
                        SET @DueDate = DateAdd(day, @totDaysFromNow, @DueDate)
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
      if @DueDate <= @firstDueDate or @AsOfDate <= @firstDueDate
            SET @DueDate = @firstDueDate


      --set time
      SET @DueDate = DateAdd(hh, @DueTime, @DueDate)

      
      --add minutes
      If @DueTime - cast(@DueTime as int) > 0
      BEGIN
            SET @DueDate = DATEADD(mi, 30, @DueDate)
      END

	  -- convert back to UTC time
	  IF @timeZone IS NOT NULL BEGIN
		SET @url = dbo.GetWsUrl() + 'ConvertTimeToUtc'
		SET @param = '
		{ 
			"date": "' + CONVERT(VARCHAR(20), @DueDate, 22) + '",
			"srcTz": "' + @timeZone + '"
		}'

		EXEC dbo.CallWebApi 
			@url = @url,
			@param = @param,
			@ResponseText = @result OUTPUT

		SET @result = SUBSTRING(@result, 7, LEN(@result) - 8)

		SET @DueDate = @result
	  END
                  
      DECLARE @DueDateOrig Datetime
      SET @DueDateOrig = @DueDate

      SET @RelativeDueDate = NULL

      
      --check for after lastDueDate
      If @DueDate > dateadd(day, 1, @lastDueDate) or  @DueDate < @AsOfDate or @DueDate < @firstDueDate 
            BEGIN
                  SET @DueDate = null
                  SET @RelativeDueDate = null
                  SET @DueDateOrig = null
            END

      --if its not a business day, skip it
      IF @busDayBehavior = 1 
      BEGIN 
            IF dbo.Util_IsOfficeDay(@DueDate) = 0 
            BEGIN
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

      If IsNull(@DueDate, 0) <>  IsNull(@DueDateOrig, 0) SET @RelativeDueDate = @DueDateOrig

END
GO