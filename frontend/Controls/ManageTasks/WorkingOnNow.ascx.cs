using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_ManageTasks_WorkingOnNow : System.Web.UI.UserControl
    {
        public int InstanceId { get; set; }
        public int ChangeId { get; set; }

        public Repeater rptActive { get; set; }
        public HtmlGenericControl divInstructions { get; set; }
        public HtmlGenericControl ulTasks { get; set; }

        public Controls_ManageTasks_WorkingOnNow()
        {
            rptActive = new Repeater();
            divInstructions = new HtmlGenericControl("div");
            ulTasks = new HtmlGenericControl("ul");
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Context.Request.Headers["X-InstanceId"] != null)
                InstanceId = int.Parse(Context.Request.Headers["X-InstanceId"]);
            if (Context.Request.Headers["X-ChangeId"] != null)
                ChangeId = int.Parse(Context.Request.Headers["X-ChangeId"]);
            var checklistRepo = new ChecklistRepository();
            List<ActiveDueDate> dueDates;
            if (ChangeId <= 0)
                dueDates = checklistRepo.GetActiveDueDates(InstanceId);
            else
                dueDates = checklistRepo.ApprovalGetActiveDueDates(InstanceId, ChangeId);
            if (dueDates.Any())
            {
                rptActive.DataSource = dueDates;
                rptActive.DataBind();
                ulTasks.Visible = true;
                divInstructions.Visible = false;
            }
            else
            {
                ulTasks.Visible = false;
                divInstructions.Visible = true;
            }
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

