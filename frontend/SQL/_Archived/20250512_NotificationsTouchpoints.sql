
GO
/****** Object:  StoredProcedure [dbo].[QCheck_AddAssignedTo]    Script Date: 5/12/2025 6:32:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[QCheck_AddAssignedTo](
--DECLARE
	@InstanceID INT,-- = 1857455,
	@GroupID	int,-- = 10,
	@AssignedBy int,-- = 715,
	@Email		bit = 1
) AS
BEGIN

	SET NOCOUNT ON
	DECLARE @AssignmentsID int
	DECLARE @ScheduleID int
	DECLARE @ActiveChecklistID int
	
	DECLARE @startDate datetime
	DECLARE @dueDate datetime
	DECLARE @nextStart datetime
	DECLARE @checklistName varchar(500)
	DECLARE @checklistID int
	DECLARE @relativeStart datetime
	DECLARE @ActiveAssignments int
	DECLARE @Now datetime

	--Create the assignment
	INSERT INTO
		QCheck_Assignments
	([InstanceID],  [GroupID])
	SELECT @InstanceID, @GroupID
	WHERE NOT EXISTS
	(SELECT [ID] FROM QCheck_Assignments
	WHERE InstanceID = @InstanceID
	AND GroupID = @GroupID
	and IsDeleted = 0)

	SELECT @AssignmentsID = @@IDENTITY	
	
	--Only do this if they are not already assigned to the checklist	
	IF @AssignmentsID is not null 
	BEGIN

		SELECT Distinct @ActiveChecklistID = MIN(b.ID)
		FROM QCheck_ActiveChecklists b
		LEFT OUTER JOIN
			QCheck_ActiveAssignments newassign
		on
			newassign.AssignmentsID = @AssignmentsID AND newassign.ActiveChecklistID = b.ID--a.ActiveChecklistID
		WHERE 
			newassign.ID is null
		AND
			b.InstanceID = @InstanceID
		AND
			b.CompletedDate is null

		--Select @ActiveChecklistID
		
		INSERT INTO QCheck_ActiveAssignments
		SELECT Distinct b.ID, @AssignmentsID--a.ActiveChecklistID, @AssignmentsID
		FROM
			QCheck_ActiveChecklists b
		LEFT OUTER JOIN
			QCheck_ActiveAssignments newassign
		on
			newassign.AssignmentsID = @AssignmentsID AND newassign.ActiveChecklistID = b.ID--a.ActiveChecklistID
		WHERE 
			newassign.ID is null
		AND
			b.InstanceID = @InstanceID
		AND
			b.CompletedDate is null
		--SELECT @ActiveAssignments = @@rowcount

		/*Notify the assignee*/
		SELECT 
			@checklistName = b.[Name], @checklistID = b.id
		FROM
			QCheck_ChecklistInstances a
		INNER JOIN
			QCheck_Checklists b
		   ON
			a.ChecklistID = b.[ID]
		WHERE
			a.[ID] = @InstanceID

		
		DECLARE @SendEmail bit
		SET @SendEmail = 1
		
		SELECT @SendEmail = 0
		FROM QCheck_GroupMembership gm
		INNER JOIN QCheck_Groups g
		ON g.ID = gm.GroupID
		WHERE gm.GroupID = @GroupID 
		AND gm.UserID = @AssignedBy
		AND g.SingleMemberGroup = 1

		if @SendEmail =1 and @Email = 1
			exec QCheck_AssignedEmail_AddToQueue @GroupID, @AssignedBy, @checklistName, @InstanceID
		
		exec QCheck_InstanceChangeAlert @InstanceID, 'Assignment', 'Add'

		declare @userid int, @subject varchar(1000), @url varchar(1000), @detail varchar(1000), @assignedbyname varchar(1000)
		declare @assignees table (id int)
		insert into @assignees select userid from qcheck_groupmembership where groupid = @GroupID and userid <> @AssignedBy
		
		select @assignedbyname = fullname from QCheck_Users where id = @AssignedBy
		select @subject = 'New task assigned: '+ isnull(@checklistName, '')
		select @url = 'ManageTasks.aspx?checklistid=' + isnull(cast(@checklistid as varchar(10)), '')
		select @detail = 'You have been assigned the task "'+isnull(@checklistName, '')+'" by ' + @assignedbyname

		while exists (select id from @assignees)
		begin
			select top 1 @userid = id from @assignees

			EXEC QCheck_Notification_SET
				@userId = @userid,
				@subject = @subject,
				@url = @url,
				@urlText = 'View Task In Managed Tasks',
				@detail = @detail

			delete from @assignees where @userid = id
		end

	END

	SET NOCOUNT OFF

