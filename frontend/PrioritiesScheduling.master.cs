using System;
using System.Linq;
using System.Web;
using System.Web.UI.HtmlControls;

namespace QProcess
{
    public partial class PrioritiesScheduling : QProcessMasterPage
    {
        protected string CurrentPageName { get; set; }

        public HtmlGenericControl SchedulePrioritiesLi { get; set; }
        public HtmlGenericControl PrioritiesScheduleReportLi { get; set; }
        public HtmlGenericControl SupervisorsPriorityScheduleLi { get; set; }
        public HtmlGenericControl ScheduleReportsLi { get; set; }
        public HtmlGenericControl LateReportLi { get; set; }
        public HtmlGenericControl ExcuseLi { get; set; }

        public PrioritiesScheduling()
        {
            SchedulePrioritiesLi = new HtmlGenericControl("li");
            PrioritiesScheduleReportLi = new HtmlGenericControl("li");
            SupervisorsPriorityScheduleLi = new HtmlGenericControl("li");
            ScheduleReportsLi = new HtmlGenericControl("li");
            LateReportLi = new HtmlGenericControl("li");
            ExcuseLi = new HtmlGenericControl("li");
        }

        protected override void Page_Load(object sender, EventArgs e)
        {
            base.Page_Load(sender, e);
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;
            SetCurrentPage();
        }

        private void SetCurrentPage()
        {
            CurrentPageName = Request.Url.LocalPath.Split('/').Last(); // Request.Url.ToString().Split('/').Last();

            switch (CurrentPageName)
            {
                case "SchedulePriorities.aspx":
                    SchedulePrioritiesLi.Attributes["class"] = "active";
                    break;
                case "PrioritiesScheduleReport.aspx":
                    PrioritiesScheduleReportLi.Attributes["class"] = "active";
                    break;
                case "SupervisorsPrioritySchedule.aspx":
                    SupervisorsPriorityScheduleLi.Attributes["class"] = "active";
                    break;
                case "ScheduleReports.aspx":
                    ScheduleReportsLi.Attributes["class"] = "active";
                    break;
                case "LateReport.aspx":
                    LateReportLi.Attributes["class"] = "active";
                    break;
                case "ExcusePriorities.aspx":
                    ExcuseLi.Attributes["class"] = "active";
                    break;

            }
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

