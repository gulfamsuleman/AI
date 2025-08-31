using System;
using System.Collections.Generic;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_Shared_ChecklistPreview : System.Web.UI.UserControl
    {
        public string Name { get; set; }
        public int ChangeId { get; set; }
        public List<ChecklistItem> ChecklistItems { get; set; }
        protected int ChecklistId { get; set; }
        protected void Page_Load(object sender, EventArgs e)
        {
            //if checklist id
            //use to fetch items
            Name = Context.Request.Headers["X-ChecklistName"] ?? "";
            if (Context.Request.Headers["X-ChangeId"] != null)
                ChangeId = int.Parse(Context.Request.Headers["X-ChangeId"]);
            if (Context.Request.Headers["X-ChecklistId"] != null)
            {
                ChecklistId = int.Parse(Context.Request.Headers["X-ChecklistId"]);
                var repo = new ChecklistRepository();
                if (ChangeId <= 0)
                    ChecklistItems = repo.GetChecklistItems(ChecklistId, QProcess.Session.CurrentSession.QUser.Id);
                else
                    ChecklistItems = repo.ApprovalGetChecklistItems(ChecklistId, ChangeId);
            }
            DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

