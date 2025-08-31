using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_TaskSummary_StatusTasks : System.Web.UI.UserControl
    {
        protected IEnumerable<TaskStatusLine> ReportLines { get; set; }
        public Repeater Repeater1 { get; set; }

        public Controls_TaskSummary_StatusTasks()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            var taskSummaryRepo = new TaskSummaryRepository();
            ReportLines = taskSummaryRepo.GetStatusTasks(QProcess.Session.CurrentSession.QUser.Id);
            Repeater1.DataSource = ReportLines;
            Repeater1.DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

