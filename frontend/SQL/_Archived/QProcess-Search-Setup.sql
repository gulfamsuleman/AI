
-- Enable Full-Text Index on your table
CREATE FULLTEXT CATALOG GlobalSearchCatalog AS DEFAULT;
-- task
CREATE FULLTEXT INDEX ON QCheck_Checklists([Name]) KEY INDEX PK_QCheck_Checklists;
CREATE FULLTEXT INDEX ON QCheck_ChecklistArchive([Name]) KEY INDEX PK_QCheck_ChecklistArchive;

-- items
CREATE FULLTEXT INDEX ON QCheck_Items([Text]) KEY INDEX PK_QCheck_Items;
CREATE FULLTEXT INDEX ON QCheck_ItemArchive([Text]) KEY INDEX PK_QCheck_ItemArchive;

-- comments
CREATE FULLTEXT INDEX ON QStatus_Comments(Comments) KEY INDEX PK_QStatus_Comments;
CREATE FULLTEXT INDEX ON QStatus_CommentArchive(Comments) KEY INDEX PK_QStatus_CommentArchive;

CREATE TABLE dbo.QCheck_SearchHistory (
	Id UNIQUEIDENTIFIER NOT NULL DEFAULT(NEWSEQUENTIALID()) PRIMARY KEY,
	UserId INT NOT NULL,
	Criteria VARCHAR(500) NOT NULL,
	LastUpdated DATETIME NOT NULL DEFAULT(GETUTCDATE())
)
GO
CREATE INDEX ixQCheck_SearchHistory ON QCheck_SearchHistory(
	UserId ASC, LastUpdated DESC
) INCLUDE (Criteria)
GO
CREATE INDEX ixQCheck_SearchHistoryCriteria ON QCheck_SearchHistory(
	UserId ASC, Criteria ASC, LastUpdated DESC
)
GO
CREATE PROC dbo.QCheck_GetSearchHistory
	@userId int,
	@criteria varchar(500) = null
AS
BEGIN
	SET NOCOUNT ON

	IF @criteria IS NULL BEGIN
		SELECT TOP 10 Criteria
		FROM dbo.QCheck_SearchHistory
		WHERE UserId = @userId
		ORDER BY LastUpdated DESC
	END ELSE BEGIN
		SELECT TOP 10 Criteria
		FROM dbo.QCheck_SearchHistory
		WHERE UserId = @userId AND Criteria LIKE '%' + @criteria + '%'
		ORDER BY LastUpdated DESC
	END
END
GO

CREATE OR ALTER proc [dbo].[QStatus_MyStatusSearch] 
	@criteria varchar(4000),-- can be blank
	@logicAndOr bit,		-- 1 = AND, 0 = OR
	@userId int,
	@reportId int,
	@includeTaskName bit = 1,
	@includeItemText bit = 1,
	@includeComment bit = 1,
	@includeArchive bit = 1,
	@fromDate datetime = null,
	@toDate datetime = null
