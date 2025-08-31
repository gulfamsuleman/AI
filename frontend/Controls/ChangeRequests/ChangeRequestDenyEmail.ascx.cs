using System;
using System.Web.UI;

namespace QProcess.Controls
{
    public partial class Controls_ChangeRequests_ChangeRequestDenyEmail : UserControl
    {
        protected string Email { get; set; }
        protected string ChangeRequestID { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Context.Request.Headers["X-Email"] != null)
            {
                Email = Context.Request.Headers["X-Email"].ToString();
            }

            if (Context.Request.Headers["X-ChangeRequestID"] != null)
            {
                ChangeRequestID = Context.Request.Headers["X-ChangeRequestID"].ToString();
            }
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

