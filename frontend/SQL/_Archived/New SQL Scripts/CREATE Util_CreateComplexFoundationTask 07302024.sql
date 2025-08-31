
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create Proc [dbo].[Util_CreateComplexFoundationTask]
 (
  @taskname varchar(500),
  @DueDate datetime,
  @controller1 varchar(100),
  @controller2 varchar(100),
  @assignee1 varchar(100),
  @assignee2 varchar(100),
  @assignee3 varchar(100),
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
  @tasktype int = 0,
  @softdue datetime = null
 )
AS
BEGIN

 Declare @copyTaskID int = 1802085
 Declare @newTaskID int
 Declare @instanceID int
 Declare @SupervisorID int
 Declare @SupervisorGroupID int
 Declare @DueTime float
 Declare @PrevFreqType int
 Declare @RowsUpdated int

 DECLARE @AdminID int

 SELECT @DueTime = 19

 --Foundation commonly sends this in as Bethany Cale instead of Harper
 if @controller1 like 'Bethany%'
 begin
  select @controller1 = fullname from qcheck_users
  where shortname = 'Bharper'
 end
 if @controller2 like 'Bethany%'
 begin
  select @controller2 = fullname from qcheck_users
  where shortname = 'Bharper'
 end

 --We're going to remove the previous lines

 select @AdminID = ID from QCheck_Users where fullname = @controller1

 if  dbo.Util_isofficeday(@duedate) = 0
 begin
  select @duedate = dbo.Util_priorofficeday(@duedate)
 end


 exec [QCheck_CopyChecklist] 
  @ChecklistID = @copyTaskID,
  @NewChecklistID = @newTaskID OUTPUT,
  @NewName = @taskname,
  @Force = 1

 declare @assignedgroupid1 int, @assignedgroupid2 int, @assignedgroupid3 int, @controllergroupid1 int, @controllergroupid2 int

 select @assignedgroupid1 = id from qcheck_groups where name = @assignee1
 select @assignedgroupid2 = id from qcheck_groups where name = @assignee2
 select @assignedgroupid3 = id from qcheck_groups where name = @assignee3
 select @controllergroupid1 = id from qcheck_groups where name = @controller1
 select @controllergroupid2 = id from qcheck_groups where name = @controller2


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

 exec [QCheck_CreateInstance] 
  @ID = @instanceID output,
  @ChecklistID = @newTaskID,
  @CreatedBy = @AdminID
 
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
 
