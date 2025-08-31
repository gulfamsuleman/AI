using System;
using System.Collections.Generic;
using System.Linq;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Users_EditGroup : System.Web.UI.UserControl
	{
		protected IEnumerable<User> GroupUsers { get; set; }
		protected List<NamedUserEntity> UsersList { get; set; }
        protected List<NamedUserEntity> OwnerList { get; set; }
        protected int GroupId { get; set; }
        protected int Owner { get; set; }
        protected bool Editable { get; set; }

		protected Session CurrentSession => QProcess.Session.CurrentSession;

		protected void Page_Load(object sender, EventArgs e)
		{
			var userRepo = new UserRepository();
			var selectListRepo = new SelectListRepository();

			GroupId = int.Parse(Context.Request.Headers["X-GroupId"]);
			Editable = bool.Parse(Context.Request.Headers["X-Editable"]);
			GroupUsers = userRepo.GetUsersInGroup(GroupId);
			Owner = userRepo.GetGroupOwner(GroupId);
			OwnerList = selectListRepo.GetUsers(CurrentSession.QUser.Id, CurrentSession.QUser.IsAdmin)
                .Select(u => new NamedUserEntity { Id = u.Id, Name = u.Name }).ToList();
            UsersList = selectListRepo.GetUsers(CurrentSession.QUser.Id, CurrentSession.QUser.IsAdmin)
				.Select(u => new NamedUserEntity { Id = u.Id, Name = u.Name, InGroup = GroupUsers.Any(g => g.FullName == u.Name) }).ToList();
			UsersList.Insert(0, new NamedUserEntity { Id = -1, InGroup = false, Name = "" });
			DataBind();
		}

		public class NamedUserEntity : NamedEntity
		{
			public bool InGroup { get; set; }
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

