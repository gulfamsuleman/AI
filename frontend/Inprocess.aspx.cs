using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;
using QProcess.Controls;
using QProcess.Models;
using System.Web.UI;
using QProcess.Configuration;
using System.Web;

namespace QProcess
{

    public partial class Inprocess : SessionPage
	{
		protected List<NamedEntity> Reports { get; set; }
        public Repeater Repeater1 { get; set; }
        public Controls_Shared_Supervisors Supervisors { get; set; }
		public IUser QUser => CurrentSession.QUser;
        public string AppName => AppSettings.Get("AppName");
        //public string Firm => QProcess.Configuration.AppSettings.Get("Firm");

        public Inprocess()
        {
            Repeater1 = new Repeater();
			Supervisors = new Controls_Shared_Supervisors();
        }

        protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            //if (QUser.Username == "kshannon") QUser.IsAdmin = false;

            if (!QUser.IsAdmin)
            {
                var reportRepo = new StatusReportRepository();
                var userReport = reportRepo.GetDefaultReport(QUser.Id);

                Reports = new List<NamedEntity>() { new NamedEntity { Name = QUser.FullName, Id = userReport } };
            }
            else
            {
                var selectListRepo = new SelectListRepository();
                Reports = selectListRepo.GetReportsNoSupervisors().ToList();
                Reports.Insert(0, new NamedEntity { Id = -1, Name = "" });
            }

            Supervisors.IsSupervisorAdmin = true;
			Supervisors.InProcessingOnly = true;

			Repeater1.DataBind();
		}

        protected override void Render(HtmlTextWriter writer)
        {
            //don't bother if we're just redirecting to the auth provider
            if (Request.IsAuthenticated)
                base.Render(writer);

            //This forces the QProcess Session class to re-retrieve the user (including new supes)
            HttpContext.Current.Session["CurrentUser"] = null;
        }        
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

