using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Controls.Shared
{
    public partial class QGraphs : System.Web.UI.UserControl
    {
        public int GraphNumber { get; set; } = 6;

        public string GraphType { get; set; } = "bar";

        public string GraphTitle { get; set; } = "This is a test!";

        protected void Page_Load(object sender, EventArgs e)
        {
        }
    }
}