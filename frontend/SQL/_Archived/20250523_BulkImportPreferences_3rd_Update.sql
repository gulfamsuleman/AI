/* [QStatus_AutomationEmailPreferences_Get] */

ALTER proc [dbo].[QStatus_AutomationEmailPreferences_Get]
	@UserID int,
	@AssigneeVal int = -1
AS BEGIN

	DECLARE @Assignee int = -1, 
			@Controller int = -1,
			@Due int = -1,
			@ReportOrig int = -1,
			@Report int = -1,
			@Priority int = -1,
			@Alert int = -1,
			@SoftDue int = -1,
			@EChecklistPriority int = -1
			
	SELECT @Assignee=Assignee, 
			@Controller = Controller, 
			@Due = Due, 
			@Report = Report, 
			@ReportOrig = Report,
			@Priority = [Priority],
			@Alert = Alert,
			@SoftDue = SoftDue,
			@EChecklistPriority = EChecklistPriority
	FROM QStatus_AutomationEmailPreferences
	WHERE UserID = @UserID
	
	
	
	DECLARE @AssigneeName varchar(1000) = '',
			@ControllerName varchar(1000) = '',
			@ReportName varchar(1000) = ''
			
	IF @Assignee > -1
	BEGIN
		SELECT @AssigneeName = name from QCheck_Groups
		WHERE ID = @Assignee
	END
	
	IF @ControllerName > -1
	BEGIN
		SELECT @ControllerName = name from QCheck_Groups
		where ID = @Controller
	END
	
	--if it was not passed in, use the default
	IF @AssigneeVal = -1
	BEGIN
		SELECT @AssigneeVal = @Assignee
	END
	
	--if default not set, it will be the group id of the user who sent it
	IF @AssigneeVal = -1
	BEGIN
		SELECT @AssigneeVal = UserGroupID 
		FROM qstatus_usersupervisors
		WHERE UserID = @UserID
	END
	
	IF @Report = -1
	BEGIN
		SELECT top 1 
			@Report = tt.ID
		FROM 
			QStatus_Report r
		INNER JOIN QCheck_GroupMembership gm1
			on gm1.GroupID = @AssigneeVal
		INNER JOIN
			QStatus_GroupReport gr
		ON
			gr.ReportID = r.ID
		INNER JOIN
			QCheck_Groups g
		ON
			g.ID = gr.GroupID
		INNER JOIN
			QCheck_GroupMembership gm
		ON
			gm.GroupID = g.ID
		AND
			gm.UserID = gm1.UserID
		INNER JOIN 
			QStatus_TaskTypes tt
		ON
			tt.ReportID = r.ID
		AND 
			tt.IsDeleted = 0
		AND
			tt.NativeType = 0
		WHERE 
			r.IsDeleted = 0
		ORDER BY gr.defaultreport desc, r.ID, tt.displayOrder
	END
	
	-- OG (5/22/25): Changed from > -1 to > 0 to allow 0 to represent 'no report'
	If @Report > 0
	BEGIN
		select @ReportName = r.Name + ' - ' + tt.Description 
		from QStatus_TaskTypes tt
		inner join QStatus_Report r
			on tt.ReportID = r.id
		WHERE tt.ID = @Report
	END
		
	
	SELECT @Assignee as Assignee, 
			@Controller as Controller,
			@Due as Due,
			@Report as Report,
			@ReportOrig as ReportOrig,
			@Priority as [Priority],
			@AssigneeName as AssigneeName,
			@ControllerName as ControllerName,
			@ReportName as ReportName,
			@Alert as Alert,
			@SoftDue as SoftDue,
			@EChecklistPriority as EChecklistPriority
			 
End

GO

/* [Util_CreateComplexTaskBasedOnTemplate] */

ALTER PROCEDURE [dbo].[Util_CreateComplexTaskBasedOnTemplate]
 (
  @taskname varchar(500),
  @DueDate datetime,
  @controller1 varchar(100),
  @controller2 varchar(100) = '',
  @assignee1 varchar(100),
  @assignee2 varchar(100) = '',
  @assignee3 varchar(100) = '',
  @item2 varchar(1000) = '',
  @item3 varchar(1000) = '',
  @item4 varchar(1000) = '',
  @item5 varchar(1000) = '',
  @item6 varchar(1000) = '',
  @item7 varchar(1000) = '',
  @item8 varchar(1000) = '',
  @item9 varchar(1000) = '',
  @item10 varchar(1000) = '',
  @item11 varchar(1000) = '',
  @item12 varchar(1000) = '',
  @item13 varchar(1000) = '',
  @item14 varchar(1000) = '',
  @item15 varchar(1000) = '',
  @statusReportName varchar(100),
  @statusReportSection varchar(100),
  @tasktype int = 0,
  @softdue datetime = null,
  @location NVARCHAR(255) = NULL,
  @freqType INT = 0,
  @IsRecurring BIT = 0,
  @PriorityList BIT = 0,
  @Priority int = 0,
  @CreatorUserId int = 0,
  @IsDefaultToAssignee BIT = 0,
  @IsOnStatusReport BIT = 1
 )
