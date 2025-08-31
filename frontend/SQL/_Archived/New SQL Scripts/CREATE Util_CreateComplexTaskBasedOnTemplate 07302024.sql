
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


alter Proc [dbo].[Util_CreateComplexTaskBasedOnTemplate]
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
  @softdue datetime = null
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
 Declare @ExistingStatusReportSection varchar(100)
 declare @ExistingTaskName varchar(100)
 declare @UniqueTaskName bit

 DECLARE @AdminID int

 SELECT @DueTime = 19
 DECLARE @AppName NVARCHAR(50);
 
 SELECT @AppName = AppName from QCheck_AppSettings; --THIS IS USED FOR ERROR MESSAGING

  select @AdminID = ID from QCheck_Users where fullname = @controller1 AND IsDeleted = 0

IF @AdminID IS NULL

BEGIN
	RAISERROR('The specified Controller1 does not match any user in %s', 16, 1, @AppName)
	RETURN
END

EXEC QCheck_DuplicateNameCheck @Name = @taskname, @UserID = @AdminID, @OKToUse = @UniqueTaskName OUTPUT


 if @UniqueTaskName = 0
BEGIN
	RAISERROR('Task with the provided name alreasy exists', 16, 1)
	RETURN
END

 SELECT @StatusReportId = id from QStatus_Report where Name = @statusreportname AND IsDeleted = 0;

 IF @StatusReportId IS NULL
BEGIN
	RAISERROR('The specified status report name does not match any status report in %s', 16, 1, @AppName)
	RETURN
END

SELECT @ExistingStatusReportSection = description from QStatus_tasktypes where Description = @statusReportSection AND IsDeleted = 0


 IF @ExistingStatusReportSection IS NULL
BEGIN
	RAISERROR('The specified status report section does not match any status report section in %s', 16, 1, @AppName)
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
	@GroupID = @assignedgroupid1

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

   SELECT @instanceID = ID from QCheck_ChecklistInstances where ChecklistID = @newTaskID

 if (@assignedgroupid2 > 0)
 begin

  exec QCheck_AddAssignedTo
   @InstanceID = @instanceID,
   @GroupID = @assignedgroupid2,
   @AssignedBy = @AdminID,
   @Email = 0
 end
 if (@assignedgroupid3 > 0)
 begin
  exec QCheck_AddAssignedTo
   @InstanceID = @instanceID,
   @GroupID = @assignedgroupid3,
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

 EXEC QCheck_UpdateSchedule_part1 
  @InstanceID = @instanceID, 
  @firstDueDate = @DueDate,
  @freqType = 1, 
  @dueTime = @DueTime,
  @PrevFreqType = @PrevFreqType output,
  @RowsUpdated = @RowsUpdated output,
  @Activate = 1,
  @SoftDueOffsetDays = @SoftDueOffsetDays

 UPDATE QCheck_ChecklistManagers
  SET isdeleted = 1
  where ChecklistID = @newTaskID

 INSERT INTO QCheck_ChecklistManagers
  select @controllergroupid1, @newTaskID, 0, getdate()
  where isnull(@controllergroupid1, 0) > 0
 INSERT INTO QCheck_ChecklistManagers
  select @controllergroupid2, @newTaskID, 0, getdate()
  where isnull(@controllergroupid2, 0) > 0

 declare @itt int

 if @tasktype > 0
 begin
  exec QCheck_AddInstanceTaskType @InstanceID = @instanceID,@TaskType = @tasktype, @Priority = 1,@ID =@itt output
 end

END

 
