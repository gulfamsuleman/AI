using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess
{
    public partial class AuthTokenEmailRequest : System.Web.UI.Page
    {
        public SiteMaster MasterPage => Master as SiteMaster;

        protected void Page_Load(object sender, EventArgs e)
        {
            var user = MasterPage.QUser;

            //if (!user.IsApiAdmin)
            //{
            //    Response.Redirect("~/MyTasks.aspx");
            //}
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

