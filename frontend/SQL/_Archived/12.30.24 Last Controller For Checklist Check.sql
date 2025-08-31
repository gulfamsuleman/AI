CREATE PROCEDURE QCheck_IsLastControllerByChecklistID
    @taskID INT,
    @isLastController BIT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if there is only one result in QCheck_ChecklistManagers where ChecklistID = @taskID
    IF (SELECT COUNT(*) FROM QCheck_ChecklistManagers WHERE ChecklistID = @taskID) = 1
    BEGIN
        SET @isLastController = 1;
    END
    ELSE
    BEGIN
        SET @isLastController = 0;
    END
END
