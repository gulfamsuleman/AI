create proc QCheck_RedactedTaskList
(
 @UserID int,
 @SupervisorID int
)
AS
BEGIN
 select 
  case when reminder.id is not null or sup.id is not null then
   c.name
  else '<REDACTED>'
  END as ChecklistName, 
  isnull(convert(varchar, duetime, 101), '') as duetime,
  isnull(ccl.controllers, '') as Controllers,
  isnull(trl.reportslist, '') as StatusReportString,
  isnull(al.assignees,'') as Assignees
 
 from QCheck_Checklists c 
  inner join QCheck_ChecklistInstances ci
   on ci.checklistID = c.id
   and ci.isdeleted = 0
   and c.isdeleted = 0
  inner join QCheck_Assignments a
   on a.instanceid = ci.id
   and a.isdeleted = 0
  inner join QCheck_GroupMembership gm
   on gm.groupid = a.groupid
   and gm.userID = @userID
  OUTER APPLY  (select top 1 duetime, id from QCheck_ActiveChecklists where instanceid = ci.id and completeddate is null order by duetime asc) ac
  OUTER APPLY (select top 1 id from QCheck_ControllerAssigneeInstances_all where id = ci.id) reminder
  OUTER APPLY  (select top 1 cm.id from QCheck_ChecklistManagers cm inner join QCheck_GroupMembership gm on gm.groupID = cm.ManagerGroupID and cm.IsDeleted = 0 and gm.UserID = @SupervisorID and cm.ChecklistID = c.id) sup
  LEFT OUTER JOIN QCheck_ChecklistControllersList ccl on ccl.checklistid = c.id
  LEFT OUTER JOIN QStatus_TaskReportList trl on trl.activechecklistid = ac.id and trl.userid = @UserID
  LEFT OUTER JOIN dbo.QCheck_AssigneeLookup AL on a.InstanceID=al.InstanceID
  
END