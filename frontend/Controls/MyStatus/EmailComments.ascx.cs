using System;
using System.Collections.Generic;
using System.Linq;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_MyStatus_EmailComments : System.Web.UI.UserControl
	{
		public List<ReportEmailHeader> ReportEmails { get; set; }
		public Dictionary<ReportCommentItems, List<ReportComment>> Comments { get; set; }
		public string Mode { get; set; }
		public int ReportId { get; set; }
		public int TaskId { get; set; }
		public int UserId { get; set; }
		public bool Inbox { get; set; }
		public string TimeZones { get; set; }
		protected void Page_Load(object sender, EventArgs e)
		{
			var repo = new StatusReportRepository();
			if (Context.Request.Headers["X-TaskId"] != null)
				TaskId = int.Parse(Context.Request.Headers["X-TaskId"]);
			if (Context.Request.Headers["X-Inbox"] != null)
				Inbox = Convert.ToBoolean(Context.Request.Headers["X-Inbox"]);
			if (Context.Request.Headers["X-RecipientIds"] != null)
			{
				var recIds = Context.Request.Headers["X-RecipientIds"];
                TimeZones = repo.GetTimeZonesForUsers(recIds);
            }

            ReportId = int.Parse(Context.Request.Headers["X-ReportId"]);
			Mode = Context.Request.Headers["X-Mode"];
			UserId = QProcess.Session.CurrentSession.QUser.Id;
			ReportEmails = repo.GetReportEmails(ReportId, TaskId);
			Comments = new Dictionary<ReportCommentItems, List<ReportComment>>();

			var items = new List<ReportCommentItems>();
			switch (Mode)
			{
				case "comments":
					items = repo.GetLatestCommentedReports(UserId, ReportId, timeZones: TimeZones);
					break;
				case "todays-comments":
					items = repo.GetTodaysCommentedReports(UserId, ReportId, timeZones: TimeZones);
					break;
				case "report":
					break;
			}
			foreach (var item in items.Where(item => item.ID != null))
			{
				Comments.Add(item, repo.GetLatestComments(UserId, item.ID.Value, ReportId, new DateTime(1900, 1, 1)));
			}
		}

		protected string LoggedInEmailCheck(int emailUserID)
		{
			if (emailUserID == UserId)
			{
				return "checked disabled='disabled'";
			}
			else
			{
				return "";
			}
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

