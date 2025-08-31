using QProcess.Extensions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess
{
    public partial class TimezoneConversion : SessionPage, IProvideReportIdForLogging
    {
        public int ReportId { get; set; }
        public SiteMaster MasterPage => Master as SiteMaster;
        public int UserId { get; set; }
        public string UserName { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            ReportId = 1;

            if ((Request.IsMobileBrowser() && !CurrentSession.ForceDesktop(Request)) || CurrentSession.ForceMobile(Request))
            {
                Response.RedirectToMobile(Request.Url);
            }

            var user = MasterPage.QUser;

            UserId = MasterPage.QUser.Id;
            UserName = MasterPage.QUser.FullName;
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

