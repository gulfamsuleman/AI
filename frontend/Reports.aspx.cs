using System;
using System.Web;

namespace QProcess
{

    public partial class Reports : SessionPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

