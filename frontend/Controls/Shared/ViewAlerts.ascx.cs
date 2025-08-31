using System;
using System.Collections.Generic;
using System.Linq;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Shared_ViewAlerts : System.Web.UI.UserControl
	{
		protected List<ViewAlert> ViewAlerts { get; set; }

		protected void Page_Load(object sender, EventArgs e)
		{
			var repo = new ViewAlertRepository();
			ViewAlerts = repo.GetAlertTimes(int.Parse(Context.Request.Headers["X-UniqueId"]),
											(TaskStage)Enum.Parse(typeof(TaskStage), Context.Request.Headers["X-TaskStage"])).ToList();
			DataBind();
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

