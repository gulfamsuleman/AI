using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Reports_OverdueMessage : System.Web.UI.UserControl
	{
		protected List<NamedEntity> Recipients { get; set; }
		public Repeater Repeater1 { get; set; }

		public Controls_Reports_OverdueMessage()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var selectListRepo = new SelectListRepository();
			var userID = QProcess.Session.CurrentSession.QUser.Id;
			var controllerID = userID;
			if (Context.Request.Headers["X-UserId"] != null)
			{
				controllerID = Convert.ToInt32(Context.Request.Headers["X-UserId"]);
			}
			Recipients = selectListRepo.GetOverdueRecipients(userID, controllerID).ToList();

			Repeater1.DataSource = Recipients;
			Repeater1.DataBind();
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

