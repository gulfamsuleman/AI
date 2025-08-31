using DataAccessLayer;
using QProcess;
using QProcess.Domain.Models;
using QProcess.Domain.SYSTEM;
using QProcess.Extensions;
using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Data;
using System.Linq;
using System.Text;
using System.Web.Services;

namespace QProcess.Services
{
    [WebService(Namespace = "http://tempuri.org/")]
    [WebServiceBinding(ConformsTo = WsiProfiles.BasicProfile1_1)]
    [System.Web.Script.Services.ScriptService]
    public class ControlService : WebService
    {
        private Session session { get { return QProcess.Session.CurrentSession; } }

        public ControlService()
        {

            //Uncomment the following line if using designed components 
            //InitializeComponent(); 
        }

        [WebMethod(EnableSession = true)]
        public string Control_GET(string req)
        {
            if (session.QUser.Id <= 0) return "";

            return System.IO.File.ReadAllText(Server.MapPath("../ControlsSlim/Shared/" + req + ".html"));
        }

        [WebMethod(EnableSession = true)]
        public ChecklistItem[] ChecklistItem_GET(int uniqueId)
        {
            var list = new List<ChecklistItem>();
            using (var cmd = new CmdObj("QStatus_GetSlimChecklistItems"))
            {
                cmd.Add("@uniqueId", uniqueId);
                var ds = cmd.GetDS();

                foreach (DataRow row in ds.Tables[0].Rows)
                    list.Add(new ChecklistItem(row));
            }

            return list.Count > 0 ? list.ToArray() : null;
        }

        [WebMethod(EnableSession = true)]
        public NamedEntity[] Group_GET()
        {
            var selectListRepository = new SelectListRepository();

            return selectListRepository.GetGroups();
        }

        [WebMethod(EnableSession = true)]
        public NamedEntity[] Supervisor_GET()
        {
            var selectListRepository = new SelectListRepository();

            return selectListRepository.GetAllSupervisors();
        }

        [WebMethod(EnableSession = true)]
        public Checklist[] Checklist_GET(ChecklistRequest req)
        {
            var checklistRepo = new ChecklistRepository();
            var userRepo = new UserRepository();

            if (string.IsNullOrWhiteSpace(req.StartDate))
                req.StartDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-7).ToShortDateString();

            if (string.IsNullOrWhiteSpace(req.EndDate))
                req.EndDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-7).ToShortDateString();

            if (req.Recurrence == 0)
                req.Recurrence = userRepo.GetPreferredRecurrence(session.QUser.Id);

