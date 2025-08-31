using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_MyStatus_MoveTask : System.Web.UI.UserControl
    {
        public List<Section> MySections { get; set; }

        public Repeater Repeater1 { get; set; }

        public Controls_MyStatus_MoveTask()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            var repo = new StatusReportRepository();
            MySections = repo.GetMySections(QProcess.Session.CurrentSession.QUser.Id);
            Repeater1.DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

