using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_Priorities_PriorityList : System.Web.UI.UserControl
    {
        public List<PriorityList> PriorityLists { get; set; }
        public bool IsEmailing { get; set; }
        public bool Condensed { get; set; }
        public PriorityInfo Info { get; set; }
        public Repeater Repeater1 { get; set; }
        public bool IsMobile { get; set; }


        public Controls_Priorities_PriorityList()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            Repeater1.DataSource = PriorityLists;
            Repeater1.DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

