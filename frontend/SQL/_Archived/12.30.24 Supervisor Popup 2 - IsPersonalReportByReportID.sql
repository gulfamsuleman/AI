CREATE PROCEDURE [dbo].[QStatus_IsPersonalReportByReportID]
    @reportId INT,
    @isPersonalReport BIT OUTPUT
AS
BEGIN
	/* Determine if a report is a personal report (report name = a FullName in QCheck_Users.
	Returns a bool, used to prevent deleting the last supervisor in the supervisor popup */
    SET NOCOUNT ON;

    DECLARE @reportName NVARCHAR(255);

    -- Retrieve the Name from QStatus_Report
    SELECT @reportName = Name
    FROM QStatus_Report
    WHERE ID = @reportId;

    -- Check if the Name exists in QCheck_Users FullName column
    IF EXISTS (SELECT 1 FROM QCheck_Users WHERE FullName = @reportName)
    BEGIN
        SET @isPersonalReport = 1;
    END
    ELSE
    BEGIN
        SET @isPersonalReport = 0;
    END
END
GO