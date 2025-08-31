using QProcess.Controls;
using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Mobile
{
    public partial class MobileInbox : SessionPage, IProvideReportIdForLogging, IProvideLastViewTimeForLogging, IFooterHidden
    {
        protected int UserId { get; set; }
        protected int SetUserId { get; set; }
        public int ReportId { get; set; }
        public int TaskId { get; set; }
        public DateTime LastViewTime { get; set; }
        protected UserSettings UserSettings { get; set; }
        protected List<NamedEntity> TaskTypes { get; set; }

        public MobileInbox()
        {
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            UserId = CurrentSession.QUser.Id;
            ReportId = Convert.ToInt32(Context.Request.Params["reportId"]);
            SetTaskID();

            if (Context.Request.Params["lastViewTime"] != null)
                LastViewTime = DateTime.Parse(Context.Request.Params["lastViewTime"]);
            else
                LastViewTime = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow();
        }

        protected void SetTaskID()
        {
            if (Context.Request.QueryString["TaskID"] != null)
            {
                TaskId = Convert.ToInt32(Context.Request.QueryString["TaskId"]);
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

