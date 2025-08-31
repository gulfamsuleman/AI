using QProcess.Models;
using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Mobile
{
    public partial class Mobile : QProcessMasterPage
    {
        protected int ReportId { get; set; }
        protected string CurrentViewName { get; set; }
        protected DateTime LastViewTime { get; set; }
        public IUser QUser => QProcess.Session.CurrentSession.QUser;

        protected override void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            base.Page_Load(sender, e);

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
                LogPageUsage(userId, browser, true, CurrentViewName);
            }

            var UserRepo = new Repositories.UserRepository();
            if (UserRepo.HasOldOverdueTasks(QProcess.Session.CurrentSession.QUser.Id)
                && !Configuration.AppSettings.AppName.Contains("Dev"))
            {
                if (Request.Url.LocalPath.Split('/').Last() != "MobileReports.aspx")
                {
                    Response.Redirect("/Mobile/MobileReports.aspx?o=1");
                }
            }
            
            if (this.Page is IProvideReportIdForLogging)
                ReportId = ((IProvideReportIdForLogging)this.Page).ReportId;
            if (this.Page is IProvideLastViewTimeForLogging)
                LastViewTime = ((IProvideLastViewTimeForLogging)this.Page).LastViewTime;
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

        protected override void Render(HtmlTextWriter writer)
        {
            if (Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request))
                base.Render(writer);
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

