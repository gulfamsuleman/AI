
/****** Object:  StoredProcedure [dbo].[QStatus_GetTaskTypeByReport]    Script Date: 8/28/2024 9:07:59 AM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE PROCEDURE [dbo].[QStatus_GetTaskTypeByReport] (
@ReportName varchar(75),
@SectionName varchar(75)
)
	
AS
BEGIN

select r.ID ReportID, r.Name ReportName, tt.ID SectionID, tt.Description SectionName
FROM QStatus_Report r
JOIN QStatus_TaskTypes tt ON tt.ReportID = r.ID
WHERE r.Name = @ReportName
AND r.IsDeleted = 0
AND tt.Description = @SectionName
AND tt.IsDeleted = 0

END
GO


