GO
/****** Object:  StoredProcedure [dbo].[QCheck_AddInstanceTaskTypeOutput]    Script Date: 10/4/2024 11:15:15 AM ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE OR ALTER PROCEDURE [dbo].[QStatus_CreateNewCommentFromApi]
(
	@Comments NVARCHAR(500),
	@ActiveChecklistId INT = 0,
	@TaskName NVARCHAR(250) = NULL,
	@NewID INT OUTPUT,
	@CommentInitials nVARCHAR(5) OUTPUT,
	@FullName NVARCHAR(50) OUTPUT
)
 AS
BEGIN
	DECLARE @TempInstanceId INT

	DECLARE @AppName NVARCHAR(50);
    SELECT @AppName = AppName from QCheck_AppSettings;

IF @ActiveChecklistId > 0 
 BEGIN
    SET	@TempInstanceId = (SELECT ID FROM QCheck_ActiveCheckLists WHERE ID = @ActiveChecklistID AND CompletedDate IS NOT NULL)

		IF @TempInstanceId = 0 OR @TempInstanceId IS NULL
		BEGIN
			RAISERROR('Provided ActiveChecklistId is not valid', 16, 1, @AppName)
			RETURN
		END

	BEGIN
		EXEC QStatus_CreateNewComment @ActiveChecklistId, 0, @Comments, @NewID, @CommentInitials, @FullName
	END
END
	ELSE IF @TaskName IS NOT NULL
	BEGIN

	  DECLARE @DuplicateCount INT 
	   SET @DuplicateCount = (SELECT COUNT(ac.ID) FROM QCheck_Checklists c
					INNER JOIN QCheck_ChecklistInstances ci
						ON ci.ChecklistID = c.ID
					INNER JOIN QCheck_ActiveChecklists ac
						ON ci.ID = ac.InstanceID
						WHERE c.Name = @TaskName)

		IF @DuplicateCount > 1
		BEGIN
			RAISERROR('Provided task is not valid', 16, 1, @AppName)
			RETURN
		END


		SET @TempInstanceId = (SELECT ac.ID FROM QCheck_ActiveChecklists ac
			INNER JOIN QCheck_ChecklistInstances ci
			ON ac.InstanceId = ci.ID
			INNER JOIN QCheck_Checklists c
			on ci.ChecklistID = c.ID
			WHERE c.Name = @TaskName
			AND c.IsDeleted = 0)

		IF @TempInstanceId = 0 OR @TempInstanceId IS NULL
		BEGIN
			RAISERROR('Provided task is not valid', 16, 1, @AppName)
			RETURN
		END
		
		EXEC QStatus_CreateNewComment @TempInstanceId, 0, @Comments, @NewID, @CommentInitials, @FullName
	

	END

END

--SELECT ac.InstanceID FROM QCheck_ActiveChecklists ac
--			INNER JOIN QCheck_ChecklistInstances ci
--			ON ac.InstanceId = ci.ID
--			INNER JOIN QCheck_Checklists c
--			on ci.ChecklistID = c.ID
--			WHERE c.Name = 'This is a task made for test case with optionals omitted Status Report!'
--		AND c.IsDeleted = 0

--	DECLARE @NewID2 INT 
--	DECLARE @CommentInitials2 nVARCHAR(5)
--	DECLARE @FullName2 NVARCHAR(50)

--EXEC QStatus_CreateNewCommentFromApi 'These are just some test comments',  0, 'This is a task made for test case with optionals omitted Status Report!', @NewID = @NewID2 output, @CommentInitials = @CommentInitials2 output, @FulLName = @FullName2 output

--SELECT ac.ID FROM QCheck_ActiveChecklists ac
--			INNER JOIN QCheck_ChecklistInstances ci
--			ON ac.InstanceId = ci.ID
--			INNER JOIN QCheck_Checklists c
--			on ci.ChecklistID = c.ID
--			WHERE c.Name = 'This is a task made for test caseptionals omitted Status Report 3212!'
--			AND c.IsDeleted = 0