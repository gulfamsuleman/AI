GO
/****** Object:  StoredProcedure [dbo].[QCheck2_AddItem]    Script Date: 12/30/2024 4:20:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE QCheck_ChangeTaskDueDateThroughApi (
@ActiveChecklistId INT,
@newDueDate DATETIME
)
AS 
BEGIN 
	DECLARE @AppName VARCHAR(250)

	SELECT @AppName = AppName from QCheck_AppSettings; --THIS IS USED FOR ERROR MESSAGING
	DECLARE @ExistingTask INT = (SELECT ID FROM QCheck_ActiveChecklists WHERE ID = @ActiveChecklistId)

	IF @ExistingTask IS NULL
	BEGIN
		RAISERROR('The provided task does not exist in  %S', 16, 1, @AppName)
		RETURN
	END
	EXEC QCheck_UpdateDueDate @ActiveChecklistId, @newDueDate 


END