using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_TaskSummary_SetStatus : System.Web.UI.UserControl
	{
		protected int InstanceId { get; set; }
		protected List<NamedEntity> DropDownReports { get; set; }
		protected List<InstanceReportAssignment> DataGridReports { get; set; }
		public Repeater Repeater1 { get; set; }
		public Repeater Repeater2 { get; set; }

		public Controls_TaskSummary_SetStatus()
		{
			Repeater1 = new Repeater();
			Repeater2 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			InstanceId = Convert.ToInt32(Context.Request.Headers["X-InstanceId"]);
			var selectListRepo = new SelectListRepository();
			DropDownReports = selectListRepo.GetReportsForInstance(QProcess.Session.CurrentSession.QUser.Id, InstanceId).SelectMany(r => r.Entities).ToList();
			DropDownReports.Insert(0, new NamedEntity { Id = -1, Name = "" });
			var checklistRepo = new ChecklistRepository();
			DataGridReports = checklistRepo.GetInstanceReports(InstanceId);

			Repeater1.DataSource = DropDownReports;
			Repeater1.DataBind();
			if (DataGridReports.Any())
			{
				Repeater2.DataSource = DataGridReports;
				Repeater2.DataBind();
			}
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

