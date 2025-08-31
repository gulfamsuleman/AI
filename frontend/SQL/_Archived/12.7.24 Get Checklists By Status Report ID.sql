-- Add the new column with a default value of 0 and NOT NULL constraint
ALTER TABLE QStatus_Report
ADD IsViewTv BIT NOT NULL DEFAULT 0;

GO

/****** Object:  StoredProcedure [dbo].[QCheck_GetChecklistsByStatusReportId]    Script Date: 12/7/2024 9:41:18 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[QCheck_GetChecklistsByStatusReportId]
    @id INT
AS
BEGIN
/*
	This is passed the id of the status report and if the status report table has IsViewTv set to
	true, then this will return all tasks and comments related to that task. This will be used
	to view tasks on a TV in Sky Harbor Airport.
*/
    WITH CTE AS (
        SELECT 
            c.ID AS ChecklistID,
            r.Name AS StatusReportName, 
            c.Name AS ChecklistName,
            tt.Description AS SectionName, 
            s.TimeZone AS TimeZone,
            ac.DueTime,
			CASE WHEN aac.ActiveChecklistID IS NULL THEN 0 ELSE 1 END AS PendingChange,
            ROW_NUMBER() OVER (PARTITION BY c.ID ORDER BY ac.DueTime) AS RowNum,
            -- Aggregate the comments in the subquery first, ordered by DisplayOrder
            STRING_AGG('[-]' + sc.Comments, CHAR(13) + CHAR(10)) AS Comments -- [-] is used as a token for replacement

        FROM 
            QStatus_Report r    
        INNER JOIN 
            QStatus_TaskTypes tt ON r.ID = tt.ReportID    
        INNER JOIN 
            QStatus_InstanceTaskType itt ON tt.ID = itt.TaskType    
        INNER JOIN 
            QCheck_ChecklistInstances ci ON ci.ID = itt.InstanceID    
        INNER JOIN 
            QCheck_Checklists c ON ci.ChecklistID = c.ID 
        INNER JOIN 
            QCheck_Schedule s ON s.ID = ci.ScheduleID 
        INNER JOIN 
            QCheck_ActiveChecklists ac ON ac.InstanceID = ci.ID
		LEFT OUTER JOIN QCheck_MostRecentDeadlineRequests mrdr
			ON ac.ID = mrdr.ActiveChecklistID
		LEFT OUTER JOIN QCheck_Approval_ChangeRequests cr
			ON cr.ID = mrdr.ChangeRequestID
		LEFT OUTER JOIN QCheck_Approval_ActiveChecklists aac
			ON aac.ChangeRequestID = cr.ID
			AND aac.ActiveChecklistID = mrdr.ActiveChecklistID
		LEFT JOIN QStatus_Comments sc
			ON sc.ForeignKeyID = ac.ID AND sc.SpecialTask = 0
        WHERE 
            r.ID = @id
			AND r.IsViewTv = 1
			AND ac.CompletedDate IS NULL
        GROUP BY 
            c.ID, r.Name, c.Name, tt.Description, s.TimeZone, ac.DueTime, aac.ActiveChecklistID
    )
    SELECT 
        ChecklistID,
        StatusReportName, 
        ChecklistName,
        SectionName, 
        TimeZone,
        DueTime,
		PendingChange,
        COALESCE(Comments, '') AS Comments
    FROM 
        CTE
    WHERE 
        RowNum = 1;
END;
GO


