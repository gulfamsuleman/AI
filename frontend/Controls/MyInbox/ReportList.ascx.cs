using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_MyInbox_ReportList : System.Web.UI.UserControl
	{
		public string Title { get; set; }
		public string SortBy { get; set; }
		public string SortOrder { get; set; }
		public List<ReportListItem> ReportList { get; set; }
		public Repeater Repeater1 { get; set; }

        public Controls_MyInbox_ReportList()
		{
			Repeater1 = new Repeater();
		}

		protected void Page_Load(object sender, EventArgs e)
		{
			Repeater1.DataSource = ReportList;
			Repeater1.DataBind();
		}

		protected string GetDaysAgo(DateTime date)
		{
			if (date != DateTime.MinValue)
			{
				var timeSpan = (QProcess.Session.CurrentSession?.UserTimeZone?.GetLocalTimeNow().Date
					?? DateTime.Today).Subtract(date.Date);
				switch (timeSpan.Days)
				{
					case 1:
						return "1 Day Ago";
					default:
						return timeSpan.Days + " Days Ago";
				}
			}
			return "";
		}

		protected string FormatReportName(string n)
		{
			if (n.Length > 25)
			{
				n = n.Substring(0, 22) + "...";
			}
			return n;
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

