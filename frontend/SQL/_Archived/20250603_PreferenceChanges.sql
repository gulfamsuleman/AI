/* [Util_CreateEmailTaskWithPriority] */

CREATE OR ALTER  PROCEDURE [dbo].[Util_CreateEmailTaskWithPriority] (
	@TaskName VARCHAR(1000),
	@CreatedBy int,
	@Assignee int,
	@Controller int,
	@DueDate DATETIME, 
	@Section int = null,
	@Priority int,
	@PriorityUser int = null,
	@Comments varchar(1500) = null,
	@Alert DATETIME = null,
	@SoftDue DATETIME = null,
	@Email bit = 1,
	@TemplateName VARCHAR(500) = ''
) AS
BEGIN
	SET NOCOUNT ON
	if (@priority = 999) select @priority = 99 --999 is reserved for completed tasks

	--Get creating user's time zone
	DECLARE @TimeZone varchar(255)
	SELECT @TimeZone = ISNULL(TimeZoneOverride, LastTimeZone)
	FROM QCheck_Users
	WHERE ID = @CreatedBy
	
	insert into qcheck_emailtasks (TaskName, CreatedBy, CreatedDt)
	select @TaskName, @CreatedBy, GetUtcDate()

	--if this is a QPT for an email2db template, apply the correct section and information
	
	  declare @autosectionID int, @addcreatednote bit = 0

	  select @autosectionID = sectionID, @addcreatednote = creatednote from [Util_Email2DBTasks]
	  where @taskname like triggername + '%'

	  if @autosectionID is not null
	  begin
		if isnull(@addcreatednote, 0) = 1
		Begin
			select @taskname = @taskname + ' - from ' + email + ' - Sent on ' + convert(varchar, dbo.[ConvertTimeFromUtc](getutcdate(), @TimeZone), 101)
			from qcheck_users 
			where id = @createdby 
		End

		select @Section = @autosectionID
	  end

	--midnight by default - set to end of day time that's defaulted for this company
	if datepart(hour, @DueDate) = 0
	begin
		select @DueDate = dateadd(hour, duetime, @DueDate)
		from QCheck_UserDefaultTimes
		where UserID = -1
	end
	-- Get app configuration
	DECLARE @AppURL VARCHAR(50), @ImagesURL VARCHAR(50), @ExternalURL VARCHAR(50), @BaseDomain VARCHAR(50), @FromAddress VARCHAR(50), @AppName VARCHAR(50), @GradingAddress VARCHAR(50), @AutomationAddress VARCHAR(50), @DeveloperAddress VARCHAR(50), @ITAddress VARCHAR(50), @MailServer VARCHAR(50)
	SELECT @AppURL = AppURL, @ImagesURL = ImagesURL, @ExternalURL = ExternalURL, @BaseDomain = BaseDomain, @FromAddress = FromAddress, @Appname = AppName, @GradingAddress = GradingAddress, @AutomationAddress = AutomationAddress, @DeveloperAddress = DeveloperAddress, @ITAddress = ITAddress, @MailServer = MailServer FROM QCheck_AppSettings WHERE ID = 1
	DECLARE 
		@CallingProgram varchar(50),
		@ID int,
		@ReportID int,
		@TaskType int,
		@PrevFreqType int,
		@RowsUpdated int,
		@NewInstanceID int,
		@NewActiveID int,
		@scheduleID int,
		@errorCode int,
		@errorMsg varchar(500),
		@nagBeforeDays int,
		@nagTime int

	SELECT @CallingProgram = @AppName + ' Tasks Email'

