using QProcess.Extensions;
using System;
using System.Web;

namespace QProcess
{

    public partial class NewTask : SessionPage
	{
		protected void Page_Load(object sender, EventArgs e)
		{
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

