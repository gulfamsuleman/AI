IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ProcedureExecutionLog]') AND type in (N'U'))
DROP TABLE [dbo].[ProcedureExecutionLog]
GO

CREATE TABLE [dbo].[ProcedureExecutionLog](
	[ProcedureName] [nvarchar](128) NULL,
	[ExecutionTime] [datetime] NULL
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[QCheck_KPITotals]') AND type in (N'U'))
DROP TABLE [dbo].[QCheck_KPITotals]
GO

CREATE TABLE [dbo].[QCheck_KPITotals](
	[fullname] [varchar](100) NULL,
	[userid] [int] NULL,
	[tasks] [int] NULL,
	[prioritylates] [int] NULL,
	[prioritycharge] [int] NULL,
	[tasklates] [int] NULL,
	[taskcharge] [int] NULL,
	[overdue] [int] NULL,
	[supervisorcontrolled] [int] NULL,
	[comments] [int] NULL,
	[taskscompleted] [int] NULL,
	[emailsent] [int] NULL,
	[priorityemails] [int] NULL,
	[taskscreated] [int] NULL,
	[changerequests] [int] NULL,
	[dtRun] [datetime] NULL,
	[numDays] [int] NULL,
	[totalpoints] [int] NULL,
	[recurringtaskscreated] [int] NULL,
	[multisteptaskscreated] [int] NULL
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Qcheck_MonthlyBonusKPIs]') AND type in (N'U'))
DROP TABLE [dbo].[Qcheck_MonthlyBonusKPIs]
GO

CREATE TABLE [dbo].[Qcheck_MonthlyBonusKPIs](
	[FullName] [nvarchar](max) NULL,
	[empid] [int] NULL,
	[bonusgroup] [nvarchar](10) NULL,
	[DT] [datetime] NULL,
	[points] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

CREATE OR ALTER   PROCEDURE [dbo].[Combined_BonusMonthsKPIs]
AS
BEGIN
    DECLARE @Results TABLE (
        FullName NVARCHAR(MAX), 
        empid INT, 
        bonusgroup NVARCHAR(10), 
        dt DATETIME,
        points INT
    );

    ;WITH BonusTests AS (
        SELECT TOP 1 WITH TIES employee, gradeddt
        FROM (
            SELECT *
            FROM PHIProcess..Grading_QProcessTests

            UNION ALL

            SELECT *
            FROM _Reporting..PFS_Grading_QProcessTests
        ) t
        ORDER BY ROW_NUMBER() OVER (PARTITION BY employee ORDER BY gradeddt DESC)
    ),
    Supervisors AS (
        SELECT SupervisorName = u.FullName
        FROM PHIProcess..QStatus_Report r
            JOIN PHIProcess..QStatus_Supervisors s ON s.ReportID = r.ID
            JOIN PHIProcess..QCheck_GroupMembership gm ON gm.GroupID = s.SupervisorGroupID
            JOIN PHIProcess..QCheck_Users u ON u.ID = gm.UserID
        WHERE [Name] = 'ALL MANAGEMENT - SYSTEM REPORT'
    ),
    Users AS (
        SELECT TOP 1 WITH TIES
            FullName,
            startdt = CONVERT(DATE, StartDt),
            enddt = CONVERT(DATE, enddt)
        FROM (
            SELECT u.FullName, b.startdt, b.enddt
            FROM PHIProcess..QCheck_BonusUsers b
                JOIN PHIProcess..QCheck_Users u ON u.ID = b.userid
            WHERE b.startdt <> COALESCE(b.enddt, GETUTCDATE())

            UNION ALL

            SELECT FullName, StartDt, NULL
            FROM _Reporting..PFS_UserList
        ) t
        ORDER BY ROW_NUMBER() OVER (PARTITION BY FullName ORDER BY startdt DESC)
    ),
    bda2 AS (
        SELECT fullname, empid, userid, dt, usage, bonus, bonusgroup
        FROM _Reporting..[PHIProcess_BonusDatesAmounts]

        UNION ALL

        SELECT fullname, empid, userid, dt, usage, bonus, bonusgroup
        FROM _Reporting..PFS_BonusDatesAmounts
    ),
    DailyBonus AS (
        SELECT FullName, empid, bonusgroup, dt,
            SUM(bonus) AS points
        FROM _Reporting..Combined_BonusDatesAmounts
        WHERE dt < '2024-02-01'
        GROUP BY FullName, dt, userid, bonusgroup, empid
        
        UNION ALL

        SELECT FullName, empid, bonusgroup, dt, 
            SUM(CASE WHEN bonus > 30 THEN 30 ELSE bonus END) AS points
        FROM (
                SELECT fullname, empid, bonusgroup, dt = CONVERT(DATE, dt), bonus = SUM(bonus)
                FROM _Reporting..Combined_BonusDatesAmounts
                WHERE dt >= '2024-02-01' AND dt < '2025-01-01'
                GROUP BY fullname, empid, bonusgroup, CONVERT(DATE, dt)
        ) AS t
        GROUP BY FullName, dt, bonusgroup, empid
    ),
    DailyBonus2 AS (
        SELECT t3.fullname, t3.empid, t3.userid, t3.dt, t3.points,
            t3.bonusgroup
        FROM (
            SELECT fullname, empid, userid, dt,
                points = CASE
                    WHEN points > 30 THEN 30
                    WHEN points < 0 THEN 0
                    ELSE points
                END,
                bonusgroup
            FROM (
                SELECT fullname, empid, userid, dt,
                    points = SUM(CASE
                        WHEN usage = 'Sent Status/Priority' AND points > 8 THEN 8
                        ELSE points
                    END),
                    bonusgroup
                FROM (
                    SELECT fullname, empid, userid, dt = CONVERT(DATE, dt), usage, points = SUM(bonus), bonusgroup
                    FROM (
                        SELECT fullname, empid, userid, dt, usage, bonus, bonusgroup 
                        FROM bda2
                        UNION ALL
                        SELECT fullname, empid, userid, dt, usage, bonus, bonusgroup
                        FROM _Reporting..Combined_BonusDatesPenalties
                    ) t
                    WHERE dt >= '2025-01-01'
                    GROUP BY fullname, empid, userid, CONVERT(DATE, dt), usage, bonusgroup
                ) t1
                GROUP BY fullname, empid, userid, dt, bonusgroup
            ) t2
        ) t3
        LEFT JOIN Supervisors s ON s.supervisorname = t3.fullname
        LEFT JOIN Users u ON u.FullName = t3.fullname
        LEFT JOIN BonusTests bt ON bt.employee = t3.fullname
    )
    INSERT INTO @Results
    SELECT d.fullname, d.empid, d.bonusgroup, d.dt, d.points
    FROM DailyBonus d

    UNION ALL

    SELECT fullname, empid, bonusgroup, dt, points = SUM(points)
    FROM DailyBonus2
    GROUP BY fullname, empid, bonusgroup, dt

    -- Uncomment the following line if you want to filter only positive points
    -- HAVING SUM(points) > 0

	DELETE FROM Qcheck_MonthlyBonusKPIs
    INSERT INTO Qcheck_MonthlyBonusKPIs
    SELECT * FROM @Results;
END
GO

CREATE OR ALTER PROCEDURE [dbo].[QCheck_KPI]
(	
	@userid int = 0, 
	@supervisorid int = 0,
	@numdays int = 90
)
as
begin

	declare @users table (
		fullname varchar(100),
		userid int,
		tasks int,
		prioritylates int,
		prioritycharge int,
		tasklates int,
		taskcharge int,
		overdue int,
		supervisorcontrolled int,
		comments int,
		taskscompleted int,
		emailsent int,
		priorityemails int,
		taskscreated int,
		changerequests int,
		totalpoints int,
		multisteptaskscreated int,
		recurringtaskscreated int
	)

	insert into @users select fullname, id, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,0, 0 ,0 from qcheck_users where isdeleted = 0 AND ID = @userid
	
	UPDATE @users
	set changerequests = k.changerequests,
	prioritylates = k.prioritylates,
	prioritycharge = k.prioritycharge,
	tasklates = k.tasklates,
	taskcharge = k.taskcharge,
	taskscompleted = k.taskscompleted,
	taskscreated = k.taskscreated,
	priorityemails = k.priorityemails,
	comments = k.comments,
	tasks = k.tasks,
	overdue = k.overdue,
    supervisorcontrolled = k.supervisorcontrolled,
	totalpoints = k.totalpoints
	FROM @users u
	INNER JOIN QCheck_KPITotals k ON u.fullname = k.fullname AND k.numDays = @numdays;
	
	
	with KPIs as
	(
		select  tasks, prioritylates, prioritycharge, tasklates, taskcharge, overdue, supervisorcontrolled,
			case when tasks = 0 then 0 else cast(supervisorcontrolled / (tasks * 1.0) * 100.0 as int) end as supervisorcontrolledpct, 
			comments, taskscompleted,
			priorityemails, taskscreated, changerequests, totalpoints
		from QCheck_KPITotals
		where numdays = @numdays
	)
	select fullname, tasks, prioritylates, prioritycharge, tasklates, taskcharge, overdue, supervisorcontrolled,
		case when tasks = 0 then 0 else cast(supervisorcontrolled / (tasks * 1.0) * 100.0  as int) end as supervisorcontrolledpct, comments, taskscompleted,
		priorityemails, taskscreated, changerequests, totalpoints
	from @users

	union all 

	select 'MIN' as [fullname],
			min(tasks),
			min(prioritylates),
			min(prioritycharge),
			min(tasklates),
			min(taskcharge),
			min(overdue),
			min(supervisorcontrolled),
			min(supervisorcontrolledpct), 
			min(comments),
			min(taskscompleted),
			min(priorityemails),
			min(taskscreated), 
			min(changerequests),
			MIN(totalpoints)
	from KPIs

	union all

	select 'MAX' as [fullname],
			max(tasks),
			max(prioritylates),
			max(prioritycharge),
			max(tasklates),
			max(taskcharge),
			max(overdue),
			max(supervisorcontrolled),
			max(supervisorcontrolledpct), 
			max(comments),
			max(taskscompleted),
			max(priorityemails),
			max(taskscreated), 
			max(changerequests),
			MAX(totalpoints)
	from KPIs


	union all

	select 'AVG' as [fullname],
			AVG(tasks),
			AVG(prioritylates),
			AVG(prioritycharge),
			AVG(tasklates),
			AVG(taskcharge),
			AVG(overdue),
			AVG(supervisorcontrolled),
			AVG(supervisorcontrolledpct), 
			AVG(comments),
			AVG(taskscompleted),
			AVG(priorityemails),
			AVG(taskscreated), 
			AVG(changerequests),
			AVG(totalpoints)
	from KPIs

end
GO

CREATE OR ALTER PROCEDURE [dbo].[QCheck_KpiSimple] (
@UserIds VARCHAR(MAX),
@numDays INT = 90
)

AS

BEGIN 
	SELECT DISTINCT
	kt.tasks as Tasks,
	kt.tasklates as LateTasks,
	kt.userid as UserId,
	kt.fullname as FullName,
	kt.overdue as OverdueTasks,
	kt.taskscompleted as CompletedTasks,
	kt.prioritylates as LatePriorities,
	kt.priorityemails as PriorityEmails,
	kt.prioritycharge as PriorityCharges,
	kt.comments as CommentsMade,
	kt.taskcharge as TasksCharged,
	kt.emailsent as EmailsSent,
	kt.changerequests as ChangeRequests,
	kt.taskscreated as TasksCreated,
	kt.supervisorcontrolled as SupervisorControlled,
	kt.totalpoints as TotalPoints
	FROM QCheck_KPITotals kt
	WHERE kt.userid IN (SELECT UserName.c from dbo.Util_fn_List_To_Table(@userIds, ',') as UserName)
	AND kt.numDays = @numDays
END
GO

CREATE OR ALTER proc [dbo].[QCheck_KPITotalsCalc] (
@numdays INT = 90
)
AS
BEGIN
	
	declare @users table (
		fullname varchar(100),
		userid int,
		empId int,
		tasks int,
		prioritylates int,
		prioritycharge int,
		tasklates int,
		taskcharge int,
		overdue int,
		supervisorcontrolled int,
		comments int,
		taskscompleted int,
		emailsent int,
		priorityemails int,
		taskscreated int,
		changerequests int,
		totalpoints int,
		multisteptaskscreated int,
		recurringtaskscreated int
	)
	DELETE FROM QCheck_KPITotals WHERE numdays = @numdays
	insert into @users select fullname, id, empID, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 from qcheck_users 
	where 
		(id in (select userid from qstatus_comments where commentdt  > dateadd(day, -1 * @numdays, getutcdate()))
		or id in (select completedby from qcheck_activechecklists_all where completeddate  > dateadd(day, -1 * @numdays, getutcdate())))
		and id > 0

	update @users 
	set changerequests = a.tasks
	from @users u
	cross apply (
		select count(cr.id) as tasks 
		FROM
        QCheck_Approval_ActiveChecklists aac
        INNER JOIN QCheck_Approval_ChangeRequests cr
            ON aac.ChangeRequestID = cr.ID
			AND cr.RequestingUser = u.userID
			AND cr.RequestDate >  DATEADD(DAY, -1 * @NUMDAYS, GETUTCDATE())
	) a


	update @users 
		set prioritylates = isnull(prioritylate.lates, 0),
		prioritycharge = isnull(prioritylate.charge, 0),
		tasklates = isnull(tasklate.lates, 0) ,
		taskcharge = isnull(tasklate.charge, 0) 
	from @users u
		outer apply (select count(id) as lates, sum(latecharge) as charge from PriorityList_LateFee_Log where empid = u.userid and isactive = 1 and latedate > dateadd(day, -1 * @numdays, getutcdate()) ) prioritylate
		outer apply (select count(id) as lates, sum(latecharge) as charge from overduetasks_LateFee_Log where empid = u.userid and isactive = 1 and asofdate > dateadd(day, -1 * @numdays, getutcdate())) tasklate

	update @users 
	set taskscompleted = a.tasks
	from @users u
	cross apply (
		select count(id) as tasks 
		from qcheck_activechecklists_all
		where completedby = u.userid
		and completeddate > dateadd(day, -1 * @numdays, getutcdate())
	) a

	update @users
	set taskscreated = a.tasks
	from @users u
	cross apply (
		select count(id) as tasks 
		from qcheck_checklists
		where owner = u.userid
		and createdate > dateadd(day, -1 * @numdays, getutcdate())
	) a

	update @users set 
		priorityemails = a.emails
	from @users u
	cross apply (
		select count(logid) as emails 
		from QCheck_Log_Emails
		where fromid = u.userid
		and sent > dateadd(day, -1 * @numdays, getutcdate())
	) a

	update @users
		set comments = comm.comments
	from
	@users u
		inner join 
	(
		select u.userid, count(commentdt) as comments
		from
		@users u
			inner join  
		(
			SELECT u.userid, c.Comments, CommentDt = DATEADD(minute, ((DATEDIFF(minute, 0, CommentDt))/1) * 1, 0)
			FROM qstatus_comments_all c
			inner join @users u
			on u.userid = c.userid
			where c.commentdt > dateadd(day, -1 * @numdays, getutcdate())
		) a on a.userid = u.userid
		group by u.userid
	) comm on comm.userid = u.userid

	update @users  
		set tasks = stats.tasks,
		overdue = stats.overdue,
		supervisorcontrolled = stats.supervisorcontrolled
	from
	@users u
		inner join 
	(
		select 
			userid = users.userid,
			tasks = count(distinct case when  ac.DueTime >  DATEADD(DAY, -1 * @NUMDAYS, GETUTCDATE()) then ac.id end), 
			overdue = COUNT(DISTINCT CASE WHEN ac.DueTime > DATEADD(DAY, -1 * @NUMDAYS, GETUTCDATE()) AND ac.DueTime < GETUTCDATE() THEN ac.id END),
			supervisorcontrolled = sum(case when reminder.id is null and ac.DueTime > DATEADD(DAY, -1 * @NUMDAYS, GETUTCDATE()) then 1 else 0 end)
		from 
			@users users
			inner join qcheck_groupmembership gm
				on gm.userid = users.userid
			inner join qcheck_assignments_All a
				on a.groupid = gm.groupid
			inner join qcheck_checklistinstances_All ci
				on ci.id = a.instanceid
				and ci.isdeleted = 0
			inner join qcheck_activechecklists_All ac
				on ac.instanceid = ci.id
				and ac.completeddate is null
			INNER JOIN QCheck_Checklists_All c ON ci.ChecklistID = c.ID
			outer apply (select id from QCheck_ControllerAssigneeInstances_all where id = ci.id) reminder
			group by users.userid
	) stats on stats.userid = u.userid
	

UPDATE u
SET totalpoints = (
    SELECT SUM(k.points)
    FROM Qcheck_MonthlyBonusKPIs k
    WHERE k.FullName = u.FullName
      AND k.Dt >= DATEADD(DAY, -1 * @numdays, GETUTCDATE())
      AND k.Dt < DATEADD(DAY, 1, GETUTCDATE())
    GROUP BY k.FullName
)
FROM @users u
WHERE EXISTS (
    SELECT 1
    FROM Qcheck_MonthlyBonusKPIs k
    WHERE k.FullName = u.FullName
);


	insert into QCheck_KPITotals 
		select 
		fullname,
		userid,
		tasks,
		prioritylates,
		prioritycharge,
		tasklates,
		taskcharge,
		overdue,
		supervisorcontrolled,
		comments,
		taskscompleted,
		emailsent,
		priorityemails,
		taskscreated,
		changerequests,
		dtRun = getdate(),
		numDays = @numdays,
		totalpoints,
		recurringtaskscreated,
		multisteptaskscreated
	from @users

	DELETE FROM ProcedureExecutionLog
	where ProcedureName = 'QCheck_KPITotalsCalc' 

	INSERT INTO ProcedureExecutionLog  (ProcedureName, ExecutionTime)
	VALUES ('QCheck_KPITotalsCalc', GETDATE())

end
GO

CREATE OR ALTER   proc [dbo].[QCheck_RedactedTaskList]
(
	@UserID int,
	@SupervisorID int
)
AS
BEGIN
DECLARE @Timezone VARCHAR(MAX)

set @Timezone = (select ISNULL(TimeZoneOverride, LastTimeZone) FROM QCheck_Users where ID = @SupervisorID)

	select 
		c.ID as ChecklistId,
		a.ID as AssignmentId,
		case when reminder.id is not null or sup.id is not null then
			c.name
		else '<REDACTED>'
		END as ChecklistName, 
		isnull(convert(varchar, duetime, 101), '') as duetime,
		isnull(ccl.controllers, '') as Controllers,
		isnull(trl.reportslist, '') as StatusReportString,
		isnull(al.assignees,'') as Assignees,
		ISNULL(cast(DATEDIFF(day, GETDATE(), cast(ac.duetime as date)) as int), 0) as DaysOutstanding,
		CASE 
		WHEN DATEDIFF(day, GETDATE(), cast(ac.duetime as date)) >= 0 THEN 'NO'
					ELSE 'YES'
				  END as IsDue,
		CASE 
		WHEN ac.Duetime  IS NULL THEN 1
					ELSE 0
				  END as NoDate
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
		LEFT OUTER JOIN	dbo.QCheck_AssigneeLookup AL on a.InstanceID=al.InstanceID
		
		ORDER BY NoDate ASC, ac.DueTime ASC, ChecklistName DESC
END



GO

CREATE OR ALTER PROC [dbo].[QStatus_GetReportListAndTaskCount]
    @UserID int,
    @IncludeDefault bit = 1
AS
BEGIN
    SET NOCOUNT ON;

    -- Temporary table to hold results
   SELECT 
        DISTINCT r.[ID],
        r.name,
        REPLACE(REPLACE(r.Name, '&', '&amp;'), '"', '&quot;') +
		CASE WHEN @IncludeDefault = 0 THEN '' 
        ELSE ISNULL(
                ' (' + 
                CASE DATEDIFF(DAY, CONVERT(datetime, CONVERT(varchar, commentdt, 101)), CONVERT(datetime, CONVERT(varchar, GETUTCDATE(), 101)))
                    WHEN 0 THEN 'today'
                    WHEN 1 THEN '1 day ago'
                    ELSE CONVERT(varchar, DATEDIFF(DAY, CONVERT(datetime, CONVERT(varchar, commentdt, 101)), CONVERT(datetime, CONVERT(varchar, GETUTCDATE(), 101)))) + ' days ago'
                END
                + ')', '')
				END AS [Description],
        cac.ActiveTaskCount
    INTO #result
    FROM QStatus_Report r
    INNER JOIN QStatus_GroupReport gr ON gr.ReportID = r.ID
    INNER JOIN QCheck_Groups g ON g.ID = gr.GroupID
    INNER JOIN QCheck_GroupMembership gm ON gm.GroupID = g.ID AND gm.UserID = @UserID
    LEFT OUTER JOIN QStatus_ReportLastestComments lastcomment ON lastcomment.reportID = r.ID AND lastcomment.userID = @UserID
    CROSS APPLY (
        SELECT COUNT(c.Name) AS ActiveTaskCount 
        FROM QStatus_TaskTypes tt
        INNER JOIN QStatus_InstanceTaskType itt ON itt.TaskType = tt.ID
        INNER JOIN QCheck_ChecklistInstances ci ON ci.ID = itt.InstanceID
        INNER JOIN QCheck_Checklists c ON c.ID = ci.ChecklistID
        INNER JOIN QCheck_Schedule s ON s.ID = ci.ScheduleID
        INNER JOIN QCheck_ActiveChecklists ac ON ac.InstanceID = ci.ID 
        WHERE r.ID = tt.ReportID
        AND tt.Description NOT LIKE 'Completed%'
        AND ac.CompletedDate IS NOT NULL 
        AND ac.CompletedDate < GETUTCDATE()
		AND gm.UserID = @UserID
    ) cac
    WHERE r.IsDeleted = 0
    GROUP BY r.ID, r.[Name], commentdt, cac.ActiveTaskCount

    DECLARE @recordIds TABLE (ID INT); -- Adjusted to use a table variable
    INSERT INTO @recordIds
        SELECT DISTINCT ID FROM #result;
    
    SELECT * FROM #result 
    ORDER BY [Name];
END
GO

CREATE OR ALTER PROCEDURE [dbo].[QCheck_GetSupervisedUsersByGroup](
	@SupervisorID INT
)
 AS

BEGIN

	SET NOCOUNT ON

SELECT DISTINCT g3.ID, g3.name as GroupName
 FROM QCheck_Users U -- user supervised
  INNER JOIN QCheck_GroupMembership gm --  groups for user supervised
   on gm.userid = u.id
  INNER JOIN QCheck_Groups g1
   on g1.id = gm.groupid
  INNER JOIN QStatus_GroupReport GR -- status reports for user supervised
   ON GR.groupid = g1.id
   and gr.defaultreport = 1
  INNER JOIN QStatus_Report R
   ON r.id = gr.reportid
   AND r.IsDeleted = 0
   AND (r.name = u.fullname or r.name not in (select fullname from qcheck_users where isdeleted = 0))
  INNER JOIN QStatus_Supervisors S --supervisors of those reports
   ON R.[ID] = S.ReportID   
   AND s.AsOf < GetUtcDate()
   AND s.DirectSupervisor = 1 
   AND s.interestedparty = 0
  INNER JOIN QCheck_Groups G 
   ON S.SupervisorGroupID = G.[ID] 
   INNER JOIN QCheck_GroupMembership gm2
   on gm2.groupid = g.id
   INNER JOIN QCheck_Users su   --supervisor User 
   on su.[ID] = gm2.userid
   and su.[ID] <> u.id
   AND su.[ID] = @SupervisorID
  INNER JOIN QCheck_GroupMembership GM3  -- Groups for the supervised Users
   ON GM3.UserID = u.ID
  INNER JOIN QCheck_Groups G3
   ON g3.ID = GM3.GroupID
   AND g3.singlemembergroup = 0
 WHERE
  U.IsDeleted = 0  
 ORDER by G3.Name


END
GO

CREATE OR ALTER PROCEDURE [dbo].[QCheck_GetSupervisedUsersInGroup](
	@GroupID INT,
	@SupervisorID INT
)
 AS

BEGIN

	SET NOCOUNT ON

SELECT DISTINCT u.FullName, u.ID, g.Name, us.SupervisorUserID
FROM QCheck_Users u 
INNER JOIN QCheck_GroupMembership gm ON u.ID = gm.UserID
INNER JOIN QCheck_Groups g ON g.ID = gm.GroupID
INNER JOIN QStatus_UserSupervisors us ON  us.UserID = gm.UserID
where 
us.SupervisorUserID = @SupervisorID
and
g.ID = @GroupID
	

	SET NOCOUNT OFF

END

















































































GO

CREATE OR ALTER PROCEDURE [dbo].[QStatus_GetSupervisedUsers]
--DECLARE
	@UserID int,-- = 50
	@IncludeIP bit = 0
AS
BEGIN
	
	SET NOCOUNT ON
	SELECT u.ID, u.FullName "Name", s.InterestedParty
	FROM QCheck_Users U
		INNER JOIN QCheck_GroupMembership gm
			on gm.userid = u.id
		INNER JOIN QCheck_Groups g1
			on g1.id = gm.groupid
		INNER JOIN QStatus_GroupReport GR
			ON GR.groupid = g1.id
			and gr.defaultreport = 1
		INNER JOIN QStatus_Report R
			ON r.id = gr.reportid
			AND r.IsDeleted = 0
			AND (r.name = u.fullname or r.name not in (select fullname from qcheck_users where isdeleted = 0))
		INNER JOIN QStatus_Supervisors S
			ON R.[ID] = S.ReportID			
			AND s.AsOf < GetUtcDate()
			--for priority lists, we only want employees the user directly supervises
			AND s.DirectSupervisor = 1 
			AND (s.InterestedParty = 0 OR @IncludeIP = 1)
		INNER JOIN QCheck_Groups G
			ON S.SupervisorGroupID = G.[ID]	
		 INNER JOIN QCheck_GroupMembership gm2
			on gm2.groupid = g.id
		 INNER JOIN QCheck_Users su
			on su.[ID] = gm2.userid
			and su.[ID] <> u.id
			AND su.[ID] = @UserID
	WHERE
		U.IsDeleted = 0		
	ORDER BY Name
	SET NOCOUNT OFF
END
GO

CREATE OR ALTER PROCEDURE [dbo].[Util_GetLastRunTimeForStoredProcedure](
@StoredProcName VARCHAR(MAX) 
)
AS

BEGIN

SELECT 
   p.ProcedureName AS procedure_name,
    p.ExecutionTime as LastRunOn
FROM 
    ProcedureExecutionLog AS p

WHERE 
    p.ProcedureName = @StoredProcName
ORDER BY 
     p.ExecutionTime DESC;

END

GO

CREATE OR ALTER PROCEDURE [dbo].[QCheck_GetGroupMembers]
	@ID int
 AS

BEGIN

	SET NOCOUNT ON

		SELECT gm.ID, u.FullName, gm.GroupID, u.ID as UserID
		FROM QCheck_GroupMembership gm
		INNER JOIN QCheck_Users u
		ON gm.UserID = u.ID
		WHERE gm.GroupID = @ID
		
	SET NOCOUNT OFF

End
GO