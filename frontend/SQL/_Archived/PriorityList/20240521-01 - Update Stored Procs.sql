
/****** Object:  StoredProcedure [dbo].[InsertEmailLog]    Script Date: 5/13/2024 3:54:40 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[InsertEmailLog] 
	@fromId int,
	@toAddress varchar(255),
	@subject varchar(Max)
AS
BEGIN
	declare @toId int=-1;

	select @toId=ID from QCheck_Users where email=@toAddress and empID>0

	INSERT INTO [dbo].[QCheck_Log_Emails]
           ([FromId]
           ,[ToId]
           ,[Subject]
           ,[Sent])
     VALUES
           (@fromId
           ,@toId
           ,@subject
           ,Getdate())

	if @fromId in (select userid from qcheck_bonususers) and @subject = 'PriorityList' and @fromId <> @toId
	begin
		insert into PriorityList_BonusSend
		select pl.userid, pli.activechecklistid, getdate() 
		from Priorities_Lists pl
			JOIN Priorities_ListItems pli
				ON pli.ListID = pl.ID
			left join PriorityList_BonusSend plb
				on plb.userid = pl.userid 
				and plb.activechecklistid = pli.activechecklistid 
				and plb.dt > cast(getdate() as date)
		where pl.userid = @fromId
		and @subject like '%' + pl.Name + '%'
		and plb.dt is null
	end
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_AddDefault]    Script Date: 5/13/2024 3:55:12 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER proc [dbo].[PriorityList_AddDefault]
	@UserID int,
	@ListID int = null,
	@Days int = 7
AS
BEGIN
	
	DECLARE @MaxPriority int

	if @ListID IS NULL
		select @ListId = ID 
		from Priorities_Lists 
		where UserID = @UserID 
			AND IsDefaultList = 1

	SELECT @MaxPriority = max(priority)
	FROM Priorities_ListItems li
	WHERE li.ListID = @ListID

	IF isnull(@MaxPriority, 0) <= 0 SET @MaxPriority = 0
	
	DECLARE @newtasks table
	(
		priority int identity(1,1),
		activechecklistid int,
		duetime datetime
	)		

	insert into @newtasks (activechecklistid, duetime)
	select distinct activechecklistid, ac.duetime from qcheck_activechecklists ac
	inner join qcheck_activeassignments aa
	on ac.id = aa.activechecklistid
	inner join qcheck_assignments a
	on a.id = aa.assignmentsid
	and a.isdeleted = 0
	inner join qcheck_groups g
	on g.id = a.groupid
	inner join qcheck_groupmembership gm
	on gm.groupid = g.id
	where gm.userid = @UserID
	and ac.duetime < convert(datetime, convert(varchar, getdate() + @Days, 101))
	and ac.duetime >= convert(datetime, convert(varchar, getdate() - 7, 101))
	and ac.completeddate is null
	and activechecklistid not in (select li.activechecklistid 
		from Priorities_ListItems li
		where li.ID = @ListID)
	order by ac.duetime asc	

	insert into Priorities_ListItems (ListID, ActiveChecklistID, Priority)
	select @listID, activechecklistid, priority + isnull(@MaxPriority, 0)
	from @newtasks
	
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_AddTask]    Script Date: 5/13/2024 3:56:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER    proc [dbo].[PriorityList_AddTask]
	@UserID int,
	@ListID int = null,
	@ActiveChecklistID int,
	@Priority int = 0
AS
BEGIN
	
	DECLARE @ID int
	DECLARE @MaxPriority int
	SET @MaxPriority = 0

	if @ListID IS NULL
		select @ListId = ID 
		from Priorities_Lists 
		where UserID = @UserID 
			AND IsDefaultList = 1

	SELECT @MaxPriority = max(priority)
	FROM Priorities_ListItems li
	WHERE li.ListID = @ListID	
	
	INSERT INTO Priorities_ListItems (ListID, ActiveChecklistID, Priority)
	SELECT @ListID, @ActiveChecklistID, isnull(@MaxPriority, 0) + 1 
	WHERE NOT EXISTS (select 'Y' 
		from Priorities_ListItems li
		where li.ID = @ListID 
			AND li.activechecklistid = @ActiveChecklistID)
	
	SELECT @ID = SCOPE_IDENTITY()
	
	IF @Priority > 0 AND @Priority < (@MaxPriority + 1)
	BEGIN
		EXEC [PriorityList_MoveTask] @ID, @Priority
	END
	
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_Clear]    Script Date: 5/13/2024 3:57:16 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER      proc [dbo].[PriorityList_Clear]
	@UserID int = NULL,
	@ListID int = NULL
AS
BEGIN
	
	DELETE Priorities_ListItems	 
	FROM Priorities_ListItems li
	JOIN Priorities_Lists l ON l.ID = li.ListID
	WHERE l.ID = @ListID 
		OR (@ListID IS NULL 
			AND l.UserID = @UserID 
			AND l.IsDefaultList = 1)
	
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_Refresh]    Script Date: 5/13/2024 4:13:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER    proc [dbo].[PriorityList_Refresh]
	@UserID int,
	@ListID int = NULL
AS
BEGIN

	if @ListID IS NULL
		select @ListId = ID 
		from Priorities_Lists 
		where UserID = @UserID 
			AND IsDefaultList = 1

	--update recurring itmes
	update Priorities_ListItems
	set activechecklistid = newlist.newacid
	from Priorities_ListItems p
	inner join (
		select a.ListID ID, min(ac2.id) as newacid 
		from Priorities_ListItems a			
		inner join qcheck_activechecklists ac
			on a.activechecklistid = ac.id
		inner join qcheck_checklistinstances ci
			on ci.id = ac.instanceid
		inner join qcheck_activechecklists ac2
			on ac2.instanceid = ci.id
			and ac2.completeddate is null
		where a.priority > 0
			and ac.completeddate is not null
			and ac2.duetime < getdate() + 8
			and a.ListID = @ListID			
		group by a.ListID
	) newlist 
		on newlist.id = p.id
		and p.ListID = @ListID

	--move off the completed tasks
	UPDATE Priorities_ListItems
	SET Priority = -1
	FROM Priorities_ListItems p
	INNER JOIN QCheck_ActiveChecklists ac
	ON p.activechecklistid = ac.id
	AND completeddate is not null
	AND p.ListID = @ListID

	--return any reopened tasks
	UPDATE Priorities_ListItems
	SET Priority = 99
	FROM Priorities_ListItems p
	INNER JOIN QCheck_ActiveChecklists ac
	ON p.activechecklistid = ac.id
	AND completeddate is  null
	AND p.Priority = -1
	AND p.ListID = @ListID

	--remove deleted tasks
	DELETE FROM Priorities_ListItems
	WHERE ListID = @ListID
	AND ActiveChecklistID not in (
		SELECT ac.ID 
		FROM QCheck_ActiveChecklists ac
		INNER JOIN QCheck_ChecklistInstances ci
		ON ac.InstanceID = ci.ID
		AND ci.IsDeleted = 0
		INNER JOIN QCheck_Checklists c
		ON ci.ChecklistID = c.ID
		AND c.IsDeleted = 0		
	)

	--remove dupes
	DELETE Priorities_ListItems
	FROM Priorities_ListItems p
	INNER JOIN (select * from Priorities_ListItems where ListID = @ListID) p2
	ON p.activechecklistid = p2.activechecklistid
	AND p.ListID = p2.ListID
	AND p.ID > p2.ID

	--reprioritize
	DECLARE @Prioritytemp Table
	(
		ActiveChecklistID int,
		P int identity(1,1)
	)
	
	INSERT INTO @Prioritytemp (ActiveChecklistID)
	SELECT ActiveChecklistID From Priorities_ListItems
	WHERE ListID = @ListID
	AND Priority >= 0
	ORDER BY Priority asc

	UPDATE Priorities_ListItems
	SET Priority = P
	FROM Priorities_ListItems p
	INNER JOIN @Prioritytemp t
	ON p.ActiveChecklistID = t.Activechecklistid
	AND p.ListID = @ListID
	
END
GO

------------------------------------
-- BOOKMARK - End of 5/13/24
------------------------------------

/****** Object:  StoredProcedure [dbo].[PriorityList_Get]    Script Date: 5/13/2024 3:57:58 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   PROC [dbo].[PriorityList_Get]
	@UserID int = NULL,
	@ListID int = NULL
AS
BEGIN
	SET NOCOUNT ON

	if @ListID IS NULL
		select @ListId = ID 
		from Priorities_Lists 
		where UserID = @UserID 
			AND IsDefaultList = 1

	if @UserID IS NULL
		select @UserID = UserID
		from Priorities_Lists 
			where ID = @ListID 

	EXEC PriorityList_Refresh @UserID, @ListID

	SELECT DISTINCT p.ID, 
		convert(varchar(10), p.Priority) as Priority
		, p.ActiveChecklistID, c.[Name]
		, convert(varchar, ac.duetime, 101) as due
		, isnull('['+convert(varchar, qc.commentdt, 101) + '] [' + qc.initials + '] ' + replace(qc.comments, '''', ''), 'No Comments') as comments
		, @UserID as UserId
		, @ListID as ListId
		, CASE WHEN convert(integer, p.Priority) > 0 THEN 0 ELSE 1 END AS PriorityRank --active ones first
		, convert(integer, p.Priority) AS PriorityNbr
		, ac.duetime
		, c.ID AS ChecklistId
		, qc.ID AS CommentId
	INTO #result
	FROM 
		Priorities_ListItems p
		INNER JOIN QCheck_ActiveChecklists ac
			ON ac.id = p.ActiveChecklistID
		INNER JOIN QCheck_ChecklistInstances ci
			ON ci.id = ac.instanceid
		INNER JOIN QCheck_Checklists c
			ON c.id = ci.checklistid
		LEFT OUTER JOIN
			(select foreignkeyid, max(ID) as ID from qstatus_comments
			where specialtask = 0
			group by foreignkeyid
			) com ON com.foreignkeyid = ac.ID
		LEFT OUTER JOIN qstatus_comments qc
			ON qc.ID = com.ID
	WHERE p.ListID = @ListID
	and (ac.completeddate is null
	or ac.completeddate > convert(datetime, convert(varchar, getdate() - 1, 1)))

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ActiveChecklistID FROM #result WHERE ActiveChecklistID IS NOT NULL
	EXEC dbo.Audit_Set @userId, @recordIds, 'ActiveChecklist', 2

	DELETE @recordIds 
	INSERT INTO @recordIds
		SELECT DISTINCT ChecklistId FROM #result WHERE ChecklistId IS NOT NULL
	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	DELETE @recordIds 
	INSERT INTO @recordIds
		SELECT DISTINCT CommentId FROM #result WHERE CommentId IS NOT NULL
	EXEC dbo.Audit_Set @userId, @recordIds, 'Comment', 2

	ALTER TABLE #result DROP COLUMN ChecklistId
	ALTER TABLE #result DROP COLUMN CommentId

	SELECT *
	FROM #result
	ORDER BY PriorityRank, PriorityNbr, DueTime
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_GetAvailableTasks]    Script Date: 5/13/2024 3:58:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [dbo].[PriorityList_GetAvailableTasks]
	@UserID int,
	@ListID int = null,
	@SourceUserID int
AS

	if @ListID IS NULL
		select @ListId = ID 
		from Priorities_Lists 
		where UserID = @UserID 
			AND IsDefaultList = 1

	select distinct activechecklistid, c.name, convert(varchar, ac.duetime, 101) as duetime, cast(ac.duetime as datetime)
	from qcheck_activechecklists ac
	inner join qcheck_checklistinstances ci
	on ci.id = ac.instanceid
	inner join qcheck_checklists c
	on c.id = ci.checklistid
	inner join qcheck_activeassignments aa
	on ac.id = aa.activechecklistid
	inner join qcheck_assignments a
	on a.id = aa.assignmentsid
	inner join qcheck_groups g
	on g.id = a.groupid
	inner join qcheck_groupmembership gm
	on gm.groupid = g.id
	left outer join Priorities_List_CrossReference cr
		on cr.crossreferenceid = gm.userid
	where (gm.userid = @UserID or cr.userID = @UserID)
		and (ac.completeddate is null or ac.completedby is null)
		and c.isdeleted =0
		and ci.isdeleted = 0
		and a.isdeleted = 0
		and activechecklistid not in (
				select activechecklistid 
				from Priorities_ListItems 
				where ListID = @ListID
			)
		and activechecklistid not in
			(Select activechecklistID from Priorities_ListExclude
				Where UserID = @SourceUserID
				AND ForUserID = @UserID)
	order by cast(ac.duetime as datetime) asc

GO

/****** Object:  StoredProcedure [dbo].[PriorityList_MoveDown]    Script Date: 5/13/2024 3:59:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER  proc [dbo].[PriorityList_MoveDown]
	@ID int
AS
BEGIN
	
	--check current priority
	DECLARE @Priority int, @MaxPriority int, @ListID int
	
	SELECT @Priority = Priority, @ListID = ListID
	FROM Priorities_ListItems
	WHERE [ID] = @ID

	SELECT @MaxPriority = Max(Priority)
	FROM Priorities_ListItems WHERE ListID = @ListID
	
	IF @Priority < isnull(@MaxPriority, 0)
	BEGIN
		SET @Priority = @Priority + 1
		EXEC PriorityList_MoveTask @ID, @Priority
	END

END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_MoveTask]    Script Date: 5/13/2024 3:59:57 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER    proc [dbo].[PriorityList_MoveTask]
	@ID int,
	@Priority int
AS
BEGIN
	
	--check current priority
	DECLARE @CurrentPriority int
	DECLARE @ListID int
	SET @ListID = 0

	SELECT @CurrentPriority = Priority, 
		@ListID = ListID
	FROM Priorities_ListItems
	WHERE ID = @ID
	
	IF @Priority > @CurrentPriority and @CurrentPriority > 0 and @Priority > 0
		UPDATE Priorities_ListItems
		SET Priority = Priority - 1
		WHERE ListID = @ListID
			AND Priority > @CurrentPriority
			AND Priority <= @Priority

	IF @Priority < @CurrentPriority and @CurrentPriority > 0 and @Priority > 0
		UPDATE Priorities_ListItems
		SET Priority = Priority + 1
		WHERE ListID = @ListID
			AND Priority >= @Priority
			AND Priority < @CurrentPriority


	UPDATE Priorities_ListItems
	SET Priority = @Priority
	WHERE ID = @ID

	SELECT @ListID
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_MoveUp]    Script Date: 5/13/2024 4:00:57 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   proc [dbo].[PriorityList_MoveUp]
	@ID int
AS
BEGIN
	
	--check current priority
	DECLARE @Priority int
	
	SELECT @Priority = Priority
	FROM Priorities_ListItems
	WHERE [ID] = @ID
	
	IF @Priority > 1
	BEGIN
		SET @Priority = @Priority - 1
		EXEC PriorityList_MoveTask @ID, @Priority
	END

END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_QDController]    Script Date: 5/13/2024 4:01:23 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER proc [dbo].[PriorityList_QDController]
AS
BEGIN

	-- Get app configuration
	DECLARE @AppURL VARCHAR(50), @ImagesURL VARCHAR(50), @ExternalURL VARCHAR(50), @BaseDomain VARCHAR(50), @FromAddress VARCHAR(50), @AppName VARCHAR(50), @GradingAddress VARCHAR(50), @AutomationAddress VARCHAR(50), @DeveloperAddress VARCHAR(50), @ITAddress VARCHAR(50), @MailServer VARCHAR(50), @GPRUserID INT
	SELECT @AppURL = AppURL, @ImagesURL = ImagesURL, @ExternalURL = ExternalURL, @BaseDomain = BaseDomain, @FromAddress = FromAddress, @Appname = AppName, @GradingAddress = GradingAddress, @AutomationAddress = AutomationAddress, @DeveloperAddress = DeveloperAddress, @ITAddress = ITAddress, @MailServer = MailServer, @GPRUserID = GPRUserID FROM QCheck_AppSettings WHERE ID = 1
	
	DECLARE @ACs table
	(
		activechecklistid int
	)

	insert into @ACs
	SELECT  i.ActiveChecklistID
	from Priorities_ListItems i
		inner join Priorities_Lists l 
			ON l.ID = i.ListID
		inner join QCheck_ActiveChecklists ac
			on ac.ID = i.ActiveChecklistID 
		inner join QCheck_ChecklistInstances ci
			on ci.ID = ac.InstanceID
		inner join QCheck_Checklists c
			on c.ID = ci.ChecklistID
		cross apply (
			SELECT g.id FROM qcheck_groupmembership gm
				inner join qcheck_groups g
					on g.id = gm.groupid
					and g.singlemembergroup = 1
					and gm.userid = @GPRUserID
		) grp
		left outer join qcheck_checklistmanagers cm
			on cm.checklistid = c.id
			and cm.isdeleted = 0
			and cm.managergroupid <> grp.id
		left outer join qcheck_checklistmanagers cmGPR
			on cmGPR.checklistid = c.id
			and cmGPR.isdeleted = 0
			and cmGPR.managergroupid = grp.id
	
	WHERE
		--TODO: This should almost certainly be a specific priority list (not Tim's personal list plus rules)
		l.UserID in (
			select ID from QCheck_Users 
			where ShortName = 'tgermany'
		)
		and l.IsDefaultList = 1
		--- per Jillian/GPR on 2/9/22 don't do this for WOHelp tasks unless they are from GPR
		and (
				(
					ISNULL(c.name, '') not like '%wohelp%'
					and ISNULL(c.name, '') not like '%carmelhelp%'
				)
				or 
				ISNULL(c.name, '') like '%graynor%'
			)
		and (cm.id is not null or cmGPR.id is null)
		
		declare @activechecklistid int
		while exists (select 1 from @ACs)
		begin
			select top 1 @activechecklistid = activechecklistid from @ACs
			exec QCheck_SetSoloController @ActiveChecklistID, @GPRUserID
			delete from @ACs where activechecklistid = @activechecklistid
		end

END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_Record_LateFee]    Script Date: 5/13/2024 4:11:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[PriorityList_Record_LateFee]
@ReportStartDate Datetime=NULL,
@ReportEndDate Datetime=null
AS
BEGIN

	DECLARE @HasCharges bit
	SELECT @HasCharges = HasCharges from QCheck_AppSettings

	IF ISNULL(@HasCharges,0) = 0 RETURN;
	
	SET DATEFIRST 1;

	Declare @OrigReportEndDate datetime;

	--select @ReportEndDate=IsNUll(@ReportEndDate,'01/01/9999')
	--select @ReportEndDate=IsNUll(@ReportEndDate,GetDate()-1)
	select @ReportEndDate=IsNUll(@ReportEndDate,GetDate())
	select @OrigReportEndDate=@ReportEndDate
	--get the last 30 days since the late charge steps up on a rolling 30 day period
	select @ReportStartDate=Isnull(@ReportStartDate,@ReportEndDate-30)

	Declare @EndDate Datetime=Convert(Date,GetDate()-1)

	Create table #Schedule
	(
		Seq int identity(1,1),
		ScheduleId int,
		SupervisorID int,
		ListID int,
		UserID int,
		DaysOfWeek varchar(10),
		ReportDay varchar(10),
		TimesOfday varchar(10),
		CreatedDate datetime,
		ModifiedDate datetime,
		IsActive bit
	)

	Create table #ScheduleReport
	(
		Seq int identity(1,1),
		ScheduleId int,
		Supervisor varchar(100),
		Employee varchar(100),
		ListID int,
		UserID int,
		ReportDate varchar(50),
		ScheduledDate datetime, 
		SentDate datetime,
		ReportsPerWeek int ,
		IsLate varchar(5),
		IsExcludedReason varchar(100)
	)

	Create table #LateRecords
	(
		Seq int identity(1,1),
		ScheduleId int,
		Supervisor varchar(100),
		Employee varchar(100),
		UserID int,
		ReportDate varchar(50),
		ScheduledDate datetime, 
		SentDate datetime,
		ReportsPerWeek int ,
		IsLate varchar(5),
		IsExcludedReason varchar(100)
	)

	Create table #Employees
	(
		Seq int identity(1,1),
		UserID int
	)

	Insert into #Employees(UserID)
	select distinct l.UserID   
	From Priorities_Schedule sch
	LEFT JOIN Priorities_Lists l 
		ON l.ID = sch.ListID
	JOIN Qcheck_Users u 
		on u.ID = sch.UserID 
	WHERE sch.IsActive=1 
		and u.IsDeleted=0
		and u.id not in (
			select userid from qcheck_bonususers 
			where isnull(startdt, '1/1/2021') < getdate()
			and isnull(enddt, '1/1/2500') > getdate()
		)

	declare @Counter int=1
	declare @ScheduleCount int=1;

	Insert into #Schedule(ScheduleId,SupervisorID,ListID,UserID,
		DaysOfWeek,ReportDay,TimesOfday,CreatedDate,ModifiedDate,IsActive)--load the schedules
	select s.[ScheduleID]
		,s.[SupervisorID]
		,s.[ListID]
		,s.[UserID]
		,s.[DaysOfWeek]
		,s.[ReportDay]
		,s.[TimesOfDay]
		,s.[CreatedDate]
		,s.ModifiedDate
		,s.IsActive
	From Priorities_Schedule s  
	LEFT JOIN Priorities_Lists l 
		ON l.ID = s.ListID
	where IsActive=1 
		--and SupervisorID=@supervisor
		--and EmployeeID =@employeeId
	
	--get inactive schedules -added on 10/25/2017	
	Insert into #Schedule(ScheduleId,SupervisorID,ListID,UserID,
		DaysOfWeek,ReportDay,TimesOfday,CreatedDate,ModifiedDate,IsActive)--load the schedules
	select s.[ScheduleID]
		,s.[SupervisorID]
		,s.[ListID]
		,s.[UserID]
		,s.[DaysOfWeek]
		,s.[ReportDay]
		,s.[TimesOfDay]
		,s.[CreatedDate]
		,s.ModifiedDate
		,s.IsActive
	From Priorities_Schedule s
	where IsActive=0  
			and Convert(date,CreatedDate)<>Convert(date,ModifiedDate)

	select @ScheduleCount=count(*) from #Schedule
	--select * from #Schedule
	while(@Counter<=@ScheduleCount)
	Begin

		Declare @UserID int=0;
		Declare @ListID int=0;
		Declare @SupervisorID int=0;
		Declare @DayOfWeek int =0
		Declare @ReportDay int =0
		Declare @StartDate Datetime
		Declare @ScheduledTime time;
		Declare @ReportsPerWeek int=0;
		--set @UserID=715;
		Declare @IsActive bit=1;
		--set @UserID=715;
		select @IsActive=IsActive 
		from #Schedule 
		where Seq=@Counter
	
		set @ReportEndDate=@OrigReportEndDate

		if(@IsActive=0)
		Begin
			--select @ReportEndDate=Convert(Date,ModifiedDate) from #Schedule where Seq=@Counter and @ReportEndDate>=Convert(Date,ModifiedDate)
			--select @ReportEndDate=dateadd(day, datediff(day,'19000101',ModifiedDate), CAST(TimesOfDay AS DATETIME)) from #Schedule where Seq=@Counter and @ReportEndDate>=Convert(Date,ModifiedDate)
			--select 'Inactive '
			--select @ReportEndDate
			select @ReportEndDate=ModifiedDate 
			from #Schedule 
			where Seq=@Counter 
				and @ReportEndDate >= Convert(Date,ModifiedDate)
		End

		select 
			@SupervisorID=SupervisorID, 
			@UserID=UserID,
			@ListID=ListID,
			@DayOfWeek=DaysofWeek,
			@ReportDay=ReportDay,
			@StartDate=Convert(Date,CreatedDate),
			@ScheduledTime=TimesOfday 
		from #Schedule where Seq=@Counter

		select @ReportsPerWeek=count(*) 
		from Priorities_Schedule 
		where UserID = @UserID
			AND ISNULL(ListID,0)=ISNULL(@ListID,0)
			and IsActive=1

		Create table #ScheduleDates
		(
			seq int identity(1,1),
			ScheduledDate datetime
		)

		Create table #ReportDates
		(
			seq int identity(1,1),
			ReportDate datetime
		)

		if(@StartDate<=Convert(Date,@ReportStartDate))
		Begin
			set @StartDate=@ReportStartDate
		End


		--select @StartDate,@EndDate,@ScheduledTime
		Insert Into #ScheduleDates(ScheduledDate)--this stores the list of all scheduled dates per schedule
		SELECT dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST(@ScheduledTime AS DATETIME))
		from [dbo].[Util_fn_List_WeekDays_DateRange](@StartDate,@ReportEndDate,@DayOfWeek) dt
		where 
		dt.WeekDayDate>=@ReportStartDate 
			and dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST(@ScheduledTime AS DATETIME))<=@ReportEndDate

		Insert Into #ReportDates(ReportDate)--this stores the list of all scheduled dates per schedule
		SELECT dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST('00:00' AS DATETIME))
		from [dbo].[Util_fn_List_WeekDays_DateRange](@StartDate,@ReportEndDate,@ReportDay) dt
		where
		dt.WeekDayDate>=@ReportStartDate 
			and dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST(@ScheduledTime AS DATETIME))<=@ReportEndDate
		--select * from #ScheduleDates

		Declare @ScheduledDatesCounter int=1;

		Declare @ScheduledDatesCount int=0;

		select @ScheduledDatesCount=count(*) from #ScheduleDates

		while (@ScheduledDatesCounter<=@ScheduledDatesCount)
		Begin

		Declare @ScheduledDate Datetime;
		Declare @ReportDate Datetime;
		select @ScheduledDate=ScheduledDate from #ScheduleDates where Seq=@ScheduledDatesCounter 
		select @ReportDate=ReportDate from #ReportDates where Seq=@ScheduledDatesCounter 

		if(@ReportsPerWeek=1)--this is for weekly reports
		Begin
			Insert into #ScheduleReport(
				Supervisor,
				Employee,
				UserID,
				ListID,
				ReportDate,
				ScheduledDate,
				SentDate,
				IsLate,
				ReportsPerWeek,
				IsExcludedReason
			) values (
				 (select FullName from QCheck_Users where ID=@SupervisorID)
				,(select FullName from QCheck_Users where ID=@UserID)
				,@UserID
				,@ListID
				,(select ReportDate from #ReportDates where Seq=@ScheduledDatesCounter)
				,(select ScheduledDate from #ScheduleDates where Seq=@ScheduledDatesCounter)
				,(select Min(Sent) from QCheck_Log_Emails --changed from Min to Max on 04/05/2018 by venkat
					where 
					Sent>@ReportDate-2 and
					(Sent<= @ScheduledDate 
						or Convert(Date,Sent)=Convert(Date,@ScheduledDate))
					and FromId=@UserID 
					and ToId <> FromId
				)
				,null
				,@ReportsPerWeek
				,case 
					when Exists(
						select 1 
						from Priorities_ScheduleExclude 
						where UserID=@UserID 
							and IsActive=1 
							and ExcludedDate<=@ScheduledDate 
							and Convert(Date,ExcludedDate) = Convert(Date,@ScheduledDate)
						)
					Then 'Excused'
					when Exists(
						select 1 
						from MyVacation.dbo.Vacation 
						where EmployeeID=(
								select EmpID 
								from Qcheck_Users 
								where ID=@UserID
							) 
							and Convert(Date,VacationDay) = Convert(Date,@ScheduledDate)
						)
					Then 'Vacation'
				End
			)
		End
		else
		Begin
			Insert into #ScheduleReport(
				Supervisor,
				Employee,
				UserID,
				ListID,
				ReportDate,
				ScheduledDate,
				SentDate,
				IsLate,
				ReportsPerWeek,
				IsExcludedReason
			) values (
				(select FullName from QCheck_Users where ID=@SupervisorID)
				,(select FullName from QCheck_Users where ID=@UserID)
				,@UserID
				,@ListID
				,(select ReportDate from #ReportDates where Seq=@ScheduledDatesCounter)
				,(select ScheduledDate from #ScheduleDates where Seq=@ScheduledDatesCounter)
				,(select Min(Sent) from QCheck_Log_Emails --changed from Min to Max on 04/05/2018 by venkat
					where Sent > @ReportDate 
					and (Sent <= @ScheduledDate 
						or Convert(Date, Sent) = Convert(Date, @ScheduledDate))
					and FromId = @UserID 
					and ToId <> FromId
				)
				,null
				,@ReportsPerWeek
				,case 
					when Exists(
						select 1 
						from Priorities_ScheduleExclude 
						where ListID=@ListID 
							and IsActive=1 
							and ExcludedDate <= @ScheduledDate 
							and Convert(Date, ExcludedDate) = Convert(Date, @ScheduledDate))
					Then 'Excused'
					when Exists(
						select 1 
						from MyVacation.dbo.Vacation 
						where EmployeeID=(
								select EmpID 
								from Qcheck_Users 
								where ID=@UserID
							) 
							and Convert(Date,VacationDay) = Convert(Date,@ScheduledDate))
					Then 'Vacation'
				End
			)
		End

		set @ScheduledDatesCounter=@ScheduledDatesCounter+1
		End

		Drop table #ScheduleDates 
		Drop table #ReportDates 

		set @Counter=@Counter+1
	End

	--select * from #ScheduleReport
	-- order by Employee Desc

	--process late records here
	Declare @employeeCounter int=1
	Declare @employeeCount int=1
	select @employeeCount=count(*) from #Employees

	while(@employeeCounter<=@employeeCount)
	Begin
		Declare @empIDLate int;
		select @empIDLate=UserID from #Employees where seq=@employeeCounter

		Insert into #LateRecords(
			Supervisor,
			Employee,
			UserID,
			ReportDate,
			ScheduledDate,
			SentDate,
			IsLate,
			ReportsPerWeek,
			IsExcludedReason
		)
		select Supervisor,
			Employee,
			UserID,
			ReportDate,
			ScheduledDate,
			SentDate,
			IsLate,
			ReportsPerWeek,
			IsExcludedReason 
		from #ScheduleReport 
		where (
				(SentDate is null and IsExcludedReason is null) 
				or (SentDate>ScheduledDate and IsExcludedReason is null)
			) 
			and UserID=@empIDLate

		--select * from #LateRecords where EmpID=@empIDLate order by ScheduledDate desc

		--select @OrigReportEndDate as OrigReportEndDate
 
		if(Exists(select 1 from #LateRecords 
			where ScheduledDate <= @OrigReportEndDate 
				and Convert(Date,ScheduledDate) = Convert(Date,@OrigReportEndDate) 
				and UserID = @empIDLate ))--means we have a late record on the report enddate
		Begin
			--select 'found late'
			Declare @totalLateCount int=0
			select @totalLateCount=count(*) from #LateRecords where UserID=@empIDLate
 
 
			if(NOT Exists(select 1 from PriorityList_LateFee_Log 
				where Convert(Date,Latedate)=COnvert(date,@OrigReportEndDate) 
				and EmpID=@empIDLate and IsActive=1) )--check if there is already a late charge recorded for the enddate
			Begin
				INSERT INTO [dbo].[PriorityList_LateFee_Log]
						([EmpID]
						,[LateDate]
						,[LateCharge]
						,[IsActive])
					VALUES
						(@empIDLate
						,Convert(date,@OrigReportEndDate)
				--       ,case when @totalLateCount>3
						--   then (select StepupCharge from QCheck_LateFee where EndDate is null)
							--else (select LateCharge from QCheck_LateFee where EndDate is null)
							--End
							,(select Isnull(LateCharge,100) 
								from QCheck_LateFee 
								where LateCount=@totalLateCount 
									and EndDate is null)
							,1)

				INSERT INTO  [AcmeDotNet].[dbo].[empFines]
						([SourceId]
						,[EmpId]
						,[Charge]
						,[ChargeSource]
						,[ChargeDesc]
						,[ChargeDate]
						,[CreatedDate]
						)
				select 
					Id
					,(select empid from qcheck_users where id=PL.EmpID)
					,LateCharge
					,'QProcess-MissedPriority'
					,'QProcess-MissedPriority-'+COnvert(varchar(10), LateDate, 101)
					,LateDate
					,GetDate()
				From PriorityList_LateFee_Log PL
				where PL.Id=@@IDENTITY
				
			End
		End

		set @employeeCounter=@employeeCounter+1;
	End

END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_Record_LateFee_Employee]    Script Date: 5/13/2024 4:12:54 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[PriorityList_Record_LateFee_Employee]
@ReportStartDate Datetime=NULL,
@ReportEndDate Datetime=null,
@employeeId int=0

AS
BEGIN
	DECLARE @HasCharges bit
	SELECT @HasCharges = HasCharges from QCheck_AppSettings

	IF ISNULL(@HasCharges,0) = 0 RETURN;

	SET DATEFIRST 1;
	Declare @OrigReportEndDate datetime;

	--select @ReportEndDate=IsNUll(@ReportEndDate,'01/01/9999')
	--select @ReportEndDate=IsNUll(@ReportEndDate,GetDate()-1)
	select @ReportEndDate=IsNUll(@ReportEndDate,GetDate())
	select @OrigReportEndDate=@ReportEndDate
	--get the last 30 days since the late charge steps up on a rolling 30 day period
	select @ReportStartDate=Isnull(@ReportStartDate,@ReportEndDate-30)

	Declare @EndDate Datetime=Convert(Date,GetDate()-1)

	Create table #Schedule
	(
		Seq int identity(1,1),
		ScheduleId int,
		SupervisorID int,
		ListID int,
		UserID int,
		DaysOfWeek varchar(10),
		ReportDay varchar(10),
		TimesOfday varchar(10),
		CreatedDate datetime,
		ModifiedDate datetime,
		IsActive bit
	)

	Create table #ScheduleReport
	(
		Seq int identity(1,1),
		ScheduleId int,
		Supervisor varchar(100),
		Employee varchar(100),
		ListID int,
		UserID int,
		ReportDate varchar(50),
		ScheduledDate datetime, 
		SentDate datetime,
		ReportsPerWeek int ,
		IsLate varchar(5),
		IsExcludedReason varchar(100)
	)

	Create table #LateRecords
	(
		Seq int identity(1,1),
		ScheduleId int,
		Supervisor varchar(100),
		Employee varchar(100),
		UserID int,
		ReportDate varchar(50),
		ScheduledDate datetime, 
		SentDate datetime,
		ReportsPerWeek int ,
		IsLate varchar(5),
		IsExcludedReason varchar(100)
	)

	Create table #Employees
	(
		Seq int identity(1,1),
		UserID int
	)

	Insert into #Employees(UserID)
	select distinct sch.UserID   
	From Priorities_Schedule sch
	LEFT JOIN Priorities_Lists l 
		ON l.ID = sch.ListID
	JOIN Qcheck_Users u 
		on u.ID = sch.UserID 
	WHERE sch.IsActive=1 
		and u.IsDeleted=0
		and u.id not in (
			select userid from qcheck_bonususers 
			where isnull(startdt, '1/1/2021') < getdate()
			and isnull(enddt, '1/1/2500') > getdate()
		)


	declare @Counter int=1
	declare @ScheduleCount int=1;

	Insert into #Schedule(ScheduleId,SupervisorID,ListID,UserID,
		DaysOfWeek,ReportDay,TimesOfday,CreatedDate,ModifiedDate,IsActive)--load the schedules
	select s.[ScheduleID]
		,s.[SupervisorID]
		,s.[ListID]
		,s.[UserID]
		,s.[DaysOfWeek]
		,s.[ReportDay]
		,s.[TimesOfDay]
		,s.[CreatedDate]
		,s.ModifiedDate
		,s.IsActive
	From Priorities_Schedule s  
	LEFT JOIN Priorities_Lists l 
		ON l.ID = s.ListID
	where IsActive=1 
		--and SupervisorID=@supervisor
		and s.UserID = @employeeId
	
	--get inactive schedules -added on 10/25/2017	
	Insert into #Schedule(ScheduleId,SupervisorID,ListID,UserID,
		DaysOfWeek,ReportDay,TimesOfday,CreatedDate,ModifiedDate,IsActive)--load the schedules
	select s.[ScheduleID]
		,s.[SupervisorID]
		,s.[ListID]
		,s.[UserID]
		,s.[DaysOfWeek]
		,s.[ReportDay]
		,s.[TimesOfDay]
		,s.[CreatedDate]
		,s.ModifiedDate
		,s.IsActive
	From Priorities_Schedule s
	where IsActive=0 
		AND s.UserID = @employeeId
		and Convert(date,CreatedDate)<>Convert(date,ModifiedDate)

	select @ScheduleCount=count(*) from #Schedule
	--select * from #Schedule
	while(@Counter<=@ScheduleCount)
	Begin

		Declare @UserID int=0;
		Declare @ListID int=0;
		Declare @SupervisorID int=0;
		Declare @DayOfWeek int =0
		Declare @ReportDay int =0
		Declare @StartDate Datetime
		Declare @ScheduledTime time;
		Declare @ReportsPerWeek int=0;
		--set @UserID=715;
		Declare @IsActive bit=1;
		--set @UserID=715;
		select @IsActive=IsActive 
		from #Schedule 
		where Seq=@Counter
	
		set @ReportEndDate=@OrigReportEndDate

		if(@IsActive=0)
		Begin
			--select @ReportEndDate=Convert(Date,ModifiedDate) from #Schedule where Seq=@Counter and @ReportEndDate>=Convert(Date,ModifiedDate)
			--select @ReportEndDate=dateadd(day, datediff(day,'19000101',ModifiedDate), CAST(TimesOfDay AS DATETIME)) from #Schedule where Seq=@Counter and @ReportEndDate>=Convert(Date,ModifiedDate)
			--select 'Inactive '
			--select @ReportEndDate
			select @ReportEndDate=ModifiedDate 
			from #Schedule 
			where Seq=@Counter 
				and @ReportEndDate >= Convert(Date,ModifiedDate)
		End

		select 
			@SupervisorID=SupervisorID, 
			@UserID=UserID,
			@ListID=ListID,
			@DayOfWeek=DaysofWeek,
			@ReportDay=ReportDay,
			@StartDate=Convert(Date,CreatedDate),
			@ScheduledTime=TimesOfday 
		from #Schedule where Seq=@Counter

		select @ReportsPerWeek=count(*) 
		from Priorities_Schedule 
		where UserID = @UserID
			AND ISNULL(ListID,0)=ISNULL(@ListID,0)
			and IsActive=1

		Create table #ScheduleDates
		(
			seq int identity(1,1),
			ScheduledDate datetime
		)

		Create table #ReportDates
		(
			seq int identity(1,1),
			ReportDate datetime
		)

		if(@StartDate<=Convert(Date,@ReportStartDate))
		Begin
			set @StartDate=@ReportStartDate
		End


		--select @StartDate,@EndDate,@ScheduledTime
		Insert Into #ScheduleDates(ScheduledDate)--this stores the list of all scheduled dates per schedule
		SELECT dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST(@ScheduledTime AS DATETIME))
		from [dbo].[Util_fn_List_WeekDays_DateRange](@StartDate,@ReportEndDate,@DayOfWeek) dt
		where 
		dt.WeekDayDate>=@ReportStartDate 
			and dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST(@ScheduledTime AS DATETIME))<=@ReportEndDate

		Insert Into #ReportDates(ReportDate)--this stores the list of all scheduled dates per schedule
		SELECT dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST('00:00' AS DATETIME))
		from [dbo].[Util_fn_List_WeekDays_DateRange](@StartDate,@ReportEndDate,@ReportDay) dt
		where
		dt.WeekDayDate>=@ReportStartDate 
			and dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST(@ScheduledTime AS DATETIME))<=@ReportEndDate
		--select * from #ScheduleDates

		Declare @ScheduledDatesCounter int=1;

		Declare @ScheduledDatesCount int=0;

		select @ScheduledDatesCount=count(*) from #ScheduleDates

		while (@ScheduledDatesCounter<=@ScheduledDatesCount)
		Begin

		Declare @ScheduledDate Datetime;
		Declare @ReportDate Datetime;
		select @ScheduledDate=ScheduledDate from #ScheduleDates where Seq=@ScheduledDatesCounter 
		select @ReportDate=ReportDate from #ReportDates where Seq=@ScheduledDatesCounter 

		if(@ReportsPerWeek=1)--this is for weekly reports
		Begin
			Insert into #ScheduleReport(
				Supervisor,
				Employee,
				UserID,
				ListID,
				ReportDate,
				ScheduledDate,
				SentDate,
				IsLate,
				ReportsPerWeek,
				IsExcludedReason
			) values (
				 (select FullName from QCheck_Users where ID=@SupervisorID)
				,(select FullName from QCheck_Users where ID=@UserID)
				,@UserID
				,@ListID
				,(select ReportDate from #ReportDates where Seq=@ScheduledDatesCounter)
				,(select ScheduledDate from #ScheduleDates where Seq=@ScheduledDatesCounter)
				,(select Min(Sent) from QCheck_Log_Emails --changed from Min to Max on 04/05/2018 by venkat
					where 
					Sent>@ReportDate-2 and
					(Sent<= @ScheduledDate 
						or Convert(Date,Sent)=Convert(Date,@ScheduledDate))
					and FromId=@UserID 
					and ToId <> FromId
				)
				,null
				,@ReportsPerWeek
				,case 
					when Exists(
						select 1 
						from Priorities_ScheduleExclude 
						where ListID=@ListID 
							and IsActive=1 
							and ExcludedDate<=@ScheduledDate 
							and Convert(Date,ExcludedDate) = Convert(Date,@ScheduledDate)
						)
					Then 'Excused'
					when Exists(
						select 1 
						from MyVacation.dbo.Vacation 
						where EmployeeID=(
								select EmpID 
								from Qcheck_Users 
								where ID=@UserID
							) 
							and Convert(Date,VacationDay) = Convert(Date,@ScheduledDate)
						)
					Then 'Vacation'
				End
			)
		End
		else
		Begin
			Insert into #ScheduleReport(
				Supervisor,
				Employee,
				UserID,
				ListID,
				ReportDate,
				ScheduledDate,
				SentDate,
				IsLate,
				ReportsPerWeek,
				IsExcludedReason
			) values (
				(select FullName from QCheck_Users where ID=@SupervisorID)
				,(select FullName from QCheck_Users where ID=@UserID)
				,@UserID
				,@ListID
				,(select ReportDate from #ReportDates where Seq=@ScheduledDatesCounter)
				,(select ScheduledDate from #ScheduleDates where Seq=@ScheduledDatesCounter)
				,(select Min(Sent) from QCheck_Log_Emails --changed from Min to Max on 04/05/2018 by venkat
					where Sent > @ReportDate 
					and (Sent <= @ScheduledDate 
						or Convert(Date, Sent) = Convert(Date, @ScheduledDate))
					and FromId = @UserID 
					and ToId <> FromId
				)
				,null
				,@ReportsPerWeek
				,case 
					when Exists(
						select 1 
						from Priorities_ScheduleExclude 
						where ListID=@ListID 
							and IsActive=1 
							and ExcludedDate <= @ScheduledDate 
							and Convert(Date, ExcludedDate) = Convert(Date, @ScheduledDate))
					Then 'Excused'
					when Exists(
						select 1 
						from MyVacation.dbo.Vacation 
						where EmployeeID=(
								select EmpID 
								from Qcheck_Users 
								where ID=@UserID
							) 
							and Convert(Date,VacationDay) = Convert(Date,@ScheduledDate))
					Then 'Vacation'
				End
			)
		End

		set @ScheduledDatesCounter=@ScheduledDatesCounter+1
		End

		Drop table #ScheduleDates 
		Drop table #ReportDates 

		set @Counter=@Counter+1
	End

	--select * from #ScheduleReport
	-- order by Employee Desc

	--process late records here
	Declare @employeeCounter int=1
	Declare @employeeCount int=1
	select @employeeCount=count(*) from #Employees

	while(@employeeCounter<=@employeeCount)
	Begin
		Declare @empIDLate int;
		select @empIDLate=UserID from #Employees where seq=@employeeCounter

		Insert into #LateRecords(
			Supervisor,
			Employee,
			UserID,
			ReportDate,
			ScheduledDate,
			SentDate,
			IsLate,
			ReportsPerWeek,
			IsExcludedReason
		)
		select Supervisor,
			Employee,
			UserID,
			ReportDate,
			ScheduledDate,
			SentDate,
			IsLate,
			ReportsPerWeek,
			IsExcludedReason 
		from #ScheduleReport 
		where (
				(SentDate is null and IsExcludedReason is null) 
				or (SentDate>ScheduledDate and IsExcludedReason is null)
			) 
			and UserID=@empIDLate

		--select * from #LateRecords where EmpID=@empIDLate order by ScheduledDate desc

		--select @OrigReportEndDate as OrigReportEndDate
 
		if(Exists(select 1 from #LateRecords 
			where ScheduledDate <= @OrigReportEndDate 
				and Convert(Date,ScheduledDate) = Convert(Date,@OrigReportEndDate) 
				and UserID = @empIDLate ))--means we have a late record on the report enddate
		Begin
			--select 'found late'
			Declare @totalLateCount int=0
			select @totalLateCount=count(*) from #LateRecords where UserID=@empIDLate
 
 
			if(NOT Exists(select 1 from PriorityList_LateFee_Log 
				where Convert(Date,Latedate)=COnvert(date,@OrigReportEndDate) 
				and EmpID=@empIDLate and IsActive=1) )--check if there is already a late charge recorded for the enddate
			Begin
				INSERT INTO [dbo].[PriorityList_LateFee_Log]
						([EmpID]
						,[LateDate]
						,[LateCharge]
						,[IsActive])
					VALUES
						(@empIDLate
						,Convert(date,@OrigReportEndDate)
				--       ,case when @totalLateCount>3
						--   then (select StepupCharge from QCheck_LateFee where EndDate is null)
							--else (select LateCharge from QCheck_LateFee where EndDate is null)
							--End
							,(select Isnull(LateCharge,100) 
								from QCheck_LateFee 
								where LateCount=@totalLateCount 
									and EndDate is null)
							,1)

				INSERT INTO  [AcmeDotNet].[dbo].[empFines]
						([SourceId]
						,[EmpId]
						,[Charge]
						,[ChargeSource]
						,[ChargeDesc]
						,[ChargeDate]
						,[CreatedDate]
						)
				select 
					Id
					,(select empid from qcheck_users where id=PL.EmpID)
					,LateCharge
					,'QProcess-MissedPriority'
					,'QProcess-MissedPriority-'+COnvert(varchar(10), LateDate, 101)
					,LateDate
					,GetDate()
				From PriorityList_LateFee_Log PL
				where PL.Id=@@IDENTITY
				
			End
		End

		set @employeeCounter=@employeeCounter+1;
	End
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_AddTasks]    Script Date: 5/13/2024 4:14:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER proc [dbo].[PriorityList_AddTasks]
	@UserID int = NULL,
	@ListID int = NULL,
	@ActiveChecklistIDs varchar(1000)
AS
BEGIN
	DECLARE @ID_list TABLE
	(
		ID int IDENTITY(1,1),
		ActiveChecklistID int
	)
	DECLARE @rowcount int, @i int, @ActiveChecklistID int


	INSERT INTO @ID_list
	SELECT n FROM dbo.Util_fn_List_To_Table(@ActiveChecklistIDs,';')
	where n is not null

	SELECT @rowcount = @@ROWCOUNT
	SELECT @i = 1
	
	WHILE @i <= @rowcount
	BEGIN
		SELECT @ActiveChecklistID = ActiveChecklistID
		FROM @ID_list
		WHERE [ID] = @i
		
		EXEC PriorityList_AddTask @UserID, @ListID, @ActiveChecklistID

		SET @i = @i + 1
	END

	
END
GO


/****** Object:  StoredProcedure [dbo].[PriorityList_RemoveTask]    Script Date: 5/13/2024 4:14:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER proc [dbo].[PriorityList_RemoveTask]
	@ID int
AS
BEGIN
	
	--check priority
	DECLARE @Priority int
	DECLARE @ListID int
	SET @ListID = 0

	SELECT @Priority = Priority, 
		@ListID = ListID
	FROM Priorities_ListItems
	WHERE [ID] = @ID

	--remove from list
	DELETE FROM Priorities_ListItems
	WHERE [ID] = @ID

	-- move up lower priorities
	IF (IsNull(@Priority, 0)) > 0 and (IsNull(@ListID, 0)) > 0 
		UPDATE Priorities_ListItems
		SET Priority = Priority -1
		WHERE ListID = @ListID
		AND Priority > @Priority

	SELECT @ListID as "userID"

END
GO

CREATE OR ALTER PROCEDURE [dbo].[PriorityListSet_GetPersonalByUser] (
	@UserID INT
) AS

BEGIN

	SELECT 
		ls.ID,
		ls.Name,
		ls.UserID,
		ls.PersonalSet,
		ls.UpdatedDate
	FROM Priorities_ListSets ls
	JOIN Priorities_ListSetLists lsl
		ON lsl.SetID = ls.ID
	JOIN Priorities_Lists l
		ON l.ID = lsl.ListID
	WHERE
		ls.UserID = @UserID
		AND ls.PersonalSet = 1
		AND l.IsDefaultList = 1
		
END

/****** Object:  StoredProcedure [dbo].[PriorityListSet_GetComments]    Script Date: 5/13/2024 4:14:53 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   PROC [dbo].[PriorityListSet_GetComments]
	@SetID int,
	@UserID int,
	@StartTime datetime,
	@AllUsers bit = 0
AS
BEGIN
	SET NOCOUNT ON

	select 
		lsl.listid, 
		li.activechecklistid, 
		--'[' + c.initials + '] '+ case when c.comments like '%href%' then c.comments else replace(c.comments, '''', '''''') end as comments,--commented by venkat 11/02/2017
		'[' + c.initials + '] '+ c.comments as comments,
		li.id,
		c.id as CommentId,
		c.DisplayOrder
	into #result
	from Priorities_ListSetLists lsl
	inner join Priorities_ListItems li
		on li.listid = lsl.listid
	inner join qstatus_comments c
		on c.foreignkeyid = li.activechecklistid
		and c.specialtask = 0
		and (c.userid = @userid OR @AllUsers = 1)
		and c.commentdt > @starttime
	where lsl.setid = @setid
		and len(c.comments) > 0
	order by lsl.listid, c.displayorder

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT CommentId FROM #result WHERE CommentId IS NOT NULL

	EXEC dbo.Audit_Set @userId, @recordIds, 'Comment', 2

	SELECT listid, activechecklistid, comments, id
	FROM #result
	ORDER BY listID, DisplayOrder
END
GO

/****** Object:  StoredProcedure [dbo].[QCheck_CompleteChecklist]    Script Date: 5/13/2024 4:15:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- This stored procedure will mark a checklist as Complete
-- ID is the checklist ID
-- if all items are not marked as complete, then it will not be completed
-- and a 0 will be returned

CREATE OR ALTER   PROCEDURE [dbo].[QCheck_CompleteChecklist] (
	@ID INT,
	@CompletedBy int,
	@IsNA bit = 0,
	@NAReason varchar(max) = '',
	@isComplete bit output,
	@UpcomingDueTimeID INT = -1 OUTPUT,
	@NewActiveChecklistID INT = -1 OUTPUT
)
AS
BEGIN

	SET NOCOUNT ON

	DECLARE @numChecks int,
			@numDone int,
			@numLeft int,
			@AssignedToChecklist INT,
			@ControlsChecklist INT, 
			@AlreadyComplete BIT = 0,
			@recordIds AS RecordId
			
	SET @AssignedToChecklist = 0
	SET @ControlsChecklist = 0
	
	SELECT 
		@AssignedToChecklist = gm.UserID,
		@AlreadyComplete = case when ac.CompletedDate is null then 0 else 1 end
	FROM
		QCheck_ActiveChecklists ac
		INNER JOIN QCheck_Assignments a
			ON a.InstanceID = ac.InstanceID
		INNER JOIN QCheck_Groups g
			ON g.ID = a.GroupId
		INNER JOIN QCheck_GroupMembership gm
			ON gm.GroupID = g.ID
			AND gm.UserID = @CompletedBy
			AND ac.ID = @ID
	
	SELECT
		@ControlsChecklist = gm.UserID
	FROM
		QCheck_ActiveChecklists ac
		INNER JOIN QCheck_ChecklistInstances ci
			ON ac.InstanceID = ci.ID
		INNER JOIN QCheck_Checklists c
			ON ci.ChecklistID = c.ID
		INNER JOIN QCheck_ChecklistManagers cm
			ON c.ID = cm.ChecklistID
			AND cm.IsDeleted = 0
		INNER JOIN QCheck_Groups g
			ON cm.ManagerGroupID = g.ID
		INNER JOIN QCheck_GroupMembership gm
			ON g.ID = gm.GroupID
			AND gm.UserID = @CompletedBy
			AND ac.ID = @ID
	
	SET @isComplete = 0

	--find the number of checks that must be completed
	SELECT 
		@numChecks = count(d.[ID]) 
	FROM
		QCheck_ActiveChecklists a
		INNER JOIN QCheck_ChecklistInstances b
			ON a.InstanceID = b.[ID]
		INNER JOIN QCheck_Checklists c
			ON b.ChecklistID = c.[ID]
		INNER JOIN QCheck_Items d
			ON d.ChecklistID = c.ID
	WHERE 
		a.[ID] = @ID
		AND d.ItemTypeID = 1
		AND d.IsDeleted = 0

	--find the number of checks that are done
	SELECT 
		@numDone = count(d.[ID]) 
	FROM
		QCheck_ActiveChecklists a
		INNER JOIN QCheck_ChecklistInstances b
			ON a.InstanceID = b.[ID]
		INNER JOIN QCheck_Checklists c
			ON b.ChecklistID = c.[ID]
		INNER JOIN QCheck_Items d
			ON d.ChecklistID = c.ID
		INNER JOIN QCheck_ActiveItems e
			ON d.[ID] = e.ChecklistItemID AND e.ActiveChecklistID = a.[ID]
	WHERE 
		a.[ID] = @ID
		AND d.ItemTypeID = 1
		AND d.IsDeleted = 0
		AND e.CompletedDate is not null

	--num left = total - done
	SET @numLeft = @numChecks - @numDone

	-- Mark individual checklist items complete. Assignees can mark complete if there is one step
	-- to the checklist or if marking N/A. 
	-- Per GPR 2/5/2014, controllers that aren't assignees can mark multiple step checklists complete
	IF (@numChecks = 1 and @numLeft = 1) OR (@ControlsChecklist = 1 AND @AssignedToChecklist = 0) OR (@IsNA = 1)
	BEGIN
		DELETE @recordIds
		INSERT INTO @recordIds
			SELECT DISTINCT ID 
			FROM QCheck_ActiveItems
			WHERE ActiveChecklistID = @ID AND CompletedDate IS NULL

		EXEC dbo.Audit_Set @CompletedBy, @recordIds, 'ActiveItem', 3

		UPDATE 
			QCheck_ActiveItems
		SET 
			Completedby = @CompletedBy, 
			CompletedDate = getdate(),
			[Text] = CASE WHEN @IsNA = 1 THEN 'N/A' ELSE '' END
		WHERE 
			ActiveChecklistID = @ID
			AND CompletedDate IS NULL
		
		SELECT 
			ActiveChecklistID = @ID, 
			ChecklistItemID = i.ID, 
			[Text] = CASE WHEN @IsNA = 1 THEN 'N/A' ELSE '' END, 
			CompletedDate = GETDATE(), 
			CompletedBy = @CompletedBy
		INTO #tmp
		FROM 
			QCheck_ActiveChecklists ac
			INNER JOIN QCheck_ChecklistInstances ci
				ON ac.InstanceID = ci.ID
			INNER JOIN QCheck_Checklists c
				ON ci.ChecklistID = c.ID
			INNER JOIN QCheck_Items i
				ON i.ChecklistId = c.ID
				AND i.ItemTypeID = 1
				AND i.IsDeleted = 0
			LEFT OUTER JOIN QCheck_ActiveItems ai
				ON ai.ActiveChecklistID = @ID
				AND ai.ChecklistItemID = i.ID
		WHERE 
			ac.ID = @ID
			AND ai.ID IS NULL

		INSERT INTO QCheck_ActiveItems
			SELECT * FROM #tmp

		IF @@ROWCOUNT > 0 BEGIN
			DELETE @recordIds
			INSERT INTO @recordIds
				SELECT DISTINCT ID
				FROM dbo.QCheck_ActiveItems a
				INNER JOIN #tmp b 
					ON b.ActiveChecklistID = a.ActiveChecklistID 
					AND b.ChecklistItemID = a.ChecklistItemID

			EXEC dbo.Audit_Set @CompletedBy, @recordIds, 'ActiveItem', 1
		END
	END
	-- if it is zero, then update the active checklist
	If @numLeft <= 0 OR (@numChecks = 1 and @numLeft = 1) OR (@ControlsChecklist = 1 AND @AssignedToChecklist = 0) OR (@IsNA = 1)
	BEGIN
		DELETE @recordIds
		INSERT INTO @recordIds
			SELECT DISTINCT ID 
			FROM QCheck_ActiveChecklists
			WHERE [ID] = @ID AND CompletedDate IS NULL

		EXEC dbo.Audit_Set @CompletedBy, @recordIds, 'ActiveChecklist', 3

		UPDATE QCheck_ActiveChecklists
		SET 
			CompletedBy = @CompletedBy,
			CompletedDate = getDate(),
			IsNA = @IsNA,
			NAReason = @NAReason
		WHERE 
			[ID] = @ID
			AND CompletedDate is null

		SET @isComplete = 1

		if @AlreadyComplete = 0
		BEGIN
			EXEC QCheck_ActiveInstanceAlert @ID, 'Complete'

			IF @ID in (select ac.id 
					from qcheck_activechecklists ac
						inner join qcheck_checklistinstances ci
							on ci.id = ac.InstanceID
						inner join QCheck_CompletionTriggers ct
							on ct.checklistid = ci.ChecklistID
					where ct.isActive = 1)
			BEGIN
				--process any triggered sp that need to be run
				DECLARE @sp varchar(255)
				DECLARE CompletionTriggers_CURS CURSOR FOR 
					select sp 
					from qcheck_activechecklists ac
					inner join qcheck_checklistinstances ci
						on ci.id = ac.InstanceID
					inner join QCheck_CompletionTriggers ct
						on ct.checklistid = ci.ChecklistID
					where ac.ID = @ID and ct.isActive = 1
				
				Open CompletionTriggers_CURS				
				FETCH NEXT FROM CompletionTriggers_CURS INTO @sp
				
				WHILE @@FETCH_STATUS = 0 
				BEGIN

					if @sp = 'util_CT_GuardCameraCheck'
					begin
						exec [util_CT_GuardCameraCheck] @ID
					end

					FETCH NEXT FROM CompletionTriggers_CURS INTO @sp
				END

				CLOSE CompletionTriggers_CURS
				DEALLOCATE CompletionTriggers_CURS
				
			END
		END	

		EXEC QCheck_ActivateFutureInstancesAfterCompleted @ID, @UpcomingDueTimeID OUTPUT, @NewActiveChecklistID OUTPUT
				
		--If this task is in any priority lists, and it's recurring, we need to add the new copy to the lists in its place
		if Exists(select 1 from Priorities_ListItems 
			where ActiveChecklistID = @ID)			
			AND @NewActiveChecklistID IS NOT NULL
		Begin

			DECLARE @ListID int = 0, @Priority int = 0, @PriUserID int = 0 

			DECLARE PriorityLists_CURS CURSOR FOR 
				SELECT ListID, UserID, Priority 
				FROM Priorities_ListItems li
				JOIN Priorities_Lists l 
					ON l.ID = li.ListID
				WHERE li.ActiveChecklistID = @ID
				
			OPEN PriorityLists_CURS				
			FETCH NEXT FROM PriorityLists_CURS INTO @ListID, @PriUserID, @Priority
				
			WHILE @@FETCH_STATUS = 0 
			BEGIN

				exec PriorityList_AddTask 
					@UserID=@PriUserID, 
					@ListID = @ListID, 
					@ActiveChecklistID=@NewActiveChecklistID, 
					@Priority=@Priority			
					
				FETCH NEXT FROM PriorityLists_CURS INTO @ListID, @PriUserID, @Priority
			END

			CLOSE PriorityLists_CURS
			DEALLOCATE PriorityLists_CURS
		END	
	END

	SET NOCOUNT OFF
END
GO

---------------------------------------------------------------------------------
-- BOOKMARK - EOD 2024-05-16
---------------------------------------------------------------------------------

/****** Object:  StoredProcedure [dbo].[QCheck_GetCalendarChecklists]    Script Date: 5/13/2024 4:17:14 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   PROC [dbo].[QCheck_GetCalendarChecklists]
	@UserID int,
	@startDate datetime,
	@endDate datetime,
	@ID varchar(8000),
	@ShowStatusCalendar bit = 0,
	@ShowAlertEmails bit = 1
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @IDs table(
		ID int
	)

	INSERT INTO @IDs SELECT CAST(Data as int) FROM dbo.Util_Split(@ID,',')
	
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
	
	IF @UserID <> 5000 BEGIN

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
				QCheck_Approval_ChangeRequests CR
				INNER JOIN QCheck_Approval_ActiveChecklists AAC
					ON AAC.ChangeRequestID = CR.[ID]
				-- 3/25/2013 dalvarado - Created this view and joined it here to eliminate duplicate entries
				-- on the calendar view when you have multiple outstanding change requests for a task.
				INNER JOIN QCheck_MostRecentDeadlineRequests MRDR
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
			QCheck_Assignments a
			INNER JOIN QCheck_Groups g
				on g.ID = a.GroupID
			INNER JOIN QCheck_Groupmembership gm
				on gm.GroupID = g.ID
				and gm.UserID = @UserID
		WHERE a.IsDeleted = 0

		INSERT INTO @tblAssignee
		SELECT a.InstanceID
		FROM 
			QCheck_Assignments a
			INNER JOIN QCheck_Groups g
				on g.ID = a.GroupID
			INNER JOIN QCheck_Groupmembership gm
				on gm.GroupID = g.ID
				and gm.UserID IN (SELECT ID FROM @IDs)
			--Failsafe against query string hacking; @UserID and @ID must have a supervisor/report relationship
			INNER JOIN (
				SELECT u.ID
				FROM QCheck_Users U
					INNER JOIN QStatus_Report R
						ON U.FullName = R.[Name]	
						AND r.IsDeleted = 0
					INNER JOIN QStatus_Supervisors S
						ON R.[ID] = S.ReportID			
						AND s.AsOf < GETDATE()
						AND (s.DirectSupervisor = 1 
							OR s.InterestedParty = 1)
					INNER JOIN QCheck_Groups G
						ON S.SupervisorGroupID = G.[ID]			
					INNER JOIN QCheck_Users SU
						ON G.Owner = SU.[ID]
						AND su.IsDeleted = 0
						AND SU.[ID] = @UserID
					WHERE
						U.IsDeleted = 0
						AND U.ID IN (SELECT ID FROM @IDs)
			) X ON x.ID = gm.UserID
		WHERE a.IsDeleted = 0		
	
		INSERT INTO @tblManaged
		SELECT ci.ID
		FROM 
			QCheck_ChecklistInstances ci
			INNER JOIN QCheck_Checklists c
				on c.ID = ci.ChecklistID
				and c.IsDeleted = 0
				and ci.IsDeleted = 0
			INNER JOIN QCheck_ChecklistManagers cm
				on cm.ChecklistID = c.ID
				and cm.IsDeleted = 0
			INNER JOIN QCheck_Groups g
				on g.ID = cm.ManagerGroupID
			INNER JOIN QCheck_Groupmembership gm
				on gm.GroupID = g.ID
				and gm.UserID = @UserID

		INSERT INTO @tblStatusControlled
		SELECT r.ID 
		FROM 
			QStatus_Report r
			INNER JOIN QStatus_GroupReport gr
				ON gr.ReportID = r.ID
			INNER JOIN QCheck_Groups g
				ON g.ID = gr.GroupID
			INNER JOIN QCheck_GroupMembership gm
				ON gm.GroupID = g.ID
				AND gm.UserID = @UserID			
		WHERE
			r.IsDeleted = 0
			AND (
				r.ID IN (SELECT ID FROM @IDs)
				or -1 IN (SELECT ID FROM @IDs)		
			)
	
		INSERT INTO @tblStatusSupervised
		SELECT r.ID 
		FROM 
			QStatus_Report r
			INNER JOIN QStatus_Supervisors sup
				ON sup.ReportID = r.ID
				AND sup.DirectSupervisor = 1
			INNER JOIN QCheck_Groups g
				ON g.ID = sup.SupervisorGroupID
			INNER JOIN QCheck_GroupMembership gm
				ON gm.GroupID = g.ID
				AND gm.UserID = @UserID	
		WHERE
			r.IsDeleted = 0
			AND EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, r.ID))			

		--KVS 2017-10-30 - Adding alerts as a viewable calendar item
		INSERT INTO @tblScheduledAlerts
		SELECT a.InstanceID,
			al.ID
		FROM 
			QCheck_Assignments a
			INNER JOIN QCheck_Alerts al
				ON al.InstanceID = a.InstanceID
				AND al.IsDeleted = 0				
			INNER JOIN QCheck_Groups g
				ON (al.AlerteeGroupID IS NULL AND g.ID = a.GroupID)
				OR al.AlerteeGroupID = g.ID
			INNER JOIN QCheck_Groupmembership gm
				on gm.GroupID = g.ID
				and gm.UserID = @UserID
		WHERE a.IsDeleted = 0 
		
		-- ****************************************
		-- All or assigned to me
		IF EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0)) 
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
				CASE WHEN a.ID IS NULL OR @ShowAlertEmails = 0 THEN 0 ELSE 1 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac 
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID
				LEFT OUTER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				LEFT OUTER JOIN QCheck_Alerts a
					ON al.AlertID = a.ID
					AND a.AlertType = 'Overdue'
				LEFT OUTER JOIN QCheck_ActiveAlerts aa
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms 
					on ms.checklistid = c.ID	
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
					ORDER BY ListID
				) p				
			WHERE
				EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0)) 

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
				CASE WHEN a.ID IS NULL OR @ShowAlertEmails = 0 THEN 0 ELSE 1 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				null as OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_UpcomingDueTimes ac 
					on ac.InstanceID = ci.ID 
					AND ac.DueTime BETWEEN @startDate and @endDate
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID
				LEFT OUTER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				LEFT OUTER JOIN QCheck_Alerts a
					ON al.AlertID = a.ID
					AND a.AlertType = 'Overdue'
				LEFT OUTER JOIN QCheck_ActiveAlerts aa
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
					ORDER BY ListID
				) p			
			WHERE
				EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0)) 
	
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
				CASE WHEN a.ID IS NULL OR @ShowAlertEmails = 0 THEN 0 ELSE 1 END as IsEmailScheduled,
				case when ms.checklistid is null then 0 else 1 end as MultiStep,
				case when p.activechecklistid is null then 0 else 1 end as IsPriority,
				ac.OrigDueTime
			FROM 
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklistArchive ac 
					on ac.InstanceID = ci.ID 
					AND CAST(GETDATE() as date) > @startDate
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID
				LEFT OUTER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				LEFT OUTER JOIN QCheck_Alerts a
					ON al.AlertID = a.ID
					AND a.AlertType = 'Overdue'
				LEFT OUTER JOIN QCheck_ActiveAlerts aa
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
					ORDER BY ListID
				) p		
			WHERE
				EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0)) 
		END

		-- ****************************************
		-- Managed by me
		IF EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, -2)) 
			OR (EXISTS (SELECT 'Y' FROM @IDs WHERE ID > 0) and @ShowStatusCalendar = 0)
		BEGIN

			-- IF @ID = -2, *only* show tasks controlled by the user (ignore supervisor or group membership)
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
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac 
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN QCheck_ActiveAssignments aa
					on aa.ActiveChecklistID = ac.ID
				INNER JOIN QCheck_Assignments a
					on a.ID = aa.AssignmentsID
					and a.isdeleted = 0
				INNER JOIN QCheck_Groups g
					on g.ID = a.GroupID
				INNER JOIN QCheck_Groupmembership gm
					on gm.GroupID = g.ID
					and (
						EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, -2)) 
						OR (
							EXISTS (SELECT 'Y' FROM @IDs WHERE ID > 0) 
							and @ShowStatusCalendar = 0
							and gm.UserID IN (select ID FROM @IDs)
						)
					)
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblAssignee ta2
					on ta2.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm 
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
					ORDER BY ListID
				) p
			WHERE
				(tm.ID is not null OR (-2 NOT IN (SELECT ID FROM @IDs) AND ta2.ID IS NOT NULL))
	
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
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_UpcomingDueTimes ac 
					on ac.InstanceID = ci.ID 
					AND ac.DueTime BETWEEN @startDate and @endDate
				INNER JOIN QCheck_Assignments a
					on a.InstanceID = ci.ID
					and a.isdeleted = 0
				INNER JOIN QCheck_Groups g
					on g.ID = a.GroupID
				INNER JOIN QCheck_Groupmembership gm
					on gm.GroupID = g.ID
					and (
						EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, -2)) 
						OR (
							EXISTS (SELECT 'Y' FROM @IDs WHERE ID > 0) 
							and @ShowStatusCalendar = 0
							and gm.UserID IN (select ID FROM @IDs)
						)
					)
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblAssignee ta2
					on ta2.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm 
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
					ORDER BY ListID
				) p
			WHERE
				(tm.ID is not null OR (-2 NOT IN (SELECT ID FROM @IDs) AND ta2.ID IS NOT NULL))	

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
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklistArchive ac 
					on ac.InstanceID = ci.ID 
					AND CAST(GETDATE() as date) > @startDate			
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN QCheck_Assignments a
					on a.InstanceID = ci.ID
					and a.isdeleted = 0
				INNER JOIN QCheck_Groups g
					on g.ID = a.GroupID
				INNER JOIN QCheck_Groupmembership gm
					on gm.GroupID = g.ID
					and (
						EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, -2)) 
						OR (
							EXISTS (SELECT 'Y' FROM @IDs WHERE ID > 0) 
							and @ShowStatusCalendar = 0
							and gm.UserID IN (select ID FROM @IDs)
						)
					)
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblAssigned ta2
					on ta2.ID = ci.ID
				left outer JOIN @tblManaged tm 
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
					ORDER BY ListID
				) p
			WHERE
				(tm.ID is not null OR (-2 NOT IN (SELECT ID FROM @IDs) AND ta2.ID IS NOT NULL))	

		END
	
		-- ****************************************
		-- Status
		IF EXISTS (SELECT 'Y' FROM @IDs WHERE ID = -1) OR @ShowStatusCalendar = 1
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
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac 
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN QStatus_ActiveChecklistTaskType actt
					on actt.ActiveChecklistID = ac.ID
				INNER JOIN QStatus_TaskTypes tt
					ON tt.ID = actt.TaskType
				LEFT OUTER JOIN @tblStatusControlled tc
					ON tc.ID = tt.ReportID
				LEFT OUTER JOIN @tblStatusSupervised tss
					ON tss.ID = tt.ReportID
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
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
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_UpcomingDueTimes ac 
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.DueTime BETWEEN @startDate and @endDate
					)
				INNER JOIN QStatus_InstanceTaskType itt
					on itt.InstanceID = ci.ID
				INNER JOIN QStatus_TaskTypes tt
					ON tt.ID = itt.TaskType
				LEFT OUTER JOIN @tblStatusControlled tc
					ON tc.ID = tt.ReportID
				LEFT OUTER JOIN @tblStatusSupervised tss
					ON tss.ID = tt.ReportID
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
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
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklistArchive ac 
					on ac.InstanceID = ci.ID
					AND CAST(GETDATE() as date) > @startDate		
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN QStatus_InstanceTaskType itt
					on itt.InstanceID = ci.ID
				INNER JOIN QStatus_TaskTypes tt
					ON tt.ID = itt.TaskType
				LEFT OUTER JOIN @tblStatusControlled tc
					ON tc.ID = tt.ReportID
				LEFT OUTER JOIN @tblStatusSupervised tss
					ON tss.ID = tt.ReportID
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
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
		IF EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0)) BEGIN

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
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac 
					on ac.InstanceID = ci.ID 
					AND ac.DueTime < @startDate
					AND ac.DueTime < GETDATE() -- Only overdue stuff, not active tasks in future weeks
					AND ac.CompletedDate IS NULL
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID
				LEFT OUTER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				LEFT OUTER JOIN QCheck_Alerts a
					ON al.AlertID = a.ID
					AND a.AlertType = 'Overdue'
				LEFT OUTER JOIN QCheck_ActiveAlerts aa
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
					ORDER BY ListID
				) p		
			WHERE
				EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0))
				
		END
		
		-- Managed by me
		IF EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, -2)) 
			OR (EXISTS (SELECT 'Y' FROM @IDs WHERE ID > 0) and @ShowStatusCalendar = 0)		
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
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac 
					on ac.InstanceID = ci.ID 
					AND ac.DueTime < @startDate
					AND ac.DueTime < GETDATE() -- Only overdue stuff, not active tasks in future weeks
					AND ac.CompletedDate IS NULL
				INNER JOIN QCheck_ActiveAssignments aa
					on aa.ActiveChecklistID = ac.ID
				INNER JOIN QCheck_Assignments a
					on a.ID = aa.AssignmentsID
					and a.isdeleted = 0
				INNER JOIN QCheck_Groups g
					on g.ID = a.GroupID
				INNER JOIN QCheck_Groupmembership gm
					on gm.GroupID = g.ID
					and (
						EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, -2)) 
						OR (
							EXISTS (SELECT 'Y' FROM @IDs WHERE ID > 0) 
							and @ShowStatusCalendar = 0
							and gm.UserID IN (select ID FROM @IDs)
						)
					)
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblAssignee ta2
					on ta2.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
					ORDER BY ListID
				) p	
			WHERE
				(tm.ID is not null OR (-2 NOT IN (SELECT ID FROM @IDs) AND ta2.ID IS NOT NULL))		
		END
		
		-- Status
		IF EXISTS (SELECT 'Y' FROM @IDs WHERE ID = -1) OR @ShowStatusCalendar = 1
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
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac 
					on ac.InstanceID = ci.ID 
					AND ac.DueTime < @startDate
					AND ac.DueTime < GETDATE() -- Only overdue stuff, not active tasks in future weeks
					AND ac.CompletedDate IS NULL
				INNER JOIN QStatus_ActiveChecklistTaskType actt
					on actt.ActiveChecklistID = ac.ID
				INNER JOIN QStatus_TaskTypes tt
					ON tt.ID = actt.TaskType
				LEFT OUTER JOIN @tblStatusControlled tc
					ON tc.ID = tt.ReportID
				LEFT OUTER JOIN @tblStatusSupervised tss
					ON tss.ID = tt.ReportID
				LEFT OUTER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
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
		IF EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0)) and @ShowAlertEmails = 1 BEGIN
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
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklists ac 
					on ac.InstanceID = ci.ID 
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID 
				LEFT OUTER JOIN @tblPendingChanges pc
					ON ac.[ID] = pc.ActiveChecklistID
				INNER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				INNER JOIN QCheck_Alerts a
					ON al.AlertID = a.ID
					AND a.AlertType IN ('Reminder', 'Custom', 'Hours')
				INNER JOIN QCheck_ActiveAlerts aa
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID
				LEFT OUTER JOIN QCheck_AlertExceptions ae
					ON ae.ActiveAlertID = aa.ID
					AND ae.UserID = @UserID
					AND ae.IsActive = 1		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
					ORDER BY ListID
				) p					
			WHERE
				EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0))

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
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_UpcomingDueTimes ac 
					on ac.InstanceID = ci.ID 
					AND ac.DueTime BETWEEN @startDate and @endDate
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID
				INNER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				INNER JOIN QCheck_Alerts a
					ON al.AlertID = a.ID
					AND a.AlertType IN ('Reminder', 'Custom', 'Hours')
				INNER JOIN QCheck_ActiveAlerts aa
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID
				LEFT OUTER JOIN QCheck_AlertExceptions ae
					ON ae.ActiveAlertID = aa.ID
					AND ae.UserID = @UserID
					AND ae.IsActive = 1		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
					ORDER BY ListID
				) p				
			WHERE
				EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0))
	
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
				QCheck_ChecklistInstances ci
				INNER JOIN QCheck_Checklists c 
					on ci.checklistID = c.ID 
					AND c.IsDeleted = 0
					and ci.IsDeleted = 0
				INNER JOIN QCheck_ActiveChecklistArchive ac 
					on ac.InstanceID = ci.ID 
					AND CAST(GETDATE() as date) > @startDate
					AND (
						ac.DueTime BETWEEN @startDate and @endDate
						OR ac.ReminderDate BETWEEN @startDate and @endDate
					)
				INNER JOIN @tblAssigned ta
					on ta.ID = ci.ID
				LEFT OUTER JOIN @tblManaged tm
					on tm.ID = ci.ID
				LEFT OUTER JOIN QCheck_Schedule s 
					ON ci.ScheduleID = s.ID
				INNER JOIN @tblScheduledAlerts al
					ON al.ID = ci.ID
				INNER JOIN QCheck_Alerts a
					ON al.AlertID = a.ID
					AND a.AlertType IN ('Reminder', 'Custom', 'Hours')
				INNER JOIN QCheck_ActiveAlerts aa
					ON aa.ActiveChecklistID = ac.ID
					AND aa.AlertID = a.ID
				LEFT OUTER JOIN QCheck_AlertExceptions ae
					ON ae.ActiveAlertID = aa.ID
					AND ae.UserID = @UserID
					AND ae.IsActive = 1		
				LEFT OUTER JOIN QCheck_MultiStep ms on ms.checklistid = c.ID
				OUTER APPLY(
					select top 1 pli.ActiveChecklistID
					FROM Priorities_ListItems pli
					JOIN Priorities_Lists pl
						ON pl.ID = pli.ListID
						AND pli.ActiveChecklistID = ac.ID
						AND pl.UserID = @UserID	
					ORDER BY ListID
				) p			
			WHERE
				EXISTS (SELECT 'Y' FROM @IDs WHERE ID IN(-1, 0))
		END
	END
	
	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ChecklistId FROM @tblResults WHERE ChecklistId IS NOT NULL

	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	DELETE @recordIds
	INSERT INTO @recordIds
		SELECT DISTINCT objID FROM @tblResults WHERE objID IS NOT NULL

	EXEC dbo.Audit_Set @userId, @recordIds, 'ActiveChecklist', 2

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

/****** Object:  StoredProcedure [dbo].[QStatus_GetReport]    Script Date: 5/13/2024 4:18:05 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER   PROC [dbo].[QStatus_GetReport] (
	@UserID int,
	@ReportID int,
	@deletedDate datetime = null,
	@MoveCompleted bit = 0,
	@DueFilter datetime = null,
	@AssignedTo int = -1,
	@PriorityListSetID INT = -1

/*
set @UserID = 24
set @ReportID = 1100843
set @MoveCompleted = 0
set @AssignedTo = -1
set @PriorityListSetID = 149
--set @PriorityListSetID = -1
*/
) AS

