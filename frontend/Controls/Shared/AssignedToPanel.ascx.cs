using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Shared_AssignedToPanel : System.Web.UI.UserControl
	{
		public int InstanceId { get; set; }
		public int ChangeId { get; set; }
		public List<AssigneeInfo> MyAssignees { get; set; }
		protected IList<NamedEntity> Assignees;
		protected int UserId { get; set; }

		public Repeater Repeater1 { get; set; }

		public Controls_Shared_AssignedToPanel()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			UserId = QProcess.Session.CurrentSession.QUser.Id;
			var selectListRepo = new SelectListRepository();
			Assignees = selectListRepo.GetGroups().ToList();
			Assignees.Insert(0, new NamedEntity { Id = -1, Name = "" });
			Repeater1.DataBind();

			if (Context.Request.Headers["X-InstanceId"] != null)
				InstanceId = int.Parse(Context.Request.Headers["X-InstanceId"]);
			if (Context.Request.Headers["X-ChangeId"] != null)
				ChangeId = int.Parse(Context.Request.Headers["X-ChangeId"]);
			var checklistRepo = new ChecklistRepository();
			MyAssignees = checklistRepo.GetAssigneesForInstance(InstanceId, ChangeId);
			DataBind();
		}
		public HtmlString SerializedAssignments()
		{
			var serializer = new JavaScriptSerializer();
			var toSerialize = MyAssignees.Select(a => new { id = a.ID, name = a.Name, existing = a.Existing }).ToList();
			return new HtmlString(serializer.Serialize(toSerialize));
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