AS
BEGIN
 Declare @newTaskID int
 Declare @instanceID int
 Declare @SupervisorID int
 Declare @SupervisorGroupID int
 Declare @DueTime int
 Declare @PrevFreqType int
 Declare @RowsUpdated int
 Declare @StatusReportId int
 DECLARE @statusReportName2 varchar(100) -- If Assignee 2 and defaulting to their status report
 DECLARE @statusReportSection2 varchar(100) -- If Assignee 2 and defaulting to their status report
 DECLARE @statusReportName3 varchar(100) -- If Assignee 3 and defaulting to their status report
 DECLARE @statusReportSection3 varchar(100) -- If Assignee 3 and defaulting to their status report
 DECLARE @tasktype2 int = 0
 DECLARE @tasktype3 int = 0
 DECLARE @AdminID int
 DECLARE @AppName NVARCHAR(50);

 if (@priority = 999) select @priority = 99 --999 is reserved for completed tasks
 
 --midnight by default - set to end of day time that's defaulted for this company
 if datepart(hour, @DueDate) = 0
 begin
 	select @DueDate = dateadd(hour, duetime, @DueDate)
 	from QCheck_UserDefaultTimes
 	where UserID = -1
 end

 if datepart(hour, @softdue) = 0
 begin
 	select @softdue = dateadd(hour, duetime, @softdue)
 	from QCheck_UserDefaultTimes
 	where UserID = -1
 end


 SELECT @AppName = AppName from QCheck_AppSettings; --THIS IS USED FOR ERROR MESSAGING


 declare @assignedgroupid1 int, @assignedgroupid2 int, @assignedgroupid3 int, @controllergroupid1 int, @controllergroupid2 int
 
 --BEGIN CHECKS FOR ASSIGNEES AND CONTROLLERS HERE
select @assignedgroupid1 = id from qcheck_groups where name = @assignee1
 IF @assignedgroupid1 IS NULL
 BEGIN
 	RAISERROR('The specified Assignee1 does not match any group name in %s', 16, 1, @AppName)
 	RETURN
 END

IF @assignee2 <> ''
BEGIN
	select @assignedgroupid2 = id from qcheck_groups where name = @assignee2
	IF @assignedgroupid2 IS NULL
		BEGIN
			RAISERROR('The specified Assignee2 does not match any group name in %s', 16, 1, @AppName)
			RETURN
		END
END
IF @assignee3 <> ''
BEGIN
	select @assignedgroupid3 = id from qcheck_groups where name = @assignee3
	IF @assignedgroupid3 IS NULL
		BEGIN
			RAISERROR('The specified Assignee3 does not match any group name in %s', 16, 1, @AppName)
			RETURN
		END
END
select @controllergroupid1 = id from qcheck_groups where name = @controller1
IF @controllergroupid1 IS NULL
BEGIN
	RAISERROR('The specified Controller1 does not match any group name in %s', 16, 1, @AppName)
	RETURN
END
IF @controller2 <> ''
BEGIN
	select @controllergroupid2 = id from qcheck_groups where name = @controller2
	IF @controllergroupid2 IS NULL
		BEGIN
			RAISERROR('The specified Controller2 does not match any group name in %s', 16, 1, @AppName)
			RETURN
		END
END

