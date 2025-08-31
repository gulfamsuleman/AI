using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Mobile
{
    public partial class MobileNewTask : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;
        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request))
                base.Render(writer);
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

