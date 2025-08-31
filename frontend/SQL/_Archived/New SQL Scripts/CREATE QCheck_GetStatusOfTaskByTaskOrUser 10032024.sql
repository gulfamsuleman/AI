
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[QStatus_GetStatusOfTaksByTaskOrUser] (
	@ActiveChecklistId INT = 0,
	@TaskName NVARCHAR(250) = NULL,
	@UserName NVARCHAR(30) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	IF @ActiveChecklistId > 0
	BEGIN
	SELECT 
	c.Name AS TaskName, 
	g.Name AS Assignees,
	con.controllers AS Controllers,
	ac.DueTime AS Deadline, 
	CASE WHEN ac.CompletedDate IS NULL THEN 0 ELSE 1 END AS IsCompleted
		FROM QCheck_Checklists c
		INNER JOIN QCheck_ChecklistInstances ci
		ON c.ID = ci.ChecklistID AND ci.IsDeleted = 0
		INNER JOIN QCheck_ActiveChecklists ac
		ON ci.ID = ac.InstanceID
		INNER JOIN QCheck_Assignments a
		ON ac.InstanceID = a.InstanceID AND a.IsDeleted = 0
		INNER JOIN QCheck_GroupMembership gm
		ON a.GroupID = gm.GroupID
		INNER JOIN QCheck_Groups g
		ON gm.GroupID = g.ID
		INNER JOIN QCheck_Users u
		ON g.Owner = u.ID AND u.IsDeleted = 0
		INNER JOIN QCheck_ChecklistControllersList con
		ON c.ID = con.checklistid
	WHERE ac.ID = @ActiveChecklistId 
	GROUP BY con.controllers, c.Name, g.Name, ac.Duetime, ac.CompletedDate
	END

	ELSE IF @TaskName <> NULL
	BEGIN
	SELECT 
	c.Name AS TaskName, 
	g.Name AS Assignees,
	con.controllers AS Controllers,
	ac.DueTime AS Deadline, 
	CASE WHEN ac.CompletedDate IS NULL THEN 0 ELSE 1 END AS IsCompleted
		FROM QCheck_Checklists c
		INNER JOIN QCheck_ChecklistInstances ci
		ON c.ID = ci.ChecklistID AND ci.IsDeleted = 0
		INNER JOIN QCheck_ActiveChecklists ac
		ON ci.ID = ac.InstanceID
		INNER JOIN QCheck_Assignments a
		ON ac.InstanceID = a.InstanceID AND a.IsDeleted = 0
		INNER JOIN QCheck_GroupMembership gm
		ON a.GroupID = gm.GroupID
		INNER JOIN QCheck_Groups g
		ON gm.GroupID = g.ID
		INNER JOIN QCheck_Users u
		ON g.Owner = u.ID AND u.IsDeleted = 0
		INNER JOIN QCheck_ChecklistControllersList con
		ON c.ID = con.checklistid
	WHERE c.Name = @TaskName 
	GROUP BY con.controllers, c.Name, g.Name, ac.Duetime, ac.CompletedDate
	END

	ELSE IF @UserName <> NULL
	BEGIN
	SELECT 
	c.Name AS TaskName, 
	g.Name AS Assignees,
	con.controllers AS Controllers,
	ac.DueTime AS Deadline, 
	CASE WHEN ac.CompletedDate IS NULL THEN 0 ELSE 1 END AS IsConpleted
		FROM QCheck_Checklists c
		INNER JOIN QCheck_ChecklistInstances ci
		ON c.ID = ci.ChecklistID AND ci.IsDeleted = 0
		INNER JOIN QCheck_ActiveChecklists ac
		ON ci.ID = ac.InstanceID
		INNER JOIN QCheck_Assignments a
		ON ac.InstanceID = a.InstanceID AND a.IsDeleted = 0
		INNER JOIN QCheck_GroupMembership gm
		ON a.GroupID = gm.GroupID
		INNER JOIN QCheck_Groups g
		ON gm.GroupID = g.ID
		INNER JOIN QCheck_Users u
		ON g.Owner = u.ID AND u.IsDeleted = 0
		INNER JOIN QCheck_ChecklistControllersList con
		ON c.ID = con.checklistid
	WHERE g.Name = @UserName
	GROUP BY con.controllers, c.Name, g.Name, ac.Duetime, ac.CompletedDate
	END


END
GO