/* Get reports/sections if defaulting to assignees */
IF @IsDefaultToAssignee = 1
BEGIN
    -- @assignedgroupid1
    IF @assignedgroupid1 IS NOT NULL AND @assignedgroupid1 > 0
    BEGIN
        SELECT TOP 1 
            @statusReportName = r.Name,
            @statusReportSection = tt.Description
        FROM 
            QStatus_Report r
            INNER JOIN QCheck_GroupMembership gm1 ON gm1.GroupID = @assignedgroupid1
            INNER JOIN QStatus_GroupReport gr ON gr.ReportID = r.ID
            INNER JOIN QCheck_Groups g ON g.ID = gr.GroupID
            INNER JOIN QCheck_GroupMembership gm ON gm.GroupID = g.ID AND gm.UserID = gm1.UserID
            INNER JOIN QStatus_TaskTypes tt ON tt.ReportID = r.ID AND tt.IsDeleted = 0 AND tt.NativeType = 0
        WHERE 
            r.IsDeleted = 0
        ORDER BY gr.defaultreport DESC, r.ID, tt.displayOrder;
    END

    -- @assignedgroupid2
    IF @assignedgroupid2 IS NOT NULL AND @assignedgroupid2 > 0
    BEGIN
        SELECT TOP 1 
            @statusReportName2 = r.Name,
            @statusReportSection2 = tt.Description
        FROM 
            QStatus_Report r
            INNER JOIN QCheck_GroupMembership gm1 ON gm1.GroupID = @assignedgroupid2
            INNER JOIN QStatus_GroupReport gr ON gr.ReportID = r.ID
            INNER JOIN QCheck_Groups g ON g.ID = gr.GroupID
            INNER JOIN QCheck_GroupMembership gm ON gm.GroupID = g.ID AND gm.UserID = gm1.UserID
            INNER JOIN QStatus_TaskTypes tt ON tt.ReportID = r.ID AND tt.IsDeleted = 0 AND tt.NativeType = 0
        WHERE 
            r.IsDeleted = 0
        ORDER BY gr.defaultreport DESC, r.ID, tt.displayOrder;
    END

    -- @assignedgroupid3
    IF @assignedgroupid3 IS NOT NULL AND @assignedgroupid3 > 0
    BEGIN
        SELECT TOP 1 
            @statusReportName3 = r.Name,
            @statusReportSection3 = tt.Description
        FROM 
            QStatus_Report r
            INNER JOIN QCheck_GroupMembership gm1 ON gm1.GroupID = @assignedgroupid3
            INNER JOIN QStatus_GroupReport gr ON gr.ReportID = r.ID
            INNER JOIN QCheck_Groups g ON g.ID = gr.GroupID
            INNER JOIN QCheck_GroupMembership gm ON gm.GroupID = g.ID AND gm.UserID = gm1.UserID
            INNER JOIN QStatus_TaskTypes tt ON tt.ReportID = r.ID AND tt.IsDeleted = 0 AND tt.NativeType = 0
        WHERE 
            r.IsDeleted = 0
        ORDER BY gr.defaultreport DESC, r.ID, tt.displayOrder;
    END
END

IF @IsOnStatusReport  = 1
BEGIN
	 SELECT @StatusReportId = id from QStatus_Report where Name = @statusreportname;
	 IF @StatusReportId IS NULL
	BEGIN
		RAISERROR('The specified status report name does not match any status report in %s', 16, 1, @AppName)
		RETURN
	END
	
	 SELECT @tasktype = tt.id
	 from qstatus_report r
		inner join qstatus_tasktypes tt
			on r.isdeleted = 0
			and tt.isdeleted = 0 
			and r.id = tt.reportid
			and r.name = @statusReportName
			and tt.description = @statusReportSection
END

DECLARE @newinstanceid INT
DECLARE @newactiveid INT
	select @AdminID = ID from QCheck_Groups where Name = @controller1

IF @AdminID IS NULL
BEGIN
	RAISERROR('The specified Controller1 does not match any user in %s', 16, 1, @AppName)
	RETURN
END  

