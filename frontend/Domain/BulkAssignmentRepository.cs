using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using QProcess.Models;

namespace QProcess.Repositories
{
    public class BulkAssignmentRepository
	{
		public IEnumerable<BulkAssignment> GetBulkAssignments(int userId)
		{
			using (var cmd = new CmdObj("QCheck_GetAssignedBulk", 360))
			{
				cmd.Add("@ID", userId);
				var bulkAssignments = cmd.GetDS();
				return bulkAssignments.Tables[0].AsEnumerable().Select(ba =>
					{
						var bulkAssignment = new BulkAssignment
							{
								Id = (int) ba["ID"],
								Name = (string) ba["Name"],
								NextDue = !Convert.IsDBNull(ba["nextdue"]) ? (string) ba["nextdue"] : null,
								LastCompleted = !Convert.IsDBNull(ba["lastcompleted"]) ? (string) ba["lastcompleted"] : null,
								Assignees = (string) ba["Assignees"],
								Controllers = (string) ba["Controllers"],
								Active = (string) ba["Active"],
								IsHighlighted = (int) ba["Highlight"] == 1
							};
						int indexStart = ((string) ba["Alertees"]).IndexOf('>')+1;
						int indexEnd = ((string) ba["Alertees"]).IndexOf("</a>");
						if (indexStart > 0 && indexEnd > 0)
							bulkAssignment.Alertees = ((string) ba["Alertees"]).Substring(indexStart, indexEnd - indexStart);
						return bulkAssignment;
					});
			}
		}

