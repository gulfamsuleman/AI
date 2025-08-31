USE [PHIProcess]
GO

/****** Object:  StoredProcedure [dbo].[QCheck_GetMyTasksToAdd]    Script Date: 7/9/2024 12:49:09 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[QCheck_GetMyTasksToAddExcludeAlreadyAdded]
	@UserID int,
	@ReportID int
AS

BEGIN

	SET NOCOUNT ON
	

		SELECT 
			ci.ID,
			c.Name, 
			CONVERT(VARCHAR(10), duetimes.dt, 101) as duetime,
			CAST(duetimes.dt AS DATETIME) AS duedt,
			dbo.QCheck_AssigneesList(ci.ID) AS Assignees
		FROM
			QCheck_Checklists c
			INNER JOIN QCheck_ChecklistInstances ci
				ON ci.ChecklistID = c.ID
				AND ci.IsDeleted = 0
				AND c.IsDeleted = 0
			INNER JOIN QCheck_Assignments a
				ON a.InstanceID = ci.ID
				AND a.IsDeleted = 0
			INNER JOIN QCheck_Groups g
				ON g.ID = a.GroupID
			INNER JOIN QCheck_GroupMembership gm
				ON gm.GroupID = g.ID
				AND gm.UserID = @UserID	
			INNER JOIN (
				select ac.instanceid, convert(varchar(10), ac.duetime, 101) as dt, convert(varchar(10), ac.reminderdate, 101) as softdue
				from qcheck_activechecklists ac
				left outer join qcheck_activechecklists ac2 on ac.instanceid = ac2.instanceid and ac2.origduetime < ac.origduetime
				where ac2.[id] is null
			) duetimes
				on duetimes.instanceid = ci.id
		WHERE CI.ID NOT IN (SELECT itt.instanceid
							FROM qstatus_instancetasktype itt
							INNER JOIN qstatus_tasktypes tt
								ON tt.id = itt.tasktype
							INNER JOIN qstatus_report r
								ON r.id = tt.reportid
							WHERE r.id = @ReportID)
	
		UNION --tasks I control

		SELECT 
			ci.ID,
			c.Name, 
			CONVERT(VARCHAR(10), duetimes.dt, 101) as duetime,
			CAST(duetimes.dt AS DATETIME) AS duedt,
			dbo.QCheck_AssigneesList(ci.ID) AS Assignees
		FROM
			QCheck_Checklists c
			INNER JOIN QCheck_ChecklistInstances ci
				ON ci.ChecklistID = c.ID
				AND ci.IsDeleted = 0
				AND c.IsDeleted = 0
			INNER JOIN QCheck_ChecklistManagers cm
				ON cm.ChecklistID = c.ID
				AND cm.IsDeleted = 0
			INNER JOIN QCheck_Groups g
				ON g.ID = cm.ManagerGroupID
			INNER JOIN QCheck_GroupMembership gm
				ON gm.GroupID = g.ID
				AND gm.UserID = @UserID	
			INNER JOIN (
				select ac.instanceid, convert(varchar(10), ac.duetime, 101) as dt, convert(varchar(10), ac.reminderdate, 101) as softdue
				from qcheck_activechecklists ac
				left outer join qcheck_activechecklists ac2 on ac.instanceid = ac2.instanceid and ac2.origduetime < ac.origduetime
				where ac2.[id] is null
			) duetimes
				on duetimes.instanceid = ci.id
		WHERE CI.ID NOT IN (SELECT itt.instanceid
							FROM qstatus_instancetasktype itt
							INNER JOIN qstatus_tasktypes tt
								ON tt.id = itt.tasktype
							INNER JOIN qstatus_report r
								ON r.id = tt.reportid
							WHERE r.id = @ReportID)


		UNION --tasks on status reports I control

		SELECT 
			ci.ID,
			c.Name, 
			CONVERT(VARCHAR(10), duetimes.dt, 101) as duetime,
			CAST(duetimes.dt AS DATETIME) AS duedt,
			dbo.QCheck_AssigneesList(ci.ID) AS Assignees
		FROM
			QCheck_Checklists c
			INNER JOIN QCheck_ChecklistInstances ci
				ON ci.ChecklistID = c.ID
				AND ci.IsDeleted = 0
				AND c.IsDeleted = 0
			INNER JOIN QStatus_InstanceTaskType itt
				ON itt.InstanceID = ci.ID
			INNER JOIN QStatus_TaskTypes tt
				ON tt.ID = itt.TaskType
				AND tt.IsDeleted = 0
			INNER JOIN QStatus_Report r
				ON r.ID = tt.ReportID
				AND r.IsDeleted = 0
			INNER JOIN QStatus_GroupReport gr
				ON gr.ReportID = r.ID
			INNER JOIN QCheck_Groups g
				ON g.ID = gr.GroupID
			INNER JOIN QCheck_GroupMembership gm
				ON gm.GroupID = g.ID
				AND gm.UserID = @UserID	
			INNER JOIN (
				select ac.instanceid, convert(varchar(10), ac.duetime, 101) as dt, convert(varchar(10), ac.reminderdate, 101) as softdue
				from qcheck_activechecklists ac
				left outer join qcheck_activechecklists ac2 on ac.instanceid = ac2.instanceid and ac2.origduetime < ac.origduetime
				where ac2.[id] is null
			) duetimes
				on duetimes.instanceid = ci.id
		WHERE CI.ID NOT IN (SELECT itt.instanceid
							FROM qstatus_instancetasktype itt
							INNER JOIN qstatus_tasktypes tt
								ON tt.id = itt.tasktype
							INNER JOIN qstatus_report r
								ON r.id = tt.reportid
							WHERE r.id = @ReportID)

		UNION --supervisor
	
		SELECT 
			ci.ID,
			c.Name, 
			CONVERT(VARCHAR(10), duetimes.dt, 101) as duetime,
			CAST(duetimes.dt AS DATETIME) AS duedt,
			dbo.QCheck_AssigneesList(ci.ID) AS Assignees
		FROM
			QCheck_Checklists c
			INNER JOIN QCheck_ChecklistInstances ci
				ON ci.ChecklistID = c.ID
				AND ci.IsDeleted = 0
				AND c.IsDeleted = 0
			INNER JOIN QStatus_InstanceTaskType itt
				ON itt.InstanceID = ci.ID
			INNER JOIN QStatus_TaskTypes tt
				ON tt.ID = itt.TaskType
				AND tt.IsDeleted = 0
			INNER JOIN QStatus_Report r
				ON r.ID = tt.ReportID
				AND r.IsDeleted = 0
			INNER JOIN QStatus_Supervisors s
				ON s.ReportID = r.ID
			INNER JOIN QCheck_Groups g
				ON g.ID = s.SupervisorGroupID
			INNER JOIN QCheck_GroupMembership gm
				ON gm.GroupID = g.ID
				AND gm.UserID = @UserID	
			INNER JOIN (
				select ac.instanceid, convert(varchar(10), ac.duetime, 101) as dt, convert(varchar(10), ac.reminderdate, 101) as softdue
				from qcheck_activechecklists ac
				left outer join qcheck_activechecklists ac2 on ac.instanceid = ac2.instanceid and ac2.origduetime < ac.origduetime
				where ac2.[id] is null
			) duetimes
				on duetimes.instanceid = ci.id
		WHERE CI.ID NOT IN (SELECT itt.instanceid
							FROM qstatus_instancetasktype itt
							INNER JOIN qstatus_tasktypes tt
								ON tt.id = itt.tasktype
							INNER JOIN qstatus_report r
								ON r.id = tt.reportid
							WHERE r.id = @ReportID)
				
		ORDER BY 4

	SET NOCOUNT OFF

End

GO


