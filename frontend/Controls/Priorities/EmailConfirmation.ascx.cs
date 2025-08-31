using System;

namespace QProcess.Controls
{
    public partial class Controls_Priorities_EmailConfirmation : System.Web.UI.UserControl
    {
        protected string Message { get; set; }
        protected void Page_Load(object sender, EventArgs e)
        {
            Message = Context.Request.Headers["X-message"];
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

