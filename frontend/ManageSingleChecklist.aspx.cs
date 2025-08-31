using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using QProcess.Repositories;
using QProcess.Extensions;
using System.Web.UI.WebControls;
using QProcess.Controls;

namespace QProcess
{

    public partial class ManageSingleChecklist : SessionPage
	{
		protected Dictionary<double, string> TimeOptions = new Dictionary<double, string>();
		protected int ChangeId;
		protected TaskStage TaskStage { get; set; }
		protected int TaskId { get; set; }
		protected DateTime DueDate { get; set; }
		protected DateTime ReminderDate { get; set; }
		protected bool Controller { get; set; }
		protected bool HeaderOnly { get; set; }
		protected bool HideChangeDeadline { get; set; }
		protected bool IsDaily { get; set; }
		protected bool PendingChange { get; set; }
		protected bool AddPriority { get; set; }

        public Repeater Repeater1 { get; set; }
        public Repeater Repeater2 { get; set; }
        public Repeater Repeater3 { get; set; }
        public Controls_Shared_Checklist Checklist1 { get; set; }

        public ManageSingleChecklist()
        {
            Repeater1 = new Repeater();
            Repeater2 = new Repeater();
            Repeater3 = new Repeater();
			Checklist1 = new Controls_Shared_Checklist();
        }

        protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            var repo = new ChecklistRepository();
			var userId = QProcess.Session.CurrentSession.QUser.Id;
			var groupId = QProcess.Session.CurrentSession.QUser.GroupId;

			TaskStage = TaskStage.Current;

            TaskId = Context.Request.QueryString["id"] != null ? 
				int.Parse(Context.Request.QueryString["id"]) : 
				int.Parse(Context.Request.Params["taskId"]);

			AddPriority = Context.Request.Params.AllKeys.Contains("addPriority")
				&& int.Parse(Context.Request.Params["addPriority"]) == 1;
			var newDateTime = new DateTime(1900, 1, 1, 0, 0, 0);
			for (var i = 0.0; i < 24; i += .5)
			{
				var tempTime = newDateTime.AddHours(i);
				TimeOptions.Add(i, tempTime.ToString("t"));
			}
			Page.Header.DataBind();
			Repeater1.DataBind();
			Repeater2.DataBind();
			Repeater3.DataBind();

			HeaderOnly = (Request["headerOnly"] == "1") ? true : false;
			HideChangeDeadline = (Request["hideChangeDeadline"] == "0") ? false : true;

			if (Request["changeId"].ToBlank() == "-1")
			{
				Checklist1.Checklist = repo.GetSingleChecklist(userId, TaskStage, TaskId);
			}
			else
			{
				int changeId = 0;
				if (Context.Request.QueryString["ChangeID"] != null) changeId = int.Parse(Context.Request.QueryString["ChangeID"]); 
				if (Context.Request.Params["changeId"] != null) changeId = int.Parse(Context.Request.Params["changeId"]);

                Checklist1.Checklist = changeId > 0 ?
					repo.GetSingleChecklistForApproval(userId, TaskStage, TaskId, ChangeId) :
					repo.GetSingleChecklist(userId, TaskStage, TaskId);
			}

			Controller = repo.UserManagesChecklist(groupId, Checklist1.Checklist.ChecklistId);
			IsDaily = Checklist1.Checklist.IsDaily;
			PendingChange = Checklist1.Checklist.PendingChange;

			if (Checklist1.Checklist.IsVisible)
			{
				DueDate = Checklist1.Checklist.DueDate;
				ReminderDate = Checklist1.Checklist.ReminderDate;
			}
			else
			{
				ReminderDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date;
			}
		}
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

