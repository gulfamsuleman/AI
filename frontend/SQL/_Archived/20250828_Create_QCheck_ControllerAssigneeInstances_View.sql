-- Creates view used by queries; safe to run multiple times.

IF OBJECT_ID('dbo.QCheck_ControllerAssigneeInstances', 'V') IS NULL
BEGIN
    EXEC('CREATE VIEW dbo.QCheck_ControllerAssigneeInstances AS
          SELECT ci.id
          FROM dbo.QCheck_ChecklistManagers cm
          INNER JOIN dbo.QCheck_GroupMembership gm1
              ON gm1.groupid = cm.ManagerGroupID
             AND cm.IsDeleted = 0
          INNER JOIN dbo.QCheck_ChecklistInstances ci
              ON ci.checklistid = cm.checklistid
             AND ci.isdeleted = 0
          INNER JOIN dbo.QCheck_Assignments a
              ON a.InstanceID = ci.id
             AND a.IsDeleted = 0
          INNER JOIN dbo.QCheck_GroupMembership gm2
              ON gm2.GroupID = a.groupid
             AND gm2.userid = gm1.userid');
END

GO