exec [QCheck_CreateSimple_part1]
	@ID = @newTaskID OUTPUT,
	@Name = @taskname, 
	@DueDate = @DueDate,
	@CreatedBy = @CreatorUserId,
	@TaskType = @taskType,
	@PrevFreqType = @freqType,
	@NewInstanceID = @newinstanceid OUTPUT,
	@NewActiveID = @newactiveid OUTPUT,
	@GroupID = @assignedgroupid1,
	@Activate = 1,
	@IsReminder = 0,
	@ReminderDate = @softdue,
	--@AddToPriorityList = @PriorityList, -- Can't rely on this, it does nothing with Priority #
	--@Priority = @Priority,
	@Timezone = @location, -- Only used in CreateSimple
	@EmailAssignees = 0 -- Only used in CreateSimple


 update qcheck_items
 set [text] = @taskname
 where checklistid = @newTaskID
 if len(@item2) >0
 begin
  exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item2, @URL = ''
 end
 if len(@item3) >0
 begin
  exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item3, @URL = ''
 end
 if len(@item4) >0
 begin
  exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item4, @URL = ''
 end
 if len(@item5) >0
 begin
  exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item5, @URL = ''
 end
 if len(@item6) >0
 begin
  exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item6, @URL = ''
 end
 if len(@item7) >0
 begin
  exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item7, @URL = ''
 end
 if len(@item8) >0
 begin
  exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item8, @URL = ''
 end
 if len(@item9) >0
 begin
  exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item9, @URL = ''
 end
 if len(@item10) >0
 begin
  exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item10, @URL = ''
 end
 if len(@item11) >0
 begin
  exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item11, @URL = ''
 end
 if len(@item12) >0
 begin
  exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item12, @URL = ''
 end
 if len(@item13) >0
 begin
  exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item13, @URL = ''
 end
 if len(@item14) >0
 begin
  exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item14, @URL = ''
 end
 if len(@item15) >0
 begin
  exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item15, @URL = ''
 end
 SELECT @instanceID = ID FROM QCheck_ChecklistInstances where ChecklistID = @newTaskID
  
 if (isnull(@AssignedGroupID1, 0) > 0)
 begin
  exec QCheck_AddAssignedTo
   @InstanceID = @instanceID,
   @GroupID = @AssignedGroupID1,
   @AssignedBy = @AdminID,
   @Email = 0
 end
 if (isnull(@AssignedGroupID2, 0) > 0)
BEGIN
    EXEC QCheck_AddAssignedTo
        @InstanceID = @instanceID,
        @GroupID = @AssignedGroupID2,
        @AssignedBy = @AdminID,
        @Email = 0;
	IF @IsOnStatusReport = 1
	BEGIN
		SELECT @tasktype2 = tt.id
		FROM qstatus_report r
		INNER JOIN qstatus_tasktypes tt
			ON r.id = tt.reportid
		WHERE
			r.isdeleted = 0
			AND tt.isdeleted = 0
			AND r.name = @statusReportName2
			AND tt.description = @statusReportSection2;

		-- Add previously created task to their status report
		IF @tasktype2 IS NOT NULL AND @tasktype2 > 0
		BEGIN
			INSERT INTO [dbo].[QStatus_InstanceTaskType]
				([InstanceID], [TaskType])
			VALUES
				(@NewInstanceID, @tasktype2);
		END
	END
END
 if (isnull(@AssignedGroupID3, 0) > 0)
BEGIN
    EXEC QCheck_AddAssignedTo
        @InstanceID = @instanceID,
        @GroupID = @AssignedGroupID3,
        @AssignedBy = @AdminID,
        @Email = 0;

	IF @IsOnStatusReport = 1
	BEGIN
		SELECT @tasktype3 = tt.id
		FROM qstatus_report r
		INNER JOIN qstatus_tasktypes tt
			ON r.id = tt.reportid
		WHERE
			r.isdeleted = 0
			AND tt.isdeleted = 0
			AND r.name = @statusReportName3
			AND tt.description = @statusReportSection3;

		-- Add previously created task to their status report
		IF @tasktype3 IS NOT NULL AND @tasktype3 > 0
		BEGIN
			INSERT INTO [dbo].[QStatus_InstanceTaskType]
				([InstanceID], [TaskType])
			VALUES
				(@NewInstanceID, @tasktype3);
		END
	END
END

 declare @SoftDueOffsetDays int = null
 if (@softdue is not null)
 begin
  if (@softdue < @duedate)
  begin
   select @SoftDueOffsetDays = datediff(day, @softdue, @duedate)
  end
 end

 UPDATE QCheck_ChecklistManagers
  SET isdeleted = 1
  where ChecklistID = @newTaskID
 INSERT INTO QCheck_ChecklistManagers
  select @controllergroupid1, @newTaskID, 0, GetUtcDate()
  where isnull(@controllergroupid1, 0) > 0
 INSERT INTO QCheck_ChecklistManagers
  select @controllergroupid2, @newTaskID, 0, GetUtcDate()
  where isnull(@controllergroupid2, 0) > 0
 declare @itt int


IF (ISNULL(@assignee1, '') = '' AND ISNULL(@assignee2, '') = '' AND ISNULL(@assignee3, '') = '')
BEGIN
    IF @CreatorUserId > 0
    BEGIN
        EXEC [PriorityList_AddTask] @UserID = @CreatorUserId, @ActiveChecklistID = @NewActiveID, @Priority = @Priority, @ListID = NULL
    END
