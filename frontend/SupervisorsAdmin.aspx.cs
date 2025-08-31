using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI.WebControls;
using QProcess.Repositories;
using QProcess.Controls;

namespace QProcess
{

	public partial class SupervisorsAdmin : SessionPage
	{
		protected List<NamedEntity> Reports { get; set; }
		protected List<NamedEntity> People { get; set; }

        public Repeater Repeater1 { get; set; }
        public Repeater Repeater2 { get; set; }
		public Controls_Shared_Supervisors Supervisors { get; set; }
        public Controls_Shared_Controllers Controllers { get; set; }

        protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            if (!CurrentSession.QUser.IsGradingAdmin)
				Context.Response.Redirect("MyTasks.aspx");
			var selectListRepo = new SelectListRepository();
			Reports = selectListRepo.GetReports().ToList();
			Reports.Insert(0, new NamedEntity { Id = -1, Name = "" });

			Supervisors.IsSupervisorAdmin = true;
			Controllers.IsSupervisorsAdmin = true;

			Repeater1.DataBind();

			People = selectListRepo.GetReportsUserList().ToList();
			People.Insert(0, new NamedEntity { Id = -1, Name = "" });
			Repeater2.DataBind();
		}
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

