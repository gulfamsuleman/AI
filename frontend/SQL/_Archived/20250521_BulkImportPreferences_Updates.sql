CREATE OR ALTER proc [dbo].[QStatus_BulkImportPreferences_Set]
	@UserID int,
	@Assignee int,
	@Controller int,
	@Due int,
	@Report int,
	@Priority int,
	@Alert int = -1,
	@SoftDue int = -1
AS BEGIN

	UPDATE QStatus_BulkImportPreferences
		SET Assignee = @Assignee,
			Controller = @Controller,
			Due = @Due,
			Report = @Report,
			[Priority] = @Priority,
			SoftDue = @SoftDue
		WHERE UserID = @UserID
		
	IF @@ROWCOUNT = 0
	BEGIN
		INSERT INTO QStatus_BulkImportPreferences
		(UserID, Assignee, Controller, Due, Report, [Priority], SoftDue)
		SELECT @UserID, @Assignee, @Controller, @Due, @Report, @Priority, @SoftDue
	END

END

GO

CREATE OR ALTER proc [dbo].[QStatus_BulkImportPreferences_Get]
	@UserID int,
	@AssigneeVal int = -1
AS BEGIN

	DECLARE @Assignee int = -1, 
			@Controller int = -1,
			@Due int = -1,
			@Report int = -1,
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
	IF @Report = -1
	BEGIN
		SELECT 
			@ReportName = '',
			@SectionName = '' 

		--SELECT top 1 
		--	@Report = tt.ID
		--FROM 
		--	QStatus_Report r
		--INNER JOIN QCheck_GroupMembership gm1
		--	on gm1.GroupID = @AssigneeVal
		--INNER JOIN
		--	QStatus_GroupReport gr
		--ON
		--	gr.ReportID = r.ID
		--INNER JOIN
		--	QCheck_Groups g
		--ON
		--	g.ID = gr.GroupID
		--INNER JOIN
		--	QCheck_GroupMembership gm
		--ON
		--	gm.GroupID = g.ID
		--AND
		--	gm.UserID = gm1.UserID
		--INNER JOIN 
		--	QStatus_TaskTypes tt
		--ON
		--	tt.ReportID = r.ID
		--AND 
		--	tt.IsDeleted = 0
		--AND
		--	tt.NativeType = 0
		--WHERE 
		--	r.IsDeleted = 0
		--ORDER BY gr.defaultreport desc, r.ID, tt.displayOrder
	END
	ELSE
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

CREATE OR ALTER PROCEDURE [dbo].[Util_CreateComplexTaskBasedOnTemplate]
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
  @IsDefaultToAssignee BIT = 0
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
 if (isnull(@AssignedGroupID3, 0) > 0)
BEGIN
    EXEC QCheck_AddAssignedTo
        @InstanceID = @instanceID,
        @GroupID = @AssignedGroupID3,
        @AssignedBy = @AdminID,
        @Email = 0;

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