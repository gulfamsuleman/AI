using System;
using System.Collections.Generic;
using QProcess.Repositories;
using QProcess.Models;
using System.Web.UI.WebControls;

namespace QProcess.Controls
{
    public partial class Controls_Shared_CommentList : System.Web.UI.UserControl
    {
        public DateTime LastViewed { get; set; }
        public List<StatusReportLine.Comment> Comments { get; set; }
        public IUser QUser { get { return QProcess.Session.CurrentSession.QUser; } }

        public Repeater Repeater1 { get; set; }

        public Controls_Shared_CommentList()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            Repeater1.DataSource = Comments;
            Repeater1.DataBind();
        }

        public string Str2Html(string s)
        {
            return s.Replace("\n", "<br/>");
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

