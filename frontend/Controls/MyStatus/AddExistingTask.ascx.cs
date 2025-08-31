using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_MyStatus_AddExistingTask : System.Web.UI.UserControl
    {
        public List<ExistingTasksHeader> ExistingTasks { get; set; }
        public List<ExistingTasksAssignee> Assignees { get; set; }
        public int SelectedSectionId { get; set; }
        protected string Sort { get; set; }
        protected int ReportId { get; set; }
        public Repeater ExistingTasksRepeater { get; set; }
        public Repeater AssigneesRepeater { get; set; }

        public Controls_MyStatus_AddExistingTask()
        {
            ExistingTasksRepeater = new Repeater();
            AssigneesRepeater = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            var repo = new StatusReportRepository();
            var userId = QProcess.Session.CurrentSession.QUser.Id;
            SelectedSectionId = int.Parse(Context.Request.Headers["X-Section"]);
            Sort = Convert.ToString(Context.Request.Headers["X-Sort"]);
            ReportId = Convert.ToInt32(Context.Request.Headers["X-ReportId"]);
            ExistingTasks = repo.GetExistingTasksToAdd(userId, ReportId, Sort).ToList();
            if (ExistingTasks.Any())
            {
                ExistingTasksRepeater.DataSource = ExistingTasks;
                ExistingTasksRepeater.DataBind();
            }
            Assignees = repo.GetExistingTasksToAddAssignees(userId).ToList();
            if (Assignees.Any())
            {
                AssigneesRepeater.DataSource = Assignees;
                AssigneesRepeater.DataBind();
            }
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

