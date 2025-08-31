using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Enums;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Reports_Overdue : System.Web.UI.UserControl
	{
		protected List<NamedEntity> Users { get; set; }
		protected bool IsOverdueAdmin { get; set; }
		protected int UserId { get; set; }
		protected List<ReportChecklistStatus> Tasks { get; set; }
		public Repeater Repeater1 { get; set; }
		public Repeater Repeater2 { get; set; }
		public Controls_Reports_SortBy SortByControl { get; set; }

		public Controls_Reports_Overdue()
		{
			Repeater1 = new Repeater();
			Repeater2 = new Repeater();
			SortByControl = new Controls_Reports_SortBy();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			UserId = QProcess.Session.CurrentSession.QUser.Id;
			IsOverdueAdmin = QProcess.Session.CurrentSession.QUser.IsOverdueAdmin;
			SortByControl.Sort = "Due";
			var selectListRepo = new SelectListRepository();
			Users = selectListRepo.GetReportsUserList().ToList();

			var reportsRepo = new ReportsRepository();
			if (Context.Request.Headers["X-UserId"] != null)
			{
				UserId = Convert.ToInt32(Context.Request.Headers["X-UserId"]);
			}
			if (Context.Request.Headers["X-Sort"] != null)
			{
				SortByControl.Sort = Convert.ToString(Context.Request.Headers["X-Sort"]);
			}

			Tasks = reportsRepo.GetOpenChecklist(UserId, SortByControl.Sort, ReportType.Overdue).ToList();

			Repeater1.DataSource = Users;
			Repeater1.DataBind();
			Repeater2.DataSource = Tasks;
			Repeater2.DataBind();
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

