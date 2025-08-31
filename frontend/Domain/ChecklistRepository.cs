using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices.ComTypes;
using System.Security.Cryptography.Xml;
using System.Security.RightsManagement;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Web.Http.Results;
using System.Web.Providers.Entities;
using System.Web.Services.Description;
using System.Web.UI.WebControls;
using DataAccessLayer;
using DocumentFormat.OpenXml.Office2010.Excel;
using DocumentFormat.OpenXml.Wordprocessing;
using DocumentFormat.OpenXml.Spreadsheet;
using HtmlAgilityPack;
using QProcess.Configuration;
using QProcess.Domain;
using QProcess.Domain.Models;
using QProcess.Domain.SYSTEM;
using QProcess.Extensions;
using TimeZoneConverter;
using static QProcess.ChecklistExportMap;

namespace QProcess.Repositories
{
    public class ChecklistRepository
    {
        private readonly UserTimeZone myTz = QProcess.Session.CurrentSession.UserTimeZone;
        public IEnumerable<Checklist> GetSlimChecklists(int userId, DateTime start, DateTime end, int recurrance, int? activeChecklistId, int? instanceId)
        {
            start = myTz.GetSystemTime(start);
            end = myTz.GetSystemTime(end);

            using (var cmd = new CmdObj("QCheck_SlimGetUserChecklists"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@startdate", start);
                cmd.Add("@enddate", end);
                cmd.Add("@recurrance", recurrance);
                if (activeChecklistId.HasValue)
                    cmd.Add("@activeChecklistID", activeChecklistId.Value);
                if (instanceId.HasValue)
                    cmd.Add("@instanceID", instanceId.Value);

                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    return ds.Tables[0].AsEnumerable()
                    .GroupBy(r => r["UniqueID"])
                    .Select(g =>
                    {
                        var checklistArchetype = g.First();
                        var checklistId = checklistArchetype["ChecklistID"];
                        var createDate = checklistArchetype["CreateDate"];
                        var identifier = checklistArchetype["Identifier"];
                        var uniqueId = checklistArchetype["UniqueID"];
                        var dueTime = checklistArchetype["DueTime"];
                        var upcomingId = checklistArchetype["UpcomingID"];
                        var controllers = checklistArchetype["Controllers"];
                        var statusReportString = checklistArchetype["StatusReportString"];
                        var recurring = checklistArchetype["Recurring"];
                        var scheduleString = checklistArchetype["ScheduleString"];
                        var assignees = checklistArchetype["Assignees"];
                        var assigneecount = checklistArchetype["AssigneeCount"];
                        var checklistName = checklistArchetype["ChecklistName"];
                        var controllerPartOfAssignee = checklistArchetype["ControllerPartOfAssignee"];//added by venkat 06/13/2018
                        var pendingchange = checklistArchetype["PendingChange"];
                        var newDeadline = checklistArchetype["NewDeadline"];
                        var isNA = checklistArchetype["isNA"];
                        var naReason = checklistArchetype["naReason"];

                        var checklist = new Checklist
                        {
                            ChecklistId = (DBNull.Value != checklistId) ? (int)checklistId : 0,
                            CreateDate = (DBNull.Value != createDate) ? myTz.GetLocalTime((DateTime)createDate) : new DateTime(1900, 1, 1),
                            Identifier = (DBNull.Value != identifier) ? (int)identifier : 0,
                            UniqueId = (DBNull.Value != uniqueId) ? (int)uniqueId : 0,
                            DueDate = (DBNull.Value != dueTime) ? myTz.GetLocalTime((DateTime)dueTime) : new DateTime(1900, 1, 1),
                            UpcomingId = (DBNull.Value != upcomingId) ? (int)upcomingId : 0,
                            Controllers = (DBNull.Value != controllers) ? (string)controllers : "",
                            StatusReportString = (DBNull.Value != statusReportString) ? (string)statusReportString : "",
                            IsRecurring = (((DBNull.Value != recurring) ? (int)recurring : 0) != 0),
                            RecurranceSchedule = (DBNull.Value != scheduleString) ? (string)scheduleString : "",
                            Assignees = (DBNull.Value != assignees) ? (string)assignees : "",
                            AssigneeCount = (DBNull.Value != assigneecount) ? (int)assigneecount : 0,
                            Name = (DBNull.Value != checklistName) ? (string)checklistName : "",
                            TaskStage = TaskStage.Current,
                            ControllerPartOfAssignee = controllerPartOfAssignee.ToBoolEx(),//added by venkat 06/13/2018
                            PendingChange = (((DBNull.Value != pendingchange) ? (int)pendingchange : 0) != 0),
                            NewDeadline = (DBNull.Value != newDeadline) ? myTz.GetLocalTimeEx((DateTime)newDeadline) : null,
                            IsNA = isNA.ToBoolEx().Value,
                            NAReason = (DBNull.Value != naReason) ? (string)naReason : ""
                        };

                        int newStartIndex = checklist.StatusReportString.IndexOf("<a");
                        if (newStartIndex > 0)
                            checklist.StatusReportString = checklist.StatusReportString.Substring(newStartIndex);

                        var htmlDoc = new HtmlDocument();
                        htmlDoc.LoadHtml(checklist.StatusReportString);
                        if (htmlDoc.ParseErrors.Any())
                            checklist.StatusReportString = "[Error parsing status reports (malformed HTML)]";

                        //Not sure why this was commented out but completed tasks were showing overdue
                        if (DBNull.Value != checklistArchetype["ActiveChkCompletedDate"])
                        {
                            checklist.CompletedOn = myTz.GetLocalTimeEx((DateTime)checklistArchetype["ActiveChkCompletedDate"]);
                            checklist.IsCompleted = true;
                        }
                        if ((int)checklistArchetype["ChkType"] == 2)
                        {
                            checklist.TaskStage = TaskStage.Future;
                        }

                        return checklist;
                    })
                    .ToList();
                }
                else
                {
                    return new List<Checklist>();
                }

            }
        }

        /* Used in collapsible Other Overdue section */
        public IEnumerable<Checklist> GetSlimOtherOverdueChecklists(int userId, DateTime start, DateTime end, int recurrance, int? activeChecklistId, int? instanceId)
        {
            using (var cmd = new CmdObj("QCheck_SlimGetUserOtherOverdueChecklists"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@startdate", start);
                cmd.Add("@enddate", end);
                cmd.Add("@recurrance", recurrance);
                if (activeChecklistId.HasValue)
                    cmd.Add("@activeChecklistID", activeChecklistId.Value);
                if (instanceId.HasValue)
                    cmd.Add("@instanceID", instanceId.Value);

                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    return ds.Tables[0].AsEnumerable()
                    .GroupBy(r => r["UniqueID"])
                    .Select(g =>
                    {
                        var checklistArchetype = g.First();
                        var checklistId = checklistArchetype["ChecklistID"];
                        var createDate = checklistArchetype["CreateDate"];
                        var identifier = checklistArchetype["Identifier"];
                        var uniqueId = checklistArchetype["UniqueID"];
                        var dueTime = checklistArchetype["DueTime"];
                        var upcomingId = checklistArchetype["UpcomingID"];
                        var controllers = checklistArchetype["Controllers"];
                        var statusReportString = checklistArchetype["StatusReportString"];
                        var recurring = checklistArchetype["Recurring"];
                        var scheduleString = checklistArchetype["ScheduleString"];
                        var assignees = checklistArchetype["Assignees"];
                        var assigneecount = checklistArchetype["AssigneeCount"];
                        var checklistName = checklistArchetype["ChecklistName"];
                        var controllerPartOfAssignee = checklistArchetype["ControllerPartOfAssignee"];//added by venkat 06/13/2018
                        var pendingchange = checklistArchetype["PendingChange"];
                        var newDeadline = checklistArchetype["NewDeadline"];
                        var isNA = checklistArchetype["isNA"];
                        var naReason = checklistArchetype["naReason"];

                        var checklist = new Checklist
                        {
                            ChecklistId = (DBNull.Value != checklistId) ? (int)checklistId : 0,
                            CreateDate = (DBNull.Value != createDate) ? myTz.GetLocalTime((DateTime)createDate) : new DateTime(1900, 1, 1),
                            Identifier = (DBNull.Value != identifier) ? (int)identifier : 0,
                            UniqueId = (DBNull.Value != uniqueId) ? (int)uniqueId : 0,
                            DueDate = (DBNull.Value != dueTime) ? myTz.GetLocalTime((DateTime)dueTime) : new DateTime(1900, 1, 1),
                            UpcomingId = (DBNull.Value != upcomingId) ? (int)upcomingId : 0,
                            Controllers = (DBNull.Value != controllers) ? (string)controllers : "",
                            StatusReportString = (DBNull.Value != statusReportString) ? (string)statusReportString : "",
                            IsRecurring = (((DBNull.Value != recurring) ? (int)recurring : 0) != 0),
                            RecurranceSchedule = (DBNull.Value != scheduleString) ? (string)scheduleString : "",
                            Assignees = (DBNull.Value != assignees) ? (string)assignees : "",
                            AssigneeCount = (DBNull.Value != assigneecount) ? (int)assigneecount : 0,
                            Name = (DBNull.Value != checklistName) ? (string)checklistName : "",
                            TaskStage = TaskStage.Current,
                            ControllerPartOfAssignee = controllerPartOfAssignee.ToBoolEx(),//added by venkat 06/13/2018
                            PendingChange = (((DBNull.Value != pendingchange) ? (int)pendingchange : 0) != 0),
                            NewDeadline = (DBNull.Value != newDeadline) ? myTz.GetLocalTimeEx((DateTime)newDeadline) : null,
                            IsNA = isNA.ToBoolEx().Value,
                            NAReason = (DBNull.Value != naReason) ? (string)naReason : ""
                        };

                        int newStartIndex = checklist.StatusReportString.IndexOf("<a");
                        if (newStartIndex > 0)
                            checklist.StatusReportString = checklist.StatusReportString.Substring(newStartIndex);

                        var htmlDoc = new HtmlDocument();
                        htmlDoc.LoadHtml(checklist.StatusReportString);
                        if (htmlDoc.ParseErrors.Any())
                            checklist.StatusReportString = "[Error parsing status reports (malformed HTML)]";

                        //Not sure why this was commented out but completed tasks were showing overdue
                        if (DBNull.Value != checklistArchetype["ActiveChkCompletedDate"])
                        {
                            checklist.CompletedOn = (DateTime)checklistArchetype["ActiveChkCompletedDate"];
                            checklist.IsCompleted = true;
                        }
                        if ((int)checklistArchetype["ChkType"] == 2)
                        {
                            checklist.TaskStage = TaskStage.Future;
                        }

                        return checklist;
                    })
                    .ToList();
                }
                else
                {
                    return new List<Checklist>();
                }

            }
        }

