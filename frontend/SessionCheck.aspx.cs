using System;
using System.Web;

namespace QProcess
{
    public partial class SessionCheck : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request);
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

