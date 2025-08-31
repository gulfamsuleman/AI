using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_MyInbox_DueDateChanges : System.Web.UI.UserControl
	{
		protected List<DueDateChange> DueDateChanges { get; set; }
		protected int ReportId { get; set; }
		public Repeater Repeater1 { get; set; }

		public Controls_MyInbox_DueDateChanges()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var myInboxRepo = new MyInboxRepository();
			if (Context.Request.Headers["X-ReportId"] != null)
				ReportId = Convert.ToInt32(Context.Request.Headers["X-ReportId"]);
			DueDateChanges = myInboxRepo.GetDueDateChanges(ReportId).ToList();

			if (DueDateChanges.Any())
			{
				Repeater1.DataSource = DueDateChanges;
				Repeater1.DataBind();
			}
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

