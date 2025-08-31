using System;
using System.Web;

namespace QProcess
{

    public partial class BlankMaster : QProcessMasterPage
    {
        protected override void Page_Load(object sender, EventArgs e)
        {
            base.Page_Load(sender, e);
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

