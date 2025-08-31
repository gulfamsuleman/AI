using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading;
using System.Text;
using QProcess.Enums;
using QProcess.Extensions;
using System.Data.SqlClient;
using QProcess.Domain.Models;

namespace QProcess.Repositories
{
    public class StatusReportRepository
    {
        private readonly UserTimeZone myTz = QProcess.Session.CurrentSession.UserTimeZone;

        // Manage Reports
        public int AddReport(int groupId)
		{
			using (var cmd = new CmdObj("QStatus2_AddReport"))
			{
				cmd.Add("@GroupID", groupId);
				cmd.Add("@ReturnID", SqlDbType.Int, ParameterDirection.Output, 32);
				cmd.ExecuteNonQueryWithOutput();
				return (int)cmd["@ReturnID"];
			}
		}

		public void SaveReport(int reportId, string name)
		{
			using (var cmd = new CmdObj("QStatus_UpdateReport"))
			{
				cmd.Add("@ReportID", reportId);
				cmd.Add("@Name", name);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void DeleteReport(int reportId)
		{
			using (var cmd = new CmdObj("QStatus_DeleteReport"))
			{
				cmd.Add("@ReportID", reportId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		// Sections
		public IEnumerable<Section> GetSectionsList(int reportId, bool deleted)
		{
			using (var cmd = new CmdObj("QStatus_GetSections"))
			{
				cmd.Add("@ReportID", reportId);
				cmd.Add("@IsDeleted", deleted);
				var results = cmd.GetDS();
				return results.Tables[0].AsEnumerable().Select(row => new Section
				{
					Id = (int)row["ID"],
					Name = (string)row["Description"]
				});
			}
		}

		public void EditSection(int sectionId, string name)
		{
			using (var cmd = new CmdObj("QStatus_UpdateSectionName"))
			{
				cmd.Add("@TaskId", sectionId);
				cmd.Add("@Description", name);
				cmd.ExecuteNonQueryWithOutput();
			}
			ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportBySectionId, sectionId);
		}

		public int AddSection(int reportId)
		{
			using (var cmd = new CmdObj("QStatus2_AddSection"))
			{
				cmd.Add("@ReportID", reportId);
				cmd.Add("@ReturnID", SqlDbType.Int, ParameterDirection.Output, 32);
				cmd.ExecuteNonQueryWithOutput();
				ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportByReportId, reportId);
				return (int)cmd["@ReturnID"];
			}
		}

		public void RestoreDeleteSection(int sectionId)
		{
			using (var cmd = new CmdObj("QStatus_DeleteRestoreSection"))
			{
				cmd.Add("@TaskID", sectionId);
				cmd.ExecuteNonQueryWithOutput();
			}
			ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportBySectionId, sectionId);
		}

		public void MoveSection(int fromSectionId, int toSectionId)
		{
			using (var cmd = new CmdObj("QStatus_MoveSection"))
			{
				cmd.Add("@ID", fromSectionId);
				cmd.Add("@MoveTo", toSectionId);
				cmd.ExecuteNonQueryWithOutput();
			}
			ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportBySectionId, fromSectionId);
		}
		
		// Attorney Client
		public bool GetAttorneyClient(int reportId)
		{
			using (var cmd = new CmdObj("QStatus_IsConfidential"))
			{
				cmd.Add("@ReportID", reportId);
				cmd.Add("@IsConfidential", SqlDbType.Bit, ParameterDirection.Output, 1);
				cmd.ExecuteNonQueryWithOutput();
				return Convert.ToBoolean(cmd["@IsConfidential"]);
			}
		}

		public void SetAttorneyClient(int reportId, bool isConfidential)
		{
			int i = isConfidential ? 1 : 0;
			using (var cmd = new CmdObj("QStatus_SaveConfidential"))
			{
				cmd.Add("@ReportID", reportId);
				cmd.Add("@IsConfidential", i);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

        public string GetControllerUserIDsByReportID(int reportId)
        {
            using (var cmd = new CmdObj("QStatus_GetControllerUserIDsByReportID"))
            {
                cmd.Add("@ID", reportId);
                cmd.Add("@ReturnString", SqlDbType.VarChar, ParameterDirection.Output, 1000);
                cmd.ExecuteNonQueryWithOutput();
                return cmd["@ReturnString"].ToString();
            }
        }

        public int GetDefaultReport(int userId)
		{
			var userRepo = new UserRepository();
			var report = userRepo.GetLastReport(userId);

			if (report.HasValue)
				return report.Value;

			using (var cmd = new CmdObj("QStatus_DefaultStatus"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@ReportID", SqlDbType.Int, ParameterDirection.Output, 4);
				cmd.ExecuteNonQueryWithOutput();
				return Convert.ToInt32(cmd["@ReportID"]);
			}
		}

		public bool CheckIsUser (int userId, int reportId)
		{
			using(var cmd = new CmdObj("QStatus_IsUser"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@ReportID", reportId);
				cmd.Add("@IsUser", SqlDbType.Bit, ParameterDirection.Output, 1);
				cmd.ExecuteNonQueryWithOutput();
				return Convert.ToBoolean(cmd["@IsUser"]);
			}
		}

		public int SetUserId(int userId, int reportId)
		{
			using (var cmd = new CmdObj("QStatus_GetReportUser"))
			{
				cmd.Add("@ReportID", reportId);
				cmd.Add("@CheckUserID", userId);
				cmd.Add("@UserID", SqlDbType.Int, ParameterDirection.Output, 4);
				cmd.ExecuteNonQueryWithOutput();
				return Convert.ToInt32(cmd["@UserID"]);
			}
		}

		public bool CheckSupervisor(int userId, int reportId)
		{
            (new UserRepository()).AddPreference(userId, "LastPrintableReport", reportId.ToString());
			using (var cmd = new CmdObj("QStatus_CheckSupervisor"))
			{
				cmd.Add("@SupervisorID", userId);
				cmd.Add("@ReportID", reportId);
				cmd.Add("@IsSupervisor", SqlDbType.Bit, ParameterDirection.Output, 1);
				cmd.ExecuteNonQueryWithOutput();
				return Convert.ToBoolean(cmd["@IsSupervisor"]);
			}
		}

        public int GetCommentColor(int userId, int reportId)
        {
            using (var cmd = new CmdObj("QStatus_GetColor"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@ReportID", reportId);
                cmd.Add("@ColorNum", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                return Convert.ToInt32(cmd["@ColorNum"]);
            }
        }

		public string GetReportName(int reportId, int userId)
		{
			using (var cmd = new CmdObj("QStatus_GetReportName"))
			{
				cmd.Add("@ReportID", reportId);
                cmd.Add("@UserId", userId);
                cmd.Add("@ReportName", SqlDbType.VarChar, ParameterDirection.Output, 16);
				cmd.ExecuteNonQueryWithOutput();
				return Convert.ToString(cmd["@ReportName"]);
			}
		}

		public List<Report> GetMyReportsList(int userId, bool includeDaysAgo, bool? allRow = null)
		{
			using(var cmd = new CmdObj("QStatus_GetReportList"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@IncludeDefault", includeDaysAgo);
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

        public List<Report> GetMyReportsListWithTaskCount(int userId, bool includeDaysAgo, bool? allRow = null)
        {
            using (var cmd = new CmdObj("QStatus_GetReportListAndTaskCount"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@IncludeDefault", includeDaysAgo);
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
                        Name = Convert.ToString(row["Description"]),
						TaskCount = (int)row["ActiveTaskCount"]
                    }).ToList();
            }
        }

        public List<ReportHeader> GetMyReportsListHeaders(int userId, bool? allRow = null)
		{
			using (var cmd = new CmdObj("QStatus_GetReportList"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@IncludeDefault", 1);
				var results = cmd.GetDS();
				if (allRow.HasValue && allRow.Value)
				{
					var placeholder = results.Tables[0].NewRow();
					placeholder[0] = 0;
					placeholder[1] = "All";
					results.Tables[0].Rows.InsertAt(placeholder, 0);
				}
				return results.Tables[0].AsEnumerable()
					.Select(row => new ReportHeader
						{
							ID = (int)row["ID"],
							Name = (string)row["Description"]
						}).ToList();
			}
		}

		public List<ReportHeader> GetReportListSupervised(int userId, bool interestedParty)
		{
			using(var cmd = new CmdObj("QStatus_GetReportList_Supervised"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@InterestedParty", interestedParty?1:0);
				cmd.Add("@NamesOnly",0);
				return cmd.GetDS().Tables[0].AsEnumerable()
					.Select(r => new ReportHeader
					    {
						    ID = (int) r["ID"],
						    Name = (string) r["description"]
					    }).ToList();
			}
		}

        public List<ReportHeader> GetReports()
        {
            using (var cmd = new CmdObj("QStatus_GetReports"))
            {
                return cmd.GetDS().Tables[0].AsEnumerable()
                    .Select(r => new ReportHeader
                    {
                        ID = (int)r["ID"],
                        Name = (string)r["description"]
                    }).ToList();
            }
        }

        public List<ReportHeaderSupervised> GetReportListSupervisedAndIP(int userId)
        {
			List<ReportHeaderSupervised> ip;
            List<ReportHeaderSupervised> supervised;
            bool interestedParty = true;
            using (var cmd = new CmdObj("QStatus_GetReportList_Supervised"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@InterestedParty", interestedParty ? 1 : 0);
                cmd.Add("@NamesOnly", 1);
                ip = cmd.GetDS().Tables[0].AsEnumerable()
                    .Select(r => new ReportHeaderSupervised
                    {
                        ID = (int)r["QStatusSupervisorID"],
                        Name = (string)r["description"],
						GroupName = (string)r["GroupName"],
						InterestedParty = interestedParty
                    }).ToList();
            }

            interestedParty = false;
            using (var cmd = new CmdObj("QStatus_GetReportList_Supervised"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@InterestedParty", interestedParty ? 1 : 0);
                cmd.Add("@NamesOnly", 1);
                supervised = cmd.GetDS().Tables[0].AsEnumerable()
                    .Select(r => new ReportHeaderSupervised
                    {
                        ID = (int)r["QStatusSupervisorID"],
                        Name = (string)r["description"],
                        GroupName = (string)r["GroupName"],
                        InterestedParty = interestedParty
                    }).ToList();
            }

			return supervised.Concat(ip).ToList();
        }

        public IEnumerable<ExistingTasksHeader> GetExistingTasksToAdd(int userId, int reportId, string sort = "")
		{
            using (var cmd = new CmdObj("QCheck_GetMyTasksToAddExcludeAlreadyAdded"))
            {
				cmd.Add("@UserID", userId);
                cmd.Add("@ReportID", reportId);
                var tasks = cmd.GetDS();

                if (sort == "name") // Ignores duetime as that is the default sorting
                    tasks.Tables[0].DefaultView.Sort = "name";
                var sortedTasks = tasks.Tables[0].DefaultView.ToTable();
                return sortedTasks.AsEnumerable().Select(t => new ExistingTasksHeader
                {
                    ID = Convert.ToInt32(t["ID"]),
                    Name = Convert.ToString(t["Name"]),
                    DueDate = myTz.GetLocalTime(Convert.ToDateTime(t["duetime"])),
                    DueTime = myTz.GetLocalTime(Convert.ToDateTime(t["duedt"])),
                    Assignees = Convert.ToString(t["Assignees"])
                });
            }
		}

        public IEnumerable<ExistingTasksAssignee> GetExistingTasksToAddAssignees(int userId)
        {
            using (var cmd = new CmdObj("QCheck_GetMyTasksToAddAssignees"))
            {
                cmd.Add("@UserID", userId);
                var tasks = cmd.GetDS();

                return tasks.Tables[0].DefaultView.ToTable().AsEnumerable().Select(t => new ExistingTasksAssignee
                {
                    Name = Convert.ToString(t["Name"])
                });
            }
        }

        public int AddExistingTaskToSection(int instanceId, int taskType)
        {
            using (var cmd = new CmdObj("QCheck_AddInstanceTaskType"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@TaskType", taskType);
                cmd.Add("@ID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByInstanceId, instanceId);
                return (int)cmd["@ID"];
            }
        }

		public int AddExistingTaskToSectionOutput (int instanceId, int taskType)
		{
			using (var cmd = new CmdObj("QCheck_AddInstanceTaskTypeOutput"))
			{
				cmd.Add("@InstanceID", instanceId);
				cmd.Add("@TaskType", taskType);
				cmd.Add("@acId", SqlDbType.Int, ParameterDirection.Output, 4);
				cmd.ExecuteNonQueryWithOutput();
				ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByInstanceId, instanceId);
				return (int)cmd["@acId"];
			}
		}

        public string AddTaskToStatusSection(int reportSectionId, int activeChecklistId = 0, string taskName = null)
        {
            try
            {
                using (var cmd = new CmdObj("QStatus_AddTasksToStatusSection"))
                {
                    cmd.Add("@ReportSectionId", reportSectionId);
                    cmd.Add("@ActiveChecklistId", activeChecklistId);
                    cmd.Add("@TaskName", taskName);
                    cmd.ExecuteNonQueryWithOutput();

					//int returnValue = 0;

                    return $"Task successfully added to report";
                }
            }
            catch (SqlException ex)
            {
                var message = ex.Message.ToString();
                return message;
            }
        }

        public int AddExistingTaskToSectionThroughChat(int instanceId, int taskType)
        {
            using (var cmd = new CmdObj("QCheck_AddInstanceTaskType"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@TaskType", taskType);
                cmd.Add("@ID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                return (int)cmd["@ID"];
            }
        }

        public List<ReportEmailHeader> GetReportEmails(int reportId, int taskId)
		{
			using(var cmd = new CmdObj("QStatus_GetReportEmails"))
			{
				cmd.Add("@ReportID", reportId);
				cmd.Add("@TaskID", taskId);
				return cmd.GetDS().Tables[0].AsEnumerable()
					.Select(row =>new ReportEmailHeader
						{
							ID = (int) row["ID"],
							Email = (string) row["Email"],
							FullName = (string) row["Fullname"]
						}).ToList();
			}
		}

		public List<ReportCommentItems> GetTodaysCommentedReports(int userId, int reportId, DateTime? deletedDate=null,
            int[] selectedComments=null, bool moveCompleted = false, string timeZones = "")
		{
			deletedDate = myTz.GetSystemTimeEx(deletedDate);

			using (var cmd = new CmdObj("QStatus_GetReportTodaysComments"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@ReportID", reportId);
				if (deletedDate != null)
					cmd.Add("@deletedDate", deletedDate);
                if (selectedComments != null)
                    cmd.Add("@selectedComments", selectedComments.Aggregate(new StringBuilder(), (sb, id) => sb.AppendFormat("{0},", id), (sb) => sb.RemoveLast().ToString()));
                cmd.Add("@MoveCompleted", moveCompleted);
				if (timeZones != null)
					cmd.Add("@TimeZones", timeZones);
				return cmd.GetDS().Tables[0].AsEnumerable()
					.Select(row =>
					{
						var reportComment = new ReportCommentItems
						{
                            ID = row.GetConvertedNullableValue("ID", Convert.ToInt32),
                            Description = row.GetConvertedStringValue("Description"),
                            DueDate = row.GetConvertedStringValue("DueDate").IsNullOrBlankOr("0")
								? null
								: myTz.GetLocalTime(DateTime.Parse(row.GetConvertedStringValue("DueDate"))).ToString(),
                            Priority = row.GetConvertedNullableValue("Priority", Convert.ToInt32),
							Comments = row.GetConvertedStringValue("Comments"),
                            UpdatedDate = row.GetConvertedStringValue("UpdatedDate").IsNullOrBlankOr("0")
								? null
								: myTz.GetLocalTime(DateTime.Parse(row.GetConvertedStringValue("UpdatedDate"))).ToString(),
                            Type = row.GetConvertedStringValue("Type"),
							NativeType = Convert.ToInt32(row["NativeType"]),
                            IsDeleted = row.GetConvertedNullableValue("IsDeleted", Convert.ToBoolean),
							ReturnOrder = Convert.ToInt32(row["ReturnOrder"]),
                            TaskType = row.GetConvertedStringValue("TaskType"),
							PriorityChanged = Convert.ToBoolean(row["PriorityChanged"]),
							DueDateChanged = Convert.ToBoolean(row["DueDateChanged"]),
							TaskNameChanged = Convert.ToBoolean(row["TaskNameChanged"]),
							NewTask = Convert.ToBoolean(row["NewTask"]),
                            AssignedTo = row.GetConvertedStringValue("AssignedTo")
						};
						return reportComment;
					}).ToList();
			}
		}

        public List<ReportCommentItems> GetLatestCommentedReports(int userId, int reportId, DateTime? deletedDate = null,
            int[] selectedComments = null, bool moveCompleted = false, DateTime? commentsSince = null, string timeZones = "")
		{
			deletedDate = myTz.GetSystemTimeEx(deletedDate);
			commentsSince = myTz.GetSystemTimeEx(commentsSince);

			using(var cmd = new CmdObj("QStatus_GetReportLatestComments"))
			{
                cmd.Add("@UserID", userId);
                cmd.Add("@ReportID", reportId);
                if (deletedDate != null)
                    cmd.Add("@deletedDate", deletedDate);
                if (selectedComments != null)
                    cmd.Add("@selectedComments", selectedComments.Aggregate(new StringBuilder(), (sb, id) => sb.AppendFormat("{0},", id), (sb) => sb.RemoveLast().ToString()));
                cmd.Add("@MoveCompleted", moveCompleted);
                if (commentsSince != null)
                    cmd.Add("@commentsSince", commentsSince);
                if (timeZones != null)
                    cmd.Add("@TimeZones", timeZones);
                return cmd.GetDS().Tables[0].AsEnumerable()
					.Select(row => {
						var reportComment = new ReportCommentItems
							{
								ID = row.GetConvertedNullableValue("ID", Convert.ToInt32),
								Description = row.GetConvertedStringValue("Description"),
								DueDate = row.GetConvertedStringValue("DueDate").IsNullOrBlankOr("0") 
									? row.GetConvertedStringValue("DueDate")
                                    : myTz.GetLocalTime(DateTime.Parse(row.GetConvertedStringValue("DueDate"))).ToString(),
								Priority = row.GetConvertedNullableValue("Priority", Convert.ToInt32),
								Comments = row.GetConvertedStringValue("Comments"),
								UpdatedDate = row.GetConvertedStringValue("UpdatedDate").IsNullOrBlankOr("0") 
									? row.GetConvertedStringValue("UpdatedDate")
                                    : myTz.GetLocalTime(DateTime.Parse(row.GetConvertedStringValue("UpdatedDate"))).ToString(),
								Type = row.GetConvertedStringValue("Type"),
								NativeType = Convert.ToInt32(row["NativeType"]),
								IsDeleted = row.GetConvertedNullableValue("IsDeleted", Convert.ToBoolean),
								ReturnOrder = Convert.ToInt32(row["ReturnOrder"]),
								TaskType = row.GetConvertedStringValue("TaskType"),
								PriorityChanged = Convert.ToBoolean(row["PriorityChanged"]),
								DueDateChanged = Convert.ToBoolean(row["DueDateChanged"]),
								TaskNameChanged = Convert.ToBoolean(row["TaskNameChanged"]),
								NewTask = Convert.ToBoolean(row["NewTask"]),
								AssignedTo = row.GetConvertedStringValue("AssignedTo")
							};
						return reportComment;
					}).ToList();
			}
		} 

        public List<ReportCommentItems> GetReportLatestUrgent(int userId, int reportId, DateTime? deletedDate = null, string timeZones = "")
        {
			deletedDate = myTz.GetSystemTimeEx(deletedDate);

            using (var cmd = new CmdObj("QStatus_GetReportLatestUrgent"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@ReportID", reportId);
                if (deletedDate != null)
                    cmd.Add("@deletedDate", deletedDate);
                if (timeZones != null)
                    cmd.Add("@TimeZones", timeZones);
                return cmd.GetDS().Tables[0].AsEnumerable()
                    .Select(row =>
                    {
                        var reportComment = new ReportCommentItems
                        {
                            ID = row.GetConvertedNullableValue("ID", Convert.ToInt32),
                            Description = row.GetConvertedStringValue("Description"),
                            DueDate = row.GetConvertedStringValue("DueDate").IsNullOrBlankOr("0") 
								? null 
								: myTz.GetLocalTime(DateTime.Parse(row.GetConvertedStringValue("DueDate"))).ToString(),
                            Priority = row.GetConvertedNullableValue("Priority", Convert.ToInt32),
                            Comments = row.GetConvertedStringValue("Comments"),
                            UpdatedDate = row.GetConvertedStringValue("UpdatedDate").IsNullOrBlankOr("0") 
								? null 
								: myTz.GetLocalTime(DateTime.Parse(row.GetConvertedStringValue("UpdatedDate"))).ToString(),
                            Type = row.GetConvertedStringValue("Type"),
                            NativeType = Convert.ToInt32(row["NativeType"]),
                            IsDeleted = row.GetConvertedNullableValue("IsDeleted", Convert.ToBoolean),
                            ReturnOrder = Convert.ToInt32(row["ReturnOrder"]),
                            PriorityChanged = Convert.ToBoolean(row["PriorityChanged"]),
                            DueDateChanged = Convert.ToBoolean(row["DueDateChanged"]),
                            TaskNameChanged = Convert.ToBoolean(row["TaskNameChanged"]),
                            NewTask = Convert.ToBoolean(row["NewTask"]),
                            AssignedTo = row.GetConvertedStringValue("AssignedTo")
                        };
                        return reportComment;
                    }).ToList();
            }
        }

		public string GetTimeZonesForUsers(string userIdString)
		{
            using (var db = new CmdObj("UserTimeZones_GET"))
            {
				db.Add("@userIds", userIdString);
                var timeZones = db.GetScalar().ToString();

                return timeZones ?? "";
            }
        }

        private string ParseComment(string s)
        {
            s = s.Replace("\n", "<br>");
            s = ParseLinks(s);
            return s;
        }

        private string ParseLinks(string t)
        {
            string keepEnd;
            string keepStart;
            string linkPart;

            while (t.Contains("[link]") && t.Contains("[/link]")) {
                keepEnd = t.Substring(t.IndexOf("[/link]") + 7);
                keepStart = t.Substring(0, t.IndexOf("[link]"));
                linkPart = t.Substring(t.IndexOf("[link]") + 6, (t.IndexOf("[/link]") - (t.IndexOf("[link]") + 6)));
                t = keepStart + "<!--a1--><a href='" + linkPart + "' target='_new' onclick='event.cancelBubble=true;'><!--/a1-->" + linkPart + "<!--a2--></a><!--/a2-->" + keepEnd;
            }

            return t;
        }

		public NewCommentReturn CreateNewComment(int taskId, int userId, string comments)
		{
			using (var cmd = new CmdObj("QStatus_CreateNewComment"))
			{
				cmd.Add("@TaskID", taskId);
				cmd.Add("@UserID", userId);
				cmd.Add("@Comments", ParseComment(comments));
				cmd.Add("@NewID", SqlDbType.Int, ParameterDirection.Output, 4);
				cmd.Add("@CommentsInitials", SqlDbType.VarChar, ParameterDirection.Output, 100);
				cmd.Add("@FullName", SqlDbType.VarChar, ParameterDirection.Output, 50);
				cmd.ExecuteNonQueryWithOutput();
				ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByTaskId, taskId);
				return new NewCommentReturn
				{
					Id = Convert.ToInt32(cmd["@NewID"]),
					Initials = Convert.ToString(cmd["@CommentsInitials"]),
					FullName = Convert.ToString(cmd["@CommentsInitials"]),
					Indentaion = 0
				};
			}
		}

        public string CreateNewComment(string comments, int activeChecklistId = 0, string taskName = null)
        {
			try
			{
				using (var cmd = new CmdObj("QStatus_CreateNewCommentFromApi"))
				{
					cmd.Add("@Comments", ParseComment(comments));
					cmd.Add("@activeChecklistId", activeChecklistId);
					cmd.Add("@taskName", taskName);
					cmd.Add("@NewID", SqlDbType.Int, ParameterDirection.Output, 4);
					cmd.Add("@CommentInitials", SqlDbType.VarChar, ParameterDirection.Output, 100);
					cmd.Add("@FullName", SqlDbType.VarChar, ParameterDirection.Output, 50);
					cmd.ExecuteNonQueryWithOutput();
					var result = string.IsNullOrEmpty(taskName) ? activeChecklistId.ToString() : taskName;
					return $"Comment successfully added to Task: {result}";
				}
			} catch (SqlException ex)
			{
				var result = ex.Message.ToString();
				return $"Comment was not added to task due to the following: {result}";
			}
        }

        public NewCommentReturn ReplyToComment(int commentId, int userId, string comments, int taskId)
		{
			using(var cmd = new CmdObj("QStatus_CreateQuickReply"))
			{
				cmd.Add("@CommentID", commentId);
				cmd.Add("@Comments", ParseComment(comments));
				cmd.Add("@UserID", userId);
				cmd.Add("@ReplyID", SqlDbType.Int, ParameterDirection.Output, 4);
				cmd.Add("@CommentsInitials", SqlDbType.VarChar, ParameterDirection.Output, 100);
				cmd.Add("@FullName", SqlDbType.VarChar, ParameterDirection.Output, 50);
				cmd.Add("@tabin", SqlDbType.Int, ParameterDirection.Output, 4);
				cmd.ExecuteNonQueryWithOutput();
				ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByTaskId, taskId);
				return new NewCommentReturn
				{
					Id = Convert.ToInt32(cmd["@ReplyID"]),
					Initials = Convert.ToString(cmd["@CommentsInitials"]),
					FullName = Convert.ToString(cmd["@FullName"]),
					Indentaion = Convert.ToInt32(cmd["@tabin"]) * 30
				};
			}
		}

		public NewCommentReturn EditComment(int commentId, string comments, int taskId)
		{
			using(var cmd = new CmdObj("QStatus_EditComment"))
			{
				cmd.Add("@CommentID", commentId);
				cmd.Add("@Comments", ParseComment(comments));
				cmd.Add("@CommentsInitials", SqlDbType.VarChar, ParameterDirection.Output, 100);
				cmd.Add("@FullName", SqlDbType.VarChar, ParameterDirection.Output, 50);
				cmd.Add("@tabin", SqlDbType.Int, ParameterDirection.Output, 4);
				cmd.ExecuteNonQueryWithOutput();
				ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByTaskId, taskId);
				return new NewCommentReturn
				{
					Id = Convert.ToInt32(cmd["@CommentID"]),
					Initials = Convert.ToString(cmd["@CommentsInitials"]),
					FullName = Convert.ToString(cmd["@FullName"]),
					Indentaion = Convert.ToInt32(cmd["@tabin"])*30
				};
			}
		}

        public List<ReportComment> GetRelatedComments(int taskId, int userId)
        {
            using (var cmd = new CmdObj("QStatus_GetRelatedComments"))
            {
				cmd.Add("@TaskId", taskId);
				cmd.Add("@UserId", userId);
                return cmd.GetDS().Tables[0].AsEnumerable()
                    .Select(row => new ReportComment
                    {
                        Id = (int)row["ID"],
                        ForeignKeyId = (int)row["ForeignKeyID"],
                        Comments = (string)row["Comments"],
                        DisplayOrder = (int)row["DisplayOrder"],
                        TabIn = (int)row["TabIn"],
                        CommentDate = myTz.GetLocalTime((DateTime)row["CommentDt"]),
                        Initials = (string)row["Initials"],
                        UserId = (int)row["UserID"],
                        ReplyId = RideTheLightning.GetConvertedNullableValue(row, "ReplyID", Convert.ToInt32),
                        SpecialTask = (bool)row["SpecialTask"],
                        TaskId = (int)row["TaskID"],
                        FullName = (string)row["FullName"]
                    }).ToList();
            }
        }

		// Timeline
		public List<Timeline> GetReportTimeline(int reportId, int userId)
		{
			using (var cmd = new CmdObj("QStatus_GetReportTimeline"))
			{
				cmd.Add("@ReportID", reportId);
				cmd.Add("@UserID", userId);
				var result = cmd.GetDS().Tables[0].AsEnumerable()
					.Select(r => new Timeline
						{
							DueDate = myTz.GetLocalTime(DateTime.Parse((string)r["DueDate"])).Date.ToShortDateString(),
							Description = (string)r["Description"],
							Overdue = (int)r["Overdue"]
						}).ToList();
				return result;
			}
		}

		// Complete Task
		public string CompleteTask(bool isComplete, int taskId, int userId, int reportId)
		{
			// Something happened, could not complete the task
			if (!isComplete)
			{
				return "<strong>Cannot mark the task as completed - please complete the checklist steps first.</strong>";
			}
			// Task is associated with a section, update section
			if (reportId > 0)
			{
				using (var cmd = new CmdObj("QCheck_GetSectionInfoForTask"))
				{
					cmd.Add("@taskId", taskId);
					cmd.Add("@reportId", reportId);
					cmd.Add("@sectionID", SqlDbType.Int, ParameterDirection.Output, 4);
					cmd.Add("@sectionName", SqlDbType.VarChar, ParameterDirection.Output, 200);
					cmd.ExecuteNonQueryWithOutput();
					return Convert.ToString(cmd["@sectionID"]) + "|" + Convert.ToString(cmd["@sectionName"]);
				}

			}
			// Task is just associated with a user, return the UserName
			using (var cmd = new CmdObj("QCheck_GetUserName"))
			{
				cmd.Add("@ID", userId);
				cmd.Add("@UserName", SqlDbType.VarChar, ParameterDirection.Output, 100);
				cmd.ExecuteNonQueryWithOutput();
				return Convert.ToString(cmd["@UserName"]);
			}
		}

		// Reopen Task
		public string ReOpenTask(int taskId, int reportId)
		{
			// Report was passed in
			if (reportId > 0)
			{
				using (var cmd = new CmdObj("QCheck_GetSectionInfoForTask"))
				{
					cmd.Add("@taskid", taskId);
					cmd.Add("@reportid", reportId);
					cmd.Add("@sectionID", SqlDbType.Int, ParameterDirection.Output, 4);
					cmd.Add("@sectionName", SqlDbType.VarChar, ParameterDirection.Output, 200);
					cmd.ExecuteNonQueryWithOutput();
					return Convert.ToString(cmd["@sectionId"]) + "|" + Convert.ToString(cmd["@sectionName"]);
				}
			}
			// Report not passed in
			using (var cmd = new CmdObj("QCheck_GetDueDate"))
			{
				cmd.Add("@ID", taskId);
				cmd.Add("@DueDate", SqlDbType.DateTime, ParameterDirection.Output, 8);
				cmd.ExecuteNonQueryWithOutput();
				return Convert.ToString(myTz.GetLocalTime((DateTime)cmd["@DueDate"]));
			}
		}

		public void RestoreTask(int taskId)
		{
			using (var cmd = new CmdObj("QCheck_RestoreTask"))
			{
				cmd.Add("@ActiveChecklistID", taskId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void UpdateMyTask(int taskId, int userId, string description, DateTime? dueDate, int? priority, DateTime? reminderDate)
		{
			//dueDate doesn't have the time component; QCheck_GetUserChecklists is an easy way to get it
			using(var db = new CmdObj("QCheck_GetTaskByACID"))
			{
				db.Add("@activeChecklistID", taskId);
				var currDueTime = db.GetDS().Tables[0].Rows[0]["dueTime"].ToDateTimeEx().GetValueOrDefault();
				var currDueTimeLocal = myTz.GetLocalTime(currDueTime);
				dueDate = dueDate + (currDueTimeLocal - currDueTimeLocal.Date);

				if(reminderDate.HasValue)
					reminderDate = reminderDate.Value.Date + (currDueTimeLocal - currDueTimeLocal.Date);
            }

			//*now* we can convert to UTC
			dueDate = myTz.GetSystemTimeEx(dueDate);
            reminderDate = myTz.GetSystemTimeEx(reminderDate);

			//as a quirk of the stored procedure, if an empty description is passed to the sproc, it will ignore it
			//taskid and userid are all that are truly required
			using(var cmd = new CmdObj("QStatus_UpdateMyTask"))
			{
				cmd.Add("@TaskID", taskId);
				cmd.Add("@UserID", userId);
				cmd.Add("@Description", description);
				cmd.Add("@DueDate", dueDate);
				cmd.Add("@Priority", priority);
				cmd.Add("@ReminderDate", reminderDate);
				cmd.ExecuteNonQueryWithOutput();
			}
			ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByTaskId, taskId);
		}

		public List<ReportComment> GetLatestComments(int userId, int taskId, int reportId, DateTime? commentsSince=null, int[]selectedComments=null )
		{
			commentsSince = myTz.GetSystemTimeEx(commentsSince);

			using(var cmd = new CmdObj("QStatus_GetLatestComments"))
			{
				cmd.Add("@ReportId", reportId);
				cmd.Add("@TaskId", taskId);
				cmd.Add("@UserId", userId);
				if (commentsSince != null)
					cmd.Add("@CommentsSince", commentsSince);
				if (selectedComments != null)
					cmd.Add("@SelectedComments", string.Join(",", selectedComments));
				return cmd.GetDS().Tables[0].AsEnumerable()
					.Select(row => new ReportComment
						{
							Id=(int)row["ID"],
							ForeignKeyId = (int)row["ForeignKeyID"],
							Comments = (string)row["Comments"],
							DisplayOrder = (int)row["DisplayOrder"],
							TabIn = (int)row["TabIn"],
							CommentDate = (DateTime)row["CommentDt"],
							Initials = (string)row["Initials"],
							UserId = (int)row["UserID"],
							ReplyId = RideTheLightning.GetConvertedNullableValue(row, "ReplyID", Convert.ToInt32),
							SpecialTask = (bool)row["SpecialTask"],
							TaskId = (int)row["TaskID"],
							ColorNum = (int)row["ColorNum"],
							FullName = (string)row["FullName"]
						}).ToList();
			}
		}

		// Add Priorities
		public bool AddPriorities(int userId, int taskId)
		{
			try
			{

				using (var cmd = new CmdObj("PriorityList_AddTask"))
				{
					cmd.Add("@UserID", userId);
					cmd.Add("@ActiveChecklistID", taskId);
					cmd.ExecuteNonQueryWithOutput();
				}
				return true;
			}
			catch (Exception)
			{
				return false;
			}
		}

		public List<Section> GetMySections(int userId)
		{
			using (var cmd = new CmdObj("QStatus_GetMySections"))
			{
				cmd.Add("@UserId", userId);
				var sections = cmd.GetDS();
				return sections.Tables[0].AsEnumerable()
					.Select(r => new Section
					{
						Id = Convert.ToInt32(r["ID"]),
						Name = Convert.ToString(r["Column1"]),
						ReportId = Convert.ToInt32(r["ID1"])
					}
				).ToList();

			}
		}

		public bool CopyTask(int taskId, int sectionId)
		{
			try
			{
				using (var cmd = new CmdObj("QStatus_CopyTask"))
				{
					cmd.Add("@TaskID", taskId);
					cmd.Add("@Type", sectionId);
					cmd.Add("@Copied", SqlDbType.Bit, ParameterDirection.Output, 1);
					cmd.ExecuteNonQueryWithOutput();
					ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByTaskId, taskId);
					return Convert.ToBoolean(cmd["@Copied"]);
				}
			}
			catch (Exception)
			{
				return false;
			}
		}

		public bool MoveTask(int taskId, int sectionId, int reportId)
		{
			try
			{
				using (var cmd = new CmdObj("QStatus_MoveTask"))
				{
					cmd.Add("@ReportID", reportId);
					cmd.Add("@TaskID", taskId);
					cmd.Add("@Type", sectionId);
					cmd.Add("@Moved", SqlDbType.Bit, ParameterDirection.Output, 1);
					cmd.Add("@CurrentTaskType", SqlDbType.Int, ParameterDirection.Output, 8);
					cmd.Add("@NewReportID", SqlDbType.Int, ParameterDirection.Output, 8);
					cmd.Add("@NewSectionName", SqlDbType.VarChar, ParameterDirection.Output, 8);
					cmd.Add("@IsComplete", SqlDbType.Bit, ParameterDirection.Output, 1);
					cmd.ExecuteNonQueryWithOutput();
					ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportByReportId, reportId);
					ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByTaskId, taskId);
					return Convert.ToBoolean(cmd["@Moved"]);
				}
			}
			catch (Exception) 
			{
				return false;
			}
		}

        public bool IsLastControllerByChecklistID(int taskId)
        {
            using (var cmd = new CmdObj("QCheck_IsLastControllerByChecklistID"))
            {
                cmd.Add("@taskID", taskId);
                cmd.Add("@isLastController", SqlDbType.Bit, ParameterDirection.Output, 1);
                cmd.ExecuteNonQueryWithOutput();
                return Convert.ToBoolean(cmd["@isLastController"]);
            }
        }

        // Bulk Update
        public IEnumerable<BulkUpdateTask> GetBulkUpdateTaskList(int reportId)
		{
			using (var cmd = new CmdObj("QCheck_GetReportTaskList"))
			{
				cmd.Add("@ReportID", reportId);
				var tasks = cmd.GetDS();
				return tasks.Tables[0].AsEnumerable().Select(t => new BulkUpdateTask
					{
						Id = Convert.ToInt32(t["id"]),
						Name = Convert.ToString(t["name"]),
						Section = Convert.ToString(t["section"]),
						DueDate = myTz.GetLocalTime(Convert.ToDateTime(t["duetime"])),
					});
			}
		}

		// Change Fonts
		public int ChangeFonts(int userId)
		{
			using (var cmd = new CmdObj("QStatus_ResetFont"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@Font", SqlDbType.Int, ParameterDirection.ReturnValue, 4);
				cmd.ExecuteNonQueryWithOutput();
				return Convert.ToInt32(cmd["@Font"]);
			}
		}

		// Remove Task
		public void RemoveTaskFromReport(int userId, int reportId, int activeChecklistId)
		{
			using (var cmd = new CmdObj("QCheck_RemoveFromReport"))
			{
				cmd.Add("@ActiveChecklistID", activeChecklistId);
				cmd.Add("@ReportID", reportId);
				cmd.Add("@UserID", userId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		// Check for Departments
		public bool CheckForDepartments(int supervisorId)
		{
			using (var cmd = new CmdObj("QStatus_CheckDepartments"))
			{
				cmd.Add("@SupervisorID", supervisorId);
				cmd.Add("@HasDepartments", SqlDbType.Bit, ParameterDirection.Output, 1);
				cmd.ExecuteNonQueryWithOutput();
				return Convert.ToBoolean(cmd["@HasDepartments"]);
			}
		}

		// Add Department Supervisor
		public void AddDepartmentSupervisor(int groupId, int reportId)
		{
			using (var cmd = new CmdObj("QStatus_AddDepartmentSuper"))
			{
				cmd.Add("@SupervisorGroupID", groupId);
				cmd.Add("@ReportID", reportId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

        public int GetColumnWidth(int userId, int reportId)
        {
            using (var cmd = new CmdObj("QStatus_GetColumnWidth"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@ReportID", reportId);
                cmd.Add("@Width", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                return Convert.ToInt32(cmd["@Width"]);
            }
        }

        public void SetColumnWidth(int userId, int reportId, int width)
        {
            using (var cmd = new CmdObj("QStatus_SetColumnWidth"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@ReportID", reportId);
                cmd.Add("@Width", width);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

		public ReportTaskType GetTaskTypeByReport(string reportName, string sectionName)
		{
            using (var cmd = new CmdObj("QStatus_GetTaskTypeByReport"))
            {
                cmd.Add("@ReportName", reportName);
                cmd.Add("@SectionName", sectionName);
                var tasks = cmd.GetDS();
                var result = tasks.Tables[0].AsEnumerable().Select(t => new ReportTaskType
                {
                    Id = Convert.ToInt32(t["ReportID"]),
                    Name = Convert.ToString(t["ReportName"]),
                    Section = Convert.ToString(t["SectionID"]),
                    SectionName = Convert.ToString(t["SectionName"])
                }).FirstOrDefault();

				return result;
            }
        }
	}

	[Serializable]
	public class ReportTaskType
	{
		public int Id;
		public string Name; 
		public string Section;
		public string SectionName;
	}

    [Serializable]
    public class NewCommentReturn
	{
		public int Id;
		public string Initials;
		public string FullName;
		public int Indentaion;
	}

    [Serializable]
    public class ReportComment
	{
		public int Id { get; set; }
		public int ForeignKeyId { get; set; }
		public string Comments { get; set; }
		public int DisplayOrder { get; set; }
		public int TabIn { get; set; }
		public DateTime CommentDate { get; set; }
		public string Initials { get; set; }
		public int UserId { get; set; }
		public int? ReplyId { get; set; }
		public bool SpecialTask { get; set; }
		public int TaskId { get; set; }
		public int ColorNum { get; set; }
		public string FullName { get; set; }
	}

    [Serializable]
    public class ReportCommentItems
	{
		public int? ID { get; set; }
		public string Description { get; set; }
		public string DueDate { get; set; }
		public int? Priority { get; set; }
		public string Comments { get; set; }
		public string UpdatedDate { get; set; }
		public string Type { get; set; }
		public int NativeType { get; set; }
		public bool? IsDeleted { get; set; }
		public int ReturnOrder { get; set; }
		public string TaskType { get; set; }
		public bool PriorityChanged { get; set; }
		public bool DueDateChanged { get; set; }
		public bool TaskNameChanged { get; set; }
		public bool NewTask { get; set; }
        public string AssignedTo { get; set; }
        public bool IsDaily { get; set; }
        public bool? IsRecurring { get; set; }
	}

    [Serializable]
    public class ReportEmailHeader
	{
		public int ID { get; set; }
		public string Email { get; set; }
		public string FullName { get; set; }

	}

    [Serializable]
    public class ExistingTasksHeader
	{
        public int ID { get; set; }
        public string Name { get; set; }
        public DateTime DueDate { get; set; }
        public DateTime DueTime { get; set; }
        public string Assignees { get; set; }
    }

    [Serializable]
    public class ExistingTasksAssignee
    {
        public string Name { get; set; }
    }

    [Serializable]
    public class ReportHeader
	{
		public int ID { get; set; }
		public string Name { get; set; }
    }

    [Serializable]
    public class ReportHeaderSupervised
    {
        public int ID { get; set; }
        public string Name { get; set; }
        public string GroupName { get; set; }
        public bool InterestedParty { get; set; }
    }

    [Serializable]
    public class Report
	{
		public int Id { get; set; }
		public string Name { get; set; }
		public int TaskCount { get; set; }
	}

    [Serializable]
    public class Section
	{
		public int Id { get; set; }
		public string Name { get; set; }
		public int ReportId { get; set; }
	}

    [Serializable]
    public enum ExportType
	{
		Excel,
		Word
	}

    [Serializable]
    public class ExportOptions
	{
		public DateTime? DueDateFrom { get; set; }
		public DateTime? DueDateTo { get; set; }
		public DateTime? CommentFrom { get; set; }
		public DateTime? CommentTo { get; set; }
		public bool ExcludeGeneralComments { get; set; }
		public ExportType ExportType { get; set; }
		public List<int> ArchiveList { get; set; }
		public List<int> ReportList { get; set; }
	}

    [Serializable]
    public class Timeline
	{
		public string Description { get; set; }
		public string DueDate { get; set; }
		public int Overdue { get; set; }
	}

    [Serializable]
    public class StatusReport
	{
		public bool IsArchive { get; set; }
		public DateTime? LastViewedFilter { get; set; }
		public IEnumerable<StatusReportLine> ReportLines { get; set; }
	}

    [Serializable]
    public class StatusReportLine : ReportLine
	{
        public StatusReportLine(){}

        public StatusReportLine(ReportCommentItems rci, int userId) 
        {
            this.AssignedTo = rci.AssignedTo;
            this.Controllers = rci.AssignedTo;
            this.Description = rci.Description;
            this.DueDate = string.IsNullOrEmpty(rci.DueDate) ? null : (DateTime?)DateTime.Parse(rci.DueDate);
            this.ID = rci.ID;
            this.LineType = Type.All.ContainsKey(rci.Type)
                                    ? Type.All[rci.Type]
                                    : Type.Task; ;
            this.MyTaskType = this.LineType != Type.Task
                                      ? TaskType.None
                                      : (TaskType)Convert.ToInt32(rci.NativeType);
            this.ReminderDate = null;
            this.SortDate = null;
            this.Priority = rci.Priority;
            this.SectionID = rci.TaskType;
            this.NativeType = rci.NativeType;
            this.CommentID = rci.Comments == null ? null : (int?)Int32.Parse(rci.Comments);
            this.HasRelatedComments = TaskHasRelatedComments(this.ID ?? 0, userId);
            this.IsDaily = rci.IsDaily;
        }

        private bool TaskHasRelatedComments(int taskId, int userId)
        {
            using (var cmd = new CmdObj("QStatus_GetRelatedComments"))
            {
                cmd.Add("@TaskId", taskId);
				cmd.Add("@UserId", userId);
                return (cmd.GetDS().Tables[0].Rows.Count > 0);
            }
        }

        [Serializable]
        public class Comment
		{
            public Comment() { }
            public Comment(ReportComment comment)
            {
                this.Id = comment.Id;
                this.UserId = comment.UserId;
                this.Text = comment.Comments;
                this.Date = comment.CommentDate;
                this.Initials = comment.Initials;
                this.FullName = comment.FullName;
                this.TabIn = comment.TabIn;
                this.Color = comment.ColorNum;
            }

			public int Id { get; set; }
			public int UserId { get; set; }
			public string Text { get; set; }
			public DateTime Date { get; set; }
			public string Initials { get; set; }
			public string FullName { get; set; }
			public int TabIn { get; set; }
			public int Color { get; set; }

            public string ColorString
            {
                get
                {
                    switch (Color)
                    {
                        case 0:
                            return "red";
                        case 1:
                            return "blue";
                        case 2:
                            return "#800000";
                        case 3:
                            return "#008000";
                        case 4:
                            return "#660";
                        case 50:
                            return "#800080";
                        default:
                            return "black";
                    }
                }
            }
		}

		public DateTime? ReminderDate { get; set; }
		public DateTime? SortDate { get; set; }
		public string SectionID { get; set; }
		public List<Comment> Comments { get; set; }
        public int? CommentID { get; set; }
    }

    [Serializable]
    public class BulkUpdateTask
	{
		public int Id { get; set; }
		public string Name { get; set; }
		public string Section { get; set; }
		public DateTime DueDate { get; set; }
	}

    [Serializable]
    public class SubmittedBulkUpdate
	{
		public int TaskId { get; set; }
		public bool UpdateDueDate { get; set; }
		public bool UpdateComment { get; set; }
		public string Comment { get; set; }
		public DateTime DateTime { get; set; }
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

