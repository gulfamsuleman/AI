using System;
using QProcess.Configuration;
using System.Web.UI;

namespace QProcess
{
    public class SessionPage : Page
    {
		protected Session CurrentSession;
		protected string Firm { get; set; }

		protected QProcessMasterPage MasterPage => Master as QProcessMasterPage;			

		public SessionPage()
		{
		}

		protected override void OnPreInit(EventArgs e)
		{
			base.OnPreInit(e);
			CurrentSession = new Session(this.Session);
			Firm = AppSettings.Get("Firm");
		}
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

