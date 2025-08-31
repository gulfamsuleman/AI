using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;
using QProcess.Controls;
using System.Web;

namespace QProcess
{
    public partial class GradingAdmin : SessionPage
	{
		protected int PeriodId { get; set; }
		protected IEnumerable<GradingGridLine> GridLines { get; set; }
		protected string SortedColumn { get; set; }
		protected string SortOrder { get; set; }

        public Repeater Repeater1 { get; set; }
		public Controls_Grading_GradingPeriods GradingPeriodsControl { get; set; }

        public GradingAdmin()
        {
            Repeater1 = new Repeater();
			GradingPeriodsControl = new Controls_Grading_GradingPeriods();
        }

        protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            if (!QProcess.Session.CurrentSession.QUser.IsGradingAdmin)
				Context.Response.Redirect("Grading.aspx");
			var gradingRepo = new GradingRepository();
			SortedColumn = Context.Request.Params["sortBy"] ?? "";
			SortOrder = Context.Request.Params["sortOrder"] ?? "";
			string sortExpression;
			if (!String.IsNullOrEmpty(SortedColumn) && !String.IsNullOrEmpty(SortOrder))
				sortExpression = SortedColumn + " " + SortOrder;
			else
				sortExpression = "";
			PeriodId = Context.Request.Params["period"] != null ? int.Parse(Context.Request.Params["period"]) : GradingPeriodsControl.GradingPeriods.First().Id;
			GradingPeriodsControl.PeriodId = PeriodId;
			GridLines = gradingRepo.GetGradingGrid(PeriodId, sortExpression);

			Repeater1.DataBind();
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

