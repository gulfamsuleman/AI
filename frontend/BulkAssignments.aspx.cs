using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess
{

    public partial class BulkAssignments : SessionPage
	{
		protected List<BulkAssignment> BulkAssigned { get; set; }
		protected List<NamedEntity> Members { get; set; }

		public Repeater Repeater1 { get; set; }
		public Repeater Repeater2 { get; set; }

		protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            var bulkAssignedRepo = new BulkAssignmentRepository();
			BulkAssigned = bulkAssignedRepo.GetBulkAssignments(QProcess.Session.CurrentSession.QUser.Id).ToList();
			var selectListRepo = new SelectListRepository();
			Members = selectListRepo.GetGroups().ToList();
			Members.Insert(0, new NamedEntity { Id = -1, Name = "" });

			Repeater1.DataSource = Members;
			Repeater2.DataSource = BulkAssigned;

			Page.DataBind();
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

