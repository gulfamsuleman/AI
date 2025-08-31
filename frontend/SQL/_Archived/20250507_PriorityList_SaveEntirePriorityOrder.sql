CREATE PROCEDURE [dbo].[PriorityList_SaveEntirePriorityOrder]
    @TaskOrderCsv NVARCHAR(MAX)
AS
BEGIN
	/* OG (5/7/25): Priorities Page - Saves entire priority list after sorting by a field */

    -- Split CSV string into rows
    WITH ParsedData AS (
        SELECT 
            Id,
            Data AS TaskOrder
        FROM dbo.Util_Split(@TaskOrderCsv, ',')
    ),
    TaskOrderTable AS (
        SELECT 
            CAST(SUBSTRING(TaskOrder, 1, CHARINDEX('|', TaskOrder) - 1) AS INT) AS TaskId,
            CAST(SUBSTRING(TaskOrder, CHARINDEX('|', TaskOrder) + 1, LEN(TaskOrder)) AS INT) AS Priority
        FROM ParsedData
    )
    -- Update entire priority list
    UPDATE p
    SET Priority = t.Priority
    FROM Priorities_ListItems p
    INNER JOIN TaskOrderTable t ON p.ID = t.TaskId;
END
GO


