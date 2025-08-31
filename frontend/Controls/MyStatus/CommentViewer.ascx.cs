using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI;
using QProcess.Repositories;

namespace QProcess.Controls
{
	public partial class Controls_MyStatus_CommentViewer : UserControl
	{
		public Dictionary<ReportCommentItems, List<ReportComment>> Comments { get; set; }
		public string Mode { get; set; }
		public int UserId { get; set; }
		public int ReportId { get; set; }
		public DateTime? StartTime { get; set; }

		protected void Page_Load(object sender, EventArgs e)
		{
			var repo = new StatusReportRepository();
			UserId = int.Parse(Context.Request.Headers["X-UserId"]);
			Mode = Context.Request.Headers["X-Mode"];
			ReportId = int.Parse(Context.Request.Headers["X-ReportId"]);
			StartTime = !string.IsNullOrWhiteSpace(Context.Request.Headers["X-StartTime"]) ? (DateTime?)DateTime.Parse(Context.Request.Headers["X-StartTime"]) : null;
			Comments = new Dictionary<ReportCommentItems, List<ReportComment>>();
			var items = repo.GetLatestCommentedReports(UserId, ReportId, null, null, false, StartTime);

			foreach (var item in items.Where(item => item.ID != null))
			{
				var comments = repo.GetLatestComments(UserId, item.ID.Value, ReportId, StartTime);
				Comments.Add(item, comments);
			}
		}
	}
}
/* Copyright © 2024 Renegade Swish, LLC */

