using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Grading_GradingUsers : System.Web.UI.UserControl
	{
		public List<GradingUser> Users
		{
			get { return _Users ?? new GradingRepository().GetGradingUsers(UserId).ToList(); }
			set { _Users = value; }
		}
		private List<GradingUser> _Users { get; set; }
		public int SelectedUserId { get; set; }
		public bool IsFullList { get; set; }
		public bool IsVacations { get; set; }
		public bool IsReportsOnHold { get; set; }
		protected int UserId { get; set; }
		public Repeater Repeater1 { get; set; }

		public Controls_Grading_GradingUsers()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var gradingRepo = new GradingRepository();
			UserId = QProcess.Session.CurrentSession.QUser.Id;
			_Users = gradingRepo.GetGradingUsers(UserId).ToList();
			if (!IsFullList)
				Users = Users.Where(u => u.Id == UserId).ToList();
			if (IsVacations)
				Users.Insert(0, new GradingUser { Id = -1, Name = "" });
			if (IsReportsOnHold)
				Users.Insert(0, new GradingUser { Id = -1, Name = "All" });

			Repeater1.DataBind();
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

