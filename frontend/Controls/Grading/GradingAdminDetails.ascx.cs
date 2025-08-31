using System;
using System.Linq;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Grading_GradingAdminDetails : System.Web.UI.UserControl
	{
		protected int UserId { get; set; }
		protected int PeriodId { get; set; }
		protected Tuple<DateTime, DateTime> PeriodDates { get; set; }
		protected bool IsAdminDetails { get; set; }

		public Controls_Grading_GradingUsers GradingUsersControl { get; set; }
		public Controls_Grading_GradingPeriods GradingPeriodsControl { get; set; }
		public Controls_Grading_GradingDeductions GradingDeductionsControl { get; set; }
		public Controls_Grading_GradingVacations GradingVacationsControl { get; set; }
		public Controls_Grading_GradingReportsOnHold GradingReportsOnHoldControl { get; set; }

		public Controls_Grading_GradingAdminDetails()
		{
			GradingUsersControl = new Controls_Grading_GradingUsers();
			GradingPeriodsControl = new Controls_Grading_GradingPeriods();
			GradingDeductionsControl = new Controls_Grading_GradingDeductions();
			GradingVacationsControl = new Controls_Grading_GradingVacations();
			GradingReportsOnHoldControl = new Controls_Grading_GradingReportsOnHold();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var gradingRepo = new GradingRepository();
			var selectListRepo = new SelectListRepository();
			IsAdminDetails = true;
			if (!QProcess.Session.CurrentSession.QUser.IsGradingAdmin)
				Context.Response.Redirect("Grading.aspx");
			UserId = Context.Request.Headers["X-UserId"] != null ? int.Parse(Context.Request.Headers["X-UserId"]) : GradingUsersControl.Users.First().Id;
			GradingUsersControl.SelectedUserId = UserId;
			PeriodId = Context.Request.Headers["X-PeriodId"] != null ? int.Parse(Context.Request.Headers["X-PeriodId"]) : GradingPeriodsControl.GradingPeriods.First().Id;
			PeriodDates = gradingRepo.GetGradingPeriodDates(PeriodId);

			GradingUsersControl.IsFullList = true;
			GradingUsersControl.SelectedUserId = UserId;
			GradingPeriodsControl.PeriodId = PeriodId;
			GradingPeriodsControl.GradingPeriods = selectListRepo.GetGradingPeriods().ToList();
			GradingDeductionsControl.UserId = UserId;
			GradingDeductionsControl.PeriodId = PeriodId;
			GradingDeductionsControl.IsAdminDetails = true;
			GradingVacationsControl.Vacations = gradingRepo.GetVacations(PeriodDates.Item1, PeriodDates.Item2, UserId);
			GradingVacationsControl.IsAdminDetails = true;
			GradingReportsOnHoldControl.IsAdminDetails = true;
			GradingReportsOnHoldControl.ReportsOnHold = gradingRepo.GetReportsOnHold(PeriodDates.Item1, PeriodDates.Item2, UserId);
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

