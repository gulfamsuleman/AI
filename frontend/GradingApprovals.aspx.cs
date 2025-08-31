using System;
using System.Linq;
using System.Web;
using QProcess.Repositories;
using QProcess.Controls;

namespace QProcess
{

    public partial class GradingApprovals : SessionPage
	{
		protected int PeriodId { get; set; }
		protected Tuple<DateTime, DateTime> PeriodDates { get; set; }
		protected bool IsApproval { get; set; }

        public Controls_Grading_GradingVacations GradingVacationsControl { get; set; }
        public Controls_Grading_GradingReportsOnHold GradingReportsOnHoldControl { get; set; }
        public Controls_Grading_GradingPeriods GradingPeriodsControl { get; set; }
        
        public GradingApprovals()
        {
            GradingVacationsControl = new Controls_Grading_GradingVacations();
            GradingReportsOnHoldControl = new Controls_Grading_GradingReportsOnHold();
            GradingPeriodsControl = new Controls_Grading_GradingPeriods();
        }

        protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            if (!QProcess.Session.CurrentSession.QUser.IsGradingAdmin)
				Context.Response.Redirect("Grading.aspx");
			var gradingRepo = new GradingRepository();
			PeriodId = Context.Request.Params["period"] != null ? int.Parse(Context.Request.Params["period"]) : GradingPeriodsControl.GradingPeriods.First().Id;
			PeriodDates = gradingRepo.GetGradingPeriodDates(PeriodId);
			IsApproval = true;

			GradingVacationsControl.IsApproval = IsApproval;
			GradingVacationsControl.Vacations = gradingRepo.GetVacations(PeriodDates.Item1, PeriodDates.Item2);
			GradingReportsOnHoldControl.IsAdmin = IsApproval;
			GradingReportsOnHoldControl.ReportsOnHold = gradingRepo.GetReportsOnHold(PeriodDates.Item1, PeriodDates.Item2);
			GradingPeriodsControl.PeriodId = PeriodId;
		}
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

