using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_MyStatus_BulkUpdate : System.Web.UI.UserControl
	{
		protected List<BulkUpdateTask> Tasks { get; set; }
		protected int ReportId { get; set; }
		public Repeater Repeater1 { get; set; }

		public Controls_MyStatus_BulkUpdate()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var statusReportRepo = new StatusReportRepository();
			if (Context.Request.Headers["X-ReportId"] != null)
			{
				ReportId = Convert.ToInt32(Context.Request.Headers["X-ReportId"]);
				Tasks = statusReportRepo.GetBulkUpdateTaskList(ReportId).ToList();

				Repeater1.DataSource = Tasks;
				Repeater1.DataBind();
			}

		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

