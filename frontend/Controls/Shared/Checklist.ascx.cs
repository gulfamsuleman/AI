using System;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using QProcess.Extensions;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Shared_Checklist : System.Web.UI.UserControl
	{
		public Checklist Checklist { get; set; }
		public bool IsMyTasks { get; set; }
		protected bool IsCompletable { get; set; }
		protected int UniqueId { get; set; }
		protected TaskStage TaskStage { get; set; }
		protected bool IsDaily { get; set; }
		public string CompletionCssClass
		{
			get
			{
				if (Checklist.TaskStage == TaskStage.Future)
					return "future";
				if (Checklist.IsCompleted)
					return "completed";
				if (Checklist.DueDate < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow())
					return "overdue";
				return "normal";
			}
		}

		public string CompletionString
		{
			get
			{
				if (Checklist.TaskStage == TaskStage.Future)
					return "Due";
				if (Checklist.IsCompleted)
					return "Completed";
				if (Checklist.DueDate < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow())
					return "Overdue";
				return "Due";
			}
		}

		public DateTime DisplayDate
		{
			get
			{
				return Checklist.IsCompleted ? Checklist.CompletedOn.Value : Checklist.DueDate;
			}
		}

		public Repeater Repeater1 { get; set; }

		public Controls_Shared_Checklist()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			//Headers - used by JQueryHandler and other dynamic-loading features.
			if (Context.Request.Headers["X-UniqueId"] != null && Context.Request.Headers["X-TaskStage"] != null)
			{
				//Any call to JQueryHandler (which uses these X headers)
				//*should* be coming from an authed request for an ASPX				

				UniqueId = Convert.ToInt32(Context.Request.Headers["X-UniqueId"]);
				TaskStage = (Convert.ToString(Context.Request.Headers["X-TaskStage"])).FromString<TaskStage>();
				var checklistRepo = new ChecklistRepository();
				Checklist = checklistRepo.GetSingleChecklist(QProcess.Session.CurrentSession.QUser.Id, TaskStage, UniqueId);
				IsMyTasks = true;
			}
			//Query Strings - used in "permalinks" i.e. assignment emails.
			else if (Context.Request.QueryString.AllKeys.Contains("taskId")	&& Context.Request.QueryString.AllKeys.Contains("taskStage"))
			{
                //When coming here from a permalink, we may not be authed and we need to be.
                if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

                UniqueId = Convert.ToInt32(Context.Request.QueryString["taskId"]);
                TaskStage = (Convert.ToString(Context.Request.QueryString["taskStage"])).FromString<TaskStage>();
                var checklistRepo = new ChecklistRepository();
                Checklist = checklistRepo.GetSingleChecklist(QProcess.Session.CurrentSession.QUser.Id, TaskStage, UniqueId);
                IsMyTasks = false;
            }

            else if (Context.Request.QueryString.AllKeys.Contains("id") && Context.Request.QueryString.AllKeys.Contains("type"))
            {
                //When coming here from a permalink, we may not be authed and we need to be.
                if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

                UniqueId = Convert.ToInt32(Context.Request.QueryString["id"]);
                TaskStage = (Convert.ToString(Context.Request.QueryString["type"])).FromString<TaskStage>();
                var checklistRepo = new ChecklistRepository();
                Checklist = checklistRepo.GetSingleChecklist(QProcess.Session.CurrentSession.QUser.Id, TaskStage, UniqueId);
                IsMyTasks = false;
            }

            IsDaily = Checklist.IsDaily;

			//It's *possible* to create checklists with no items; if it happens, just let them complete the task
			if (Checklist?.Items == null || !Checklist.Items.Any(i => i.ItemTypeString == "Checkbox"))
				IsCompletable = true;
			else
			{
				IsCompletable = Checklist.Items.Where(i => i.ItemTypeString == "Checkbox").All(i => i.IsItemComplete);
				if (!IsCompletable && Checklist.Items.Where(i => i.ItemTypeString == "Checkbox").Count() <= 1)
					IsCompletable = true;
			}

			Repeater1.DataSource = Checklist?.Items ?? new ChecklistItem[0];
			Repeater1.DataBind();
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

