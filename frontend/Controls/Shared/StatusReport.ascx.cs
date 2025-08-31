using System;
using System.Linq;
using QProcess.Repositories;
using System.Web.UI.WebControls;

namespace QProcess.Controls
{
    public partial class Controls_Shared_StatusReport : QProcessControl, IProvideLastViewTimeForLogging
    {
        protected StatusReport Report { get; set; }
        public int ReportId { get; set; }
        protected int UserId { get; set; }
        protected bool IsArchive { get; set; }
        public bool IsInbox { get; set; }
        protected string TasksIControl { get; set; }
        protected bool LargeFont { get; set; }
        public DateTime LastViewTime { get; set; }
        public int TaskWidth { get; set; }
        public string CommentColor { get; set; }
        public int ColorNum { get; set; }
        protected string FontClass { get; set; }
        public Repeater Repeater1 { get; set; }

        public Controls_Shared_StatusReport()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            Models.IUser qUser = CurrentSession.QUser;

            if (!Request.IsAuthenticated) return;

            var userRepo = new UserRepository();
            UserId = qUser.Id;

            LargeFont = userRepo.GetPreference(UserId, "Fonts") == "0";
            if (LargeFont)
            {
                FontClass = "class=\"serif-fonts\"";
            }
            else
            {
                FontClass = "";
            }

            if (Context.Request.Headers["X-IsArchive"] != null)
                IsArchive = Convert.ToBoolean(Context.Request.Headers["X-IsArchive"]);

            if (Context.Request.Headers["X-ReportId"] != null)

                ReportId = Convert.ToInt32(Context.Request.Headers["X-ReportId"]);
            if (Context.Request.Headers["X-IsInbox"] != null)
                IsInbox = Convert.ToBoolean(Context.Request.Headers["X-IsInbox"]);

            SetTasksIControl();

            if (Context.Request.Headers["X-LastViewed"] != null &&
                String.IsNullOrEmpty((Context.Request.Headers["X-LastViewed"] != null).ToString()))
            {
                LastViewTime = Convert.ToDateTime(Context.Request.Headers["X-LastViewed"]);
                if (LastViewTime > QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-1))
                {
                    LastViewTime = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-1);
                }
                Report = QProcess.Cache.CurrentCache.GetReportSlim(UserId, ReportId, IsArchive, LastViewTime);
            }
            else
            {
                Report = QProcess.Cache.CurrentCache.GetReportSlim(UserId, ReportId, IsArchive);
                LastViewTime = Report.ReportLines.FirstOrDefault(l => l.LineType == ReportLine.Type.Header)?.DueDate ?? QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-1);
                if (LastViewTime > QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-1))
                {
                    LastViewTime = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-1);
                }
            }

            var repo = new StatusReportRepository();
            TaskWidth = repo.GetColumnWidth(UserId, ReportId);
            ColorNum = repo.GetCommentColor(UserId, ReportId);

            switch (ColorNum)
            {
                case 0:
                    CommentColor = "red";
                    break;
                case 1:
                    CommentColor = "blue";
                    break;
                case 2:
                    CommentColor = "#800000";
                    break;
                case 3:
                    CommentColor = "#008000";
                    break;
                case 4:
                    CommentColor = "#660";
                    break;
                case 50:
                    CommentColor = "#800080";
                    break;
                default:
                    CommentColor = "black";
                    break;
            }
            Repeater1.DataSource = Report.ReportLines;
            Repeater1.DataBind();
        }

        protected void SetTasksIControl()
        {
            var userRepo = new UserRepository();
            TasksIControl = userRepo.GetActiveChecklistsIManage(UserId);
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

