using System;
using System.Linq;
using QProcess.Repositories;
using QProcess.Controls;
using System.Web;

namespace QProcess
{

    public partial class Grading : SessionPage
	{
		protected int UserId { get; set; }
		protected bool IsGradingAdmin { get; set; }
		protected int PeriodId { get; set; }
		protected Tuple<DateTime, DateTime> PeriodDates { get; set; }

        public Controls_Grading_GradingPeriods GradingPeriodsControl { get; set; }
        public Controls_Grading_GradingDeductions GradingDeductionsControl { get; set; }
        public Controls_Grading_GradingVacations GradingVacationsControl { get; set; }
        public Controls_Grading_GradingReportsOnHold GradingReportsOnHoldControl { get; set; }

        public Grading()
        {
            GradingPeriodsControl = new Controls_Grading_GradingPeriods();
            GradingDeductionsControl = new Controls_Grading_GradingDeductions();
            GradingVacationsControl = new Controls_Grading_GradingVacations();
            GradingReportsOnHoldControl = new Controls_Grading_GradingReportsOnHold();
        }

        protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            var gradingRepo = new GradingRepository();
			UserId = Context.Request.Params["userId"] != null ? int.Parse(Context.Request.Params["userId"]) : QProcess.Session.CurrentSession.QUser.Id;
			IsGradingAdmin = QProcess.Session.CurrentSession.QUser.IsGradingAdmin;
			PeriodId = Context.Request.Params["period"] != null ? int.Parse(Context.Request.Params["period"]) : GradingPeriodsControl.GradingPeriods.First().Id;
			PeriodDates = gradingRepo.GetGradingPeriodDates(PeriodId);

			GradingPeriodsControl.PeriodId = PeriodId;
			GradingDeductionsControl.UserId = UserId;
			GradingDeductionsControl.PeriodId = PeriodId;
			GradingVacationsControl.IsApproval = false;
			GradingVacationsControl.Vacations = gradingRepo.GetVacations(PeriodDates.Item1, PeriodDates.Item2, UserId);
			GradingReportsOnHoldControl.IsAdmin = false;
			GradingReportsOnHoldControl.ReportsOnHold = gradingRepo.GetReportsOnHold(PeriodDates.Item1, PeriodDates.Item2, UserId);
		}
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

