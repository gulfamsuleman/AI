CREATE OR ALTER PROC [dbo].[QCheck_CreateSimple_part1]
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
	@TimeZone varchar(255) = NULL,
	@EmailAssignees bit = 1,
	@TemplateChecklistID INT = NULL

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
		SELECT @TimeZone = COALESCE(TimeZoneOverride, LastTimeZone, SystemTimeZone) 
		FROM QCheck_Users 
			CROSS APPLY (SELECT TOP 1 SystemTimeZone FROM QCheck_AppSettings) stz
		WHERE ID = @CreatedBy
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
	
	IF @TemplateChecklistID IS NOT NULL 
		BEGIN
			INSERT INTO QCheck_ChecklistManagers (ManagerGroupID, ChecklistID, IsDeleted)
			SELECT ManagerGroupID, @ID, 0
			FROM QCheck_ChecklistManagers
			WHERE ChecklistID = @TemplateChecklistID AND IsDeleted = 0

			UNION ALL SELECT groupid, @ID, 0
			FROM (
				SELECT TOP 1 g.id as groupID
				FROM qcheck_users u
				INNER JOIN qcheck_groupmembership gm
					ON u.id = gm.userid
				INNER JOIN qcheck_groups g
					ON g.id = gm.groupid
					AND g.singlemembergroup = 1
				WHERE u.id = @CreatedBy 
					AND @CreatedBy IS NOT NULL
				ORDER BY g.id ASC
			) OwnerGroup
			WHERE groupID not in (SELECT ManagerGroupID FROM QCheck_ChecklistManagers WHERE ChecklistID = @TemplateChecklistID AND IsDeleted = 0)

			INSERT INTO QCheck_Items (
				ChecklistID, 
				SequenceNum, 
				ItemTypeID, 
				[Text], 
				[URL], 
				IsDeleted )
			SELECT 
				@ID, 
				SequenceNum, 
				ItemTypeID, 
				[Text], 
				URL, 
				0
			FROM 
				QCheck_Items	
			WHERE 
				ChecklistID = @TemplateChecklistID
				AND IsDeleted = 0	
		END 
	ELSE 
		BEGIN
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
	END

	EXEC QCheck_CreateInstance @ID = @NewInstanceID output, @ChecklistID = @ID, @Name = '', @CreatedBy = @CreatedBy, @TimeZone = @TimeZone

	EXEC QCheck_AddAssignedTo @NewInstanceID, @GroupID, @CreatedBy, @EmailAssignees

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
		declare @UserList table 
		(
			seq INT IDENTITY(1,1),
			UserID int	
		)
		Insert into @UserList
		select UserID From QCheck_GroupMembership where GroupID=@GroupID
 
		Declare @userListCount int
		SELECT @userListCount = Count(*) FROM @UserList
		Declare @counter int=1
		Declare @AssignedToUserID int
		WHILE @counter <= @userListCount
		BEGIN
			set @AssignedToUserID=(select UserID from @UserList where seq=@counter)
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