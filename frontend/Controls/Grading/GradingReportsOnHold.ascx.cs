using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Grading_GradingReportsOnHold : System.Web.UI.UserControl
	{
		public IEnumerable<ReportOnHold> ReportsOnHold { get; set; }
		protected List<NamedEntity> GradingReports { get; set; }
		protected int UserId { get; set; }
		public bool IsAdmin { get; set; }
		public bool IsAdminDetails { get; set; }
		public Repeater Repeater1 { get; set; }
		public Repeater Repeater2 { get; set; }
		public Controls_Grading_GradingUsers GradingUsersControl { get; set; }


		public Controls_Grading_GradingReportsOnHold()
		{
			Repeater1 = new Repeater();
			Repeater2 = new Repeater();
			GradingUsersControl = new Controls_Grading_GradingUsers();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var selectListRepo = new SelectListRepository();
			UserId = QProcess.Session.CurrentSession.QUser.Id;
			GradingReports = selectListRepo.GetGradingUserReports(UserId).ToList();
			GradingReports.Insert(0, new NamedEntity { Id = 0, Name = "" });

			GradingUsersControl.IsFullList = IsAdmin;
			GradingUsersControl.IsReportsOnHold = true;
			GradingUsersControl.IsVacations = false;

			Repeater1.DataBind();
			Repeater2.DataBind();
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

