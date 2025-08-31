using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Controls.Shared
{
    public partial class GroupReassignment : System.Web.UI.UserControl
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