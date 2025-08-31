using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using QProcess.Domain.Models;
using QProcess.Enums;
using QProcess.Extensions;

namespace QProcess.Repositories
{
	public class MyInboxRepository
    {
        private readonly UserTimeZone myTz = QProcess.Session.CurrentSession.UserTimeZone;

        public DateTime GetLastViewed(int userId, int reportId)
		{
			using (var cmd = new CmdObj("QStatus_GetLastViewed"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@ReportID", reportId);
				cmd.Add("@LastViewed", SqlDbType.DateTime, ParameterDirection.Output, 8);
				cmd.ExecuteNonQueryWithOutput();
				return myTz.GetLocalTime(Convert.ToDateTime(cmd["@LastViewed"]));
			}
		}

		public IEnumerable<ReportListItem> GetInboxReports(int userId, bool read, InboxViewType viewType, string sortExpression)
		{
			using (var cmd = new CmdObj("QStatus_GetReportsUnreadData"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@Read", read);
				cmd.Add("@ViewType", Convert.ToInt32(viewType));
				var reports = cmd.GetDS();
				reports.Tables[0].DefaultView.Sort = sortExpression;
				var sortedTable = reports.Tables[0].DefaultView.ToTable();
				return sortedTable.AsEnumerable().Select(r => new ReportListItem
					{
						ReportId = Convert.ToInt32(r["ReportID"]),
						LastReportDate = myTz.GetLocalTime(Convert.ToDateTime(r["LastReportDate"])),
						LastViewed = myTz.GetLocalTimeEx(r.GetConvertedNullableValue("LastViewed", Convert.ToDateTime)),
						FullName = Convert.ToString(r["fullname"]),
						IsFav = Convert.ToString(r["IsFav"]) != "non"
					});
			}
		}

        public List<Report> GetMySupervisedReportsList(int userId, bool includeDaysAgo, bool? allRow = null)
        {
            using (var cmd = new CmdObj("QStatus_GetReportList_Supervised"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@InterestedParty", 0);
                cmd.Add("@NamesOnly", 1);
                var results = cmd.GetDS();
                if (allRow.HasValue && allRow.Value)
                {
                    var placeholder = results.Tables[0].NewRow();
                    placeholder[0] = 0;
                    placeholder[1] = "All";
                    results.Tables[0].Rows.InsertAt(placeholder, 0);
                }
                return results.Tables[0].AsEnumerable()
                    .Select(row => new Report
                    {
                        Id = Convert.ToInt32(row["ID"]),
                        Name = Convert.ToString(row["Description"])
                    }).ToList();
            }
        }

        public List<Report> GetMyInterestedPartyReportsList(int userId, bool includeDaysAgo, bool? allRow = null)
        {
            using (var cmd = new CmdObj("QStatus_GetReportList_Supervised"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@InterestedParty", 1);
                cmd.Add("@NamesOnly", 1);
                var results = cmd.GetDS();
                if (allRow.HasValue && allRow.Value)
                {
                    var placeholder = results.Tables[0].NewRow();
                    placeholder[0] = 0;
                    placeholder[1] = "All";
                    results.Tables[0].Rows.InsertAt(placeholder, 0);
                }
                return results.Tables[0].AsEnumerable()
                    .Select(row => new Report
                    {
                        Id = Convert.ToInt32(row["ID"]),
                        Name = Convert.ToString(row["Description"])
                    }).ToList();
            }
        }

		public bool InterestedPartyOnly(int userId)
		{
			using (var cmd = new CmdObj("QStatus_InterestedPartyOnly"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@Result", SqlDbType.Bit, ParameterDirection.Output, 1);
				cmd.ExecuteNonQueryWithOutput();
				return Convert.ToBoolean(cmd["@Result"]);
			}
		}

		public void MarkAsRead(int reportId, int supervisorId)
		{
			using (var cmd = new CmdObj("QStatus_MarkRead"))
			{
				cmd.Add("@ReportID", reportId);
				cmd.Add("@SupervisorID", supervisorId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void ToggleFavoriteReport(int userId, int reportId)
		{
			using (var cmd = new CmdObj("QStatus_ResetFavorite"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@ReportID", reportId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public Dictionary<EmailPreferenceType, bool> GetSupervisorEmailPreferences(int userId)
		{
			using (var cmd = new CmdObj("QStatus_GetSupervisorEmailPreferences"))
			{
				cmd.Add("@UserID", userId);
				cmd.ExecuteNonQueryWithOutput();
				var settings = cmd.GetDS();
				return settings.Tables[0].AsEnumerable()
					.ToDictionary(setting => Convert.ToString(setting["ID"]).FromString<EmailPreferenceType>(), setting => Convert.ToBoolean(setting["SendEmail"]));
			}
		}

		public void SetSupervisorEmailPreference(int userId, EmailPreferenceType type, bool sendEmail)
		{
			using (var cmd = new CmdObj("QStatus_SetSupervisorEmailPreference"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@Type", Convert.ToInt32(type));
				cmd.Add("@SendEmail", sendEmail);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void AddDepartmentSupervisor(int groupId, int reportId)
		{
			using (var cmd = new CmdObj("QStatus_AddDepartmentSuper"))
			{
				cmd.Add("@SupervisorGroupID", groupId);
				cmd.Add("@ReportID", reportId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public string GetSupervisorRole(int userId, int reportId)
		{
			using (var cmd = new CmdObj("QStatus_GetSupervisorRole"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@ReportID", reportId);
				cmd.Add("@Role", SqlDbType.VarChar, ParameterDirection.Output, 20);
				cmd.ExecuteNonQueryWithOutput();
				return Convert.ToString(cmd["@Role"]);
			}
		}

		public IEnumerable<Personnel> GetSupervisorList(int reportId)
		{
			using (var cmd = new CmdObj("QStatus_GetSupervisorList"))
			{
				cmd.Add("@ReportID", reportId);
				var supervisors = cmd.GetDS();
				return supervisors.Tables[0].AsEnumerable().Select(s =>
					new Personnel
						{
							FullName = Convert.ToString(s["FullName"])
						});
			}
		}

		public IEnumerable<Personnel> GetInterestedPartyList(int reportId)
		{
			using (var cmd = new CmdObj("QStatus_GetInterestedPartyList"))
			{
				cmd.Add("@ReportID", reportId);
				var interestedParties = cmd.GetDS();
				return interestedParties.Tables[0].AsEnumerable().Select(s =>
					new Personnel
					{
						FullName = Convert.ToString(s["FullName"])
					});
			}
		}

		public IEnumerable<Personnel> GetUserList(int reportId)
		{
			using (var cmd = new CmdObj("QStatus_GetUserList"))
			{
				cmd.Add("@ReportID", reportId);
				var users = cmd.GetDS();
				return users.Tables[0].AsEnumerable().Select(s =>
					new Personnel
					{
						FullName = Convert.ToString(s["FullName"])
					});
			}
		}

		public IEnumerable<DueDateChange> GetDueDateChanges(int reportId)
		{
			using (var cmd = new CmdObj("QStatus_GetDueDateChanges"))
			{
				cmd.Add("@ReportID", reportId);
				var dates = cmd.GetDS();
				return dates.Tables[0].AsEnumerable().Select(d => new DueDateChange
					{
						Description = Convert.ToString(d["description"]),
						OldDueDate = myTz.GetLocalTime(Convert.ToDateTime(d["ddo"])),
						NewDueDate = myTz.GetLocalTime(Convert.ToDateTime(d["dd"]))
					});
			}
		}

		public void AddConfidentialReport(int reportId)
		{
			using (var cmd = new CmdObj("QStatus_AddDontEmail"))
			{
				cmd.Add("@ReportID", reportId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void RemoveConfidentialReport(int reportId)
		{
			using (var cmd = new CmdObj("QStatus_RemoveDontEmail"))
			{
				cmd.Add("@ReportID", reportId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}
	}

	public class ReportListItem
	{
		public int ReportId { get; set; }
		public DateTime LastReportDate { get; set; }
		public DateTime? LastViewed { get; set; }
		public string FullName { get; set; }
		public bool IsFav { get; set; }
	}

	public class Personnel
	{
		public string FullName { get; set; }
	}

	public class DueDateChange
	{
		public string Description { get; set; }
		public DateTime OldDueDate { get; set; }
		public DateTime NewDueDate { get; set; }
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

