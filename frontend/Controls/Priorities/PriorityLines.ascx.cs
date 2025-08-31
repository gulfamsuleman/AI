using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Web;
using System.Web.UI.WebControls;
using QProcess.Extensions;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_Priorities_PriorityLines : System.Web.UI.UserControl
    {
        public bool IsSingleUserList { get; set; }
        public bool UserHasComments { get; set; }
        public List<PriorityLine> PriorityLines { get; set; }
        public Repeater Repeater1 { get; set; }
        public bool IsMobile => 
            HttpContext.Current.Request.IsMobileBrowser() 
            || QProcess.Session.CurrentSession.ForceMobile(HttpContext.Current.Request);

        public Controls_Priorities_PriorityLines()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            Repeater1.DataSource = PriorityLines;
            Repeater1.DataBind();
        }

        protected string priorityString(int priority)
        {
            if (priority > 0)
            {
                return priority.ToString();
            }
            else
            {
                return "&nbsp;";
            }
        }

        protected string completedStyle(int priority)
        {
            if (priority > 0)
            {
                return "";
            }
            else
            {
                return "style=\"font-style: italic;color: #999;\"";
            }
        }

        protected string completedPrefix(int priority)
        {
            if (priority > 0)
            {
                return "";
            }
            else
            {
                return "Completed: ";
            }
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

