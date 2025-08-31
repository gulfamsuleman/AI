using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess
{

    public partial class Automations : SessionPage
	{
		protected List<TaskDetails> Tasks { get; set; }

		public Repeater Repeater1 { get; set; }
        public Repeater Repeater2 { get; set; }

        protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            var linkedRepo = new LinkedDeadlineRepository();
            Tasks = linkedRepo.GetControlledTaskNames(QProcess.Session.CurrentSession.QUser.Id).ToList();
			Repeater1.DataSource = Tasks;
            Repeater2.DataSource = Tasks;

            Page.DataBind();
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

