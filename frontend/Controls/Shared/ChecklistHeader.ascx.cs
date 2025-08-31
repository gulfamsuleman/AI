using System;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Shared_ChecklistHeader : System.Web.UI.UserControl
	{
		public Checklist Checklist { get; set; }
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
		protected void Page_Load(object sender, EventArgs e)
		{

		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

