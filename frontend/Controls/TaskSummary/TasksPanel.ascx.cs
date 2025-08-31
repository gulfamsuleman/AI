using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_TaskSummary_TasksPanel : System.Web.UI.UserControl
	{
        protected Session CurrentSession => QProcess.Session.CurrentSession;
        protected List<Repositories.TaskSummary> Tasks { get; set; }
		public Repeater Repeater1 { get; set; }

		public Controls_TaskSummary_TasksPanel()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var taskSummaryRepo = new TaskSummaryRepository();
			switch (Context.Request.Params["type"])
			{
				case "summary":
					Tasks = taskSummaryRepo.GetSummaryTasks(CurrentSession.QUser.Id).ToList();
					break;
				case "managed":
					Tasks = taskSummaryRepo.GetManagedTasks(CurrentSession.QUser.Id).ToList();
					break;
			}
			Repeater1.DataSource = Tasks;
			Repeater1.DataBind();
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

