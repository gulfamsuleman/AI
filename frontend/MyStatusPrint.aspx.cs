using System;
using System.Web;
using QProcess.Repositories;

namespace QProcess
{

    public partial class MyStatusPrint : SessionPage, IProvideReportIdForLogging
    {
        public int ReportId { get; set; }
        protected int UserId { get; set; }
        protected bool IsArchive { get; set; }
        protected string TasksIControl { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            IsArchive = Context.Request.Params["archive"] != null && Convert.ToInt32(Context.Request.Params["archive"]) == 1;
            UserId = CurrentSession.QUser.Id;
            SetReportId();
        }

        protected void SetReportId()
        {
            //if specified in query and have permissions use
            //else use preference if set
            //else use default
            var statusRepo = new StatusReportRepository();
            var userRepo = new UserRepository();
            if (Context.Request.QueryString["ReportID"] != null)
            {
                var tempId = Convert.ToInt32(Context.Request.QueryString["ReportID"]);
                if (statusRepo.CheckIsUser(UserId, tempId))
                    ReportId = tempId;
            }
            else
            {
                //if preference, use
                //else use default
                var lastReportPreferenceString = userRepo.GetPreference(UserId, "LastReport");
                int lastReport;
                ReportId = Int32.TryParse(lastReportPreferenceString, out lastReport) ? lastReport : statusRepo.GetDefaultReport(UserId);
            }
            userRepo.AddPreference(UserId, "LastReport", ReportId.ToString());
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

