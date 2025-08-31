
GO
/****** Object:  StoredProcedure [dbo].[Util_CreateComplexTaskBasedOnTemplate]    Script Date: 11/21/2024 4:11:30 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
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
  @location NVARCHAR(255) = NULL
 )
AS
BEGIN
 Declare @newTaskID int
 Declare @instanceID int
 Declare @SupervisorID int
 Declare @SupervisorGroupID int
 Declare @DueTime float
 Declare @PrevFreqType int
 Declare @RowsUpdated int
 Declare @StatusReportId int
 DECLARE @AdminID int
 SELECT @DueTime = 19
 DECLARE @AppName NVARCHAR(50);
 
 
 SELECT @AppName = AppName from QCheck_AppSettings; --THIS IS USED FOR ERROR MESSAGING
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
 select @AdminID = ID from QCheck_Users where fullname = @controller1
IF @AdminID IS NULL
BEGIN
	RAISERROR('The specified Controller1 does not match any user in %s', 16, 1, @AppName)
	RETURN
END  
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
IF @assignee2 <> ''
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
exec [QCheck_CreateSimple_part1]
	@ID = @newTaskID OUTPUT,
	@Name = @taskname, 
	@DueDate = @DueDate,
	@CreatedBy = @AdminID,
	@TaskType = @taskType,
	@NewInstanceID = @newinstanceid OUTPUT,
	@NewActiveID = @newactiveid OUTPUT,
	@GroupID = @assignedgroupid1,
	@Activate = 1,
	@IsReminder = 0,
	@ReminderDate = null,
	@AddToPriorityList = 0,
	@DueTime = 19,
	@Timezone = @location
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
 begin
  exec QCheck_AddAssignedTo
   @InstanceID = @instanceID,
   @GroupID = @AssignedGroupID2,
   @AssignedBy = @AdminID,
   @Email = 0
 end
 if (isnull(@AssignedGroupID3, 0) > 0)
 begin
  exec QCheck_AddAssignedTo
   @InstanceID = @instanceID,
   @GroupID = @AssignedGroupID3,
   @AssignedBy = @AdminID,
   @Email = 0
 end
 declare @SoftDueOffsetDays int = null
 if (@softdue is not null)
 begin
  if (@softdue < @duedate)
  begin
   select @SoftDueOffsetDays = datediff(day, @softdue, @duedate)
  end
 end
 --EXEC QCheck_UpdateSchedule_part1 
 -- @InstanceID = @instanceID, 
 -- @firstDueDate = @DueDate,
 -- @freqType = 1, 
 -- @dueTime = @DueTime,
 -- @PrevFreqType = @PrevFreqType output,
 -- @RowsUpdated = @RowsUpdated output,
 -- @Activate = 1,
 -- @SoftDueOffsetDays = @SoftDueOffsetDays
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
 --if @tasktype > 0
 --begin
 -- exec QCheck_AddInstanceTaskType @InstanceID = @instanceID,@TaskType = @tasktype, @Priority = 1,@ID =@itt output
 --end
END
 


GO
/****** Object:  StoredProcedure [dbo].[QCheck_CreateTaskThroughApi]    Script Date: 11/21/2024 4:15:22 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[QCheck_CreateTaskThroughApi] (
	@TaskName NVARCHAR(1000),
	@Assignees NVARCHAR(1000),
	@Controller NVARCHAR(1000) = NULL,
	@DueDate DATETIME = NULL,
	@ReportSectionId INT = NULL,
	@Location NVARCHAR(255) = NULL,
	@DueTime INT = 19,
	@NewActiveID int output
) AS

	DECLARE 
		@ChecklistID INT,
		@SoftDue datetime,
		@CreatedBy int,
		@ReportID int,
		@TaskType int = NULL,
		@PrevFreqType int,
		@RowsUpdated int,
		@NewInstanceID int,
		@scheduleID int,
		@traderQPUserID int,
		@controlledBy int,
		@errorCode int,
		@errorMsg varchar(500),
		@uniqueTaskName bit

  DECLARE @AppName NVARCHAR(50);
 
  SELECT @AppName = AppName from QCheck_AppSettings; --THIS IS USED FOR ERROR MESSAGING

	---- Due in 1 days by default

	IF @DueDate IS NOT NULL
	BEGIN 
		IF @DueDate < GETUTCDATE() OR @SoftDue < GETUTCDATE()
		BEGIN
			RAISERROR('Due date and soft due date must be a future date', 16, 1, @AppName)
			RETURN
		END
	END 
	ELSE IF @DueDate IS NULL
	BEGIN 
	SET @SoftDue = DATEADD(HOUR, @DueTime - 1, GETUTCDATE())
	SET @DueDate = DATEADD(DAY, 1, GETUTCDATE())
	END

	CREATE TABLE #Assignees(
		Name NVARCHAR(30)
);

INSERT INTO #Assignees (Name) SELECT UserName.c from dbo.Util_fn_List_To_Table(@assignees, ',') as UserName;

	SET @errorCode = 0
	SET @errorMsg = ''

	CREATE TABLE #AssigneeIDs(
		ID INT
	);
	
	INSERT INTO #AssigneeIDs (ID) SELECT DISTINCT ID
	FROM QCheck_Groups
	WHERE Name IN (SELECT Name fROM #Assignees)

	DECLARE @tempAssigneeCount INT 

	SELECT @tempAssigneeCount = COUNT(ID) FROM #AssigneeIDs

	IF @tempAssigneeCount = 0 
	BEGIN
		RAISERROR('The specified Assignee names do not match any in %s', 16, 1, @AppName)
		RETURN
	END

	DECLARE @assignedTo INT = (SELECT TOP (1) ID FROM #AssigneeIDs)

	IF @Controller IS NOT NULL AND LEN(@Controller) > 0
	 BEGIN
	SELECT @controlledBy = ID
	FROM QCheck_Groups
	WHERE Name = @Controller

	IF @controlledBy IS NULL
	BEGIN
		RAISERROR('The specified Controller user name does not match any in %s', 16, 1, @AppName)
		RETURN
	END
	END
	ELSE 
	BEGIN
	 SELECT @ControlledBy = @AssignedTo
	 END

	EXEC QCheck_DuplicateNameCheck @Name = @TaskName, @UserID = 0, @OKToUse = @UniqueTaskName OUTPUT

	if @UniqueTaskName = 0
	BEGIN
		RAISERROR('Task with the provided name already exists and is already assigned to selected group', 16, 1)
		RETURN
	END

	EXEC dbo.QCheck_CreateSimple_part1 @ChecklistID OUTPUT, @TaskName, 1, @DueDate, 0, @ReportSectionId, 
		@PrevFreqType OUTPUT, @RowsUpdated OUTPUT, @NewInstanceID OUTPUT, @NewActiveID OUTPUT, @assignedTo, 1, 1, NULL, 0, @DueTime, @Location

	DECLARE @nextAssigned INT
	DECLARE assigneeCursor CURSOR FOR SELECT DISTINCT ID FROM #AssigneeIDs

	OPEN assigneeCursor
	FETCH FROM assigneeCursor INTO @nextAssigned

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC QCheck_AddAssignedTo @NewInstanceID,  @nextAssigned , @CreatedBy
		FETCH FROM assigneeCursor INTO @nextAssigned
	END	

	CLOSE assigneeCursor
	DEALLOCATE assigneeCursor

	SET @errorCode = @@ERROR

	IF @errorCode = 0
	BEGIN
		UPDATE QCheck_Alerts
		SET AlertTime = 17
		WHERE InstanceID = @NewInstanceID

		SET @errorCode = @@ERROR
	END
	ELSE IF @errorMsg = ''
		SET @errorMsg = 'UPDATE QCheck_Alerts SET AlertTime = 17 WHERE InstanceID = ' + cast(@NewInstanceID as varchar)

	IF @errorCode = 0
	BEGIN
		UPDATE QCheck_ChecklistManagers
		SET IsDeleted = 1 
		WHERE ChecklistID = @ChecklistID
			AND ManagerGroupID <> @controlledBy
		
		SET @errorCode = @@ERROR
		IF @errorCode = 0
		BEGIN
			UPDATE QCheck_ChecklistManagers
			SET IsDeleted = 0 
			WHERE ChecklistID = @ChecklistID
				AND ManagerGroupID = @controlledBy

			IF @@ROWCOUNT = 0
			BEGIN
				INSERT INTO QCheck_ChecklistManagers (ManagerGroupID, ChecklistID, IsDeleted, CreateDate)
				VALUES (@controlledBy, @ChecklistID, 0, GETDATE())
			END
		END
	END
	ELSE IF @errorMsg = ''
		SET @errorMsg = 'UPDATE QCheck_ChecklistManagers SET ManagerGroupID = ' + CONVERT(VARCHAR(10), @assignedTo) + ' WHERE ChecklistID = (SELECT ChecklistID FROM QCheck_ChecklistInstances WHERE ID = ' + CAST(@NewInstanceID AS varchar) + ')'
		
	IF @errorCode <> 0
	BEGIN
		DECLARE @msg varchar(5000)
		SET @msg = 'Error Number ' + cast(@errorCode AS varchar) + '; Error Msg: ' + @errorMsg
		EXEC XPSendEmail
		    @FROM       = 'sqlmail@acmewidget.com',
		    @FROM_NAME  = 'SQLMail',
		    @TO         = 'developers@acmewidget.com',
		    @subject    = 'TaxQ QProcess Task Error',
		    @message    = @msg,
		    @type       = 'text/html',
		    @server     = 'SMTPGATEWAY'
	END


/* Add Comment to Task Through API */