END

GO
/****** Object:  StoredProcedure [dbo].[QCheck_AddAssignedToByActiveChecklist]    Script Date: 5/12/2025 6:33:03 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
-- This stored procedure will Assign a member to a checklist
-- InstanceID is the instance being assigned to
-- AssignedTo is the member being assigned
-- AssignedBy is the member who assigned the checklist out
ALTER PROCEDURE [dbo].[QCheck_AddAssignedToByActiveChecklist]
(
	@ActiveChecklistID INT,
	@GroupID	int,
	@AssignedBy 	int,
	@Email		bit = 1
)
 AS
BEGIN
	SET NOCOUNT ON
	DECLARE @AssignmentsID int
	DECLARE @ScheduleID int
	--DECLARE @ActiveChecklistID int
	DECLARE @startDate datetime
	DECLARE @dueDate datetime
	DECLARE @nextStart datetime
	DECLARE @checklistName varchar(500)
	DECLARE @checklistID int
	DECLARE @relativeStart datetime
	DECLARE @ActiveAssignments int
	DECLARE @Now datetime
	DECLARE @InstanceID int

	SELECT @InstanceID = InstanceID
	FROM QCheck_ActiveChecklists
	WHERE ID = @ActiveChecklistID

	--Create the assignment
	INSERT INTO
		QCheck_Assignments
	([InstanceID],  [GroupID])
	SELECT @InstanceID, @GroupID
	WHERE NOT EXISTS
	(SELECT [ID] FROM QCheck_Assignments
	WHERE InstanceID = @InstanceID
	AND GroupID = @GroupID
	and IsDeleted = 0)
	SELECT @AssignmentsID = @@IDENTITY	
	
	--Only do this if they are not already assigned to the checklist	
	IF @AssignmentsID is not null 
	BEGIN
		
		INSERT INTO QCheck_ActiveAssignments
		SELECT Distinct b.ID, @AssignmentsID--a.ActiveChecklistID, @AssignmentsID
		FROM
			QCheck_ActiveChecklists b
		LEFT OUTER JOIN
			QCheck_ActiveAssignments newassign
		on
			newassign.AssignmentsID = @AssignmentsID AND newassign.ActiveChecklistID = b.ID--a.ActiveChecklistID
		WHERE 
			newassign.ID is null
		AND
			b.InstanceID = @InstanceID
		AND
			b.CompletedDate is null
		--SELECT @ActiveAssignments = @@rowcount
		/*Notify the assignee*/
		SELECT 
			@checklistName = b.[Name], @checklistID = b.id
		FROM
			QCheck_ChecklistInstances a
		INNER JOIN
			QCheck_Checklists b
		   ON
			a.ChecklistID = b.[ID]
		WHERE
			a.[ID] = @InstanceID
		
		DECLARE @SendEmail bit
		SET @SendEmail = 1
		
		SELECT @SendEmail = 0
		FROM QCheck_GroupMembership gm
		INNER JOIN QCheck_Groups g
		ON g.ID = gm.GroupID
		WHERE gm.GroupID = @GroupID 
		AND gm.UserID = @AssignedBy
		AND g.SingleMemberGroup = 1
		if @SendEmail =1 and @Email = 1
			exec QCheck_AssignedEmail_AddToQueue @GroupID, @AssignedBy, @checklistName, @InstanceID
		
		exec QCheck_InstanceChangeAlert @InstanceID, 'Assignment', 'Add'

		declare @userid int, @subject varchar(1000), @url varchar(1000), @detail varchar(1000), @assignedbyname varchar(1000)
		declare @assignees table (id int)
		insert into @assignees select userid from qcheck_groupmembership where groupid = @GroupID and userid <> @AssignedBy
	
		select @assignedbyname = fullname from QCheck_Users where id = @AssignedBy
		select @subject = 'New task assigned: '+ isnull(@checklistName, '')
		select @url = 'ManageTasks.aspx?checklistid=' + isnull(cast(@checklistid as varchar(10)), '')
		select @detail = 'You have been assigned the task "'+isnull(@checklistName, '')+'" by ' + @assignedbyname

		while exists (select id from @assignees)
		begin
			select top 1 @userid = id from @assignees

			EXEC QCheck_Notification_SET
				@userId = @userid,
				@subject = @subject,
				@url = @url,
				@urlText = 'View Task In Managed Tasks',
				@detail = @detail

			delete from @assignees where @userid = id
		end
	END
	SET NOCOUNT OFF
