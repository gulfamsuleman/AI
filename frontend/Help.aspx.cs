using System;
using QProcess.Configuration;
using System.Web;
using QProcess.Extensions;

namespace QProcess
{

    public partial class Help : SessionPage
    {
        public string GradingEmail => AppSettings.Get("GradingAddress");
        public string TaskEmail => AppSettings.Get("QPTAddress");

        protected void Page_Load(object sender, EventArgs e)
        {
            //var zero = 0;
            //var divByZero = 1 / zero;

            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            if ((Request.IsMobileBrowser() && !CurrentSession.ForceDesktop(Request))
                || CurrentSession.ForceMobile(Request))
            {
                Response.RedirectToMobile(Request.Url);
                return;
            }
        }                 
    }

}
    
/* Copyright © 2024 Renegade Swish, LLC */