GO
/****** Object:  StoredProcedure [dbo].[QStatus_ReportValidation]    Script Date: 11/21/2024 4:37:17 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE OR ALTER PROCEDURE [dbo].[QStatus_ReportValidation] (
@Assignees NVARCHAR(500),
@Controller NVARCHAR(500),
@SectionId INT,	
@RecordsReturned INT OUTPUT
)
AS
BEGIN

 DECLARE @AppName NVARCHAR(50);
 
 SELECT @AppName = AppName from QCheck_AppSettings; --THIS IS USED FOR ERROR MESSAGING

CREATE TABLE #CombinedUsers(
UserName NVARCHAR(30)
);

INSERT INTO #CombinedUsers (UserName) SELECT UserName.c from dbo.Util_fn_List_To_Table(@assignees, ',') as UserName;
INSERT INTO #CombinedUsers (UserName) SELECT @Controller;

select r.id ReportID, u.id UserID from 
  QStatus_TaskTypes tt
  INNER JOIN QStatus_Report r ON r.ID = tt.ReportID AND r.IsDeleted = 0
  INNER JOIN QStatus_GroupReport gr ON gr.ReportID = r.ID
  INNER JOIN QCheck_Groups g ON g.ID = gr.GroupID
  INNER JOIN QCheck_GroupMembership gm on gm.GroupID = g.ID
  INNER JOIN QCheck_Users u ON u.ID = gm.UserID AND u.FullName IN ((SELECT * from #CombinedUsers)) and u.IsDeleted = 0
  WHERE tt.ID = @SectionId
    AND tt.IsDeleted = 0

  UNION

  select r.id, u.ID from 
  QStatus_TaskTypes tt
  INNER JOIN QStatus_Report r ON r.ID = tt.ReportID AND r.IsDeleted = 0
  INNER JOIN QStatus_Supervisors s ON s.ReportID = r.ID and s.InterestedParty = 0
  INNER JOIN QCheck_Groups g ON g.ID = s.SupervisorGroupID
  INNER JOIN QCheck_GroupMembership gm on gm.GroupID = g.ID
  INNER JOIN QCheck_Users u ON u.ID = gm.UserID AND u.FullName = @Controller and u.IsDeleted = 0
  WHERE tt.ID = @SectionId
    AND tt.IsDeleted = 0

SELECT @RecordsReturned = @@ROWCOUNT

END


GO
/****** Object:  StoredProcedure [dbo].[QStatus_GetStatusOfTasksByTaskOrUser]    Script Date: 11/21/2024 4:48:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[QStatus_GetStatusOfTasksByTaskOrUser] (
	@ActiveChecklistId INT = 0,
	@TaskName NVARCHAR(250) = NULL,
	@UserName NVARCHAR(30) = NULL
)
AS
BEGIN
	
	DECLARE @TempActiveChecklistId INT
	DECLARE @TempTaskName NVARCHAR(250)
	DECLARE @TempUserName NVARCHAR(30)
	DECLARE @TempTaskCount INT

	DECLARE @AppName NVARCHAR(50);
    SELECT @AppName = AppName from QCheck_AppSettings;

	IF @ActiveChecklistId > 0
		BEGIN
		SET	@TempActiveChecklistId = (SELECT ID FROM QCheck_ActiveCheckLists WHERE ID = @ActiveChecklistID)
		IF @TempActiveChecklistId = 0
		BEGIN
			RAISERROR('Provided ActiveChecklistId is not valid', 16, 1, @AppName)
			RETURN
		END

			SELECT 
			c.Name AS TaskName, 
			g.Name AS Assignees,
			con.controllers AS Controllers,
			ac.DueTime AS Deadline, 
			CASE WHEN ac.CompletedDate IS NULL THEN 0 ELSE 1 END AS IsCompleted
				FROM QCheck_Checklists c
				INNER JOIN QCheck_ChecklistInstances ci
				ON c.ID = ci.ChecklistID AND ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac
				ON ci.ID = ac.InstanceID
				INNER JOIN QCheck_Assignments a
				ON ac.InstanceID = a.InstanceID AND a.IsDeleted = 0
				INNER JOIN QCheck_GroupMembership gm
				ON a.GroupID = gm.GroupID
				INNER JOIN QCheck_Groups g
				ON gm.GroupID = g.ID
				INNER JOIN QCheck_Users u
				ON g.Owner = u.ID AND u.IsDeleted = 0
				INNER JOIN QCheck_ChecklistControllersList con
				ON c.ID = con.checklistid
			WHERE ac.ID = @ActiveChecklistId 
			GROUP BY con.controllers, c.Name, g.Name, ac.Duetime, ac.CompletedDate
		END

	ELSE IF @TaskName IS NOT NULL
		BEGIN

		SET	@TempTaskCount = (SELECT COUNT(Name) FROM QCheck_CheckLists WHERE Name = @TaskName AND IsDeleted = 0)
		IF @TempTaskCount > 1
		BEGIN
			RAISERROR('Task name is ambiguous. Please use an Active Checklist ID', 16, 1, @AppName)
			RETURN
		END

		SET	@TempTaskName = (SELECT Name FROM QCheck_CheckLists WHERE Name = @TaskName AND IsDeleted = 0)
		IF @TempTaskName IS NULL
		BEGIN
			RAISERROR('Provided Task Name is not valid', 16, 1, @AppName)
			RETURN
		END

			SELECT 
			c.Name AS TaskName, 
			g.Name AS Assignees,
			con.controllers AS Controllers,
			ac.DueTime AS Deadline, 
			CASE WHEN ac.CompletedDate IS NULL THEN 0 ELSE 1 END AS IsCompleted
				FROM QCheck_Checklists c
				INNER JOIN QCheck_ChecklistInstances ci
				ON c.ID = ci.ChecklistID AND ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac
				ON ci.ID = ac.InstanceID
				INNER JOIN QCheck_Assignments a
				ON ac.InstanceID = a.InstanceID AND a.IsDeleted = 0
				INNER JOIN QCheck_GroupMembership gm
				ON a.GroupID = gm.GroupID
				INNER JOIN QCheck_Groups g
				ON gm.GroupID = g.ID
				INNER JOIN QCheck_Users u
				ON g.Owner = u.ID AND u.IsDeleted = 0
				INNER JOIN QCheck_ChecklistControllersList con
				ON c.ID = con.checklistid
			WHERE c.Name = @TaskName
			GROUP BY con.controllers, c.Name, g.Name, ac.Duetime, ac.CompletedDate
		END

	ELSE IF @UserName IS NOT NULL
		BEGIN

		SET	@TempUserName = (SELECT ID FROM QCheck_Groups WHERE Name = @UserName)
		IF @TempUserName IS NULL
		BEGIN
			RAISERROR('Provided User Name is not valid', 16, 1, @AppName)
			RETURN
		END
			SELECT 
			c.Name AS TaskName, 
			g.Name AS Assignees,
			con.controllers AS Controllers,
			ac.DueTime AS Deadline, 
			CASE WHEN ac.CompletedDate IS NULL THEN 0 ELSE 1 END AS IsCompleted
				FROM QCheck_Checklists c
				INNER JOIN QCheck_ChecklistInstances ci
				ON c.ID = ci.ChecklistID AND ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac
				ON ci.ID = ac.InstanceID
				INNER JOIN QCheck_Assignments a
				ON ac.InstanceID = a.InstanceID AND a.IsDeleted = 0
				INNER JOIN QCheck_GroupMembership gm
				ON a.GroupID = gm.GroupID
				INNER JOIN QCheck_Groups g
				ON gm.GroupID = g.ID
				INNER JOIN QCheck_Users u
				ON g.Owner = u.ID AND u.IsDeleted = 0
				INNER JOIN QCheck_ChecklistControllersList con
				ON c.ID = con.checklistid
			WHERE g.Name = @UserName
				AND c.CreateDate > DATEADD(year, -2, GETUTCDATE())
			GROUP BY con.controllers, c.Name, g.Name, ac.Duetime, ac.CompletedDate
		END


END

GO
/****** Object:  StoredProcedure [dbo].[QStatus_CreateNewCommentFromApi]    Script Date: 11/21/2024 5:26:24 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE OR ALTER PROCEDURE [dbo].[QStatus_CreateNewCommentFromApi]
(
	@Comments NVARCHAR(500),
	@ActiveChecklistId INT = 0,
	@TaskName NVARCHAR(250) = NULL,
	@NewID INT OUTPUT,
	@CommentInitials nVARCHAR(5) OUTPUT,
	@FullName NVARCHAR(50) OUTPUT
)
 AS
BEGIN
	DECLARE @TempInstanceId INT

	DECLARE @AppName NVARCHAR(50);
    SELECT @AppName = AppName from QCheck_AppSettings;

IF @ActiveChecklistId > 0 
 BEGIN
    SET	@TempInstanceId = (SELECT ID FROM QCheck_ActiveCheckLists WHERE ID = @ActiveChecklistID AND CompletedDate IS NOT NULL)
		IF @TempInstanceId = 0
		BEGIN
			RAISERROR('Provided ActiveChecklistId is not valid', 16, 1, @AppName)
			RETURN
		END

	BEGIN
		EXEC QStatus_CreateNewComment @ActiveChecklistId, 0, @Comments, @NewID, @CommentInitials, @FullName
	END
END
	ELSE IF @TaskName IS NOT NULL
	BEGIN

	  DECLARE @DuplicateCount INT 
	   SET @DuplicateCount = (SELECT COUNT(ac.ID) FROM QCheck_Checklists c
					INNER JOIN QCheck_ChecklistInstances ci
						ON ci.ChecklistID = c.ID
					INNER JOIN QCheck_ActiveChecklists ac
						ON ci.ID = ac.InstanceID
						WHERE c.Name = @TaskName)

		IF @DuplicateCount > 1
		BEGIN
			RAISERROR('Provided task is not valid', 16, 1, @AppName)
			RETURN
		END


		SET @TempInstanceId = (SELECT ac.ID FROM QCheck_ActiveChecklists ac
			INNER JOIN QCheck_ChecklistInstances ci
			ON ac.InstanceId = ci.ID
			INNER JOIN QCheck_Checklists c
			on ci.ChecklistID = c.ID
			WHERE c.Name = @TaskName
			AND c.IsDeleted = 0)

		IF @TempInstanceId = 0 OR @TempInstanceId IS NULL
		BEGIN
			RAISERROR('Provided task is not valid', 16, 1, @AppName)
			RETURN
		END
		
		EXEC QStatus_CreateNewComment @TempInstanceId, 0, @Comments, @NewID, @CommentInitials, @FullName
	

	END

END


GO
/****** Object:  StoredProcedure [dbo].[QCheck_CompleteTaskByTaskNameOrId]    Script Date: 11/21/2024 5:27:47 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   PROCEDURE [dbo].[QCheck_CompleteTaskByTaskNameOrId] (
	@ActiveChecklistID INT = 0,
	@TaskName NVARCHAR(250) = NULL,
	@isComplete BIT OUTPUT
)
AS
BEGIN

	DECLARE @AppName NVARCHAR(50);
    SELECT @AppName = AppName from QCheck_AppSettings;

	DECLARE @MultipleEntries INT
	DECLARE @TempActiveChecklistId INT
	DECLARE @TempTaskName NVARCHAR(250)

	DECLARE @UpcomingDuetimeId INT = -1
	DECLARE @NewActiveChecklistId INT = -1

	IF @ActiveChecklistID > 0 
	BEGIN
		SET	@TempActiveChecklistId = (SELECT ID FROM QCheck_ActiveCheckLists WHERE ID = @ActiveChecklistID AND CompletedDate IS NULL)

		IF @TempActiveChecklistId = 0 OR @TempActiveChecklistId IS NULL AND @TaskName IS NOT NULL
		BEGIN
		
			SET @TempTaskName = (SELECT Name FROM QCheck_Checklists WHERE Name = @TaskName)

			IF @TempTaskName IS NULL
			BEGIN
				RAISERROR('Task name is invalid. Please provide another task name or a Task ID instead.', 16, 1, @AppName)
				RETURN
			END

			SET @MultipleEntries = (SELECT COUNT(Name) FROM QCheck_Checklists
				WHERE IsDeleted = 0 AND Name = @TaskName)

			IF @MultipleEntries > 1
			BEGIN
				RAISERROR('Task name is invalid. Please provide another task name or a Task ID instead.', 16, 1, @AppName)
				RETURN
			END

			SET @TempActiveChecklistId = (SELECT ac.ID FROM QCheck_ActiveChecklists ac
				INNER JOIN QCheck_ChecklistInstances ci
				ON ac.InstanceId = ci.ID
				INNER JOIN QCheck_Checklists c
				on ci.ChecklistID = c.ID
				WHERE c.IsDeleted = 0 AND ac.CompletedDate IS NULL AND c.Name = @TaskName)

			IF (@TempActiveChecklistId = 0 OR @TempActiveChecklistId IS NULL)
			BEGIN
				RAISERROR('Task has already been completed', 16, 1, @AppName)
				RETURN
			END
			
			EXEC QCheck_CompleteChecklist @TempActiveChecklistId, 0, 0, 'Closed By System', @isComplete OUTPUT, @UpcomingDuetimeId OUTPUT, @NewActiveChecklistId OUTPUT
		
		END
		ELSE IF @TempActiveChecklistId = 0 OR @TempActiveChecklistId IS NULL AND @TaskName IS NULL
			BEGIN
				RAISERROR('Provided ActiveChecklistId is not valid', 16, 1, @AppName)
				RETURN
			END
			
		EXEC QCheck_CompleteChecklist @ActiveChecklistID, 0, 0, 'Closed By System', @isComplete OUTPUT, @UpcomingDuetimeId OUTPUT, @NewActiveChecklistId OUTPUT

		END
	ELSE IF @TaskName IS NOT NULL
	BEGIN
		
		SET @TempTaskName = (SELECT Name FROM QCheck_Checklists WHERE Name = @TaskName)

		BEGIN
			RAISERROR('Task name is invalid. Please provide another task name or a Task ID instead.', 16, 1, @AppName)
			RETURN
		END


		SET @MultipleEntries = (SELECT COUNT(Name) FROM QCheck_Checklists
			WHERE IsDeleted = 0 AND Name = @TaskName)

		IF @MultipleEntries > 1
		BEGIN
			RAISERROR('Task name is invalid. Please provide another task name or a Task ID instead.', 16, 1, @AppName)
			RETURN
		END
		ELSE
		BEGIN

			SET @TempActiveChecklistId = (SELECT ac.ID FROM QCheck_ActiveChecklists ac
			INNER JOIN QCheck_ChecklistInstances ci
			ON ac.InstanceId = ci.ID
			INNER JOIN QCheck_Checklists c
			on ci.ChecklistID = c.ID
			WHERE c.IsDeleted = 0 AND ac.CompletedDate IS NULL AND c.Name = @TaskName)

			IF (@TempActiveChecklistId = 0 OR @TempActiveChecklistId IS NULL)
			BEGIN
			RAISERROR('Task has already been completed', 16, 1, @AppName)
			RETURN
		END
			EXEC QCheck_CompleteChecklist @TempActiveChecklistId, 0, 0, 'Closed By System', @isComplete OUTPUT, @UpcomingDuetimeId OUTPUT, @NewActiveChecklistId OUTPUT
		END
	END

END


GO
/****** Object:  StoredProcedure [dbo].[QCheck_ConvertTimezonesOfAllSelectedTasks]    Script Date: 11/21/2024 5:28:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[QCheck_ConvertTimezonesOfAllSelectedTasks]
@ActiveChecklistID INT,
@NewTimeZone VARCHAR(255)
AS 

BEGIN

    DECLARE @InstanceID INT, @ScheduleID INT, @OldTimeZone varchar(255)

    SELECT @InstanceID = ci.ID, @ScheduleID = s.ID, @OldTimeZone = s.TimeZone
    FROM QCheck_ActiveChecklists ac
    INNER JOIN QCheck_ChecklistInstances ci
        ON ci.ID = ac.InstanceID
    INNER JOIN QCheck_Schedule s
        ON ci.ScheduleID = s.ID
    WHERE ac.ID = @ActiveChecklistID

    UPDATE QCheck_Schedule
    SET TimeZone = @NewTimeZone
    WHERE ID = @ScheduleID
    
    --Order of operations:
    --Convert from UTC to old local time zone
    --Convert from old TZ to new TZ
    --Convert from new TZ to UTC
    UPDATE QCheck_ActiveChecklists 
    SET DueTime = dbo.ConvertTime(DueTime, @NewTimezone, @OldTimeZone),
		OrigDueTime = dbo.ConvertTime(OrigDueTime, @NewTimezone, @OldTimeZone),
		ReminderDate = dbo.ConvertTime(ReminderDate, @NewTimezone, @OldTimeZone)
    WHERE InstanceID = @InstanceID 
        AND CompletedDate IS NULL

    EXEC QCheck_SetUpcomingInstance @InstanceID 

END

GO
/****** Object:  StoredProcedure [dbo].[QCheck_GetTasksIControlWithTImezones]    Script Date: 11/21/2024 5:29:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE [dbo].[QCheck_GetTasksIControlWithTImezones]
	@UserId INT
AS
BEGIN
	SET NOCOUNT ON;
 SELECT 
    ac.ID as objID, 
    c.ID as ChecklistID, 
    c.Name as ChecklistName, 
    ac.DueTime, 
    ac.ReminderDate,
    CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
    ac.OrigDueTime,
    ISNULL(s.TimeZone, 'America/Chicago') TimeZone,
	s.lastDueDate,
	s.freqInterval,
	s.freqType
   FROM 
    QCheck_ChecklistInstances ci
    INNER JOIN QCheck_Checklists c 
     on ci.checklistID = c.ID 
     AND c.IsDeleted = 0
     and ci.IsDeleted = 0
    CROSS APPLY( select top 1 * from QCheck_ActiveChecklists ac 
     WHERE ac.InstanceID = ci.ID AND ac.CompletedDate IS NULL
     ORDER BY ac.DueTime
    ) ac
    LEFT OUTER JOIN QCheck_Schedule s 
     ON ci.ScheduleID = s.ID     
    LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID 
    LEFT OUTER JOIN QCheck_ChecklistManagers cm ON cm.ChecklistID = c.ID and cm.IsDeleted = 0
    LEFT OUTER JOIN QCheck_GroupMembership gm ON gm.GroupID = cm.ManagerGroupID
   WHERE
    gm.UserID = @UserId
END
GO