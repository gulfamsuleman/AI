-- Creates the view used across queries to detect multi-step checklists
-- Safe to run multiple times; only creates if missing.

IF OBJECT_ID('dbo.QCheck_MultiStep', 'V') IS NULL
BEGIN
    EXEC('CREATE VIEW dbo.QCheck_MultiStep AS
          SELECT checklistid
          FROM dbo.QCheck_Items WITH (NOLOCK)
          WHERE isdeleted = 0
            AND itemtypeid = 1
          GROUP BY checklistid
          HAVING COUNT(id) > 1');
END

GO

