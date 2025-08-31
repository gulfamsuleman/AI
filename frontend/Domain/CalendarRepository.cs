using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using QProcess.Domain.Models;
using QProcess.Extensions;
using QProcess.Models;

namespace QProcess.Repositories
{
    public class CalendarRepository
    {
        private readonly UserTimeZone myTz = Session.CurrentSession.UserTimeZone;

        public IEnumerable<CalendarChecklist> GetChecklists(int userId, int[] assigneeId, bool showStatus, DateTime startDate, DateTime endDate)
		{
			using (var cmd = new CmdObj("QCheck_GetCalendarChecklists"))
			{
				//If including "Assigned To Me" alongside other users, treat the current user as just another user
                if (assigneeId != null && assigneeId.Length > 1 && assigneeId.Contains(0))
					assigneeId = assigneeId.Except(new[] { 0 }).Concat(new[] {userId}).ToArray();				

				string assigneeIdString =
					assigneeId != null && assigneeId.Length > 1
						? assigneeId.Skip(1)
							.Aggregate(assigneeId.First().ToString(),
								(s, i) => s + "," + i.ToString())
						: assigneeId != null && assigneeId.Length == 1
						? assigneeId[0].ToString() : "0";				

				cmd.Add("@UserID", userId);
				cmd.Add("@ID", assigneeIdString);
				cmd.Add("@ShowStatusCalendar", showStatus);
				cmd.Add("@startDate", myTz.GetSystemTime(startDate));
				cmd.Add("@endDate", myTz.GetSystemTime(endDate));
                var checklists = cmd.GetDS();
			    var retList = checklists.Tables[0].AsEnumerable()
			        .Select(c => new CalendarChecklist
			        {
			            Active = (int) c["active"] == 1,
			            ChangeId = (int) c["ChangeID"],
			            ChecklistId = (int) c["ChecklistID"],
			            ChecklistName = (string) c["ChecklistName"],
			            DueTime = myTz.GetLocalTime((DateTime)c["DueTime"]),
			            Id = (int) c["objID"],
			            IsAssigned = (int) c["assignedto"] == 1,
			            IsManager = (int) c["ismanager"] == 1,
			            IsRecurring = (bool) c["isRecurring"],
			            IsAlert = (bool) c["isAlert"],
			            AlertId = c["AlertID"].ToIntEx(),
			            IsEmailScheduled = (bool) c["isEmailScheduled"],
			            NewDeadline = myTz.GetLocalTime((DateTime)c["NewDeadline"]),
			            OriginalDeadline = !Convert.IsDBNull(c["OriginalDeadline"])
			                ? myTz.GetLocalTime((DateTime)c["OriginalDeadline"])
			                : DateTime.MinValue,
			            PendingChange = (bool) c["PendingChange"],
			            ReminderDate = !Convert.IsDBNull(c["ReminderDate"])
			                ? myTz.GetLocalTime(((DateTime)c["ReminderDate"])
								//.AddHours(((DateTime)c["DueTime"]).Hour))
								//.AddMinutes(((DateTime)c["DueTime"]).Minute
								)
			                : DateTime.MinValue,
			            TaskStage = (TaskStage) Enum.ToObject(typeof (TaskStage), (int) c["type"]),
			            IsNA = (bool) c["IsNA"]

			        });

				return retList;
			}
		}

		public IEnumerable<CalendarAssignee> GetAssignees(int userId)
		{
			using (var cmd = new CmdObj("QCheck_GetSupervisedUsersForCalendar"))			
			{
				cmd.Add("@UserID", userId);
				var assignees = cmd.GetDS().Tables[0].AsEnumerable().Select(a => new CalendarAssignee
					{
						Id = ((int)a["ID"]).ToString(),
						Name = (string) a["MemberName"]
					}).ToList();				
				var toReturn = assignees;
                toReturn.Insert(0, new CalendarAssignee { Id = "0", Name = "Assigned To Me" });
                toReturn.Insert(0, new CalendarAssignee { Id = "-2", Name = "All Tasks I Control" });                				
				return toReturn;
			}
		}
	}

	public class CalendarChecklist : ICalendarChecklist
	{
		public bool Active { get; set; }
		public int ChangeId { get; set; }
		public int ChecklistId { get; set; }
		public string ChecklistName { get; set; }
		public DateTime DueTime { get; set; }
		public int Id { get; set; }
		public bool IsAssigned { get; set; }
		public bool IsManager { get; set; }
        public bool IsAlert { get; set; }
        public bool IsEmailScheduled { get; set; }
        public bool IsRecurring { get; set; }
		public DateTime NewDeadline { get; set; }
		public bool PendingChange { get; set; }
		public DateTime ReminderDate { get; set; }
		public DateTime OriginalDeadline { get; set; }
		public TaskStage TaskStage { get; set; }
        public bool IsNA { get; set; }
	    public int? AlertId { get; set; }
		public string Assignees { get; set; }
	}

	public class CalendarAssignee
	{
		public string Id { get; set; }
		public string Name { get; set; }
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

