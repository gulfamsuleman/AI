USE [PHIProcess]
GO

/****** Object:  StoredProcedure [dbo].[Util_CreateFoundationTask]    Script Date: 7/29/2024 8:53:13 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE Proc [dbo].[Util_CreateComplexTask]
	(
		@taskname varchar(500),
		@DueDate datetime,
		@item varchar(1000) = '',
		@tasktype int = 0,
		@controller1 varchar(50),
		@controller2 varchar(50) = '',
		@assignee1 varchar(50),
		@assignee2 varchar(50) = '',
		@item2 varchar(500) = '',
		@item3 varchar(500) = '',
		@item4 varchar(500) = '',
		@item5 varchar(500) = '',
		@item6 varchar(500) = '',
		@statusReport int,
		@statusReportSections varchar(150) = ''
	)
AS
BEGIN

	Declare @copyTaskID int = 1802085
	Declare @newTaskID int
	Declare @instanceID int
	Declare @SupervisorID int
	Declare @SupervisorGroupID int
	declare @Admin varchar(100) = 'bharper'
	declare @AdminID int
	declare @AdminGroupID int = 1916
	Declare @DueTime float
	Declare @PrevFreqType int
	Declare @RowsUpdated int
	Declare @AssignedGroupID int = 2209 --Phil Lab Tracking


	SELECT @DueTime = 19



	select @AdminID = ID from QCheck_Users where shortname = @Admin


	exec [QCheck_CopyChecklist] 
		@ChecklistID = @copyTaskID,
		@NewChecklistID = @newTaskID OUTPUT,
		@NewName = @taskname,
		@Force = 1

	update qcheck_items
	set [text] = @taskname
	where checklistid = @newTaskID

	if len(@item) >0
	begin
		exec [QCheck_AddItem] @ChecklistID = @newTaskID, @ItemTypeID = 1, @Text = @item, @URL = ''
	end

	exec [QCheck_CreateInstance] 
		@ID = @instanceID output,
		@ChecklistID = @newTaskID,
		@CreatedBy = @AdminID
	
	exec QCheck_AddAssignedTo
		@InstanceID = @instanceID,
		@GroupID = @AssignedGroupID,
		@AssignedBy = @AdminID,
		@Email = 0

	EXEC QCheck_UpdateSchedule_part1 
		@InstanceID = @instanceID, 
		@firstDueDate = @DueDate,
		@freqType = 1, 
		@dueTime = @DueTime,
		@PrevFreqType = @PrevFreqType output,
		@RowsUpdated = @RowsUpdated output,
		@Activate = 1

	UPDATE QCheck_ChecklistManagers
		SET ManagerGroupID = @AdminGroupID
		where ChecklistID = @newTaskID

	declare @itt int

	if @tasktype > 0
	begin
		exec QCheck_AddInstanceTaskType @InstanceID = @instanceID,@TaskType = @tasktype, @Priority = 1,@ID =@itt output
	end

END
GO