		public void AddAssignment(int assignmentId, int assigneeGroupId, int userId, string comment)
		{
			using (var cmd = new CmdObj("QCheck_Bulk_AddAssignment", 360))
			{
				cmd.Add("@AssignmentID", assignmentId);
				cmd.Add("@AssigneeGroupID", assigneeGroupId);
				cmd.Add("@AssignedBy", userId);
				cmd.Add("@Comment", comment);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void RemoveAssignment(int assignmentId, int assigneeGroupId, int assignedBy, string comment)
		{
			using (var cmd = new CmdObj("QCheck_Bulk_RemoveAssignment", 360))
			{
				cmd.Add("@AssignmentID", assignmentId);
				cmd.Add("@AssigneeGroupID", assigneeGroupId);
				cmd.Add("@AssignedBy", assignedBy);
				cmd.Add("@Comment", comment);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

        public void DeleteInstanceByAssignment(int assignmentId)
        {
            using (var cmd = new CmdObj("QCheck_OutprocessDeleteAssignment", 360))
            {
                cmd.Add("@AssignmentID", assignmentId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void DeleteReportByGroupReportID(int groupReportId)
        {
            using (var cmd = new CmdObj("QStatus_OutprocessDeleteReport", 360))
            {
                cmd.Add("@GroupReportID", groupReportId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void DeleteAssignment(int assignmentId, int assigneeGroupId, int assignedBy, string comment)
        {
            using (var cmd = new CmdObj("QCheck_Bulk_DeleteAssignment", 360))
            {
                cmd.Add("@AssignmentID", assignmentId);
                cmd.Add("@AssigneeGroupID", assigneeGroupId);
                cmd.Add("@AssignedBy", assignedBy);
                cmd.Add("@Comment", comment);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void RemoveHighlighting(int userId)
		{
			using (var cmd = new CmdObj("QCheck_Bulk_RemoveHighlighting"))
			{
				cmd.Add("@UserID", userId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

        public List<ReportListing> GetControlledReports(int userId)
        {
            using (var cmd = new CmdObj("QStatus_GetUserReports"))
            {
                cmd.Add("@ID", userId);
                var myReports = cmd.GetDS();
                return myReports.Tables[0].AsEnumerable().Select(rl => new ReportListing
                {
                    ReportID = (int)rl["ID"],
                    ReportName = (string)rl["Name"],
                    Controllers = (string)rl["Controllers"],
                    SupervisorsIP = (string)rl["Supervisors"]
                }).ToList();
            }
        }

        public List<ReportListing> GetSupervisedReports(int userId)
        {
            using (var cmd = new CmdObj("QStatus_GetSupervisedReports"))
            {
                cmd.Add("@ID", userId);
                var myReports = cmd.GetDS();
                return myReports.Tables[0].AsEnumerable().Select(rl => new ReportListing
                {
                    ReportID = (int)rl["ID"],
                    ReportName = (string)rl["Name"],
                    Controllers = (string)rl["Controllers"],
                    SupervisorsIP = (string)rl["Supervisors"]
                }).ToList();
            }
        }

        public List<TaskDetails> GetAssignedTaskDetails(int userId)
        {
            using (var cmd = new CmdObj("QCheck_GetAssigned"))
            {
                cmd.Add("@ID", userId);
                var myTaskDetails = cmd.GetDS();
                return myTaskDetails.Tables[0].AsEnumerable().Select(td => new TaskDetails
                {
                    Id = (int)td["ID"],
                    Name = (string)td["Name"],
                    Assignees = (string)td["Assignees"],
                    Controllers = (string)td["Controllers"],
                    Alertees = (string)td["Alertees"]
                }).ToList();
            }
        }

        public List<TaskDetails> GetControlledTaskDetails(int userId)
        {
            using (var cmd = new CmdObj("QCheck_GetControlled"))
            {
                cmd.Add("@ID", userId);
                var myTaskDetails = cmd.GetDS();
                return myTaskDetails.Tables[0].AsEnumerable().Select(td => new TaskDetails
                {
                    Id = (int)td["ID"],
                    Name = (string)td["Name"],
                    Assignees = (string)td["Assignees"],
                    Controllers = (string)td["Controllers"],
                    Alertees = (string)td["Alertees"]
                }).ToList();
            }
        }

        public List<TaskDetails> GetAlerteeTaskDetails(int userId)
        {
            using (var cmd = new CmdObj("QCheck_GetAlertee"))
            {
                cmd.Add("@ID", userId);
                var myTaskDetails = cmd.GetDS();
                return myTaskDetails.Tables[0].AsEnumerable().Select(td => new TaskDetails
                {
                    Id = (int)td["ID"],
                    Name = (string)td["Name"],
                    Assignees = (string)td["Assignees"],
                    Controllers = (string)td["Controllers"],
                    Alertees = (string)td["Alertees"]
                }).ToList();
            }
        }

        public List<TaskDetails> GetTasksControlledByGroup(int groupID, string loginName, bool newOnly, bool incompleteOnly)
        {
            using (var cmd = new CmdObj("QCheck_TasksControlledByGroup"))
            {
                cmd.Add("@GroupID", groupID);
                cmd.Add("@Login", loginName);
                cmd.Add("@NewOnly", newOnly);
                cmd.Add("@IncompleteOnly", incompleteOnly);
                var myTaskDetails = cmd.GetDS();
                return myTaskDetails.Tables[0].AsEnumerable().Select(td => new TaskDetails
                {
                    Id = (int)td["ChecklistID"],
                    Name = (string)td["ChecklistName"],
                    Assignees = (string)td["Assignees"],
                    Controllers = (string)td["Controllers"],
                    IsHighlighted = ((int)td["IsNew"] == 1 ? true : false)
                }).ToList();
            }
        }

        public void RemoveReportUser(int id)
        {
            using (var cmd = new CmdObj("QStatus_DeleteReportUser"))
            {
                cmd.Add("@ID", id);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void RemoveReportSupervisor(int id)
        {
            using (var cmd = new CmdObj("QStatus_DeleteSupervisor"))
            {
                cmd.Add("@ID", id);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void RemoveAssignment(int id)
        {
            using (var cmd = new CmdObj("QCheck_DeleteAssignedTo"))
            {
                cmd.Add("@ID", id);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void RemoveController(int id)
        {
            using (var cmd = new CmdObj("QCheck_DeleteManager"))
            {
                cmd.Add("@ID", id);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void RemoveAlertee(int id)
        {
            using (var cmd = new CmdObj("QCheck_DeleteAlert"))
            {
                cmd.Add("@ID", id);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ReassignReportUser(int id, int reassignedTo)
        {
            using (var cmd = new CmdObj("QStatus_ReassignReport"))
            {
                cmd.Add("@ID", id);
                cmd.Add("@NewGroupID", reassignedTo);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ReassignReportSupervisor(int id, int reassignedTo)
        {
            using (var cmd = new CmdObj("QStatus_ReassignSupervisor"))
            {
                cmd.Add("@ID", id);
                cmd.Add("@NewGroupID", reassignedTo);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ReassignAssignment(int id, int reassignedTo, bool status)
        {
            using (var cmd = new CmdObj("QCheck_ReassignTask"))
            {
                cmd.Add("@ID", id);
                cmd.Add("@GroupID", reassignedTo);
                cmd.Add("@Status", status);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ReassignController(int id, int reassignedTo)
        {
            using (var cmd = new CmdObj("QCheck_ReassignController"))
            {
                cmd.Add("@ID", id);
                cmd.Add("@NewGroupID", reassignedTo);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ReassignAlertee(int id, int reassignedTo)
        {
            using (var cmd = new CmdObj("QCheck_ReassignAlert"))
            {
                cmd.Add("@ID", id);
                cmd.Add("@NewGroupID", reassignedTo);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ClearTaskControllers(int checklistID)
        {
            using (var cmd = new CmdObj("QCheck_ClearControllersForChecklist"))
            {
                cmd.Add("@ChecklistID", checklistID);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void AddCheckListManager(int groupID, int checklistID)
        {
            using (var cmd = new CmdObj("QCheck_AddManager"))
            {
                cmd.Add("@GroupID", groupID);
                cmd.Add("@ChecklistID", checklistID);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

	}

	public class BulkAssignment : ITaskDetails
	{
		public int Id { get; set; }
		public string Name { get; set; }
		public string NextDue { get; set; }
		public string LastCompleted { get; set; }
		public string Assignees { get; set; }
		public string Controllers { get; set; }
		public string Alertees { get; set; }
		public string Active { get; set; }
		public bool IsHighlighted { get; set; }
	}

    public class ReportListing : IReportListing
    {
        public int ReportID { get; set; }
        public string ReportName { get; set; }
        public string Controllers { get; set; }
        public string SupervisorsIP { get; set; }
    }

    public class TaskDetails : ITaskDetails
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string NextDue { get; set; }
        public string LastCompleted { get; set; }
        public string Assignees { get; set; }
        public string Controllers { get; set; }
        public string Alertees { get; set; }
        public string Active { get; set; }
        public bool IsHighlighted { get; set; }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