AS
BEGIN
	--EXEC QStatus_MyStatusSearch @criteria = 'credence', @logicAndOr = 1, @userId = 74, @reportId = 10186

	SET NOCOUNT ON
	IF TRIM(ISNULL(@criteria, '')) = '' RETURN

	UPDATE dbo.QCheck_SearchHistory
	SET LastUpdated = GETUTCDATE()
	WHERE UserId = @userId AND Criteria = @criteria

	IF @@ROWCOUNT = 0 BEGIN
		INSERT INTO dbo.QCheck_SearchHistory (UserId, Criteria) VALUES (@userId, @criteria)
	END

	-- variable declaration
	CREATE TABLE #allChecklist (Id INT, Archive BIT)
	CREATE TABLE #allowedChecklist (Id INT NOT NULL, ActiveChecklistId INT NOT NULL)
	CREATE TABLE #allowedChecklistArchive (Id INT NOT NULL, ActiveChecklistId INT NOT NULL)

	INSERT INTO #allowedChecklist
	SELECT 
		ChecklistId = c.ID, ActiveChecklistId = ac.ID
	FROM 
		QStatus_TaskTypes tt
		INNER JOIN QStatus_ActiveChecklistTaskType actt
			ON actt.TaskType = tt.ID
		INNER JOIN QCheck_ActiveChecklists ac
			ON ac.ID = actt.ActiveChecklistID
		INNER JOIN qcheck_checklistinstances ci
			ON ci.ID = ac.InstanceID
		INNER JOIN qcheck_checklists c
			ON ci.ChecklistID = c.ID
	WHERE 1 = 1
		AND tt.ReportID = @reportId
		AND tt.IsDeleted = 0
		AND tt.NativeType = 0
		AND ac.DueTime >= ISNULL(@fromDate, ac.DueTime)
		AND ac.DueTime <= ISNULL(@toDate, ac.DueTime)
	GROUP BY c.ID, ac.ID

	INSERT INTO #allowedChecklistArchive
	SELECT
		ChecklistId = c.ID, ActiveChecklistId = ac.ID
	FROM 
		QStatus_TaskTypes tt
		INNER JOIN QStatus_ActiveChecklistTaskTypeArchive actt
			ON actt.TaskType = tt.ID
		INNER JOIN QCheck_ActiveChecklistArchive ac
			ON ac.ID = actt.ActiveChecklistID
		INNER JOIN QCheck_ChecklistInstanceArchive ci
			ON ci.ID = ac.InstanceID
		INNER JOIN QCheck_ChecklistArchive c
			ON ci.ChecklistID = c.ID
	WHERE 1 = 1
		AND tt.ReportID = @reportId
		AND tt.IsDeleted = 0
		AND tt.NativeType = 0
		AND ac.DueTime >= ISNULL(@fromDate, ac.DueTime)
		AND ac.DueTime <= ISNULL(@toDate, ac.DueTime)
	GROUP BY c.ID, ac.ID

	DECLARE @exec VARCHAR(max) = '',
			@first BIT = NULL,
			@word VARCHAR(255) = '',
			@contain VARCHAR(max) = ''

	-- build criteria string
	DECLARE oCursor CURSOR FOR
		SELECT [Data] FROM dbo.Util_Split(@criteria,' ')

	OPEN oCursor
	FETCH NEXT FROM oCursor INTO @word
	WHILE @@FETCH_STATUS = 0 BEGIN
		set @word = REPLACE(@word, '''', '''''')

		if @first is null
			begin
				set @first = 0
				--set @cmd = @cmd + ' [Name] like ''%' + @word + '%'''
				set @contain = @contain + '"' + @word + '*"'
			end
		else
			begin
				if @logicAndOr = 0
					begin
						--set @cmd = @cmd + ' or [Name] like ''%' + @word + '%'''
						set @contain = @contain + ' OR "' + @word + '*"'
					end
				else
					begin
						--set @cmd = @cmd + ' and [Name] like ''%' + @word + '%'''
						set @contain = @contain + ' AND "' + @word + '*"'
					end
			end
		
		fetch next from oCursor into @word
	END
	CLOSE oCursor
	DEALLOCATE oCursor

	IF @contain <> '' SET @contain = 'CONTAINS([Name], ''' + @contain + ''')'

	IF @includeTaskName = 1 BEGIN
		SET @exec = 'insert into #allChecklist select ID, 0 from QCheck_Checklists with (nolock) where ' + @contain; EXEC(@exec)

		IF @includeArchive = 1
			SET @exec = 'insert into #allChecklist select ID, 1 from QCheck_ChecklistArchive with (nolock) where ' + @contain; EXEC(@exec)
	END

	IF @includeItemText = 1 BEGIN
		SET @exec = 'insert into #allChecklist select ChecklistID, 0 from QCheck_Items with (nolock) where ' + REPLACE(@contain, '[Name]', '[Text]'); EXEC(@exec)
		
		IF @includeArchive = 1
			SET @exec = 'insert into #allChecklist select ChecklistID, 1 from QCheck_ItemArchive with (nolock) where ' + REPLACE(@contain, '[Name]', '[Text]'); EXEC(@exec)
	END

	IF @includeComment = 1 BEGIN
		SET @exec = 'insert into #allChecklist select aa.ChecklistID, 0 from QStatus_Comments c with (nolock) inner join QCheck_ActiveChecklists a with (nolock) on a.ID = c.ForeignKeyID inner join QCheck_ChecklistInstances aa with (nolock) on aa.ID = a.InstanceID where specialtask=0 and ' + REPLACE(@contain, '[Name]', '[Comments]'); EXEC(@exec)
		
		IF @includeArchive = 1
			SET @exec = 'insert into #allChecklist select aa.ChecklistID, 1 from QStatus_CommentArchive c with (nolock) inner join QCheck_ActiveChecklistArchive a with (nolock) on a.ID = c.ForeignKeyID inner join QCheck_ChecklistInstanceArchive aa with (nolock) on aa.ID = a.InstanceID where specialtask=0 and ' + REPLACE(@contain, '[Name]', '[Comments]'); EXEC(@exec)
	END

	SELECT c.ActiveChecklistId
	FROM #allowedChecklist c
	INNER JOIN #allChecklist sc 
		ON sc.Id = c.Id AND sc.Archive = 0
	GROUP BY c.ActiveChecklistId


	SELECT DISTINCT 
		--ActiveChecklistIdArchive = ac.ID, 
		Task = ISNULL(ca.[Name], c.[Name]),
		DueTime = CONVERT(CHAR(10), ac.DueTime, 101),
		assignees = isnull(al.assignees, ''),
		controllers = isnull(dbo.QCheck_ManagersList(ISNULL(cia.ChecklistID, ci.ChecklistID)), ''),
		comments = (SELECT STRING_AGG(CONVERT(NVARCHAR(MAX),cmt), '') FROM (
			SELECT 
				 cmt = '<div>[' + CONVERT(VARCHAR(10), c.CommentDt, 101) + '] [' + c.Initials + '] ' + c.Comments + '</div>'
			FROM
				QStatus_COMMENTS C
			WHERE c.ForeignKeyID = ac.ID

			UNION ALL SELECT 
				 cmt = '<div>[' + CONVERT(VARCHAR(10), c.CommentDt, 101) + '] [' + c.Initials + '] ' + c.Comments + '</div>'
			FROM
				QStatus_commentarchive C
			WHERE c.ForeignKeyID = ac.ID) xc)
	FROM
		QStatus_ActiveChecklistTaskType actt
		INNER JOIN QStatus_TaskTypes	tt
			ON actt.TaskType = tt.ID AND tt.IsDeleted = 0
		INNER JOIN QCheck_ActiveChecklistArchive ac
			ON ac.ID = actt.ActiveChecklistID
		INNER JOIN QCheck_ActiveAssignmentArchive aa
			ON aa.ActiveChecklistID = ac.ID
		LEFT OUTER JOIN QCheck_ChecklistInstanceArchive cia
			ON ac.InstanceID = cia.[ID]
		LEFT OUTER JOIN QCheck_ChecklistArchive ca
			ON ca.ID = cia.ChecklistID
		-- 2/26/2013 dalvarado - found cases where the instance wasn't archived with the active checklist, so need to look
		-- in both checklistinstances and checklistinstancearchive.
		LEFT OUTER JOIN qcheck_checklistinstances ci
			ON ac.InstanceID = ci.ID
		LEFT OUTER JOIN QCheck_Checklists c
			ON c.ID = ci.ChecklistID
		LEFT OUTER JOIN qcheck_assigneelookup al
			ON al.instanceid = ac.instanceid
	WHERE ac.ID IN (
		SELECT c.ActiveChecklistId
		FROM #allowedChecklistArchive c
		INNER JOIN #allChecklist sc 
			ON sc.Id = c.Id AND sc.Archive = 1
		GROUP BY c.ActiveChecklistId
	)
	-- remove below for production
	-- test code to make sure at least 10 comments are returned
	--UNION ALL
	--SELECT TOP 10
	--	--ActiveChecklistIdArchive = ac.ID, 
	--	Task = ISNULL(ca.[Name], c.[Name]),
	--	DueTime = CONVERT(CHAR(10), ac.DueTime, 101),
	--	assignees = isnull(al.assignees, ''),
	--	controllers = isnull(dbo.QCheck_ManagersList(ISNULL(cia.ChecklistID, ci.ChecklistID)), ''),
	--	comments = (SELECT STRING_AGG(cmt, '') FROM (
	--		SELECT 
	--			 cmt = '<div>[' + CONVERT(VARCHAR(10), c.CommentDt, 101) + '] [' + c.Initials + '] ' + c.Comments + '</div>'
	--		FROM
	--			QStatus_COMMENTS C
	--		WHERE c.ForeignKeyID = ac.ID

	--		UNION ALL SELECT 
	--			 cmt = '<div>[' + CONVERT(VARCHAR(10), c.CommentDt, 101) + '] [' + c.Initials + '] ' + c.Comments + '</div>'
	--		FROM
	--			QStatus_commentarchive C
	--		WHERE c.ForeignKeyID = ac.ID) xc)
	--FROM
	--	QStatus_ActiveChecklistTaskType actt
	--	INNER JOIN QStatus_TaskTypes	tt
	--		ON actt.TaskType = tt.ID AND tt.IsDeleted = 0
	--	INNER JOIN QCheck_ActiveChecklistArchive ac
	--		ON ac.ID = actt.ActiveChecklistID
	--	INNER JOIN QCheck_ActiveAssignmentArchive aa
	--		ON aa.ActiveChecklistID = ac.ID
	--	LEFT OUTER JOIN QCheck_ChecklistInstanceArchive cia
	--		ON ac.InstanceID = cia.[ID]
	--	LEFT OUTER JOIN QCheck_ChecklistArchive ca
	--		ON ca.ID = cia.ChecklistID
	--	-- 2/26/2013 dalvarado - found cases where the instance wasn't archived with the active checklist, so need to look
	--	-- in both checklistinstances and checklistinstancearchive.
	--	LEFT OUTER JOIN qcheck_checklistinstances ci
	--		ON ac.InstanceID = ci.ID
	--	LEFT OUTER JOIN QCheck_Checklists c
	--		ON c.ID = ci.ChecklistID
	--	LEFT OUTER JOIN qcheck_assigneelookup al
	--		ON al.instanceid = ac.instanceid
	--WHERE
	--	tt.ReportID = 10794
END
GO
CREATE OR ALTER proc [dbo].[QStatus_GlobalSearch] 
	@userIDs varchar(4000),	-- separated by commas or leave blank
	@criteria varchar(4000),-- can be blank
	@logicAndOr bit,		-- 1 = AND, 0 = OR
	@userId int,
	@reportId int = null,
	@includeTaskName bit = 1,
	@includeItemText bit = 1,
	@includeComment bit = 1,
	@fromDate date = null,
	@toDate date = null
AS
BEGIN
	SET NOCOUNT ON
	IF TRIM(ISNULL(@criteria, '')) = '' RETURN

	UPDATE dbo.QCheck_SearchHistory
	SET LastUpdated = GETUTCDATE()
	WHERE UserId = @userId AND Criteria = @criteria

	IF @@ROWCOUNT = 0 BEGIN
		INSERT INTO dbo.QCheck_SearchHistory (UserId, Criteria) VALUES (@userId, @criteria)
	END

	--EXEC QStatus_GlobalSearch @userIDs = '', @criteria = 'determine impact', @logicAndOr = 1, @userId = 74, @reportId = 10606

	-- if not admin, then lock user into only viewing items they are/were assignee/controller
	DECLARE @isAdmin BIT = 0, @loginId INT = 0, @needTruncating BIT = 0, @count INT = 0
	SELECT @isAdmin = [admin], @loginId = ID
	FROM QCheck_Users
	WHERE IsDeleted = 0 AND ID = @userId

	IF @isAdmin <> 1 SET @userIDs = CAST(@loginId AS VARCHAR(4000))

	-- variable declaration
	CREATE TABLE #grp (Id int)
	CREATE TABLE #checklist (Id INT NOT NULL PRIMARY KEY)
	CREATE TABLE #checklistArchive (Id INT NOT NULL PRIMARY KEY)
	CREATE TABLE #allChecklist (Id INT, Archive BIT)
	CREATE TABLE #allowedChecklist (Id INT NOT NULL PRIMARY KEY)
	CREATE TABLE #allowedChecklistArchive (Id INT NOT NULL PRIMARY KEY)

	-- restrict to a specific status report
	IF ISNULL(@reportId, 0) <> 0 BEGIN
		INSERT INTO #allowedChecklist
		SELECT 
			ChecklistId = c.ID
		FROM 
			QStatus_TaskTypes tt
			INNER JOIN QStatus_ActiveChecklistTaskType actt
				ON actt.TaskType = tt.ID
			INNER JOIN QCheck_ActiveChecklists ac
				ON ac.ID = actt.ActiveChecklistID
			INNER JOIN qcheck_checklistinstances ci
				ON ci.ID = ac.InstanceID
			INNER JOIN qcheck_checklists c
				ON ci.ChecklistID = c.ID
		WHERE 1 = 1
			AND tt.ReportID = @reportId
			AND tt.IsDeleted = 0
			AND tt.NativeType = 0
		GROUP BY c.ID

		INSERT INTO #allowedChecklistArchive
		SELECT
			ChecklistId = c.ID
		FROM 
			QStatus_TaskTypes tt
			INNER JOIN QStatus_ActiveChecklistTaskTypeArchive actt
				ON actt.TaskType = tt.ID
			INNER JOIN QCheck_ActiveChecklistArchive ac
				ON ac.ID = actt.ActiveChecklistID
			INNER JOIN QCheck_ChecklistInstanceArchive ci
				ON ci.ID = ac.InstanceID
			INNER JOIN QCheck_ChecklistArchive c
				ON ci.ChecklistID = c.ID
		WHERE 1 = 1
			AND tt.ReportID = @reportId
			AND tt.IsDeleted = 0
			AND tt.NativeType = 0
		GROUP BY c.ID
	END

	DECLARE @exec VARCHAR(max) = '',
			@first BIT = NULL,
			@word VARCHAR(255) = '',
			@contain VARCHAR(max) = ''

	-- build criteria string
	DECLARE oCursor CURSOR FOR
		SELECT [Data] FROM dbo.Util_Split(@criteria,' ')

	OPEN oCursor
	FETCH NEXT FROM oCursor INTO @word
	WHILE @@FETCH_STATUS = 0 BEGIN
		set @word = REPLACE(@word, '''', '''''')

		if @first is null
			begin
				set @first = 0
				--set @cmd = @cmd + ' [Name] like ''%' + @word + '%'''
				set @contain = @contain + '"' + @word + '*"'
			end
		else
			begin
				if @logicAndOr = 0
					begin
						--set @cmd = @cmd + ' or [Name] like ''%' + @word + '%'''
						set @contain = @contain + ' OR "' + @word + '*"'
					end
				else
					begin
						--set @cmd = @cmd + ' and [Name] like ''%' + @word + '%'''
						set @contain = @contain + ' AND "' + @word + '*"'
					end
			end
		
		fetch next from oCursor into @word
	END
	CLOSE oCursor
	DEALLOCATE oCursor

	IF @contain <> '' SET @contain = 'CONTAINS([Name], ''' + @contain + ''')'

	-- filter out matches by IDs
	if @userIDs = ''
		begin
			insert into #grp
				select ID from QCheck_Groups
				union all
				select ID from QCheck_GroupArchive
		end
	else
		begin
			insert into #grp
				select 
					GroupID
				from 
					QCheck_GroupChanges with (nolock) 
				where 
					UserID in (select Data from dbo.Util_split(@userIDs, ','))
				union 
				select
					ID
				from
					QCheck_Groups with (nolock) 
				where 
					[Owner] in (select Data from dbo.Util_split(@userIDs, ','))

		end

	IF @includeTaskName = 1 BEGIN
		SET @exec = 'insert into #allChecklist select ID, 0 from QCheck_Checklists with (nolock) where ' + @contain; EXEC(@exec)
		SET @exec = 'insert into #allChecklist select ID, 1 from QCheck_ChecklistArchive with (nolock) where ' + @contain; EXEC(@exec)
	END

	IF @includeItemText = 1 BEGIN
		SET @exec = 'insert into #allChecklist select ChecklistID, 0 from QCheck_Items with (nolock) where ' + REPLACE(@contain, '[Name]', '[Text]'); EXEC(@exec)
		SET @exec = 'insert into #allChecklist select ChecklistID, 1 from QCheck_ItemArchive with (nolock) where ' + REPLACE(@contain, '[Name]', '[Text]'); EXEC(@exec)
	END

	IF @includeComment = 1 BEGIN
		SET @exec = 'insert into #allChecklist select aa.ChecklistID, 0 from QStatus_Comments c with (nolock) inner join QCheck_ActiveChecklists a with (nolock) on a.ID = c.ForeignKeyID inner join QCheck_ChecklistInstances aa with (nolock) on aa.ID = a.InstanceID where specialtask=0 and ' + REPLACE(@contain, '[Name]', '[Comments]'); EXEC(@exec)
		SET @exec = 'insert into #allChecklist select aa.ChecklistID, 1 from QStatus_CommentArchive c with (nolock) inner join QCheck_ActiveChecklistArchive a with (nolock) on a.ID = c.ForeignKeyID inner join QCheck_ChecklistInstanceArchive aa with (nolock) on aa.ID = a.InstanceID where specialtask=0 and ' + REPLACE(@contain, '[Name]', '[Comments]'); EXEC(@exec)
	END

	-- remove duplicates
	INSERT INTO #checklist SELECT Id FROM #allChecklist WHERE Archive = 0 GROUP BY Id
	INSERT INTO #checklistArchive SELECT Id FROM #allChecklist WHERE Archive = 1 GROUP BY Id
	DROP TABLE #allChecklist

	-- restrict to provided status report Id
	IF @reportId IS NOT NULL BEGIN
		DELETE c
		FROM #checklist c
		LEFT OUTER JOIN #allowedChecklist sc ON sc.Id = c.Id
		WHERE sc.Id IS NULL

		DELETE c
		FROM #checklistArchive c
		INNER JOIN #allowedChecklistArchive sc ON sc.Id = c.Id
		WHERE sc.Id IS NULL
	END

	-- get result
	select distinct top 101
		i.ChecklistID,
		a.IsDeleted,
		0 as Archived,
		c.Name as Task,
		dbo.QCheck_ScheduleString(i.ScheduleID) AS ScheduleString
	into #result
	from 
		QCheck_Assignments a with (nolock) 
		inner join QCheck_ChecklistInstances i with (nolock) on a.InstanceID = i.ID
		inner join QCheck_ActiveChecklists aa with (nolock) on i.ID = aa.InstanceID
		inner join QCheck_Checklists c with (nolock) on i.ChecklistID = c.ID
		inner join #checklist cl on cl.Id = c.ID
		left outer join QCheck_ChecklistManagers cm with (nolock) on cm.ChecklistID = c.ID
	where   
		(   --assigned or controlled
			a.GroupID in (select Id from #grp) 
			or isnull(cm.ManagerGroupID, 0) in (select Id from #grp)
		)
		and aa.DueTime >= ISNULL(@fromDate, aa.DueTime) and aa.DueTime <= ISNULL(@toDate, aa.DueTime)

	IF @@ROWCOUNT > 100 BEGIN
		SET @needTruncating = 1
		DELETE TOP (1) FROM #result
	END

	select distinct top 101
		i.ChecklistID,
		a.IsDeleted,
		1 as Archived,
		c.Name as Task,
		dbo.QCheck_ScheduleStringArchive(i.ScheduleID) AS ScheduleString
	into #resultArchive
	from 
		QCheck_AssignmentArchive a with (nolock)
		inner join QCheck_ChecklistInstanceArchive i with (nolock) on a.InstanceID = i.ID 
		inner join QCheck_ActiveChecklistArchive aa with (nolock) on i.ID = aa.InstanceID
		inner join QCheck_ChecklistArchive c with (nolock) on i.ChecklistID = c.ID
		inner join #checklistArchive cl on cl.Id = c.ID
		left outer join QCheck_ChecklistManagerArchive cm with (nolock) on cm.ChecklistID = c.ID
	where   
		(--assigned or controlled
			a.GroupID in (select Id from #grp) 
			or isnull(cm.ManagerGroupID, 0) in (select Id from #grp)
		)
		and aa.DueTime >= ISNULL(@fromDate, aa.DueTime) and aa.DueTime <= ISNULL(@toDate, aa.DueTime)

	IF @@ROWCOUNT > 100 BEGIN
		SET @needTruncating = 1
		DELETE TOP (1) FROM #resultArchive
	END

	select
		r.*,
		convert(varchar, aa.CompletedDate, 100) as CompletedDate,
		isnull(ccl.controllers, '') as Controllers,
		dbo.Util_StripHTML(replace(isnull((select top 1 ReportsList from QStatus_TaskReportList where ActiveChecklistID = aa.ID), ''),'Status Reports: ','')) as StatusReport,
		isnull(al.assignees,'') as Assignees,
		'[' + convert(varchar, ct.CommentDt, 101) + '] [' + ct.Initials + '] ' + ct.Comments as Comments,
		it.Text as ItemText
	from #result r
	left outer join 
		QCheck_ChecklistInstances i with (nolock) on i.ID = 
		(select max(ID) from QCheck_ChecklistInstances with (nolock) where ChecklistID = r.ChecklistID)
	left outer join 
		QCheck_ActiveChecklists aa with (nolock) on aa.ID =
		(select max(ID) from QCheck_ActiveChecklists with (nolock) where InstanceID = i.ID)
	left outer join 
		QCheck_ChecklistControllersList ccl on ccl.checklistid = r.ChecklistID
	left outer join 
		QCheck_AssigneeLookup AL on aa.InstanceID = al.InstanceID
	left outer join
		QStatus_Comments ct on ct.ForeignKeyID = aa.ID and ct.DisplayOrder = 1
	left outer join
		QCheck_Items it with (nolock)  on it.ID = 
		(select min(ID) from QCheck_Items with (nolock) where ChecklistID = r.ChecklistID)
			
	union all select
		r.*
		,
		convert(varchar, aa.CompletedDate, 100) as CompletedDate,
		dbo.QStatus_GetChecklistControllerArchive(i.ChecklistID) as Controllers,
		replace(isnull(dbo.QStatus_GetChecklistReportArchive(aa.ID),''),'Status Reports: ','') as StatusReport,
		dbo.QCheck_FullAssigneesListArchive(i.ID) as Assignees,
		'[' + convert(varchar, ct.CommentDt, 101) + '] [' + ct.Initials + '] ' + ct.Comments as Comments,
		it.Text as ItemText
	from #resultArchive r
	left outer join 
		QCheck_ChecklistInstanceArchive i with (nolock) on i.ID = 
		(select max(ID) from QCheck_ChecklistInstanceArchive with (nolock) where ChecklistID = r.ChecklistID)
	left outer join 
		QCheck_ActiveChecklistArchive aa with (nolock) on aa.ID =
		(select max(ID) from QCheck_ActiveChecklistArchive with (nolock) where InstanceID = i.ID)
	left outer join
		QStatus_CommentArchive ct on ct.ForeignKeyID = aa.ID and ct.DisplayOrder = 1
	left outer join
		QCheck_ItemArchive it with (nolock)  on it.ID = 
		(select min(ID) from QCheck_ItemArchive with (nolock) where ChecklistID = r.ChecklistID)

	SELECT @needTruncating
END
GO
CREATE OR ALTER proc [dbo].[QStatus_MyTaskSearch] 
	@criteria varchar(4000),-- can be blank
	@logicAndOr bit,		-- 1 = AND, 0 = OR
	@userId int,
	@includeTaskName bit = 1,
	@includeItemText bit = 1,
	@includeComment bit = 1,
	@fromDate datetime = null,
	@toDate datetime = null
AS
BEGIN
	--EXEC QStatus_MyTaskSearch @criteria = 'credence', @logicAndOr = 1, @userId = 74, @fromDate = '2025-01-29 06:00:00', @toDate = '2025-02-13 06:00:00'

	SET NOCOUNT ON
	IF TRIM(ISNULL(@criteria, '')) = '' RETURN

	UPDATE dbo.QCheck_SearchHistory
	SET LastUpdated = GETUTCDATE()
	WHERE UserId = @userId AND Criteria = @criteria

	IF @@ROWCOUNT = 0 BEGIN
		INSERT INTO dbo.QCheck_SearchHistory (UserId, Criteria) VALUES (@userId, @criteria)
	END

	-- variable declaration
	CREATE TABLE #allChecklist (Id INT)
	CREATE TABLE #allowedChecklist (Id INT NOT NULL PRIMARY KEY)

	-- get current checklists
	INSERT INTO #allowedChecklist
	SELECT 
		c.ID as ChecklistID
	FROM
		QCheck_ActiveChecklists a 
		INNER JOIN QCheck_ChecklistInstances b ON a.InstanceID = b.ID AND b.IsDeleted = 0
		INNER JOIN QCheck_Schedule s ON b.ScheduleID = s.ID 
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
		LEFT OUTER JOIN QCheck_MostRecentDeadlineRequests mrdr
				ON a.ID = mrdr.ActiveChecklistID
		LEFT OUTER JOIN QCheck_Approval_ChangeRequests cr
			ON cr.ID = mrdr.ChangeRequestID
		LEFT OUTER JOIN QCheck_Approval_ActiveChecklists aac
				ON aac.ChangeRequestID = CR.[ID]
				AND aac.ActiveChecklistID = mrdr.ActiveChecklistID
	WHERE a.dueTime between @fromDate and @toDate

	UNION 
	
	-- get future checklists
	SELECT 
		c.ID As ChecklistID
	FROM
		QCheck_ChecklistInstances b
		INNER JOIN QCheck_UpcomingDueTimes upcoming1
			ON b.ID = upcoming1.instanceID
			and upcoming1.DueTime between @fromDate and @toDate
		INNER JOIN QCheck_Schedule s 
			ON b.ScheduleID = s.ID 
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
		AND ac.ID is null

	DECLARE @exec VARCHAR(max) = '',
			@first BIT = NULL,
			@word VARCHAR(255) = '',
			@contain VARCHAR(max) = ''

	-- build criteria string
	DECLARE oCursor CURSOR FOR
		SELECT [Data] FROM dbo.Util_Split(@criteria,' ')

	OPEN oCursor
	FETCH NEXT FROM oCursor INTO @word
	WHILE @@FETCH_STATUS = 0 BEGIN
		set @word = REPLACE(@word, '''', '''''')

		if @first is null
			begin
				set @first = 0
				--set @cmd = @cmd + ' [Name] like ''%' + @word + '%'''
				set @contain = @contain + '"' + @word + '*"'
			end
		else
			begin
				if @logicAndOr = 0
					begin
						--set @cmd = @cmd + ' or [Name] like ''%' + @word + '%'''
						set @contain = @contain + ' OR "' + @word + '*"'
					end
				else
					begin
						--set @cmd = @cmd + ' and [Name] like ''%' + @word + '%'''
						set @contain = @contain + ' AND "' + @word + '*"'
					end
			end
		
		fetch next from oCursor into @word
	END
	CLOSE oCursor
	DEALLOCATE oCursor

	IF @contain <> '' SET @contain = 'CONTAINS([Name], ''' + @contain + ''')'

	IF @includeTaskName = 1 BEGIN
		SET @exec = 'insert into #allChecklist select ID from QCheck_Checklists with (nolock) where ' + @contain; EXEC(@exec)
	END

	IF @includeItemText = 1 BEGIN
		SET @exec = 'insert into #allChecklist select ChecklistID from QCheck_Items with (nolock) where ' + REPLACE(@contain, '[Name]', '[Text]'); EXEC(@exec)
	END

	IF @includeComment = 1 BEGIN
		SET @exec = 'insert into #allChecklist select aa.ChecklistID from QStatus_Comments c with (nolock) inner join QCheck_ActiveChecklists a with (nolock) on a.ID = c.ForeignKeyID inner join QCheck_ChecklistInstances aa with (nolock) on aa.ID = a.InstanceID where specialtask=0 and ' + REPLACE(@contain, '[Name]', '[Comments]'); EXEC(@exec)
	END

	SELECT c.Id
	FROM #allChecklist c
	INNER JOIN #allowedChecklist sc ON sc.Id = c.Id
	Group BY c.Id
END
GO