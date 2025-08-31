using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Threading;
using QProcess.Domain.Models;
using QProcess.Enums;
using QProcess.Models;

namespace QProcess.Repositories
{
    public class TaskSummaryRepository
    {
        private readonly UserTimeZone myTz = QProcess.Session.CurrentSession.UserTimeZone;

        public IEnumerable<TaskSummary> GetSummaryTasks(int userId)
		{
			return GetSummaryOrManagedTasks(userId, "QCheck_ActiveTasksAssigned");
		}

		public IEnumerable<TaskSummary> GetManagedTasks(int userId)
		{
			return GetSummaryOrManagedTasks(userId, "QCheck_ActiveTasksManaged");
		}
		
		public IEnumerable<TaskSummary> GetSummaryOrManagedTasks(int userId, string storedProc)
		{
			using (var cmd = new CmdObj(storedProc))
			{
				cmd.Add("@UserID", userId);
				var tasks = cmd.GetDS();
				return tasks.Tables[0].AsEnumerable().Select(t => new TaskSummary
					{
						InstanceId = Convert.ToInt32(t["instanceID"]),
						UpcomingId = t.GetConvertedNullableValue("upcomingID", Convert.ToInt32),
						HistoryType = Convert.ToInt32(t["HistoryType"]),
						HistoryId = t.GetConvertedNullableValue("HistoryID", Convert.ToInt32),
						ChecklistName = Convert.ToString(t["Checklist Name"]),
						Assignees = Convert.ToString(t["Assignees"]),
						Controllers = Convert.ToString(t["Managers"]),
						Frequency = Convert.ToString(t["Frequency"]),
						LastCompleted = myTz.GetLocalTimeEx(t.GetConvertedNullableValue("Last Completed", Convert.ToDateTime)),
						CurrentDueTime = myTz.GetLocalTime(Convert.ToDateTime(t["Current Due Time"])),
						ActiveId = Convert.ToInt32(t["ActiveID"]),
						NextDueDate = myTz.GetLocalTimeEx(t.GetConvertedNullableValue("nextduedate", Convert.ToDateTime))
					});
			}
		}

		public IEnumerable<TaskStatusLine> GetStatusTasks(int userId)
		{
			using (var cmd = new CmdObj("QStatus_GetReportTaskListByUser"))
			{
				cmd.Add("@UserID", userId);
				var tasks = cmd.GetDS();
				return tasks.Tables[0].AsEnumerable().Select(t => 
					{
						var line = new TaskStatusLine();
						var lineTypeKey = Convert.ToString(t["Type"]);
						line.LineType = ReportLine.Type.All.ContainsKey(lineTypeKey)
							                ? ReportLine.Type.All[lineTypeKey]
							                : ReportLine.Type.Task;
						line.MyTaskType = (TaskType) Convert.ToInt32(t["NativeType"]);
						line.ID = t.GetConvertedNullableValue("ID", Convert.ToInt32);
						line.InstanceId = t.GetConvertedNullableValue("InstanceID", Convert.ToInt32);
						line.Description = Convert.ToString(t["Description"]);
						line.DueDate = myTz.GetLocalTimeEx(t.GetConvertedNullableValue("DueDate", Convert.ToDateTime));
						line.Priority = t.GetConvertedNullableValue("Priority", Convert.ToInt32);
						line.AssignedTo = Convert.ToString(t["Assignees"]);
						line.Controllers = Convert.ToString(t["Managers"]);
						line.Frequency = Convert.ToString(t["Frequency"]);
						line.LastCompleted = myTz.GetLocalTimeEx(t.GetConvertedNullableValue("Last Completed", Convert.ToDateTime));
						line.NextDueDate = myTz.GetLocalTimeEx(t.GetConvertedNullableValue("nextduedate", Convert.ToDateTime));
						line.UpcomingId = t.GetConvertedNullableValue("UpcomingID", Convert.ToInt32);
						line.HistoryType = t.GetConvertedNullableValue("HistoryType", Convert.ToInt32);
						line.HistoryId = t.GetConvertedNullableValue("HistoryID", Convert.ToInt32);

						int temp;
						if (int.TryParse(Convert.ToString(t["Type"]), out temp))
							line.SectionId = temp;
						if (int.TryParse(Convert.ToString(t["Comments"]), out temp))
							line.CommentsId = temp;

						return line;
					});


			}
		}

		public UserSettings GetUserSettings(int userId)
		{
			using (var cmd = new CmdObj("QStatus_InitUser"))
			{
				cmd.Add("@UserID", userId);
				cmd.Add("@IsSupervisor", SqlDbType.Int, ParameterDirection.Output, 4);
				cmd.Add("@Font", SqlDbType.Int, ParameterDirection.Output, 4);
				cmd.ExecuteNonQueryWithOutput();
				return new UserSettings
					{
						IsSupervisor = (int)cmd["@IsSupervisor"] == 1,
						Font = (int)cmd["@Font"]
					};
			}
		}

		public void AddInstanceTaskType(int instanceId, int taskType, int? priority = 1)
		{
			using (var cmd = new CmdObj("QCheck_AddInstanceTaskType"))
			{
				cmd.Add("@InstanceID", instanceId);
                cmd.Add("@TaskType", taskType);
                cmd.Add("@Priority", priority);
                cmd.Add("@ID", SqlDbType.Int, ParameterDirection.Output, 4);
				cmd.ExecuteNonQueryWithOutput();
			}
			ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByInstanceId, instanceId);
		}

		public void AddActiveTaskType(int taskId, int taskType)
		{
			using (var cmd = new CmdObj("QCheck_AddActiveTaskType"))
			{
				cmd.Add("@ID", taskId);
				cmd.Add("@TaskType", taskType);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void DeleteInstanceTaskType(int instanceTaskTypeId, int userId)
		{
			using (var cmd = new CmdObj("QCheck_DeleteInstanceTaskType"))
			{
				cmd.Add("@ID", instanceTaskTypeId);
				cmd.Add("@UserID", userId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}
	}

	public class TaskSummary : ITaskSummary
	{
		public int InstanceId { get; set; }
		public int? UpcomingId { get; set; }
		public int HistoryType { get; set; }
		public int? HistoryId { get; set; }
		public string ChecklistName { get; set; }
		public string Assignees { get; set; }
		public string Controllers { get; set; }
		public string Frequency { get; set; }
		public DateTime? LastCompleted { get; set; }
		public DateTime CurrentDueTime { get; set; }
		public int ActiveId { get; set; }
		public DateTime? NextDueDate { get; set; }
	}

	public class UserSettings
	{
		public bool IsSupervisor { get; set; }
		public int Font { get; set; }
	}

	public class TaskStatusLine : ReportLine
	{
		public int? InstanceId { get; set; }
		public int? UpcomingId { get; set; }
		public int? HistoryType { get; set; }
		public int? HistoryId { get; set; }
		public string Frequency { get; set; }
		public DateTime? LastCompleted { get; set; }
		public DateTime? NextDueDate { get; set; }
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

