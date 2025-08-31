USE [PFSProcess]
GO

/****** Object:  StoredProcedure [dbo].[QStatus_GetControllerUserIDsByReportID]    Script Date: 12/29/2024 2:34:51 PM ******/
SET ANSI_NULLS OFF
GO

SET QUOTED_IDENTIFIER OFF
GO


CREATE PROCEDURE [dbo].[QStatus_GetControllerUserIDsByReportID]
    @ID int,
    @ReturnString VARCHAR(1000) OUTPUT
AS
BEGIN
	/* Takes the ReportID and returns a string with the comma-separated user IDs 
	   of any controllers via the @ReturnString output parameter */

    SET @ReturnString = ''

    SELECT @ReturnString = @ReturnString + CAST(u.ID AS VARCHAR) + ', '
    FROM (
        SELECT DISTINCT u.ID
        FROM
            QStatus_GroupReport gr
        INNER JOIN
            QCheck_Groups g
        ON
            g.ID = gr.GroupID
        INNER JOIN
            QCheck_GroupMembership gm
        ON
            gm.GroupID = g.ID
        AND
            gr.ReportID = @ID
        INNER JOIN
            QCheck_Users u
        ON 
            u.ID = gm.UserID
        AND
            gr.ReportID = @ID
        AND
            u.isdeleted = 0
    ) u

    IF LEN(@ReturnString) > 0
        SET @ReturnString = LEFT(@ReturnString, LEN(@ReturnString) - 1)
END

GO


