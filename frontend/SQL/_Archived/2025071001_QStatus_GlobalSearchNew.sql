/****** Object:  StoredProcedure [dbo].[QStatus_GlobalSearchNew]    Script Date: 7/10/2025 4:13:40 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER   proc [dbo].[QStatus_GlobalSearchNew] 
--DECLARE
	@userIDs varchar(4000),-- = '',	-- separated by commas or leave blank
	@criteria varchar(4000),-- = '("Final Test" AND QProcess) OR "oncall"',-- can be blank
	@logicAndOr bit = null,		-- 1 = AND, 0 = OR, NULL = "advanced"
	@userId int,-- = 715,
	@reportId int = null,
	@includeTaskName bit = 1,
	@includeItemText bit = 1,
	@includeComment bit = 1,
	@includeArchive bit = 1,
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

	--EXEC QStatus_GlobalSearch @userIDs = '', @criteria = 'determine impact', @logicAndOr = 1, @userId = 74, @reportId = 10606, @includeArchive = 0

	-- if not admin, then lock user into only viewing items they are/were assignee/controller
	DECLARE @isAdmin BIT = 0, @loginId INT = 0, @needTruncating BIT = 0, @count INT = 0
	SELECT @isAdmin = [admin], @loginId = ID
	FROM QCheck_Users
	WHERE IsDeleted = 0 AND ID = @userId

	IF @isAdmin <> 1 SET @userIDs = CAST(@loginId AS VARCHAR(4000))

	DROP TABLE IF EXISTS #grp
	DROP TABLE IF EXISTS #checklist
	DROP TABLE IF EXISTS #checklistArchive
	DROP TABLE IF EXISTS #allChecklist
	DROP TABLE IF EXISTS #allowedChecklist
	DROP TABLE IF EXISTS #allowedChecklistArchive
	DROP TABLE IF EXISTS #result
	DROP TABLE IF EXISTS #resultArchive

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
			AND ac.DueTime >= ISNULL(@fromDate, ac.DueTime)
			AND ac.DueTime <= ISNULL(@toDate, ac.DueTime)
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
			AND ac.DueTime >= ISNULL(@fromDate, ac.DueTime)
			AND ac.DueTime <= ISNULL(@toDate, ac.DueTime)
		GROUP BY c.ID
	END

	DECLARE @exec VARCHAR(max) = '',
			@first BIT = NULL,
			@word VARCHAR(255) = '',
			@contain VARCHAR(max) = ''

	IF @logicAndOr IS NULL BEGIN
		DECLARE @i INT = 1, @j int, @k int, @isCrit bit = 0
		DECLARE @len INT = LEN(@criteria)
		DECLARE @c NCHAR(1), @d NCHAR(4)
		DECLARE @parts Table (part varchar(4000))

		WHILE @i <= @len
		BEGIN
			SET @c = SUBSTRING(@criteria, @i, 1);
			SET @isCrit = 1
			
			IF @c = ';' RETURN --guard clause for SQL injection
			ELSE IF @c = ' '
			BEGIN
				SET @i = @i+1		
				SET @isCrit = 0
			END
			ELSE IF @c IN ('(', ')')
			BEGIN
				INSERT INTO @parts VALUES (@c)
				SET @i = @i+1
				SET @isCrit = 0
			END
			ELSE IF @c = '"'
			BEGIN
				SET @j = CHARINDEX('"', @criteria, @i+1)
				IF @j < @i SET @j = @len+1
				INSERT INTO @parts VALUES (SUBSTRING(@criteria, @i+1, @j-@i-1))
				SET @i = @j+1		
				SET @isCrit = 0
			END
			ELSE IF @c = 'N'
			BEGIN
				SET @d = SUBSTRING(@criteria, @i, 4);
				IF TRIM(@d) = 'NOT'
				BEGIN
					INSERT INTO @parts VALUES('NOT')
					SET @i = @i+4
				SET @isCrit = 0
				END
			END
			ELSE IF @c = 'A'
			BEGIN
				SET @d = SUBSTRING(@criteria, @i, 4);
				IF TRIM(@d) = 'AND'
				BEGIN
					INSERT INTO @parts VALUES('AND')
					SET @i = @i+4
				SET @isCrit = 0
				END
			END
			ELSE IF @c = 'O'
			BEGIN
				SET @d = SUBSTRING(@criteria, @i, 3);
				IF TRIM(@d) = 'OR'
				BEGIN
					INSERT INTO @parts VALUES('OR')
					SET @i = @i+3
					SET @isCrit = 0
				END
			END
	
			IF @isCrit = 1
			BEGIN
				SET @j = CHARINDEX(')', @criteria, @i+1)
				SET @k = CHARINDEX(' ', @criteria, @i+1)
				IF @j < @i OR @j > @k
					SET @j = @k
			
				IF @j < @i SET @j = @len+1
				INSERT INTO @parts VALUES (SUBSTRING(@criteria, @i, @j-@i))
				SET @i = CASE WHEN @j = @k THEN @j+1 ELSE @j END
			END

		END

		UPDATE @parts SET part = 'CONTAINS([Content], N''"' + part + '"'')' WHERE part NOT IN ('(', ')', 'AND', 'OR', 'NOT')

		--SELECT * FROM @parts

		SELECT @contain = STRING_AGG(part, ' ') FROM @Parts
		--SELECT @contain
	END ELSE BEGIN
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

		IF @contain <> '' SET @contain = 'CONTAINS([Content], N''' + @contain + ''')'
	END	

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

	BEGIN TRANSACTION
		EXEC sp_getapplock @Resource = 'TaskContentLock', @LockMode = 'Exclusive', @LockOwner = 'Transaction';

		SET @exec = 'insert into #allChecklist select ChecklistId, 0 from TaskContent with (nolock) where ' + @contain; EXEC(@exec)
	
		IF @includeArchive = 1
			SET @exec = 'insert into #allChecklist select ChecklistId, 1 from TaskContentArchive with (nolock) where ' + @contain; EXEC(@exec)

	COMMIT TRANSACTION
	--IF @includeTaskName = 1 BEGIN
	--	SET @exec = 'insert into #allChecklist select ID, 0 from QCheck_Checklists with (nolock) where ' + @contain; EXEC(@exec)
		
	--	IF @includeArchive = 1
	--		SET @exec = 'insert into #allChecklist select ID, 1 from QCheck_ChecklistArchive with (nolock) where ' + @contain; EXEC(@exec)
	--END

	--IF @includeItemText = 1 BEGIN
	--	SET @exec = 'insert into #allChecklist select ChecklistID, 0 from QCheck_Items with (nolock) where ' + REPLACE(@contain, '[Name]', '[Text]'); EXEC(@exec)
		
	--	IF @includeArchive = 1
	--		SET @exec = 'insert into #allChecklist select ChecklistID, 1 from QCheck_ItemArchive with (nolock) where ' + REPLACE(@contain, '[Name]', '[Text]'); EXEC(@exec)
	--END

	--IF @includeComment = 1 BEGIN
	--	SET @exec = 'insert into #allChecklist select aa.ChecklistID, 0 from QStatus_Comments c with (nolock) inner join QCheck_ActiveChecklists a with (nolock) on a.ID = c.ForeignKeyID inner join QCheck_ChecklistInstances aa with (nolock) on aa.ID = a.InstanceID where specialtask=0 and ' + REPLACE(@contain, '[Name]', '[Comments]'); EXEC(@exec)
		
	--	IF @includeArchive = 1
	--		SET @exec = 'insert into #allChecklist select aa.ChecklistID, 1 from QStatus_CommentArchive c with (nolock) inner join QCheck_ActiveChecklistArchive a with (nolock) on a.ID = c.ForeignKeyID inner join QCheck_ChecklistInstances_All aa with (nolock) on aa.ID = a.InstanceID where specialtask=0 and ' + REPLACE(@contain, '[Name]', '[Comments]'); EXEC(@exec)
	--END

	--select @exec

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
	select distinct 
		i.ChecklistID,
		a.IsDeleted,
		0 as Archived,
		c.Name as Task,
		dbo.QCheck_ScheduleString(i.ScheduleID) AS ScheduleString,
		comments = (SELECT STRING_AGG(CONVERT(NVARCHAR(MAX),cmt), '') FROM (
			SELECT TOP (1)
		   cmt = char(9) + '[' + CONVERT(varchar, cm.CommentDt, 101) + '] [' + cm.Initials + '] ' + cm.Comments + '<br>'
	FROM 
		   #checklist c 
		   INNER JOIN QCheck_ChecklistInstances_All ci
				  ON c.ID = ci.ChecklistID
		   INNER JOIN QCheck_ActiveChecklists_All ac
				  ON ci.ID = ac.InstanceID
		   INNER JOIN QStatus_Comments_All cm
				  ON cm.ForeignKeyID = ac.ID
				  AND cm.SpecialTask = 0
		WHERE c.ID = i.ChecklistID
		ORDER BY cm.CommentDt DESC
		   
	--union all SELECT 
	--	   cmt = char(9) + '[' + CONVERT(varchar, cm.CommentDt, 101) + '] [' + cm.Initials + '] ' + cm.Comments
	--FROM 
	--	   #checklistArchive c 
	--	   INNER JOIN QCheck_ChecklistInstances_All ci
	--			  ON c.ID = ci.ChecklistID
	--	   INNER JOIN QCheck_ActiveChecklistArchive ac
	--			  ON ci.ID = ac.InstanceID
	--	   INNER JOIN QStatus_CommentArchive cm
	--			  ON cm.ForeignKeyID = ac.ID
	--			  AND cm.SpecialTask = 0
	) xc)
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

	select distinct
		i.ChecklistID,
		a.IsDeleted,
		1 as Archived,
		c.Name as Task,
		dbo.QCheck_ScheduleStringArchive(i.ScheduleID) AS ScheduleString,
		comments =''
		   
	--union all SELECT 
	--	   cmt = char(9) + '[' + CONVERT(varchar, cm.CommentDt, 101) + '] [' + cm.Initials + '] ' + cm.Comments
	--FROM 
	--	   #checklistArchive c 
	--	   INNER JOIN QCheck_ChecklistInstances_All ci
	--			  ON c.ID = ci.ChecklistID
	--	   INNER JOIN QCheck_ActiveChecklistArchive ac
	--			  ON ci.ID = ac.InstanceID
	--	   INNER JOIN QStatus_CommentArchive cm
	--			  ON cm.ForeignKeyID = ac.ID
	--			  AND cm.SpecialTask = 0
				 -- ) xc)
	into #resultArchive
	from 
		QCheck_AssignmentArchive a with (nolock)
		inner join QCheck_ChecklistInstances_All i with (nolock) on a.InstanceID = i.ID 
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
		and @includeArchive = 1

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
		--'[' + convert(varchar, ct.CommentDt, 101) + '] [' + ct.Initials + '] ' + ct.Comments as Comments,
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
		--'[' + convert(varchar, ct.CommentDt, 101) + '] [' + ct.Initials + '] ' + ct.Comments as Comments,
		it.Text as ItemText
	from #resultArchive r
	left outer join 
		QCheck_ChecklistInstances_All i with (nolock) on i.ID = 
		(select max(ID) from QCheck_ChecklistInstances_All with (nolock) where ChecklistID = r.ChecklistID)
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