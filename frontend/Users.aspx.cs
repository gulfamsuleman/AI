using System;
using System.Web;
using System.Collections.Generic;
using QProcess.Repositories;

namespace QProcess
{

    public partial class Users : SessionPage, IProvideReportIdForLogging
	{
		protected IEnumerable<User> UserLines;
		protected IEnumerable<UserGroup> UserGroups;
		public int ReportId { get; set; }

		protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            if (!CurrentSession.QUser.IsAdmin)
				Response.Redirect("Groups.aspx");
			var repo = new UserRepository();
			UserLines = repo.GetUsers();
			UserGroups = repo.GetGroups();
			ReportId = 1;
			DataBind();
		}
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