-- =======================================================
-- Initialize and validate inputs
-- =======================================================
	SET @errorCode = 0
	SET @errorMsg = ''
	
	--If(_Util.dbo.IsOfficeDay(@DueDate)=0)--added by venkat 09/07/2018
	--Begin
	--set @DueDate=_Util.dbo.NextOfficeDayMaintainTime(@DueDate)
	--End
	IF @SoftDue IS NULL SET @SoftDue = @DueDate
	-- Make sure a calling program was passed in
	IF @ErrorCode = 0 BEGIN
		IF LEN(@CallingProgram) = 0 BEGIN
			SET @ErrorCode = -1000
			SET @ErrorMsg = 'Zero-length calling program was given'
		END
	END
	-- Validate the task name
	IF @ErrorCode = 0 BEGIN
		IF LEN(@TaskName) = 0 BEGIN
			SET @ErrorCode = -1001
			SET @ErrorMsg = 'Zero-length task name was given'
		END
	END
	-- Look up the status report, if one was passed in
	-- @Section = null signifies it isn't meant to be shown on a report
	IF @ErrorCode = 0 AND @Section IS NOT NULL BEGIN
		IF @Section = 0 BEGIN
			--find a section for the group specified
			SELECT top 1 
				@TaskType = tt.ID
			FROM 
				QStatus_Report r
				INNER JOIN QCheck_GroupMembership gm1
					on gm1.GroupID = @Assignee
				INNER JOIN QStatus_GroupReport gr
					ON gr.ReportID = r.ID
				INNER JOIN QCheck_Groups g
					ON g.ID = gr.GroupID
				INNER JOIN QCheck_GroupMembership gm
					ON gm.GroupID = g.ID
					AND gm.UserID = gm1.UserID
				INNER JOIN QStatus_TaskTypes tt
					ON tt.ReportID = r.ID
					AND tt.IsDeleted = 0
					AND tt.NativeType = 0
			WHERE 
				r.IsDeleted = 0
			ORDER BY gr.defaultreport desc, r.ID, tt.displayOrder
		END ELSE BEGIN
			SELECT @TaskType = @Section
		END
		
		IF @TaskType is not null BEGIN
			SELECT @ReportID = ReportID
			FROM QStatus_TaskTypes
			WHERE ID = @TaskType
			IF @ReportID IS NULL BEGIN
				SET @ErrorCode = -1004
				SET @ErrorMsg = 'Could not find status report'
			END
		END
	END