        public RedactedTasksList GetSingleChecklistForReassignment(int userId, int checklistId)
        {
            using (var cmd = new CmdObj("QCheck_GetSingleChecklistForReassignment"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@ChecklistId", checklistId);
                var ds = cmd.GetDS();

                if (ds.Tables[0].Rows.Count > 0)
                {
                    var row = ds.Tables[0].Rows[0];
                    var checklist = new RedactedTasksList()
                    {
                        ChecklistID = (int)row["ChecklistId"],
                        ChecklistName = (string)row["ChecklistName"],
                        DueDate = (string)row["duetime"],
                        Controllers = (string)row["Controllers"],
                        StatusReportString = (string)row["StatusReportString"],
                        Assignees = (string)row["Assignees"]
                    };

                    return checklist;
                }

                return new RedactedTasksList();
            }
        }

        public DataSet GetChecklistsForExport(int userId, int memberGroupId = 0, int managerGroupId = 0, bool isAdmin = false, string search = "", int parentId = 0)
        {
            using (var cmd = new CmdObj("QCheck_GetMyChecklistsForExport"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@memberGroupId", memberGroupId);
                cmd.Add("@managerGroupId", managerGroupId);
                cmd.Add("@isAdmin", isAdmin);
                cmd.Add("@search", search);
                return cmd.GetDS();
            }
        }

        public IEnumerable<ChecklistObject> GetChecklistsForExport(int userId, int memberGroupId = 0, bool isAdmin = false, string search = "")
        {
            using (var cmd = new CmdObj("QCheck_GetManagedChecklistsForExport"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@memberGroupID", memberGroupId);
                cmd.Add("@isAdmin", isAdmin);
                cmd.Add("@search", search);
                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    return ds.Tables[0].AsEnumerable()
                        .Select(r => new ChecklistObject
                        {
                            Name = (string)r["TaskName"],
                            DueDate = r["DueTime"] != DBNull.Value ? (DateTime?)myTz.GetLocalTime((DateTime)r["DueTime"]) : null,
                            Assignees = r["Assignees"].ToString().Replace("&nbsp;", " "),
                            Controllers = (string)r["Controllers"],
                            RecurranceSchedule = (string)r["RecurranceSchedule"],
                            PendingChange = Convert.ToBoolean(r["PendingChange"]),
                            NewDeadline = r["NewDeadline"] != DBNull.Value ? (DateTime?)myTz.GetLocalTime((DateTime)r["NewDeadline"]) : null,
                            CreateDate = r["CreateDate"] != DBNull.Value ? (DateTime?) myTz.GetLocalTime((DateTime)r["CreateDate"]) : null
                        });
                }
                else return new List<ChecklistObject>();
            }

        }

        public IEnumerable<Checklist> GetChecklists(int userId, DateTime start, DateTime end, int recurrance, int? activeChecklistId, int? instanceId)
        {
            start = myTz.GetSystemTime(start);
            end = myTz.GetSystemTime(end);

            using (var cmd = new CmdObj("QCheck_GetUserChecklists"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@startdate", start);
                cmd.Add("@enddate", end);
                cmd.Add("@recurrance", recurrance);
                if (activeChecklistId.HasValue)
                    cmd.Add("@activeChecklistID", activeChecklistId.Value);
                if (instanceId.HasValue)
                    cmd.Add("@instanceID", instanceId.Value);

                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    return ds.Tables[0].AsEnumerable()
                    .GroupBy(r => r["UniqueID"])
                    .Select(g =>
                    {
                        var checklistArchetype = g.First();
                        var checklistId = checklistArchetype["ChecklistID"];
                        var createDate = checklistArchetype["CreateDate"];
                        var identifier = checklistArchetype["Identifier"];
                        var uniqueId = checklistArchetype["UniqueID"];
                        var dueTime = checklistArchetype["DueTime"];
                        var upcomingId = checklistArchetype["UpcomingID"];
                        var controllers = checklistArchetype["Controllers"];
                        var statusReportString = checklistArchetype["StatusReportString"];
                        var recurring = checklistArchetype["Recurring"];
                        var scheduleString = checklistArchetype["ScheduleString"];
                        var assignees = checklistArchetype["Assignees"];
                        var assigneecount = checklistArchetype["AssigneeCount"];
                        var checklistName = checklistArchetype["ChecklistName"];
                        var controllerPartOfAssignee = checklistArchetype["ControllerPartOfAssignee"];//added by venkat 06/13/2018
                        var pendingchange = checklistArchetype["PendingChange"];
                        var newDeadline = checklistArchetype["NewDeadline"];
                        var isNA = checklistArchetype["isNA"];
                        var naReason = checklistArchetype["naReason"];

                        var checklist = new Checklist
                        {
                            ChecklistId = (DBNull.Value != checklistId) ? (int)checklistId : 0,
                            CreateDate = (DBNull.Value != createDate) ? myTz.GetLocalTime((DateTime)createDate) : new DateTime(1900, 1, 1),
                            Identifier = (DBNull.Value != identifier) ? (int)identifier : 0,
                            UniqueId = (DBNull.Value != uniqueId) ? (int)uniqueId : 0,
                            DueDate = (DBNull.Value != dueTime) ? myTz.GetLocalTime((DateTime)dueTime) : new DateTime(1900, 1, 1),
                            UpcomingId = (DBNull.Value != upcomingId) ? (int)upcomingId : 0,
                            Controllers = (DBNull.Value != controllers) ? (string)controllers : "",
                            StatusReportString = (DBNull.Value != statusReportString) ? (string)statusReportString : "",
                            IsRecurring = (((DBNull.Value != recurring) ? (int)recurring : 0) != 0),
                            RecurranceSchedule = (DBNull.Value != scheduleString) ? (string)scheduleString : "",
                            Assignees = (DBNull.Value != assignees) ? (string)assignees : "",
                            AssigneeCount = (DBNull.Value != assigneecount) ? (int)assigneecount : 0,
                            Name = (DBNull.Value != checklistName) ? (string)checklistName : "",
                            TaskStage = TaskStage.Current,
                            ControllerPartOfAssignee = controllerPartOfAssignee.ToBoolEx(),//added by venkat 06/13/2018
                            PendingChange = (((DBNull.Value != pendingchange) ? (int)pendingchange : 0) != 0),
                            NewDeadline = (DBNull.Value != newDeadline) ? myTz.GetLocalTimeEx((DateTime)newDeadline) : null,
                            IsNA = isNA.ToBoolEx().Value,
                            NAReason = (DBNull.Value != naReason) ? (string)naReason : ""
                        };

                        int newStartIndex = checklist.StatusReportString.IndexOf("<a");
                        if (newStartIndex > 0)
                            checklist.StatusReportString = checklist.StatusReportString.Substring(newStartIndex);

                        var htmlDoc = new HtmlDocument();
                        htmlDoc.LoadHtml(checklist.StatusReportString);
                        if (htmlDoc.ParseErrors.Any())
                            checklist.StatusReportString = "[Error parsing status reports (malformed HTML)]";

                        if (DBNull.Value != checklistArchetype["ActiveChkCompletedDate"])
                        {
                            checklist.CompletedOn = myTz.GetLocalTimeEx((DateTime)checklistArchetype["ActiveChkCompletedDate"]);
                            checklist.IsCompleted = true;
                        }
                        if ((int)checklistArchetype["ChkType"] == 2)
                        {
                            checklist.TaskStage = TaskStage.Future;
                        }
                        checklist.Items = g.Select(r => new ChecklistItem(r)).ToArray();
                        return checklist;
                    })
                    .ToList();
                }
                else
                {
                    return new List<Checklist>();
                }

            }
        }
        public List<Checklist> GetNAChecklists(int userId, DateTime startDate)
        {
            startDate = myTz.GetSystemTime(startDate);

            using (var cmd = new CmdObj("QCheck_NALastWeek"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@startdate", startDate);
                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    return ds.Tables[0].AsEnumerable()

                    .Select(g =>

                        new Checklist
                        {
                            ChecklistId = (int)g["ChecklistID"],
                            Name = (string)g["Name"]

                        })
                    .ToList();
                }
                else
                {
                    return new List<Checklist>();
                }
            }
        }
        public List<Checklist> GetExtendedChecklists(int userId, DateTime startDate)
        {
            startDate = myTz.GetSystemTime(startDate);

            using (var cmd = new CmdObj("QCheck_ExtendedTaskList"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@startdate", startDate);
                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    return ds.Tables[0].AsEnumerable()

                    .Select(g =>

                        new Checklist
                        {
                            ChecklistId = (int)g["ChecklistID"],
                            Name = (string)g["Name"]

                        })
                    .ToList();
                }
                else
                {
                    return new List<Checklist>();
                }
            }
        }
        public List<Checklist> GetOverdueChecklists(int userId, DateTime startDate)//added by Venkat 12/16/2016
        {
            startDate = myTz.GetSystemTime(startDate);

            using (var cmd = new CmdObj("QCheck_GetOverdueUserChecklists"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@startdate", startDate);
                //cmd.Add("@enddate", end);
                //cmd.Add("@recurrance", recurrance);
                //if (activeChecklistId.HasValue)
                //    cmd.Add("@activeChecklistID", activeChecklistId.Value);
                //if (instanceId.HasValue)
                //    cmd.Add("@instanceID", instanceId.Value);

                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    return ds.Tables[0].AsEnumerable()

                    .Select(g =>

                        new Checklist
                        {
                            ChecklistId = (int)g["ChecklistID"],
                            Name = (string)g["ChecklistName"],
                            AssigneeCount = (int)g["AssigneeCount"],
                            PendingChange = (((DBNull.Value != g["PendingChange"]) ? (int)g["PendingChange"] : 0) != 0)
                        })
                    .ToList();
                }
                else
                {
                    return new List<Checklist>();
                }

            }
        }

        public List<UserStats> GetUserStats(int userId, int supervisorId, int numOfDays)
        {
            using (var cmd = new CmdObj("QCheck_KPI"))
            {
                cmd.Add("@userid", userId);
                cmd.Add("@supervisorid", supervisorId);
                cmd.Add("@numdays", numOfDays);

                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    var results = ds.Tables[0].AsEnumerable()

                    .Select(g =>

                        new UserStats
                        {
                            FullName = (string)g["fullname"],
                            Tasks = (int)g["tasks"],
                            LatePriorities = (int)g["prioritylates"],
                            ChargedPriorities = (int)g["prioritycharge"],
                            LateTasks = (int)g["tasklates"],
                            ChargedTasks = (int)g["taskcharge"],
                            OverdueTasks = (int)g["overdue"],
                            SupervisorControlledTasks = (int)g["supervisorcontrolled"],
                            SupervisorControlledPct = (int)g["supervisorcontrolledpct"],
                            CommentsMade = (int)g["comments"],
                            TasksCompleted = (int)g["taskscompleted"],
                            PriorityEmailsTotal = (int)g["priorityemails"],
                            TasksCreated = (int)g["taskscreated"],
                            TotalPoints = (g["TotalPoints"] as int?) ?? 0
                        })
                    .ToList();
                    return results;
                }
                
                else
                {
                    return new List<UserStats>();
                }

            }
        }
        public List<UserStats> GetUserStatsSimple(string usernames, bool includePoints = false, int numOfDays = 90)
        {
            using (var cmd = new CmdObj("QCheck_KpiSimple"))
            {
                cmd.Add("@UserIds", usernames);
                cmd.Add("@numDays", numOfDays);

                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    var results = ds.Tables[0].AsEnumerable()

                    .Select(g =>

                        new UserStats
                        {
                            UserId = (int)g["UserId"],
                            FullName = (string)g["FullName"],
                            Tasks = (g["Tasks"] as int?) ?? 0,
                            LatePriorities = (g["LatePriorities"] as int?) ?? 0,
                            ChargedPriorities = (g["PriorityCharges"] as int?) ?? 0,
                            LateTasks = (g["LateTasks"] as int?) ?? 0,
                            ChargedTasks = (g["TasksCharged"] as int?) ?? 0,
                            OverdueTasks = (g["OverdueTasks"] as int?) ?? 0,
                            SupervisorControlledTasks = (g["SupervisorControlled"] as int?) ?? 0,
                            CommentsMade = (g["CommentsMade"] as int?) ?? 0,
                            TasksCompleted = (g["CompletedTasks"] as int?) ?? 0,
                            PriorityEmailsTotal = (g["PriorityEmails"] as int?) ?? 0,
                            TasksCreated = (g["TasksCreated"] as int?) ?? 0,
                            EmailsSent = (g["EmailsSent"] as int?) ?? 0,
                            ChangeRequests = (g["ChangeRequests"] as int?) ?? 0,
                            TotalPoints = (g["TotalPoints"] as int?) ?? 0
                        })
                    .ToList();


                    return results;
                }
                else
                {
                    return new List<UserStats>();
                }

            }
        }