            return checklistRepo.GetSlimChecklists(session.QUser.Id, DateTime.Parse(req.StartDate), DateTime.Parse(req.EndDate), req.Recurrence, req.ActiveChecklistId, req.InstanceId)
                .OrderBy(c => c.IsCompleted)
                .ThenBy(c => c.IsCompleted ? c.CompletedOn : c.DueDate)
                .ToArray();
        }
        [WebMethod(EnableSession = true)]
        public Checklist[] ChecklistOtherOverdue_GET(ChecklistRequest req)
        {
            var checklistRepo = new ChecklistRepository();
            var userRepo = new UserRepository();

            if (string.IsNullOrWhiteSpace(req.StartDate))
                req.StartDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-7).ToShortDateString();

            if (string.IsNullOrWhiteSpace(req.EndDate))
                req.EndDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-7).ToShortDateString();

            if (req.Recurrence == 0)
                req.Recurrence = userRepo.GetPreferredRecurrence(session.QUser.Id);

            return checklistRepo.GetSlimOtherOverdueChecklists(session.QUser.Id, DateTime.Parse(req.StartDate), DateTime.Parse(req.EndDate), req.Recurrence, req.ActiveChecklistId, req.InstanceId)
                .OrderBy(c => c.IsCompleted)
                .ThenBy(c => c.IsCompleted ? c.CompletedOn : c.DueDate)
                .ToArray();
        }

        [WebMethod(EnableSession = true)]
        public ReportHeader[] StatusReportHeader_GET()
        {
            var userId = session.QUser.Id;
            var statusReportRepo = new StatusReportRepository();
            var list = new List<ReportHeader>();

            var headers = statusReportRepo.GetMyReportsListHeaders(userId);
            if (headers?.Count > 0)
            {
                list.Add(new ReportHeader() { ID = -1, Name = "My Reports" });
                list.AddRange(headers);
            }

            headers = statusReportRepo.GetReportListSupervised(userId, true);
            if (headers?.Count > 0)
            {
                list.Add(new ReportHeader() { ID = -2, Name = "Interested Party Reports" });
                list.AddRange(headers);
            }

            headers = statusReportRepo.GetReportListSupervised(userId, false);
            if (headers?.Count > 0)
            {
                list.Add(new ReportHeader() { ID = -3, Name = "Supervised Reports" });
                list.AddRange(headers);
            }

            return list.ToArray();
        }

        [WebMethod(EnableSession = true)]
        public CommentResponse[] Comment_GET(CommentRequest req)
        {
            var list = new List<CommentResponse>();
            using (var cmd = new CmdObj("QStatus_GetSlimCommentsByIds"))
            {
                cmd.Add("@ReportID", req.ReportId);
                cmd.Add("@UserID", session.QUser.Id);
                cmd.Add("@RecordId", CreateDataTable(req.Ids));
                var ds = cmd.GetDS();

                foreach (DataRow row in ds.Tables[0].Rows)
                    list.Add(new CommentResponse()
                    {
                        Id = (int)row["Id"],
                        Text = row["Text"].ToString()
                    });
            }

            return list.ToArray();
        }

    [WebMethod(EnableSession = true)]
    public TimeZoneResponse GetTimeZoneInfo(string tz)
    {
        var myTz = session.QUser?.MyTimeZone;
        if (myTz == null) return null;

        if (string.IsNullOrWhiteSpace(tz)) tz = "UTC";

        myTz.LastTimeZone = tz;
        myTz.Save(session.QUser.Id);

        return new TimeZoneResponse()
        {
            LastTimeZone = myTz.LastTimeZone,
            TimeZoneOverride = myTz.TimeZoneOverride,
            OffsetFromServer = myTz.GmtOffset
        };
    }

    [WebMethod(EnableSession = true)]
    public bool SetTimeZoneInfo(string tz)
    {
        var myTz = session.QUser?.MyTimeZone;
        if (myTz == null) return false;

        myTz.TimeZoneOverride = tz;
        myTz.Save(session.QUser.Id);

        return true;
    }

    private (DateTime, string) FormatTime(DateTime dte, string tz, int day = 0)
    {
        var tzi = TimeZoneHelper.GetTimeZone(tz);
        var ldt = TimeZoneInfo.ConvertTimeFromUtc(dte, tzi);
        var nme = tzi.IsDaylightSavingTime(ldt) ? tzi.DaylightName : tzi.StandardName;
        var abr = " " + string.Join("", nme.Split(' ').Where(s => s.Length > 2).Select(s => s[0]));

        if (day == 0 || day != ldt.Day)
            return (ldt, TimeZoneInfo.ConvertTimeFromUtc(dte, tzi).ToString("M/d/yyyy h:mm tt") + abr);
        else
            return (ldt, TimeZoneInfo.ConvertTimeFromUtc(dte, tzi).ToString("h:mm tt") + abr);
    }

    [WebMethod]
    public string ConvertTimeFromUtc(string date, string dstTz)
    {
        var dte = DateTime.Parse(date);
        var dstTzi = TimeZoneHelper.GetTimeZone(dstTz);

        return TimeZoneInfo.ConvertTimeFromUtc(dte, dstTzi).ToString("MM/dd/yyyy hh:mm tt");
    }

    [WebMethod]
    public string ConvertTimeToUtc(string date, string srcTz)
    {
        var dte = DateTime.Parse(date);
        var srcTzi = TimeZoneHelper.GetTimeZone(srcTz);

        return TimeZoneInfo.ConvertTimeToUtc(dte, srcTzi).ToString("MM/dd/yyyy hh:mm tt");
    }

    [WebMethod]
    public string FormatTime(string date, string localTz, string[] timezone)
    {
        var dte = DateTime.Parse(date);
        var rst = new List<string>();
        var (ldt, pri) = FormatTime(dte, localTz);

        for (int i = 0; i < timezone.Length; i++)
        {
            if (timezone[i] == localTz) continue;

            rst.Add("(" + FormatTime(dte, timezone[i], ldt.Day).Item2 + ")");
        }

        if (rst.Count > 0)
            return pri + " " + string.Join(", ", rst);
        else
            return pri;
    }

    [WebMethod]
    public bool RefreshTimeZoneInfo()
    {
        DataSet ds = null;
        using (var db = new DBCommand("TimeZone_GET"))
            ds = db.ExecuteDataSet();

        if (ds.Tables.Count == 0 || ds.Tables[0].Rows.Count == 0)
            return false;

        var sysTz = TimeZoneHelper.GetTimeZone(System.Configuration.ConfigurationManager.AppSettings["SystemTimeZone"]);

        foreach (DataRow row in ds.Tables[0].Rows)
        {
            var tzName = row[0].ToBlank();
            var gmtOffset = 0;

            // null or blank time zone will use server time zone so offset will be zero
            if (!string.IsNullOrWhiteSpace(tzName))
                gmtOffset = TimeZoneHelper.GetOffsetBetweenTimeZone(sysTz, TimeZoneHelper.GetTimeZone(tzName)).ToIntEx().Value;

            using (var db = new DBCommand("TimeZone_SET"))
                db.Add("@timezone", tzName)
                  .Add("@gmtOffset", gmtOffset)
                  .ExecuteNonQuery();
        }

        return true;
    }

    [WebMethod(EnableSession = false)]
    public string[] GetTimeZoneList() => TimeZoneHelper.GetTimeZoneNamesByCountryCode();

    
        [WebMethod(EnableSession = true)]
        public ChecklistAuthResponse ChecklistAuth_GET(ChecklistAuthRequest req)
        {
            var repo = new ChecklistRepository();
            var userId = QProcess.Session.CurrentSession.QUser.Id;
            var groupId = QProcess.Session.CurrentSession.QUser.GroupId;
            var taskStage = (TaskStage)Enum.Parse(typeof(TaskStage), req.TaskStage);
            var checklist = repo.GetSingleChecklist(userId, taskStage, req.TaskId);

            return new ChecklistAuthResponse()
            {
                Controller = repo.UserManagesChecklist(groupId, req.ChecklistId),
                IsDaily = checklist.IsDaily,
                PendingChange = checklist.PendingChange,
                DueDate = checklist.DueDate.ToString("MM/dd/yyyy h:mm tt"),
                ReminderDate = checklist.ReminderDate.ToString("MM/dd/yyyy h:mm tt"),
            };
        }

        [WebMethod(EnableSession = true)]
        public TaskNag TaskNag_GET(int checklistId)
        {
            using (var cmd = new CmdObj("QCheck_GetTaskNag"))
            {
                cmd.Add("@checklistId", checklistId);
                var ds = cmd.GetDS();

                if (ds.Tables[0].Rows.Count > 0)
                {
                    var row = ds.Tables[0].Rows[0];
                    var nag = new TaskNag();
                    nag.ChecklistId = checklistId;
                    nag.Subject = row["Subject"].ToString();
                    nag.BodyText = row["BodyText"].ToString();
                    nag.ScheduleType = bool.Parse(row["ScheduleType"].ToString());
                    nag.Recipients = row["Recipients"].ToString();

                    if (row["Interval"] != DBNull.Value)
                        nag.Interval = int.Parse(row["Interval"].ToString());

                    if (row["StartTime"] != DBNull.Value)
                        nag.StartTime = row["StartTime"].ToString();

                    if (row["EndTime"] != DBNull.Value)
                        nag.EndTime = row["EndTime"].ToString();

                    if (row["TimeOfDay"] != DBNull.Value)
                        nag.TimeOfDay = row["TimeOfDay"].ToString();

                    return nag;
                }
            }

            return null;
        }

        [WebMethod(EnableSession = true)]
        public bool TaskNag_SET(TaskNag req)
        {
            try
            {
                using (var cmd = new CmdObj("QCheck_SetTaskNag"))
                {
                    cmd.Add("@checklistId", req.ChecklistId);
                    cmd.Add("@subject", req.Subject);
                    cmd.Add("@bodyText", req.BodyText);
                    cmd.Add("@scheduleType", req.ScheduleType);
                    cmd.Add("@recipients", req.Recipients);
                    cmd.Add("@isActive", req.IsActive);

                    if (req.Interval != null) cmd.Add("@interval", req.Interval);
                    if (!string.IsNullOrWhiteSpace(req.StartTime)) cmd.Add("@startTime", req.StartTime);
                    if (!string.IsNullOrWhiteSpace(req.EndTime)) cmd.Add("@endTime", req.EndTime);
                    if (!string.IsNullOrWhiteSpace(req.TimeOfDay)) cmd.Add("@timeOfDay", req.TimeOfDay);

                    cmd.ExecuteNonQueryWithOutput();
                    return true;
                }
            }
            catch (Exception)
            {
                return false;
            }
        }

        private string GetColorText(int id)
        {
            switch (id)
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

    private DataTable CreateDataTable(IEnumerable<int> ids)
    {
        var table = new DataTable();
        table.Columns.Add("ID", typeof(int));
        foreach (var id in ids) table.Rows.Add(id);

        return table;
    }

        public class CommentResponse
        {
            public int Id { get; set; }
            public string Text { get; set; }
        }

        public class CommentRequest
        {
            public int[] Ids { get; set; }
            public int ReportId { get; set; }
        }

    
        public class ChecklistRequest
        {
            public string StartDate { get; set; }
            public string EndDate { get; set; }
            public int Recurrence { get; set; }
            public int? ActiveChecklistId { get; set; }
            public int? InstanceId { get; set; }
        }

        public class ChecklistAuthResponse
        {
            public string DueDate { get; set; }
            public string ReminderDate { get; set; }
            public bool Controller { get; set; }
            public bool PendingChange { get; set; }
            public bool IsDaily { get; set; }
        }
        public class ChecklistAuthRequest
        {
            public string TaskStage { get; set; }
            public int ChecklistId { get; set; }
            public int TaskId { get; set; }
        }

        public class TaskNag
        {
            public int ChecklistId { get; set; }
            public string Subject { get; set; }
            public string BodyText { get; set; }
            public bool ScheduleType { get; set; }
            public int? Interval { get; set; } = null;
            public string StartTime { get; set; } = null;
            public string EndTime { get; set; } = null;
            public string TimeOfDay { get; set; } = null;
            public string Recipients { get; set; }
            public bool IsActive { get; set; } = true;
        }

        public class TimeZoneResponse
        {
            public string LastTimeZone { get; set; } = null;
            public string TimeZoneOverride { get; set; } = null;
            public int OffsetFromServer { get; set; } = 0;
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

