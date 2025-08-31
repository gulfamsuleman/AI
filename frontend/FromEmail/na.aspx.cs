using System;

namespace QProcess
{

    public partial class FromEmail_na : System.Web.UI.Page
    {
        protected int ac = 0;
        protected int UserID = 0;
        protected int mobile = 0;

        protected void Page_Load(object sender, EventArgs e)
        {
            ac = Convert.ToInt32(Request["ac"]);
            UserID = Convert.ToInt32(Request["UserID"]);
            mobile = Convert.ToInt32(Request["mobile"]);
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

