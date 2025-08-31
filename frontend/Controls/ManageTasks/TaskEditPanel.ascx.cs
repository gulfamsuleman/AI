using System;
using System.Collections.Generic;
using System.Web.UI;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_ManageTasks_TaskEditPanel : UserControl
    {
        public int TaskId { get; set; }
        public int UserId { get; set; }
        public int GroupId { get; set; }
        public int ChangeId { get; set; }
        public string ChecklistName { get; set; }
        public List<ChecklistItem> MyChecklistItems { get; set; }
        public List<ChecklistInstance> MyInstances { get; set; }
        public int AssignmentNumber { get; set; }
        //public Checklist MyChecklist { get; set; }

        public Controls_Shared_ChecklistItemsPanel ChecklistItemsPanel { get; set; }
        public Controls_ManageTasks_AssignmentPanel AssignmentPanel { get; set; }
        public Repeater AssignmentRepeater { get; set; }
        public Panel pnlSendRequest { get; set; }
        public Panel pnlApproval { get; set; }

        public Controls_ManageTasks_TaskEditPanel()
        {
            ChecklistItemsPanel = new Controls_Shared_ChecklistItemsPanel();
            AssignmentPanel = new Controls_ManageTasks_AssignmentPanel();

            AssignmentRepeater = new Repeater();
            pnlSendRequest = new Panel();
            pnlApproval = new Panel();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            var repo = new ChecklistRepository();
            AssignmentNumber = 0;
            if (Request.Headers["X-ChangeId"] != null)
            {
                ChangeId = int.Parse(Request.Headers["X-ChangeId"]);
            }
            UserId = QProcess.Session.CurrentSession.QUser.Id;
            GroupId = QProcess.Session.CurrentSession.QUser.GroupId;
            if (Request.Headers["X-TaskId"] != null)
            {
                TaskId = int.Parse(Request.Headers["X-TaskId"]);
                MyChecklistItems = repo.GetChecklistItems(TaskId, UserId);
                if (ChangeId <= 0)
                    ChecklistName = repo.GetChecklistName(TaskId, UserId);
                else
                    ChecklistName = repo.ApprovalGetChecklistName(ChangeId, UserId);

                if (repo.UserManagesChecklist(GroupId, TaskId))
                {
                    pnlSendRequest.Visible = false;
                    if (ChangeId > 0)
                    {
                        pnlApproval.Visible = true;
                    }
                }
                else
                {
                    if (ChangeId <= 0)
                    {
                        ChangeId = repo.GetNewChangeRequest(UserId);
                        repo.CopyChecklistItemsToChange(ChangeId, TaskId);
                        repo.CopySchedulesToChange(ChangeId, TaskId);
                    }
                }

                if (ChangeId <= 0)
                    MyInstances = repo.GetChecklistInstances(TaskId);
                else
                    MyInstances = repo.ApprovalGetChecklistInstances(TaskId, ChangeId);
            }
            AssignmentRepeater.DataSource = MyInstances;
            DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

