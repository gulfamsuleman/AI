using System;
using System.Collections.Generic;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_NewTask_ComplexTask : System.Web.UI.UserControl
    {
        public int ChecklistId { get; set; }
        public int InstanceId { get; set; }
        public int UserId { get; set; }
        public string ChecklistName { get; set; }
        public List<ChecklistItem> MyChecklistItems { get; set; }
        public List<ChecklistInstance> MyInstances { get; set; }
        public int AssignmentNumber { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            var repo = new ChecklistRepository();
            UserId = QProcess.Session.CurrentSession.QUser.Id;
            if (Request.Headers["X-ChecklistId"] != null)
            {
                ChecklistId = int.Parse(Request.Headers["X-ChecklistId"]);
                MyChecklistItems = repo.GetChecklistItems(ChecklistId, UserId);
                ChecklistName = repo.GetChecklistName(ChecklistId, UserId);
            }
            if (Request.Headers["X-InstanceId"] != null)
            {
                InstanceId = int.Parse(Request.Headers["X-InstanceId"]);
            }
            DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