-- =======================================================
-- Set up the checklist
-- =======================================================
	-- Create the task
	IF @ErrorCode = 0 BEGIN
		/*
		EXEC dbo.QCheck_CreateSimple_part1 @ID, @TaskName, 1, @DueDate, @CreatedBy, @TaskType, @PrevFreqType OUTPUT, @RowsUpdated OUTPUT, @NewInstanceID OUTPUT, @NewActiveID OUTPUT, @assignee, 1, 0, @SoftDue			
		SET @errorCode = @@ERROR
		IF @ErrorCode <> 0 SET @errorMsg = 'QCheck_CreateSimple_part1 ' + cast(@ID as varchar) + ', ' + @TaskName + ', ' + cast(@DueDate as varchar) + ', ' + @CreatedBy + ', ' + @TaskType + ', assignedTo = ' + @assignee
		*/
		
		/*** LOGIC FROM QCheck_CreateSimple_Part1 with a fix for the due time ***/
		DECLARE @ReminderDate DATETIME
		SET @ReminderDate = @SoftDue
		DECLARE @UserID int
		DECLARE @FolderID int
		DECLARE @FolderName varchar(50)
		DECLARE @PrevSchedule bit
		
		SET @PrevSchedule = 0
		SET @ReportID = 0

		IF @Section IS NOT NULL
		BEGIN
			SELECT @ReportID = reportID
			FROM
				QStatus_TaskTypes
			WHERE ID = @TaskType
		END
		INSERT INTO QCheck_Checklists
		([Name], Owner)
		VALUES
		(@TaskName, @CreatedBy)
		SELECT @ID = @@IDENTITY	
		-- Creator is the controller
		DECLARE @ControllerGroupID int
		SELECT @ControllerGroupID = ID
		FROM QCheck_Groups
		WHERE owner = @CreatedBy
		AND SingleMemberGroup = 1
		INSERT INTO QCheck_ChecklistManagers
		(ChecklistID, ManagerGroupID)
		VALUES (@ID, @ControllerGroupID)
		if len(@TemplateName) > 0
		begin
			insert into QCheck_Items ([ChecklistID], [SequenceNum], [ItemTypeID], [Text], [URL])
			select @ID, i.[SequenceNum], i.[ItemTypeID], i.[Text], i.[URL]
			from QCheck_Items i
			cross apply
				(
					select top 1 ID from QCheck_Checklists where name = @TemplateName and isdeleted = 0
					order by ID asc
				) cFirst
			inner join QCheck_Checklists c
				on i.checklistid = c.id
				and c.ID = cFirst.ID
				and i.isdeleted = 0
		end
		
		if not exists (select 1 from qcheck_items where checklistid = @ID)
		begin
			EXEC QCheck_AddItem @ID, null, 1, @TaskName, ''
		end
		EXEC QCheck_CreateInstance @NewInstanceID output, @ID, '', @CreatedBy
		EXEC QCheck_AddAssignedTo @NewInstanceID, @assignee, @CreatedBy, @Email
		---- KVS 2017-09-26 - Removing these default alerts per GPR/Nelson;
		----	Users who want them can add them manually
		---- Reminder 1 day before due
		--EXEC QCheck_AddAlert
		--		@InstanceID = @NewInstanceID, 
		--		@nagBeforeDays = 1,
		--		@nagTime = 17,
		--		@alertType = 'Reminder'
		
		---- 2/11/2014 dalvarado - Also set a reminder for 1 hour before due
		--EXEC QCheck_AddAlert
		--		@InstanceID = @NewInstanceID, 
		--		@nagBeforeDays = NULL,
		--		@nagTime = -1,
		--		@alertType = 'Reminder'

	
				
		DECLARE @DueTime INT = DATEPART(HOUR, @DueDate)
		EXEC QCheck_UpdateSchedule_part1 
				@InstanceID = @NewInstanceID, 
				@firstDueDate = @DueDate,
				@freqType = 1, 
				@dueTime = @DueTime,
				@PrevFreqType = @PrevFreqType output,
				@RowsUpdated = @RowsUpdated output,
				@Activate = 1,
				@TimeZone = @TimeZone
				--@busDayBehavior=3--added by venkat for testing

		SELECT @NewActiveID = ID
		FROM QCheck_ActiveChecklists
		WHERE InstanceID = @NewInstanceID
		-- Set the reminder date to whatever was passed in, if it's not past the due time
		UPDATE QCheck_ActiveChecklists
		SET ReminderDate = @ReminderDate
		WHERE 
			[ID] = @NewActiveID
			AND @ReminderDate <= DueTime
		IF @TaskType IS NOT NULL BEGIN
			DECLARE @NewTaskTypeID int
			--don't use @Priority here - that value's intended for priority lists. Default to priority 1
			EXEC QCheck_AddInstanceTaskType @NewInstanceID, @TaskType, 1, @NewTaskTypeID OUTPUT
		END      
		
		-- rebuild cache
		EXEC QCheck_ChecklistControllersList_Refresh @ID
		
		/*** END LOGIC FROM QCheck_CreateSimple_Part1 with a fix for the due time ***/
	END
	
	-- Make sure the deadline is right--for some reason if you pass in 5pm, the task is due at 6pm.
	IF @ErrorCode = 0 BEGIN
		UPDATE QCheck_ActiveChecklists SET 
			DueTime = dbo.ConvertTimeToUtc(@DueDate, @TimeZone), 
			OrigDueTime = dbo.ConvertTimeToUtc(@DueDate, @TimeZone)
		WHERE ID = @NewActiveID
	END
	IF @ErrorCode = 0 BEGIN
		
		if len(isnull(ltrim(rtrim(@comments)), '')) > 0
		begin
			declare @NewID int,
				@initials varchar(100),
				@fn varchar(50)
			exec QStatus_CreateNewComment @NewActiveID, @CreatedBy, @comments, @NewID, @initials, @fn
		end

		--IF @reportID IS NOT NULL AND @reportID <> 0
		--BEGIN
			UPDATE qstatus_report SET isdirty = 1 WHERE id = @reportID
		--END
	ENd
	-- Make the assigned group a controller on the task
	IF @errorCode = 0
	BEGIN
		UPDATE QCheck_ChecklistManagers
		SET ManagerGroupID = @Controller
		WHERE ChecklistID = (SELECT ChecklistID FROM QCheck_ChecklistInstances WHERE ID = @NewInstanceID)
		
		SET @errorCode = @@ERROR
		IF @ErrorCode <> 0 SET @errorMsg = 'UPDATE QCheck_ChecklistManagers SET ManagerGroupID = ' + CAST(@assignee as varchar) + ' WHERE ChecklistID = (SELECT ChecklistID FROM QCheck_ChecklistInstances WHERE ID = ' + CAST(@NewInstanceID AS varchar) + ')'
	END
	
	-- ADD To priority lists
	IF @errorCode = 0
	BEGIN
		IF @PriorityUser > 0
		BEGIN	
			exec [PriorityList_AddTask] @UserID = @PriorityUser, @ActiveChecklistID = @NewActiveID, @Priority = @Priority, @ListID = null
			SET @errorCode = @@ERROR
			IF @ErrorCode <> 0 SET @errorMsg = 'ADD TO PRIORITIES'
		END	
		ELSE
		BEGIN
			IF @Priority > 0
			BEGIN
				exec [PriorityList_AddTask_ForGroup] @CreatedBy, @Assignee, @NewActiveID, @Priority
				SET @errorCode = @@ERROR
				IF @ErrorCode <> 0 SET @errorMsg = 'ADD TO PRIORITIES'
			END	
			
		END
	END
	
	-- Create a reminder
	IF @Alert IS NOT NULL BEGIN
		SET @nagBeforeDays = ABS(DATEDIFF(DAY, @DueDate, @Alert))
		SET @nagTime = DATEPART(HOUR, @Alert)
		EXEC QCheck_AddReminder	@NewInstanceID, @nagBeforeDays, @nagTime
	END
	
	
