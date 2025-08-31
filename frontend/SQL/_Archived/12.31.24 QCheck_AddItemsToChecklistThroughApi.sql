GO
/****** Object:  StoredProcedure [dbo].[QCheck2_AddItem]    Script Date: 12/30/2024 4:20:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE QCheck_AddItemsToChecklistThroughApi (
@ActiveChecklistId INT,
@ItemTypeID INT,
@Text	varchar(max),
@URL	varchar(1000),
@UserId INT,
@ReturnID INT OUTPUT
)
AS 
BEGIN 

	DECLARE @ChecklistId INT = (SELECT ci.ChecklistId FROM QCheck_ChecklistInstances ci 
								INNER JOIN QCheck_ActiveChecklists ac ON ac.InstanceID = ci.ID
								WHERE ac.ID = @ActiveChecklistId)

	EXEC QCheck2_AddItem @ChecklistId, NULL, @ItemTypeID, @Text, @URL, @UserId, @ReturnID OUTPUT


END