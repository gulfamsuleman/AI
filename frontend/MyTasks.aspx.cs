using System;
using System.Collections.Generic;
using System.Linq;
using QProcess.Repositories;
using QProcess.Extensions;
using System.Web.UI.WebControls;
using System.Web;

namespace QProcess
{

    public partial class MyTasks : SessionPage
	{
		public List<Checklist> Checklists;

		public int RecurrenceValue { get; private set; }
		public string StartDateString { get; private set; }
		public string EndDateString { get; private set; }
		protected bool IsMyTasks { get; set; }
		protected bool ExpandAll { get; set; }
		protected string AcID { get; set; }

        public Repeater taskRepeater1 { get; set; }
        public Repeater taskRepeater2 { get; set; }

        public MyTasks()
        {
            taskRepeater1 = new Repeater();
            taskRepeater2 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;
			if((Request.IsMobileBrowser() && !CurrentSession.ForceDesktop(Request)) || CurrentSession.ForceMobile(Request) )
			{ 
				Response.RedirectToMobile(Request.Url);
				return;
			}

            // [ST] 08/05/14 11:34 AM - retrieve to allow open task via querystring, Frogslayer did not copy this functionality over
            AcID = Request.QueryString["ac"].ToBlank();

			if (Context.Request.QueryString["expandAll"] != null)
				ExpandAll = Convert.ToBoolean(Context.Request.QueryString["expandAll"]);

			var checklistRepo = new ChecklistRepository();
			var userRepo = new UserRepository();

			var overdueInfo = checklistRepo.GetOverdueInfo(CurrentSession.QUser.Id);

			Tuple<DateTime, DateTime> dateRange = userRepo.GetPreferredDateRange(CurrentSession.QUser.Id, overdueInfo.MinDueDate);
			DateTime start = dateRange.Item1;
			DateTime end = dateRange.Item2;
			DateTime now = CurrentSession.QUser.MyTimeZone.GetLocalTimeNow();

			// Setting up some reasonable defaults - window will be 1 week back and 2 weeks forward
			if (start == null || start < now.AddDays(-90))
			{
				start = now.AddDays(-7);
			}

			if (end == null || end > now.AddDays(90))
			{
				end = now.AddDays(14);
			}
			int recurrance = userRepo.GetPreferredRecurrence(CurrentSession.QUser.Id);

			if (Request.HttpMethod == "POST")
			{
				if (Request.Form["filter-submit"] != null)
				{
					int.TryParse(Request.Form["recurrance"], out recurrance);
					DateTime.TryParse(Request.Form["start-date"], out start);
					DateTime.TryParse(Request.Form["end-date"] + " 23:59:59", out end);
				}
			}

			IsMyTasks = true;			

			if (ExpandAll)
			{
                Checklists = checklistRepo.GetChecklists(CurrentSession.QUser.Id, start, end, recurrance, null, null)
					.OrderBy(c => c.IsCompleted)
					.ThenBy(c => c.IsCompleted ? c.CompletedOn : c.DueDate)
					.ToList();

                taskRepeater1.DataSource = Checklists;
				taskRepeater1.DataBind();
			}
			else
			{
				taskRepeater2.DataSource = Checklists;
				taskRepeater2.DataBind();
			}

			RecurrenceValue = recurrance;
			StartDateString = start.ToShortDateString();
			EndDateString = end.ToShortDateString();
		}
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