END
ELSE
BEGIN
    IF @Priority > 0
    BEGIN
        IF ISNULL(@assignee1, '') <> ''
        BEGIN
            EXEC [PriorityList_AddTask_ForGroup] @CreatorUserId, @assignedgroupid1, @NewActiveID, @Priority
        END
        IF ISNULL(@assignee2, '') <> ''
        BEGIN
            EXEC [PriorityList_AddTask_ForGroup] @CreatorUserId, @assignedgroupid2, @NewActiveID, @Priority
        END
        IF ISNULL(@assignee3, '') <> ''
        BEGIN
            EXEC [PriorityList_AddTask_ForGroup] @CreatorUserId, @assignedgroupid3, @NewActiveID, @Priority
        END
    END
END

END

GO

/* [QStatus_BulkImportPreferences] */

ALTER TABLE [dbo].[QStatus_BulkImportPreferences]
ALTER COLUMN [Report] [int] NULL;
GO

/* [QStatus_BulkImportPreferences_Get] */
ALTER proc [dbo].[QStatus_BulkImportPreferences_Get]
	@UserID int,
	@AssigneeVal int = -1
AS BEGIN

	DECLARE @Assignee int = -1, 
			@Controller int = -1,
			@Due int = -1,
			@Report int = null,
			@Priority int = -1,
			@SoftDue int = -1
			
	SELECT @Assignee=Assignee, 
			@Controller = Controller, 
			@Due = Due, 
			@Report = Report, 
			@Priority = [Priority],
			@SoftDue = SoftDue
	FROM QStatus_BulkImportPreferences
	WHERE UserID = @UserID

	DECLARE @AssigneeName varchar(1000) = '',
			@ControllerName varchar(1000) = '',
			@ReportName varchar(1000) = '',
			@SectionName varchar(1000) = ''

	-- Assignee
	IF @Assignee = -1
	BEGIN
		SET @Assignee = @UserID
		SELECT @AssigneeName = FullName FROM QCheck_Users WHERE ID = @UserID
	END
	ELSE
	BEGIN
		SELECT @AssigneeName = name FROM QCheck_Groups WHERE ID = @Assignee
	END

	-- Controller logic
	IF @Controller = -1
	BEGIN
		SET @Controller = @UserID
		SELECT @ControllerName = FullName FROM QCheck_Users WHERE ID = @UserID
	END
	ELSE
	BEGIN
		SELECT @ControllerName = name FROM QCheck_Groups WHERE ID = @Controller
	END	

	--if it was not passed in, use the default
	IF @AssigneeVal = -1
	BEGIN
		SELECT @AssigneeVal = @Assignee
	END
	
	SELECT @AssigneeVal = UserGroupID 
	FROM qstatus_usersupervisors
	WHERE UserID = @UserID
	
	-- Don't set Report Name and Section Name if preference is assignee's report as there could be multiple assignees
	IF @Report IS NOT NULL AND @Report <> -1
	BEGIN
		SELECT 
			@ReportName = r.Name,
			@SectionName = tt.Description 
		FROM QStatus_TaskTypes tt
		inner join QStatus_Report r
			on tt.ReportID = r.id
		WHERE tt.ID = @Report		
	END

	SELECT @Assignee as Assignee, 
			@Controller as Controller,
			@Due as Due,
			@Report as Report,
			@Priority as [Priority],
			@AssigneeName as AssigneeName,
			@ControllerName as ControllerName,
			@ReportName as ReportName,
			@SectionName as SectionName,
			@SoftDue as SoftDue
			 
End

GO

/* [QStatus_AutomationEmailPreferences] */
ALTER TABLE [dbo].[QStatus_AutomationEmailPreferences]
ALTER COLUMN [Report] [int] NULL;
GO

