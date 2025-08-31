using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Reports_TasksByPerson : System.Web.UI.UserControl
	{
		protected List<NamedEntity> Users { get; set; }
		protected List<UserTask> UserTasks { get; set; }
		protected int? SelectedUserId { get; set; }
		protected string Search { get; set; }
		public Repeater Repeater1 { get; set; }
		public Repeater Repeater2 { get; set; }

		public Controls_Reports_TasksByPerson()
		{
			Repeater1 = new Repeater();
			Repeater2 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var selectListRepo = new SelectListRepository();
			var reportsRepo = new ReportsRepository();
			SelectedUserId = QProcess.Session.CurrentSession.QUser.Id;
			Search = "";
			if (Context.Request.Headers["X-SelectedUserId"] != null)
			{
				if (Convert.ToInt32(Context.Request.Headers["X-SelectedUserId"]) == -1)
					SelectedUserId = null;
				else
					SelectedUserId = Convert.ToInt32(Context.Request.Headers["X-SelectedUserId"]);
			}
			if (Context.Request.Headers["X-Search"] != null)
				Search = Convert.ToString(Context.Request.Headers["X-Search"]);
			Users = selectListRepo.GetReportsUserList().ToList();
			Users.Insert(0, new NamedEntity { Id = -1, Name = "" });

			UserTasks = reportsRepo.GetUserTasksReport(SelectedUserId, Search).ToList();

			Repeater1.DataSource = Users;
			Repeater1.DataBind();
			Repeater2.DataSource = UserTasks;
			Repeater2.DataBind();
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

