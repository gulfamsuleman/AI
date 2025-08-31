using System;
using System.Collections.Generic;
using System.Linq;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Shared_AssigneesMultiSelect : System.Web.UI.UserControl
	{
		public IEnumerable<NamedEntity> PossibleAssignees;
		public List<int> InitialSelections;

		protected void Page_Load(object sender, EventArgs e)
		{
			InitialSelections = new List<int>();
			if (!string.IsNullOrEmpty(Context.Request.Headers["X-Preselect"]))
				InitialSelections = Context.Request.Headers["X-Preselect"].Split(',').Select(int.Parse).ToList();
			var selectListRepo = new SelectListRepository();
			PossibleAssignees = selectListRepo.GetGroups().Where(g => g != null);
			DataBind();

		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