ALTER PROCEDURE [dbo].[Util_CreateEmailTaskWithPriority] (
	@TaskName VARCHAR(1000),
	@CreatedBy int,
	@Assignee int,
	@Controller int,
	@DueDate DATETIME, 
	@Section int = null,
	@Priority int,
	@PriorityUser int = null,
	@Comments varchar(1500) = null,
	@Alert DATETIME = null,
	@SoftDue DATETIME = null,
	@Email bit = 1,
	@TemplateName VARCHAR(500) = ''
) AS
BEGIN
	SET NOCOUNT ON
	if (@priority = 999) select @priority = 99 --999 is reserved for completed tasks

	--Get creating user's time zone
	DECLARE @TimeZone varchar(255)
	SELECT @TimeZone = ISNULL(TimeZoneOverride, LastTimeZone)
	FROM QCheck_Users
	WHERE ID = @CreatedBy
	
	insert into qcheck_emailtasks (TaskName, CreatedBy, CreatedDt)
	select @TaskName, @CreatedBy, GetUtcDate()

	--if this is a QPT for an email2db template, apply the correct section and information
	
	  declare @autosectionID int, @addcreatednote bit = 0

	  select @autosectionID = sectionID, @addcreatednote = creatednote from [Util_Email2DBTasks]
	  where @taskname like triggername + '%'

	  if @autosectionID is not null
	  begin
		if isnull(@addcreatednote, 0) = 1
		Begin
			select @taskname = @taskname + ' - from ' + email + ' - Sent on ' + convert(varchar, dbo.[ConvertTimeFromUtc](getutcdate(), @TimeZone), 101)
			from qcheck_users 
			where id = @createdby 
		End

		select @Section = @autosectionID
	  end

	--midnight by default - set to end of day time that's defaulted for this company
	if datepart(hour, @DueDate) = 0
	begin
		select @DueDate = dateadd(hour, duetime, @DueDate)
		from QCheck_UserDefaultTimes
		where UserID = -1
	end
	-- Get app configuration
	DECLARE @AppURL VARCHAR(50), @ImagesURL VARCHAR(50), @ExternalURL VARCHAR(50), @BaseDomain VARCHAR(50), @FromAddress VARCHAR(50), @AppName VARCHAR(50), @GradingAddress VARCHAR(50), @AutomationAddress VARCHAR(50), @DeveloperAddress VARCHAR(50), @ITAddress VARCHAR(50), @MailServer VARCHAR(50)
	SELECT @AppURL = AppURL, @ImagesURL = ImagesURL, @ExternalURL = ExternalURL, @BaseDomain = BaseDomain, @FromAddress = FromAddress, @Appname = AppName, @GradingAddress = GradingAddress, @AutomationAddress = AutomationAddress, @DeveloperAddress = DeveloperAddress, @ITAddress = ITAddress, @MailServer = MailServer FROM QCheck_AppSettings WHERE ID = 1
	DECLARE 
		@CallingProgram varchar(50),
		@ID int,
		@ReportID int,
		@TaskType int,
		@PrevFreqType int,
		@RowsUpdated int,
		@NewInstanceID int,
		@NewActiveID int,
		@scheduleID int,
		@errorCode int,
		@errorMsg varchar(500),
		@nagBeforeDays int,
		@nagTime int

	SELECT @CallingProgram = @AppName + ' Tasks Email'

-- =======================================================
-- Initialize and validate inputs
-- =======================================================
	SET @errorCode = 0
	SET @errorMsg = ''
	
	--If(_Util.dbo.IsOfficeDay(@DueDate)=0)--added by venkat 09/07/2018
	--Begin
	--set @DueDate=_Util.dbo.NextOfficeDayMaintainTime(@DueDate)
	--End
	IF @SoftDue IS NULL SET @SoftDue = @DueDate
	-- Make sure a calling program was passed in
	IF @ErrorCode = 0 BEGIN
		IF LEN(@CallingProgram) = 0 BEGIN
			SET @ErrorCode = -1000
			SET @ErrorMsg = 'Zero-length calling program was given'
		END
	END
	-- Validate the task name
	IF @ErrorCode = 0 BEGIN
		IF LEN(@TaskName) = 0 BEGIN
			SET @ErrorCode = -1001
			SET @ErrorMsg = 'Zero-length task name was given'
		END
	END
	-- Look up the status report, if one was passed in
	-- @Section = null signifies it isn't meant to be shown on a report
	IF @ErrorCode = 0 AND @Section <> null BEGIN
		IF @Section = 0 BEGIN
			--find a section for the group specified
			SELECT top 1 
				@TaskType = tt.ID
			FROM 
				QStatus_Report r
				INNER JOIN QCheck_GroupMembership gm1
					on gm1.GroupID = @Assignee
				INNER JOIN QStatus_GroupReport gr
					ON gr.ReportID = r.ID
				INNER JOIN QCheck_Groups g
					ON g.ID = gr.GroupID
				INNER JOIN QCheck_GroupMembership gm
					ON gm.GroupID = g.ID
					AND gm.UserID = gm1.UserID
				INNER JOIN QStatus_TaskTypes tt
					ON tt.ReportID = r.ID
					AND tt.IsDeleted = 0
					AND tt.NativeType = 0
			WHERE 
				r.IsDeleted = 0
			ORDER BY gr.defaultreport desc, r.ID, tt.displayOrder
		END ELSE BEGIN
			SELECT @TaskType = @Section
		END
		
		IF @TaskType is not null BEGIN
			SELECT @ReportID = ReportID
			FROM QStatus_TaskTypes
			WHERE ID = @TaskType
			IF @ReportID IS NULL BEGIN
				SET @ErrorCode = -1004
				SET @ErrorMsg = 'Could not find status report'
			END
		END
	END