-- =======================================================
-- Alert on any errors
-- =======================================================
	IF @errorCode <> 0
	BEGIN
		DECLARE @msg varchar(5000)
		DECLARE @MailSubject VARCHAR(1000)
		SET @MailSubject = @AppName + ' Automated Task Creation Error'
		SET @msg = 'Calling Program: ' + @CallingProgram + '<br/><br/>Error Number: ' + cast(@errorCode AS varchar) + '<br/><br/>' + @errorMsg
		EXEC XPSendEmail
		    @FROM       = @FromAddress,
		    @FROM_NAME  = 'SQLMail',
		    @TO         = @DeveloperAddress,
		    @subject    = @MailSubject,
		    @message    = @msg,
		    @type       = 'text/html',
		    @server     = @MailServer
		RAISERROR ('Unable to create task', 16, 1)
	END
	ELSE
	BEGIN
		SELECT @AppURL = appurl from qcheck_appsettings s
		inner join qcheck_users u
		on s.ID = u.App
		WHERE u.ID = @CreatedBy
		if @ReportID is null OR @Section IS NULL
		begin
			select @AppURL as appUrl, @NewInstanceID as NewInstanceID
		end
		else
		begin
			select @AppURL + '/MyStatus.aspx?reportID=' + convert(varchar(10), @reportId) + '&taskID=' + convert(varchar(10), @NewActiveID)  as appUrl, @NewInstanceID as NewInstanceID
		
		end
	END	
	
	SET NOCOUNT OFF
END

GO

/* [PriorityListSet_GetComments] */

CREATE OR ALTER   PROC [dbo].[PriorityListSet_GetComments]
    @SetID int,
    @UserID int,
    @StartTime datetime,
    @AllUsers bit = 0,
    @IncludeHistory bit = 1
