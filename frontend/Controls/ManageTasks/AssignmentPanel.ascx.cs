using System;

namespace QProcess.Controls
{
    public partial class Controls_ManageTasks_AssignmentPanel : System.Web.UI.UserControl
    {
        public int InstanceId { get; set; }
        public int UserId { get; set; }
        public int ChangeId { get; set; }
        public int AssignmentNumber { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Context.Request.Headers["X-InstanceId"] != null)
                InstanceId = int.Parse(Context.Request.Headers["X-InstanceId"]);
            if (Context.Request.Headers["X-UserId"] != null)
                UserId = int.Parse(Context.Request.Headers["X-UserId"]);
            if (Context.Request.Headers["X-ChangeId"] != null)
                ChangeId = int.Parse(Context.Request.Headers["X-ChangeId"]);
            if (Context.Request.QueryString["ControlName"] == "Controls/ManageTasks/AssignmentPanel.ascx")
                DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