-- =======================================================
-- Set up the checklist
-- =======================================================
	-- Create the task
	IF @ErrorCode = 0 BEGIN
		/*
		EXEC dbo.QCheck_CreateSimple_part1 @ID, @TaskName, 1, @DueDate, @CreatedBy, @TaskType, @PrevFreqType OUTPUT, @RowsUpdated OUTPUT, @NewInstanceID OUTPUT, @NewActiveID OUTPUT, @assignee, 1, 0, @SoftDue			
		SET @errorCode = @@ERROR
		IF @ErrorCode <> 0 SET @errorMsg = 'QCheck_CreateSimple_part1 ' + cast(@ID as varchar) + ', ' + @TaskName + ', ' + cast(@DueDate as varchar) + ', ' + @CreatedBy + ', ' + @TaskType + ', assignedTo = ' + @assignee
		*/
		
		/*** LOGIC FROM QCheck_CreateSimple_Part1 with a fix for the due time ***/
		DECLARE @ReminderDate DATETIME
		SET @ReminderDate = @SoftDue
		DECLARE @UserID int
		DECLARE @FolderID int
		DECLARE @FolderName varchar(50)
		DECLARE @PrevSchedule bit
		
		SET @PrevSchedule = 0
		SET @ReportID = 0

		IF @Section <> NULL
		BEGIN
			SELECT @ReportID = reportID
			FROM
				QStatus_TaskTypes
			WHERE ID = @TaskType
		END
		INSERT INTO QCheck_Checklists
		([Name], Owner)
		VALUES
		(@TaskName, @CreatedBy)
		SELECT @ID = @@IDENTITY	
		-- Creator is the controller
		DECLARE @ControllerGroupID int
		SELECT @ControllerGroupID = ID
		FROM QCheck_Groups
		WHERE owner = @CreatedBy
		AND SingleMemberGroup = 1
		INSERT INTO QCheck_ChecklistManagers
		(ChecklistID, ManagerGroupID)
		VALUES (@ID, @ControllerGroupID)
		if len(@TemplateName) > 0
		begin
			insert into QCheck_Items ([ChecklistID], [SequenceNum], [ItemTypeID], [Text], [URL])
			select @ID, i.[SequenceNum], i.[ItemTypeID], i.[Text], i.[URL]
			from QCheck_Items i
			cross apply
				(
					select top 1 ID from QCheck_Checklists where name = @TemplateName and isdeleted = 0
					order by ID asc
				) cFirst
			inner join QCheck_Checklists c
				on i.checklistid = c.id
				and c.ID = cFirst.ID
				and i.isdeleted = 0
		end
		
		if not exists (select 1 from qcheck_items where checklistid = @ID)
		begin
			EXEC QCheck_AddItem @ID, null, 1, @TaskName, ''
		end
		EXEC QCheck_CreateInstance @NewInstanceID output, @ID, '', @CreatedBy
		EXEC QCheck_AddAssignedTo @NewInstanceID, @assignee, @CreatedBy, @Email
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

	
				
		DECLARE @DueTime INT = DATEPART(HOUR, @DueDate)
		EXEC QCheck_UpdateSchedule_part1 
				@InstanceID = @NewInstanceID, 
				@firstDueDate = @DueDate,
				@freqType = 1, 
				@dueTime = @DueTime,
				@PrevFreqType = @PrevFreqType output,
				@RowsUpdated = @RowsUpdated output,
				@Activate = 1,
				@TimeZone = @TimeZone
				--@busDayBehavior=3--added by venkat for testing

		SELECT @NewActiveID = ID
		FROM QCheck_ActiveChecklists
		WHERE InstanceID = @NewInstanceID
		-- Set the reminder date to whatever was passed in, if it's not past the due time
		UPDATE QCheck_ActiveChecklists
		SET ReminderDate = @ReminderDate
		WHERE 
			[ID] = @NewActiveID
			AND @ReminderDate <= DueTime
		IF @TaskType IS NOT NULL BEGIN
			DECLARE @NewTaskTypeID int
			--don't use @Priority here - that value's intended for priority lists. Default to priority 1
			EXEC QCheck_AddInstanceTaskType @NewInstanceID, @TaskType, 1, @NewTaskTypeID OUTPUT
		END      
		
		-- rebuild cache
		EXEC QCheck_ChecklistControllersList_Refresh @ID
		
		/*** END LOGIC FROM QCheck_CreateSimple_Part1 with a fix for the due time ***/
	END
	
	-- Make sure the deadline is right--for some reason if you pass in 5pm, the task is due at 6pm.
	IF @ErrorCode = 0 BEGIN
		UPDATE QCheck_ActiveChecklists SET 
			DueTime = dbo.ConvertTimeToUtc(@DueDate, @TimeZone), 
			OrigDueTime = dbo.ConvertTimeToUtc(@DueDate, @TimeZone)
		WHERE ID = @NewActiveID
	END
	IF @ErrorCode = 0 BEGIN
		
		if len(isnull(ltrim(rtrim(@comments)), '')) > 0
		begin
			declare @NewID int,
				@initials varchar(100),
				@fn varchar(50)
			exec QStatus_CreateNewComment @NewActiveID, @CreatedBy, @comments, @NewID, @initials, @fn
		end

		IF @reportID IS NOT NULL AND @reportID <> 0
		BEGIN
			UPDATE qstatus_report SET isdirty = 1 WHERE id = @reportID
		END
	ENd
	-- Make the assigned group a controller on the task
	IF @errorCode = 0
	BEGIN
		UPDATE QCheck_ChecklistManagers
		SET ManagerGroupID = @Controller
		WHERE ChecklistID = (SELECT ChecklistID FROM QCheck_ChecklistInstances WHERE ID = @NewInstanceID)
		
		SET @errorCode = @@ERROR
		IF @ErrorCode <> 0 SET @errorMsg = 'UPDATE QCheck_ChecklistManagers SET ManagerGroupID = ' + CAST(@assignee as varchar) + ' WHERE ChecklistID = (SELECT ChecklistID FROM QCheck_ChecklistInstances WHERE ID = ' + CAST(@NewInstanceID AS varchar) + ')'
	END
	
	-- ADD To priority lists
	IF @errorCode = 0
	BEGIN
		IF @PriorityUser > 0
		BEGIN	
			exec [PriorityList_AddTask] @UserID = @PriorityUser, @ActiveChecklistID = @NewActiveID, @Priority = @Priority, @ListID = null
			SET @errorCode = @@ERROR
			IF @ErrorCode <> 0 SET @errorMsg = 'ADD TO PRIORITIES'
		END	
		ELSE
		BEGIN
			IF @Priority > 0
			BEGIN
				exec [PriorityList_AddTask_ForGroup] @CreatedBy, @Assignee, @NewActiveID, @Priority
				SET @errorCode = @@ERROR
				IF @ErrorCode <> 0 SET @errorMsg = 'ADD TO PRIORITIES'
			END	
			
		END
	END
	
	-- Create a reminder
	IF @Alert IS NOT NULL BEGIN
		SET @nagBeforeDays = ABS(DATEDIFF(DAY, @DueDate, @Alert))
		SET @nagTime = DATEPART(HOUR, @Alert)
		EXEC QCheck_AddReminder	@NewInstanceID, @nagBeforeDays, @nagTime
	END
	
	
