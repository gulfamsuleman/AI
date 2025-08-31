using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_MyInbox_ConfidentialReports : System.Web.UI.UserControl
	{
		IEnumerable<NamedEntity> ConfidentialReports { get; set; }
		List<NamedEntity> Reports { get; set; }
		public Repeater Repeater1 { get; set; }
		public Repeater Repeater2 { get; set; }

		public Controls_MyInbox_ConfidentialReports()
		{
			Repeater1 = new Repeater();
			Repeater2 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var selectListRepo = new SelectListRepository();
			Reports = selectListRepo.GetReports().ToList();
			Reports.Insert(0, new NamedEntity { Id = -1, Name = "" });
			ConfidentialReports = selectListRepo.GetConfidentialReports();

			Repeater1.DataSource = Reports;
			Repeater1.DataBind();
			Repeater2.DataSource = ConfidentialReports;
			Repeater2.DataBind();
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

