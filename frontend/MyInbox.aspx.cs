using System;
using System.Collections.Generic;
using System.Web;
using QProcess.Repositories;
using QProcess.Controls;
using System.Web.UI;
using QProcess.Extensions;

namespace QProcess
{

    public partial class MyInbox : SessionPage, IProvideReportIdForLogging, IProvideLastViewTimeForLogging, IFooterHidden
	{
		protected int UserId { get; set; }
		protected int SetUserId { get; set; }
		public int ReportId { get; set; }
		public int TaskId { get; set; }
		public DateTime LastViewTime { get; set; }
		protected UserSettings UserSettings { get; set; }
		protected List<NamedEntity> TaskTypes { get; set; }
        
		public Controls_Shared_ReportToolbar ReportToolbar { get; set; }

        public MyInbox()
        {
            ReportToolbar = new Controls_Shared_ReportToolbar();            
        }

        protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;
            if ((Request.IsMobileBrowser() && !CurrentSession.ForceDesktop(Request))
                || CurrentSession.ForceMobile(Request))
            {
                Response.RedirectToMobile(Request.Url);
                return;
            }

            UserId = CurrentSession.QUser.Id;
			ReportId = Convert.ToInt32(Context.Request.Params["reportId"]);
			if (ReportId > 0)
			{
				ReportToolbar.IsMyInboxStatus = true;
			}
			SetTaskID();

			ReportToolbar.IsMyInbox = true;
			ReportToolbar.ReportId = ReportId;

			if (Context.Request.Params["lastViewTime"] != null)
				LastViewTime = DateTime.Parse(Context.Request.Params["lastViewTime"]);
			else
				LastViewTime = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow();
		}

        protected override void Render(HtmlTextWriter writer)
        {
			if(Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request))
				base.Render(writer);
        }

        protected void SetTaskID()
		{
			if (Context.Request.QueryString["TaskID"] != null)
			{
				TaskId = Convert.ToInt32(Context.Request.QueryString["TaskId"]);
			}
		}
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

