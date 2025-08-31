using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{	
	public partial class Controls_MyStatus_ManageReports : System.Web.UI.UserControl
	{
		protected List<Report> Reports { get; set; }
		public Repeater Repeater1 { get; set; }

		public Controls_MyStatus_ManageReports()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var statusReportRepo = new StatusReportRepository();
			Reports = statusReportRepo.GetMyReportsList(QProcess.Session.CurrentSession.QUser.Id, false);

			Repeater1.DataSource = Reports;
			Repeater1.DataBind();
		}
	}
	
}
/* Copyright © 2024 Renegade Swish, LLC */

