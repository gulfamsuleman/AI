using System;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Shared_ChecklistExport : System.Web.UI.UserControl
	{
		public Checklist Checklist { get; set; }
		protected void Page_Load(object sender, EventArgs e)
		{

		}
		public string CompletionString
		{
			get
			{
				if (Checklist.IsCompleted)
					return "Completed";
				if (Checklist.DueDate < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow())
					return "Overdue";
				return "";
			}
		}

		public string StatusCssClass
		{
			get
			{
				if (Checklist.IsCompleted) return "SubHeadCompleted";
				if (Checklist.DueDate < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow()) return "SubHeadOverdue";
				if (Checklist.TaskStage == TaskStage.Future) return "SubHeadFuture";
				return "SubHeadOpen";
			}
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

