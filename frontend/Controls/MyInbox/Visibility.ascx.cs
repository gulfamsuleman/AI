using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_MyInbox_Visibility : System.Web.UI.UserControl
	{
		protected List<Personnel> Supervisors { get; set; }
		protected List<Personnel> InterestedParties { get; set; }
		protected List<Personnel> Controllers { get; set; }
		protected int ReportId { get; set; }
		public Repeater Repeater1 { get; set; }
		public Repeater Repeater2 { get; set; }
		public Repeater Repeater3 { get; set; }

		public Controls_MyInbox_Visibility()
		{
			Repeater1 = new Repeater();
			Repeater2 = new Repeater();
			Repeater3 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var myInboxRepo = new MyInboxRepository();
			if (Context.Request.Headers["X-ReportId"] != null)
				ReportId = Convert.ToInt32(Context.Request.Headers["X-ReportId"]);
			Supervisors = myInboxRepo.GetSupervisorList(ReportId).ToList();
			InterestedParties = myInboxRepo.GetInterestedPartyList(ReportId).ToList();
			Controllers = myInboxRepo.GetUserList(ReportId).ToList();

			if (Supervisors.Any())
			{
				Repeater1.DataSource = Supervisors;
				Repeater1.DataBind();
			}
			if (InterestedParties.Any())
			{
				Repeater2.DataSource = InterestedParties;
				Repeater2.DataBind();
			}
			if (Controllers.Any())
			{
				Repeater3.DataSource = Controllers;
				Repeater3.DataBind();
			}
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

