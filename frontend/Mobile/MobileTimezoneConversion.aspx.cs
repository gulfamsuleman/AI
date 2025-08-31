using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Mobile
{
    public partial class MobileTimezoneConversion : SessionPage, IProvideReportIdForLogging
    {
        public int ReportId { get; set; }
        public int UserId { get; set; }
        public string UserName { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            {
                if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;
            }

            UserName = CurrentSession.QUser.Username;
            UserId = CurrentSession.QUser.Id;



        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

