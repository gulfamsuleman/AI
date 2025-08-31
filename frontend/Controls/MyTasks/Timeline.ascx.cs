using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_MyTasks_Timeline : System.Web.UI.UserControl
	{
		protected IEnumerable<Report> Reports { get; set; }
		protected int UserId { get; set; }
		protected int Controller { get; set; }
		protected int SelectedReportId { get; set; }
		public Repeater Repeater1 { get; set; }

		public Controls_MyTasks_Timeline()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var repo = new StatusReportRepository();
			UserId = QProcess.Session.CurrentSession.QUser.Id;
			Controller = Convert.ToInt32(Context.Request.Headers["X-Controller"]);
			SelectedReportId = Convert.ToInt32(Context.Request.Headers["X-ReportId"]);
			if (Controller == 1)
			{
				Reports = repo.GetMyReportsList(UserId, true, true);
				Repeater1.DataSource = Reports;
				Repeater1.DataBind();
			}
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

