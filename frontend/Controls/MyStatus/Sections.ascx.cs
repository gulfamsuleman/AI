using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_MyStatus_Sections : System.Web.UI.UserControl
	{
		protected List<Section> Sections { get; set; }
		protected List<Section> DeletedSections { get; set; }
		protected int ReportId { get; set; }
		public Repeater Repeater1 { get; set; }
		public Repeater Repeater2 { get; set; }

		public Controls_MyStatus_Sections()
		{
			Repeater1 = new Repeater();
			Repeater2 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var statusReportRepo = new StatusReportRepository();
			ReportId = Convert.ToInt32(Context.Request.Headers["X-ReportId"]);
			Sections = statusReportRepo.GetSectionsList(ReportId, false).ToList();
			DeletedSections = statusReportRepo.GetSectionsList(ReportId, true).ToList();

			Repeater1.DataSource = Sections;
			Repeater1.DataBind();
			Repeater2.DataSource = DeletedSections;
			Repeater2.DataBind();
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

