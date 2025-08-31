using System;
using System.Linq;
using System.Web;
using System.Web.UI.HtmlControls;

namespace QProcess
{
    public partial class OverdueTasksChargeMonitor : QProcessMasterPage
    {
        protected string CurrentPageName { get; set; }
        protected new string Firm => base.Firm ?? String.Empty;

        public HtmlGenericControl OverdueTasksReportLi { get; set; }
        public HtmlGenericControl OverdueTaskChargesLi { get; set; }
        public HtmlGenericControl ExcuseOverdueTasksLi { get; set; }

        public OverdueTasksChargeMonitor()
        {
            OverdueTasksReportLi = new HtmlGenericControl("li");
            OverdueTaskChargesLi = new HtmlGenericControl("li");
            ExcuseOverdueTasksLi = new HtmlGenericControl("li");
        }
        protected override void Page_Load(object sender, EventArgs e)
        {
            base.Page_Load(sender, e);
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;
            SetCurrentPage();
        }

        private void SetCurrentPage()
        {
            CurrentPageName = Request.Url.LocalPath.Split('/').Last();

            switch (CurrentPageName)
            {
                case "OverdueTaskReport.aspx":
                    OverdueTasksReportLi.Attributes["class"] = "active";
                    break;
                case "OverdueTaskCharges.aspx":
                    OverdueTaskChargesLi.Attributes["class"] = "active";
                    break;
                case "ExcuseOverdueTasks.aspx":
                    ExcuseOverdueTasksLi.Attributes["class"] = "active";
                    break;

            }
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

