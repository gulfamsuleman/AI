using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Priorities_AvailableUsers : System.Web.UI.UserControl
	{
		protected int SetId { get; set; }
		protected List<NamedEntity> AvailableUsers { get; set; }
		public Repeater Repeater1 { get; set; }

		public Controls_Priorities_AvailableUsers()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var selecListRepo = new SelectListRepository();
			SetId = Convert.ToInt32(Context.Request.Headers["X-SetId"]);
			AvailableUsers = selecListRepo.GetAvailableUsers(QProcess.Session.CurrentSession.QUser.Id, SetId).ToList();

			if (AvailableUsers.Any())
			{
				Repeater1.DataSource = AvailableUsers;
				Repeater1.DataBind();
			}
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

