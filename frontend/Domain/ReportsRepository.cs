using System;
using System.Collections.Generic;
using System.Data;
using QProcess.Domain.Models;
using QProcess.Enums;
using QProcess.Extensions;

namespace QProcess.Repositories
{
    public class ReportsRepository
    {
        private readonly UserTimeZone myTz = QProcess.Session.CurrentSession.UserTimeZone;

        public IEnumerable<ReportChecklistStatus> GetOpenChecklist(int userId, string sort, ReportType reportType)
		{
			using (var cmd = new CmdObj("QCheck_GetChecklistStatus"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@sort", sort);
				cmd.Add("@reportType", reportType.GetDescription());
				var reports = cmd.GetDS();
				return reports.Tables[0].AsEnumerable().Select(r => new ReportChecklistStatus
					{
						Id = Convert.ToInt32(r["Identifier"]),
						Task = Convert.ToString(r["Task"]),
						DueDateTime = myTz.GetLocalTime(Convert.ToDateTime(r["Due Date"])),
						AssignedTo = Convert.ToString(r["Assigned To"]),
						StatusReport = Convert.ToString(r["Status Report"]),
						AssigneeUserList = Convert.ToString(r["AssigneeUserList"]),
                        IsOldOverdue = (myTz.GetLocalTime(Convert.ToDateTime(r["Due Date"])) < myTz.GetLocalTimeNow().AddDays(-7) && !(Convert.ToBoolean(r["HasChangeRequest"])) && (Convert.ToString(r["AssigneeUserList"]).Contains(Session.CurrentSession.QUser.Id.ToString())))
					});
			}
		}

		public IEnumerable<ThreeDayChecklistStatusSummary> GetThreeDayChecklistSummary(ThreeDayDropdown value)
		{
			string storedProcedure = "";
			switch (value)
			{
				case ThreeDayDropdown.ControllerNow:
					storedProcedure = "QCheck_3DayODRpt_Ctrl_Now_Summary";
					break;
				case ThreeDayDropdown.Controller2Week:
					storedProcedure = "QCheck_3DayODRpt_Ctrl_2Wk_Summary";
					break;
				case ThreeDayDropdown.AssigneeNow:
					storedProcedure = "QCheck_3DayODRpt_Assn_Now_Summary";
					break;
				case ThreeDayDropdown.Assignee2Week:
					storedProcedure = "QCheck_3DayODRpt_Assn_2Wk_Summary";
					break;
			}
			using (var cmd = new CmdObj(storedProcedure))
			{
				var summaries = cmd.GetDS();
				return summaries.Tables[0].AsEnumerable().Select(s => new ThreeDayChecklistStatusSummary
					{
						Person = Convert.ToString(s["Person"]),
						DaysOverdue = Convert.ToInt32(s["Overdue3Days"])
					});
			}
		}

		public IEnumerable<ThreeDayChecklistStatusDetail> GetThreeDayChecklistDetail(ThreeDayDropdown value)
		{
			string storedProcedure = "";
			switch (value)
			{
				case ThreeDayDropdown.ControllerNow:
					storedProcedure = "QCheck_3DayODRpt_Ctrl_Now_Detail";
					break;
				case ThreeDayDropdown.Controller2Week:
					storedProcedure = "QCheck_3DayODRpt_Ctrl_2Wk_Detail";
					break;
				case ThreeDayDropdown.AssigneeNow:
					storedProcedure = "QCheck_3DayODRpt_Assn_Now_Detail";
					break;
				case ThreeDayDropdown.Assignee2Week:
					storedProcedure = "QCheck_3DayODRpt_Assn_2Wk_Detail";
					break;
			}
			using (var cmd = new CmdObj(storedProcedure))
			{
				var summaries = cmd.GetDS();
				return summaries.Tables[0].AsEnumerable().Select(s => new ThreeDayChecklistStatusDetail
				{
					Person = Convert.ToString(s["Person"]),
					Checklist = Convert.ToString(s["Checklist"]),
					Assignees = Convert.ToString(s["Assignees"]),
					DueDateTime = myTz.GetLocalTime(Convert.ToDateTime(s["Due"]))
				});
			}
		}

		public IEnumerable<UserTask> GetUserTasksReport(int? userId, string search)
		{
			using (var cmd = new CmdObj("QCheck_UserTasksReport"))
			{
				if(userId.HasValue)
					cmd.Add("@UserID", userId.Value);
				else
					cmd.Add("@UserID", DBNull.Value);
				cmd.Add("@Search", search);
				var tasks = cmd.GetDS();
				return tasks.Tables[0].AsEnumerable().Select(t => new UserTask
					{
						Task = Convert.ToString(t["Task"]),
						Assignees = Convert.ToString(t["Assignees"]),
						Controllers = Convert.ToString(t["Controllers"]),
						DueDateTime = myTz.GetLocalTime(Convert.ToDateTime(t["Due"])),
						CompletedDateTime = myTz.GetLocalTimeEx(t.GetConvertedNullableValue("Completed", Convert.ToDateTime)),
						Schedule = Convert.ToString(t["Schedule"])
					});
			}
		}

		public IEnumerable<CompletedChecklist> GetCompletedChecklists(int userId, int memberId, DateTime startDate, DateTime endDate, string sort)
		{
			startDate = myTz.GetSystemTime(startDate);
			endDate = myTz.GetSystemTime(endDate);

			endDate = endDate.Date + new TimeSpan(23, 59, 00);
			using (var cmd = new CmdObj("QCheck_GetCompletedChecklists"))
			{
				cmd.Add("@loginID", userId);
				cmd.Add("@member", memberId);
				cmd.Add("@checklistID", -1);
				cmd.Add("@starting", startDate);
				cmd.Add("@ending", endDate);
				cmd.Add("@sort", sort);
				var completed = cmd.GetDS();
				return completed.Tables[0].AsEnumerable().Select(c => new CompletedChecklist
					{
						Id = Convert.ToInt32(c["Identifier"]),
						Type = Convert.ToInt32(c["type"]),
						Task = Convert.ToString(c["Task"]),
						CompletedBy = Convert.ToString(c["Completed By"]),
						DueDateTime = myTz.GetLocalTime(Convert.ToDateTime(c["Due Date"])),
						CompletedOn = myTz.GetLocalTime(Convert.ToDateTime(c["Completed On"])),
                    IsNA = Convert.ToBoolean(c["IsNA"]),
                    NAReason = Convert.ToString(c["NAReason"]),
						Sort = Convert.ToString(c["Sort"])
					});

			}
		}

		public bool SendOverdueMessageEmails(int userId, string recipientIds, string message)
		{
			try
			{
				using (var cmd = new CmdObj("QCheck_MessageToOverdues_Email"))
				{
					cmd.Add("@UserID", userId);
					cmd.Add("@RecipientIDs", recipientIds);
					cmd.Add("@Message", message);
					cmd.ExecuteNonQueryWithOutput();
				}
			}
			catch (Exception)
			{
				return false;
			}
			return true;
		}
	}

