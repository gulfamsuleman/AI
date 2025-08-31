using System;
using System.Collections.Generic;
using QProcess.Enums;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_MyInbox_ManageEmails : System.Web.UI.UserControl
	{
		protected Dictionary<EmailPreferenceType, bool> EmailPreferences { get; set; }
		protected void Page_Load(object sender, EventArgs e)
		{
			var myInboxRepo = new MyInboxRepository();
			EmailPreferences = myInboxRepo.GetSupervisorEmailPreferences(QProcess.Session.CurrentSession.QUser.Id);
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

