USE [PHIProcess]
GO

/****** Object:  StoredProcedure [dbo].[QCheck_CreateSimple_part1]    Script Date: 7/30/2024 9:22:42 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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
	@AddToPriorityList bit=0--added by venkat 04/20/2017
AS
BEGIN
	SET NOCOUNT ON
	
	if @ReminderDate is null set @ReminderDate = @DueDate

	DECLARE @UserID int,
			@FolderID int,
			@FolderName varchar(50),
			@DueTime int,
			@recordIds AS RecordId,
			@PrevSchedule bit = 0,
			@ReportID int = 0

	SELECT @DueTime = duetime FROM QCheck_UserDefaultTimes WHERE UserID = @CreatedBy

	IF @DueTime IS NULL
		SELECT @DueTime = duetime from QCheck_UserDefaultTimes WHERE UserID = -1
	
	SELECT @ReportID = reportID
	FROM QStatus_TaskTypes
	WHERE ID = @TaskType

	INSERT INTO QCheck_Checklists ([Name], Owner) VALUES (@Name, @CreatedBy)
	SELECT @ID = SCOPE_IDENTITY()

	--INSERT INTO @recordIds VALUES(@ID)
	--EXEC dbo.Audit_Set @CreatedBy, @recordIds, 'Checklist', 1

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

	--DELETE FROM @recordIds
	--INSERT INTO @recordIds VALUES(@NewActiveID)
	--EXEC dbo.Audit_Set @CreatedBy, @recordIds, 'ActiveChecklist', 3

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


