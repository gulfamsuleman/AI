/****** Object:  StoredProcedure [dbo].[PHISFTP_Test_Import]    Script Date: 7/19/2024 1:05:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[QCheck_OutprocessAndReplaceUser] (
	@OutprocessUserId INT,
	@ReassignmentTargetUserId INT
	)
AS
BEGIN

	BEGIN TRY 

		BEGIN TRANSACTION OutprocessUser;

		--DECLARE USER IDS, GET SINGLE MEMBER GROUP (SMG) IDS AND STATUS REPORT IDS FOR BOTH USERS--

		DECLARE @OutprocessedSmgID INT = (SELECT ID 
										  FROM QCheck_Groups g
										  WHERE g.Owner = @OutprocessUserId
											AND SingleMemberGroup = 1
										)

		DECLARE @ReassignSmgID INT = (SELECT ID 
									  FROM QCheck_Groups g
									  WHERE g.Owner = @ReassignmentTargetUserId
										AND SingleMemberGroup = 1
									   )

		DECLARE @OutprocessedUserStatusReportId INT = (SELECT TOP (1) s.ReportID 
													   FROM QStatus_Supervisors s
													   INNER JOIN QStatus_Report sr
														ON s.ReportID = sr.ID
													   INNER JOIN QCheck_Users u
														ON u.FullName = sr.Name
													   WHERE u.ID = @OutprocessedSmgID
													   )

		----UPDATE GROUP MEMBERSHIP WITH NEW USER--

		UPDATE gm
		SET UserID = @ReassignmentTargetUserId
		FROM QCheck_GroupMembership gm
		JOIN QCheck_Groups g ON g.ID = gm.GroupID AND g.SingleMemberGroup = 0
		WHERE gm.UserID = @OutprocessUserId
		AND NOT EXISTS( 
			SELECT 'Y' FROM QCheck_GroupMembership gm2 
			WHERE gm2.GroupID = gm.GroupID 
				AND gm2.UserID = @ReassignmentTargetUserId
		)

		DELETE QCheck_GroupMembership FROM QCheck_GroupMembership gm 
			JOIN QCheck_Groups g ON g.ID = gm.GroupID AND g.SingleMemberGroup = 0
		WHERE UserID = @OutprocessUserId

		--UPDATE ALL ASSIGNMENTS WITH NEW USER--

		UPDATE a
		SET GroupID = @ReassignSmgID,
		DtAssigned = GETDATE() -- set when new user was assigned
		FROM QCheck_Assignments a
		INNER JOIN QCheck_Groups g 
			ON g.ID = a.GroupID 
		WHERE GroupID = @OutprocessedSmgID
		AND a.InstanceID NOT IN
			(
				SELECT t.InstanceID
				FROM QCheck_Assignments t
				INNER JOIN QCheck_GroupMembership gm
					ON gm.groupid = t.groupid
					and gm.GroupID =  @ReassignSmgID
			)

		DELETE QCheck_Assignments FROM QCheck_Assignments a
		WHERE a.GroupID= @OutprocessedSmgID
						
		--UPDATE GROUP REPORT ID IN GROUP REPORT--

		UPDATE QStatus_GroupReport 
		SET GroupID = @ReassignSmgID
		WHERE GroupID = @OutprocessedSmgID
		 AND ReportID <> @OutprocessedUserStatusReportId 
		 AND ReportID NOT IN (SELECT r.reportid 
							FROM QStatus_GroupReport r
							INNER JOIN QCheck_Groupmembership gm
								ON gm.groupid = r.groupid
								AND gm.userid = @ReassignmentTargetUserId
 
							UNION
 
							SELECT s.reportid FROM QStatus_Supervisors s
							INNER JOIN  QCheck_Groupmembership gm
								ON gm.groupid = s.supervisorgroupID
								AND gm.userid = @ReassignmentTargetUserId
							)

		UPDATE QStatus_Supervisors 
		SET SupervisorGroupID = @ReassignSmgID
		WHERE SupervisorGroupID = @OutprocessedSmgID
		 AND ReportID <> @OutprocessedUserStatusReportId 
		 AND ReportID NOT IN (SELECT r.reportid 
							FROM QStatus_GroupReport r
							INNER JOIN QCheck_Groupmembership gm
								ON gm.groupid = r.groupid
								AND gm.userid = @ReassignmentTargetUserId
 
							UNION
 
							SELECT s.reportid FROM QStatus_Supervisors s
							INNER JOIN  QCheck_Groupmembership gm
								ON gm.groupid = s.supervisorgroupID
								AND gm.userid = @ReassignmentTargetUserId
							)

		UPDATE QCheck_ChecklistManagers
		SET ManagerGroupID = @ReassignSmgID
		WHERE ManagerGroupID = @OutprocessedSmgID
			AND IsDeleted = 0
			AND ChecklistID NOT IN (SELECT ChecklistID 
									FROM QCheck_Checklistmanagers cm
										INNER JOIN QCheck_GroupMembership gm
											on cm.ManagerGroupID = gm.GroupID
											AND gm.UserID = @ReassignmentTargetUserId
											AND cm.IsDeleted = 0
											)
	
		--HARD DELETE AND SOFT DELETE OUTPROCESSED USER FROM DIFFERENT GROUP, STATUS REPORT, AND USER TABLES--

		DELETE FROM QCheck_GroupMembership
		WHERE GroupID = @OutprocessedSmgID

		DELETE FROM QStatus_GroupReport 
		WHERE GroupID = @OutprocessedSmgID

		DELETE FROM QStatus_Supervisors
		WHERE SupervisorGroupID = @OutprocessedSmgID

		UPDATE QStatus_Report 
		SET IsDeleted = 1
		WHERE ID = @OutprocessedUserStatusReportId

		DELETE FROM QCheck_Groups
		WHERE ID = @OutprocessedSmgID

		UPDATE QCheck_Users
		SET IsDeleted = 1
		WHERE ID = @OutprocessUserId

		UPDATE QCheck_ChecklistManagers
		SET IsDeleted = 1
		WHERE ManagerGroupID = @OutprocessedSmgID
			  AND IsDeleted = 0

		UPDATE QCheck_Alerts 
		SET IsDeleted = 1
		WHERE AlerteeGroupID = @OutprocessedSmgID
			AND IsDeleted = 0

		--ADDENDUM: Need to delete records from priority lists for user to be outprocessed

		DELETE FROM Priorities_Lists 
		WHERE UserID = @OutprocessUserID

		DELETE FROM Priorities_ListSets 
		WHERE UserID = @OutprocessUserID

		DELETE FROM Priorities_ListItems 
		WHERE ListID NOT IN (SELECT ID 
							 FROM Priorities_Lists)

		DELETE FROM Priorities_ListSetLists 
		WHERE SetID NOT IN (SELECT ID 
							FROM Priorities_ListSets
							) OR 
							ListID NOT IN (SELECT ID 
							FROM Priorities_Lists
							)

		DELETE FROM Priorities_ListSets 
		WHERE ID NOT IN (SELECT DISTINCT SetID 
						 FROM Priorities_ListSetLists
						 )

		COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH

		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION OutprocessUser;

			DECLARE @ErrorMessage NVARCHAR(4000);
			DECLARE @ErrorSeverity INT;
			DECLARE @ErrorState INT;

			SELECT @ErrorMessage = ERROR_MESSAGE();
			SELECT @ErrorSeverity = ERROR_SEVERITY();
			SELECT @ErrorState = ERROR_STATE();

			RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

	END CATCH

END
GO


