USE [PHIProcesSTest]
GO

/****** Object:  StoredProcedure [dbo].[Util_GradeTest_Breakdown]    Script Date: 7/15/2024 9:38:45 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[Util_UserTestReport] AS
BEGIN

select 
    u.ID UserID,u.empID EmployeeID, u.FullName FullName, u.Email Email, 
    CAST(x.DtAssigned as date) LatestTraining, CAST(x2.DtAssigned as date) FirstTraining,   
    qptCount.Count NumAttempts,
    qptMax.Grade BestGrade, qptMax.GradedDt
from QCheck_Users u
    JOIN QCheck_GroupMembership gm
        ON u.ID = gm.UserID 
    JOIN QCheck_Groups g
        ON g.ID = gm.GroupID AND g.SingleMemberGroup = 1
    OUTER APPLY (
        SELECT TOP 1 a.DtAssigned, i.ID InstanceID, a.ID AssignmentID, c.ID ChecklistID  
        FROM QCheck_Assignments_All a       
        JOIN QCheck_ChecklistInstances_All i 
            ON a.InstanceID = i.ID AND a.IsDeleted = 0
        JOIN QCheck_Checklists_All c
            ON i.ChecklistID = c.ID AND i.IsDeleted = 0 
            AND c.Name LIKE '%Process%Final%Test%'
        WHERE a.GroupID = gm.GroupID
        ORDER BY a.DtAssigned DESC
    ) x
    OUTER APPLY (
        SELECT TOP 1 a.DtAssigned, i.ID InstanceID, a.ID AssignmentID, c.ID ChecklistID  
        FROM QCheck_Assignments_All a       
        JOIN QCheck_ChecklistInstances_All i 
            ON a.InstanceID = i.ID AND a.IsDeleted = 0
        JOIN QCheck_Checklists_All c
            ON i.ChecklistID = c.ID AND i.IsDeleted = 0 
            AND c.Name LIKE '%Process%Final%Test%'
        WHERE a.GroupID = gm.GroupID
            AND a.DtAssigned <> x.DtAssigned
        ORDER BY a.DtAssigned
    ) x2
    OUTER APPLY (
        SELECT COUNT(*) Count FROM Grading_QProcessTests qpt2
        WHERE qpt2.employee = u.FullName        
    ) qptCount
    OUTER APPLY (
        SELECT TOP 1 Employee, Grade, GradedDt FROM Grading_QProcessTests qpt3
        WHERE qpt3.employee = u.FullName
        ORDER BY Grade DESC
    ) qptMax
WHERE u.IsDeleted = 0   
    AND (u.Email LIKE '%@phihelico%' OR u.Email LIKE '%@phi-int%' OR u.Email LIKE '%@phiairmedical%')
	AND (x.DtAssigned IS NOT NULL OR qptMax.grade IS NOT NULL)
ORDER BY 
    CASE WHEN qptMax.gradeddt IS NULL THEN 1 ELSE 2 END, 
    CASE WHEN x.ChecklistID IS NULL THEN 1 ELSE 2 END, 
    u.FullName

END
GO