AS
BEGIN
    SET NOCOUNT ON

	--quick fix for themost common scenario; if user's asking for the current day's comments,
	--they're really asking for the current *local* day's comments
	--Comment/delete this after deploying the fix committed by KVS on 11/27 around 2 PM CST
	SELECT @StartTime = 
			CAST(dbo.ConvertTimeToUtc(
					CAST(dbo.ConvertTimeFromUtc(GETUTCDATE(), ISNULL(u.TimeZoneOverride, u.LastTimeZone)) as date)
					, ISNULL(u.TimeZoneOverride, u.LastTimeZone))
				as datetime)
		FROM QCheck_Users u
		WHERE ID = @UserID
	
	--if(@StartTime = CAST(GETUTCDATE() as date))
	--begin

		
		/*SELECT @StartTime = 
			CAST(dbo.ConvertTimeToUtc(
					CAST(dbo.ConvertTimeFromUtc(GETUTCDATE(), ISNULL(u.TimeZoneOverride, u.LastTimeZone)) as date)
					, ISNULL(u.TimeZoneOverride, u.LastTimeZone))
				as datetime)
		FROM QCheck_Users u
		WHERE ID = @UserID*/
	--end

    IF @IncludeHistory = 0 BEGIN
        select 
            l.userid, 
            l.ID ListID,
            li.activechecklistid, 
            '[' + c.initials + '] '+ c.comments as comments,
            li.id,
            c.id as CommentId,
            c.DisplayOrder,
            c.TabIn AS TabIn,
            c.UserID AS CommentUserID
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

        -- Remove or update @recordIds if not needed

        SELECT 
            UserID, 
            ListID, 
            activechecklistid, 
            comments, 
            id, 
            IsHidden = CAST(0 AS BIT),
            TabIn,
            CommentUserID,
            CommentId
        FROM #result
        ORDER BY UserID, DisplayOrder
    END ELSE IF @IncludeHistory = 1 BEGIN
        SELECT li.ActiveChecklistID, li.[Priority], lsl.ListID, li.ID, l.UserID
        INTO #checklists
        FROM 
            Priorities_ListSetLists lsl
            INNER JOIN Priorities_Lists l        
                ON l.ID = lsl.ListID            
            INNER JOIN Priorities_ListItems li
                ON li.ListID = l.ID
        WHERE lsl.setid = @setid

        SELECT UserID, ListID, ActiveChecklistID, Comments, RawComment, Id, IsHidden, TabIn, CommentUserID, CommentId, CommentDt
        FROM (
            SELECT DISTINCT
                UserID = l.UserId,
                ListID = l.ListID,
                ActiveChecklistID = l.ActiveChecklistID,
                Comments = '[' + CONVERT(VARCHAR(10), c.CommentDt, 101) + '] [' + u.FullName + '] ' + c.Comments,
                Id = l.ID,
                IsHidden = CAST(CASE WHEN c.commentdt > @starttime THEN 0 ELSE 1 END AS BIT),
                DisplayOrder = c.DisplayOrder,
                TabIn = c.TabIn,
                CommentUserID = c.UserID,
                CommentId = c.ID
            FROM 
                QStatus_COMMENTS C
                INNER JOIN QCheck_Users u
                    ON u.ID = C.UserID
                INNER JOIN #checklists l
                    ON l.ActiveChecklistID = c.ForeignKeyID

            UNION ALL SELECT DISTINCT
                UserID = l.UserID,
                ListID = l.ListID,
                ActiveChecklistID = l.ActiveChecklistID,
                Comments = '[' + CONVERT(VARCHAR(10), c.CommentDt, 101) + '] [' + u.FullName + '] ' + c.Comments,
                Id = l.ID,
                IsHidden = CAST(CASE WHEN c.commentdt > @starttime THEN 0 ELSE 1 END AS BIT),
                DisplayOrder = c.DisplayOrder,
                TabIn = c.TabIn,
                CommentUserID = c.UserID,
                CommentId = c.ID
            FROM 
                QStatus_commentarchive C
                INNER JOIN QCheck_Users u
                    ON u.ID = C.UserID
                INNER JOIN #checklists l
                    ON l.ActiveChecklistID = c.ForeignKeyID
        ) x
        ORDER BY UserID, DisplayOrder
    END
END

GO

/* [PriorityListSet_GetComments_UTC] */

CREATE OR ALTER   PROC [dbo].[PriorityListSet_GetComments_UTC]
    @SetID int,
    @UserID int,
    @StartTime datetime,
    @AllUsers bit = 0,
    @IncludeHistory bit = 1
