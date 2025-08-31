CREATE OR ALTER PROC [dbo].[QCheck_SlimGetUserChecklists](
	@UserID int,
	@activeChecklistID int = 0,
	@instanceID int = 0,
	@startDate datetime = null,
	@endDate datetime = null,
	@recurrance int = 0
) AS
BEGIN
	SET NOCOUNT ON
	
	-- get current checklists
	SELECT 
		c.ID as ChecklistID,
		c.Name as ChecklistName, 
		c.CreateDate,
		a.ID As Identifier, 
		a.ID as UniqueID, 
		a.dueTime, 
		0 as UpcomingID, 
		a.CompletedDate As ActiveChkCompletedDate, 
		--f.ID as AssignmentID, 
		isNull(a.CompletedDate,'12/12/9999') As Computed, 	
		1 As ChkType, 
		a.dueTime as dueSort,
		CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as Recurring,
		CASE WHEN s.freqType = 1 THEN 'One Time' 
			 WHEN s.freqType = 2 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Daily' ELSE 'Every ' + CONVERT(varchar,s.freqRecurrance) + ' days' END 
			 WHEN s.freqType = 3 THEN 
					CASE WHEN s.freqRecurrance = 1 THEN 
							'Weekly' 
					ELSE 
							'Every ' + CONVERT(varchar,s.freqRecurrance) + ' weeks' 
					END + CASE WHEN s.freqInterval > 0 THEN ' on ' + dbo.QCheck_GetDaysFromInterval(s.freqInterval) ELSE '' END
			 WHEN s.freqType = 4 and  s.freqRecurrance <> 3 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Monthly' ELSE 'Every' + CONVERT(varchar,s.freqRecurrance) + ' months' END
			 WHEN s.freqType = 4 and  s.freqRecurrance = 3 THEN 'Quarterly'  
 			 WHEN s.freqType = 5 THEN 
					CASE WHEN s.freqRecurrance = 1 THEN 
							'Yearly' 
					ELSE 
							'Every ' + CONVERT(varchar,s.freqRecurrance) + ' years'  
					END + CASE WHEN s.freqInterval > 0 THEN ' in ' + dbo.QCheck_GetMonthsFromInterval(s.freqInterval) ELSE '' END
			ELSE '' END as ScheduleString,
		--dbo.QStatus_GetActiveChecklistControllers(a.ID) AS Controllers,
		--dbo.QStatus_GetChecklistReports(a.ID, @UserID) as StatusReportString
		isnull(ccl.controllers, '') as Controllers,
		isnull(trl.reportslist, '') as StatusReportString,
		isnull(al.assignees,'') as Assignees,
		case when ms.checklistid is null then 0 else 1 end as MultiStep,
		case when cai.id is null then 0 else 1 end as ControllerPartOfAssignee,
		al.assigneecount,
		case when aac.ActiveChecklistID is null then 0 else 1 end as PendingChange, 
		aac.DueTime as NewDeadline,
		isnull(a.isna, 0) as isna, 
		isnull(a.nareason, '') as nareason
	INTO #result
	FROM
		QCheck_ActiveChecklists a 
		INNER JOIN QCheck_ChecklistInstances b ON a.InstanceID = b.ID AND b.IsDeleted = 0
		INNER JOIN QCheck_Schedule s ON b.ScheduleID = s.ID and Not (s.freqType = 1 and @recurrance = 2) and Not (s.freqType > 1 and @recurrance = 1)
		INNER JOIN QCheck_Checklists c on b.checklistID = c.ID AND c.IsDeleted = 0
		INNER JOIN QCheck_ActiveAssignments k on k.ActiveChecklistID = a.ID 
		INNER JOIN QCheck_GroupMembership gm on gm. UserID = @UserID
		INNER JOIN QCheck_Groups g on g.ID = gm.GroupID
		INNER JOIN QCheck_Assignments f on f.GroupID = gm.GroupID And f.IsDeleted = 0 and f.InstanceID = b.ID
		LEFT OUTER JOIN QStatus_TaskReportList trl on trl.activechecklistid = a.id and trl.userid = @UserID
	    LEFT OUTER JOIN QCheck_ChecklistControllersList ccl on ccl.checklistid = c.id
		LEFT OUTER JOIN	dbo.QCheck_AssigneeLookup AL on a.InstanceID=al.InstanceID
		LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
		LEFT OUTER JOIN QCheck_ControllerAssigneeInstances cai on cai.id = b.id
		--LEFT OUTER JOIN QCheck_PendingApprovals pa on pa.activechecklistid = a.id
		LEFT OUTER JOIN QCheck_MostRecentDeadlineRequests mrdr
				ON a.ID = mrdr.ActiveChecklistID
		LEFT OUTER JOIN QCheck_Approval_ChangeRequests cr
			ON cr.ID = mrdr.ChangeRequestID
		LEFT OUTER JOIN QCheck_Approval_ActiveChecklists aac
				ON aac.ChangeRequestID = CR.[ID]
				AND aac.ActiveChecklistID = mrdr.ActiveChecklistID
	 WHERE
		-- 3/30/2016 dalvarado - removing this filter so you can see past completed items
		--(a.CompletedDate is null or (DatePart(month,a.CompletedDate) = DatePart(month,getDate()) and DatePart(day,a.CompletedDate) = DatePart(day,getDate()) and DatePart(year,a.CompletedDate) = DatePart(year,getDate()))) AND 
		(@activeChecklistID = 0 or a.ID = @activeChecklistID)
		AND @instanceID = 0
		AND a.dueTime between @startDate and @endDate

	UNION 
	
	-- get future checklists
	SELECT 
		c.ID As ChecklistID,
		c.Name as ChecklistName, 
		c.CreateDate,
		b.ID As Identifier,
		upcoming1.ID as UniqueID, 
		upcoming1.DueTime as dueTime, 
		upcoming1.ID as UpcomingID,
		null As ActiveChkCompletedDate, 
		--f.ID as AssignmentID, 
		'12/12/9999' As Computed, 	
		2 As ChkType, 
		upcoming1.DueTime as dueSort,
		CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as Recurring,
		CASE WHEN s.freqType = 1 THEN 'One Time' 
			 WHEN s.freqType = 2 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Daily' ELSE 'Every ' + CONVERT(varchar,s.freqRecurrance) + ' days' END 
			 WHEN s.freqType = 3 THEN 
					CASE WHEN s.freqRecurrance = 1 THEN 
							'Weekly' 
					ELSE 
							'Every ' + CONVERT(varchar,s.freqRecurrance) + ' weeks' 
					END + CASE WHEN s.freqInterval > 0 THEN ' on ' + dbo.QCheck_GetDaysFromInterval(s.freqInterval) ELSE '' END
			 WHEN s.freqType = 4 and  s.freqRecurrance <> 3 THEN CASE WHEN s.freqRecurrance = 1 THEN 'Monthly' ELSE 'Every' + CONVERT(varchar,s.freqRecurrance) + ' months' END
			 WHEN s.freqType = 4 and  s.freqRecurrance = 3 THEN 'Quarterly'  
 			 WHEN s.freqType = 5 THEN 
					CASE WHEN s.freqRecurrance = 1 THEN 
							'Yearly' 
					ELSE 
							'Every ' + CONVERT(varchar,s.freqRecurrance) + ' years'  
					END + CASE WHEN s.freqInterval > 0 THEN ' in ' + dbo.QCheck_GetMonthsFromInterval(s.freqInterval) ELSE '' END
			ELSE '' END as ScheduleString,
		--dbo.QStatus_GetChecklistControllers(c.ID) AS Controllers,
		isnull(ccl.controllers, '') as Controllers,
		'' as StatusReportString,
		isnull(al.assignees,'') as Assignees,
		case when ms.checklistid is null then 0 else 1 end as MultiStep,
		case when cai.id is null then 0 else 1 end as ControllerPartOfAssignee,
		AL.assigneecount,
		0 as PendingChange, 
		null as NewDeadline,
		0 as isna, 
		'' as nareason
	FROM
		QCheck_ChecklistInstances b
		INNER JOIN QCheck_UpcomingDueTimes upcoming1
			ON b.ID = upcoming1.instanceID
			and upcoming1.DueTime between @StartDate and @EndDate
		INNER JOIN QCheck_Schedule s 
			ON b.ScheduleID = s.ID 
			and Not (s.freqType = 1 and @recurrance = 2) 
			and Not (s.freqType > 1 and @recurrance = 1)
		INNER JOIN QCheck_Checklists c 
			on b.checklistID = c.ID 
			AND c.IsDeleted = 0
		INNER JOIN QCheck_GroupMembership gm 
			on gm. UserID = @UserID
		INNER JOIN QCheck_Groups g
			on g.ID = gm.GroupID
		INNER JOIN QCheck_Assignments f  
			on f.GroupID = gm.GroupID
			And f.IsDeleted = 0 
			and f.InstanceID = b.ID
		LEFT OUTER JOIN QCheck_ActiveChecklists ac
			ON ac.InstanceID = upcoming1.InstanceID
			AND ac.OrigDueTime = upcoming1.DueTime
		LEFT OUTER JOIN QCheck_ChecklistControllersList ccl on ccl.checklistid = c.id
		LEFT OUTER JOIN	dbo.QCheck_AssigneeLookup AL on b.ID=al.InstanceID
		LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
		LEFT OUTER JOIN QCheck_ControllerAssigneeInstances cai on cai.id = b.id
	WHERE 
		not b.isDeleted = 1 
		AND (@instanceID = 0 or b.ID = @instanceID)
		AND @activeChecklistID = 0
		AND ac.ID is null
		AND @recurrance < 3
		
	ORDER BY --ChkType,
		Computed desc,
		dueSort,
		ChecklistName,
		Identifier


	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ChecklistId
		FROM #result
		WHERE ChecklistId IS NOT NULL
	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	-- return result
	SELECT * FROM #result
END