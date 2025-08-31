using QProcess.Repositories;
using System;
using System.Web;

namespace QProcess.Controls
{
	public partial class Controls_MyStatus_ReportLine : System.Web.UI.UserControl
	{
		public StatusReportLine Line { get; set; }
		public DateTime LastViewed { get; set; }
		public int TaskWidth { get; set; }
		protected void Page_Load(object sender, EventArgs e)
		{
		}
		public HtmlString TakeControlButton()
		{
			if (QProcess.Session.CurrentSession.QUser.IsSupervisor)
			{
				var button = "<input type='button' data-role='take-control' value='Take Control' class='btn btn-default btn-sm'/>";
				return new HtmlString(button);
			}
			else
			{
				return new HtmlString("");
			}
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