AS
BEGIN
    SET NOCOUNT ON

	DECLARE @TimeZone VARCHAR(MAX) = NULL;
	SET @TimeZone = (SELECT ISNULL(TimeZoneOverride, LastTimeZone) FROM QCheck_Users WHERE ID = @UserID);

    IF @IncludeHistory = 0 BEGIN
        select 
            l.userid, 
            l.ID ListID,
            li.activechecklistid, 
            '[' + c.initials + '] '+ c.comments as comments,
            li.id,
            c.id as CommentId,
            c.DisplayOrder,
            c.TabIn AS TabIn,
            c.UserID AS CommentUserID,
            CAST(dbo.ConvertTimeFromUtc(c.CommentDt, @TimeZone) AS DATETIME) AS CommentDt
        into #result
        from Priorities_ListSetLists lsl
            JOIN Priorities_Lists l        
                on l.ID = lsl.ListID            
            JOIN Priorities_ListItems li
                on li.ListID = l.ID
            JOIN QCheck_Users u
                ON u.ID = l.UserID
            join qstatus_comments c
                on c.foreignkeyid = li.activechecklistid
                and c.specialtask = 0
                and (c.userid = @userid OR @AllUsers = 1)
                and c.commentdt > @starttime
        where lsl.setid = @setid
            and len(c.comments) > 0
        order by l.userid, c.displayorder

        SELECT 
            UserID, 
            ListID, 
            activechecklistid, 
            comments, 
            id,
            CAST(0 AS BIT) AS IsHidden,
            TabIn,
            CommentUserID,
            CommentId,
            CommentDt
        FROM #result
        ORDER BY UserID, DisplayOrder
    END ELSE IF @IncludeHistory = 1 BEGIN
        SELECT li.ActiveChecklistID, li.[Priority], lsl.ListID, li.ID, l.UserID
        INTO #checklists
        FROM 
            Priorities_ListSetLists lsl
            INNER JOIN Priorities_Lists l        
                ON l.ID = lsl.ListID            
            INNER JOIN Priorities_ListItems li
                ON li.ListID = l.ID
        WHERE lsl.setid = @setid

        SELECT UserID, ListID, ActiveChecklistID, Comments, Id, IsHidden, TabIn, CommentUserID, CommentId, CommentDt
        FROM (
            SELECT DISTINCT
                UserID = l.UserID,
                ListID = l.ListID,
                ActiveChecklistID = l.ActiveChecklistID,
                Comments = '[' + CONVERT(VARCHAR(10), c.CommentDt, 101) + '] [' + u.FullName + '] ' + c.Comments,
                Id = l.ID,
                IsHidden = CAST(CASE WHEN c.commentdt > @starttime THEN 0 ELSE 1 END AS BIT),
                DisplayOrder = c.DisplayOrder,
                TabIn = c.TabIn,
                CommentUserID = c.UserID,
                CommentId = c.ID,
				CAST(dbo.ConvertTimeFromUtc(c.CommentDt, @TimeZone) AS DATETIME) AS CommentDt
            FROM 
                QStatus_COMMENTS C
                INNER JOIN QCheck_Users u
                    ON u.ID = C.UserID
                INNER JOIN #checklists l
                    ON l.ActiveChecklistID = c.ForeignKeyID

            UNION ALL SELECT DISTINCT
                UserID = l.UserID,
                ListID = l.ListID,
                ActiveChecklistID = l.ActiveChecklistID,
                Comments = '[' + CONVERT(VARCHAR(10), c.CommentDt, 101) + '] [' + u.FullName + '] ' + c.Comments,
                Id = l.ID,
                IsHidden = CAST(CASE WHEN c.commentdt > @starttime THEN 0 ELSE 1 END AS BIT),
                DisplayOrder = c.DisplayOrder,
                TabIn = c.TabIn,
                CommentUserID = c.UserID,
                CommentId = c.ID,
                CAST(dbo.ConvertTimeFromUtc(c.CommentDt, @TimeZone) AS DATETIME) AS CommentDt
            FROM 
                QStatus_commentarchive C
                INNER JOIN QCheck_Users u
                    ON u.ID = C.UserID
                INNER JOIN #checklists l
                    ON l.ActiveChecklistID = c.ForeignKeyID
        ) x
        ORDER BY UserID, DisplayOrder
    END
END

GO