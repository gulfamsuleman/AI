CREATE OR ALTER PROCEDURE [dbo].[QStatus_GetTaskItemDetailsByStatusReportID] (
	@ReportID int
)
AS
BEGIN

	/* OG (05/29/2025): Returns item details for 'Email All' button on 'My Status' page (both preview and email) */

	DECLARE @TempReportId INT = 0
	DECLARE @AppName NVARCHAR(50)

	SELECT @AppName = AppName from QCheck_AppSettings;

	SET @TempReportId = (SELECT ID FROM QStatus_Report WHERE ID = @ReportID AND IsDeleted = 0)
	IF @TempReportId = 0
	BEGIN
		RAISERROR('Specified status report is not available.', 16, 1, @AppName)
		RETURN
	END

	;WITH ItemDetails AS (
		SELECT
			ac.ID AS ActiveChecklistID,
			i.ID AS ChecklistItemID,
			i.Text AS ItemName,
			it.Name AS ItemType,
			ai.CompletedDate, 
			CASE WHEN ai.CompletedDate IS NULL THEN 0 ELSE 1 END AS IsCompleted,
			cu.FullName AS CompletedBy,
			ROW_NUMBER() OVER (
				PARTITION BY ac.ID, i.ID
				ORDER BY ai.CompletedDate DESC
			) AS rn
		FROM QCheck_Items i
		INNER JOIN QCheck_ItemTypes it ON it.ID = i.ItemTypeID
		INNER JOIN QCheck_Checklists c ON c.ID = i.ChecklistID
		INNER JOIN QCheck_ChecklistInstances ci ON c.ID = ci.ChecklistID AND ci.IsDeleted = 0
		INNER JOIN QCheck_ActiveChecklists ac ON ci.ID = ac.InstanceID
		LEFT JOIN QCheck_ActiveItems ai ON ai.ActiveChecklistID = ac.ID AND ai.ChecklistItemID = i.ID
		INNER JOIN QCheck_Assignments a ON ac.InstanceID = a.InstanceID AND a.IsDeleted = 0
		INNER JOIN QStatus_InstanceTaskType itt ON itt.InstanceID = ci.ID
		INNER JOIN QStatus_TaskTypes tt ON tt.ID = itt.TaskType
		INNER JOIN QStatus_Report r ON r.ID = tt.ReportID
		LEFT JOIN QCheck_Users cu ON cu.ID = ai.CompletedBy
		WHERE r.ID = @TempReportId
		AND i.IsDeleted = 0
	)
		SELECT
			ActiveChecklistID,
			ChecklistItemID,
			ItemName,
			ItemType,
			CompletedDate,
			IsCompleted,
			CompletedBy
		FROM ItemDetails
		WHERE rn = 1
		ORDER BY ChecklistItemID, ActiveChecklistID
END
GO


