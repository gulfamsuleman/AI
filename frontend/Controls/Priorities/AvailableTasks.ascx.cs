using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Priorities_AvailableTasks : System.Web.UI.UserControl
	{
		protected List<PriorityTask> AvailableTasks { get; set; }
		protected int ForUserId { get; set; }
        protected int ForListId { get; set; }
        protected string Sort { get; set; }
		public Repeater Repeater1 { get; set; }

		public Controls_Priorities_AvailableTasks()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var prioritiesRepo = new PrioritiesRepository();
			ForUserId = Convert.ToInt32(Context.Request.Headers["X-TargetUserId"]);
            ForListId = Convert.ToInt32(Context.Request.Headers["X-TargetListId"]);
            Sort = Convert.ToString(Context.Request.Headers["X-Sort"]);
			AvailableTasks = prioritiesRepo.GetAvailableTasks(ForUserId, ForListId, QProcess.Session.CurrentSession.QUser.Id, Sort).ToList();

			if (AvailableTasks.Any())
			{
				Repeater1.DataSource = AvailableTasks;
				Repeater1.DataBind();
			}
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

