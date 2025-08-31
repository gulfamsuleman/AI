
GO
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE OR ALTER PROCEDURE [dbo].[QStatus_ReportValidation] (
@Assignees NVARCHAR(500),
@Controller NVARCHAR(500),
@SectionId INT,	
@RecordsReturned INT OUTPUT
)
AS
BEGIN

 DECLARE @AppName NVARCHAR(50);
 
 SELECT @AppName = AppName from QCheck_AppSettings; --THIS IS USED FOR ERROR MESSAGING

CREATE TABLE #CombinedUsers(
UserName NVARCHAR(30)
);

INSERT INTO #CombinedUsers (UserName) SELECT UserName.c from dbo.Util_fn_List_To_Table(@assignees, ',') as UserName;
INSERT INTO #CombinedUsers (UserName) SELECT @Controller;

select r.id ReportID, u.id UserID from 
??QStatus_TaskTypes tt
??INNER JOIN QStatus_Report r ON r.ID = tt.ReportID AND r.IsDeleted = 0
??INNER JOIN QStatus_GroupReport gr ON gr.ReportID = r.ID
??INNER JOIN QCheck_Groups g ON g.ID = gr.GroupID
??INNER JOIN QCheck_GroupMembership gm on gm.GroupID = g.ID
??INNER JOIN QCheck_Users u ON u.ID = gm.UserID AND u.FullName IN ((SELECT * from #CombinedUsers)) and u.IsDeleted = 0
??WHERE tt.ID = @SectionId
????AND tt.IsDeleted = 0

??UNION

??select r.id, u.ID from 
??QStatus_TaskTypes tt
??INNER JOIN QStatus_Report r ON r.ID = tt.ReportID AND r.IsDeleted = 0
??INNER JOIN QStatus_Supervisors s ON s.ReportID = r.ID and s.InterestedParty = 0
??INNER JOIN QCheck_Groups g ON g.ID = s.SupervisorGroupID
??INNER JOIN QCheck_GroupMembership gm on gm.GroupID = g.ID
??INNER JOIN QCheck_Users u ON u.ID = gm.UserID AND u.FullName = @Controller and u.IsDeleted = 0
??WHERE tt.ID = @SectionId
????AND tt.IsDeleted = 0

SELECT @RecordsReturned = @@ROWCOUNT

END