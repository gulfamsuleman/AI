using System;

namespace QProcess
{

    public partial class MyGroups : SessionPage
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            if(CurrentSession.QUser.IsAdmin)
                Response.Redirect("users.aspx");
            else
                Response.Redirect("groups.aspx");
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

