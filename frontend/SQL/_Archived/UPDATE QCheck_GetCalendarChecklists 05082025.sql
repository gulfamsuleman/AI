
GO

/****** Object:  StoredProcedure [dbo].[QCheck_GetCalendarChecklists]    Script Date: 5/8/2025 8:33:17 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE OR ALTER PROC [dbo].[QCheck_GetCalendarChecklists](
	@UserID int,
	@startDate datetime,
	@endDate datetime,
	@ID varchar(8000) = 0,
	@ShowStatusCalendar bit = 0,
	@ShowAlertEmails bit = 1,
	@pushReminders bit = 0
	) 
	as 
	begin
	DECLARE @User_ID int
		,@start_Date datetime
		,@end_Date datetime
		,@ID_ varchar(8000)
		,@Show_Status_Calendar bit = 0
		,@Show_Alert_Emails bit = 1
	SELECT @User_ID = @UserID
		,@start_Date = @startDate
		,@end_Date = @endDate
		,@ID_ = @ID
		,@Show_Status_Calendar = @ShowStatusCalendar
		,@Show_Alert_Emails = @ShowAlertEmails

	SET NOCOUNT ON

	DECLARE @ID_s table(
		ID int
	)
	INSERT INTO @ID_s SELECT CAST(Data as int) FROM dbo.Util_Split(@ID_,',')
	
	DECLARE @tblAssigned table(
		ID int
	)
	DECLARE @tblAssignee table(
		ID int
	)
	DECLARE @tblManaged table(
		ID int
	)
	
	DECLARE @tblStatusControlled table(
		ID int
	)	
	DECLARE @tblStatusSupervised table(
		ID int
	)
	DECLARE @tblScheduledAlerts table(
		ID int,
		AlertID int
	)
	DECLARE @tblPendingChanges table(
		ActiveChecklistID INT,
		ChangeID INT,
		NewDeadline DATETIME
	)
	
	DECLARE @tblResults table(
		objID int, 
		ChecklistID int, 
		ChecklistName varchar(500),  
		DueTime datetime, 
		ReminderDate datetime,
		type int,
		active int,
		assignedto int,
		ismanager int,
		isRecurring bit,
		PendingChange bit,
		ChangeID int,
		NewDeadline datetime,
		IsNA bit,
		isAlert bit,
		AlertID int,
		isEmailScheduled bit,
		MultiStep bit,
		IsPriority bit,
		OriginalDeadline datetime
	)
	
	IF @User_ID <> 5000 BEGIN
		INSERT INTO @tblPendingChanges (
			ActiveChecklistID,
			ChangeID,
			NewDeadline
		)
			SELECT 
				AAC.ActiveChecklistID,
				CR.[ID],
				AAC.DueTime
			FROM 
				QCheck_Approval_ChangeRequests CR WITH (NOLOCK)
				INNER JOIN QCheck_Approval_ActiveChecklists AAC WITH (NOLOCK)
					ON AAC.ChangeRequestID = CR.[ID]
				-- 3/25/2013 dalvarado - Created this view and joined it here to eliminate duplicate entries
				-- on the calendar view when you have multiple outstanding change requests for a task.
				INNER JOIN QCheck_MostRecentDeadlineRequests MRDR WITH (NOLOCK)
					ON AAC.ActiveChecklistID = MRDR.ActiveChecklistID
					AND CR.ID = MRDR.ChangeRequestID
			WHERE 
				CR.IsActive = 1
				AND CR.Approved = 0
				AND CR.Rejected = 0
				AND CR.ReadyForSupervisor = 1
	
		INSERT INTO @tblAssigned
		SELECT a.InstanceID
		FROM 
			QCheck_Assignments a WITH (NOLOCK)
			INNER JOIN QCheck_Groups g WITH (NOLOCK)
				on g.ID = a.GroupID
			INNER JOIN QCheck_Groupmembership gm WITH (NOLOCK)
				on gm.GroupID = g.ID
				and gm.UserID = @User_ID
		WHERE a.IsDeleted = 0

		INSERT INTO @tblAssignee
		SELECT a.InstanceID
		FROM 
			QCheck_Assignments a WITH (NOLOCK)
			INNER JOIN QCheck_Groups g WITH (NOLOCK)
				on g.ID = a.GroupID
			INNER JOIN QCheck_Groupmembership gm WITH (NOLOCK)
				on gm.GroupID = g.ID
				and gm.UserID IN (SELECT ID FROM @ID_s)
			--Failsafe against query string hacking; @User_ID and @ID_ must have a supervisor/report relationship
			INNER JOIN (
				SELECT u.ID
				FROM QCheck_Users U WITH (NOLOCK)
					INNER JOIN QStatus_Report R WITH (NOLOCK)
						ON U.FullName = R.[Name]	
						AND r.IsDeleted = 0
					INNER JOIN QStatus_Supervisors S WITH (NOLOCK)
						ON R.[ID] = S.ReportID			
						AND s.AsOf < GETUTCDATE()
						AND (s.DirectSupervisor = 1 
							OR s.InterestedParty = 1)
					INNER JOIN QCheck_Groups G WITH (NOLOCK)
						ON S.SupervisorGroupID = G.[ID]			
					INNER JOIN QCheck_Users SU WITH (NOLOCK)
						ON G.Owner = SU.[ID]
						AND su.IsDeleted = 0
						AND SU.[ID] = @User_ID
					WHERE
						U.IsDeleted = 0
						AND U.ID IN (SELECT ID FROM @ID_s)
			) X ON x.ID = gm.UserID
		WHERE a.IsDeleted = 0		
	
		INSERT INTO @tblManaged
		SELECT ci.ID
		FROM 
			QCheck_ChecklistInstances ci WITH (NOLOCK)
			INNER JOIN QCheck_Checklists c WITH (NOLOCK)
				on c.ID = ci.ChecklistID
				and c.IsDeleted = 0
				and ci.IsDeleted = 0
			INNER JOIN QCheck_ChecklistManagers cm WITH (NOLOCK)
				on cm.ChecklistID = c.ID
				and cm.IsDeleted = 0
			INNER JOIN QCheck_Groups g WITH (NOLOCK)
				on g.ID = cm.ManagerGroupID
			INNER JOIN QCheck_Groupmembership gm WITH (NOLOCK)
				on gm.GroupID = g.ID
				and gm.UserID = @User_ID

		INSERT INTO @tblStatusControlled
		SELECT r.ID 
		FROM 
			QStatus_Report r WITH (NOLOCK)
			INNER JOIN QStatus_GroupReport gr WITH (NOLOCK)
				ON gr.ReportID = r.ID
			INNER JOIN QCheck_Groups g WITH (NOLOCK)
				ON g.ID = gr.GroupID
			INNER JOIN QCheck_GroupMembership gm WITH (NOLOCK)
				ON gm.GroupID = g.ID
				AND gm.UserID = @User_ID			
		WHERE
			r.IsDeleted = 0
			AND (
				r.ID IN (SELECT ID FROM @ID_s)
				or -1 IN (SELECT ID FROM @ID_s)		
			)
	
		INSERT INTO @tblStatusSupervised
		SELECT r.ID 
		FROM 
			QStatus_Report r WITH (NOLOCK)
			INNER JOIN QStatus_Supervisors sup WITH (NOLOCK)
				ON sup.ReportID = r.ID
				AND sup.DirectSupervisor = 1
			INNER JOIN QCheck_Groups g WITH (NOLOCK)
				ON g.ID = sup.SupervisorGroupID
			INNER JOIN QCheck_GroupMembership gm WITH (NOLOCK)
				ON gm.GroupID = g.ID
				AND gm.UserID = @User_ID	
		WHERE
			r.IsDeleted = 0
			AND EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, r.ID))			
		--KVS 2017-10-30 - Adding alerts as a viewable calendar item
		INSERT INTO @tblScheduledAlerts
		SELECT a.InstanceID,
			al.ID
		FROM 
			QCheck_Assignments a WITH (NOLOCK)
			INNER JOIN QCheck_Alerts al
				ON al.InstanceID = a.InstanceID
				AND al.IsDeleted = 0				
			INNER JOIN QCheck_Groups g WITH (NOLOCK)
				ON (al.AlerteeGroupID IS NULL AND g.ID = a.GroupID)
				OR al.AlerteeGroupID = g.ID
			INNER JOIN QCheck_Groupmembership gm WITH (NOLOCK)
				on gm.GroupID = g.ID
				and gm.UserID = @User_ID
		WHERE a.IsDeleted = 0 
		
		-- ****************************************
		-- All or assigned to me
		IF EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, 0)) 
		BEGIN
			-- Current tasks assigned to me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime,
				ac.ReminderDate,
				1 AS type, --meaning current
				case when ac.completeddate is null then 1 else 0 end as active,
				1,
				CASE WHEN tm.ID is null then 0 else 1 end as ismanager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				CASE WHEN pc.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
				ISNULL(pc.ChangeID, -1) AS ChangeID,
				ISNULL(pc.NewDeadline, ac.DueTime) AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as IsAlert,
				aa.ID as AlertID,
				CASE WHEN a.ID IS NULL OR @Show_Alert_Emails = 0 THEN 0 ELSE 1 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac  WITH (NOLOCK)
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @start_Date and @end_Date
						OR ac.ReminderDate BETWEEN @start_Date and @end_Date
						OR (ac.ReminderDate < @start_Date and ac.DueTime > @end_Date and ac.completeddate is not null) -- old reminder that may still need to show
					)
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK)
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID
				LEFT OUTER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				LEFT OUTER JOIN QCheck_Alerts a WITH (NOLOCK)
					ON al.AlertID = a.ID
					AND a.AlertType = 'Overdue'
				LEFT OUTER JOIN QCheck_ActiveAlerts aa WITH (NOLOCK)
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms WITH (NOLOCK)
					on ms.checklistid = c.ID	
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p				
			WHERE
				EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, 0)) 
			-- Future tasks assigned to me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				NULL AS ReminderDate,
				3 AS type, --meaning future
				1 as active,
				1,
				CASE WHEN tm.ID is null then 0 else 1 end as ismanager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				0 As IsNA,
				0 as IsAlert,
				aa.ID as AlertID,
				CASE WHEN a.ID IS NULL OR @Show_Alert_Emails = 0 THEN 0 ELSE 1 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				null as OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_UpcomingDueTimes ac WITH (NOLOCK)
					on ac.InstanceID = ci.ID 
					AND ac.DueTime BETWEEN @start_Date and @end_Date
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK)
					ON ci.ScheduleID = s.ID
				LEFT OUTER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				LEFT OUTER JOIN QCheck_Alerts a WITH (NOLOCK)
					ON al.AlertID = a.ID
					AND a.AlertType = 'Overdue'
				LEFT OUTER JOIN QCheck_ActiveAlerts aa WITH (NOLOCK)
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms WITH (NOLOCK)
					on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p			
			WHERE
				EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, 0)) 
	
			-- Past tasks assigned to me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime,
				ac.ReminderDate,
				2 AS type, --meaning past
				0 as active,
				1,
				CASE WHEN tm.ID is null then 0 else 1 end as ismanager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as IsAlert,
				a.ID as AlertID,
				CASE WHEN a.ID IS NULL OR @Show_Alert_Emails = 0 THEN 0 ELSE 1 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklistArchive ac WITH (NOLOCK)
					on ac.InstanceID = ci.ID 
					AND CAST(GETUTCDATE() as date) > @start_Date
					AND (
						ac.DueTime BETWEEN @start_Date and @end_Date
						OR ac.ReminderDate BETWEEN @start_Date and @end_Date
						OR (ac.ReminderDate < @start_Date and ac.DueTime > @end_Date and ac.completeddate is not null) -- old reminder that may still need to show
					)
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK) 
					ON ci.ScheduleID = s.ID
				LEFT OUTER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				LEFT OUTER JOIN QCheck_Alerts a WITH (NOLOCK)
					ON al.AlertID = a.ID
					AND a.AlertType = 'Overdue'
				LEFT OUTER JOIN QCheck_ActiveAlerts aa WITH (NOLOCK)
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms WITH (NOLOCK)
					on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p		
			WHERE
				EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, 0)) 
		END
		-- ****************************************
		-- Managed by me
		IF EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, -2)) 
			OR (EXISTS (SELECT 'Y' FROM @ID_s WHERE ID > 0) and @Show_Status_Calendar = 0)
		BEGIN
			-- IF @ID_ = -2, *only* show tasks controlled by the user (ignore supervisor or group membership)
			-- IF ID > 0, show any task where the assignee's status report is visible to the user
			
			-- Current tasks managed by me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				ac.ReminderDate,
				1 AS type, --meaning current
				case when ac.completeddate is null then 1 else 0 end as active,
				CASE WHEN ta.ID is null then 0 else 1 end as assignedto,
				CASE WHEN tm.ID is null then 0 else 1 end as isManager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				CASE WHEN pc.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
				ISNULL(pc.ChangeID, -1) AS ChangeID,
				ISNULL(pc.NewDeadline, ac.DueTime) AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as isAlert,
				NULL as AlertID,
				0 as isEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac WITH (NOLOCK)
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @start_Date and @end_Date
						OR ac.ReminderDate BETWEEN @start_Date and @end_Date
						OR (ac.ReminderDate < @start_Date and ac.DueTime > @end_Date and ac.completeddate is not null) -- old reminder that may still need to show
					)
				INNER JOIN QCheck_ActiveAssignments aa WITH (NOLOCK)
					on aa.ActiveChecklistID = ac.ID
				INNER JOIN QCheck_Assignments a WITH (NOLOCK)
					on a.ID = aa.AssignmentsID
					and a.isdeleted = 0
				INNER JOIN QCheck_Groups g WITH (NOLOCK)
					on g.ID = a.GroupID
				INNER JOIN QCheck_Groupmembership gm WITH (NOLOCK)
					on gm.GroupID = g.ID
					and (
						EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, -2)) 
						OR (
							EXISTS (SELECT 'Y' FROM @ID_s WHERE ID > 0) 
							and @Show_Status_Calendar = 0
							and gm.UserID IN (select ID FROM @ID_s)
						)
					)
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblAssignee ta2
					on ta2.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm 
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK)
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID		
				LEFT OUTER JOIN QCheck_MultiStep ms WITH (NOLOCK)
					on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p
			WHERE
				(tm.ID is not null OR (-2 NOT IN (SELECT ID FROM @ID_s) AND ta2.ID IS NOT NULL))
	
			-- Future tasks managed by me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				NULL AS ReminderDate,
				3 AS type, --meaning current
				1 as active,
				CASE WHEN ta.ID is null then 0 else 1 end as assignedto,
				CASE WHEN tm.ID is null then 0 else 1 end as isManager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				0 AS IsNA,
				0 as isAlert,
				NULL as AlertID,
				0 as isEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				null as OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_UpcomingDueTimes ac WITH (NOLOCK)
					on ac.InstanceID = ci.ID 
					AND ac.DueTime BETWEEN @start_Date and @end_Date
				INNER JOIN QCheck_Assignments a WITH (NOLOCK)
					on a.InstanceID = ci.ID
					and a.isdeleted = 0
				INNER JOIN QCheck_Groups g WITH (NOLOCK)
					on g.ID = a.GroupID
				INNER JOIN QCheck_Groupmembership gm WITH (NOLOCK)
					on gm.GroupID = g.ID
					and (
						EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, -2)) 
						OR (
							EXISTS (SELECT 'Y' FROM @ID_s WHERE ID > 0) 
							and @Show_Status_Calendar = 0
							and gm.UserID IN (select ID FROM @ID_s)
						)
					)
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblAssignee ta2
					on ta2.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm 
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK)
					ON ci.ScheduleID = s.ID 		
				LEFT OUTER JOIN QCheck_MultiStep ms WITH (NOLOCK)
					on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p
			WHERE
				(tm.ID is not null OR (-2 NOT IN (SELECT ID FROM @ID_s) AND ta2.ID IS NOT NULL))	
			-- Past tasks managed by me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				ac.ReminderDate,
				2 AS type, --meaning past
				0 as active,
				CASE WHEN ta.ID is null then 0 else 1 end as assignedto,
				CASE WHEN tm.ID is null then 0 else 1 end as isManager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as isAlert,
				NULL as AlertID,
				0 as isEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklistArchive ac WITH (NOLOCK)
					on ac.InstanceID = ci.ID 
					AND CAST(GETUTCDATE() as date) > @start_Date			
					AND (
						ac.DueTime BETWEEN @start_Date and @end_Date
						OR ac.ReminderDate BETWEEN @start_Date and @end_Date
						OR (ac.ReminderDate < @start_Date and ac.DueTime > @end_Date and ac.completeddate is not null) -- old reminder that may still need to show
					)
				INNER JOIN QCheck_Assignments a WITH (NOLOCK)
					on a.InstanceID = ci.ID
					and a.isdeleted = 0
				INNER JOIN QCheck_Groups g WITH (NOLOCK)
					on g.ID = a.GroupID
				INNER JOIN QCheck_Groupmembership gm WITH (NOLOCK)
					on gm.GroupID = g.ID
					and (
						EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, -2)) 
						OR (
							EXISTS (SELECT 'Y' FROM @ID_s WHERE ID > 0) 
							and @Show_Status_Calendar = 0
							and gm.UserID IN (select ID FROM @ID_s)
						)
					)
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblAssignee ta2
					on ta2.ID = ci.ID
				left outer JOIN @tblManaged tm 
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK)
					ON ci.ScheduleID = s.ID 		
				LEFT OUTER JOIN QCheck_MultiStep ms WITH (NOLOCK)
					on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p
			WHERE
				(tm.ID is not null OR (-2 NOT IN (SELECT ID FROM @ID_s) AND ta2.ID IS NOT NULL))	
		END
	
		-- ****************************************
		-- Status
		IF EXISTS (SELECT 'Y' FROM @ID_s WHERE ID = -1) OR @Show_Status_Calendar = 1
		BEGIN
			
			-- Current tasks on status report
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				ac.ReminderDate,
				1 AS type, --meaning current
				case when ac.completeddate is null then 1 else 0 end as active,
				CASE WHEN ta.ID is null then 0 else 1 end,
				CASE WHEN tm.ID is null then 0 else 1 end,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				CASE WHEN pc.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
				ISNULL(pc.ChangeID, -1) AS ChangeID,
				ISNULL(pc.NewDeadline, ac.DueTime) AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as isAlert,
				NULL as AlertID,
				0 as isEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac WITH (NOLOCK)
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @start_Date and @end_Date
						OR ac.ReminderDate BETWEEN @start_Date and @end_Date
						OR (ac.ReminderDate < @start_Date and ac.DueTime > @end_Date and ac.completeddate is not null) -- old reminder that may still need to show
					)
				INNER JOIN QStatus_ActiveChecklistTaskType actt WITH (NOLOCK)
					on actt.ActiveChecklistID = ac.ID
				INNER JOIN QStatus_TaskTypes tt WITH (NOLOCK)
					ON tt.ID = actt.TaskType
				LEFT OUTER JOIN @tblStatusControlled tc
					ON tc.ID = tt.ReportID
				LEFT OUTER JOIN @tblStatusSupervised tss
					ON tss.ID = tt.ReportID
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK)
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID		
				LEFT OUTER JOIN QCheck_MultiStep ms WITH (NOLOCK)
					on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p
			WHERE 
				NOT (
					tc.ID is null 
					and tss.ID is null
				)
	
			-- Future tasks on status report
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				NULL AS ReminderDate,
				3 AS type, --meaning future
				1 as active,
				CASE WHEN ta.ID is null then 0 else 1 end,
				CASE WHEN tm.ID is null then 0 else 1 end,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				0 AS IsNA,
				0 as isAlert,
				NULL as AlertID,
				0 as isEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				null as OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_UpcomingDueTimes ac WITH (NOLOCK)
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @start_Date and @end_Date
						OR ac.DueTime BETWEEN @start_Date and @end_Date
					)
				INNER JOIN QStatus_InstanceTaskType itt WITH (NOLOCK)
					on itt.InstanceID = ci.ID
				INNER JOIN QStatus_TaskTypes tt WITH (NOLOCK)
					ON tt.ID = itt.TaskType
				LEFT OUTER JOIN @tblStatusControlled tc
					ON tc.ID = tt.ReportID
				LEFT OUTER JOIN @tblStatusSupervised tss
					ON tss.ID = tt.ReportID
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK)
					ON ci.ScheduleID = s.ID 		
				LEFT OUTER JOIN QCheck_MultiStep ms WITH (NOLOCK)
					on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p
			WHERE 
				NOT (
					tss.ID is null 
					and tc.ID is null
				)
	
			-- Past tasks on status report
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				ac.ReminderDate,
				2 AS type, --meaning past
				0 as active,
				CASE WHEN ta.ID is null then 0 else 1 end,
				CASE WHEN tm.ID is null then 0 else 1 end,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as isAlert,
				NULL as AlertID,
				0 as isEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklistArchive ac WITH (NOLOCK)
					on ac.InstanceID = ci.ID
					AND CAST(GETUTCDATE() as date) > @start_Date		
					AND (
						ac.DueTime BETWEEN @start_Date and @end_Date
						OR ac.ReminderDate BETWEEN @start_Date and @end_Date
						OR (ac.ReminderDate < @start_Date and ac.DueTime > @end_Date and ac.completeddate is not null) -- old reminder that may still need to show
					)
				INNER JOIN QStatus_InstanceTaskType itt WITH (NOLOCK)
					on itt.InstanceID = ci.ID
				INNER JOIN QStatus_TaskTypes tt WITH (NOLOCK)
					ON tt.ID = itt.TaskType
				LEFT OUTER JOIN @tblStatusControlled tc
					ON tc.ID = tt.ReportID
				LEFT OUTER JOIN @tblStatusSupervised tss
					ON tss.ID = tt.ReportID
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK)
					ON ci.ScheduleID = s.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms WITH (NOLOCK)
					on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p
			WHERE 
				NOT (
					tss.ID is null 
					and tc.ID is null
				)
		END
		-- ****************************************
		-- Overdue tasks
		
		-- All or assigned to me
		IF EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, 0)) BEGIN
			-- Overdue tasks assigned to me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime,
				ac.ReminderDate,
				1 AS type, --meaning current
				case when ac.completeddate is null then 1 else 0 end as active,
				1,
				CASE WHEN tm.ID is null then 0 else 1 end as ismanager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				CASE WHEN pc.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
				ISNULL(pc.ChangeID, -1) AS ChangeID,
				ISNULL(pc.NewDeadline, ac.DueTime) AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as IsAlert,
				aa.ID as AlertID,
				CASE WHEN a.ID IS NULL THEN 0 ELSE 1 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac WITH (NOLOCK)
					on ac.InstanceID = ci.ID 
					AND ac.DueTime < @start_Date
					AND ac.DueTime < GETUTCDATE() -- Only overdue stuff, not active tasks in future weeks
					AND ac.CompletedDate IS NULL
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK)
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID
				LEFT OUTER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				LEFT OUTER JOIN QCheck_Alerts a WITH (NOLOCK)
					ON al.AlertID = a.ID
					AND a.AlertType = 'Overdue'
				LEFT OUTER JOIN QCheck_ActiveAlerts aa WITH (NOLOCK)
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms WITH (NOLOCK)
					on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p		
			WHERE
				EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, 0))
				
		END
		
		-- Managed by me
		IF EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, -2)) 
			OR (EXISTS (SELECT 'Y' FROM @ID_s WHERE ID > 0) and @Show_Status_Calendar = 0)		
		BEGIN
			-- Overdue tasks managed by me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				ac.ReminderDate,
				1 AS type, --meaning current
				case when ac.completeddate is null then 1 else 0 end as active,
				CASE WHEN ta.ID is null then 0 else 1 end as assignedto,
				CASE WHEN tm.ID is null then 0 else 1 end as isManager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				CASE WHEN pc.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
				ISNULL(pc.ChangeID, -1) AS ChangeID,
				ISNULL(pc.NewDeadline, ac.DueTime) AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as IsAlert,
				NULL as AlertID,
				0 as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac WITH (NOLOCK)
					on ac.InstanceID = ci.ID 
					AND ac.DueTime < @start_Date
					AND ac.DueTime < GETUTCDATE() -- Only overdue stuff, not active tasks in future weeks
					AND ac.CompletedDate IS NULL
				INNER JOIN QCheck_ActiveAssignments aa WITH (NOLOCK)
					on aa.ActiveChecklistID = ac.ID
				INNER JOIN QCheck_Assignments a WITH (NOLOCK)
					on a.ID = aa.AssignmentsID
					and a.isdeleted = 0
				INNER JOIN QCheck_Groups g WITH (NOLOCK)
					on g.ID = a.GroupID
				INNER JOIN QCheck_Groupmembership gm WITH (NOLOCK)
					on gm.GroupID = g.ID
					and (
						EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, -2)) 
						OR (
							EXISTS (SELECT 'Y' FROM @ID_s WHERE ID > 0) 
							and @Show_Status_Calendar = 0
							and gm.UserID IN (select ID FROM @ID_s)
						)
					)
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblAssignee ta2
					on ta2.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK)
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID		
				LEFT OUTER JOIN QCheck_MultiStep ms WITH (NOLOCK)
					on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p	
			WHERE
				(tm.ID is not null OR (-2 NOT IN (SELECT ID FROM @ID_s) AND ta2.ID IS NOT NULL))		
		END
		
		-- Status
		IF EXISTS (SELECT 'Y' FROM @ID_s WHERE ID = -1) OR @Show_Status_Calendar = 1
		BEGIN
			
			-- Overdue tasks on status report
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name as ChecklistName, 
				ac.DueTime, 
				ac.ReminderDate,
				1 AS type, --meaning current
				case when ac.completeddate is null then 1 else 0 end as active,
				CASE WHEN ta.ID is null then 0 else 1 end,
				CASE WHEN tm.ID is null then 0 else 1 end,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				CASE WHEN pc.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
				ISNULL(pc.ChangeID, -1) AS ChangeID,
				ISNULL(pc.NewDeadline, ac.DueTime) AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				0 as IsAlert,
				NULL as AlertID,
				0 as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac WITH (NOLOCK)
					on ac.InstanceID = ci.ID 
					AND ac.DueTime < @start_Date
					AND ac.DueTime < GETUTCDATE() -- Only overdue stuff, not active tasks in future weeks
					AND ac.CompletedDate IS NULL
				INNER JOIN QStatus_ActiveChecklistTaskType actt WITH (NOLOCK)
					on actt.ActiveChecklistID = ac.ID
				INNER JOIN QStatus_TaskTypes tt WITH (NOLOCK)
					ON tt.ID = actt.TaskType
				LEFT OUTER JOIN @tblStatusControlled tc
					ON tc.ID = tt.ReportID
				LEFT OUTER JOIN @tblStatusSupervised tss
					ON tss.ID = tt.ReportID
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK)
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID
				LEFT OUTER JOIN QCheck_MultiStep ms	WITH (NOLOCK)
					on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p
			WHERE 
				NOT (
					tc.ID is null 
					and tss.ID is null
				)
				
		END
		-- ****************************************
		-- Email reminders - Assigned ONLY
		IF EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, 0)) and @Show_Alert_Emails = 1 BEGIN
			-- Current tasks assigned to me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name + (CASE WHEN a.AlertText IS NOT NULL AND a.AlertText <> '' THEN ' - ' + a.AlertText
							WHEN a.AlertType IN ('Reminder') THEN ' - Reminder'
							WHEN a.AlertType IN ('Hours') THEN ' - Overdue Reminder' 
							ELSE ' - Alert' END) as ChecklistName, 
				CASE
					WHEN a.AlertType = 'Hours' OR a.AlertTime < 0 
						THEN DATEADD(minute, IsNull(a.AlertTime * 60, 0), ac.DueTime)
					ELSE DATEADD(minute, IsNull(a.AlertTime * 60, 0),
							DATEADD(day, IsNull(a.DaysBefore, 0) * -1, 
								DateAdd(day, DATEDIFF(day, 0, ac.DueTime),0)))
				END as DueTime,
				NULL as ReminderDate,
				1 AS type, --meaning current
				case when ac.completeddate is null then 1 else 0 end as active,
				1,
				CASE WHEN tm.ID is null then 0 else 1 end as ismanager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				CASE WHEN pc.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
				ISNULL(pc.ChangeID, -1) AS ChangeID,
				ISNULL(pc.NewDeadline, ac.DueTime) AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				1 as IsAlert,
				aa.ID as AlertID,
				CASE WHEN ae.ID IS NULL THEN 1 ELSE 0 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac WITH (NOLOCK)
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @start_Date and @end_Date
						OR ac.ReminderDate BETWEEN @start_Date and @end_Date
						OR (ac.ReminderDate < @start_Date and ac.DueTime > @end_Date and ac.completeddate is not null) -- old reminder that may still need to show
					)
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK)
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID
				INNER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				INNER JOIN QCheck_Alerts a WITH (NOLOCK)
					ON al.AlertID = a.ID
					AND a.AlertType IN ('Reminder', 'Custom', 'Hours')
				INNER JOIN QCheck_ActiveAlerts aa WITH (NOLOCK)
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID
				LEFT OUTER JOIN QCheck_AlertExceptions ae WITH (NOLOCK)
					ON ae.ActiveAlertID = aa.ID
					AND ae.UserID = @User_ID
					AND ae.IsActive = 1		
				LEFT OUTER JOIN QCheck_MultiStep ms WITH (NOLOCK)
					on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p					
			WHERE
				EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, 0))
			-- Future tasks assigned to me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name + IsNull(' - ' + a.AlertText, (CASE 
							WHEN a.AlertType IN ('Reminder') THEN ' - Reminder'
							WHEN a.AlertType IN ('Hours') THEN ' - Overdue Reminder' 
							ELSE ' - Alert' END)) as ChecklistName, 
				CASE 
					WHEN a.AlertType = 'Hours' OR a.AlertTime < 0 
						THEN DATEADD(hour, IsNull(a.AlertTime, 0), ac.DueTime)
					ELSE DATEADD(hour, IsNull(a.AlertTime, 0),
							DATEADD(day, IsNull(a.DaysBefore, 0) * -1, 
								DateAdd(day, DATEDIFF(day, 0, ac.DueTime),0)))
				END as DueTime,
				NULL AS ReminderDate,
				3 AS type, --meaning future
				1 as active,
				1,
				CASE WHEN tm.ID is null then 0 else 1 end as ismanager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				0 As IsNA,
				1 as IsAlert,
				a.ID as AlertID,
				CASE WHEN ae.ID IS NULL THEN 1 ELSE 0 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				null as OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_UpcomingDueTimes ac WITH (NOLOCK)
					on ac.InstanceID = ci.ID 
					AND ac.DueTime BETWEEN @start_Date and @end_Date
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK)
					ON ci.ScheduleID = s.ID
				INNER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				INNER JOIN QCheck_Alerts a WITH (NOLOCK)
					ON al.AlertID = a.ID
					AND a.AlertType IN ('Reminder', 'Custom', 'Hours')
				INNER JOIN QCheck_ActiveAlerts aa WITH (NOLOCK)
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID
				LEFT OUTER JOIN QCheck_AlertExceptions ae WITH (NOLOCK)
					ON ae.ActiveAlertID = aa.ID
					AND ae.UserID = @User_ID
					AND ae.IsActive = 1		
				LEFT OUTER JOIN QCheck_MultiStep ms WITH (NOLOCK)
					on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p				
			WHERE
				EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, 0))
	
			-- Past tasks assigned to me
			INSERT INTO @tblResults
			SELECT 
				ac.ID as objID, 
				c.ID as ChecklistID, 
				c.Name + IsNull(' - ' + a.AlertText, (CASE 
							WHEN a.AlertType IN ('Reminder') THEN ' - Reminder'
							WHEN a.AlertType IN ('Hours') THEN ' - Overdue Reminder' 
							ELSE ' - Alert' END)) as ChecklistName, 
				CASE 
					WHEN a.AlertType = 'Hours' OR a.AlertTime < 0 
						THEN DATEADD(hour, IsNull(a.AlertTime, 0), ac.DueTime)
					ELSE DATEADD(hour, IsNull(a.AlertTime, 0),
							DATEADD(day, IsNull(a.DaysBefore, 0) * -1, 
								DateAdd(day, DATEDIFF(day, 0, ac.DueTime),0)))
				END as DueTime,
				NULL as ReminderDate,
				2 AS type, --meaning past
				0 as active,
				1,
				CASE WHEN tm.ID is null then 0 else 1 end as ismanager,
				CASE WHEN s.freqType > 1 THEN 1 ELSE 0 END as isRecurring,
				0 AS PendingChange,
				-1 AS ChangeID,
				ac.DueTime AS NewDeadline,
				ISNULL(ac.IsNA, 0) AS IsNA,
				1 as IsAlert,
				a.ID as AlertID,
				CASE WHEN ae.ID IS NULL THEN 1 ELSE 0 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci WITH (NOLOCK)
				INNER JOIN QCheck_Checklists c WITH (NOLOCK)
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklistArchive ac WITH (NOLOCK)
					on ac.InstanceID = ci.ID 
					AND CAST(GETUTCDATE() as date) > @start_Date
					AND (
						ac.DueTime BETWEEN @start_Date and @end_Date
						OR ac.ReminderDate BETWEEN @start_Date and @end_Date
						OR (ac.ReminderDate < @start_Date and ac.DueTime > @end_Date and ac.completeddate is not null) -- old reminder that may still need to show
					)
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s WITH (NOLOCK)
					ON ci.ScheduleID = s.ID
				INNER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				INNER JOIN QCheck_Alerts a WITH (NOLOCK)
					ON al.AlertID = a.ID
					AND a.AlertType IN ('Reminder', 'Custom', 'Hours')
				INNER JOIN QCheck_ActiveAlerts aa WITH (NOLOCK)
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID
				LEFT OUTER JOIN QCheck_AlertExceptions ae WITH (NOLOCK)
					ON ae.ActiveAlertID = aa.ID
					AND ae.UserID = @User_ID
					AND ae.IsActive = 1		
				LEFT OUTER JOIN QCheck_MultiStep ms WITH (NOLOCK)
					on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli WITH (NOLOCK)
					JOIN Priorities_Lists pl WITH (NOLOCK)
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @User_ID	
					ORDER BY ListID
				) p			
			WHERE
				EXISTS (SELECT 'Y' FROM @ID_s WHERE ID IN(-1, 0))
		END
	END
/*	
	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ChecklistId FROM @tblResults WHERE ChecklistId IS NOT NULL
	EXEC dbo.Audit_Set @User_ID, @recordIds, 'Checklist', 2
	DELETE @recordIds
	INSERT INTO @recordIds
		SELECT DISTINCT objID FROM @tblResults WHERE objID IS NOT NULL
	EXEC dbo.Audit_Set @User_ID, @recordIds, 'ActiveChecklist', 2
*/
	-- Get the output
	SELECT DISTINCT * 
	FROM 
		@tblResults
	ORDER BY 
		DueTime,
		objID, 
		ChecklistName

	SET NOCOUNT OFF

END
GO


