using System;
using System.Linq;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using QProcess.Extensions;
using QProcess.Models;

namespace QProcess
{

    public partial class SiteMaster : QProcessMasterPage
    {
        private const string AntiXsrfTokenKey = "__AntiXsrfToken";
        private const string AntiXsrfUserNameKey = "__AntiXsrfUserName";
        private string _antiXsrfTokenValue;
        public IUser QUser => QProcess.Session.CurrentSession.QUser;
        private DateTime? BeginServerLoad { get; set; }
        protected int ServerLoadTime { get; set; }
        protected string CurrentPageName { get; set; }
        protected string CurrentViewName { get; set; }
        protected int ReportId { get; set; }
        protected DateTime LastViewTime { get; set; }

        public HtmlGenericControl MyTasksLi { get; set; }
        public HtmlGenericControl CalendarLi { get; set; }
        public HtmlGenericControl ManageTasksLi { get; set; }
        public HtmlGenericControl NewTaskLi { get; set; }
        public HtmlGenericControl ChangeRequestsLi { get; set; }
        public HtmlGenericControl ReportssLi { get; set; }
        public HtmlGenericControl UsersLi { get; set; }
        public HtmlGenericControl GroupsLi { get; set; }
        public HtmlGenericControl TaskSummaryLi { get; set; }
        public HtmlGenericControl MyStatusLi { get; set; }
        public HtmlGenericControl MyInboxLi { get; set; }
        public HtmlGenericControl PrioritiesLi { get; set; }

        public SiteMaster()
        {
            MyTasksLi = new HtmlGenericControl("li");
            CalendarLi = new HtmlGenericControl("li");
            ManageTasksLi = new HtmlGenericControl("li");
            NewTaskLi = new HtmlGenericControl("li");
            ChangeRequestsLi = new HtmlGenericControl("li");
            ReportssLi = new HtmlGenericControl("li");
            UsersLi = new HtmlGenericControl("li");
            GroupsLi = new HtmlGenericControl("li");
            TaskSummaryLi = new HtmlGenericControl("li");
            MyStatusLi = new HtmlGenericControl("li");
            MyInboxLi = new HtmlGenericControl("li");
            PrioritiesLi = new HtmlGenericControl("li");
        }

        protected void Page_PreRender(object sender, EventArgs e)
        {
            var timeSpan = QProcess.Session.CurrentSession?.UserTimeZone?.GetLocalTimeNow() - BeginServerLoad;
            if(timeSpan.HasValue)
                ServerLoadTime = timeSpan.Value.Milliseconds 
                    + 1000 * timeSpan.Value.Seconds 
                    + 60000 * timeSpan.Value.Minutes;
        }

        protected void Page_Init(object sender, EventArgs e)
        {
            // The code below helps to protect against XSRF attacks
            var requestCookie = Request.Cookies[AntiXsrfTokenKey];
            Guid requestCookieGuidValue;
            if (requestCookie != null && Guid.TryParse(requestCookie.Value, out requestCookieGuidValue))
            {
                // Use the Anti-XSRF token from the cookie
                _antiXsrfTokenValue = requestCookie.Value;
                Page.ViewStateUserKey = _antiXsrfTokenValue;
            }
            else
            {
                // Generate a new Anti-XSRF token and save to the cookie
                _antiXsrfTokenValue = Guid.NewGuid().ToString("N");
                Page.ViewStateUserKey = _antiXsrfTokenValue;

                var responseCookie = new HttpCookie(AntiXsrfTokenKey)
                {
                    HttpOnly = true,
                    Value = _antiXsrfTokenValue
                };
                if (FormsAuthentication.RequireSSL && Request.IsSecureConnection)
                {
                    responseCookie.Secure = true;
                }
                Response.Cookies.Set(responseCookie);
            }
            BeginServerLoad = QProcess.Session.CurrentSession?.UserTimeZone?.GetLocalTimeNow();
            Page.PreLoad += master_Page_PreLoad;
        }

        void master_Page_PreLoad(object sender, EventArgs e)
        {
            if (!IsPostBack)
            {
                // Set Anti-XSRF token
                ViewState[AntiXsrfTokenKey] = Page.ViewStateUserKey;
                ViewState[AntiXsrfUserNameKey] = QProcess.Session.CurrentSession.QUser.Username ?? String.Empty;
            }
            else
            {
                // Validate the Anti-XSRF token
                if ((string)ViewState[AntiXsrfTokenKey] != _antiXsrfTokenValue
                    || (string)ViewState[AntiXsrfUserNameKey] != (QProcess.Session.CurrentSession.QUser.Username ?? String.Empty))
                {
                    throw new InvalidOperationException("Validation of Anti-XSRF token failed.");
                }
            }
        }

