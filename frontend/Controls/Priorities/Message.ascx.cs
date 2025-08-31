using System;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Priorities_Message : System.Web.UI.UserControl
	{
		protected bool Reply { get; set; }
		protected int RespondToId { get; set; }
		protected string RespondToName { get; set; }
		protected PriorityMessage Message { get; set; }
		protected void Page_Load(object sender, EventArgs e)
		{
			Reply = Convert.ToBoolean(Context.Request.Headers["X-reply"]);
			RespondToId = Convert.ToInt32(Context.Request.Headers["X-respondId"]);
			RespondToName = Convert.ToString(Context.Request.Headers["X-respondName"]);
			if (Reply)
			{
				Message = QProcess.Cache.CurrentCache.GetMessagesByUserId(QProcess.Session.CurrentSession.QUser.Id);
			}

		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