        public int GetUserRafflePoints(int userId, DateTime startDate, DateTime endDate)
        {
            var result = 0;
            using (var cmd = new CmdObj("GetUserDailyBonuses"))
            {
                cmd.Add("@UserId", userId);
                cmd.Add("@StartDate", startDate);
                cmd.Add("@EndDate", endDate);
                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    var results = ds.Tables[0].AsEnumerable();
                    foreach (DataRow row in results) {
                        result = result + (int)row["FinalBonus"];
                    }
                }
                return result;
            }
        }
        public List<UserStats> GetUserStatsSimplePhi(string usernames)
        {
            using (var cmd = new CmdObj("QCheck_KpiSimplePhi"))
            {
                cmd.Add("@UserIds", usernames);

                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    var results =  ds.Tables[0].AsEnumerable()

                    .Select(g =>

                        new UserStats
                        {
                            UserId = (int)g["UserId"],
                            FullName = (string)g["FullName"],
                            OverdueTasks = (int)g["OverdueTasks"],
                            TasksCompletedOnTime = (int)g["TasksCompletedOnTime"],
                            TasksCreatedThroughEmail = (int)g["TasksCreatedThroughEmail"],
                            MultiStepOrRecurringTasksCompleted = (int)g["MultiStepOrRecurringTasksCompleted"],
                            SendPriorityListOrStatusEmail = (int)g["SendPriorityListOrStatusEmail"],
                            MissingPriorityListsorStatusReport =  (int)g["MissingPriorityListsorStatusReport"],
                            CommentsMade = 0

                        })
                    .ToList();

                    foreach (var result in results)
                    {
                        result.TotalPoints = result.TasksCompletedOnTime * 1 + result.TasksCreatedThroughEmail * 1 +
                            result.CommentsMade * 1 + result.MultiStepOrRecurringTasksCompleted * 1 +
                            result.SendPriorityListOrStatusEmail * .4
                            - result.OverdueTasks * .1 - result.MissingPriorityListsorStatusReport * 4;
                    }

                    return results;
                }
                else
                {
                    return new List<UserStats>();
                }

            }
        }
        public List<Checklist> GetPotentialNAChecklists(int userId, DateTime startDate, DateTime endDate, int assignee)
        {
            startDate = myTz.GetSystemTime(startDate);
            endDate = myTz.GetSystemTime(endDate);

            using (var cmd = new CmdObj("QCheck_GetPotentialNATasks"))
            {
                cmd.Add("@controller", userId);
                cmd.Add("@start", startDate);
                cmd.Add("@end", endDate);
                cmd.Add("@assigned", assignee);

                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    return ds.Tables[0].AsEnumerable()

                    .Select(g =>

                        new Checklist
                        {
                            ChecklistId = (int)g["id"],
                            Name = (string)g["Name"],
                            DueDate = myTz.GetLocalTime((DateTime)g["duetime"]),
                            Assignees = (string)g["assignees"]
                        })
                    .ToList();
                }
                else
                {
                    return new List<Checklist>();
                }

            }
        }

        public string GetLastRunOfProcedure(string procedureName)
        {
            var result = "";

            using (var cmd = new CmdObj("Util_GetLastRunTimeForStoredProcedure"))
            {
                cmd.Add("@StoredProcName", procedureName);

                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    var lastRun = ds.Tables[0].Rows[0]["LastRunOn"];
                    return lastRun.ToString();
                }
                else
                {
                    return "";
                }
            }
            return result;
        }
        public List<Checklist> GetChecklistsByStatusReportId(int id)
        {
            using (var cmd = new CmdObj("QCheck_GetChecklistsByStatusReportId"))
            {
                cmd.Add("@id", id);

                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    return ds.Tables[0].AsEnumerable()

                    .Select(g =>

                        new Checklist
                        {
                            ChecklistId = (int)g["ChecklistID"],
                            Name = (string)g["ChecklistName"],
                            StatusReportName = (string)g["StatusReportName"],
                            SectionName = (string)g["SectionName"],
                            //DisplayOrder = (int)g["DisplayOrder"],
                            DueDate = myTz.GetLocalTime((DateTime)g["DueTime"]),
                            Timezone = (string)g["TimeZone"],
                            //, AssigneeCount = (int)g["AssigneeCount"]
                            Comments = (string)g["Comments"],
                            PendingChange = (((DBNull.Value != g["PendingChange"]) ? (int)g["PendingChange"] : 0) != 0)
                        })
                    .ToList();
                }
                else
                {
                    return new List<Checklist>();
                }
            }
        }

        public Checklist GetSingleChecklist(int userId, TaskStage taskStage, int checklistId)
        {
            using (var cmd = new CmdObj("QCheck_GetSingleChecklist"))
            {
                cmd.Add("@loginId", userId);
                cmd.Add("@type", taskStage);
                cmd.Add("@id", checklistId);
                var sc = cmd.GetDS().Tables[0].AsEnumerable().GroupBy(r => r["UniqueID"])
                    .Select(c =>
                    {
                        var checklistArchetype = c.First();
                        var chkId = checklistArchetype["ChecklistID"];
                        var uniqueId = checklistArchetype["UniqueID"];
                        var dueTime = checklistArchetype["DueTime"];
                        var upcomingId = checklistArchetype["UpcomingID"];
                        var controllers = checklistArchetype["Controllers"];
                        var statusReportString = checklistArchetype["StatusReportString"];
                        var recurring = checklistArchetype["Recurring"];
                        var isDaily = checklistArchetype["IsDaily"];
                        var scheduleString = checklistArchetype["ScheduleString"];
                        var assignees = checklistArchetype["Assignees"];
                        var checklistName = checklistArchetype["ChecklistName"];
                        var createDate = checklistArchetype["CreateDate"];
                        var controllerPartOfAssignee = checklistArchetype["ControllerPartOfAssignee"];//added by venkat 06/13/2018
                        var isNA = checklistArchetype["isNA"];
                        var naReason = checklistArchetype["naReason"];
                        var pendingChange = checklistArchetype.Table.Columns.Contains("PendingChange")
                            ? checklistArchetype["PendingChange"]
                            : "false";
                        var newDeadline = checklistArchetype.Table.Columns.Contains("NewDeadline")
                            ? checklistArchetype["NewDeadline"]
                            : null;

                        var checklist = new Checklist
                        {
                            ChecklistId = (DBNull.Value != chkId) ? (int)chkId : 0,
                            CreateDate = (DBNull.Value != createDate) ? myTz.GetLocalTime((DateTime)createDate) : new DateTime(1900, 1, 1),
                            UniqueId = (DBNull.Value != uniqueId) ? (int)uniqueId : 0,
                            DueDate = (DBNull.Value != dueTime) ? myTz.GetLocalTime((DateTime)dueTime) : new DateTime(1900, 1, 1),
                            UpcomingId = (DBNull.Value != upcomingId) ? (int)upcomingId : 0,
                            Controllers = (DBNull.Value != controllers) ? (string)controllers : "",
                            StatusReportString = (DBNull.Value != statusReportString) ? (string)statusReportString : "",
                            IsRecurring = (((DBNull.Value != recurring) ? (int)recurring : 0) != 0),
                            IsDaily = (((DBNull.Value != isDaily) ? (int)isDaily : 0) != 0),
                            RecurranceSchedule = (DBNull.Value != scheduleString) ? (string)scheduleString : "",
                            Assignees = (DBNull.Value != assignees) ? (string)assignees : "",
                            Name = (DBNull.Value != checklistName) ? (string)checklistName : "",
                            TaskStage = TaskStage.Current,
                            ControllerPartOfAssignee = controllerPartOfAssignee.ToBoolEx(),//added by venkat 06/13/2018,
                            IsNA = isNA.ToBoolEx().Value,
                            NAReason = (DBNull.Value != naReason) ? (string)naReason : "",
                            PendingChange = pendingChange.ToBoolEx().GetValueOrDefault(),
                            NewDeadline = myTz.GetLocalTimeEx(newDeadline.ToDateTimeEx())
                        };
                        // No Reminder Date, assume regular due date
                        if (Convert.IsDBNull(checklistArchetype["ReminderDate"]))
                            //checklist.ReminderDate = (DateTime) checklistArchetype["DueTime"];
                            checklist.ReminderDate = myTz.GetLocalTime(checklist.DueDate);
                        else
                            checklist.ReminderDate = myTz.GetLocalTime((DateTime)checklistArchetype["ReminderDate"]);

                        int newStartIndex = checklist.StatusReportString.IndexOf("<a");
                        if (newStartIndex > 0)
                        {
                            checklist.StatusReportString = checklist.StatusReportString.Substring(newStartIndex);
                        }
                        else
                        {
                            checklist.StatusReportString = checklist.StatusReportString.Replace("Status Reports: ", "");
                        }

                        var htmlDoc = new HtmlDocument();
                        htmlDoc.LoadHtml(checklist.StatusReportString);
                        if (htmlDoc.ParseErrors.Any())
                            checklist.StatusReportString = "[Error parsing status reports (malformed HTML)]";

                        if (!Convert.IsDBNull(checklistArchetype["ActiveChkCompletedDate"]))
                        {
                            checklist.CompletedOn = myTz.GetLocalTimeEx((DateTime)checklistArchetype["ActiveChkCompletedDate"]);
                            checklist.IsCompleted = true;
                        }
                        if ((int)checklistArchetype["ChkType"] == 2)
                        {
                            checklist.TaskStage = TaskStage.Future;
                        }
                        if (!c.Any(r => Convert.IsDBNull(r["ItemId"])))
                            checklist.Items = c.Select(r => new ChecklistItem(r)).ToArray();
                        checklist.IsVisible = true;
                        return checklist;
                    });
                return sc.Any() ? sc.First() : new Checklist { IsVisible = false };
            }
        }

        public Checklist GetSingleChecklistForApproval(int userId, TaskStage taskStage, int activeChecklistId, int changeId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_GetSingleChecklist"))
            {
                cmd.Add("@loginId", userId);
                cmd.Add("@type", taskStage);
                cmd.Add("@id", activeChecklistId);
                cmd.Add("@ChangeID", changeId);
                var sc = cmd.GetDS().Tables[0].AsEnumerable().GroupBy(r => r["UniqueID"])
                    .Select(c =>
                    {
                        var checklistArchetype = c.First();
                        var chkId = checklistArchetype["ChecklistID"];
                        var uniqueId = checklistArchetype["UniqueID"];
                        var dueTime = checklistArchetype["DueTime"];
                        var upcomingId = checklistArchetype["UpcomingID"];
                        var controllers = checklistArchetype["Controllers"];
                        var statusReportString = checklistArchetype["StatusReportString"];
                        var recurring = checklistArchetype["Recurring"];
                        var isDaily = checklistArchetype["IsDaily"];
                        var scheduleString = checklistArchetype["ScheduleString"];
                        var assignees = checklistArchetype["Assignees"];
                        var checklistName = checklistArchetype["ChecklistName"];
                        var createDate = checklistArchetype["CreateDate"];

                        var checklist = new Checklist
                        {
                            ChecklistId = (DBNull.Value != chkId) ? (int)chkId : 0,
                            CreateDate = (DBNull.Value != createDate) ? myTz.GetLocalTime((DateTime)createDate) : new DateTime(1900, 1, 1),
                            UniqueId = (DBNull.Value != uniqueId) ? (int)uniqueId : 0,
                            DueDate = (DBNull.Value != dueTime) ? myTz.GetLocalTime((DateTime)dueTime) : new DateTime(1900, 1, 1),
                            UpcomingId = (DBNull.Value != upcomingId) ? (int)upcomingId : 0,
                            Controllers = (DBNull.Value != controllers) ? (string)controllers : "",
                            StatusReportString = (DBNull.Value != statusReportString) ? (string)statusReportString : "",
                            IsRecurring = (((DBNull.Value != recurring) ? (int)recurring : 0) != 0),
                            IsDaily = (((DBNull.Value != isDaily) ? (int)isDaily : 0) != 0),
                            RecurranceSchedule = (DBNull.Value != scheduleString) ? (string)scheduleString : "",
                            Assignees = (DBNull.Value != assignees) ? (string)assignees : "",
                            Name = (DBNull.Value != checklistName) ? (string)checklistName : "",
                            TaskStage = TaskStage.Current
                        };
                        // No Reminder Date, assume regular due date
                        if (Convert.IsDBNull(checklistArchetype["ReminderDate"]))
                            checklist.ReminderDate = myTz.GetLocalTime((DateTime)checklistArchetype["DueTime"]);
                        else
                            checklist.ReminderDate = myTz.GetLocalTime((DateTime)checklistArchetype["ReminderDate"]);

                        int newStartIndex = checklist.StatusReportString.IndexOf("<a");
                        if (newStartIndex > 0)
                            checklist.StatusReportString = checklist.StatusReportString.Substring(newStartIndex);

                        var htmlDoc = new HtmlDocument();
                        htmlDoc.LoadHtml(checklist.StatusReportString);
                        if (htmlDoc.ParseErrors.Any())
                            checklist.StatusReportString = "[Error parsing status reports (malformed HTML)]";

                        if (!Convert.IsDBNull(checklistArchetype["ActiveChkCompletedDate"]))
                        {
                            checklist.CompletedOn = myTz.GetLocalTimeEx((DateTime)checklistArchetype["ActiveChkCompletedDate"]);
                            checklist.IsCompleted = true;
                        }
                        if ((int)checklistArchetype["ChkType"] == 2)
                        {
                            checklist.TaskStage = TaskStage.Future;
                        }
                        checklist.Items = c.Select(r => new ChecklistItem(r)).ToArray();
                        return checklist;
                    });
                return sc.First();
            }
        }

        public void RequestNewDueDate(int taskId, DateTime newDueDate, int userId, string comment, UserTimeZone timezone)
        {
            newDueDate = myTz.GetSystemTime(newDueDate);

            using (var cmd = new CmdObj("QCheck_Approval_NewDeadline"))
            {
                cmd.Add("@ActiveChecklistID", taskId);
                cmd.Add("@NewDueTime", newDueDate);
                cmd.Add("@UserID", userId);
                cmd.Add("@Comment", comment);
                cmd.Add("@Timezone", timezone.TimeZoneOverride ?? timezone.LastTimeZone);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void UpdateSchedule(int taskId, DateTime newDueDate)
        {
            newDueDate = myTz.GetSystemTime(newDueDate);

            using (var cmd = new CmdObj("QCheck_UpdateDueDate"))
            {
                cmd.Add("@TaskID", taskId);
                cmd.Add("@DueDate", newDueDate);
                cmd.Add("@changedby", Session.CurrentSession.QUser.Username);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public OverdueInfo GetOverdueInfo(int userId)
        {
            using (var cmd = new CmdObj("QCheck_GetOverdueTasks"))
            {
                cmd.Add("@UserID", userId);
                var tasks = cmd.GetDS().Tables[0].AsEnumerable().Select(r => new
                {
                    DueDate = myTz.GetLocalTime((DateTime)r["dueTime"]),
                    Name = (string)r["ChecklistName"]
                }).ToList();

                if (tasks.Count > 0)
                {
                    return new OverdueInfo
                    {
                        MinDueDate = myTz.GetLocalTime(tasks.Min(t => t.DueDate)),
                        OverdueCount = tasks.Count
                    };
                }
                else
                {
                    return new OverdueInfo
                    {
                        MinDueDate = DateTime.Parse("1/1/1900"),
                        OverdueCount = 0
                    };
                }

            }
        }

        public bool UserManagesChecklist(int groupId, int checklistId)
        {
            using (var cmd = new CmdObj("QCheck_ManagesChecklist"))
            {
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@GroupID", groupId);
                cmd.Add("@IsManager", SqlDbType.Bit, ParameterDirection.Output, 1);
                cmd.ExecuteNonQueryWithOutput();
                return (bool)cmd["@IsManager"];
            }
        }

        // This comes from AllChecklistsConsolidated.aspx.cs:974
        public int GetNewChangeRequest(int userId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_NewChangeRequest"))
            {
                cmd.Add("@RequestingUserID", userId);
                cmd.Add("@Comment", "");
                cmd.Add("@ChangeID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                return (int)cmd["@ChangeID"];
            }
        }

        // This comes from AllChecklistsConsolidated.aspx.cs:992
        public void CopyChecklistItemsToChange(int changeId, int checklistId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_CopyChecklistItems"))
            {
                cmd.Add("@ChangeID", changeId);
                cmd.Add("@ChecklistID", checklistId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        // This comes from AllChecklistsConsolidated.aspx.cs:992
        public void CopySchedulesToChange(int changeId, int checklistId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_CopySchedules"))
            {
                cmd.Add("@ChangeID", changeId);
                cmd.Add("@ChecklistID", checklistId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public StringBuilder AddBulkTasks(List<BulkTask> tasks)
        {
            List<DBCommand> commands = new List<DBCommand>();
            using (var manager = new DBManager(DataProvider.SqlServer, AppSettings.Get("database").ToString()))
            {
                manager.EnableBatchTransaction = true;
                foreach (var task in tasks)
                {
                    DBCommand cmd = new DBCommand("Util_CreateComplexTaskBasedOnTemplate");

                    // Due dates must not be in the past
                    var dueDate = task.DueDate.HasValue
                        ? (task.DueDate.Value.Date < DateTime.Today ? DateTime.Today : task.DueDate.Value.Date)
                        : (DateTime?)null;

                    var softDueDate = task.SoftDueDate.HasValue
                        ? (task.SoftDueDate.Value.Date < DateTime.Today ? DateTime.Today : task.SoftDueDate.Value.Date)
                        : (DateTime?)null;

                    cmd.AddParameter("@taskname", task.Task.Trim());
                    cmd.AddParameter("@DueDate", dueDate);
                    cmd.AddParameter("@softdue", softDueDate);
                    cmd.AddParameter("@CreatorUserId", Session.CurrentSession.QUser.Id);
                    cmd.AddParameter("@location", myTz.TimeZoneName ?? myTz.TimeZoneOverride);
                    cmd.AddParameter("@controller1", task.Controller1.Trim());
                    cmd.AddParameter("@controller2", task.Controller2.Trim());
                    cmd.AddParameter("@assignee1", task.Assignee1.Trim());
                    cmd.AddParameter("@assignee2", task.Assignee2.Trim());
                    cmd.AddParameter("@assignee3", task.Assignee3.Trim());
                    cmd.AddParameter("@item2", task.Item2.Trim());
                    cmd.AddParameter("@item3", task.Item3.Trim());
                    cmd.AddParameter("@item4", task.Item4.Trim());
                    cmd.AddParameter("@item5", task.Item5.Trim());
                    cmd.AddParameter("@item6", task.Item6.Trim());
                    cmd.AddParameter("@item7", task.Item7.Trim());
                    cmd.AddParameter("@item8", task.Item8.Trim());
                    cmd.AddParameter("@item9", task.Item9.Trim());
                    cmd.AddParameter("@statusReportName", task.StatusReportName.Trim());
                    cmd.AddParameter("@statusReportSection", task.StatusReportSection.Trim());
                    cmd.AddParameter("@PriorityList", task.ToPriorityList);
                    cmd.AddParameter("@Priority", task.Priority);
                    cmd.AddParameter("@IsDefaultToAssignee", task.IsDefaultToAssignee);
                    cmd.AddParameter("@IsOnStatusReport", task.IsOnStatusReport);

                    commands.Add(cmd);
                }

                manager.BatchExecute(commands.ToArray());

                StringBuilder returnMessages = new StringBuilder();
                if (manager.BatchException != null)
                {
                    foreach (var exception in manager.BatchException)
                    {
                        returnMessages.AppendLine($"{exception.Message}<br>");
                    }
                }

                return returnMessages;
            }
        }

        public NewTaskReturnValue CreateNewChecklist(int userId, NewChecklistInitializer initializer, bool willCustomize)
        {
            // get System due time
            //No! QCheck_CreateSimple_Part1 needs *local* dates/times
            var dueDateAndTime = //myTz.GetSystemTime(
                DateTime.Parse($"{initializer.DueDate:MM/dd/yyyy} {myTz.DueTime:00}:00")
                //)
                ;

            int newId, instanceId;
            if (!willCustomize)
            {
                using (var cmd = new CmdObj("QCheck_CreateSimple_part1"))
                {
                    cmd.Add("@ID", SqlDbType.Int, ParameterDirection.Output, 4);
                    cmd.Add("@Name", initializer.Name);
                    if (initializer.Priority.HasValue)
                        cmd.Add("@Priority", initializer.Priority.Value);
                    cmd.Add("@DueDate", dueDateAndTime.Date);
                    cmd.Add("@CreatedBy", userId);
                    if (initializer.TaskType.HasValue)
                        cmd.Add("@TaskType", initializer.TaskType.Value);
                    cmd.Add("@PrevFreqType", SqlDbType.Int, ParameterDirection.Output, 4);
                    cmd.Add("@RowsUpdated", SqlDbType.Int, ParameterDirection.Output, 4);
                    cmd.Add("@NewInstanceID", SqlDbType.Int, ParameterDirection.Output, 4);
                    cmd.Add("@NewActiveID", SqlDbType.Int, ParameterDirection.Output, 4);
                    cmd.Add("@GroupID", initializer.AssignedTo);
                    cmd.Add("@IsReminder", initializer.IsSelfControlled);
                    cmd.Add("@ReminderDate", myTz.GetSystemTime(DateTime.Parse($"{initializer.SoftDue:MM/dd/yyyy} {myTz.DueTime:00}:00")));
                    cmd.Add("@AddToPriorityList", initializer.AddToPriorityList);//added by venkat 04/20/2017                    
                    cmd.Add("@DueTime", dueDateAndTime.Hour + (dueDateAndTime.Minute / 60f));
                    cmd.Add("@TimeZone", myTz.TimeZoneName);

                    if (initializer.TemplateId > 0) cmd.Add("@TemplateChecklistID", initializer.TemplateId);

                    cmd.ExecuteNonQueryWithOutput();
                    int rowsUpdated = Convert.ToInt32(cmd["@RowsUpdated"]);
                    newId = Convert.ToInt32(cmd["@ID"]);
                    instanceId = Convert.ToInt32(cmd["@NewInstanceID"]);

                    if (rowsUpdated > 0)
                        using (var part2Cmd = new CmdObj("QCheck_UpdateSchedule_Part2"))
                        {
                            part2Cmd.Add("@InstanceID", instanceId);
                            part2Cmd.Add("@PrevFreqType", cmd["@PrevFreqType"] ?? DBNull.Value);
                            part2Cmd.Add("@activate", 1);
                            part2Cmd.ExecuteNonQueryWithOutput();
                        }
                }
            }
            else
            {
                using (var cmd = new CmdObj("QCheck_Create"))
                {
                    cmd.Add("@ID", SqlDbType.Int, ParameterDirection.Output, 4);
                    cmd.Add("@Name", initializer.Name);
                    cmd.Add("@CreatedBy", userId);
                    cmd.Add("@IsReminder", initializer.IsSelfControlled);
                    cmd.ExecuteNonQueryWithOutput();

                    newId = Convert.ToInt32(cmd["@ID"]);
                }

                this.AddChecklistItem(newId, 1, initializer.Name, "", userId);
                instanceId = this.CreateChecklistInstance(newId, userId);
                var taskSummaryRepo = new TaskSummaryRepository();
                if (initializer.TaskType.HasValue)
                {
                    var priority = 1;
                    if (initializer.Priority.HasValue)
                    {
                        priority = initializer.Priority.Value;
                    }
                    taskSummaryRepo.AddInstanceTaskType(instanceId, initializer.TaskType.Value, priority);
                }
                this.AddAssignee(instanceId, initializer.AssignedTo, userId);
                this.SaveSchedule(true, instanceId, 1, null, null, null,
                    DateTime.Parse($"{initializer.DueDate:MM/dd/yyyy} {myTz.DueTime:00}:00"), null, 0,
                    myTz.TimeZoneName, false, (initializer.DueDate - initializer.SoftDue).Days);
                //KVS 2017-09-26 - Removing these default alerts per Nelson and GPR
                //this.AddAlert(instanceId, "Reminder", 1, 17, null, null);
                //this.AddAlert(instanceId, "Reminder", null, -1, null, null);
            }

            if (initializer.FolderId > 0)
                using (var cmd = new CmdObj("QCheck_MoveChecklistToFolder"))
                {
                    cmd.Add("@UserID", userId);
                    cmd.Add("@ChecklistID", newId);
                    cmd.Add("@FolderID", initializer.FolderId);
                    cmd.ExecuteNonQueryWithOutput();
                }

            if (!initializer.IsSelfControlled && initializer.TemplateId == 0)
                using (var cmd = new CmdObj("QCheck_ForceChecklistManager"))
                {
                    cmd.Add("@ChecklistID", newId);
                    cmd.Add("@ManagerGroupID", initializer.ControllerId);
                    if (initializer.Controller2Id.HasValue)
                        cmd.Add("@Manager2GroupID", initializer.Controller2Id);
                    cmd.ExecuteNonQueryWithOutput();
                }

            /*
            4/29/2015 dalvarado - No longer doing this, there is a daily e-mail.  Leaving in place just in case we need to roll back.
            if (!willCustomize)
            {
			using (var cmd = new CmdObj("QCheck_NotifyControllerCreation"))
			{
				cmd.Add("@ChecklistID", newId);
				cmd.ExecuteNonQueryWithOutput();
			}
            }
            */

            ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByChecklistId, newId);
            return new NewTaskReturnValue() { ChecklistId = newId, InstanceId = instanceId };
        }

        public void ClearActive(int instanceId)
        {
            using (var cmd = new CmdObj("QCheck_ClearActive"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void UpdatePriority(int instanceID, int priority)
        {
            using (var cmd = new CmdObj("QStatus_UpdateTaskPriority"))
            {
                cmd.Add("@InstanceID", instanceID);
                cmd.Add("@Priority", priority);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void FinalizeCustomizableChecklist(int checklistId, int instanceId, DateTime? firstReminderDate)
        {
            if (firstReminderDate.HasValue)
            {
                using (var cmd = new CmdObj("QCheck_SetFirstReminderDate"))
                {
                    cmd.Add("@InstanceID", instanceId);
                    cmd.Add("@ReminderDate", myTz.GetSystemTime(firstReminderDate.Value));
                    cmd.ExecuteNonQueryWithOutput();
                }
            }
            /*
            4/29/2015 dalvarado - No longer doing this, there is a daily e-mail.  Just leaving in place in case we need to roll back.
			using (var cmd = new CmdObj("QCheck_NotifyControllerCreation"))
			{
				cmd.Add("@ChecklistID", checklistId);
				cmd.ExecuteNonQueryWithOutput();
			}
            */
        }

        public int CopyChecklist(int checklistId)
        {
            using (var cmd = new CmdObj("QCheck_CopyChecklist"))
            {
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@NewChecklistID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.Add("@NewOwner", Session.CurrentSession.QUser.Id);
                cmd.ExecuteNonQueryWithOutput();
                return Convert.ToInt32(cmd["@NewChecklistID"]);
            }
        }

        public void TakeControlOfChecklist(int activeChecklistId, int managerGroupId)
        {
            using (var cmd = new CmdObj("QCheck_ForceChecklistManagerByActiveChecklist"))
            {
                cmd.Add("@ActiveChecklistID", activeChecklistId);
                cmd.Add("@ManagerGroupID", managerGroupId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void DeleteChecklistInstance(int instanceId)
        {
            using (var cmd = new CmdObj("QCheck_DeleteInstance"))
            {
                cmd.Add("@ID", instanceId);
                cmd.ExecuteNonQueryWithOutput();
            }
            ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByInstanceId, instanceId);
        }

        public void ApprovalDeleteChecklistInstance(int instanceId, int changeId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_DeleteInstance"))
            {
                cmd.Add("@ID", instanceId);
                cmd.Add("@ChangeID", changeId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public int CopyChecklistInstance(int instanceId)
        {
            using (var cmd = new CmdObj("QCheck2_CopyInstance"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@ID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                return Convert.ToInt32(cmd["@ID"]);
            }
        }

        public void ApprovalCopyChecklistInstance(int instanceId, int changeId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_CopyInstance"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@changeID", changeId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ActivateChecklistInstance(int instanceId)
        {
            using (var cmd = new CmdObj("QCheck_ActivateInstance"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@AsOfDate", myTz.GetSystemTime());
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public List<ActiveDueDate> GetActiveDueDates(int instanceId)
        {
            using (var cmd = new CmdObj("QCheck_GetActiveDueDates"))
            {
                cmd.Add("@InstanceID", instanceId);
                return cmd.GetDS()
                    .Tables[0]
                    .AsEnumerable()
                    .Select(row => new ActiveDueDate(row, myTz))
                    .ToList();
            }
        }

        public List<ActiveDueDate> ApprovalGetActiveDueDates(int instanceId, int changeId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_GetActiveDueDates"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@ChangeId", changeId);
                return cmd.GetDS()
                    .Tables[0]
                    .AsEnumerable()
                    .Select(row => new ActiveDueDate(row, myTz))
                    .ToList();
            }
        }

        public int StartChecklist(int activeChecklistId, int upcomingId)
        {
            using (var cmd = new CmdObj("QCheck_ActivateFuture"))
            {
                cmd.Add("@InstanceID", activeChecklistId);
                cmd.Add("@UpcomingID", upcomingId);
                cmd.Add("@NewID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByChecklistId, activeChecklistId);
                return Convert.ToInt32(cmd["@NewID"]);
            }
        }

        public int AddChecklistItem(int checklistId, int itemTypeId, string text, string url, int userId)
        {
            using (var cmd = new CmdObj("QCheck2_AddItem"))
            {
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@ItemTypeID", itemTypeId);
                cmd.Add("@Text", text);
                cmd.Add("@URL", url);
                cmd.Add("@UserId", userId);
                cmd.Add("@ReturnID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                return Convert.ToInt32(cmd["@ReturnID"]);
            }
        }

        public int ApprovalAddChecklistItem(int checklistId, int changeId, int itemTypeId, string text, string url, int userId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_AddItem"))
            {
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@ChangeID", changeId);
                cmd.Add("@ItemTypeID", itemTypeId);
                cmd.Add("@Text", text);
                cmd.Add("@URL", url);
                cmd.Add("@UserId", userId);
                cmd.Add("@ReturnID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                return Convert.ToInt32(cmd["@ReturnID"]);
            }
        }

        public void MoveChecklistItem(int fromId, int toId)
        {
            using (var cmd = new CmdObj("QCheck_MoveItem"))
            {
                cmd.Add("@ID", fromId);
                cmd.Add("@MoveTo", toId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ApprovalMoveChecklistItem(int fromId, int toId, int changeId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_MoveItem"))
            {
                cmd.Add("@ID", fromId);
                cmd.Add("@MoveTo", toId);
                cmd.Add("@ChangeID", changeId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void UpdateChecklistItem(int itemId, int checklistId, int itemTypeId, string text, string url, int userId)
        {
            using (var cmd = new CmdObj("QCheck_UpdateItem"))
            {
                cmd.Add("@ID", itemId);
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@ItemTypeID", itemTypeId);
                cmd.Add("@Text", text);
                cmd.Add("@URL", url);
                cmd.Add("@UserId", userId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ApprovalUpdateChecklistItem(int itemId, int checklistId, int changeId, int itemTypeId, string text, string url, int userId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_UpdateItem"))
            {
                cmd.Add("@ID", itemId);
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@ChangeID", changeId);
                cmd.Add("@ItemTypeID", itemTypeId);
                cmd.Add("@Text", text);
                cmd.Add("@URL", url);
                cmd.Add("@UserId", userId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void DeleteChecklistItem(int itemId, int userId)
        {
            using (var cmd = new CmdObj("QCheck_DelItem"))
            {
                cmd.Add("@UserId", userId);
                cmd.Add("@ItemID", itemId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ApprovalDeleteChecklistItem(int itemId, int userId)
        {
            try
            {
                using (var cmd = new CmdObj("QCheck_Approval_DelItem"))
                {
                    cmd.Add("@ID", itemId);
                    cmd.Add("@UserId", userId);
                    cmd.ExecuteNonQueryWithOutput();
                }
            }
            catch (SqlException ex)
            {
                var message = ex.Message.ToString();
                return;
            }
        }

        public void SaveChecklistItem(int userId, int activeChecklistId, int activeChecklistItemId, bool isCompleted, string comments, out string completedBy, out string completedOn)
        {
            using (var cmd = new CmdObj("QCheck_CreateActiveItem"))
            {
                cmd.Add("@ActiveChecklistID", activeChecklistId);
                cmd.Add("@ChecklistItemID", activeChecklistItemId);
                cmd.Add("@IsCompleted", isCompleted);
                cmd.Add("@CompletedBy", userId);
                cmd.Add("@UserText", comments);
                cmd.Add("@CompletedByName", SqlDbType.VarChar, ParameterDirection.Output, 50);
                cmd.Add("@CompletedOn", SqlDbType.DateTime, ParameterDirection.Output, 1);
                cmd.ExecuteNonQueryWithOutput();

                completedBy = Convert.ToString(cmd["@CompletedByName"]);
                completedOn = Convert.ToString(myTz.GetLocalTimeEx((DateTime?)cmd["@CompletedOn"]));
            }
        }

        public void MoveChecklistToFolder(int checklistId, int userId, int folderId)
        {
            using (var cmd = new CmdObj("QCheck_MoveChecklistToFolder"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@FolderID", folderId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public int AddSubFolder(int userId, int folderId)
        {
            using (var cmd = new CmdObj("QCheck_AddSubFolder"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@FolderID", folderId);
                cmd.Add("@NewID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                return (int)cmd["@NewID"];
            }
        }

        public void DeleteFolder(int folderId)
        {
            using (var cmd = new CmdObj("QCheck_DeleteFolder"))
            {
                cmd.Add("@FolderID", folderId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void RenameFolder(int folderId, string name)
        {
            using (var cmd = new CmdObj("QCheck_RenameFolder"))
            {
                cmd.Add("@FolderID", folderId);
                cmd.Add("@FolderName", name);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void MoveFolderToFolder(int folderId, int newParentId)
        {
            using (var cmd = new CmdObj("QCheck_MoveFolderToFolder"))
            {
                cmd.Add("@FolderID", folderId);
                cmd.Add("@ParentID", newParentId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void DeleteStatus(int id, int userId)
        {
            using (var cmd = new CmdObj("DeleteInstanceTaskType"))
            {
                cmd.Add("@ID", id);
                cmd.Add("@UserID", userId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        // Overloading to prevent breaking parts of the app.
        public bool CompleteChecklist(int userId, int activeChecklistId, out int UpcomingDueTimeID, out int NewActiveChecklistID)
        {
            return CompleteChecklist(userId, activeChecklistId, false, "", out UpcomingDueTimeID, out NewActiveChecklistID);
        }

        public bool CompleteChecklist(int userId, int activeChecklistId, bool na, string naReason, out int UpcomingDueTimeID, out int NewActiveChecklistID)
        {
            using (var cmd = new CmdObj("QCheck_CompleteChecklist"))
            {
                cmd.Add("@ID", activeChecklistId);
                cmd.Add("@CompletedBy", userId);
                cmd.Add("@IsNA", na);
                cmd.Add("@NAReason", naReason);
                cmd.Add("@isComplete", SqlDbType.Bit, ParameterDirection.Output, 1);
                cmd.Add("@UpcomingDueTimeID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.Add("@NewActiveChecklistID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByTaskId, activeChecklistId);
                UpcomingDueTimeID = Convert.ToInt32(cmd["@UpcomingDueTimeID"]);
                NewActiveChecklistID = Convert.ToInt32(cmd["@NewActiveChecklistID"]);
                return Convert.ToBoolean(cmd["@isComplete"]);
            }
        }

        public void ReOpenChecklist(int taskId)
        {
            using (var cmd = new CmdObj("QCheck_ReOpenChecklist"))
            {
                cmd.Add("@ActiveChecklistID", taskId);
                cmd.ExecuteNonQueryWithOutput();
            }
            ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByTaskId, taskId);
        }

        public List<ChecklistItem> GetChecklistItems(int checklistId, int userId)
        {
            using (var cmd = new CmdObj("QCheck_GetChecklistItems"))
            {
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@UserId", userId);
                return cmd.GetDS()
                    .Tables[0]
                    .AsEnumerable()
                    .Select(row => new ChecklistItem
                    {
                        ItemId = (int)row["ID"],
                        ItemTypeString = (string)row["Type"],
                        ItemTypeId = (int)row["TypeID"],
                        Description = (string)row["Text"],
                        Url = (string)row["URL"]
                    }).ToList();
            }
        }

        public List<ChecklistItem> ApprovalGetChecklistItems(int checklistId, int changeId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_GetChecklistItems"))
            {
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@ChangeID", changeId);
                return cmd.GetDS()
                    .Tables[0]
                    .AsEnumerable()
                    .Select(row => new ChecklistItem
                    {
                        ItemId = (int)row["ID"],
                        ItemTypeString = (string)row["Type"],
                        ItemTypeId = (int)row["TypeID"],
                        Description = (string)row["Text"],
                        Url = (string)row["URL"]
                    }).ToList();
            }
        }

        public void ToggleTemplate(int id)
        {
            using (var cmd = new CmdObj("QCheck_ToggleTemplate"))
            {
                cmd.Add("@ID", id);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void UpdateChecklistName(int checklistId, string newName, int userId)
        {
            using (var cmd = new CmdObj("QCheck_UpdateChecklistName"))
            {
                cmd.Add("@ID", checklistId);
                cmd.Add("@Name", newName);
                cmd.Add("@UserId", userId);
                cmd.ExecuteNonQueryWithOutput();
            }
            Cache.CurrentCache.RefreshCachedStatusReportsByChecklistId(checklistId);
        }

        public void ApprovalUpdateChecklistName(int checklistId, int changeId, string newName, int userId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_UpdateChecklistName"))
            {
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@ChangeID", changeId);
                cmd.Add("@Name", newName);
                cmd.Add("@UserId", userId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public List<ChecklistInstance> GetChecklistInstances(int checklistId)
        {
            using (var cmd = new CmdObj("QCheck_GetInstances"))
            {
                cmd.Add("@ChecklistId", checklistId);
                return cmd.GetDS().Tables[0].AsEnumerable().Select(row => new ChecklistInstance(row)).ToList();
            }
        }

        public List<ChecklistInstance> ApprovalGetChecklistInstances(int checklistId, int changeId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_GetInstances"))
            {
                cmd.Add("@ChecklistId", checklistId);
                cmd.Add("@ChangeID", changeId);
                return cmd.GetDS().Tables[0].AsEnumerable().Select(row => new ChecklistInstance(row)).ToList();
            }
        }

        public int CreateChecklistInstance(int checklistId, int createdById)
        {
            using (var cmd = new CmdObj("QCheck_CreateInstance"))
            {
                cmd.Add("@ID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@CreatedBy", createdById);
                cmd.ExecuteNonQueryWithOutput();
                return Convert.ToInt32(cmd["@ID"]);
            }
        }

        public string GetChecklistName(int checklistId, int userId)
        {
            using (var cmd = new CmdObj("QCheck_GetName"))
            {
                cmd.Add("@ChecklistId", checklistId);
                cmd.Add("@UserId", userId);
                return (string)cmd.GetScalar();
            }
        }
        public int GetActiveChecklistIdByChecklistId(int checklistId)
        {
            using (var cmd = new CmdObj("QCheck_GetActiveChecklistIdByChecklistId"))
            {
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@ActiveChecklistID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();

                return Convert.ToInt32(cmd["@ActiveChecklistID"]);
            }
        }

        public string ApprovalGetChecklistName(int changeId, int userId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_GetChecklistName"))
            {
                cmd.Add("@ChangeID", changeId);
                cmd.Add("@UserId", userId);
                cmd.Add("@ChecklistName", SqlDbType.VarChar, ParameterDirection.Output, 500);
                cmd.ExecuteNonQueryWithOutput();
                return cmd["@ChecklistName"].ToString();
            }
        }

        public List<ChecklistManager> GetChecklistManagers(int checklistId, int changeId)
        {
            using (var cmd = new CmdObj("QCheck_GetManagers"))
            {
                cmd.Add("@ID", checklistId);
                cmd.Add("@ChangeID", changeId);
                return cmd.GetDS().Tables[0].AsEnumerable().Select(row => new ChecklistManager(row)).ToList();
            }
        }

        public int AddManagerToChecklist(int managerGroupId, int checklistId)
        {
            using (var cmd = new CmdObj("QCheck2_AddManager"))
            {
                cmd.Add("@GroupID", managerGroupId);
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@ReturnID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                return (int)cmd["@ReturnID"];
            }
        }

        public void ApprovalAddManagerToChecklist(int managerGroupId, int changeId, int checklistId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_AddManager"))
            {
                cmd.Add("@GroupID", managerGroupId);
                cmd.Add("@ChangeID", changeId);
                cmd.Add("@ChecklistID", checklistId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void DeleteManager(int id)
        {
            using (var cmd = new CmdObj("QCheck_DeleteManager"))
            {
                cmd.Add("@ID", id);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ApprovalDeleteManager(int id, int changeId, bool existing)
        {
            using (var cmd = new CmdObj("QCheck_Approval_DeleteManager"))
            {
                cmd.Add("@ID", id);
                cmd.Add("@ChangeID", changeId);
                cmd.Add("@Existing", existing);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public List<AssigneeInfo> GetAssigneesForInstance(int instanceId, int changeId)
        {
            using (var cmd = new CmdObj("QCheck_GetInstanceAssignments"))
            {
                cmd.Add("@InstanceID", instanceId);
                if (changeId > 0)
                    cmd.Add("@ChangeID", changeId);
                return cmd.GetDS().Tables[0].AsEnumerable().Select(row => new AssigneeInfo(row)).ToList();
            }
        }

        public int GetAssigneeCount(int instanceId, int changeId)
        {
            using (var cmd = new CmdObj("QCheck_GetInstanceAssigneeCounts"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@ChangeID", changeId);
                return cmd.GetDS().Tables[0].Rows[0]["Count"].ToIntEx().Value;
            }
        }

        public int AddAssignee(int instanceId, int groupId, int assignedById)
        {
            using (var cmd = new CmdObj("QCheck2_AddAssignedTo"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@GroupID", groupId);
                cmd.Add("@AssignedBy", assignedById);
                cmd.Add("@ReturnID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByInstanceId, instanceId);
                return (int)cmd["@ReturnID"];
            }
        }

        public void UpdateAssigneesForTask(int activeChecklistId, int[] assigneesList, int userId, string comment)
        {
            using (var cmd = new CmdObj("QCheck_UpdateAssigneesForTask"))
            {
                cmd.Add("@ActiveChecklistID", activeChecklistId);
                cmd.Add("@Assignees", string.Join(",", assigneesList));
                cmd.Add("@AssignedBy", userId);
                cmd.Add("@Comment", comment);
                cmd.ExecuteNonQueryWithOutput();
            }
            ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByTaskId, activeChecklistId);
        }

        public int ApprovalAddAssignee(int instanceId, int changeId, int groupId, int assignedById)
        {
            using (var cmd = new CmdObj("QCheck_Approval_AddAssignedTo"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@ChangeID", changeId);
                cmd.Add("@GroupID", groupId);
                cmd.ExecuteNonQueryWithOutput();
                return cmd.GetDS().Tables[0].Rows[0]["ID"].ToIntEx().Value;
            }
        }

        public void DeleteAssignee(int instanceId)
        {
            using (var cmd = new CmdObj("QCheck_DeleteAssignedTo"))
            {
                cmd.Add("@ID", instanceId);
                cmd.ExecuteNonQueryWithOutput();
            }
            ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByInstanceId, instanceId);
        }

        public void ApprovalDeleteAssignee(int id, int changeId, bool existing)
        {
            using (var cmd = new CmdObj("QCheck_Approval_DeleteAssignedTo"))
            {
                cmd.Add("@ID", id);
                cmd.Add("@ChangeID", changeId);
                cmd.Add("@Existing", existing);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public List<InstanceReportAssignment> GetInstanceReports(int instanceId)
        {
            using (var cmd = new CmdObj("QCheck_GetInstanceTaskTypes"))
            {
                cmd.Add("@InstanceID", instanceId);
                return
                    cmd.GetDS().Tables[0].AsEnumerable().Select(
                        row =>
                        new InstanceReportAssignment()
                        {
                            ID = (int)row["ID"],
                            Report = (string)row["Report"],
                            TaskType = (string)row["TaskType"],
                            ReportID = (int)row["ReportID"]
                        }).ToList();
            }
        }

        public List<InstanceAlertReminder> GetInstanceAlertsReminders(int instanceId, int changeId)
        {
            using (var cmd = new CmdObj("QCheck_GetAlertsAndReminders"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@ChangeID", changeId);
                return cmd.GetDS().Tables[0].AsEnumerable().Select(row => new InstanceAlertReminder(row)).ToList();
            }
        }

        public int AddAlert(int id, string alertType, int? nagBeforeDays = null, double? nagTime = null, int? alerteeGroupId = null, string alertText = null)
        {
            using (var cmd = new CmdObj("QCheck2_AddAlert"))
            {
                cmd.Add("@InstanceID", id);
                if (nagBeforeDays != null)
                    cmd.Add("@nagBeforeDays", nagBeforeDays);
                if (nagTime != null)
                    cmd.Add("@nagTime", nagTime);
                if (alerteeGroupId != null)
                    cmd.Add("@alerteegroupID", alerteeGroupId);
                cmd.Add("@alertType", alertType);
                if (alertText != null)
                    cmd.Add("@alertText", alertText);
                cmd.Add("@ReturnID", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.ExecuteNonQueryWithOutput();
                return (int)cmd["@ReturnID"];
            }
        }

        public void ApprovalAddAlert(int id, int changeId, string alertType, int? nagBeforeDays = null, double? nagTime = null, int? alerteeGroupId = null, string alertText = null)
        {
            using (var cmd = new CmdObj("QCheck_Approval_AddAlert"))
            {
                cmd.Add("@InstanceID", id);
                cmd.Add("@ChangeID", changeId);
                if (nagBeforeDays != null)
                    cmd.Add("@nagBeforeDays", nagBeforeDays);
                if (nagTime != null)
                    cmd.Add("@nagTime", nagTime);
                if (alerteeGroupId != null)
                    cmd.Add("@alerteegroupID", alerteeGroupId);
                cmd.Add("@alertType", alertType);
                if (alertText != null)
                    cmd.Add("@alertText", alertText);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void UpdateAlert(int id, int? nagBeforeDays = null, double? nagTime = null, int? alerteeGroupId = null, string alertText = null)
        {
            using (var cmd = new CmdObj("QCheck_UpdateAlert"))
            {
                cmd.Add("@ID", id);
                if (nagBeforeDays != null)
                    cmd.Add("@nagBeforeDays", nagBeforeDays);
                if (nagTime != null)
                    cmd.Add("@nagTime", nagTime);
                if (alerteeGroupId != null)
                    cmd.Add("@alerteegroupID", alerteeGroupId);
                if (alertText != null)
                    cmd.Add("@alertText", alertText);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void DeleteAlert(int id)
        {
            using (var cmd = new CmdObj("QCheck_DeleteAlert"))
            {
                cmd.Add("@ID", id);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ApprovalDeleteAlert(int id, int changeId, bool existing)
        {
            using (var cmd = new CmdObj("QCheck_Approval_DeleteAlert"))
            {
                cmd.Add("@ID", id);
                cmd.Add("@ChangeID", changeId);
                cmd.Add("@Existing", existing);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ClearActiveChecklist(int instanceId)
        {
            using (var cmd = new CmdObj("QCheck_ClearActive"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void AddSimpleAlert(int instanceId, int alertrrgroupId, string alertType)
        {
        }

        public void SetFirstReminderDate(int instanceId, DateTime reminderDate)
        {
            using (var cmd = new CmdObj("QCheck_SetFirstReminderDate"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@ReminderDate", myTz.GetSystemTime(reminderDate));
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void UpdateReminderDate(int taskId, DateTime reminderDate)
        {
            using (var cmd = new CmdObj("QCheck_UpdateReminderDate"))
            {
                cmd.Add("@TaskID", taskId);
                cmd.Add("@ReminderDate", myTz.GetSystemTime(reminderDate));
                cmd.ExecuteNonQueryWithOutput();
            }
            ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByTaskId, taskId);
        }

        public void UpdateSoftDueDate(int taskId, DateTime dueDate)
        {
            using (var cmd = new CmdObj("QCheck_UpdateSoftDue"))
            {
                cmd.Add("@TaskID", taskId);
                cmd.Add("@NewSoftDue", myTz.GetSystemTime(dueDate));
                cmd.ExecuteNonQueryWithOutput();
            }
            ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByTaskId, taskId);
        }

        public void UpdateInstanceReminderDates(int instanceId, int softDueOffsetDays)
        {
            using (var cmd = new CmdObj("QCheck_UpdateInstanceReminderDates"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@SoftDueOffsetDays", softDueOffsetDays);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void UpdateDueDate(int taskId, DateTime dueDate)
        {
            using (var cmd = new CmdObj("QCheck_UpdateDueDate"))
            {
                cmd.Add("@TaskID", taskId);
                cmd.Add("@DueDate", myTz.GetSystemTime(dueDate));
                cmd.Add("@changedby", Session.CurrentSession.QUser.Username);
                cmd.ExecuteNonQueryWithOutput();
            }
            ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByTaskId, taskId);
        }

        public void DeleteActiveChecklist(int taskId)
        {
            using (var cmd = new CmdObj("QCheck_DeleteActiveChecklist"))
            {
                cmd.Add("@ID", taskId);
                cmd.ExecuteNonQueryWithOutput();
            }
            ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByTaskId, taskId);
        }

        public void DeleteChecklist(int checklistId)
        {
            using (var cmd = new CmdObj("QCheck_Delete"))
            {
                cmd.Add("@ID", checklistId);
                cmd.ExecuteNonQueryWithOutput();
            }
            ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByChecklistId, checklistId);
        }

        public void ApprovalDeleteChecklist(int taskId, int changeId, string comment = "")
        {
            using (var cmd = new CmdObj("QCheck_Approval_DeleteChecklist"))
            {
                cmd.Add("@ChecklistID", taskId);
                cmd.Add("@ChangeId", changeId);
                cmd.ExecuteNonQueryWithOutput();
            }
            SendRequest(changeId, comment);
        }

        public InstanceSchedule GetScheduleForInstance(int instanceId)
        {
            using (var cmd = new CmdObj("QCheck_GetSchedule"))
            {
                cmd.Add("@InstanceID", instanceId);
                return cmd.GetDS().Tables[0].AsEnumerable().Select(row => new InstanceSchedule(row, myTz)).FirstOrDefault();
            }
        }

        public InstanceSchedule ApprovalGetScheduleForInstance(int instanceId, int changeId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_GetSchedule"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@ChangeID", changeId);
                return cmd.GetDS().Tables[0].AsEnumerable().Select(row => new InstanceSchedule(row, myTz)).FirstOrDefault();
            }
        }

        public void ActivateSchedule(int instanceId)
        {
            using (var cmd = new CmdObj("QCheck_ActivateSchedule"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@activateNow", 0);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void ApprovalSaveSchedule(int instanceId, int frequencyType, int? frequencyInterval, int? frequencyRecurrance, double dueTime,
            DateTime firstDueDate, DateTime? lastDueDate = null, int businessDayBehavior = 0, string timeZone = null, int? softDueOffsetDays = null, int? changeId = 0)
        {
            using (var cmd = new CmdObj("QCheck_Approval_Schedule_UPDATE"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@firstDueDate", firstDueDate);
                cmd.Add("@lastDueDate", lastDueDate);
                cmd.Add("@busDayBehavior", businessDayBehavior);
                cmd.Add("@SoftDueOffsetDays", softDueOffsetDays);
                cmd.Add("@freqType", frequencyType);
                cmd.Add("@freqInterval", frequencyInterval);
                cmd.Add("@freqRecurrance", frequencyRecurrance);
                cmd.Add("@dueTime", dueTime);
                cmd.Add("@TimeZone", timeZone);
                cmd.Add("@ChangeID", changeId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void SaveSchedule(bool newTask, int instanceId, int frequencyType, int? frequencyInterval, int? frequencyRecurrance,
            double? dueTime, DateTime firstDueDate, DateTime? lastDueDate = null, int businessDayBehavior = 0, string timeZone = null,
            bool activate = true, int? softDueOffsetDays = null, int? businessDayValue = null)
        {
            if (dueTime == null) dueTime = myTz.DueTime;
            if (timeZone == null) timeZone = myTz.TimeZoneName;

            int dueHour = (int)dueTime;
            int dueMin = dueHour == dueTime ? 0 : 30;
            int previousFrequencyType;
            int rowsUpdated;

            firstDueDate = DateTime.Parse($"{firstDueDate:MM/dd/yyyy} {dueHour:00}:{dueMin:00}");
            if (lastDueDate != null) lastDueDate = DateTime.Parse($"{lastDueDate:MM/dd/yyyy} {dueHour:00}:{dueMin:00}");

            var systemFirstDueDate = myTz.GetSystemTime(firstDueDate);

            using (var cmd = new CmdObj("QCheck_UpdateSchedule_Part1"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@firstDueDate", firstDueDate);
                cmd.Add("@lastDueDate", lastDueDate);
                cmd.Add("@busDayBehavior", businessDayBehavior);
                cmd.Add("@SoftDueOffsetDays", softDueOffsetDays);
                cmd.Add("@BusDayValue", businessDayValue);
                cmd.Add("@freqType", frequencyType);
                cmd.Add("@freqInterval", frequencyInterval);
                cmd.Add("@freqRecurrance", frequencyRecurrance);
                cmd.Add("@dueTime", firstDueDate.Hour + ((firstDueDate.Minute == 30) ? .5f : 0f));
                cmd.Add("@PrevFreqType", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.Add("@RowsUpdated", SqlDbType.Int, ParameterDirection.Output, 4);
                cmd.Add("@activate", activate);
                cmd.Add("@TimeZone", timeZone);
                cmd.ExecuteNonQueryWithOutput();
                if (cmd["@PrevFreqType"] != null)
                    previousFrequencyType = (int)cmd["@PrevFreqType"];
                else
                    previousFrequencyType = 0;
                rowsUpdated = (int)cmd["@RowsUpdated"];
            }
            if ((rowsUpdated <= 0) && !(newTask)) return;
            using (var cmd = new CmdObj("QCheck_UpdateSchedule_Part2"))
            {
                cmd.Add("@InstanceID", instanceId);
                cmd.Add("@PrevFreqType", previousFrequencyType);
                cmd.Add("@activate", activate);
                cmd.ExecuteNonQueryWithOutput();
            }
            ThreadPool.QueueUserWorkItem(Cache.CurrentCache.RefreshCachedStatusReportsByInstanceId, instanceId);
        }

        public void ApproveRequest(int changeId, int userId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_ApproveChange"))
            {
                cmd.Add("@ChangeID", changeId);
                cmd.Add("@UserID", userId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void RejectRequest(int changeId, int userId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_RejectChange"))
            {
                cmd.Add("@ChangeID", changeId);
                cmd.Add("@UserID", userId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void SendRequest(int changeId, string comment = "")
        {
            using (var cmd = new CmdObj("QCheck_Approval_SendRequest"))
            {
                cmd.Add("@ChangeID", changeId);
                cmd.Add("@Comment", comment);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public void CancelRequest(int changeId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_CancelRequest"))
            {
                cmd.Add("@ChangeID", changeId);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public bool DuplicateNameCheck(string name, int userID)
        {
            using (var cmd = new CmdObj("QCheck_DuplicateNameCheck"))
            {
                cmd.Add("@Name", name);
                cmd.Add("@UserID", userID);
                cmd.Add("@OKToUse", SqlDbType.Bit, ParameterDirection.Output, 1);
                cmd.ExecuteNonQueryWithOutput();
                return (bool)cmd["@OKToUse"];
            }
        }

        public string GetSigningKeyModel(DateTime asOf)
        {
            using (var cmd = new CmdObj("API_GetSigningKey"))
            {
                cmd.Add("@asOf", asOf);
                var results = cmd.GetDS().Tables[0].Rows;

                if (results.Count == 0)
                    throw new Exception("No signing key exists");

                if ((bool)results[0]["IsRevoked"])
                    throw new Exception("Signing key revoked");

                return results[0]["Key"].ToString();
            }
        }

        public void PersistSigningKeyModel(string signingKey, DateTime asOf)
        {
            using (var cmd = new CmdObj("API_SetSigningKey"))
            {
                cmd.Add("@Key", signingKey);
                cmd.Add("@asOf", asOf);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        public string LogAccessAttempt(string key, string keyType, string source, string methodName, bool success)
        {
            try
            {
                using (var cmd = new CmdObj("Util_Log3rdPartyAccessAttempt"))
                {
                    cmd.Add("@KeyValue", key);
                    cmd.Add("@KeyType", keyType);
                    cmd.Add("@Source", source);
                    cmd.Add("@MethodName", methodName);
                    cmd.Add("@Success", success);
                    cmd.Add("@AttemptDate", DateTime.UtcNow);
                    cmd.ExecuteNonQueryWithOutput();

                    return $"Auth attempt has been recorded";
                }
            }
            catch (SqlException ex)
            {
                var message = ex.Message.ToString();
                return message;
            }
        }

        public List<AuthProvider.AuthLog> GetApiKeyAuthLogs(string key, string keyType, string source, int minutesSince)
        {
            using (var cmd = new CmdObj("Util_Get3rdPartyAccessLogs"))
            {
                cmd.Add("@KeyValue", key);
                cmd.Add("@KeyType", keyType);
                cmd.Add("@Source", source);
                var sinceDate = DateTime.UtcNow.AddMinutes(minutesSince * -1);
                cmd.Add("@SinceDate", sinceDate);

                var ds = cmd.GetDS();

                if (ds.Tables[0].Rows.Count > 0)
                {
                    return ds.Tables[0].AsEnumerable().Select(g =>

                    new AuthProvider.AuthLog
                    {
                        Token = (string)g["KeyValue"],
                        Type = (string)g["KeyType"],
                        Source = (string)g["Source"],
                        Method = (string)g["MethodName"],
                        Success = (bool)g["Success"],

                        Timestamp = (DateTime)g["AttemptDate"]
                    }).ToList();
                }
                else
                    return new List<AuthProvider.AuthLog>();

            }
        }

        public string PersistAPIKey(AuthProvider.ApiKey model)
        {
            try
            {
                using (var cmd = new CmdObj("Util_AddApiKey"))
                {
                    cmd.Add("@Key", model.Key);
                    cmd.Add("@Requestor", model.Requestor);
                    cmd.Add("@Approver", model.Approver);
                    cmd.Add("@OnBehalfOf", model.OnBehalfOf);
                    cmd.Add("@Intent", model.Intent);
                    cmd.Add("@Issued", model.Issued);
                    cmd.Add("@Expires", model.Expires);
                    cmd.Add("@NotBefore", model.NotBefore);
                    cmd.Add("@IsRevoked", model.IsRevoked);
                    cmd.ExecuteNonQueryWithOutput();

                    return $"API key value {model.Key} has been saved";
                }
            }
            catch (SqlException ex)
            {
                var message = ex.Message.ToString();
                return message;
            }
        }

        public string CreateGenericChecklist(TaskFromBotRequest request)
        {
            var mainController = request.Controllers.Contains(",") ? request.Controllers.Substring(0, request.Controllers.IndexOf(',')) : request.Controllers;
            var remainingControllers = request.Controllers.Contains(",") ? request.Controllers.Substring(request.Controllers.IndexOf(',')).TrimStart(',').Trim() :
                "";
            try
            {
                using (var cmd = new CmdObj("QCheck_CreateTaskThroughChatbot"))
                {
                    cmd.Add("@TaskName", request.TaskName);
                    cmd.Add("@Assignees", request.Assignees);
                    cmd.Add("@MainController", mainController);
                    cmd.Add("@Controllers", remainingControllers);
                    cmd.Add("@Items", request.Items);
                    cmd.Add("@DueDate", request.DueDate);
                    cmd.Add("@LocalDueDate", request.LocalDueDate);
                    cmd.Add("@FinalDueDate", request.FinalDueDate);
                    cmd.Add("@location", request.Location);
                    cmd.Add("@DueTime", request.DueTime);
                    cmd.Add("@FreqRecurrance", request.RecurringInterval);
                    cmd.Add("@FreqType", request.RecurringSchedule);
                    cmd.Add("@FreqInterval", request.RecurringType);
                    cmd.Add("@BusinessDayBehavior", request.BusinessDayBehavior);
                    cmd.Add("@NewInstanceId", SqlDbType.Int, ParameterDirection.Output, 4);
                    cmd.ExecuteNonQueryWithOutput();

                    var newInstanceId = Convert.ToInt32(cmd["@NewInstanceId"]);

                    return $"{newInstanceId}";
                }
            }
            catch (SqlException ex)
            {
                var message = ex.Message.ToString();
                return message;
            }
        }


        public string CreateGenericChecklist(CreateChecklistRequest request)
        {
           
            int activeChecklistId = 0;
                try
                {
                    using (var cmd = new CmdObj("QCheck_CreateTaskThroughApi"))
                    {
                        cmd.Add("@TaskName", request.TaskName);
                        cmd.Add("@Assignees", request.Assignees);
                        cmd.Add("@Controller", request.Controller);
                        cmd.Add("@DueDate", request.DueDate);
                        cmd.Add("@DueTime", request.DueTime);
                        cmd.Add("@Location", request.Location);
                        cmd.Add("@ReportSectionId", request.SectionId);
                        cmd.Add("@NewActiveID", SqlDbType.Int, ParameterDirection.Output, 4);
                        cmd.ExecuteNonQueryWithOutput();

                        activeChecklistId = Convert.ToInt32(cmd["@NewActiveID"]);

                        return $"Task has been created with ActiveChecklistID: {activeChecklistId}";

                    }
                }
                catch (SqlException ex)
                {
                    var message = ex.Message.ToString();
                    return message;
                }

            return "";
        }

        public string CompleteTaskByIdOrName(int activeChecklistId = 0, string taskName = null)
        {
            try
            {
                using (var cmd = new CmdObj("QCheck_CompleteTaskByTaskNameOrId"))
                {
                    cmd.Add("@ActiveChecklistID", activeChecklistId);
                    cmd.Add("@TaskName", taskName);
                    cmd.Add("@isComplete", SqlDbType.Int, ParameterDirection.Output, 4);
                    cmd.ExecuteNonQueryWithOutput();

                    bool returnValue = Convert.ToBoolean(cmd["@isComplete"]);

                    return $"Task Completed: {returnValue}";
                }
            }
            catch (SqlException ex)
            {
                var message = ex.Message.ToString();
                return message;
            }
        }

        public string ChangeTaskDeadlineById(int activeChecklistId, UserTimeZone myTz, DateTime newDueDate)
        {
            try
            {
                using (var cmd = new CmdObj("QCheck_ChangeTaskDuedateThroughApi"))
                {
                    cmd.Add("@ActiveChecklistID", activeChecklistId);
                    cmd.Add("@newDueDate", newDueDate);
                    cmd.ExecuteNonQueryWithOutput();

                    return $"Task Date Changed to: {myTz.GetLocalTime(newDueDate)}";
                }
            }
            catch (SqlException ex)
            {
                var message = ex.Message.ToString();
                return message;
            }
        }

        public string AddChecklistItemThroughApi(int activeChecklistId, string itemText, string url, int itemType)
        {
            try
            {
                using (var cmd = new CmdObj("QCheck_AddItemsToChecklistThroughApi"))
                {
                    cmd.Add("@ActiveChecklistID", activeChecklistId);
                    cmd.Add("@Text", itemText);
                    cmd.Add("@ItemTypeID", itemType);
                    cmd.Add("@URL", url);
                    cmd.Add("@UserId", 0);
                    cmd.Add("@ReturnID", SqlDbType.Int, ParameterDirection.Output, 4);
                    cmd.ExecuteNonQueryWithOutput();

                    int returnValue = Convert.ToInt32(cmd["@ReturnID"]);

                    return $"New Item, {itemText} added with item id {returnValue}";
                }
            }
            catch (SqlException ex)
            {
                var message = ex.Message.ToString();
                return message;
            }
        }
        public string AddCommentsToTask(string comments, string taskName = null, string activeChecklistId = null)
        {
            try
            {
                using (var cmd = new CmdObj("QCheck_AddCommentsToTask"))
                {
                    cmd.Add("@Comments", comments);
                    cmd.Add("@TaskName", taskName);
                    cmd.Add("@ActiveChecklistId", activeChecklistId);
                    cmd.Add("@Result", SqlDbType.Int, ParameterDirection.Output, 4);
                    cmd.ExecuteNonQueryWithOutput();

                    bool returnValue = Convert.ToBoolean(cmd["@Result"]);

                    return $"Comments added to task: {returnValue}";
                }
            }
            catch (SqlException ex)
            {
                var message = ex.Message.ToString();
                return message;
            }
        }

        public GetStatusResponse GetStatusOfTask(int activeChecklistId = 0, string taskName = null)
        {
            var appTimezone = ConfigurationManager.AppSettings["ApiTimeZone"].ToString();
            var apiTimezone = new UserTimeZone(appTimezone, appTimezone, appTimezone);

            try
            {
                using (var cmd = new CmdObj("QStatus_GetStatusOfTasksByTaskOrUser"))
                {
                    var taskStatusResult = new List<TaskStatus>();
                    cmd.Add("@ActiveChecklistId", activeChecklistId);
                    cmd.Add("@TaskName", taskName);
                    cmd.Add("@UserName", null);
                    var ds = cmd.GetDS();

                    if (ds.Tables[0].Rows.Count > 0)
                    {
                        taskStatusResult.AddRange(
                        ds.Tables[0].AsEnumerable().Select(g => new TaskStatus
                        {
                            TaskName = (string)g["TaskName"],
                            DueDate = (DateTime)g["Deadline"],
                            Assignee = (string)g["Assignees"],
                            Controller = (string)g["Controllers"],
                            IsCompleted = Convert.ToBoolean(g["IsCompleted"]),
                        }).ToList()
                        );

                        var tasks = taskStatusResult.GroupBy(ts => ts.TaskName)
                                .Select(ts => new TaskStatusReport
                                {
                                    TaskName = ts.Key,
                                    Assignees = ts.Where(a => !string.IsNullOrEmpty(a.Assignee)).Select(a => a.Assignee).Distinct().ToList(),
                                    Controller = ts.Where(a => !string.IsNullOrEmpty(a.Controller)).Select(a => a.Controller).Distinct().ToList(),
                                    DueDate = apiTimezone.GetLocalTime(ts.FirstOrDefault().DueDate.Value),
                                    IsCompleted = Convert.ToBoolean(ts.FirstOrDefault().IsCompleted)
                                }).ToList();

                        return new GetStatusResponse() { Report = tasks, Message = $"Task Status Found. *All times shown in {appTimezone} time." };
                    }

                    else
                        return new GetStatusResponse() { Report = new List<TaskStatusReport>(), Message = "No Task Status Found" };
                }
            }
            catch (SqlException ex)
            {
                var message = ex.Message.ToString();
                return new GetStatusResponse() { Report = new List<TaskStatusReport>(), Message = message };
            }
        }

        public GetStatusResponse GetStatusOfAllTasksByUser(string userFullName)
        {
            var appTimezone = ConfigurationManager.AppSettings["ApiTimeZone"].ToString();
            var apiTimezone = new UserTimeZone(appTimezone, appTimezone, appTimezone);

            try
            {
                using (var cmd = new CmdObj("QStatus_GetStatusOfTasksByTaskOrUser"))
                {
                    var taskStatusResult = new List<TaskStatus>();
                    cmd.Add("@ActiveChecklistId", 0);
                    cmd.Add("@TaskName", null);
                    cmd.Add("@UserName", userFullName);

                    var ds = cmd.GetDS();
                    if (ds.Tables[0].Rows.Count > 0)
                    {
                        taskStatusResult.AddRange(
                        ds.Tables[0].AsEnumerable().Select(g => new TaskStatus
                        {
                            TaskName = (string)g["TaskName"],
                            DueDate = (DateTime)g["Deadline"],
                            Assignee = (string)g["Assignees"],
                            Controller = (string)g["Controllers"],
                            IsCompleted = Convert.ToBoolean(g["IsCompleted"]),
                        }).ToList()
                        );

                        var tasks = taskStatusResult.GroupBy(ts => ts.TaskName)
                                .Select(ts => new TaskStatusReport
                                {
                                    TaskName = ts.Key,
                                    Assignees = ts.Where(a => !string.IsNullOrEmpty(a.Assignee)).Select(a => a.Assignee).Distinct().ToList(),
                                    Controller = ts.Where(a => !string.IsNullOrEmpty(a.Controller)).Select(a => a.Controller).Distinct().ToList(),
                                    DueDate = apiTimezone.GetLocalTime(ts.FirstOrDefault().DueDate.Value),
                                    IsCompleted = Convert.ToBoolean(ts.FirstOrDefault().IsCompleted)
                                }).ToList();

                        return new GetStatusResponse() { Report = tasks, Message = $"Task Status Found. *All times shown in {appTimezone} time." };
                    }

                    else
                        return new GetStatusResponse() { Report = new List<TaskStatusReport>(), Message = "No Task Status Found" };
                }
            }
            catch (SqlException ex)
            {
                var message = ex.Message.ToString();
                return new GetStatusResponse() { Report = new List<TaskStatusReport>(), Message = message };
            }
        }

        public GetStatusResponse GetStatusOfAllTasksByReport(string reportName)
        {
            var appTimezone = ConfigurationManager.AppSettings["ApiTimeZone"].ToString();
            var apiTimezone = new UserTimeZone(appTimezone, appTimezone, appTimezone);

            try
            {
                using (var cmd = new CmdObj("QStatus_GetStatusOfTasksByStatusReport"))
                {
                    var taskStatusResult = new List<TaskStatus>();
                    cmd.Add("@ReportName", reportName);

                    var ds = cmd.GetDS();
                    if (ds.Tables[0].Rows.Count > 0)
                    {
                        taskStatusResult.AddRange(
                        ds.Tables[0].AsEnumerable().Select(g => new TaskStatus
                        {
                            TaskName = (string)g["TaskName"],
                            DueDate = (DateTime)g["Deadline"],
                            Assignee = (string)g["Assignees"],
                            Controller = (string)g["Controllers"],
                            IsCompleted = Convert.ToBoolean(g["IsCompleted"]),
                        }).ToList()
                        );

                        var tasks = taskStatusResult.GroupBy(ts => ts.TaskName)
                                .Select(ts => new TaskStatusReport
                                {
                                    TaskName = ts.Key,
                                    Assignees = ts.Where(a => !string.IsNullOrEmpty(a.Assignee)).Select(a => a.Assignee).Distinct().ToList(),
                                    Controller = ts.Where(a => !string.IsNullOrEmpty(a.Controller)).Select(a => a.Controller).Distinct().ToList(),
                                    DueDate = apiTimezone.GetLocalTime(ts.FirstOrDefault().DueDate.Value),
                                    IsCompleted = Convert.ToBoolean(ts.FirstOrDefault().IsCompleted)
                                }).ToList();

                        return new GetStatusResponse() { Report = tasks, Message = $"Task Status Found. *All times shown in {appTimezone} time." };
                    }

                    else
                        return new GetStatusResponse() { Report = new List<TaskStatusReport>(), Message = "No Task Status Found" };
                }
            }
            catch (SqlException ex)
            {
                var message = ex.Message.ToString();
                return new GetStatusResponse() { Report = new List<TaskStatusReport>(), Message = message };
            }
        }

        public IEnumerable<AuthProvider.ApiKey> GetApiKeys()
        {
            try
            {
                using (var cmd = new CmdObj("QCheck_RetrieveAPIKey"))
                {
                    var ds = cmd.GetDS();
                    if (ds.Tables[0].Rows.Count > 0)
                    {
                        return ds.Tables[0].AsEnumerable().Select(g =>

                        new AuthProvider.ApiKey
                        {
                            ID = Guid.Parse(g["ID"].ToString()),
                            Key = (string)g["Api_Key"],
                            Issued = (DateTime)g["Issued"],
                            Expires = (DateTime)g["Expires"],
                            NotBefore = (DateTime)g["NotBefore"],
                            IsRevoked = (bool)g["IsRevoked"],

                            Requestor = (string)g["Requestor"],
                            OnBehalfOf = (string)g["OnBehalfOf"],
                            Intent = (string)g["Intent"],

                        }).ToList();
                    }
                    else
                        return new List<AuthProvider.ApiKey>();

                }
            }
            catch (SqlException ex)
            {
                var message = ex.Message.ToString();
                return new List<AuthProvider.ApiKey>();
            }
        }

        public AuthProvider.ApiKey GetApiKey(Guid guid)
        {
            using (var cmd = new CmdObj("QCheck_RetrieveAPIKey"))
            {
                cmd.Add("@ID", guid);
                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    return ds.Tables[0].AsEnumerable()
                        .Select(g =>
                            new AuthProvider.ApiKey
                            {
                                ID = Guid.Parse(g["ID"].ToString()),
                                Key = (string)g["Api_Key"],
                                Intent = (string)g["Intent"],
                                Issued = myTz.GetLocalTime((DateTime)g["Issued"]),
                                Expires = (DateTime)g["Expires"],

                            }).First();
                }
                else
                    return null;
            }
        }

        public AuthProvider.ApiKey GetApiKey(string apiKey)
        {
            using (var cmd = new CmdObj("QCheck_RetrieveAPIKey"))
            {
                cmd.Add("@ApiKey", apiKey);
                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    return ds.Tables[0].AsEnumerable()
                        .Select(g =>
                            new AuthProvider.ApiKey
                            {
                                ID = Guid.Parse(g["ID"].ToString()),
                                Key = (string)g["Api_Key"],
                                Intent = (string)g["Intent"],
                                Issued = (DateTime)g["Issued"],
                                Expires = (DateTime)g["Expires"],

                            }).First();
                }
                else
                    return null;
            }
        }

        public string ConvertTimezonesOfAllSelectedTasks(int checklistInstancetId, string newLocation)
        {
            try
            {
                using (var cmd = new CmdObj("QCheck_ConvertTimezonesOfAllSelectedTasks"))
                {
                    cmd.Add("@ActiveChecklistID", checklistInstancetId);
                    cmd.Add("@NewTimeZone", newLocation);
                    cmd.ExecuteNonQueryWithOutput();
                }

                return "Success";
            }
            catch (SqlException ex)
            {
                return $"Failure due to {ex.Message}";
            }
            catch (Exception ex)
            {
                return $"Failure due to {ex.Message}";
            }
        }

        public string ReassignTaskToGroup(int checklistId, int groupId)
        {
            try
            {
                using (var cmd = new CmdObj("QCheck_ReassignTask"))
                {
                    cmd.Add("@ID", checklistId);
                    cmd.Add("@GroupID", groupId);
                    cmd.ExecuteNonQueryWithOutput();
                    return "success";
                }
            }
            catch (SqlException ex) { 
                var test = ex.InnerException;
                return ex.Message.ToString(); 
            }
                
        }
        public IEnumerable<LocationAwareTask> GetTasksIControlWithTimezones(int userId)
        {
            using (var cmd = new CmdObj("QCheck_GetTasksIControlWithTimezones"))
            {
                var taskList = new List<LocationAwareTask>();
                cmd.Add("@UserId", userId);
                var ds = cmd.GetDS();
                if (ds.Tables[0].Rows.Count > 0)
                {
                    taskList.AddRange(ds.Tables[0].AsEnumerable().Select(t => new LocationAwareTask
                    {
                        objId = (int)t["objID"],
                        ChecklistId = (int)t["ChecklistID"],
                        ChecklistName = (string)t["ChecklistName"],
                        DueTime = (DateTime)t["DueTime"],
                        Timezone = (string)t["TimeZone"],
                        IsRecurring = (bool)t["isRecurring"].ToBoolEx()
                    }));
                    return taskList;
                }
                else
                    return taskList;
            }
        }

        public List<RedactedTasksList> GetRedactedTasksList(int userId, int supervisorId, bool isOwnDashboard = false)
        {
            using (var cmd = new CmdObj("QCheck_RedactedTaskList"))
            {
                cmd.Add("@UserID", userId);
                cmd.Add("@SupervisorID", supervisorId);
                cmd.Add("@IsOwnDashboard", isOwnDashboard ? 1 : 0);

                var myGroups = cmd.GetDS();
                var testGroups = myGroups.Tables[0].AsEnumerable().Select(x => new RedactedTasksList
                {
                    ChecklistID = (int)x["ChecklistId"],
                    AssignmentID = (int)x["AssignmentId"],
                    ChecklistName = (string)x["ChecklistName"],
                    DueDate = (string)x["duetime"],
                    Controllers = (string)x["Controllers"],
                    StatusReportString = (string)x["StatusReportString"],
                    Assignees = (string)x["Assignees"],
                    DaysOutstanding = (int)x["DaysOutstanding"],
                    IsDue = (string)x["IsDue"]
                }).ToList();
                return testGroups;
            }
        }

        #region Comment History Popup

        public List<CommentHistoryList> GetCommentHistoryList(int checklistId, int userId)
        {
            using (var cmd = new CmdObj("QStatus_GetCommentHistory"))
            {
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@UserID", userId);
                var dataSet = cmd.GetDS();
                var list = dataSet.Tables[0].AsEnumerable().Select(x =>
                {
                    var comments = x.Field<string>("Comments");
                    var displayOrder = x.Field<int>("DisplayOrder");
                    var dt = x.Field<DateTime>("CommentDt");
                    var commentDt = string.Empty;
                    var initials = x.Field<string>("Initials");
                    var userID = x.Field<int>("UserID");
                    var isSpecialTask = x.Field<bool>("IsSpecialTask");
                    var isRelated = x.Field<int>("IsRelated") == 1;

                    return new CommentHistoryList
                    {
                        Comments = comments,
                        DisplayOrder = displayOrder,
                        dt = dt,
                        CommentDt = dt.ToString("MM/dd/yyyy"),
                        Initials = initials,
                        UserID = userID,
                        IsSpecialTask = isSpecialTask,
                        IsRelated = isRelated
                    };
                }).ToList();
                return list;
            }
        }

        public List<CommentHistoryList> GetCommentsAllHistory(int checklistId, int uniqueId, int userId)
        {
            using (var cmd = new CmdObj("QStatus_GetCommentsAllHistory"))
            {
                cmd.Add("@ChecklistID", checklistId);
                cmd.Add("@UniqueID", uniqueId);
                var dataSet = cmd.GetDS();
                var list = dataSet.Tables[0].AsEnumerable().Select(x =>
                {
                    var id = x.Field<int>("ID");
                    var comments = x.Field<string>("Comments");
                    var displayOrder = x.Field<int>("DisplayOrder");
                    var tabIn = x.Field<int>("TabIn");
                    var dt = x.Field<DateTime>("CommentDt");
                    var commentDt = string.Empty;
                    var initials = x.Field<string>("Initials");
                    var userID = x.Field<int>("UserID");
                    var replyID = x.Field<int?>("ReplyID");
                    //var colorNum = x.Field<int>("colornum");
                    var isRelated = x.Field<bool>("IsRelated");

                    return new CommentHistoryList
                    {
                        Id = id,
                        Comments = comments,
                        DisplayOrder = displayOrder,
                        TabIn = tabIn,
                        dt = dt,
                        CommentDt = dt.ToString("MM/dd/yyyy"),
                        Initials = initials,
                        UserID = userID,
                        ReplyID = replyID,
                        //ColorNum = colorNum,
                        IsRelated = isRelated
                    };
                }).ToList();
                return list;
            }
        }


        public List<DeadlineHistoryList> GetDeadlineHistoryList(int checklistId, int activeChecklistId, int userId)
        {
            using (var cmd = new CmdObj("QStatus_GetDeadlineHistory"))
            {
                cmd.Add("@ChecklistId", checklistId);
                cmd.Add("@ActiveChecklistId", checklistId);
                cmd.Add("@UserID", userId);
                var dataSet = cmd.GetDS();
                var list = dataSet.Tables[0].AsEnumerable().Select(x =>
                {
                    var origDueTime = x.Field<DateTime?>("OrigDueTime");
                    var dueTime = x.Field<DateTime?>("DueTime");
                    var requestDate = x.Field<DateTime?>("RequestDate");
                    var requestor = x.Field<string>("Requestor");
                    var approvedDate = x.Field<DateTime?>("ApprovedDate");
                    var approver = x.Field<string>("Approver");
                    var comment = x.Field<string>("Comment");
                    var completedDate = x.Field<DateTime?>("CompletedDate");
                    var completedBy = x.Field<string>("CompletedBy");

                    return new DeadlineHistoryList
                    {
                        OrigDueTime = origDueTime,
                        OrigDueTimeStr = origDueTime?.ToString("MM/dd/yyyy") ?? string.Empty,

                        DueTime = dueTime,
                        DueTimeStr = dueTime?.ToString("MM/dd/yyyy") ?? string.Empty,

                        RequestDate = requestDate,
                        RequestDateStr = requestDate?.ToString("MM/dd/yyyy") ?? string.Empty,

                        Requestor = requestor,

                        ApprovedDate = approvedDate,
                        ApprovedDateStr = approvedDate?.ToString("MM/dd/yyyy") ?? string.Empty,

                        Approver = approver,
                        Comment = comment,

                        CompletedDate = completedDate,
                        CompletedDateStr = completedDate?.ToString("MM/dd/yyyy") ?? string.Empty,

                        CompletedBy = completedBy
                    };
                }).ToList();
                return list;
            }
        }

        public List<ChangeHistoryList> GetChangeHistoryList(int checklistId, int userId)
        {
            using (var cmd = new CmdObj("QStatus_GetChangeHistory"))
            {
                cmd.Add("@ChecklistId", checklistId);
                cmd.Add("@UserID", userId);
                var dataSet = cmd.GetDS();
                var list = dataSet.Tables[0].AsEnumerable().Select(x =>
                {
                    var changeRequest = x.Field<string>("ChangeRequest");
                    var result = x.Field<string>("Result");
                    var resultPerson = x.Field<string>("ResultPerson");
                    var requestor = x.Field<string>("Requestor");
                    var comment = x.Field<string>("Comment");

                    var requestDate = x.Field<DateTime?>("RequestDate");
                    var resultDate = x.Field<DateTime?>("ResultDate");
                    return new ChangeHistoryList
                    {
                        ChangeRequest = changeRequest,
                        Result = result,
                        ResultPerson = resultPerson,
                        Requestor = requestor,
                        Comment = comment,
                        RequestDate = requestDate,
                        ResultDate = resultDate,
                        RequestDateStr = requestDate?.ToString("MM/dd/yyyy") ?? string.Empty,
                        ResultDateStr = resultDate?.ToString("MM/dd/yyyy") ?? string.Empty
                    };
                }).ToList();
                return list;
            }
        }

        #endregion Comment History Popup
    }
    public class InstanceSchedule
    {
        public int ID { get; set; }
        public DateTime FirstDueDate { get; set; }
        public DateTime? LastDueDate { get; set; }
        public int FrequencyType { get; set; }
        public int? FrequencyInterval { get; set; }
        public int? FrequencyRecurrance { get; set; }
        public double? DueTime { get; set; }
        public string TimeZone { get; set; }
        public int BusinessDayBehavior { get; set; }
        public int? SoftDueOffsetDays { get; set; }
        public int? BusinessDayValue { get; set; }
        public InstanceSchedule() { }
        public InstanceSchedule(DataRow row, UserTimeZone tz = null)
        {
            var dueTime = row["dueTime"].ToDoubleEx();
            var dueHours = (int)dueTime;
            var dueMins = (dueTime - (int)dueTime) == .5 ? 30 : 00;
            var firstDueDate = DateTime.Parse($"{row["firstDueDate"].ToDateTimeEx():MM/dd/yyyy} {dueHours:00}:{dueMins:00}");

            var lastDueDate = row["lastDueDate"].ToDateTimeEx();
            lastDueDate = lastDueDate != null
                ? DateTime.Parse($"{lastDueDate:MM/dd/yyyy} {dueHours:00}:{dueMins:00}")
                : (DateTime?)null;

            //if (tz != null)
            //{
            //    firstDueDate = tz.GetLocalTime(firstDueDate);
            //    lastDueDate = tz.GetLocalTimeEx(lastDueDate);
            //    dueTime = firstDueDate.Hour + (firstDueDate.Minute == 0 ? 0 : .5);
            //}

            ID = (int)row["ID"];
            FirstDueDate = firstDueDate;
            LastDueDate = lastDueDate;
            FrequencyType = (int)row["freqType"];
            FrequencyInterval = row["freqInterval"].ToIntEx();
            FrequencyRecurrance = row["freqRecurrance"].ToIntEx();
            DueTime = dueTime;
            BusinessDayBehavior = (int)row["busDayBehavior"];
            SoftDueOffsetDays = row["SoftDueOffsetDays"].ToIntEx();
            BusinessDayValue = row["busDayValue"].ToIntEx();

            if (row.Table.Columns.Contains("TimeZone"))
                TimeZone = row["TimeZone"].ToString();
        }
    }

    public class InstanceAlertReminder
    {
        public int ID { get; set; }
        public int? DaysBefore { get; set; }
        public double? AlertTime { get; set; }
        public string Alertee { get; set; }
        public string AlertType { get; set; }
        public AlertType AlertTypeEnum { get; set; }
        public string AlertText { get; set; }
        public int AlerteeID { get; set; }
        public bool Existing { get; set; }
        public InstanceAlertReminder(DataRow row)
        {
            ID = Convert.ToInt32(row["ID"]);
            DaysBefore = row["DaysBefore"].ToIntEx();
            AlertTime = row["AlertTime"].ToDoubleEx();
            Alertee = Convert.ToString(row["Alertee"]);
            AlertType = Convert.ToString(row["AlertType"]);
            AlertText = Convert.ToString(row["AlertText"]);
            AlerteeID = Convert.ToInt32(row.GetNullableValue("AlerteeID"));
            Existing = Convert.ToBoolean(row["Existing"]);

            AlertTypeEnum = (AlertType)Enum.Parse(typeof(AlertType), AlertType, true);
        }
    }

    public class InstanceReportAssignment
    {
        public int ID { get; set; }
        public string Report { get; set; }
        public string TaskType { get; set; }
        public int ReportID { get; set; }
    }

    public class AssigneeInfo
    {
        public int ID { get; set; }
        public string Name { get; set; }
        public bool Existing { get; set; }
        public AssigneeInfo(DataRow row)
        {
            ID = (int)row["ID"];
            Name = (string)row["Member"];
            Existing = (bool)row["Existing"];
        }
    }

    public class OverdueInfo
    {
        public DateTime MinDueDate { get; set; }
        public int OverdueCount { get; set; }
    }

    public class NewChecklistInitializer
    {
        public string Name { get; set; }
        public DateTime DueDate { get; set; }
        public DateTime SoftDue { get; set; }
        public int AssignedTo { get; set; }
        public bool IsSelfControlled { get; set; }
        public int FolderId { get; set; }
        public int? ControllerId { get; set; }
        public int? Controller2Id { get; set; }
        public int? Priority { get; set; }
        public int? TaskType { get; set; }
        public int TemplateId { get; set; }

        public bool AddToPriorityList { get; set; } //added by venkat 04/20/2017
    }

    public class ChecklistManager
    {
        public int ID { get; set; }
        public string Name { get; set; }
        public bool Existing { get; set; }
        public ChecklistManager(DataRow row)
        {
            ID = (int)row["ID"];
            Name = (string)row["FullName"];
            Existing = (bool)row["Existing"];
        }
    }

    public class NewTaskReturnValue
    {
        public int ChecklistId { get; set; }
        public int InstanceId { get; set; }
    }

    public class ChecklistInstance
    {
        public int ID { get; set; }
        public string Name { get; set; }
        public ChecklistInstance(DataRow row)
        {
            ID = (int)row["ID"];
            Name = (string)row["Name"] ?? "";
        }
    }

    public class ChecklistItem
    {
        public string Description { get; set; }
        public string Comments { get; set; }
        public string CompletedBy { get; set; }
        public DateTime? CompletedOn { get; set; }
        public string CompletedOnString { get; set; }
        public int ItemId { get; set; }
        public string Url { get; set; }
        public bool IsTaskComplete { get; set; }
        public bool IsItemComplete { get; set; }
        public TaskStage TaskStage { get; set; }
        public bool IsEditable { get; set; }
        public string ItemTypeString { get; set; }
        public int ItemTypeId { get; set; }

        public ChecklistItem() { }

        public ChecklistItem(DataRow dataRow)
        {
            if (!Convert.IsDBNull(dataRow["usertext"]))
                Comments = (string)dataRow["usertext"];
            if (!Convert.IsDBNull(dataRow["completedby"]))
            {
                CompletedBy = (string)dataRow["completedby"];
                //isEditable based on completedbyid != UserID 
            }
            if (!Convert.IsDBNull(dataRow["completeddate"]))
            {
                CompletedOnString = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTime(Convert.ToDateTime(dataRow["completeddate"])).ToString("MM/dd/yyyy h:mm:ss tt");
                CompletedOn = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTime(Convert.ToDateTime(dataRow["completeddate"]));
                IsItemComplete = true;
            }
            Description = (string)dataRow["text"];
            ItemId = (int)dataRow["ItemID"];
            ItemTypeString = (string)dataRow["ItemType"];
            Url = (string)dataRow["URL"];
        }
    }

    public class Checklist
    {
        public string Name { get; set; }
        public string StatusReportName { get; set; }
        public string SectionName { get; set; }
        public string Timezone { get; set; }
        public string Comments { get; set; }
        public int DisplayOrder { get; set; }
        public int ChecklistId { get; set; }
        public DateTime CreateDate { get; set; }
        public DateTime DueDate { get; set; }
        public DateTime ReminderDate { get; set; }
        public DateTime? CompletedOn { get; set; }
        public bool IsCompleted { get; set; }
        public ChecklistItem[] Items { get; set; }
        public int InstanceId { get; set; }
        public TaskStage TaskStage { get; set; }
        public bool CanToggle { get; set; }
        public bool IsEditable { get; set; }
        public int UpcomingId { get; set; }
        public int Identifier { get; set; }
        public int UniqueId { get; set; }
        public string Controllers { get; set; }
        public bool IsRecurring { get; set; }
        public string RecurranceSchedule { get; set; }
        public string StatusReportString { get; set; }
        public string Assignees { get; set; }
        public int AssigneeCount { get; set; }
        public bool IsVisible { get; set; }
        public bool IsDaily { get; set; }
        public DateTime? NewDeadline { get; set; }
        public string NewDeadlineText
        {
            get
            {
                return NewDeadline?.ToShortDateString() + " " + NewDeadline?.ToShortTimeString();
            }
        }
        public string CompletionCssClass
        {
            get
            {
                if (TaskStage == TaskStage.Future)
                    return "future";
                if (IsCompleted)
                    return "completed";
                if (DueDate < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow())
                    return "overdue";
                return "normal";
            }
        }
        public string CompletionString
        {
            get
            {
                if (TaskStage == TaskStage.Future)
                    return "Due";
                if (IsCompleted)
                    return "Completed";
                if (DueDate < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow())
                    return "Overdue";
                return "Due";
            }
        }
        public string DisplayDate
        {
            get
            {
                return (IsCompleted
                    ? CompletedOn.Value.ToString("MM/dd/yyyy h:mm tt")
                    : DueDate.ToString("MM/dd/yyyy h:mm tt"))
                    //+ $" {QProcess.Session.CurrentSession.QUser?.MyTimeZone.ClientTimeZone.GetAbbrString()}"
                    ;
            }
        }
        public string DisplayCreated
        {
            get
            {
                return CreateDate.ToString("MM/dd/yyyy");
            }
        }
        public bool PendingChange { get; set; }
        public bool? ControllerPartOfAssignee { get; set; } //added by venkat 06/13/2018
        public bool IsNA { get; set; }
        public bool IsOtherOverdue { get; set; }
        public string NAReason { get; set; }
    }

    public class RedactedTasksList
    {
        public int ChecklistID { get; set; }
        public int AssignmentID { get; set; }
        public string ChecklistName { get; set; }
        public string DueDate { get; set; }
        public string Assignees { get; set; }
        public string Controllers { get; set; }
        public string StatusReportString { get; set; }
        public string IsDue { get; set; }
        public int DaysOutstanding { get; set; }
    }

    public class CommentHistoryList
    {
        public int Id { get; set; }
        public int UserID { get; set; }
        public int DisplayOrder { get; set; }
        public int TabIn { get; set; }
        public int ColorNum { get; set; }
        public int? ReplyID { get; set; }
        public bool IsSpecialTask { get; set; }
        public bool IsRelated { get; set; }
        public string Initials { get; set; }
        public string Comments { get; set; }
        public string CommentDt { get; set; }
        public DateTime dt { get; set; }
        public List<CommentHistoryList> Replies { get; set; } = new List<CommentHistoryList>();
    }

    public class DeadlineHistoryList
    {
        public string CompletedBy { get; set; }
        public string Comment { get; set; }
        public string Requestor { get; set; }
        public string Approver { get; set; }
        public string OrigDueTimeStr { get; set; }
        public string DueTimeStr { get; set; }
        public string RequestDateStr { get; set; }
        public string ApprovedDateStr { get; set; }
        public string CompletedDateStr { get; set; }

        public DateTime? OrigDueTime { get; set; }
        public DateTime? DueTime { get; set; }
        public DateTime? RequestDate { get; set; }
        public DateTime? ApprovedDate { get; set; }
        public DateTime? CompletedDate { get; set; }
    }

    public class ChangeHistoryList
    {
        public string ChangeRequest { get; set; }
        public string Requestor { get; set; }
        public string Result { get; set; }
        public string ResultPerson { get; set; }
        public string Comment { get; set; }
        public string RequestDateStr { get; set; }
        public string ResultDateStr { get; set; }
        public DateTime? RequestDate { get; set; }
        public DateTime? ResultDate { get; set; }
    }


    public class ActiveDueDate
    {
        public int Id { get; set; }
        public DateTime DueTime { get; set; }
        public ActiveDueDate(DataRow dr, UserTimeZone utz)
        {
            Id = (int)dr["ID"];
            DueTime = utz.GetLocalTime((DateTime)dr["DueTime"]);
        }
    }

    public enum TaskStage
    {
        Current = 1,
        Archived,
        Future
    }

    public enum AlertType
    {
        Overdue = 1,
        Hours = 2,
        Assignment = 3,
        Schedule = 4,
        Custom = 5,
        Complete = 7,
        Reminder = 8
    };

    public class CreateChecklistRequest
    {
        public string TaskName { get; set; }
        public string Assignees { get; set; }
        public string Controller { get; set; }
        public int? SectionId { get; set; }
        public DateTime? DueDate { get; set; }
        public int DueTime { get; set; }
        public string Location { get; set; }
    }
    public class ItemDetails
    {
        public int Id { get; set; }
        public string ItemName { get; set; }
        public string ItemType { get; set; }
        //public string Assignee { get; set; }
        //public string Controller { get; set; }
        public string CompletedBy { get; set; }
        public DateTime? CompletedDate { get; set; }
        public bool IsCompleted { get; set; }
    }

    public class TaskStatus
    {
        public string TaskName { get; set; }
        public string Assignee { get; set; }
        public string Controller { get; set; }
        public DateTime? DueDate { get; set; }
        public bool IsCompleted { get; set; }
    }

    public class TaskStatusReport
    {
        public string TaskName { get; set; }
        public List<string> Assignees { get; set; }
        public List<string> Controller { get; set; }
        public DateTime? DueDate { get; set; }
        public bool IsCompleted { get; set; }
    }

    public class GetStatusResponse
    {
        public string Message { get; set; }
        public List<TaskStatusReport> Report { get; set; }
    }

    public class LocationAwareTask
    {
        public int objId { get; set; }

        public int ChecklistId { get; set; }
        public string ChecklistName { get; set; }

        public DateTime DueTime { get; set; }
        public DateTime ReminderDate { get; set; }

        public bool IsRecurring { get; set; }

        public DateTime OrigDueTime { get; set; }

        public string Timezone { get; set; }
    }

    public class ConvertTimezoneRequest
    {
        public int InstanceId { get; set; }
        public string CurrentLocation { get; set; }
        public string NewLocation { get; set; }
        public DateTime CurrentTimeStamp { get; set; }
        public bool IsRecurring { get; set; }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

