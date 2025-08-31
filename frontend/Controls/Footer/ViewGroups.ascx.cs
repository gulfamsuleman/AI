using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Footer_ViewGroups : System.Web.UI.UserControl
	{
		protected IEnumerable<NamedEntity> Groups { get; set; }
		protected UserRepository UserRepo { get; set; }
		protected List<GroupList> MultiUserGroups { get; set; }
		public Repeater Repeater1 { get; set; }

		public Controls_Footer_ViewGroups()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var selectListRepo = new SelectListRepository();
			var userRepo = new UserRepository();
			Groups = selectListRepo.GetMultiUserGroups();
			MultiUserGroups = new List<GroupList>();
			foreach (var group in Groups)
			{
				MultiUserGroups.Add(new GroupList { Id = group.Id, Name = group.Name, GroupMembers = userRepo.GetUsersInGroup(@group.Id) });
			}
			Repeater1.DataBind();
		}

		public class GroupList
		{
			public int Id { get; set; }
			public string Name { get; set; }
			public IEnumerable<User> GroupMembers { get; set; }
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