END

GO
/****** Object:  StoredProcedure [dbo].[QStatus_CreateQuickReply]    Script Date: 5/12/2025 6:33:41 PM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

ALTER                                          PROCEDURE [dbo].[QStatus_CreateQuickReply]
	@CommentID  int,
	@Comments varchar(1500),
	@UserID int,
	@ReplyID int output,
	@CommentsInitials varchar(100) output,
	@FullName varchar(50) output,
	@tabin int output
AS
	DECLARE @DisplayOrder int
	DECLARE @MaxDisplayOrder int
	DECLARE @foreignKeyID int
	DECLARE @SpecialTask bit
	DECLARE @CommentsName VARCHAR(1000)
	DECLARE @ReplyToUserID int
	DECLARE @ReplyToComment varchar(1500)
		
	IF (SELECT TOP 1 StatusCommentsInitials FROM QCheck_AppSettings) = 1
		BEGIN
		SELECT @CommentsInitials = UPPER(LEFT(SUBSTRING(ShortName, CHARINDEX('-', ShortName) + 1, LEN(ShortName)), 2)), @FullName = FullName,
			@CommentsName = FullName
		FROM QCheck_Users
		WHERE ID = @UserID
		END
	ELSE IF (SELECT TOP 1 StatusCommentsInitials FROM QCheck_AppSettings) = 0
		BEGIN
		SELECT @CommentsInitials = fullname, @FullName = FullName,
			@CommentsName = FullName
		FROM QCheck_Users
		WHERE ID = @UserID
		END
	ELSE
		BEGIN
		SELECT @CommentsInitials = UPPER(LEFT(ShortName, 2)), @FullName = FullName,
			@CommentsName = FullName
		FROM QCheck_Users
		WHERE ID = @UserID
		END

	SELECT 
		@DisplayOrder = DisplayOrder, 
		@tabin= tabin, 
		@foreignKeyID=foreignKeyID,
		@SpecialTask = SpecialTask,
		@ReplyToUserID = u.ID,
		@ReplyToComment = c.Comments
	FROM QStatus_COMMENTS_All c
	INNER JOIN
		QCheck_Users u
	ON
		c.UserID = u.ID
	WHERE 
		c.ID = @CommentID
	If NOT @tabin is null
	BEGIN
	
		SELECT @MaxDisplayOrder = MAX(DisplayOrder)
		FROM
			QStatus_COMMENTS
		WHERE 
			foreignKeyID = @foreignKeyID
	
		IF @DisplayOrder < @MaxDisplayOrder
		BEGIN
			SELECT @DisplayOrder = ISNULL(MIN(DisplayOrder) - 1, @MaxDisplayOrder)
			FROM QStatus_COMMENTS
			WHERE DisplayOrder > @DisplayOrder
			AND TabIn <= @tabin
			AND foreignKeyID = @foreignKeyID
		END
	
		UPDATE QStatus_COMMENTS
		SET DisplayOrder = DisplayOrder + 1
		WHERE
			foreignKeyID = @foreignKeyID
		AND
			DisplayOrder > @DisplayOrder
	
		SET @tabin = @tabin + 1
	
		INSERT INTO
				QStatus_Comments
		(foreignKeyID, Comments, DisplayOrder, tabIn, CommentDt, Initials, UserID, ReplyID, specialTask)
		VALUES
		(@foreignKeyID, @Comments, @DisplayOrder + 1, @tabin, GetUtcDate(), @CommentsInitials, @UserID, @CommentID, @specialTask)
	
		SELECT @ReplyID = Scope_Identity()
	END
	DELETE FROM QStatus_Comments
	WHERE 
		ForeignKeyID = @foreignKeyID
	AND
		LEN(Comments) = 0
	DELETE FROM QStatus_CommentArchive
	WHERE 
		ForeignKeyID = @foreignKeyID
	AND
		LEN(Comments) = 0
	
	If @SpecialTask = 1
	BEGIN
		UPDATE
			QStatus_Report
		SET 
			LastReportDate = GetUtcDate()
		FROM 
			QStatus_Report r
		INNER JOIN
			QStatus_TaskTypes tt
		ON
			tt.ReportID = r.ID
		AND
			tt.IsDeleted = 0
		INNER JOIN
			QStatus_SpecialTasks st
		ON
			st.TaskType = tt.ID
		AND
			st.ID = @foreignKeyID
		INNER JOIN
			QStatus_GroupReport gr
		ON
			gr.ReportID = r.ID
		INNER JOIN 
			QCheck_Groups g
		ON
			g.ID = gr.GroupID
		INNER JOIN
			QCheck_GroupMembership gm
		ON	
			gm.GroupID = g.ID
		AND
			gm.UserID = @UserID
	END

	
	IF @ReplyToUserID <> @UserID
	BEGIN
		declare @subject varchar(1000) = @CommentsName + ' replied to your comment'
		declare @url varchar(1000) = '', @detail varchar(1000)
		declare @newComment varchar(100), @oldComment varchar(100), @taskname varchar(1000)

		select @newComment = case when len(@Comments) > 100 then left(@Comments, 97) + '...' else @Comments end
		select @oldComment = case when len(@ReplyToComment) > 100 then left(@ReplyToComment, 97) + '...' else @ReplyToComment end
		select @detail = @CommentsName + ' replied "'+@newComment+'" to your comment "'+@oldComment+'"'

		if @specialTask = 1
		begin
			select top 1 @url = 'MyInbox.aspx?ReportID=' + cast(r.ID as varchar(10))
			from qstatus_comments_all c
				inner join qstatus_specialtasks st
					on st.id = c.foreignkeyid
				inner join qstatus_tasktypes tt
					on tt.id = st.tasktype
				inner join qstatus_report r
					on r.id = tt.reportid
					and r.isdeleted = 0
				inner join qcheck_groupmembership gm
					on gm.userid = @ReplyToUserID
				cross apply
					(
						select reportid from qstatus_groupreport where groupID = gm.groupid and reportid = r.id
						union all
						select reportid from qstatus_supervisors where supervisorgroupID = gm.groupid and reportid = r.id
					) sec
			where c.id = @CommentID

		end
		else
		begin
			select top 1 @url = 'MyInbox.aspx?ReportID=' + cast(r.ID as varchar(10)) + '&taskID=' + cast(c.foreignkeyid as varchar(10))
			from qstatus_comments_all c
				inner join qstatus_activechecklisttasktype actt
					on actt.activechecklistid = c.foreignkeyid
				inner join qstatus_tasktypes tt
					on tt.id = actt.tasktype
				inner join qstatus_report r
					on r.id = tt.reportid
					and r.isdeleted = 0
				inner join qcheck_groupmembership gm
					on gm.userid = @ReplyToUserID
				cross apply
					(
						select reportid from qstatus_groupreport where groupID = gm.groupid and reportid = r.id
						union all
						select reportid from qstatus_supervisors where supervisorgroupID = gm.groupid and reportid = r.id
					) sec
			where c.id = @CommentID

			select @detail = @detail + 'on the task "'+ch.name+'"'
			from qstatus_comments_all c
				inner join qcheck_activechecklists_all ac
					on c.foreignkeyid = ac.id
				inner join qcheck_checklistinstances_all ci
					on ci.id = ac.instanceid
				inner join qcheck_checklists_all ch
					on ch.id = ci.checklistid
			where c.id = @CommentID
		end

		EXEC QCheck_Notification_SET
			@userId = @ReplyToUserID,
			@subject = @subject,
			@url = @url,
			@urlText = 'View Comment',
			@detail = @detail
	END

