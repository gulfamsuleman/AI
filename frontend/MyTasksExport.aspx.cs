using System;
using System.Web;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess
{

    public partial class MyTasksExport : SessionPage
	{
		public List<Checklist> checklists;

        public Repeater taskExportRepeater { get; set; }
        
        public MyTasksExport()
        {
            taskExportRepeater = new Repeater();            
        }

        protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            var checklistRepo = new ChecklistRepository();
			var userRepo = new UserRepository();

			var overdueInfo = checklistRepo.GetOverdueInfo(CurrentSession.QUser.Id);

			var dateRange = userRepo.GetPreferredDateRange(CurrentSession.QUser.Id, overdueInfo.MinDueDate);
			DateTime start = dateRange.Item1;
			DateTime end = dateRange.Item2;
			int recurrance = userRepo.GetPreferredRecurrence(CurrentSession.QUser.Id);

			checklists = checklistRepo.GetChecklists(CurrentSession.QUser.Id, start, end, recurrance, null, null)
				.OrderBy(q => q.DueDate).ToList();
			taskExportRepeater.DataSource = checklists;
			taskExportRepeater.DataBind();

		}
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

