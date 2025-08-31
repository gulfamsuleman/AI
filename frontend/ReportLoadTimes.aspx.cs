using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess
{

    public partial class ReportLoadTimes : SessionPage
	{
		protected List<ReportLoadTime> LoadTimes { get; set; }
		protected List<LoadTimesUser> Users { get; set; }
		protected List<LoadTimesReport> Reports { get; set; }
		protected DateTime Today { get; set; }
		protected DateTime WeekAgo { get; set; }
		protected string ReportName { get; set; }
		protected int UserId { get; set; }
		protected string SortBy { get; set; }
		protected string SortOrder { get; set; }
        public Repeater Repeater1 { get; set; }
        public Repeater Repeater2 { get; set; }
        public Repeater Repeater3 { get; set; }

        public ReportLoadTimes()
        {
            Repeater1 = new Repeater();
            Repeater2 = new Repeater();
            Repeater3 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            if (!CurrentSession.QUser.IsGradingAdmin)
				Context.Response.Redirect("Calendar.aspx");

			var loadTimeRepo = new LoadTimesRepository();
			WeekAgo = Context.Request.Params["startFilter"] != null
						? DateTime.Parse(Context.Request.Params["startFilter"])
						: QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-7);
			Today = Context.Request.Params["endFilter"] != null
						  ? DateTime.Parse(Context.Request.Params["endFilter"])
						  : QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow();
			ReportName = Context.Request.Params["reportName"] != null && Context.Request.Params["reportName"] != "All"
				? Context.Request.Params["reportName"] : "";
			UserId = Context.Request.Params["userId"] != null ? int.Parse(Context.Request.Params["userId"]) : -1;
			SortBy = Context.Request.Params["sortBy"] ?? "";
			SortOrder = Context.Request.Params["sortOrder"] ?? "";
			LoadTimes = loadTimeRepo.GetReportLoadTimes(WeekAgo, Today, ReportName, UserId, SortBy, SortOrder).ToList();
			Users = loadTimeRepo.GetUsers(WeekAgo, Today);
			Reports = loadTimeRepo.GetReports(WeekAgo, Today);

			Repeater1.DataBind();
			Repeater2.DataBind();
			Repeater3.DataBind();
		}
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

