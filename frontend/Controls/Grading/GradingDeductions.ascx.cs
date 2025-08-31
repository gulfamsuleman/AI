using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_Grading_GradingDeductions : System.Web.UI.UserControl
	{
		protected IEnumerable<Deduction> Deductions { get; set; }
		public int UserId { get; set; }
		public int PeriodId { get; set; }
		public bool IsAdminDetails { get; set; }
		public Repeater Repeater1 { get; set; }

		public Controls_Grading_GradingDeductions()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			var gradingRepo = new GradingRepository();
			Deductions = gradingRepo.GetDeductions(UserId, PeriodId, IsAdminDetails);

			Repeater1.DataBind();
		}

		public string GetPointColor(double point, int type)
		{
			string pointStyle = "class=";
			switch (type)
			{
				case 0:
					pointStyle += point < 0.0 ? "'red'" : "'green'";
					break;
				case 1:
					pointStyle += "'green bold'";
					break;
				case -1:
					pointStyle += point != 0.0 ? "'red bold'" : "";
					break;
				case 2:
					pointStyle += "'bold'";
					break;
			}
			return pointStyle;
		}

		public string GetPointValue(double point, int type)
		{
			string pointValue = "";
			switch (type)
			{
				case -1:
					pointValue += point != 0.0 ? "(" + Math.Abs(point) + ")" : point.ToString();
					break;
				case 0:
					pointValue += point < 0.0 ? "(" + Math.Abs(point) + ")" : point.ToString();
					break;
				case 1:
				case 2:
					pointValue += point.ToString();
					break;
			}
			return pointValue;
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

