using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_Priorities_PriorityLine : System.Web.UI.UserControl
    {
        public bool IsSingleUserList { get; set; }
        public bool UserHasComments { get; set; }
        public bool Condensed { get; set; }
        public List<PriorityLine> PriorityLines { get; set; }
        public Repeater Repeater1 { get; set; }

        public Controls_Priorities_PriorityLine()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            Repeater1.DataSource = PriorityLines;
            Repeater1.DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