        protected override void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            base.Page_Load(sender, e);            

            var UserRepo = new Repositories.UserRepository();
            if (UserRepo.HasOldOverdueTasks(QProcess.Session.CurrentSession.QUser.Id) 
                && !Configuration.AppSettings.AppName.Contains("Dev"))
            {
                if (Request.Url.LocalPath.Split('/').Last() != "Reports.aspx" 
                    || Request.QueryString["ViewMode"] == "mobile")
                {
                    if(Request.IsMobileBrowser()
                        && !QProcess.Session.CurrentSession.ForceDesktop(Request))
                        Response.Redirect("/Mobile/MobileReports.aspx?o=1");
                    else
                        Response.Redirect("Reports.aspx?o=1");
                }
            }
            SetCurrentPage();
            SetCurrentViewName();

            if (!IsPostBack)
            {
                int userId = QProcess.Session.CurrentSession.QUser.Id;
                string pageUrl = Request.Url.AbsolutePath;
                var browser = Context.Request.Browser.Browser + " " +
                              Context.Request.Browser.MajorVersion + "." +
                              Context.Request.Browser.MinorVersion + " / " +
                              Context.Request.Browser.Platform;
                if (Context.Request.Browser.AOL)
                    browser += " (AOL)";
                LogPageUsage(userId, browser, false, CurrentViewName);
            }

            if (this.Page is IProvideReportIdForLogging)
                ReportId = ((IProvideReportIdForLogging)this.Page).ReportId;
            if (this.Page is IProvideLastViewTimeForLogging)
                LastViewTime = ((IProvideLastViewTimeForLogging)this.Page).LastViewTime;
        }
        private void LogPageUsage(int userId, string browser, bool isMobile, string activity = null)
        {
            using (var cmd = new CmdObj("LogPageUsage"))
            {
                cmd.Add("@UserId", userId);
                cmd.Add("@Dt", DateTime.Now);
                cmd.Add("@Browser", browser ?? (object)DBNull.Value);
                cmd.Add("@IsMobile", isMobile);
                cmd.Add("@Activity", activity ?? (object)DBNull.Value);
                cmd.ExecuteNonQueryWithOutput();
            }
        }

        private void SetCurrentViewName()
        {
            var page = Request.Url.LocalPath.Split('/').Last();
            var view = Request.QueryString["view"] ?? Request.Form["view"];
            var tab = Request.QueryString["tab"] ?? Request.Form["tab"];
            if (!string.IsNullOrEmpty(view))
                CurrentViewName = $"{page}:{view}";
            else if (!string.IsNullOrEmpty(tab))
                CurrentViewName = $"{page}:{tab}";
            else
                CurrentViewName = page;
        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request))
                base.Render(writer);
        }

        private void SetCurrentPage()
        {
            CurrentPageName = Request.Url.LocalPath.Split('/').Last(); // Request.Url.ToString().Split('/').Last();

            switch (CurrentPageName)
            {
                case "MyTasks.aspx":
                    MyTasksLi.Attributes["class"] = "active";
                    break;
                case "Calendar.aspx":
                    CalendarLi.Attributes["class"] = "active";
                    break;
                case "ManageTasks.aspx":
                    ManageTasksLi.Attributes["class"] = "active";
                    break;
                case "NewTask.aspx":
                    NewTaskLi.Attributes["class"] = "active";
                    break;
                case "ChangeRequests.aspx":
                    ChangeRequestsLi.Attributes["class"] = "active";
                    break;
                case "Reports.aspx":
                    ReportssLi.Attributes["class"] = "active";
                    break;
                case "Users.aspx":
                    UsersLi.Attributes["class"] = "active";
                    break;
                case "Groups.aspx":
                    GroupsLi.Attributes["class"] = "active";
                    break;
                case "TaskSummary.aspx":
                    TaskSummaryLi.Attributes["class"] = "active";
                    break;
                case "MyStatus.aspx":
                    MyStatusLi.Attributes["class"] = "active";
                    break;
                case "MyInbox.aspx":
                    MyInboxLi.Attributes["class"] = "active";
                    break;
                case "Priorities.aspx":
                    PrioritiesLi.Attributes["class"] = "active";
                    break;
                //case "Nags.aspx":
                //    NagsLi.Attributes["class"] = "active";
                //    break;
            }
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

