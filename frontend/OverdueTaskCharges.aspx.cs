using System;

namespace QProcess
{

    public partial class OverdueTaskCharges : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            var username = QProcess.Session.CurrentSession.QUser.Username;
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

