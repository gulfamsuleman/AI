using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Script.Serialization;
using QProcess.Enums;
using QProcess.Repositories;

namespace QProcess
{

    public partial class MyStatusExport : SessionPage
	{
		protected IEnumerable<StatusReportLine> ReportLines;

		// Query string parameters
		private DateTime dueDateFrom;
		private DateTime dueDateTo;
		private DateTime commentFrom;
		private DateTime commentTo;
		private List<int> commentIds = new List<int>();
		protected bool excludeGeneralComments;

		protected void Page_Load(object sender, EventArgs e)
		{
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            if (Request.Headers["X-CommentIds"] != null)
			{
				foreach (var id in Request.Headers["X-CommentIds"])
				{
					commentIds.Add(id);
				}
			}
			GetQueryStringParameters();
			ReportLines = GetReports();
			DataBind();
		}

		protected void GetQueryStringParameters()
		{
			// Parse "dueDateFrom" passed via query string
			dueDateFrom = !string.IsNullOrEmpty(Request.QueryString["dueDateFrom"]) ? DateTime.Parse(Request.QueryString["dueDateFrom"]) : new DateTime(1900, 01, 01);

			// Parse "dueDateTo" passed via query string
			dueDateTo = !string.IsNullOrEmpty(Request.QueryString["dueDateTo"]) ? DateTime.Parse(Request.QueryString["dueDateTo"]) : new DateTime(9999, 12, 31);

			// Parse "commentFrom" passed via query string
			commentFrom = !string.IsNullOrEmpty(Request.QueryString["commentFrom"]) ? DateTime.Parse(Request.QueryString["commentFrom"]) : new DateTime(1900, 01, 01);

			// Parse "commentTo" passed via query string
			commentTo = !string.IsNullOrEmpty(Request.QueryString["commentTo"]) ? DateTime.Parse(Request.QueryString["commentTo"]) : new DateTime(9999, 12, 31);

			// Parse "excludeGeneralComments" passed via query string
			excludeGeneralComments = !string.IsNullOrEmpty(Request.QueryString["excludeGeneralComments"]) && bool.Parse(Request.QueryString["excludeGeneralComments"]);
		}

		protected IEnumerable<StatusReportLine> GetReports()
		{
			var reportLines = new List<StatusReportLine>();

			// Get requested reports
			if (!String.IsNullOrEmpty(Request.QueryString["reportList"]))
			{
				var reportList = new JavaScriptSerializer().Deserialize<List<ExportReport>>(Request.QueryString["reportList"]);
				foreach (var export in reportList)
				{
					// Filters out tasks outside the date range
					var report = QProcess.Cache.CurrentCache.GetReport(QProcess.Session.CurrentSession.QUser.Id, export.ReportId, export.ShowArchive);
					report.ReportLines = report.ReportLines.Where(q =>
								(q.LineType == ReportLine.Type.Task &&
								q.DueDate >= dueDateFrom &&
								q.DueDate <= dueDateTo) ||
								q.LineType != ReportLine.Type.Task);

					// Exclude general comments
					if (excludeGeneralComments)
						report.ReportLines = report.ReportLines.Where(q => q.MyTaskType != TaskType.GeneralComment);

					//Exclude all unlisted comments
					if (commentIds.Count != 0)
					{
						report.ReportLines = report.ReportLines.Select(l =>
												 {
													 var toReturn = l;
													 toReturn.Comments = l.Comments.Join(commentIds, c => c.Id, id => id, (c, id) => c).ToList();
													 return toReturn;
												 });
					}

					// Filters out comments outside the date range.
					foreach (StatusReportLine line in report.ReportLines.Where(q => q.LineType == ReportLine.Type.Task && q.Comments != null))
					{
						line.Comments = line.Comments
							.Where(q =>
							q.Date >= commentFrom &&
							q.Date <= commentTo).ToList();
					}

					reportLines.AddRange(report.ReportLines);
				}
			}

			return reportLines.AsEnumerable();
		}

		protected class ExportReport
		{
			public int ReportId { get; set; }
			public bool ShowArchive { get; set; }
		}
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

