using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Enums;
using QProcess.Extensions;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Reports_ThreeDayOverdue : System.Web.UI.UserControl
	{
		protected List<ThreeDayChecklistStatusSummary> ChecklistSummaries { get; set; }
		protected List<ThreeDayChecklistStatusDetail> ChecklistDetails { get; set; }
		protected ThreeDayDropdown Selection { get; set; }
		public Repeater Repeater1 { get; set; }
		public Repeater Repeater2 { get; set; }
		public Repeater Repeater3 { get; set; }

		public Controls_Reports_ThreeDayOverdue()
		{
			Repeater1 = new Repeater();
			Repeater2 = new Repeater();
			Repeater3 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var reportsRepo = new ReportsRepository();
			Selection = ThreeDayDropdown.ControllerNow;
			if (Context.Request.Headers["X-Selection"] != null)
				Selection = Convert.ToString(Context.Request.Headers["X-Selection"]).FromString<ThreeDayDropdown>();
			ChecklistSummaries = reportsRepo.GetThreeDayChecklistSummary(Selection).ToList();
			ChecklistDetails = reportsRepo.GetThreeDayChecklistDetail(Selection).ToList();

			Repeater1.DataSource = CreateDropdownList();
			Repeater1.DataBind();
			Repeater2.DataSource = ChecklistSummaries;
			Repeater2.DataBind();
			Repeater3.DataSource = ChecklistDetails;
			Repeater3.DataBind();
		}

		protected List<DropdownOption> CreateDropdownList()
		{
			return new List<DropdownOption>
		{
			new DropdownOption {Option = ThreeDayDropdown.ControllerNow, Description = "By Controller - 3 Days Overdue Now"},
			new DropdownOption {Option = ThreeDayDropdown.Controller2Week, Description = "By Controller - 3 Days Overdue in Last 2 Weeks"},
			new DropdownOption {Option = ThreeDayDropdown.AssigneeNow, Description = "By Assignee - 3 Days Overdue Now"},
			new DropdownOption {Option = ThreeDayDropdown.Assignee2Week, Description = "By Assignee - 3 Days Overdue in Last 2 Weeks"}
		};
		}

		protected class DropdownOption
		{
			public ThreeDayDropdown Option { get; set; }
			public string Description { get; set; }
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

