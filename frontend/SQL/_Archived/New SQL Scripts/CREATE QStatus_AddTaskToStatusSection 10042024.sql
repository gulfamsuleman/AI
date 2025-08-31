GO

SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE OR ALTER PROCEDURE [dbo].[QStatus_AddTasksToStatusSection]
(
	@ReportSectionId INT,
	@ActiveChecklistId INT = 0,
	@TaskName NVARCHAR(250) = NULL
)
 AS
BEGIN
	DECLARE @TempInstanceId INT
	DECLARE @TempSectionId INT
	DECLARE @AppName NVARCHAR(50);
    SELECT @AppName = AppName from QCheck_AppSettings;
	declare @acId INT

	SET @TempSectionId = (SELECT ID FROM QStatus_TaskTypes WHERE ID = @ReportSectionID)

	IF @TempSectionId = 0
		BEGIN
			RAISERROR('Provided SectionId is not valid', 16, 1, @AppName)
			RETURN
		END

IF @ActiveChecklistId > 0 
	BEGIN

		DECLARE @TempTaskNameCount INT

		SET @TempTaskNameCount = (SELECT COUNT(c.Name) FROM QStatus_Tasktypes tt
									INNER JOIN QStatus_InstanceTaskType itt
									on tt.ID = itt.TaskType
									INNER JOIN QCheck_ActiveChecklists ac
									on itt.InstanceId = ac.InstanceID
									INNER JOIN QCheck_ChecklistInstances ci
									on ac.InstanceId = ci.ID
									inner join QCheck_Checklists c
									on ci.ChecklistID = c.ID
									WHERE ac.Id = @ActiveChecklistId
									AND tt.ID = @ReportSectionId
									AND c.IsDeleted = 0)

		IF @TempTaskNameCount > 0
		BEGIN
			RAISERROR('Provided task is not valid', 16, 1, @AppName)
			RETURN
		END

		SET @TempInstanceId = (SELECT ac.InstanceID FROM QCheck_ActiveChecklists ac
		WHERE AC.ID = @ActiveChecklistId)

		IF @TempInstanceId = 0
		BEGIN
			RAISERROR('Provided InstanceId is not valid', 16, 1, @AppName)
			RETURN
		END

		EXEC QCheck_AddInstanceTaskTypeOutput @TempInstanceId, @ReportSectionId, @acId 
	END
	ELSE IF @TaskName IS NOT NULL
	BEGIN

		SET @TempTaskNameCount = (SELECT COUNT(c.Name) FROM QStatus_Tasktypes tt
									INNER JOIN QStatus_InstanceTaskType itt
									on tt.ID = itt.TaskType
									INNER JOIN QCheck_ActiveChecklists ac
									on itt.InstanceId = ac.InstanceID
									INNER JOIN QCheck_ChecklistInstances ci
									on ac.InstanceId = ci.ID
									inner join QCheck_Checklists c
									on ci.ChecklistID = c.ID
									WHERE c.Name = @TaskName
									AND tt.ID = @ReportSectionId
									AND c.IsDeleted = 0)

		IF @TempTaskNameCount > 0
		BEGIN
			RAISERROR('Provided task is not valid', 16, 1, @AppName)
			RETURN
		END
	    
		SET @TempInstanceId = (SELECT ac.InstanceID FROM QCheck_ActiveChecklists ac
			INNER JOIN QCheck_ChecklistInstances ci
			ON ac.InstanceId = ci.ID
			INNER JOIN QCheck_Checklists c
			on ci.ChecklistID = c.ID
			WHERE c.Name = @TaskName
			AND c.IsDeleted = 0)

		IF @TempInstanceId = 0
		BEGIN
			RAISERROR('Provided task is not valid', 16, 1, @AppName)
			RETURN
		END

		EXEC QCheck_AddInstanceTaskTypeOutput @TempInstanceId, @ReportSectionId, @acId

	END

END