-- =======================================================
-- Alert on any errors
-- =======================================================
	IF @errorCode <> 0
	BEGIN
		DECLARE @msg varchar(5000)
		DECLARE @MailSubject VARCHAR(1000)
		SET @MailSubject = @AppName + ' Automated Task Creation Error'
		SET @msg = 'Calling Program: ' + @CallingProgram + '<br/><br/>Error Number: ' + cast(@errorCode AS varchar) + '<br/><br/>' + @errorMsg
		EXEC XPSendEmail
		    @FROM       = @FromAddress,
		    @FROM_NAME  = 'SQLMail',
		    @TO         = @DeveloperAddress,
		    @subject    = @MailSubject,
		    @message    = @msg,
		    @type       = 'text/html',
		    @server     = @MailServer
		RAISERROR ('Unable to create task', 16, 1)
	END
	ELSE
	BEGIN
		SELECT @AppURL = appurl from qcheck_appsettings s
		inner join qcheck_users u
		on s.ID = u.App
		WHERE u.ID = @CreatedBy
		if @ReportID is null OR @ReportID = 0
		begin
			select @AppURL as appUrl, @NewInstanceID as NewInstanceID
		end
		else
		begin
			select @AppURL + '/MyStatus.aspx?reportID=' + convert(varchar(10), @reportId) + '&taskID=' + convert(varchar(10), @NewActiveID)  as appUrl, @NewInstanceID as NewInstanceID
		
		end
	END	
	
	SET NOCOUNT OFF
END

GO