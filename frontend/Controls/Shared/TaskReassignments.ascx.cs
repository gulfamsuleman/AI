
using System;

namespace QProcess.Controls.Shared
{
    public partial class TaskReassignments : System.Web.UI.UserControl
    {
        public int SupervisorID { get; set; }
        public int UserId { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            SupervisorID = int.Parse(Context.Request.Headers["X-SupervisorId"]);
            UserId = int.Parse(Context.Request.Headers["X-UserId"]);
        }
    }
}