	public class ReportChecklistStatus
	{
		public int Id { get; set; }
		public string Task { get; set; }
		public DateTime DueDateTime { get; set; }
		public string AssignedTo { get; set; }
		public string StatusReport { get; set; }
		public string AssigneeUserList { get; set; }
        public bool IsOldOverdue { get; set; }
	}

	public class ThreeDayChecklistStatusSummary
	{
		public string Person { get; set; }
		public int DaysOverdue { get; set; }
	}

	public class ThreeDayChecklistStatusDetail
	{
		public string Person { get; set; }
		public string Checklist { get; set; }
		public string Assignees { get; set; }
		public DateTime DueDateTime { get; set; }
	}

	public class UserTask
	{
		public string Task { get; set; }
		public string Assignees { get; set; }
		public string Controllers { get; set; }
		public DateTime DueDateTime { get; set; }
		public DateTime? CompletedDateTime { get; set; }
		public string Schedule { get; set; }
	}

	public class CompletedChecklist
	{
		public int Id { get; set; }
		public int Type { get; set; }
		public string Task { get; set; }
		public string CompletedBy { get; set; }
		public DateTime DueDateTime { get; set; }
		public DateTime CompletedOn { get; set; }
		public string Sort { get; set; }
        public bool IsNA { get; set; }
        public string NAReason { get; set; }
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