BEGIN
	
	--exec sp_recompile 'QStatus_GetReport'
 
	SET NOCOUNT ON
	
	DECLARE @ReportUserID int
	DECLARE @LastReadDate datetime
	DECLARE @CompletedType varchar(50)
	DECLARE @CompletedOrder int
	DECLARE @Seed int
	DECLARE @PriorityListSetName VARCHAR(50)
	
	INSERT INTO QStatus_Seed
		SELECT 1

	SELECT @Seed = scope_identity()

	DELETE FROM QStatus_Seed
	--find all the tasks

	DECLARE @ForeignKeyIDs TABLE (
		ForeignKeyID INT PRIMARY KEY
	)

	INSERT INTO @ForeignKeyIDs 
		SELECT distinct activechecklistid 
		FROM qstatus_commentedreporttasks
		WHERE reportID = @reportID 

	--add a day to whatever was passed in (takes care of default to midnight)
	IF @DueFilter is not null
		SET @DueFilter = DateAdd(day, 1, @DueFilter)
	
	SELECT @CompletedType = 'Completed'
	--find out if they are a user or supervisor/ip

	SET @ReportUserID = 0

	SELECT 
		@ReportUserID = UserID
	FROM
		QStatus_GroupReport gr
		INNER JOIN QCheck_Groups g
			ON g.ID = gr.GroupID
		INNER JOIN QCheck_GroupMembership gm
			ON gm.GroupID = g.ID
			AND gr.ReportID = @ReportID
			AND gm.UserID = @UserID

	--default to 60 days ago
	SELECT @LastReadDate = getdate() - 60
	
	--find last time it was marked read by you if you are supervisor/ip
	SELECT 
		@LastReadDate = LastViewed
	FROM 
		QStatus_SupervisorsLastViewed
	WHERE
		ReportID = @ReportID 
		AND SupervisorUserID = @UserID
	
	--if it is your report, just use yesterday
	IF @ReportUserID = @UserID
		SELECT @LastReadDate = dateadd(day, -1, getdate())

	DECLARE @tasks table(
		ID int PRIMARY KEY,
		DueTime datetime,
		ReminderDate datetime,
		InstanceID int,
		assignees varchar(1000),
		controllers VARCHAR(1000),
		tasktype int,
		taskdescription varchar(1000),
		nativetype int,
		tasktypeorder int,
		priority int,
		prioritychanged bit,
		duedatechanged bit,
		newtask bit,
		CompletedDate datetime,
		Archived bit,
		description varchar(1000),
		tasknamechanged bit,
		isDeleted bit,
		isRecurring bit,
		isPriority bit,
		isDaily bit
	)

	declare @instances table(
		ID int PRIMARY KEY,
		ChecklistID int,
		isRecurring bit
	)

	declare @checklists table(
		ID int PRIMARY KEY,
		Description varchar(1000),
		tasknamechanged bit
	)

	-- 02/23/2011 dalvarado - priorities section
	declare @priorities table (
		ID int PRIMARY KEY IDENTITY(1,1),
		ListID int,
		InstanceID INT,
		Priority INT
	)

	INSERT INTO @priorities (
		ListID,
		InstanceID,
		Priority
	)
		SELECT 
			pl.ID,
			ac.InstanceID,
			pli.Priority
		FROM
			Priorities_ListSetLists plsl
			INNER JOIN Priorities_Lists pl
				ON plsl.ListID = pl.ID
			INNER JOIN Priorities_ListItems pli
				ON pli.ListID = pl.ID
			INNER JOIN QCheck_ActiveChecklists ac
				ON pli.ActiveChecklistID = ac.[ID]
		WHERE 
			plsl.SetID = @PriorityListSetID

	SELECT @PriorityListSetName = [Name]
	FROM Priorities_ListSets
	WHERE [ID] = @PriorityListSetID

	insert into @tasks (
		ID ,
		DueTime,
		ReminderDate,
		InstanceID ,
		assignees ,
		controllers,
		tasktype ,
		taskdescription ,
		nativetype ,
		tasktypeorder ,
		priority ,
		prioritychanged ,
		duedatechanged ,
		newtask ,
		CompletedDate ,
		Archived,
		IsDeleted,
		IsPriority,
		IsDaily
	)
		SELECT distinct
			ac.ID, 
			ac.DueTime,
			CASE WHEN CONVERT(VARCHAR(10), ac.ReminderDate, 101) <> CONVERT(VARCHAR(10), ac.DueTime, 101) THEN ac.ReminderDate ELSE NULL END,
			ac.InstanceID,
			isnull(al.assignees, ''),
			isnull(dbo.QCheck_ManagersList(c.[id]), ''),
			--dbo.QCheck_FullAssigneesList(ac.instanceid),
			tt.ID,
			tt.Description,
			tt.NativeType,
			tt.DisplayOrder,
			actt.Priority,
			0 as PriorityChanged,
			0 as DueDateChanged,
			CASE WHEN actt.CreateDt > @deletedDate THEN 1 ELSE 0 END as NewTask,
			CompletedDate, 
			0,
			c.IsDeleted,
			CASE WHEN p.InstanceID IS NULL THEN 0 ELSE 1 END AS IsPriority,
			CASE WHEN (freqType = 2 AND freqRecurrance = 1) OR (freqType = 3 AND freqRecurrance = 1 AND (freqInterval & 62) = 62) THEN 1 ELSE 0 END as IsDaily
		FROM
			QStatus_ActiveChecklistTaskType actt
			INNER JOIN QStatus_TaskTypes	tt
				ON actt.TaskType = tt.ID
				AND
					tt.IsDeleted = 0
			INNER JOIN QCheck_ActiveChecklists ac
				ON ac.ID = actt.ActiveChecklistID
			INNER JOIN qcheck_checklistinstances ci
				ON ci.ID = ac.InstanceID
			INNER JOIN qcheck_checklists c
				ON ci.ChecklistID = c.ID
			INNER JOIN QCheck_Assignments a
				ON a.instanceID = ci.ID
				AND (
					a.GroupID = @AssignedTo 
					or @AssignedTo = -1
				)
				AND a.IsDeleted = 0
			left outer join qcheck_assigneelookup al
				on al.instanceid = ac.instanceid
			left outer join QCheck_Schedule s 
				ON ci.ScheduleID = s.ID 
			left outer join @Priorities p
				ON ac.InstanceID = p.InstanceID			
		WHERE
			tt.ReportID = @ReportID
			AND (
				@DueFilter is null 
				OR ac.DueTime < @DueFilter
				OR isnull(ac.ReminderDate, ac.DueTime) < @DueFilter
				OR ac.ID in (
					SELECT ForeignKeyID 
					FROM @ForeignKeyIDs
				)
			)

	insert into @tasks (
		ID ,
		DueTime,
		ReminderDate,
		InstanceID ,
		assignees ,
		controllers,
		tasktype ,
		taskdescription ,
		nativetype ,
		tasktypeorder ,
		priority ,
		prioritychanged ,
		duedatechanged ,
		newtask ,
		CompletedDate ,
		Archived ,
		IsPriority,
		IsDaily
	)
		SELECT distinct 
			ac.ID, 
			ac.DueTime,
			CASE WHEN CONVERT(VARCHAR(10), ac.ReminderDate, 101) <> CONVERT(VARCHAR(10), ac.DueTime, 101) THEN ac.ReminderDate ELSE NULL END,
			ac.InstanceID, 
			isnull(al.assignees, ''),
			isnull(dbo.QCheck_ManagersList(ISNULL(cia.ChecklistID, ci.ChecklistID)), ''),
			--dbo.QCheck_FullAssigneesList(ac.instanceid),
			tt.ID,
			tt.Description,
			tt.NativeType,
			tt.DisplayOrder,
			actt.Priority,
			0 as PriorityChanged,
			0 as DueDateChanged,
			CASE WHEN actt.CreateDt > @deletedDate THEN 1 ELSE 0 END as NewTask,
			CompletedDate, 
			1,
			0,
			0
		FROM
			QStatus_ActiveChecklistTaskType actt
			INNER JOIN QStatus_TaskTypes	tt
				ON actt.TaskType = tt.ID
				AND tt.IsDeleted = 0
			INNER JOIN QCheck_ActiveChecklistArchive ac
				ON ac.ID = actt.ActiveChecklistID
				AND ac.archivedate > @deleteddate 
				AND @deleteddate is not null
			INNER JOIN QCheck_ActiveAssignmentArchive aa
				ON aa.ActiveChecklistID = ac.ID
			LEFT OUTER JOIN QCheck_ChecklistInstanceArchive cia
				ON ac.InstanceID = cia.[ID]
			-- 2/26/2013 dalvarado - found cases where the instance wasn't archived with the active checklist, so need to look
			-- in both checklistinstances and checklistinstancearchive.
			left outer join qcheck_checklistinstances ci
				ON ac.InstanceID = ci.ID
			left outer join qcheck_assigneelookup al
				on al.instanceid = ac.instanceid
		WHERE
			tt.ReportID = @ReportID
			AND (
				@DueFilter is null 
				OR ac.DueTime < @DueFilter 
				OR isnull(ac.ReminderDate, ac.DueTime) < @DueFilter 
				OR ac.ID in (
					SELECT ForeignKeyID 
					FROM @ForeignKeyIDs
				)
			)
			AND (
				@AssignedTo = -1
				OR aa.AssignmentsID in (
					SELECT ID 
					FROM QCheck_Assignments
					WHERE 
						GroupID = @AssignedTo 
						and isdeleted = 0
				)
				OR aa.AssignmentsID in (
					SELECT ID 
					FROM QCheck_AssignmentArchive
					WHERE 
						GroupID = @AssignedTo 
						and isdeleted = 0
				)
			)

	update 
		@tasks
	set 
		DueDateChanged = 1
	from 
		@tasks t
		inner join QStatus_DueDateChanges ddc
			on ddc.ActiveChecklistID =t.ID
			AND ddc.UpdateDt > @deletedDate
	
	update 
		@tasks
	set 
		PriorityChanged = 1
	from 
		@tasks t
		inner join QStatus_PriorityChanges pc
			on pc.ActiveChecklistID =t.ID
			AND pc.UpdateDt > @deletedDate

	-- 02/23/2011 dalvarado
	IF @PriorityListSetID <> -1 BEGIN

		UPDATE 
			@tasks
		SET 
			TaskType = -1000,
			TaskDescription = 'Top Priorities' + ISNULL(' - ' + @PriorityListSetName, ''),
			TaskTypeOrder = 10,
			Priority = p.Priority
		FROM 
			@tasks t
			inner join @priorities p
				on t.InstanceID = p.InstanceID

	END

	insert into @instances

		SELECT distinct
			ci.ID,
			ci.ChecklistID,
			CASE 
				WHEN s.freqType > 1 THEN 1 
				ELSE 0 
			END as isRecurring
		FROM 
			QCheck_ChecklistInstances ci
			INNER JOIN @tasks t
				ON t.InstanceID = ci.ID
			LEFT OUTER JOIN QCheck_Schedule s 
				ON ci.ScheduleID = s.ID 
		WHERE
			ci.IsDeleted = 0 
			OR @deleteddate is not null

		UNION ALL

		SELECT distinct
			ci.ID,
			ci.ChecklistID,
			CASE 
				WHEN s.freqType > 1 THEN 1 
				ELSE 0 
			END as isRecurring
		FROM 
			QCheck_ChecklistInstanceArchive ci
			INNER JOIN @tasks t
				ON t.InstanceID = ci.ID
			LEFT OUTER JOIN QCheck_Schedule s 
				ON ci.ScheduleID = s.ID 
		WHERE
			(
				ci.IsDeleted = 0 
				OR @deleteddate is not null
			)
			AND ci.archivedate > @deleteddate 
			AND @deleteddate is not null
	

	insert into @checklists

		SELECT DISTINCT
			c.ID,
			c.Name,
			CASE 
				WHEN tnc.ChecklistID IS NULL THEN 0 
				ELSE 1 
			END as TaskNameChanged
		FROM 
			QCheck_Checklists c
			INNER JOIN @instances ci
				ON c.ID = ci.ChecklistID
			LEFT OUTER JOIN QStatus_TaskNameChanges tnc
				ON tnc.ChecklistID = c.ID
				AND tnc.UpdateDt > @deletedDate
		WHERE
			c.IsDeleted = 0 
			OR @deleteddate is not null

		UNION ALL

		SELECT DISTINCT
			c.ID,
			c.Name,
			CASE 
				WHEN tnc.ChecklistID IS NULL THEN 0 
				ELSE 1 
			END as TaskNameChanged
		FROM 
			QCheck_ChecklistArchive c
			INNER JOIN @instances ci
				ON c.ID = ci.ChecklistID
			LEFT OUTER JOIN QStatus_TaskNameChanges tnc
				ON tnc.ChecklistID = c.ID
				AND tnc.UpdateDt > @deletedDate
		WHERE
			(
				c.IsDeleted = 0 
				OR @deleteddate is not null
			)
			AND c.archivedate > @deleteddate 
			AND @deleteddate is not null

	DELETE FROM @instances where checklistid not in (select id from @checklists)
	DELETE FROM @tasks where instanceid not in (select id from @instances)

	update @tasks
	set 
		description = c.description,
		tasknamechanged = c.tasknamechanged,
		isRecurring = i.isRecurring
	from 
		@tasks t
		inner join @instances i
			on i.id = t.instanceid
		inner join @checklists c
			on c.id = i.checklistid

	INSERT INTO QStatus_TempTasks (
		ID, 
		keyID, 
		specialTask
	)
		SELECT 
			@Seed, 
			id, 
			0
		FROM 
			@Tasks
	
	INSERT INTO QStatus_TempTasks (
		ID, 
		keyID, 
		specialTask
	)
		SELECT 
			@Seed, 
			-1 * st.id, 
			1
		FROM
			QStatus_SpecialTasks st
			INNER JOIN QStatus_TaskTypes tt
				ON st.TaskType = tt.ID
				AND tt.IsDeleted = 0
				AND tt.ReportID = @ReportID
				AND st.IsDeleted = 0

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT ID FROM @checklists

	EXEC dbo.Audit_Set @userId, @recordIds, 'Checklist', 2

	--START HEADER
	SELECT
		null as ID, 
		dbo.QStatus_GetUserNames(r.ID) + 
			r.Name + ' - Status Report - '
			+ CASE 
				WHEN r.LastReportDate = 0 THEN 
					'No Status'
				ELSE 
					ISNULL(datename(dw, r.LastReportDate) + ' ', '') 
					+ ISNULL(CONVERT(varchar, r.LastReportDate, 101) + ' ', '') 
					+ ltrim(isnull(right(convert(varchar, r.LastReportDate, 100), 7), ''))
			END as Description,
		@LastReadDate as DueDate,
		@LastReadDate AS ReminderDate,
		@LastReadDate AS SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Header Row' as Type,
		-1 As NativeType,
		null as IsDeleted,
		1 As ReturnOrder,
		'0' as TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		QStatus_Report r
	WHERE
		r.ID = @ReportID
	--END OF HEADER
	
	UNION ALL

	SELECT DISTINCT
		null as ID, 
		null as Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		-1,
		null as IsDeleted,
		2 As ReturnOrder, 
		'0' As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as isDaily

	UNION ALL

	-- SECTION HEADS
	SELECT DISTINCT
		CASE WHEN t.CompletedDate IS Not Null then Null ELSE t.TaskType END AS ID, 
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType +' - '+ taskdescription ELSE taskdescription END AS Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeorder * 1000 * 2 + 1000 Else t.tasktypeorder * 1000 * 2 END As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(t.tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		@tasks t
			
	UNION ALL

	--START SECTION HEADINGS
	SELECT DISTINCT
		null as ID, 
		null as Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Headings Row' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeorder * 1000 * 2 + 1000 Else t.tasktypeorder * 1000 * 2 END + 1 As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(t.tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		@tasks t
		
	UNION ALL

	--START SECTION ENDERS
	SELECT DISTINCT
		null as ID, 
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType else t.taskdescription end as Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END + 999 As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		@tasks t
		
	UNION ALL
	
	--START SECTION
	SELECT 
		DISTINCT
		t.ID, 
		t.description + 
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				' (DELETED)'
			ELSE
				''
			END
		ELSE
			''
		END as Description,
		Convert(varchar, t.DueTime, 101) as DueDate,
		Convert(varchar, t.ReminderDate, 101) as ReminderDate,
		Convert(varchar, ISNULL(t.ReminderDate, t.DueTime), 101) as SortDate,
		t.Priority,
		CAST(t.ID as varchar) As Comments,
		0 as UpdatedDate,
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType else t.taskDescription end As Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else
			CASE WHEN t.archived = 1 THEN
				3
			ELSE
				t.NativeType
			END
		END as NativeType,
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				1
			ELSE
				IsDeleted
			END
		ELSE
			IsDeleted
		END as IsDeleted,
		--0 as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END + 100 + t.Priority As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		PriorityChanged,
		DueDateChanged,
		TaskNameChanged,
		NewTask,
		Assignees as AssignedTo,
		Controllers,
		t.isRecurring as isRecurring,
		t.IsDaily as isDaily
	FROM
		@tasks t
		
	UNION ALL

	SELECT 
		DISTINCT
		t.ID, 
		t.description + 
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				' (DELETED)'
			ELSE
				''
			END
		ELSE
			''
		END as Description,
		Convert(varchar, t.DueTime, 101) as DueDate,
		Convert(varchar, t.ReminderDate, 101) as ReminderDate,
		Convert(varchar, ISNULL(t.ReminderDate, t.DueTime), 101) as SortDate,
		t.Priority,
		CAST(t.ID as varchar) As Comments,
		0 as UpdatedDate,
		'Comments' As Type,
		999 as NativeType,
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				1
			ELSE
				IsDeleted
			END
		ELSE
			IsDeleted
		END as IsDeleted,
		--0 as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END + 100 + t.Priority As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		PriorityChanged,
		DueDateChanged,
		TaskNameChanged,
		NewTask,
		Assignees as AssignedTo,
		Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		@tasks t
		
	UNION ALL
 
	-- SECTION HEADS SPECIAL (General Comments, etc)
	SELECT DISTINCT
		null as ID, 
		tt.Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		tt.NativeType ,
		null as IsDeleted,
		tt.DisplayOrder * 1000 * 2 As ReturnOrder,
		CAST(tt.ID As varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		QStatus_SpecialTasks st
		INNER JOIN QStatus_TaskTypes	tt
			ON st.TaskType = tt.ID
			AND tt.IsDeleted = 0
			AND tt.ReportID = @ReportID
			AND st.IsDeleted = 0
	--END SECTION HEADS SPECIAL 

	UNION ALL

	-- SECTION ENDERS SPECIAL (General Comments, etc)
	SELECT DISTINCT
		null as ID, 
		tt.Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'EnderType' as Type,
		tt.NativeType ,
		null as IsDeleted,
		tt.DisplayOrder * 1000 * 2 + 999 As ReturnOrder,
		CAST(tt.ID AS varchar) AS TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring, 
		null as IsDaily
	FROM
		QStatus_SpecialTasks st
		INNER JOIN QStatus_TaskTypes	tt
			ON st.TaskType = tt.ID
			AND tt.IsDeleted = 0
			AND tt.ReportID = @ReportID
			AND st.IsDeleted = 0
	--END SECTION ENDERS SPECIAL 
	
	UNION ALL

	-- SECTION SPECIAL (General Comments, etc)
	SELECT DISTINCT
		st.ID * -1 as ID, -- negative for special sections
		tt.Description,
		0 as DueDate,
		0 as ReminderDate,
		0 as SortDate,
		st.Priority as Priority,
		CAST((st.ID * -1) as varchar) As Comments,
		0 as UpdatedDate,
		tt.Description as Type,
		tt.NativeType ,
		0 as IsDeleted,
		tt.DisplayOrder * 1000 * 2 + 100 + st.Priority As ReturnOrder,
		CAST(tt.ID AS varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
		--0 As ShowSupervisor
	FROM
		QStatus_SpecialTasks st
		INNER JOIN QStatus_TaskTypes	tt
			ON st.TaskType = tt.ID
			AND tt.IsDeleted = 0
			AND tt.ReportID = @ReportID
			AND st.IsDeleted = 0
	--END SECTION SPECIAL 
	
	ORDER BY 
		ReturnOrder,
		SortDate asc,
		ReminderDate asc, 
		DueDate asc, 
		description, 
		NativeType asc

	SELECT 
		IsConfidential 
	FROM
		QStatus_Report
	WHERE
		ID = @ReportID

	SELECT @Seed
	SET NOCOUNT OFF
END
GO

/****** Object:  StoredProcedure [dbo].[QStatus_GetStatusReportSummary]    Script Date: 5/13/2024 4:18:44 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER proc [dbo].[QStatus_GetStatusReportSummary]
	@UserID int,
	@ReportID int,
	@deletedDate datetime = null,
	@MoveCompleted bit = 0,
	@DueFilter datetime = null,
	@AssignedTo int = -1,
	@PriorityListSetID INT = -1
 as
	SET NOCOUNT ON
	
	--@UserID int = 471,
	--@ReportID int = 1100913,

	DECLARE @ReportUserID int
	DECLARE @LastReadDate datetime
	DECLARE @CompletedType varchar(50)
	DECLARE @CompletedOrder int
	DECLARE @Seed int
	DECLARE @PriorityListSetName VARCHAR(50)
	
	INSERT INTO QStatus_Seed
		SELECT 1

	SELECT @Seed = scope_identity()

	DELETE FROM QStatus_Seed
	--find all the tasks

	DECLARE @ForeignKeyIDs TABLE (
		ForeignKeyID INT PRIMARY KEY
	)

	INSERT INTO @ForeignKeyIDs 
		SELECT distinct activechecklistid 
		FROM qstatus_commentedreporttasks
		WHERE reportID = @reportID 

	--add a day to whatever was passed in (takes care of default to midnight)
	IF @DueFilter is not null
		SET @DueFilter = DateAdd(day, 1, @DueFilter)
	
	SELECT @CompletedType = 'Completed'
	--find out if they are a user or supervisor/ip

	SET @ReportUserID = 0

	SELECT 
		@ReportUserID = UserID
	FROM
		QStatus_GroupReport gr
		INNER JOIN QCheck_Groups g
			ON g.ID = gr.GroupID
		INNER JOIN QCheck_GroupMembership gm
			ON gm.GroupID = g.ID
			AND gr.ReportID = @ReportID
			AND gm.UserID = @UserID

	--default to 60 days ago
	SELECT @LastReadDate =  getdate() - 60
	
	--find last time it was marked read by you if you are supervisor/ip
	SELECT 
		@LastReadDate = LastViewed
	FROM 
		QStatus_SupervisorsLastViewed
	WHERE
		ReportID = @ReportID 
		AND SupervisorUserID = @UserID
	
	--if it is your report, just use yesterday
	IF @ReportUserID = @UserID
		SELECT @LastReadDate = dateadd(day, -1, getdate())

	DECLARE @tasks table(
		ID int PRIMARY KEY,
		DueTime datetime,
		ReminderDate datetime,
		InstanceID int,
		assignees varchar(1000),
		controllers VARCHAR(1000),
		tasktype int,
		taskdescription varchar(1000),
		nativetype int,
		tasktypeorder int,
		priority int,
		prioritychanged bit,
		duedatechanged bit,
		newtask bit,
		CompletedDate datetime,
		Archived bit,
		description varchar(1000),
		tasknamechanged bit,
		isDeleted bit,
		isRecurring bit,
		isPriority bit,
		isDaily bit
	)

	declare @instances table(
		ID int PRIMARY KEY,
		ChecklistID int,
		isRecurring bit
	)

	declare @checklists table(
		ID int PRIMARY KEY,
		Description varchar(1000),
		tasknamechanged bit
	)

	-- 02/23/2011 dalvarado - priorities section
	declare @priorities table (
		ID int PRIMARY KEY IDENTITY(1,1),
		ListID int,
		InstanceID INT,
		Priority INT
	)

	INSERT INTO @priorities (
		ListID,
		InstanceID,
		Priority
	)
		SELECT 
			pl.ID,
			ac.InstanceID,
			pli.Priority
		FROM
			Priorities_ListSetLists plsl
			INNER JOIN Priorities_Lists pl
				ON plsl.ListID = pl.ID
			INNER JOIN Priorities_ListItems pli
				ON pli.ListID = pl.ID
			INNER JOIN QCheck_ActiveChecklists ac
				ON pli.ActiveChecklistID = ac.[ID]
		WHERE 
			plsl.SetID = @PriorityListSetID

	SELECT @PriorityListSetName = [Name]
	FROM Priorities_ListSets
	WHERE [ID] = @PriorityListSetID


	insert into @tasks (
		ID ,
		DueTime,
		ReminderDate,
		InstanceID ,
		assignees ,
		controllers,
		tasktype ,
		taskdescription ,
		nativetype ,
		tasktypeorder ,
		priority ,
		prioritychanged ,
		duedatechanged ,
		newtask ,
		CompletedDate ,
		Archived,
		IsDeleted,
		IsPriority,
		IsDaily
	)
		SELECT distinct
			ac.ID, 
			ac.DueTime,
			CASE WHEN CONVERT(VARCHAR(10), ac.ReminderDate, 101) <> CONVERT(VARCHAR(10), ac.DueTime, 101) THEN ac.ReminderDate ELSE NULL END,
			ac.InstanceID,
			isnull(al.assignees, ''),
			isnull(dbo.QCheck_ManagersList(c.[id]), ''),
			--dbo.QCheck_FullAssigneesList(ac.instanceid),
			tt.ID,
			tt.Description,
			tt.NativeType,
			tt.DisplayOrder,
			actt.Priority,
			0 as PriorityChanged,
			0 as DueDateChanged,
			CASE WHEN actt.CreateDt > @deletedDate THEN 1 ELSE 0 END  as NewTask,
			CompletedDate, 
			0,
			c.IsDeleted,
			CASE WHEN p.InstanceID IS NULL THEN 0 ELSE 1 END AS IsPriority,
			CASE WHEN (freqType = 2 AND freqRecurrance = 1) OR (freqType = 3 AND freqRecurrance = 1 AND (freqInterval & 62) = 62) THEN 1 ELSE 0 END as IsDaily
		FROM
			QStatus_ActiveChecklistTaskType actt
			INNER JOIN QStatus_TaskTypes	tt
				ON actt.TaskType = tt.ID
				--AND
				--	tt.IsDeleted = 0
			INNER JOIN QCheck_ActiveChecklists ac
				ON ac.ID = actt.ActiveChecklistID
			INNER JOIN qcheck_checklistinstances ci
				ON ci.ID = ac.InstanceID
			INNER JOIN qcheck_checklists c
				ON ci.ChecklistID = c.ID
			INNER JOIN QCheck_Assignments a
				ON a.instanceID = ci.ID
				AND (
					a.GroupID = @AssignedTo 
					or @AssignedTo = -1
				)
				AND a.IsDeleted = 0
			left outer join qcheck_assigneelookup al
				on al.instanceid = ac.instanceid
			left outer join QCheck_Schedule s 
				ON ci.ScheduleID = s.ID 
			left outer join @Priorities p
				ON ac.InstanceID = p.InstanceID
			
		WHERE
			tt.ReportID = @ReportID
			AND (
				@DueFilter is null 
				OR ac.DueTime < @DueFilter
				OR isnull(ac.ReminderDate, ac.DueTime) < @DueFilter
				OR ac.ID in (
					SELECT ForeignKeyID 
					FROM @ForeignKeyIDs
				)
			)


	insert into @tasks (
		ID ,
		DueTime,
		ReminderDate,
		InstanceID ,
		assignees ,
		controllers,
		tasktype ,
		taskdescription ,
		nativetype ,
		tasktypeorder ,
		priority ,
		prioritychanged ,
		duedatechanged ,
		newtask ,
		CompletedDate ,
		Archived ,
		IsPriority,
		IsDaily
	)
		SELECT distinct 
			ac.ID, 
			ac.DueTime,
			CASE WHEN CONVERT(VARCHAR(10), ac.ReminderDate, 101) <> CONVERT(VARCHAR(10), ac.DueTime, 101) THEN ac.ReminderDate ELSE NULL END,
			ac.InstanceID, 
			isnull(al.assignees, ''),
			isnull(dbo.QCheck_ManagersList(ISNULL(cia.ChecklistID, ci.ChecklistID)), ''),
			--dbo.QCheck_FullAssigneesList(ac.instanceid),
			tt.ID,
			tt.Description,
			tt.NativeType,
			tt.DisplayOrder,
			actt.Priority,
			0 as PriorityChanged,
			0 as DueDateChanged,
			CASE WHEN actt.CreateDt > @deletedDate THEN 1 ELSE 0 END  as NewTask,
			CompletedDate, 
			1,
			0,
			0
		FROM
			QStatus_ActiveChecklistTaskType actt
			INNER JOIN QStatus_TaskTypes	tt
				ON actt.TaskType = tt.ID
				--AND tt.IsDeleted = 0
			INNER JOIN QCheck_ActiveChecklistArchive ac
				ON ac.ID = actt.ActiveChecklistID
				AND ac.archivedate > @deleteddate 
				AND @deleteddate is not null
			INNER JOIN QCheck_ActiveAssignmentArchive aa
				ON aa.ActiveChecklistID = ac.ID
			LEFT OUTER JOIN QCheck_ChecklistInstanceArchive cia
				ON ac.InstanceID = cia.[ID]
			-- 2/26/2013 dalvarado - found cases where the instance wasn't archived with the active checklist, so need to look
			-- in both checklistinstances and checklistinstancearchive.
			left outer join qcheck_checklistinstances ci
				ON ac.InstanceID = ci.ID
			left outer join qcheck_assigneelookup al
				on al.instanceid = ac.instanceid
		WHERE
			tt.ReportID = @ReportID
			AND (
				@DueFilter is null 
				OR ac.DueTime < @DueFilter 
				OR isnull(ac.ReminderDate, ac.DueTime) < @DueFilter 
				OR ac.ID in (
					SELECT ForeignKeyID 
					FROM @ForeignKeyIDs
				)
			)
			AND (
				@AssignedTo = -1
				OR aa.AssignmentsID in (
					SELECT ID 
					FROM QCheck_Assignments
					WHERE 
						GroupID = @AssignedTo 
						and isdeleted = 0
				)
				OR aa.AssignmentsID in (
					SELECT ID 
					FROM QCheck_AssignmentArchive
					WHERE 
						GroupID = @AssignedTo 
						and isdeleted = 0
				)
			)

	update 
		@tasks
	set 
		DueDateChanged = 1
	from 
		@tasks t
		inner join QStatus_DueDateChanges ddc
			on ddc.ActiveChecklistID =t.ID
			AND ddc.UpdateDt > @deletedDate
	
	update 
		@tasks
	set 
		PriorityChanged = 1
	from 
		@tasks t
		inner join QStatus_PriorityChanges pc
			on pc.ActiveChecklistID =t.ID
			AND pc.UpdateDt > @deletedDate

	-- 02/23/2011 dalvarado
	IF @PriorityListSetID <> -1 BEGIN

		UPDATE 
			@tasks
		SET 
			TaskType = -1000,
			TaskDescription = 'Top Priorities' + ISNULL(' - ' + @PriorityListSetName, ''),
			TaskTypeOrder = 10,
			Priority = p.Priority
		FROM 
			@tasks t
			inner join @priorities p
				on t.InstanceID = p.InstanceID

	END


	insert into @instances

		SELECT distinct
			ci.ID,
			ci.ChecklistID,
			CASE 
				WHEN s.freqType > 1 THEN 1 
				ELSE 0 
			END as isRecurring
		FROM 
			QCheck_ChecklistInstances ci
			INNER JOIN @tasks t
				ON t.InstanceID = ci.ID
			LEFT OUTER JOIN QCheck_Schedule s 
				ON ci.ScheduleID = s.ID 
		WHERE
			ci.IsDeleted = 0 
			OR @deleteddate is not null

		UNION ALL

		SELECT distinct
			ci.ID,
			ci.ChecklistID,
			CASE 
				WHEN s.freqType > 1 THEN 1 
				ELSE 0 
			END as isRecurring
		FROM 
			QCheck_ChecklistInstanceArchive ci
			INNER JOIN @tasks t
				ON t.InstanceID = ci.ID
			LEFT OUTER JOIN QCheck_Schedule s 
				ON ci.ScheduleID = s.ID 
		WHERE
			(
				ci.IsDeleted = 0 
				OR @deleteddate is not null
			)
			AND ci.archivedate > @deleteddate 
			AND @deleteddate is not null
	

	insert into @checklists

		SELECT DISTINCT
			c.ID,
			c.Name,
			CASE 
				WHEN tnc.ChecklistID IS NULL THEN 0 
				ELSE 1 
			END as TaskNameChanged
		FROM 
			QCheck_Checklists c
			INNER JOIN @instances ci
				ON c.ID = ci.ChecklistID
			LEFT OUTER JOIN QStatus_TaskNameChanges tnc
				ON tnc.ChecklistID = c.ID
				AND tnc.UpdateDt > @deletedDate
		WHERE
			c.IsDeleted = 0 
			OR @deleteddate is not null

		UNION ALL

		SELECT DISTINCT
			c.ID,
			c.Name,
			CASE 
				WHEN tnc.ChecklistID IS NULL THEN 0 
				ELSE 1 
			END as TaskNameChanged
		FROM 
			QCheck_ChecklistArchive c
			INNER JOIN @instances ci
				ON c.ID = ci.ChecklistID
			LEFT OUTER JOIN QStatus_TaskNameChanges tnc
				ON tnc.ChecklistID = c.ID
				AND tnc.UpdateDt > @deletedDate
		WHERE
			(
				c.IsDeleted = 0 
				OR @deleteddate is not null
			)
			AND c.archivedate > @deleteddate 
			AND @deleteddate is not null


	DELETE FROM @instances where checklistid not in (select id from @checklists)
	DELETE FROM @tasks where instanceid not in (select id from @instances)


	update @tasks
	set 
		description = c.description,
		tasknamechanged = c.tasknamechanged,
		isRecurring = i.isRecurring
	from 
		@tasks t
		inner join @instances i
			on i.id = t.instanceid
		inner join @checklists c
			on c.id = i.checklistid


	INSERT INTO QStatus_TempTasks (
		ID, 
		keyID, 
		specialTask
	)
		SELECT 
			@Seed, 
			id, 
			0
		FROM 
			@Tasks
	
	INSERT INTO QStatus_TempTasks (
		ID, 
		keyID, 
		specialTask
	)
		SELECT 
			@Seed, 
			-1 * st.id, 
			1
		FROM
			QStatus_SpecialTasks st
			INNER JOIN QStatus_TaskTypes  tt
				ON st.TaskType = tt.ID
			--	AND tt.IsDeleted = 0
				AND tt.ReportID = @ReportID
				AND st.IsDeleted = 0


	--START HEADER
	SELECT
		null as ID, 
		dbo.QStatus_GetUserNames(r.ID) + 
			r.Name + ' - Status Report - '
			+ CASE 
				WHEN r.LastReportDate = 0 THEN 
					'No Status'
				ELSE 
					ISNULL(datename(dw, r.LastReportDate) + ' ', '') 
					+ ISNULL(CONVERT(varchar, r.LastReportDate, 101) + ' ', '') 
					+ ltrim(isnull(right(convert(varchar, r.LastReportDate, 100), 7), ''))
			END as Description,
		@LastReadDate as DueDate,
		@LastReadDate AS ReminderDate,
		@LastReadDate AS SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Header Row' as Type,
		-1 As NativeType,
		null as IsDeleted,
		1 As ReturnOrder,
		'0' as TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		QStatus_Report r
	WHERE
		r.ID = @ReportID
	--END OF HEADER

	UNION ALL

	-- SECTION HEADS
	SELECT DISTINCT
		CASE WHEN t.CompletedDate IS Not Null then Null ELSE t.TaskType END AS ID, 
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType +' - '+ taskdescription ELSE taskdescription END AS Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else t.NativeType end as NativeType,
		null as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeorder * 1000 * 2 + 1000 Else t.tasktypeorder * 1000 * 2 END  As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(t.tasktype as varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		@tasks t
	
	UNION ALL
	
	--START SECTION
	SELECT 
		DISTINCT
		t.ID, 
		t.description + 
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				' (DELETED)'
			ELSE
				''
			END
		ELSE
			''
		END as Description,
		Convert(varchar, t.DueTime, 101) as DueDate,
		Convert(varchar, t.ReminderDate, 101) as ReminderDate,
		Convert(varchar, ISNULL(t.ReminderDate, t.DueTime), 101) as SortDate,
		t.Priority,
		CAST(t.ID as varchar) As Comments,
		0 as UpdatedDate,
		CASE WHEN t.CompletedDate IS Not Null then @CompletedType else t.taskDescription end As Type,
		CASE WHEN t.CompletedDate IS Not Null then 2 else
			CASE WHEN t.archived = 1 THEN
				3
			ELSE
				t.NativeType
			END
		END as NativeType,
		CASE WHEN t.CompletedDate IS NULL THEN
			CASE WHEN t.archived = 1 THEN
				1
			ELSE
				IsDeleted
			END
		ELSE
			IsDeleted
		END as IsDeleted,
		--0 as IsDeleted,
		CASE WHEN t.CompletedDate IS Not Null then t.tasktypeOrder * 1000 * 2 + 1000 Else t.tasktypeOrder * 1000 * 2 END  + 100 + t.Priority As ReturnOrder,
		CASE WHEN t.CompletedDate IS Not Null then 'C' else '' END + CAST(tasktype as varchar) As TaskType,
		PriorityChanged,
		DueDateChanged,
		TaskNameChanged,
		NewTask,
		Assignees as AssignedTo,
		Controllers,
		t.isRecurring as isRecurring,
		t.IsDaily as isDaily
	FROM
		@tasks t
		
	UNION ALL
 
	-- SECTION HEADS SPECIAL (General Comments, etc)
	SELECT DISTINCT
		null as ID, 
		tt.Description,
		null as DueDate,
		null as ReminderDate,
		null as SortDate,
		null as Priority,
		null as Comments,
		null as UpdatedDate,
		'Sub Header Row' as Type,
		tt.NativeType ,
		null as IsDeleted,
		tt.DisplayOrder * 1000 * 2 As ReturnOrder,
		CAST(tt.ID As varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
	FROM
		QStatus_SpecialTasks st
		INNER JOIN QStatus_TaskTypes	tt
			ON st.TaskType = tt.ID
			--AND tt.IsDeleted = 0
			AND tt.ReportID = @ReportID
			AND st.IsDeleted = 0
	--END SECTION HEADS SPECIAL 

	UNION ALL

	-- SECTION SPECIAL (General Comments, etc)
	SELECT DISTINCT
		st.ID * -1 as ID,  -- negative for special sections
		tt.Description,
		0 as DueDate,
		0 as ReminderDate,
		0 as SortDate,
		st.Priority as Priority,
		CAST((st.ID * -1) as varchar) As Comments,
		0 as UpdatedDate,
		tt.Description as Type,
		tt.NativeType ,
		0 as IsDeleted,
		tt.DisplayOrder * 1000 * 2 + 100 + st.Priority As ReturnOrder,
		CAST(tt.ID AS varchar) As TaskType,
		0 as PriorityChanged,
		0 as DueDateChanged,
		0 as TaskNameChanged,
		0 as NewTask,
		null as AssignedTo,
		null as Controllers,
		null as isRecurring,
		null as IsDaily
		--0 As ShowSupervisor
	FROM
		QStatus_SpecialTasks st
		INNER JOIN QStatus_TaskTypes	tt
			ON st.TaskType = tt.ID
			--AND tt.IsDeleted = 0
			AND tt.ReportID = @ReportID
			AND st.IsDeleted = 0
	--END SECTION SPECIAL 
	
	ORDER BY 
		ReturnOrder,
		SortDate asc,
		ReminderDate asc, 
		DueDate asc, 
		description, 
		NativeType asc

	SET NOCOUNT OFF
GO

/****** Object:  StoredProcedure [dbo].[QStatus_GPR_IT_Priorities]    Script Date: 5/13/2024 4:19:04 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER  proc [dbo].[QStatus_GPR_IT_Priorities]
AS
BEGIN

	declare @instanceid int, @activechecklistid int, @tasktype int, @priority int, @userID int, @reportid int
	set @tasktype = 1110414
	set @userid = 50
	set @reportid = 1100996

	DECLARE @NewTaskTypeID int


	DECLARE ACCURS CURSOR
			FOR 
	
	select actt.activechecklistid 
	from qstatus_activechecklisttasktype actt
	inner join qcheck_activechecklists ac
		on ac.id = actt.activechecklistid
		and ac.completeddate is null
	where tasktype in (1110414)
	
	OPEN ACCURS

	FETCH NEXT FROM ACCURS INTO @activechecklistid
	WHILE @@FETCH_STATUS = 0 
	BEGIN
		
		exec QCheck_RemoveFromReport @activechecklistid, @reportid, 50		

		FETCH NEXT FROM ACCURS INTO @activechecklistid
	END
	CLOSE ACCURS
	DEALLOCATE ACCURS

	DECLARE PRCURS CURSOR
			FOR 
	
	select distinct ac.id, ac.instanceid, li.priority 
	from Priorities_Lists p
	INNER JOIN Priorities_ListItems li
		ON li.ListID = p.ID
	inner join qcheck_activechecklists ac
	on li.activechecklistid = ac.id
	where p.UserID = @userid AND p.IsDefaultList = 1
	and li.priority > 0
	
	
	OPEN PRCURS

	FETCH NEXT FROM PRCURS INTO @activechecklistid, @instanceid, @priority
	WHILE @@FETCH_STATUS = 0 BEGIN
		
		set @NewTaskTypeID = null
		
		EXEC QCheck_AddInstanceTaskType @InstanceID, @tasktype, @priority, @NewTaskTypeID OUTPUT
		
		FETCH NEXT FROM PRCURS INTO @activechecklistid, @instanceid, @priority
	END
	CLOSE PRCURS
	DEALLOCATE PRCURS

	set @tasktype = 1107038
	set @userid = 59


	DECLARE PRCURS CURSOR
			FOR 
	
	select distinct ac.id, ac.instanceid, li.priority 
	from priorities_lists p
	JOIN Priorities_ListItems li
		ON li.ListID = p.ID
	inner join qcheck_activechecklists ac
		on li.activechecklistid = ac.id
	where p.userid = @userid
		and p.IsDefaultList = 1
		and li.priority > 0	
	
	OPEN PRCURS

	FETCH NEXT FROM PRCURS  INTO @activechecklistid, @instanceid, @priority
	WHILE @@FETCH_STATUS = 0 
	BEGIN		
		
		set @NewTaskTypeID = null
		EXEC QCheck_AddInstanceTaskType @InstanceID, @tasktype, @priority, @NewTaskTypeID OUTPUT

		FETCH NEXT FROM PRCURS  INTO @activechecklistid, @instanceid, @priority
	END
	CLOSE PRCURS
	DEALLOCATE PRCURS

	update qstatus_report set isdirty = 1
	where id = @reportid

END
GO

/****** Object:  StoredProcedure [dbo].[QStatus_GPR_IT_Priorities_Shortterm]    Script Date: 5/13/2024 4:19:23 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER  proc [dbo].[QStatus_GPR_IT_Priorities_Shortterm]
(
	@tasktype int,
	@userid int,
	@reportID int
)
AS
BEGIN

	declare @instanceid int, @activechecklistid int,  @priority int 

	DECLARE @NewTaskTypeID int
	--set @tasktype = 1112536
	--set @userid = 50
	--set @reportid = 1101317

	DECLARE ACCURS CURSOR FOR 	
	select activechecklistid from qstatus_activechecklisttasktype
	where tasktype = @tasktype	
	
	OPEN ACCURS

	FETCH NEXT FROM ACCURS INTO @activechecklistid
	WHILE @@FETCH_STATUS = 0 BEGIN
		
		exec QCheck_RemoveFromReport @activechecklistid, @reportid, 50		

		FETCH NEXT FROM ACCURS INTO @activechecklistid
	END
	CLOSE ACCURS
	DEALLOCATE ACCURS



	DECLARE PRCURS CURSOR FOR 	
	select distinct ac.id, ac.instanceid, li.priority 
	from priorities_lists p
	JOIN Priorities_ListItems li
		ON li.ListID = p.ID
	inner join qcheck_activechecklists ac
		on li.activechecklistid = ac.id
	where p.userid = @userid
		and p.IsDefaultList = 1
		and li.priority > 0
	
	
	OPEN PRCURS

	FETCH NEXT FROM PRCURS INTO @activechecklistid, @instanceid, @priority
	WHILE @@FETCH_STATUS = 0 BEGIN
		
		set @NewTaskTypeID= null
		EXEC QCheck_AddInstanceTaskType @InstanceID, @tasktype, @priority, @NewTaskTypeID OUTPUT
		
		FETCH NEXT FROM PRCURS INTO @activechecklistid, @instanceid, @priority
	END
	CLOSE PRCURS
	DEALLOCATE PRCURS

	update qstatus_report set isdirty = 1
	where id = @reportid

END
GO

/****** Object:  StoredProcedure [dbo].[Util_GradeTest]    Script Date: 5/13/2024 4:19:37 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[Util_GradeTest] (
--DECLARE
	@TesterGroupID INT,-- = 436,
	@TestDate DATETIME-- = '2024-02-15'
) AS
BEGIN

	DECLARE @RawScore FLOAT = 0,
			@TesterUserID INT,
			@Username VARCHAR(50),
			@Fullname varchar(100),
			@TesterReportID INT,
			@Count INT,
			@TestGraders INT,
			@TestAssignee INT,
			@Prefix varchar(5)

	--TODO: this is much better handled using an app setting, but whatev
	SELECT @Prefix = LEFT(DB_NAME() COLLATE Latin1_General_BIN, 5)
	DECLARE @done bit = 0

	WHILE @done = 0 AND LEN(@Prefix) > 0
	BEGIN
		IF NOT UNICODE(RIGHT(@Prefix, 1)) BETWEEN 65 AND 90
			SET @Prefix = LEFT(@Prefix, LEN(@Prefix) - 1)
		ELSE SET @done = 1
	END
	--Take off the first character of the second term, either a "P" or "T"
	SET @Prefix = LEFT(@Prefix, LEN(@Prefix) - 1)
	
	--SELECT @Prefix

	SELECT 
		@TesterUserID = u.ID,
		@Username = u.ShortName,
		@Fullname = u.fullname,
		@TesterReportID = r.ID
	FROM 
		QCheck_Users u
		INNER JOIN QCheck_GroupMembership gm
			ON u.ID = gm.UserID
		INNER JOIN QCheck_Groups g
			ON gm.GroupID = g.ID
		INNER JOIN QStatus_Report r
			ON u.FullName = r.Name
			AND r.IsDeleted = 0
	WHERE 
		g.ID = @TesterGroupID
		AND u.IsDeleted = 0
		AND g.SingleMemberGroup = 1
		AND u.FullName = g.Name

	--SELECT 
	--	@TesterGroupID TesterGroupID,
	--	@TesterUserID TesterUserID,
	--	@Username Username,
	--	@Fullname Fullname,
	--	@TesterReportID TesterReportID,
	--	@TestDate TestDate
		

	declare 
		@checklistcount int, 
		@itemcount int, 
		@reportcount int, 
		@sectioncount int, 
		@prioritiescount int, 
		@commentscount int, 
		@groupscount int

	--select *
	--from qcheck_checklists 
	--where owner = @testerUserID
	--and CreateDate > @TestDate
	--and name like @Prefix + '%test%'

	select @checklistcount = isnull(count(id), 0) 
	from qcheck_checklists 
	where owner = @testerUserID
		and CreateDate > @TestDate
		and name like @Prefix + '%test%'

	--select @checklistcount checklistcount

	if @checklistcount > 0 set @checklistcount = @checklistcount + 1
	if @checklistcount > 14 set @checklistcount = 14

	--select *
	--from qcheck_checklists c
	--	inner join qcheck_items i
	--		on i.checklistid = c.id
	--where c.owner = @testerUserID
	--	and c.CreateDate > @TestDate
	--	and c.name like @Prefix + '%test%5%'

	select @itemcount = isnull(count(i.id), 0) 
	from qcheck_checklists c
		inner join qcheck_items i
			on i.checklistid = c.id
	where c.owner = @testerUserID
		and c.CreateDate > @TestDate
		and c.name like @Prefix + '%test%5%'

	--select @itemcount itemcount

	--if @itemcount > 0 set @itemcount = @itemcount + 2

	if @itemcount > 8 set @itemcount = 8

	--Making sure there are 4 types of checklist items
	IF (
		SELECT COUNT(DISTINCT ItemTypeID) from qcheck_checklists c
			inner join qcheck_items i
				on i.checklistid = c.id
		where c.owner = @testerUserID
			AND c.CreateDate > @TestDate
			AND c.name like @Prefix + '%test%5%'			
	) = 4
		set @itemcount = @itemcount + 1

	--Specifically looking for URL added to "Step 2"
	IF EXISTS (
		SELECT 'Y' from qcheck_checklists c
			inner join qcheck_items i
				on i.checklistid = c.id
		where c.owner = @testerUserID
			AND c.CreateDate > @TestDate
			AND c.name like @Prefix + '%test%5%'
			AND i.Text = 'Step 2'
			AND i.URL LIKE 'http%google%com%'
	)
		set @itemcount = @itemcount + 1

	IF (
		select COUNT(*) from QCheck_ActiveAssignments aa
			JOIN QCheck_ActiveChecklists ac 
				ON ac.ID = aa.ActiveChecklistID
			JOIN QCheck_ChecklistInstances ci 
				ON ci.ID = ac.InstanceID
			JOIN QCheck_Checklists c 
				ON c.ID = ci.ChecklistID 
		WHERE c.owner = @testerUserID
			AND c.CreateDate > @TestDate
			AND c.name like @Prefix + '%test%6'
	) = 2
		set @itemcount = @itemcount + 1

	--select *  
	--from qstatus_report r
	--	inner join qstatus_groupreport gr
	--		on r.id = gr.reportid
	--		AND gr.AsOf > @TestDate
	--	inner join qcheck_groupmembership gm
	--		on gm.groupid = gr.groupid
	--			and gm.userid = @testerUserID
	--			and r.name like '%' + @Prefix + '%proces%report%'

	SET @reportcount = 0

	select @reportcount = @reportcount + isnull(count(r.id), 0)  
	from qstatus_report r
		inner join qstatus_groupreport gr
			on r.id = gr.reportid
			AND gr.AsOf > @TestDate
		inner join qcheck_groupmembership gm
			on gm.groupid = gr.groupid
				and gm.userid = @testerUserID
				and r.name like '%' + @Prefix + '%process%report'
		WHERE r.IsDeleted = 0

	select @reportcount = @reportcount + isnull(count(r.id), 0)  
	from qstatus_report r
		inner join qstatus_groupreport gr
			on r.id = gr.reportid
			AND gr.AsOf > @TestDate
		inner join qcheck_groupmembership gm
			on gm.groupid = gr.groupid
				and gm.userid = @testerUserID
				and r.name like '%' + @Prefix + '%process%report%2'
		WHERE r.IsDeleted = 0

	select @reportcount = @reportcount + isnull(count(r.id), 0)  
	from qstatus_report r
		inner join qstatus_groupreport gr
			on r.id = gr.reportid
			AND gr.AsOf > @TestDate
		inner join qcheck_groupmembership gm
			on gm.groupid = gr.groupid
				and gm.userid = @testerUserID
				and r.name like '%' + @Prefix + '%process%report%3'
		WHERE r.IsDeleted = 1

	--select @reportcount reportcount
			
	if @reportcount > 3 set @reportcount = 3	

	select @sectioncount = count(tt.id)
	from qstatus_report r
		inner join qstatus_groupreport gr
			on r.id = gr.reportid
		inner join qcheck_groupmembership gm
			on gm.groupid = gr.groupid
				and gm.userid = @testerUserID
				and r.name like '%' + @Prefix + '%process%rep%'
		inner join qstatus_tasktypes tt
			on tt.reportid = r.id
			and tt.description like '%task%'

	if @sectioncount > 3 set @sectioncount = 3

	--select @sectioncount sectioncount

	--select *
	--from prioritylist pl
	--	inner join qcheck_activechecklists ac
	--		on ac.id = pl.activechecklistid
	--	inner join qcheck_checklistinstances ci
	--		on ci.id = ac.instanceid
	--	inner join qcheck_checklists c
	--		on c.id= ci.checklistid
	--		and c.name like @Prefix + '%test%'
	--where userid = @testerUserID

	select @prioritiescount = count(pl.id) 
	from Priorities_ListItems li
		JOIN Priorities_Lists pl 
			ON pl.ID = li.ListID 
			AND pl.IsDefaultList = 1
		inner join qcheck_activechecklists ac
			on ac.id = li.activechecklistid
		inner join qcheck_checklistinstances ci
			on ci.id = ac.instanceid
		inner join qcheck_checklists c
			on c.id= ci.checklistid
			and c.name like @Prefix + '%test%'
	where userid = @testerUserID

	--select @prioritiescount prioritiescount

	if @prioritiescount > 10 set @prioritiescount = 10

	--select *
	--from qstatus_comments comm
	--	inner join qcheck_activechecklists ac
	--		on ac.id = comm.foreignkeyid 
	--		and comm.specialtask = 0
	--		and comm.userid = @testerUserID
	--	inner join qcheck_checklistinstances ci
	--		on ci.id = ac.instanceid
	--	inner join qcheck_checklists c
	--		on c.id= ci.checklistid
	--		and c.name like @Prefix + '%test%'
	--		and c.owner = @testerUserID
	--		and c.CreateDate > @TestDate

	select @commentscount = count(c.id) 
	from qstatus_comments comm
		inner join qcheck_activechecklists ac
			on ac.id = comm.foreignkeyid 
			and comm.specialtask = 0
			and comm.userid = @testerUserID
		inner join qcheck_checklistinstances ci
			on ci.id = ac.instanceid
		inner join qcheck_checklists c
			on c.id= ci.checklistid
			and c.name like @Prefix + '%test%'
			and c.owner = @testerUserID
			and c.CreateDate > @TestDate

	--select @commentscount commentscount
		
	if @commentscount > 0 set @commentscount = @commentscount
	if @commentscount > 5 set @commentscount = 5

	select @groupscount = count(id) from qcheck_groups
	where owner = @testerUserID
	and name like '%' + @Prefix + '%test%'

	--select @groupscount groupscount

	if @groupscount > 1 set @groupscount = 1

	--SELECT 
	--	sectioncount = @sectioncount,
	--	reportcount = @reportcount,
	--	itemcount = @itemcount,
	--	checklistcount = @checklistcount,
	--	prioritiescount = @prioritiescount,
	--	commentscount = @commentscount,
	--	groupscount = @groupscount

	--New "Written Section" - worth a max of 8 points with opportunity for makeup credit
	DECLARE @writtenSection int = 0
	
	--"Total Tasks" = 12 (*could* be 13 if within two weeks of a calendar quarter - no points off for that)
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Total Tasks% 12' 
				OR name like @Prefix + 'Process Total Tasks% 13')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Calendar Tasks" = 10
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Calendar Tasks% 10')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Controlled Tasks" = 4
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Controlled Tasks% 4')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Report Tasks" = 3
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Report Tasks% 3')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Priority Tasks" = 4
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Priority Tasks% 4')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Change Requests" = 3
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Change Requests% 3')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Timeline Tasks" = 0
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Timeline Tasks% 0')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Process Group - Sample Process"
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Group%Sample%')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Process Search - Choose AND Logic if..."
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Search%Choose AND logic%')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Process Help - Every task needs to be assigned..."
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Help%Every task needs to be assigned%')
	) = 1
		SET @writtenSection = @writtenSection + 1

	if @writtenSection > 9 set @writtenSection = 9

	SELECT @RawScore  = 2 * (@sectioncount + @reportcount + @itemcount + @checklistcount + @prioritiescount + @commentscount) + @groupscount + @writtenSection

	insert into Grading_QProcessTests (employee, grade, gradeddt)
	values (@Fullname,@RawScore, getdate());

	select @RawScore AS Score

END


---------------------------------------------------------------------------------
-- BOOKMARK - EOD 2024-05-17
---------------------------------------------------------------------------------

/****** Object:  StoredProcedure [dbo].[Util_GradeTest_Breakdown]    Script Date: 5/13/2024 4:20:53 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[Util_GradeTest_Breakdown] (
--DECLARE
	@TesterGroupID INT,-- = 352,
	@TestDate DATETIME-- = '2024-02-16'
) AS
BEGIN

	DECLARE @RawScore FLOAT = 0,
			@TesterUserID INT,
			@Username VARCHAR(50),
			@Fullname varchar(100),
			@TesterReportID INT,
			@Count INT,
			@TestGraders INT,
			@TestAssignee INT,
			@Prefix varchar(5)

	--TODO: this is much better handled using an app setting, but whatev
	SELECT @Prefix = LEFT(DB_NAME() COLLATE Latin1_General_BIN, 5)
	DECLARE @done bit = 0

	WHILE @done = 0 AND LEN(@Prefix) > 0
	BEGIN
		IF NOT UNICODE(RIGHT(@Prefix, 1)) BETWEEN 65 AND 90
			SET @Prefix = LEFT(@Prefix, LEN(@Prefix) - 1)
		ELSE SET @done = 1
	END
	--Take off the first character of the second term, either a "P" or "T"
	SET @Prefix = LEFT(@Prefix, LEN(@Prefix) - 1)
	
	--SELECT @Prefix

	SELECT 
		@TesterUserID = u.ID,
		@Username = u.ShortName,
		@Fullname = u.fullname,
		@TesterReportID = r.ID
	FROM 
		QCheck_Users u
		INNER JOIN QCheck_GroupMembership gm
			ON u.ID = gm.UserID
		INNER JOIN QCheck_Groups g
			ON gm.GroupID = g.ID
		INNER JOIN QStatus_Report r
			ON u.FullName = r.Name
			AND r.IsDeleted = 0
	WHERE 
		g.ID = @TesterGroupID
		AND u.IsDeleted = 0
		AND g.SingleMemberGroup = 1
		AND u.FullName = g.Name

	SELECT @Prefix Prefix,
		@TesterGroupID TesterGroupID,
		@TesterUserID TesterUserID,
		@Username Username,
		@Fullname Fullname,
		@TesterReportID TesterReportID,
		@TestDate TestDate
		

	declare 
		@checklistcount int, 
		@itemcount int, 
		@reportcount int, 
		@sectioncount int, 
		@prioritiescount int, 
		@commentscount int, 
		@groupscount int

	select *
	from qcheck_checklists 
	where owner = @testerUserID
		and CreateDate > @TestDate
		and name like @Prefix + '%test%'

	select @checklistcount = isnull(count(id), 0) 
	from qcheck_checklists 
	where owner = @testerUserID
		and CreateDate > @TestDate
		and name like @Prefix + '%test%'

	--select @checklistcount checklistcount

	if @checklistcount > 0 set @checklistcount = @checklistcount + 1
	if @checklistcount > 14 set @checklistcount = 14

	select *
	from qcheck_checklists c
		inner join qcheck_items i
			on i.checklistid = c.id
	where c.owner = @testerUserID
		and c.CreateDate > @TestDate
		and c.name like @Prefix + '%test%5%'

	select @itemcount = isnull(count(i.id), 0) 
	from qcheck_checklists c
		inner join qcheck_items i
			on i.checklistid = c.id
	where c.owner = @testerUserID
		and c.CreateDate > @TestDate
		and c.name like @Prefix + '%test%5%'

	--select @itemcount itemcount

	--if @itemcount > 0 set @itemcount = @itemcount + 2

	if @itemcount > 8 set @itemcount = 8

	--Making sure there are 4 types of checklist items
	IF (
		SELECT COUNT(DISTINCT ItemTypeID) from qcheck_checklists c
			inner join qcheck_items i
				on i.checklistid = c.id
		where c.owner = @testerUserID
			AND c.CreateDate > @TestDate
			AND c.name like @Prefix + '%test%5%'			
	) = 4
		set @itemcount = @itemcount + 1

	--Specifically looking for URL added to "Step 2"
	IF EXISTS (
		SELECT 'Y' from qcheck_checklists c
			inner join qcheck_items i
				on i.checklistid = c.id
		where c.owner = @testerUserID
			AND c.CreateDate > @TestDate
			AND c.name like @Prefix + '%test%5%'
			AND i.Text = 'Step 2'
			AND i.URL LIKE 'http%google%com%'
	)
		set @itemcount = @itemcount + 1	

	--Looking for two assignments on *Process Test 6
	IF (
		select COUNT(*) from QCheck_ActiveAssignments aa
			JOIN QCheck_ActiveChecklists ac 
				ON ac.ID = aa.ActiveChecklistID
			JOIN QCheck_ChecklistInstances ci 
				ON ci.ID = ac.InstanceID
			JOIN QCheck_Checklists c 
				ON c.ID = ci.ChecklistID 
		WHERE c.owner = @testerUserID
			AND c.CreateDate > @TestDate
			AND c.name like @Prefix + '%test%6'
	) = 2
		set @itemcount = @itemcount + 1

	set @itemcount = CASE WHEN @itemcount > 10 THEN 10 ELSE @itemcount END

	select *  
	from qstatus_report r
		inner join qstatus_groupreport gr
			on r.id = gr.reportid
			AND gr.AsOf > @TestDate
		inner join qcheck_groupmembership gm
			on gm.groupid = gr.groupid
				and gm.userid = @testerUserID
				and r.name like '%' + @Prefix + '%process%report%'

	SET @reportcount = 0

	select @reportcount = @reportcount + isnull(count(r.id), 0)  
	from qstatus_report r
		inner join qstatus_groupreport gr
			on r.id = gr.reportid
			AND gr.AsOf > @TestDate
		inner join qcheck_groupmembership gm
			on gm.groupid = gr.groupid
				and gm.userid = @testerUserID
				and r.name like '%' + @Prefix + '%process%report'
		WHERE r.IsDeleted = 0

	select @reportcount = @reportcount + isnull(count(r.id), 0)  
	from qstatus_report r
		inner join qstatus_groupreport gr
			on r.id = gr.reportid
			AND gr.AsOf > @TestDate
		inner join qcheck_groupmembership gm
			on gm.groupid = gr.groupid
				and gm.userid = @testerUserID
				and r.name like '%' + @Prefix + '%process%report%2'
		WHERE r.IsDeleted = 0

	select @reportcount = @reportcount + isnull(count(r.id), 0)  
	from qstatus_report r
		inner join qstatus_groupreport gr
			on r.id = gr.reportid
			AND gr.AsOf > @TestDate
		inner join qcheck_groupmembership gm
			on gm.groupid = gr.groupid
				and gm.userid = @testerUserID
				and r.name like '%' + @Prefix + '%process%report%3'
		WHERE r.IsDeleted = 1

	--select @reportcount reportcount
			
	if @reportcount > 3 set @reportcount = 3	

	select @sectioncount = count(tt.id)
	from qstatus_report r
		inner join qstatus_groupreport gr
			on r.id = gr.reportid
		inner join qcheck_groupmembership gm
			on gm.groupid = gr.groupid
				and gm.userid = @testerUserID
				and r.name like '%' + @Prefix + '%process%rep%'
		inner join qstatus_tasktypes tt
			on tt.reportid = r.id
			and tt.description like '%task%'

	if @sectioncount > 3 set @sectioncount = 3

	--select @sectioncount sectioncount

	select *
	from Priorities_ListItems li
		JOIN Priorities_Lists pl 
			ON pl.ID = li.ListID 
			AND pl.IsDefaultList = 1
		inner join qcheck_activechecklists ac
			on ac.id = li.activechecklistid
		inner join qcheck_checklistinstances ci
			on ci.id = ac.instanceid
		inner join qcheck_checklists c
			on c.id= ci.checklistid
			and c.name like @Prefix + '%test%'
	where userid = @testerUserID

	select @prioritiescount = count(pl.id) 
	from Priorities_ListItems li
		JOIN Priorities_Lists pl 
			ON pl.ID = li.ListID 
			AND pl.IsDefaultList = 1
		inner join qcheck_activechecklists ac
			on ac.id = li.activechecklistid
		inner join qcheck_checklistinstances ci
			on ci.id = ac.instanceid
		inner join qcheck_checklists c
			on c.id= ci.checklistid
			and c.name like @Prefix + '%test%'
	where userid = @testerUserID

	--select @prioritiescount prioritiescount

	if @prioritiescount >= 9 set @prioritiescount = 10

	select *
	from qstatus_comments comm
		inner join qcheck_activechecklists ac
			on ac.id = comm.foreignkeyid 
			and comm.specialtask = 0
			and comm.userid = @testerUserID
		inner join qcheck_checklistinstances ci
			on ci.id = ac.instanceid
		inner join qcheck_checklists c
			on c.id= ci.checklistid
			and c.name like @Prefix + '%test%'
			and c.owner = @testerUserID
			and c.CreateDate > @TestDate

	select @commentscount = count(c.id) 
	from qstatus_comments comm
		inner join qcheck_activechecklists ac
			on ac.id = comm.foreignkeyid 
			and comm.specialtask = 0
			and comm.userid = @testerUserID
		inner join qcheck_checklistinstances ci
			on ci.id = ac.instanceid
		inner join qcheck_checklists c
			on c.id= ci.checklistid
			and c.name like @Prefix + '%test%'
			and c.owner = @testerUserID
			and c.CreateDate > @TestDate

	--select @commentscount commentscount
		
	if @commentscount > 0 set @commentscount = @commentscount
	if @commentscount > 5 set @commentscount = 5

	select @groupscount = count(id) from qcheck_groups
	where owner = @testerUserID
	and name like '%' + @Prefix + '%test%'

	--select @groupscount groupscount

	if @groupscount > 1 set @groupscount = 1

	--SELECT 
	--	sectioncount = @sectioncount,
	--	reportcount = @reportcount,
	--	itemcount = @itemcount,
	--	checklistcount = @checklistcount,
	--	prioritiescount = @prioritiescount,
	--	commentscount = @commentscount,
	--	groupscount = @groupscount

	--New "Written Section" - worth a max of 9 points with opportunity for makeup credit
	DECLARE @writtenSection int = 0

	SELECT *, 
		CASE 
			WHEN name LIKE '%Total Tasks%' then 12
			WHEN name LIKE '%Calendar Tasks%' then 10
			WHEN name LIKE '%Controlled%' then 4
			WHEN name LIKE '%Report%' then 3
			WHEN name LIKE '%Priority%' then 4
			WHEN name LIKE '%Change Requests%' then 3
			WHEN name LIKE '%Timeline%' then 0
		END Expected
	from qcheck_checklists 
	where owner = @testerUserID
		and CreateDate > @TestDate
		and (name like @Prefix + '%Process % Tasks%'
		OR name like @Prefix + '%Process Change Requests%'
		OR name like @Prefix + '%Process Group%'
		OR name like @Prefix + '%Process Search%'
		OR name like @Prefix + '%Process Help%')
	
	--"Total Tasks" = 12 (*could* be 13 if within two weeks of a calendar quarter - no points off for that)
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Total Tasks% 12' 
				OR name like @Prefix + 'Process Total Tasks% 13')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Calendar Tasks" = 10
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Calendar Tasks% 10')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Controlled Tasks" = 4
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Controlled Tasks% 4')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Report Tasks" = 3
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Report Tasks% 3')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Priority Tasks" = 4
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Priority Tasks% 4')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Change Requests" = 3
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Change Requests% 3')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Timeline Tasks" = 0
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Timeline Tasks% 0')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Process Group - Sample Process"
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Group%Sample%')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Process Search - Choose AND Logic if..."
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Search%Choose AND logic%')
	) = 1
		SET @writtenSection = @writtenSection + 1

	--"Process Help - Every task needs to be assigned..."
	IF(SELECT isnull(count(id), 0) 
		from qcheck_checklists 
		where owner = @testerUserID
			and CreateDate > @TestDate
			and (name like @Prefix + 'Process Help%Every task needs to be assigned%')
	) = 1
		SET @writtenSection = @writtenSection + 1

	if @writtenSection > 9 set @writtenSection = 9

	SELECT 
		"Checklists (14) x2" = @checklistcount,
		"Items (10) x2" = @itemcount,
		"Reports (3) x2" = @reportcount,
		"Sections (3) x2" = @sectioncount,
		"Priorities (10) x2" = @prioritiescount,
		"Comments (5) x2" = @commentscount,
		"Groups (1)" = @groupscount,
		"Written (9)" = @writtensection

	SELECT @RawScore  = 2 * (@sectioncount + @reportcount + @itemcount + @checklistcount + @prioritiescount + @commentscount) + @groupscount + @writtenSection

	--insert into Grading_QProcessTests (employee, grade, gradeddt)
	--values (@Fullname,@RawScore, getdate());

	select @RawScore AS Score

END

/****** Object:  StoredProcedure [dbo].[PriorityListSet_GetAvailableUsers]    Script Date: 5/13/2024 4:44:26 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER proc [dbo].[PriorityListSet_GetAvailableUsers]
	@SetID int,
	@UserID int
AS
BEGIN
	
	SELECT l.id, l.Name + CASE WHEN l.Name <> u.FullName THEN ' (' + u.FullName + ')' ELSE '' END FullName
	FROM Priorities_Lists l
	JOIN QCheck_Users u ON u.ID = l.UserID
	WHERE (
		(l.UserID in
			(
				select gm2.userid from 
				qstatus_supervisors s
				inner join qstatus_report r
				on r.id = s.reportid
				--and r.isdeleted = 0
				inner join qcheck_groups g
				on g.id = s.supervisorgroupid
				inner join qcheck_groupmembership gm
				on gm.groupid = g.id
				and gm.userid = @userid
				inner join qstatus_groupreport gr
				on gr.reportid = r.id
				and gr.defaultreport = 1
				inner join qcheck_groups g2
				on g2.id = gr.groupid
				inner join qcheck_groupmembership gm2
				on gm2.groupid = g2.id
				--where s.interestedparty = 0 -- change per GPR 1/11/2022
		
				union
				
				select userid from QStatus_UserSupervisors
					where SupervisorUserID = @userid
			)
			and @setid not in
				(select id from Priorities_ListSets
					where PersonalSet = 1)
			and u.IsDeleted = 0
		)
		OR 
		(
			l.UserID = @UserID
			AND
			(
				l.UserID in (SELECT UserID from Priorities_ListSets
					where id = @setid)
				OR 
				@setid not in
				(select id from Priorities_ListSets
				where PersonalSet = 1)
			)
			and u.IsDeleted = 0
		)
		OR 
		(
			l.UserID in
			(
				select u2.id from qcheck_users u1
				inner join qcheck_users u2
					on u1.email = u2.email
				where u1.id = @UserID
			)
			and u.IsDeleted = 0
		)
		OR
		(
			@UserID in (select GPRUserID from Qcheck_AppSettings where [ID] = 1)
			and u.IsDeleted = 0
		)
		OR
		(
			l.UserID in (select userid from Priorities_List_CrossReference where CrossReferenceID = @UserID)
			--allowing deleted users here
		)
	)
	AND l.ID not in
	(
		select ListID from Priorities_ListSetLists
		where SetID = @setid
	)
	
	order by 2
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityListSet_GetEmails]    Script Date: 5/13/2024 4:45:01 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   proc [dbo].[PriorityListSet_GetEmails]
	@SetID int,
	@UserID int
AS

	select fullname, email, case when id = @UserID then 1 else 0 end as LoggedInUser from
	qcheck_users
	where id in
	(
		
		select UserID from Priorities_ListSets
		where ID = @SetID
		
		UNION ALL
		
		SELECT @UserID
		
		UNION ALL
		
		SELECT UserID FROM Priorities_ListSetLists lsl
		JOIN Priorities_Lists l ON lsl.ListID = l.ID
		WHERE SetID = @SETID
		
		UNION ALL
		
		select gm2.userid from qstatus_report r
		inner join qstatus_groupreport gr
		on gr.reportid = r.id
		and gr.defaultreport = 1
		inner join qcheck_groups g
		on g.id = gr.groupid
		inner join qcheck_groupmembership gm
		on gm.groupid = g.id
		and gm.userID = @UserID
		inner join qstatus_supervisors s
		on r.id = s.reportid
		and s.interestedparty = 0
		--and r.isdeleted = 0
		inner join qcheck_groups g2
		on g2.id = s.supervisorgroupid
		inner join qcheck_groupmembership gm2
		on gm2.groupid = g2.id

		UNION ALL  -- add in supervisors of the cross reference
		
		select gm2.userid from qstatus_report r
		inner join qstatus_groupreport gr
		on gr.reportid = r.id
		and gr.defaultreport = 1
		inner join qcheck_groups g
		on g.id = gr.groupid
		inner join Priorities_List_CrossReference cr
		on cr.crossreferenceid = @UserID
		inner join Priorities_ListSets pls
		on pls.userid = cr.userid
		and pls.id = @setID
		inner join qcheck_groupmembership gm
		on gm.groupid = g.id
		and gm.userID = cr.userid
		inner join qstatus_supervisors s
		on r.id = s.reportid
		and s.interestedparty = 0
		--and r.isdeleted = 0
		inner join qcheck_groups g2
		on g2.id = s.supervisorgroupid
		inner join qcheck_groupmembership gm2
		on gm2.groupid = g2.id

	)
	and id not in (select userid from Priorities_List_CrossReference)
	and isdeleted = 0
	order by 1

GO

/****** Object:  View [dbo].[QCheck_SelfManaged]    Script Date: 5/13/2024 4:45:56 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER   view [dbo].[QCheck_SelfManaged]
AS

	select ci.ID from QCheck_ChecklistInstances ci
		inner join qcheck_checklists c
			on ci.checklistid = c.id
			and ci.IsDeleted = 0
			and c.IsDeleted = 0
		inner join QCheck_ChecklistManagers m
			on m.ChecklistID = c.id
			and m.IsDeleted = 0
		inner join qcheck_groups g1
			on g1.ID = m.ManagerGroupID
		inner join QCheck_GroupMembership gm1
			on gm1.GroupID = g1.id
		inner join qcheck_assignments a
			on a.InstanceID = ci.id
			and a.IsDeleted = 0
		inner join qcheck_groups g2
			on g2.id = a.GroupID
		inner join QCheck_GroupMembership gm2
			on gm2.groupid = g2.id
		left outer join Priorities_List_CrossReference cr
			on cr.userid = gm2.userid
			or cr.userid = gm1.userid
		inner join qcheck_users u1
			on (
					(u1.id = gm1.userid and u1.id = gm2.userid) --same user
					or
					(u1.id = gm1.userid and u1.id = cr.CrossReferenceID and cr.userid = gm2.userid) --cross reference forward
					or
					(u1.id = gm2.userid and u1.id = cr.CrossReferenceID and cr.userid = gm1.userid) --cross reference backards
			)
			and u1.IsDeleted = 0
GO

/****** Object:  StoredProcedure [dbo].[QStatus_GetDefaultReportID]    Script Date: 5/13/2024 4:46:38 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[QStatus_GetDefaultReportID] (
	@UserID INT = 24,
	@ReportID INT OUTPUT
) AS

BEGIN

	SELECT 
		@ReportID = r.ID
	FROM 
		QCheck_Users U
		LEFT OUTER JOIN Priorities_List_CrossReference p
			ON u.ID = p.UserID
		INNER JOIN QCheck_GroupMembership gm
			ON gm.UserID = isnull(p.CrossReferenceID, u.ID)
		INNER JOIN QCheck_Groups g
			ON gm.GroupID = g.ID
			AND g.SingleMemberGroup = 1
		INNER JOIN QStatus_GroupReport gr
			ON g.ID = gr.GroupID
			AND gr.DefaultReport = 1
		INNER JOIN QStatus_Report r
			ON gr.ReportID = r.ID
			AND r.IsDeleted = 0
	WHERE
		U.ID = @UserID

	SELECT @ReportID = ISNULL(@ReportID, -1)
		
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_GetInfo]    Script Date: 5/13/2024 4:48:14 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[PriorityList_GetInfo] (
	@SetID INT,
	@UserID INT OUTPUT,
	@SetName VARCHAR(50) OUTPUT
) AS

BEGIN

	SELECT
		@UserID = UserID,
		@SetName = Name
	FROM
		Priorities_ListSets
	WHERE
		ID = @SetID

END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_GetSets]    Script Date: 5/13/2024 4:48:50 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER proc [dbo].[PriorityList_GetSets]
	@UserID int
	,@IsPerson int =-1
AS
BEGIN
	
	EXEC PriorityList_Init @UserID
	EXEC PriorityList_InitSupervisor @UserID
	
	DECLARE @GPR bit = 0
	SELECT @GPR = 1 where @UserID in (select GPRUserID from Qcheck_AppSettings where [ID] = 1)

	DECLARE @PreferenceValue varchar(50)

	EXEC QStatus_GetPreference @UserID, 0, 'LastPrioritySet', @PreferenceValue output

	declare @employees table(id int)

	insert into @employees
		select gm2.userid from 
		qstatus_supervisors s
		inner join qstatus_report r
		on r.id = s.reportid
		--and r.isdeleted = 0
		inner join qcheck_groups g
		on g.id = s.supervisorgroupid
		inner join qcheck_groupmembership gm
		on gm.groupid = g.id
		and gm.userid = @UserID
		inner join qstatus_groupreport gr
		on gr.reportid = r.id
		and gr.defaultreport = 1
		inner join qcheck_groups g2
		on g2.id = gr.groupid
		inner join qcheck_groupmembership gm2
		on gm2.groupid = g2.id
		--where s.interestedparty = 0 -- change per GPR 1/11/2022
		
		union
		
		select userid from QStatus_UserSupervisors
			where SupervisorUserID = @userid	

	SELECT p.[ID], 
		CASE WHEN p.UserID = @UserID or p.personalset= 1 THEN
			p.[Name]
		ELSE
			p.[Name] + ' (' + isnull(u.fullname, '') + ') '
		END as [Name],
		CASE WHEN CAST(p.ID as varchar(50)) = @PreferenceValue THEN
			1
		ELSE
			0
		END as LastPrioritySet
	FROM Priorities_ListSets p
	INNER JOIN QCheck_Users u
		on u.id = p.userID  and p.PersonalSet>@IsPerson
	WHERE p.UserID = @UserID
	OR p.UserID in (select id from @employees
					union all
					select id from qcheck_users where isdeleted = 0 and @GPR = 1 --GPR sees all
					)
   
	ORDER BY Case when p.UserID = @UserID and p.personalset= 1 then 1
		      when p.UserID = @UserID then 2
		      when p.personalset = 0 then 3
			else 4
		end asc,
		p.name,
		p.updateddate desc

END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_Init]    Script Date: 5/13/2024 4:49:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   proc [dbo].[PriorityList_Init]
	@UserID int
AS
BEGIN
	
	DECLARE @Count int
	DECLARE @Name varchar(100)
	DECLARE @SetID int

	SET @Count = 0

	SELECT @Count = count([id])
	FROM Priorities_ListSets
	WHERE UserID = @UserID

	IF @Count = 0
	BEGIN
		
		SELECT @Name = Fullname
		FROM QCheck_Users
		WHERE ID = @UserID

		EXEC PriorityList_CreateUpdate @Name = @Name, @UserID = @UserID, @IsDefaultList = 1
	END
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_InitSupervisor]    Script Date: 5/13/2024 4:49:19 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER     proc [dbo].[PriorityList_InitSupervisor]
	@UserID int
AS
BEGIN
	
	DECLARE @UserID_list TABLE
	(
		ID int IDENTITY(1,1),
		UserID int
	)

	DECLARE @rowcount int, @i int, @SubUserID int

	INSERT INTO @UserID_list
	select gm2.userid from 
	qstatus_supervisors s
	inner join qstatus_report r
	on r.id = s.reportid
	--and r.isdeleted = 0
	inner join qcheck_groups g
	on g.id = s.supervisorgroupid
	inner join qcheck_groupmembership gm
	on gm.groupid = g.id
	and gm.userid = @UserID
	inner join qstatus_groupreport gr
	on gr.reportid = r.id
	and gr.defaultreport = 1
	inner join qcheck_groups g2
	on g2.id = gr.groupid
	inner join qcheck_groupmembership gm2
	on gm2.groupid = g2.id
	where s.interestedparty = 0
	and gm2.userid not in 
		(select userid from priorities_listsets
		where personalset = 1)

	SELECT @rowcount = @@ROWCOUNT
	SELECT @i = 1
	
	WHILE @i <= @rowcount
	BEGIN
		SELECT @SubUserID = UserID
		FROM @UserID_list
		WHERE [ID] = @i
		
		EXEC PriorityList_Init @SubUserID

		SET @i = @i + 1
	END
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityListSet_Add]    Script Date: 5/13/2024 4:49:35 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER  proc [dbo].[PriorityListSet_Add]
	@UserID int,
	@Name varchar(100),
	@PersonalSet bit = 0,
	@SetID int output
AS
BEGIN
	
	INSERT INTO Priorities_ListSets (Name, UserID, PersonalSet)
	SELECT @Name, @UserID, @PersonalSet

	SELECT @SetID = @@Identity

END
GO

/****** Object:  StoredProcedure [dbo].[PriorityListSet_Delete]    Script Date: 5/13/2024 4:49:48 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER proc [dbo].[PriorityListSet_Delete]
	@SetID int output
AS
BEGIN

	DECLARE @IsPersonalSet bit = 0, @IsDefaultSet bit = 0

	SELECT @IsPersonalSet = PersonalSet
	FROM Priorities_ListSets pls	
	WHERE pls.ID = @SetID

	IF @IsPersonalSet = 1
		SELECT @IsDefaultSet = 1
		FROM Priorities_ListSetLists plsl
		JOIN Priorities_Lists pl
			ON pl.ID = plsl.ListID
			AND pl.IsDefaultList = 1
		WHERE plsl.SetID = @SetID			

	--NEVER delete the personal set for the user's default list
	IF @IsDefaultSet = 1 RETURN
	
	--The list being deleted is usually set as the default for the deleting user, which causes errors;
	--change it to the user's personal priority list before deleting
	UPDATE pref
	SET PreferenceValue = pers.ID
	FROM QStatus_Preferences pref
		JOIN Priorities_ListSets toDel 
			ON CAST(toDel.ID as varchar(20)) = pref.PreferenceValue
		JOIN Priorities_ListSets pers 
			ON pers.UserID = toDel.UserID 
			AND pers.PersonalSet = 1
		JOIN Priorities_ListSetLists plsl
			ON plsl.SetID = pers.ID
		JOIN Priorities_Lists pl
			ON pl.ID = plsl.ListID
			AND pl.IsDefaultList = 1
	WHERE pref.PreferenceType = 'LastPrioritySet'
		AND pref.PreferenceValue = @SetID

	DELETE pls 
	FROM Priorities_ListSets pls	
	WHERE pls.ID = @SetID			

	IF @@Rowcount = 1
	BEGIN

		IF @IsPersonalSet = 1  -- delete the list it was created for as well
		BEGIN
			DECLARE @ListID int
			
			SELECT @ListID = pl.ID
			FROM Priorities_Lists pl
			JOIN Priorities_ListSetLists plsl
				ON plsl.ListID = pl.ID
				AND plsl.SetID = @SetID
			
			Delete Priorities_ListItems
			FROM Priorities_ListItems pli			
			WHERE pli.ListID = @ListID

			DELETE FROM Priorities_ListSetLists
			WHERE ListID = @ListID

			Delete Priorities_Lists
			FROM Priorities_Lists pl		
			WHERE pl.ID = @ListID
		END

		--Delete all references to lists in the set		
		DELETE FROM Priorities_ListSetLists
		WHERE SetID = @SetID	
	END
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityListSet_GetInfo]    Script Date: 5/13/2024 4:51:51 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER proc [dbo].[PriorityListSet_GetInfo]
	@SetID int,
	@UserID int,
	@persistPrioritySet bit=1
AS
BEGIN
	
	IF (@SetID > 0 and @persistPrioritySet=1) BEGIN
		exec QStatus_AddPreference @UserID, 0, 'LastPrioritySet', @SetID
	END

	SELECT top 1 convert(varchar, p.UpdatedDate, 100) as dt,
		u.fullname,
		p.UserID,
		p.name,
		u.email
	 from Priorities_ListSets p
	inner join qcheck_users u
	on u.id = p.userid
	WHERE (p.[ID] = @SetID or (@setID = 0 and p.userid = @UserID))

	DECLARE @isSingleUserList bit = 0, @isSupervisor bit = 0, @isMyList bit = 0, @IsDefaultList bit = 0	

	SELECT @isSingleUserList = 1 
	FROM 
		Priorities_ListSets 
	WHERE PersonalSet = 1 AND ID = @SetID

	--A list set is the "default" if it's a single user list (personal set) 
	--and its list is the user's default list
	SELECT @isDefaultList = 1 
	FROM 
		Priorities_ListSets ls
	JOIN Priorities_ListSetLists lsl ON lsl.SetID = ls.ID
	JOIN Priorities_Lists l ON l.ID = lsl.ListID AND l.IsDefaultList = 1
	WHERE ls.PersonalSet = 1 AND ls.ID = @SetID

	select @isSupervisor = 1 from 
	qstatus_supervisors s
	inner join qstatus_report r
	on r.id = s.reportid
	--and r.isdeleted = 0
	inner join qcheck_groups g
	on g.id = s.supervisorgroupid
	inner join qcheck_groupmembership gm
	on gm.groupid = g.id
	and gm.userid = @userid
	inner join qstatus_groupreport gr
	on gr.reportid = r.id
	and gr.defaultreport = 1
	inner join qcheck_groups g2
	on g2.id = gr.groupid
	inner join qcheck_groupmembership gm2
	on gm2.groupid = g2.id
	where s.interestedparty = 0
	
	select @isSupervisor = 1
	from QStatus_SupervisorOverride
	where UserID <> SupervisorID
		and SupervisorID = @userid

	SELECT @isMyList = 1
	FROM Priorities_ListSets
	WHERE UserID = @UserID AND ID = @SetID
	
	/*select @isMyList = 1
    from PriorityListSet s
	inner join qcheck_users u
		on s.userid = u.id
	inner join qcheck_users u2
		on u.email = u2.email
	WHERE u2.id = @UserID AND s.ID = @SetID*/

	declare @dependencies varchar(1000)
	set @dependencies = ''
	
	select @dependencies = @dependencies + '*' + cast(a.setid as varchar(10)) + '*'
	from 
	(
		select distinct u2.setid 
		from Priorities_ListSetLists u1		
		inner join Priorities_ListSetLists u2
			on u2.ListID = u1.ListId
		inner join Priorities_ListSets s
			on u2.setid = s.id
		where u1.setid = @SetID

		union

		select @SetID
	) a

	SELECT @isSingleUserList IsSingleUserList, @isSupervisor IsSupervisor, 
		@isMyList IsMyList, @IsDefaultList IsDefaultList, @dependencies Dependencies

END
GO

/****** Object:  StoredProcedure [dbo].[PriorityListSet_GetPersonalByUser]    Script Date: 5/13/2024 4:52:06 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[PriorityListSet_GetPersonalByUser] (
	@UserID INT
) AS

BEGIN

	SELECT 
		ID,
		Name,
		UserID,
		PersonalSet,
		UpdatedDate
	FROM
		Priorities_ListSets
	WHERE
		UserID = @UserID
		AND PersonalSet = 1
		
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityListSet_Update]    Script Date: 5/13/2024 4:52:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER   proc [dbo].[PriorityListSet_Update]
	@SetID int
AS
BEGIN
	
	--???
	UPDATE Priorities_ListSets
	SET UpdatedDate = getdate()

END
GO

/****** Object:  StoredProcedure [dbo].[QStatus_PriorityListSet_ByReport]    Script Date: 5/13/2024 4:52:44 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[QStatus_PriorityListSet_ByReport] (
	@ReportID INT
) AS

BEGIN

	-- Returns all the named priority list sets that belong to any controller on the status report
	SELECT DISTINCT
		pls.[ID] As PriorityListSetID,
		pls.[Name] As PriorityListName
	FROM 
		QStatus_Report r
		INNER JOIN QStatus_GroupReport gr
			ON r.[ID] = gr.ReportID
		INNER JOIN QCheck_GroupMembership gm
			ON gr.GroupID = gm.GroupID
		INNER JOIN Priorities_ListSets pls
			ON gm.UserID = pls.UserID
	WHERE 
		r.[ID] = @ReportID
	ORDER BY
		pls.[Name]

END

GO

/****** Object:  StoredProcedure [dbo].[GetEmployeePrioritySchedule]    Script Date: 5/13/2024 4:53:13 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[GetEmployeePrioritySchedule] 
	@EmployeeId int = null,
	@UserId int = NULL,
	@ListId int = NULL
As	
BEGIN
	--will eventually transition to use @userId; 
	--@employeeId isn't the actual Employee Tracker Employee ID
	SET @UserId = ISNULL(@userId, @employeeId)

	--ListID can be null; that simply means any of the users' priority lists will meet the schedule requirement
	--IF @ListId IS NULL
	--	SELECT @ListId = ID
	--	FROM Priorities_Lists l
	--	WHERE l.UserID = @userId
	--		AND l.IsDefaultList = 1
				
	SELECT 
		(Select FullName from QCheck_Users where ID=s.SupervisorID) as SupervisorName
		,(Select FullName from QCheck_Users where ID=s.UserID) as EmployeeName
		,[DaysOfWeek]
		,[ReportDay]
		,[TimesOfDay]     
	FROM [dbo].[Priorities_Schedule] s 
	WHERE IsActive=1 
		AND s.UserID = @UserId
		AND ISNULL(s.ListID,0) = ISNULL(@ListId,0)
	ORDER BY EmployeeName, DaysOfWeek	
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityListSet_AddUser]    Script Date: 5/13/2024 4:53:51 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER proc [dbo].[PriorityListSet_AddUser]
	@SetID int,
	@UserID int = null,
	@ListID int = null,
	@Refresh bit = 1
AS
BEGIN

	IF @ListId IS NULL
		SELECT @ListId = ID
		FROM Priorities_Lists l
		WHERE l.UserID = @userId
			AND l.IsDefaultList = 1
	
	UPDATE Priorities_ListSetLists
	SET DisplayOrder = DisplayOrder + 1
	WHERE SetID = @SetID

	INSERT INTO Priorities_ListSetLists 
	SELECT @SetID, @ListID, 1
	WHERE NOT EXISTS (
		Select 1 from Priorities_ListSetLists 
		where setid = @setid and ListID = @ListID
	)

	IF @Refresh = 1
		exec PriorityListSet_RefreshOrder @SetID

END
GO

/****** Object:  StoredProcedure [dbo].[PriorityListSet_AddUsers]    Script Date: 5/31/2024 7:16:20 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO 

CREATE OR ALTER proc [dbo].[PriorityListSet_AddUsers]
	@SetID int,
	@UserIDs varchar(1000) = null,
	@ListIDs varchar(1000) = null
AS
BEGIN

	DECLARE @ListID_list TABLE
	(
		ID int IDENTITY(1,1),
		ListID int
	)
	DECLARE @rowcount int, @i int, @ListID int

	IF @ListIDs IS NULL
	BEGIN
		INSERT INTO @ListID_list
		SELECT l.ID
		FROM (
			SELECT n UserID FROM dbo.Util_fn_List_To_Table(@UserIDs,';')
		) u
		JOIN Priorities_Lists l
			ON l.UserID = u.UserID 
			AND l.IsDefaultList = 1
		where u.UserID is not null
	END
	ELSE
	BEGIN
		INSERT INTO @ListID_list
		SELECT n FROM dbo.Util_fn_List_To_Table(@ListIDs,';')
		where n is not null
	END

	SELECT @rowcount = @@ROWCOUNT
	SELECT @i = 1

	--SELECT * FROM @ListID_list
	
	WHILE @i <= @rowcount
	BEGIN
		SELECT @ListID = ListID
		FROM @ListID_list
		WHERE ID = @i
		
		EXEC PriorityListSet_AddUser @SetID, NULL, @ListID, 0

		SET @i = @i + 1
	END

	exec PriorityListSet_RefreshOrder @SetID

END
GO

/****** Object:  StoredProcedure [dbo].[PriorityListSet_GetUsers]    Script Date: 5/13/2024 4:56:33 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER proc [dbo].[PriorityListSet_GetUsers]
	@SetID int
AS
BEGIN
	
	SELECT l.userid, l.ID ListID, u.FullName, l.Name ListName, p.displayorder, u.email
	FROM Priorities_ListSetLists p
	JOIN Priorities_Lists l
		ON p.ListID = l.ID
	INNER JOIN QCheck_Users u
	ON l.UserID = u.ID
	WHERE p.SetID = @SetID
	ORDER BY DisplayOrder
	
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityListSet_MoveUser]    Script Date: 5/13/2024 4:56:59 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER proc [dbo].[PriorityListSet_MoveUser]
	@SetID int,
	@UserID int = null,
	@ListID int = null,
	@DisplayOrder int
AS
BEGIN
	--Will transition to primarily using list IDs; until then assume the default list for the user
	IF @ListId IS NULL
		SELECT @ListId = ID
		FROM Priorities_Lists l
		WHERE l.UserID = @userId
			AND l.IsDefaultList = 1

	--check current DisplayOrder
	DECLARE @CurrentDisplayOrder int

	SELECT 	@CurrentDisplayOrder = DisplayOrder
	FROM Priorities_ListSetLists
	WHERE ListID = @ListID
	AND SetID = @SetID
	
	IF @DisplayOrder > @CurrentDisplayOrder and @CurrentDisplayOrder > 0 and @DisplayOrder > 0
		UPDATE Priorities_ListSetLists
		SET DisplayOrder = DisplayOrder - 1
		WHERE SetID = @SetID
		AND DisplayOrder > @CurrentDisplayOrder
		AND DisplayOrder <= @DisplayOrder

	IF @DisplayOrder < @CurrentDisplayOrder and @CurrentDisplayOrder > 0 and @DisplayOrder > 0
		UPDATE Priorities_ListSetLists
		SET DisplayOrder = DisplayOrder + 1
		WHERE SetID = @SetID
		AND DisplayOrder >= @DisplayOrder
		AND DisplayOrder < @CurrentDisplayOrder

	UPDATE Priorities_ListSetLists
	SET DisplayOrder = @DisplayOrder
	WHERE ListID = @ListID
	AND SetID = @SetID

	exec PriorityListSet_RefreshOrder @SetID

END
GO

/****** Object:  StoredProcedure [dbo].[PriorityListSet_RefreshOrder]    Script Date: 5/13/2024 4:57:14 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER      proc [dbo].[PriorityListSet_RefreshOrder]
	@SetID int
AS
BEGIN
	
	DECLARE @Ordertemp Table
	(
		ListID int,
		DispOrder int identity(1,1)
	)

	INSERT INTO @Ordertemp (ListID)
	SELECT ListID
	FROM Priorities_ListSetLists
	WHERE SetID = @SetID
	order by displayorder

	UPDATE Priorities_ListSetLists
	SET DisplayOrder = DispOrder
	FROM Priorities_ListSetLists u
	INNER JOIN @Ordertemp t
	ON  u.ListID = t.ListID
	AND u.setID = @SetID

END
GO

/****** Object:  StoredProcedure [dbo].[PriorityListSet_RemoveUser]    Script Date: 5/13/2024 4:57:53 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER    proc [dbo].[PriorityListSet_RemoveUser]
	@SetID int,
	@UserID int = null,
	@ListID int = null
AS
BEGIN
	--Will transition to primarily using list IDs; until then assume the default list for the user
	IF @ListId IS NULL
		SELECT @ListId = ID
		FROM Priorities_Lists l
		WHERE l.UserID = @userId
			AND l.IsDefaultList = 1

	--remove from list
	DELETE FROM Priorities_ListSetLists
	WHERE SetID = @SetID AND ListID = @ListID
	
	exec PriorityListSet_RefreshOrder @SetID

END

GO

/****** Object:  StoredProcedure [dbo].[PriorityListSet_GetComments]    Script Date: 6/4/2024 8:23:19 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROC [dbo].[PriorityListSet_GetComments]
	@SetID int,
	@UserID int,
	@StartTime datetime,
	@AllUsers bit = 0
AS
BEGIN
	SET NOCOUNT ON

	select 
		l.userid, 
		l.ID ListID,
		li.activechecklistid, 
		--'[' + c.initials + '] '+ case when c.comments like '%href%' then c.comments else replace(c.comments, '''', '''''') end as comments,--commented by venkat 11/02/2017
		'[' + c.initials + '] '+ c.comments as comments,
		li.id,
		c.id as CommentId,
		c.DisplayOrder
	into #result
	from Priorities_ListSetLists lsl
		JOIN Priorities_Lists l		
			on l.ID = lsl.ListID			
		JOIN Priorities_ListItems li
			on li.ListID = l.ID
		join qstatus_comments c
			on c.foreignkeyid = li.activechecklistid
			and c.specialtask = 0
			and (c.userid = @userid OR @AllUsers = 1)
			and c.commentdt > @starttime
	where lsl.setid = @setid
		and len(c.comments) > 0
	order by l.userid, c.displayorder

	DECLARE @recordIds AS RecordId
	INSERT INTO @recordIds
		SELECT DISTINCT CommentId FROM #result WHERE CommentId IS NOT NULL

	--EXEC dbo.Audit_Set @userId, @recordIds, 'Comment', 2

	SELECT UserID, ListID, activechecklistid, comments, id
	FROM #result
	ORDER BY UserID, DisplayOrder
END


/****** Object:  StoredProcedure [dbo].[PriorityList_ExcludeTasks]    Script Date: 5/13/2024 4:59:51 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER proc [dbo].[PriorityList_ExcludeTasks]
	@UserID int,
	@ForUserID int,
	@ActiveChecklistIDs varchar(1000)
AS
BEGIN
	INSERT INTO Priorities_ListExclude
	SELECT @UserID, @ForUserID, n FROM dbo.Util_fn_List_To_Table(@ActiveChecklistIDs,';')
	where n is not null
END
GO

/****** Object:  StoredProcedure [dbo].[DeletePrioritySchedule]    Script Date: 5/13/2024 5:00:56 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[DeletePrioritySchedule] 
	 @ScheduleId int
AS
BEGIN
	Update Priorities_Schedule set IsActive=0, ModifiedDate=GETDATE()
	where ScheduleID=@ScheduleId
END

GO

/****** Object:  StoredProcedure [dbo].[EmailPriorityScheduleChange]    Script Date: 5/13/2024 5:01:10 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[EmailPriorityScheduleChange]
	
AS
BEGIN

	SET DATEFIRST 1;

	Create table #ScheduleChangedEmployees
	(
	  seq int identity(1,1),
	  EmpEmail varchar(100),
	  UserID int
	)

	insert into #ScheduleChangedEmployees(EmpEmail,UserID)
	select distinct qu.Email,ps.UserID 
	from Priorities_Schedule ps
		inner join QCheck_Users qu on qu.id = ps.UserID
	where Convert(date,CreatedDate) = Convert(date,Getdate()) and IsActive=1

	Declare @counter int=1
	declare @ScheduleChangeCount int=1;
   
	declare @appname varchar(100), @mailfrom varchar(100)
	select top 1 @appname = appname, @mailfrom = 'sqlmail@' + BaseDomain from QCheck_AppSettings
	declare @emailsubject varchar(1000) = @appname + ' Priority Schedule Change'


	select @ScheduleChangeCount=count(*) from #ScheduleChangedEmployees

	while(@counter<=@ScheduleChangeCount)
	Begin
		DECLARE @body NVARCHAR(MAX)
		SET @body ='<html><body><H3>'+@appname+' Priority Scheduling has changed</H3><br>
					<table border = 1>
					<tr><th> List </th><th> Day </th> <th> Time </th></tr>'

		Declare @EmpEmail varchar(100);
		Declare @UserID int;
		
		select @EmpEmail=EmpEmail, @UserID=UserID from #ScheduleChangedEmployees where Seq=@counter
		
		DECLARE @xml NVARCHAR(MAX)

		SET @xml = CAST(( 
			SELECT 
				u.FullName as 'td',
				(Case 
					when DaysOfWeek=1
					Then 'Monday'
					when DaysOfWeek=2
					Then 'Tuesday'
					when DaysOfWeek=3
					Then 'Wednesday'
					when DaysOfWeek=4
					Then 'Thursday'
					when DaysOfWeek=5
					Then 'Friday'
					when DaysOfWeek=6
					Then 'Saturday'
					when DaysOfWeek=7
					Then 'Sunday'
					End) AS 'td',
				'',
				CONVERT(varchar(15),CAST(TimesOfDay AS TIME),100) AS 'td'
			FROM  Priorities_Schedule ps
			JOIN QCheck_Users u ON u.ID = ps.UserID
				where ps.UserID = @UserID and IsActive=1 
			order by u.FullName, ps.DaysOfWeek
		FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))
		

		SET @body = @body + @xml +'</table></body></html>'
		exec dbo.xp_smtp_sendmail
						@FROM       = @mailfrom,
						@FROM_NAME  = @appname,
						@TO         = @EmpEmail,
						@CC         = '',
						@subject    = @emailsubject,
						@message    = @body,
						@type       = 'text/html', --'text/html'
						@server     = 'SMTPGATEWAY'
		set @counter=@counter+1
	End
END
GO

/****** Object:  StoredProcedure [dbo].[GetPriorityList_ScheduleReport]    Script Date: 5/13/2024 5:01:31 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[GetPriorityList_ScheduleReport]
	@ReportStartDate Datetime=NULL,
	@ReportEndDate Datetime=null,
	@supervisor int,
	@employee varchar(20)
AS
BEGIN
	SET DATEFIRST 1;
	--Declare @EmpID int=0;
	--Declare @DayOfWeek int =0
	--Declare @StartDate Datetime
	--Declare @ReportStartDate
	Declare @OrigReportEndDate datetime;
	select @ReportStartDate=IsNUll(@ReportStartDate,'01/01/1900')

	--select @ReportEndDate=IsNUll(@ReportEndDate,'01/01/9999')
	--select @ReportEndDate=IsNUll(@ReportEndDate,GetDate()-1)
	select @ReportEndDate=IsNUll(@ReportEndDate,GetDate())
	select @OrigReportEndDate=@ReportEndDate
	
	Declare @EndDate Datetime=Convert(Date,GetDate()-1)

	Create table #Schedule
	(
	  seq int identity(1,1),
	  ScheduleId int,
	  SupervisorID int,
	  UserId int,
	  ListId int,
	  DaysOfWeek varchar(10),
	  ReportDay varchar(10),
	  TimesOfday varchar(10),
	  CreatedDate datetime,
	  ModifiedDate datetime,
	  IsActive bit
	)

	Create table #ScheduleReport
	(
	  seq int identity(1,1),
	  ScheduleId int,
	  Supervisor varchar(100),
	  Employee varchar(100),
	  ListName varchar(100),
	  ReportDate varchar(50),
	  ScheduledDate datetime, 
	  SentDate datetime,
	  ReportsPerWeek int ,
	  IsLate varchar(5),
	  IsExcludedReason varchar(100)
	)

	Create table #Employees
	(
	  ID int,
	  EmpName varchar(100),
	  LastPrioritySet bit
	)

	if(@employee='All')
	Begin
		INSERT INTO #Employees
		EXEC PriorityList_GetSets @UserID = @supervisor, @IsPerson = 0
	End
	Else
	Begin
		INSERT INTO #Employees(ID, EmpName, LastPrioritySet)
		values(0, @employee, 1)
	End


	declare @Counter int=1
	declare @ScheduleCount int=1;

	Insert into #Schedule(ScheduleId,SupervisorID,UserId,ListId,DaysOfWeek,ReportDay,TimesOfday,
		CreatedDate,ModifiedDate,IsActive)
	--load the schedules
	select [ScheduleID]
		  ,[SupervisorID]
		  ,[UserID]
		  ,[ListID]
		  ,[DaysOfWeek]
		  ,[ReportDay]
		  ,[TimesOfDay]
		  ,[CreatedDate]
		  ,ModifiedDate
		  ,IsActive
		  From Priorities_Schedule s
		  where IsActive=1 
		  --and SupervisorID=@supervisor
		  and UserID in (select ID from QCheck_users where FullName in (select EmpName from #Employees) and ID <> @supervisor)

	--get inactive schedules -added on 10/25/2017
	Insert into #Schedule(ScheduleId,SupervisorID,UserID,ListID,DaysOfWeek,ReportDay,TimesOfday,CreatedDate,ModifiedDate,IsActive)
	--load the schedules
	select [ScheduleID]
		  ,[SupervisorID]
		  ,[UserID]
		  ,[ListID]
		  ,[DaysOfWeek]
		  ,[ReportDay]
		  ,[TimesOfDay]
		  ,[CreatedDate]
		  ,ModifiedDate
		  ,IsActive
		  From Priorities_Schedule s
		  where IsActive=0
		 -- and ModifiedDate>= @ReportStartDate and ModifiedDate<=@ReportEndDate
		  --and SupervisorID=@supervisor
		  and UserID in (select ID from QCheck_users where FullName in (select EmpName from #Employees) and ID <>@supervisor)
		   and Convert(date,CreatedDate)<>Convert(date,ModifiedDate)


	select @ScheduleCount=count(*) from #Schedule

	while(@Counter<=@ScheduleCount)
	Begin

		Declare @UserID int=0;
		Declare @ListID int=0;
		Declare @SupervisorID int=0;
		Declare @DayOfWeek int =0
		Declare @ReportDay int =0
		Declare @StartDate Datetime
		Declare @ScheduledTime time;
		Declare @ReportsPerWeek int=0;
		Declare @IsActive bit=1;
		--set @EmpID=715;
		set @ReportEndDate=@OrigReportEndDate
		select @IsActive=IsActive from #Schedule where Seq=@Counter
		if(@IsActive=0)
		Begin
			select @ReportEndDate=ModifiedDate from #Schedule 
			where Seq=@Counter and @ReportEndDate>=Convert(Date,ModifiedDate)
		End

		select @SupervisorID=SupervisorID, @UserID = UserID, @ListID=ListID, @DayOfWeek=DaysofWeek,
			@ReportDay=ReportDay,@StartDate=Convert(Date,CreatedDate),@ScheduledTime=TimesOfday 
			from #Schedule where Seq=@Counter
		
		select @ReportsPerWeek=count(*) 
		from Priorities_Schedule 
		where UserID = @UserID
			and ISNULL(ListID,0)=ISNULL(@ListID,0)
			and IsActive=1

		Create table #ScheduleDates
		(
		 seq int identity(1,1),
		 ScheduledDate datetime
		)

		Create table #ReportDates
		(
		 seq int identity(1,1),
		 ReportDate datetime
		)

		--select @StartDate,@EndDate,@ScheduledTime
		Insert Into #ScheduleDates(ScheduledDate)--this stores the list of all scheduled dates per schedule
		SELECT dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST(@ScheduledTime AS DATETIME))
		 from [dbo].[Util_fn_List_WeekDays_DateRange](@StartDate,@ReportEndDate,@DayOfWeek) dt
		 where 
		 dt.WeekDayDate>=@ReportStartDate 
		 and dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST(@ScheduledTime AS DATETIME))<=@ReportEndDate
		 --and dt.WeekDayDate<=@ReportEndDate
		Insert Into #ReportDates(ReportDate)--this stores the list of all scheduled dates per schedule
		SELECT dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST('00:00' AS DATETIME))
		 from [dbo].[Util_fn_List_WeekDays_DateRange](@StartDate,@ReportEndDate,@ReportDay) dt
		  where

		 dt.WeekDayDate>=@ReportStartDate 
		 and dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST(@ScheduledTime AS DATETIME))<=@ReportEndDate
		 --and dt.WeekDayDate<=@ReportEndDate
		--select * from #ScheduleDates

		Declare @ScheduledDatesCounter int=1;

		Declare @ScheduledDatesCount int=0;

		select @ScheduledDatesCount=count(*) from #ScheduleDates

		while (@ScheduledDatesCounter<=@ScheduledDatesCount)
		Begin

			Declare @ScheduledDate Datetime;
			Declare @ReportDate Datetime;
			select @ScheduledDate=ScheduledDate from #ScheduleDates where Seq=@ScheduledDatesCounter 
			select @ReportDate=ReportDate from #ReportDates where Seq=@ScheduledDatesCounter 

			if(@ReportsPerWeek=1)--this is for weekly reports
			Begin
				Insert into #ScheduleReport(Supervisor,Employee,ListName,ReportDate,ScheduledDate,SentDate,IsLate,ReportsPerWeek,IsExcludedReason)
				values
				(
					 (select FullName from QCheck_Users where ID=@SupervisorID)
					,(select FullName from QCheck_Users where ID=@UserID)
					,(select Name from Priorities_Lists where ID=@ListID)
					,(select ReportDate from #ReportDates where Seq=@ScheduledDatesCounter)
					,(select ScheduledDate from #ScheduleDates where Seq=@ScheduledDatesCounter)
					,(select Max(Sent) from QCheck_Log_Emails 
					   where 
					  -- Convert(Date,Sent)=Convert(Date,@ScheduledDate) and 
					  -- Sent>dateadd(day, datediff(day,'19000101', Convert(Date,@ScheduledDate)), CAST('00:00' AS DATETIME)) and
					  Sent>@ReportDate-2 and
					   (Sent<= @ScheduledDate or  Convert(Date,Sent)=Convert(Date,@ScheduledDate))
					   and FromId=@UserID 
					   and ToId <> FromId
					   --and ToId=@SupervisorID
					   )
					,null
					,@ReportsPerWeek
					,case when Exists(select 1 from  Priorities_ScheduleExclude
						where ListID=@ListID and IsActive=1 
							and ExcludedDate<=@ScheduledDate 
							and Convert(Date,ExcludedDate)=Convert(Date,@ScheduledDate))
					 Then 'Excused'
					 when Exists(select 1 from MyVacation.dbo.Vacation 
						where EmployeeID=(select EmpID from Qcheck_Users where ID=@UserID) 
							and Convert(Date,VacationDay)=Convert(Date,@ScheduledDate))
					 Then 'Vacation'
					 End
				)
			End
			else
			Begin
				Insert into #ScheduleReport(Supervisor,Employee,ListName,ReportDate,ScheduledDate,SentDate,IsLate,ReportsPerWeek,IsExcludedReason)
				values
				(
					 (select FullName from QCheck_Users where ID=@SupervisorID)
					,(select FullName from QCheck_Users where ID=@UserID)
					,(select Name from Priorities_Lists where ID=@ListID)
					,(select ReportDate from #ReportDates where Seq=@ScheduledDatesCounter)
					,(select ScheduledDate from #ScheduleDates where Seq=@ScheduledDatesCounter)
					,(select Max(Sent) from QCheck_Log_Emails 
					   where 
					  -- Convert(Date,Sent)=Convert(Date,@ScheduledDate) and 
				  -- Sent>dateadd(day, datediff(day,'19000101', Convert(Date,@ScheduledDate)), CAST('00:00' AS DATETIME)) and
					  Sent>@ReportDate and
					   (Sent<= @ScheduledDate or Convert(Date,Sent)=Convert(Date,@ScheduledDate))
					   and FromId=@UserID 
					   and ToId <> FromId
					   --and ToId=@SupervisorID
					   )
					,null
					,@ReportsPerWeek
					,case when Exists(select 1 from Priorities_ScheduleExclude
						where ListID=@ListID and IsActive=1 
							and ExcludedDate<=@ScheduledDate 
							and Convert(Date,ExcludedDate)=Convert(Date,@ScheduledDate))
					 Then 'Excused'
					 when Exists(select 1 from MyVacation.dbo.Vacation 
						where EmployeeID=(select EmpID from Qcheck_Users where ID=@UserID) 
							and Convert(Date,VacationDay)=Convert(Date,@ScheduledDate))
					 Then 'Vacation'
					 End
				)
			End

			set @ScheduledDatesCounter=@ScheduledDatesCounter+1
		End

		Drop table #ScheduleDates 
		Drop table #ReportDates 
		
		set @Counter=@Counter+1

	End

	--with x as (
	--	select * from #ScheduleReport
	-- order by Employee Desc
	--	)
	--	select * from x order by ScheduledDate Desc

	--select * from #Schedule

	Drop table #Employees
	select distinct * from #ScheduleReport
	 order by Employee 

END
GO

/****** Object:  StoredProcedure [dbo].[GetPriorityList_ScheduleReport_All]    Script Date: 5/13/2024 5:01:45 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[GetPriorityList_ScheduleReport_All]
@ReportStartDate Datetime=NULL,
@ReportEndDate Datetime=null
--@supervisor int
AS
BEGIN
	SET DATEFIRST 1;
	--Declare @EmpID int=0;
	--Declare @DayOfWeek int =0
	--Declare @StartDate Datetime
	Declare @OrigReportEndDate datetime;
	select @ReportStartDate=IsNUll(@ReportStartDate,'01/01/1900')

	--select @ReportEndDate=IsNUll(@ReportEndDate,'01/01/9999')
	--select @ReportEndDate=IsNUll(@ReportEndDate,GetDate()-1)
	select @ReportEndDate=IsNUll(@ReportEndDate,GetDate())
	select @OrigReportEndDate=@ReportEndDate

	Declare @EndDate Datetime=Convert(Date,GetDate()-1)

	Create table #Schedule
	(
	  seq int identity(1,1),
	  ScheduleId int,
	  SupervisorID int,
	  UserId int,
	  ListId int,
	  DaysOfWeek varchar(10),
	  ReportDay varchar(10),
	  TimesOfday varchar(10),
	  CreatedDate datetime,
	  ModifiedDate datetime,
	  IsActive bit
	)

	Create table #ScheduleReport
	(
	  seq int identity(1,1),
	  ScheduleId int,
	  Supervisor varchar(100),
	  Employee varchar(100),
	  ListName varchar(100),
	  ReportDate varchar(50),
	  ScheduledDate datetime, 
	  SentDate datetime,
	  ReportsPerWeek int ,
	  IsLate varchar(5),
	  IsExcludedReason varchar(100)
	)

	declare @Counter int=1
	declare @ScheduleCount int=1;

	Insert into #Schedule(ScheduleId,SupervisorID,UserId,ListId,DaysOfWeek,ReportDay,TimesOfday,
		CreatedDate,ModifiedDate,IsActive)
	--load the schedules
	select [ScheduleID]
		  ,[SupervisorID]
		  ,[UserID]
		  ,[ListID]
		  ,[DaysOfWeek]
		  ,[ReportDay]
		  ,[TimesOfDay]
		  ,[CreatedDate]
		  ,ModifiedDate
		  ,IsActive
	From Priorities_Schedule s
	where IsActive=1 
		  
	--get inactive schedules -added on 10/25/2017
	Insert into #Schedule(ScheduleId,SupervisorID,UserID,ListID,DaysOfWeek,ReportDay,TimesOfday,CreatedDate,ModifiedDate,IsActive)
	--load the schedules
	select [ScheduleID]
		  ,[SupervisorID]
		  ,[UserID]
		  ,[ListID]
		  ,[DaysOfWeek]
		  ,[ReportDay]
		  ,[TimesOfDay]
		  ,[CreatedDate]
		  ,ModifiedDate
		  ,IsActive
	From Priorities_Schedule s
	where IsActive=0
		and Convert(date,CreatedDate)<>Convert(date,ModifiedDate)

	select @ScheduleCount=count(*) from #Schedule

	while(@Counter<=@ScheduleCount)
	Begin

		Declare @UserID int=0;
		Declare @ListID int=0;
		Declare @SupervisorID int=0;
		Declare @DayOfWeek int =0
		Declare @ReportDay int =0
		Declare @StartDate Datetime
		Declare @ScheduledTime time;
		Declare @ReportsPerWeek int=0;

		Declare @IsActive bit=1;
		--set @EmpID=715;
		set @ReportEndDate=@OrigReportEndDate
		select @IsActive=IsActive from #Schedule where Seq=@Counter
		if(@IsActive=0)
		Begin
			--select @ReportEndDate=Convert(Date,ModifiedDate) from #Schedule where Seq=@Counter and @ReportEndDate>=Convert(Date,ModifiedDate)
			select @ReportEndDate=ModifiedDate from #Schedule where Seq=@Counter and @ReportEndDate>=Convert(Date,ModifiedDate)
		End
		--set @EmpID=715;
		select @SupervisorID=SupervisorID, @UserID=UserID, @ListID=ListID, @DayOfWeek=DaysofWeek,
			@ReportDay=ReportDay,@StartDate=Convert(Date,CreatedDate),@ScheduledTime=TimesOfday 
		from #Schedule where Seq=@Counter
	
		select @ReportsPerWeek=count(*) 
		from Priorities_Schedule 
		where UserID = @UserID
			and ISNULL(ListID,0)=ISNULL(@ListID,0)
			and IsActive=1

		Create table #ScheduleDates
		(
		 seq int identity(1,1),
		 ScheduledDate datetime
		)

		Create table #ReportDates
		(
		 seq int identity(1,1),
		 ReportDate datetime
		)

		--select @StartDate,@EndDate,@ScheduledTime
		Insert Into #ScheduleDates(ScheduledDate)--this stores the list of all scheduled dates per schedule
		SELECT dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST(@ScheduledTime AS DATETIME))
		 from [dbo].[Util_fn_List_WeekDays_DateRange](@StartDate,@ReportEndDate,@DayOfWeek) dt
		 where 

		 dt.WeekDayDate>=@ReportStartDate 
		 and  dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST(@ScheduledTime AS DATETIME))<=@ReportEndDate
		 --and dt.WeekDayDate<=@ReportEndDate
		Insert Into #ReportDates(ReportDate)--this stores the list of all scheduled dates per schedule
		SELECT dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST('00:00' AS DATETIME))
		 from [dbo].[Util_fn_List_WeekDays_DateRange](@StartDate,@ReportEndDate,@ReportDay) dt
		  where
 
		 dt.WeekDayDate>=@ReportStartDate 
		 and  dateadd(day, datediff(day,'19000101',dt.WeekDayDate), CAST(@ScheduledTime AS DATETIME))<=@ReportEndDate
		 --and dt.WeekDayDate<=@ReportEndDate
		--select * from #ScheduleDates

		Declare @ScheduledDatesCounter int=1;

		Declare @ScheduledDatesCount int=0;

		select @ScheduledDatesCount=count(*) from #ScheduleDates

		while (@ScheduledDatesCounter<=@ScheduledDatesCount)
		Begin

			Declare @ScheduledDate Datetime;
			Declare @ReportDate Datetime;
			select @ScheduledDate=ScheduledDate from #ScheduleDates where Seq=@ScheduledDatesCounter 
			select @ReportDate=ReportDate from #ReportDates where Seq=@ScheduledDatesCounter 

			if(@ReportsPerWeek=1)--this is for weekly reports
			Begin
				Insert into #ScheduleReport(Supervisor,Employee,ListName,ReportDate,ScheduledDate,SentDate,IsLate,ReportsPerWeek,IsExcludedReason)
				values
				(
						(select FullName from QCheck_Users where ID=@SupervisorID)
					,(select FullName from QCheck_Users where ID=@UserID)
					,(select Name from Priorities_Lists where ID=@ListID)
					,(select ReportDate from #ReportDates where Seq=@ScheduledDatesCounter)
					,(select ScheduledDate from #ScheduleDates where Seq=@ScheduledDatesCounter)
					,(select Max(Sent) from QCheck_Log_Emails 
						where 
						-- Convert(Date,Sent)=Convert(Date,@ScheduledDate) and 
						-- Sent>dateadd(day, datediff(day,'19000101', Convert(Date,@ScheduledDate)), CAST('00:00' AS DATETIME)) and
						Sent>@ReportDate-2 and
						(Sent<= @ScheduledDate or  Convert(Date,Sent)=Convert(Date,@ScheduledDate))
						and FromId=@UserID 
						and ToId <> FromId
						--and ToId=@SupervisorID
						)
					,null
					,@ReportsPerWeek
					,case when Exists(select 1 from  Priorities_ScheduleExclude
						where ListID=@ListID and IsActive=1 
							and ExcludedDate<=@ScheduledDate 
							and Convert(Date,ExcludedDate)=Convert(Date,@ScheduledDate))
						Then 'Excused'
						when Exists(select 1 from MyVacation.dbo.Vacation 
						where EmployeeID=(select EmpID from Qcheck_Users where ID=@UserID) 
							and Convert(Date,VacationDay)=Convert(Date,@ScheduledDate))
						Then 'Vacation'
						End
				)
			End
			else
			Begin
				Insert into #ScheduleReport(Supervisor,Employee,ListName,ReportDate,ScheduledDate,SentDate,IsLate,ReportsPerWeek,IsExcludedReason)
				values
				(
						(select FullName from QCheck_Users where ID=@SupervisorID)
					,(select FullName from QCheck_Users where ID=@UserID)
					,(select Name from Priorities_Lists where ID=@ListID)
					,(select ReportDate from #ReportDates where Seq=@ScheduledDatesCounter)
					,(select ScheduledDate from #ScheduleDates where Seq=@ScheduledDatesCounter)
					,(select Max(Sent) from QCheck_Log_Emails 
						where 
						-- Convert(Date,Sent)=Convert(Date,@ScheduledDate) and 
					-- Sent>dateadd(day, datediff(day,'19000101', Convert(Date,@ScheduledDate)), CAST('00:00' AS DATETIME)) and
						Sent>@ReportDate and
						(Sent<= @ScheduledDate or Convert(Date,Sent)=Convert(Date,@ScheduledDate))
						and FromId=@UserID 
						and ToId <> FromId
						--and ToId=@SupervisorID
						)
					,null
					,@ReportsPerWeek
					,case when Exists(select 1 from Priorities_ScheduleExclude
						where ListID=@ListID and IsActive=1 
							and ExcludedDate<=@ScheduledDate 
							and Convert(Date,ExcludedDate)=Convert(Date,@ScheduledDate))
						Then 'Excused'
						when Exists(select 1 from MyVacation.dbo.Vacation 
						where EmployeeID=(select EmpID from Qcheck_Users where ID=@UserID) 
							and Convert(Date,VacationDay)=Convert(Date,@ScheduledDate))
						Then 'Vacation'
						End
				)
			End


			set @ScheduledDatesCounter=@ScheduledDatesCounter+1
		End

		Drop table #ScheduleDates 
		Drop table #ReportDates 

		set @Counter=@Counter+1

	End

	select * from #ScheduleReport
	order by Employee

END
GO

/****** Object:  StoredProcedure [dbo].[GetPriorityListSchedules]    Script Date: 5/13/2024 5:01:58 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[GetPriorityListSchedules] 
	@supervisorId int,
	@subOrdinateId int
AS
BEGIN
	select s.ScheduleID
		,[SupervisorID]
		,s.[UserID]
		,s.[UserID] subOrdinateID
		,[ListID]
		,[DaysOfWeek]
		,[TimesOfDay]
		,ReportDay
		,[CreatedDate]
		,[CreatedBy]
		,[ModifiedDate]
		,[ModifiedBy]
		,[IsActive]
		,ISNULL(l.Name + '('++')', u.FullName)
	from Priorities_Schedule s
		LEFT JOIN Priorities_Lists l 
			ON l.ID = s.ListID
		LEFT JOIN QCheck_Users u
			ON u.ID = s.UserID
	where s.UserId=@subOrdinateId and IsActive=1
	order by l.IsDefaultList desc, l.Name, DaysOfWeek
END
GO

/****** Object:  StoredProcedure [dbo].[InsertPrioritySchedule]    Script Date: 5/13/2024 5:02:08 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[InsertPrioritySchedule] 
	@supervisorId int,
	@subOrdinateId int,
	@ListId int = null,
	@daysOfWeek varchar(10),
	@timesOfDay varchar(250),
	@reportDay varchar(10)

AS
BEGIN

	if Exists( 
		select 1 from Priorities_Schedule 
		where UserID = @subOrdinateId
			and ISNULL(ListID, 0) = ISNULL(@ListID, 0)
			and DaysOfWeek=@daysOfWeek  
			and IsActive=1
	)
	Begin
		Update [dbo].Priorities_Schedule set 
			IsActive=0,
			ModifiedDate=GETDATE(),
			ModifiedBy=@supervisorId
		where UserID = @subOrdinateId
			and ISNULL(ListID, 0) = ISNULL(@ListID, 0)			
			and DaysOfWeek=@daysOfWeek  
			and IsActive=1
	End	

	INSERT INTO [dbo].Priorities_Schedule
			([SupervisorID]
			,[UserID]
			,[ListID]
			,[DaysOfWeek]
			,[TimesOfDay]
			,ReportDay
			,[CreatedDate]
			,[CreatedBy]
			,[ModifiedDate]
			,[ModifiedBy]
			,[IsActive])
		VALUES
			(@supervisorId
			,@subOrdinateId
			,@listId
			,@daysOfWeek
			,@timesOfDay
			,@reportDay
			,GetDate()
			,@supervisorId
			,null
			,null
			,1)	
END
GO

/****** Object:  StoredProcedure [dbo].[QStatus_GetPriorityListSchedules]    Script Date: 5/13/2024 5:02:29 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[QStatus_GetPriorityListSchedules] 
	@supervisorId int,
	@subOrdinateId int
AS
BEGIN
	select s.ScheduleID
		,[SupervisorID]
		,s.[UserID]
		,s.[UserID] subOrdinateID
		,[ListID]
		,[DaysOfWeek]
		,[TimesOfDay]
		,ReportDay
		,[CreatedDate]
		,[CreatedBy]
		,[ModifiedDate]
		,[ModifiedBy]
		,[IsActive]
		,ISNULL(l.Name + '('++')', u.FullName)
	from Priorities_Schedule s
		LEFT JOIN Priorities_Lists l 
			ON l.ID = s.ListID
		LEFT JOIN QCheck_Users u
			ON u.ID = s.UserID
	where s.UserId=@subOrdinateId and IsActive=1
	order by l.IsDefaultList desc, l.Name, DaysOfWeek
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_EmailTest]    Script Date: 5/13/2024 5:04:04 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[PriorityList_EmailTest] 
	@employee varchar(100)
	,@supervisorId int
	,@excludedDate datetime
AS
BEGIN
	Declare @userID int=0

	select @userID=u.ID from QCheck_Users u where FullName=@employee and IsDeleted=0

	if NOT Exists (
		select 1 
		from Priorities_ScheduleExclude e
		where UserID=@userID 
			and ExcludedDate=@excludedDate 
			and IsActive=1
	)
	Begin
   
		if(Exists(select 1 from PriorityList_LateFee_Log where EmpID=@userID and LateDate=@excludedDate and IsActive=1 ))
		Begin
			Declare @currentLateCharge money=0
			select @currentLateCharge=Isnull(Sum(LateCharge),0) from PriorityList_LateFee_Log where EmpID=@userID and Convert(Date,LateDate)>=Convert(Date,@excludedDate) and IsActive=1
	
			Create table #ReRunDates
			(
				seq int identity(1,1),
				RunDate datetime
			)

			declare @startDate Datetime=Convert(Date,@excludedDate+1)
			declare @endDate Datetime=Convert(Date,GETDATE()-1)

			Insert into #ReRunDates(RunDate)
			SELECT dateadd(day, datediff(day,'19000101',dt.WeekDayDate), '23:59')
			from [dbo].[Util_fn_List_DateRange](@startDate,@endDate) dt 
  
			Declare @runDatesCounter int=1
			Declare @runDatesCount int=0

			select * from #ReRunDates
			select @startDate,@endDate
			select @runDatesCount=count(*) from #ReRunDates

			while(@runDatesCounter<=@runDatesCount)
			Begin
				Declare @runDate datetime;
				
				select @runDate=RunDate from #ReRunDates where Seq=@runDatesCounter
				
				set @runDatesCounter=@runDatesCounter+1
			End

			Drop table #ReRunDates

			DECLARE @BodyController varchar(max), @Subject varchar(1000),@MailServer VARCHAR(50),@assigneeEmailAddress VARCHAR(100),@supervisorEmailAddress varchar(100)

			SELECT @MailServer = MailServer 
				FROM QCheck_AppSettings WHERE ID = 1

			select @assigneeEmailAddress=u.Email from QCheck_Users u where FullName=@employee and IsDeleted=0

			select @supervisorEmailAddress=u.Email from QCheck_Users u where u.ID=@supervisorId and IsDeleted=0

			SET @bodyController ='<html><body><H3>Missed Priority List for '+CAST(@excludedDate as varchar(12))+' has been Excused</H3></body></html>'
            
			DECLARE @FromAddress VARCHAR(100) = (SELECT TOP 1 PriorityExcusedAddress FROM QCheck_AppSettings)

			EXEC dbo.xp_smtp_sendmail --this email is for Assignee
				@from = @FromAddress, 
				@to = @assigneeEmailAddress, 
				--@cc= 'vkanakamedala@acmewidget.com',
				@subject = 'Missed Priority List Excused',
				@message = @bodyController, 
				@type = 'text/html', 
				@server = @MailServer

		End
	End
END
GO

/****** Object:  StoredProcedure [dbo].[PriorityList_Exclude_Insert]    Script Date: 5/13/2024 5:04:21 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[PriorityList_Exclude_Insert] 
--DECLARE
	 @FromAddress varchar(500) --= 'kcroft@acmewidget.com'
	,@ToAddress varchar(8000) --= 'kshannon@acmewidget.com,nholm@acmewidget.com,priorityexcused@automation.acmenetwork.com,bteague@acmewidget.com,,,,'
	,@excludedDate datetime --= '2020-01-24'
	,@answer varchar(50) --= 'NO'
AS
BEGIN
    DECLARE  @isSupervisorToAddress bit=0
	DECLARE  @isSupervisorFromAddress bit=0
	DECLARE	 @sendproblememail bit = 0
	DECLARE @PriorityExcusedAddress VARCHAR(100) = (SELECT TOP 1 PriorityExcusedAddress FROM QCheck_AppSettings)
	set @ToAddress=REPLACE(@ToAddress,@PriorityExcusedAddress,'')--added this so that priorityexcused email address can be included in the To or CC list
	--set @ToAddress=REPLACE(@ToAddress,',','')--added this so that priorityexcused email address can be included in the To or CC list
			
	DECLARE @addresses TABLE (seq int IDENTITY(1,1), address varchar(500))
	DECLARE @supervisorAddress varchar(500), @firstToAddress varchar(500)

	INSERT INTO @addresses SELECT c FROM dbo.Util_fn_List_To_Table(@ToAddress, ',') WHERE c IS NOT NULL AND LEN(c) > 0
	
	--check for TO address matching an individual in qprocess		
	select TOP 1 @isSupervisorToAddress=1, @supervisorAddress = a.address
	from qstatus_supervisors s
	inner join qstatus_report r
	on r.id = s.reportid
	--and r.isdeleted = 0
	inner join qcheck_groups g
	on g.id = s.supervisorgroupid
	inner join qcheck_groupmembership gm
	on gm.groupid = g.id
	--and gm.userid = (select ID from QCheck_Users where Email=@ToAddress and IsDeleted=0)
	INNER JOIN QCheck_Users u 
	ON u.ID = gm.UserID and u.IsDeleted = 0
	INNER JOIN @addresses a
	ON a.address = u.Email
	inner join qstatus_groupreport gr
	on gr.reportid = r.id
	and gr.defaultreport = 1
	inner join qcheck_groups g2
	on g2.id = gr.groupid
	inner join qcheck_groupmembership gm2
	on gm2.groupid = g2.id
	and gm2.UserID = (select ID from QCheck_Users where Email=@FromAddress and IsDeleted=0)
	where s.interestedparty = 0
	ORDER BY a.seq

	--To be treated as a response from a supe, the supe must supervise the requestor's report (not just any report)
	--In a Reply All to the original request, the first addressed recipient should be the requestor.
	SELECT TOP 1 @firstToAddress = address FROM @addresses ORDER BY seq

	select @isSupervisorFromAddress=1, @supervisorAddress = @FromAddress from 
	qstatus_supervisors s
	inner join qstatus_report r
	on r.id = s.reportid
	--and r.isdeleted = 0
	inner join qcheck_groups g
	on g.id = s.supervisorgroupid
	inner join qcheck_groupmembership gm
	on gm.groupid = g.id
	and gm.userid = (select ID from QCheck_Users where Email=@FromAddress and IsDeleted=0)
	inner join qstatus_groupreport gr
	on gr.reportid = r.id
	and gr.defaultreport = 1
	inner join qcheck_groups g2
	on g2.id = gr.groupid
	inner join qcheck_groupmembership gm2
	on gm2.groupid = g2.id
	and gm2.UserID = (select ID from QCheck_Users where Email=@firstToAddress and IsDeleted=0)
	where s.interestedparty = 0

	if not exists (select 1 from QCheck_Users where Email=@supervisorAddress and IsDeleted=0)
	begin
		set @sendproblememail = 1
	end

	if(@FromAddress<>@ToAddress)
	Begin
		if(@isSupervisorFromAddress=1)
		Begin
			if(UPPER(RTRIM(LTRIM(@answer)))='N' OR UPPER(RTRIM(LTRIM(@answer)))='NO')
			Begin				
				Update e
				set IsActive=0 
				FROM [Priorities_ScheduleExclude] e
					JOIN Priorities_Lists l ON l.ID = e.ListID
				where l.UserID=(select u.ID from QCheck_Users u where u.Email=@firstToAddress and IsDeleted=0)
					and e.SupervisorId=(select u.ID from QCheck_Users u where u.Email=@FromAddress and IsDeleted=0)
					--this assumes supervisor declines the request on the same day it was submitted		 
					and Convert(date,ExcludedDate) = Convert(date,getdate())
			End
		End
		ELSE if(@isSupervisorToAddress=1)
		Begin
			INSERT INTO [dbo].[Priorities_ScheduleExclude]
				   ([ListID]
				   ,SupervisorId
				   ,[ExcludedDate])
			SELECT 
				l.ID,
				s.ID,				   
				(case 
					when Convert (date, @excludedDate) = '01/01/1900' Then getdate()
					else dateadd(day, datediff(day,'19000101',@excludedDate), Cast(COnvert(Time,GetDate()) as Datetime  ))
				End)
				FROM Priorities_Schedule sch
				JOIN Priorities_Lists l 
					ON l.ID = sch.ListID 
				JOIN QCheck_Users s 
					ON s.Email=@supervisorAddress 
					and s.IsDeleted=0
				JOIN QCheck_Users u 
					ON u.Email=@FromAddress 
					and u.IsDeleted=0
			 
		End
		Else
		Begin
			set @sendproblememail = 1
		End
	End
	
	if @sendproblememail = 1
	begin
	
		-- Get app configuration
		DECLARE @AppURL VARCHAR(50), @ImagesURL VARCHAR(50), @ExternalURL VARCHAR(50), @BaseDomain VARCHAR(50), @AppFromAddress VARCHAR(50), @AppName VARCHAR(50), @GradingAddress VARCHAR(50), @AutomationAddress VARCHAR(50), @DeveloperAddress VARCHAR(50), @ITAddress VARCHAR(50), @MailServer VARCHAR(50)
		SELECT @AppURL = AppURL, @ImagesURL = ImagesURL, @ExternalURL = ExternalURL, @BaseDomain = BaseDomain, @AppFromAddress = FromAddress, @Appname = AppName, @GradingAddress = GradingAddress, @AutomationAddress = AutomationAddress, @DeveloperAddress = DeveloperAddress, @ITAddress = ITAddress, @MailServer = MailServer 
		FROM QCheck_AppSettings WHERE ID = 1
		
		DECLARE @ExcuseEmail varchar(500)
		SELECT @ExcuseEmail = PermissionValue 
		from [SECURESQL_APPSEC].[_acmesec_appsec].[dbo].[APP_SpecificPermissions]
		WHERE appID = @Appname 
			and permissiontype = 'excuseemail'
		
		DECLARE @Body varchar(max), @Subject varchar(100)
		SET @Body = 'Unable to record priority excuse sent from ' + @FromAddress 
			+ ' to ' + COALESCE(@supervisorAddress, @ToAddress, '(none specified)') 
			+ '.<br/><br/>Please make sure your supervisor''s email is the only address in the TO line (and just 1 supervisor, if you have multiple you can include them in the CC line).'
		SET @Subject = 'Priority Excuse Email Failed'
		
		
		EXEC dbo.xp_smtp_sendmail 
		@from = @AppFromAddress, 
		@to = @FromAddress, 
		@cc = @ExcuseEmail,
		@subject = @Subject,
		@message = @Body, 
		@type = 'text/html', 
		@server = @MailServer
		
		--select @AppFromAddress, @FromAddress, @ExcuseEmail, @Subject, @Body, @MailServer
	end
	
	
END

GO

/****** Object:  StoredProcedure [dbo].[PriorityList_Exclude_Supervisor_Excuse_Insert]    Script Date: 5/13/2024 5:04:50 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[PriorityList_Exclude_Supervisor_Excuse_Insert] 
	@employee varchar(100)
	,@supervisorId int
	,@excludedDate datetime
AS
BEGIN
	Declare @userID int=0

	select @userID=u.ID from QCheck_Users u where FullName=@employee and IsDeleted=0

	if NOT Exists (
		select 1 
		from Priorities_ScheduleExclude e
		JOIN Priorities_Lists l 
		ON l.ID = e.ListID
			AND l.UserID = @userID
		where ExcludedDate=@excludedDate 
			and IsActive=1)
	Begin
		INSERT INTO [dbo].Priorities_ScheduleExclude
			(ListID
			,SupervisorId
			,[ExcludedDate]
			,IsActive)
		SELECT s.ListID
			,@supervisorId
			,@excludedDate
			,1
		FROM Priorities_Schedule s
		JOIN Priorities_Lists l
			ON l.ID = s.ListID
			AND l.UserID = @userID
		WHERE s.SupervisorID = @supervisorId
   
		if(Exists(select 1 from PriorityList_LateFee_Log where EmpID=@userID and LateDate=@excludedDate and IsActive=1 ))
		Begin
			Declare @currentLateCharge money=0
			select @currentLateCharge=Isnull(Sum(LateCharge),0) 
			from PriorityList_LateFee_Log 
			where EmpID=@userID 
				and Convert(Date,LateDate)>=Convert(Date,@excludedDate) 
				and IsActive=1
			   
			INSERT INTO  [AcmeDotNet].[dbo].[empFines]
				([SourceId]
				,[EmpId]
				,[Charge]
				,[ChargeSource]
				,[ChargeDesc]
				,[ChargeDate]
				,[CreatedDate])
			select 
				Id
				,(select empid from qcheck_users where id=PL.EmpID)
				,-LateCharge
				,'QProcess-MissedPriority'
				,'QProcess-MissedPriority-Excuse-'+COnvert(varchar(10),LateDate,101)
				,LateDate
				,GetDate()
			From PriorityList_LateFee_Log PL
			where EmpID=@userID and Convert(Date,LateDate)>=Convert(Date,@excludedDate) and IsActive=1

			update PriorityList_LateFee_Log set IsActive=0
			where EmpID=@userID and Convert(Date,LateDate)>=Convert(Date,@excludedDate) and IsActive=1

			Create table #ReRunDates
			(
				seq int identity(1,1),
				RunDate datetime
			)

			-- declare @startDate Datetime=Convert(Date,@excludedDate+1)--commented by venkat 05/17/2018
			declare @startDate Datetime=Convert(Date,@excludedDate)--changed by venkat 05/17/2018
			declare @endDate Datetime=Convert(Date,GETDATE()-1)

			Insert into #ReRunDates(RunDate)
			SELECT dateadd(day, datediff(day,'19000101',dt.WeekDayDate), '23:59')
			from [dbo].[Util_fn_List_DateRange](@startDate,@endDate) dt 

			Declare @runDatesCounter int=1
			Declare @runDatesCount int=0
			--select * from #ReRunDates
			--select @startDate,@endDate
			select @runDatesCount=count(*) from #ReRunDates

			while(@runDatesCounter<=@runDatesCount)
			Begin
				Declare @runDate datetime;
				select @runDate=RunDate from #ReRunDates where Seq=@runDatesCounter

				EXEC [dbo].[PriorityList_Record_LateFee_Employee] @ReportEndDate = @runDate,@employeeId=@userID
		
				set @runDatesCounter=@runDatesCounter+1
			End

			Drop table #ReRunDates

			DECLARE @BodyController varchar(max), @Subject varchar(1000),@MailServer VARCHAR(50),@assigneeEmailAddress VARCHAR(100),@supervisorEmailAddress varchar(100)

			SELECT @MailServer = MailServer 
			FROM QCheck_AppSettings WHERE ID = 1

			select @assigneeEmailAddress=u.Email from QCheck_Users u where FullName=@employee and IsDeleted=0

			select @supervisorEmailAddress=u.Email from QCheck_Users u where u.ID=@supervisorId and IsDeleted=0

			SET @bodyController ='<html><body><H3>Missed Priority List for '+CAST(@excludedDate as varchar(12))+' has been Excused</H3></body></html>'
            
			declare @fromaddress varchar(100) = (select top 1 PriorityExcusedAddress from QCheck_AppSettings)

			EXEC dbo.xp_smtp_sendmail --this email is for Assignee
				@from = @fromaddress, 
				@to = @assigneeEmailAddress, 
				@cc= @supervisorEmailAddress,
				@subject = 'Missed Priority List Excused',
				@message = @bodyController, 
				@type = 'text/html', 
				@server = @MailServer

		End
	End
END
GO

CREATE OR ALTER PROCEDURE PriorityList_CreateUpdate
	@ListID int = null,
	@Name varchar(50),
	@UserID int,
	@IsDefaultList bit
AS
BEGIN

	DECLARE @SetID int = 0

	IF ISNULL(@ListID, 0) > 0
	BEGIN		
		UPDATE Priorities_Lists SET
			Name = @Name,
			IsDefaultList = @IsDefaultList
		WHERE ID = @ListID
			AND UserID = @UserID

		--Update the name of the personal list set for this list as well
		UPDATE ls SET
			Name = @Name
		FROM Priorities_ListSets ls
		JOIN Priorities_ListSetLists lsl
			ON lsl.SetID = ls.ID		
			AND lsl.ListID = @ListID
		WHERE ls.PersonalSet = 1
	END
	ELSE
	BEGIN
		INSERT INTO Priorities_Lists (Name, UserID, IsDefaultList)
		VALUES (@Name, @UserID, @IsDefaultList)

		SELECT @ListID = SCOPE_IDENTITY()

		--Also create a personal priority list set containing this one list
		INSERT INTO Priorities_ListSets (Name, UserID, PersonalSet)
		VALUES (@Name, @UserID, 1)

		SELECT @SetID = SCOPE_IDENTITY()

		INSERT INTO Priorities_ListSetLists(SetID, ListID, DisplayOrder) VALUES (@SetID, @ListID, 1)		
	END

	--Make sure there's *exactly* one default list per user
	IF @IsDefaultList = 1
	BEGIN
		UPDATE Priorities_Lists SET
			IsDefaultList = 0
		WHERE UserID = @UserID
			AND ID <> @ListID
	END
	ELSE IF NOT EXISTS( 
		select 'Y' from Priorities_Lists
		WHERE ID <> @ListID 
			AND UserID = @UserID 
			AND IsDefaultList = 1
		)
	BEGIN
		UPDATE Priorities_Lists SET
			IsDefaultList = 1
		WHERE ID = (
			select Min(ID)
			FROM Priorities_Lists
			WHERE UserID = @UserID
			--Prefer a list other than the one we just updated, unless it's the only one
				AND (ID <> @ListID
					OR (select COUNT(*) FROM Priorities_Lists
						WHERE UserID = @UserID AND ID <> @ListID) = 0)
		)
	END

	select @ListID ListID
END
GO

CREATE OR ALTER PROCEDURE PriorityList_SetDefault
	@ListID int = null,
	@SetID int = null
AS
BEGIN
	DECLARE @UserID int = 0

	if @ListID IS NULL
		SELECT @ListID = lsl.ListID 
		FROM Priorities_ListSetLists lsl
		JOIN Priorities_ListSets ls
			ON ls.ID = lsl.SetID
			AND ls.ID = @SetID
			AND ls.PersonalSet = 1
		

	SELECT @UserID = UserID 
	FROM Priorities_Lists
	WHERE ID = @ListID
	
	UPDATE Priorities_Lists SET			
		IsDefaultList = 1
	WHERE UserID = @UserID
		AND ID = @ListID

	UPDATE Priorities_Lists SET
		IsDefaultList = 0
	WHERE UserID = @UserID
		AND ID <> @ListID
END
GO

CREATE OR ALTER PROCEDURE PriorityList_Delete
	@ListID int --must specify the actual list, can't use user
AS
BEGIN

    --... because we should never delete a user's default list
	if (select IsDefaultList from Priorities_Lists where ID = @ListID) = 1
		RETURN

	--Also delete the personal priority set containing this list
	DELETE Priorities_ListSets
	FROM Priorities_ListSets ls
	JOIN Priorities_ListSetLists lsl
		ON lsl.SetID = ls.ID
		AND lsl.ListID = @ListID
	WHERE ls.PersonalSet = 1

	--And any references to the list in other priority list sets
	DELETE FROM Priorities_ListSetLists 
	WHERE ListID = @ListID
		
	DELETE FROM Priorities_Lists
	WHERE ID = @ListID	
END
GO

/****** Object:  StoredProcedure [dbo].[QCheck_GetSupervisedUsersForSchedule]    Script Date: 6/4/2024 4:45:12 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
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
			AND s.AsOf < GETDATE()
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
