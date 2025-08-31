using System;
using System.Collections.Generic;
using System.Linq;
using QProcess.Repositories;
using System.Data;
using QProcess.Extensions;
using DataAccessLayer;

namespace QProcess
{

    public partial class MyStatusEmailForm : SessionPage
    {
        protected List<StatusReportLine> ReportLines;
        protected List<ReportCommentItems> ReportComments;
        public List<int> CommentIds = null;
        public int ReportId { get; set; }
        public string Mode { get; set; }
        public DateTime CommentsSince { get; set; }
        public bool OnlyTasksWithComments { get; set; }
        public bool IsIncludeDetails { get; set; }
        public string AppUrl { get; set; }
        public Boolean IsArchive { get; set; }
        public Boolean IsAttorneyClient { get; set; }
        public int UserId { get; set; }
        protected bool Mobile = false;
        protected string ToList { get; set; }
        protected string TimeZones { get; set; }
        protected string ReportUsername { get; set; }
        protected string WidthCSS { get; set; }
        
        protected void Page_Load(object sender, EventArgs e)
        {
            //if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            Mobile = Request.Headers["X-SingleCol"].ToBlank() == "1"
                || Request.Headers["X-SingleCol"].ToBlank().ToLowerInvariant() == "true";

            UserId = CurrentSession.QUser?.Id ?? 0;
            if (UserId == 0) UserId = Convert.ToInt32(Request.Headers["X-UserID"]);

            TimeZones = "";
            if (!String.IsNullOrEmpty(Request.Headers["X-RecipientIds"]))
            {
                var recIds = Request.Headers["X-RecipientIds"];
                TimeZones = new StatusReportRepository().GetTimeZonesForUsers(recIds);
            }

            if (!String.IsNullOrEmpty(Request.Headers["X-CommentIds"]))
            {
                CommentIds = new List<int>();

                foreach (var id in Request.Headers["X-CommentIds"].Split(','))
                {
                    CommentIds.Add(Convert.ToInt32(id));
                }
            }

            if (Request.Headers["X-IsArchive"] != null)
            {
                if (Request.Headers["X-IsArchive"].ToString().Trim() == "")
                    IsArchive = false;
                else
                    IsArchive = bool.Parse(Request.Headers["X-IsArchive"]);
            }

            if (Request.Headers["X-Mode"] != null)
            {
                Mode = Request.Headers["X-Mode"];
            }

            if (!String.IsNullOrWhiteSpace(Request.Headers["X-CommentsDate"]) 
                && !String.IsNullOrWhiteSpace(Request.Headers["X-CommentsTime"]))
            {
                CommentsSince = DateTime.Parse(Request.Headers["X-CommentsDate"]);
                var hours = Int32.Parse(Request.Headers["X-CommentsTime"]);
                CommentsSince = CommentsSince.AddHours(hours);
            }

            if (Request.Headers["X-CommentsSince"] != null) // Comes from QPC when requesting the iPhone version
            {
                CommentsSince = DateTime.Parse(Request.Headers["X-CommentsSince"]);
            }

            if (Request.Headers["X-OnlyTasksWithComments"] != null)
            {
                OnlyTasksWithComments = bool.Parse(Request.Headers["X-OnlyTasksWithComments"]);
            }

            if (Request.Headers["X-IsIncludeDetails"] != null)
            {
                IsIncludeDetails = bool.Parse(Request.Headers["X-IsIncludeDetails"]);
            }

            if (Request.Headers["X-ReportId"] != null)
            {
                ReportId = Convert.ToInt32(Request.Headers["X-ReportId"]);
                //Always true; Convert.ToInt32() is null-safe (returns 0 for null)
                //if (ReportId != null)
                //{
                using (CmdObj c = new CmdObj("QStatus_GetEmailInfo"))
                {
                    c.Add("@UserID", UserId);
                    c.Add("@ReportID", ReportId);
                    c.Add("@StatusReportUserName", SqlDbType.VarChar, ParameterDirection.Output, 50);
                    c.Add("@From", SqlDbType.VarChar, ParameterDirection.Output, 500);
                    c.Add("@AppURL", SqlDbType.VarChar, ParameterDirection.Output, 500);
                    c.ExecuteNonQueryWithOutput();

                    Response.Headers["X-EmailFrom"] = c["@From"].ToString();
                    ReportUsername = c["@StatusReportUserName"].ToString();
                    ToList = c["@From"].ToString();
                    AppUrl = c["@AppURL"].ToString();
                    Request.Headers["X-AppUrl"] = AppUrl;
                }

                var repo = new StatusReportRepository();
                IsAttorneyClient = repo.GetAttorneyClient(ReportId);
                //}
                if (Mode == "all")
                {
                    ReportLines = GetReportLines();
                }
                else
                {
                    ReportLines = GetReportCommentItems();
                }
                if (ReportLines.Count <= 2)
                {
                    Response.Clear();
                    Response.Headers.Add("X-Error", "true");
                    Response.Write("There are no comments to send");
                    Response.Flush();
                    Response.End();
                }
                else
                {
                    WidthCSS = GetWidthCSS(ReportLines);
                    DataBind();
                    Response.Headers.Add("X-SubjectLine", GetSubjectLine());
                }
            }
        }

        private string GetWidthCSS(List<StatusReportLine> reportLines)
        {
            int maxTaskLength = 0;
            foreach (ReportLine line in reportLines)
            {
                if (line.Description != null && line.DueDate != null)
                {
                    if (line.Description.Length > maxTaskLength)
                    {
                        maxTaskLength = line.Description.Length;
                    }
                }
            }
            /*
            .c1 = spacer to the left
            .c2 = Task
            .c3 = Due
            .c4 = Assignees / Controllers
            .c5 = Progress
            .c6 = Reply
            */
            if (maxTaskLength <= 50)
            {
                return ".c1 { width: 2%; } .c2 { width: 20%; } .c3 { width: 5%; } .c4 { width: 5%; } ";
            }
            else if (maxTaskLength <= 100)
            {
                return ".c1 { width: 2%; } .c2 { width: 30%; } .c3 { width: 5%; } .c4 { width: 5%; } ";
            }
            else
            {
                return ".c1 { width: 2%; } .c2 { width: 40%; } .c3 { width: 5%; } .c4 { width: 5%; } ";
            }
        }

        public List<StatusReportLine> GetReportLines()
        {
            var report = QProcess.Cache.CurrentCache.GetReport(UserId, ReportId, IsArchive, timeZones: TimeZones);
            LinkedList<StatusReportLine> lines = new LinkedList<StatusReportLine>(report.ReportLines);
            LinkedListNode<StatusReportLine> line = lines.First;
            while (line != null)
            {
                // Filter down the comments
                if (line.Value.Comments != null)
                {
                    line.Value.Comments = (from StatusReportLine.Comment c in line.Value.Comments where c.Date >= CommentsSince select c).ToList();
                }

                // If this is a task, and it doesn't have visible comments, remove it from the list if we're only showing tasks with comments.
                if (OnlyTasksWithComments && line.Value.Description != "General Comments" && line.Value.LineType == ReportLine.Type.Task && (line.Value.Comments == null || (line.Value.Comments != null && line.Value.Comments.Count == 0)))
                {
                    // Get rid of the comments line to go with this task if there is one
                    if (line.Next.Value.LineType == ReportLine.Type.Comments && line.Next.Value.Description == line.Value.Description)
                    {
                        lines.Remove(line.Next);
                    }

                    // Back up a line and remove this line
                    line = line.Previous;
                    lines.Remove(line.Next);

                    // We may have just deleted the last task in a section, if so get rid of the section header (this node and the next one) and footer (two nodes forward)
                    if (line.Value.LineType == ReportLine.Type.Headings && line.Next.Value.LineType == ReportLine.Type.Ender)
                    {
                        // Back up two lines, and remove the footer, headings, and header
                        line = line.Previous.Previous;
                        lines.Remove(line.Next.Next.Next);
                        lines.Remove(line.Next.Next);
                        lines.Remove(line.Next);
                    }
                }
                line = line.Next;
            }
            return lines.ToList();
        }

        private List<StatusReportLine> GetReportCommentItems()
        {
            StatusReportRepository repo = new StatusReportRepository();

            List<ReportCommentItems> reportItems = null;
            List<StatusReportLine> reportLines = new List<StatusReportLine>();

            var commentArray = CommentIds == null ? null : CommentIds.ToArray();

            if (Mode == "report")
            {
                reportItems = repo.GetReportLatestUrgent(UserId, ReportId, timeZones:TimeZones);
            }
            else if (Mode == "comments")
            {
                reportItems = repo.GetLatestCommentedReports(UserId, ReportId, null, commentArray, false, CommentsSince, TimeZones);
            }
            else if (Mode == "todays-comments")
            {
                reportItems = repo.GetTodaysCommentedReports(UserId, ReportId, null, null, false, TimeZones);
            }

            foreach (var item in reportItems)
            {
                var reportLine = new StatusReportLine(item, UserId);
                if (item.ID.HasValue)
                {
                    var comments = repo.GetLatestComments(UserId, item.ID.Value, ReportId, CommentsSince);
                    foreach (var comment in comments.Where(c=> commentArray == null || commentArray.Contains(c.Id)))
                    {
                        if (reportLine.Comments == null)
                            reportLine.Comments = new List<StatusReportLine.Comment>();
                        reportLine.Comments.Add(new StatusReportLine.Comment(comment));
                    }
                }
                reportLines.Add(reportLine);
            }

            return reportLines;
        }

        private string GetSubjectLine()
        {
            string prefix = "";
            if (IsAttorneyClient)
            {
                prefix = "ATTORNEY CLIENT PRIVILEGED - ";
            }
            switch (Mode)
            {
                case "all":
                    return prefix + ReportLines[0].Description;
                case "report":
                    using (CmdObj c = new CmdObj("QStatus_GetUrgentCommentsSubjectLine"))
                    {
                        c.Add("@UserID", UserId);
                        c.Add("@ReportID", ReportId);
                        c.Add("@Subject", SqlDbType.VarChar, null, ParameterDirection.Output, 500);
                        c.ExecuteNonQueryWithOutput();
                        return prefix + c["@Subject"].ToString();
                    }
                case "todays-comments":
                    using (CmdObj c = new CmdObj("QStatus_GetTodaysCommentsSubjectLine"))
                    {
                        c.Add("@UserID", UserId);
                        c.Add("@ReportID", ReportId);
                        c.Add("@Subject", SqlDbType.VarChar, null, ParameterDirection.Output, 500);
                        c.ExecuteNonQueryWithOutput();
                        return prefix + c["@Subject"].ToString();
                    }
                case "comments":
                    using (CmdObj c = new CmdObj("QStatus_GetLatestCommentsSubjectLine"))
                    {
                        c.Add("@UserID", UserId);
                        c.Add("@ReportID", ReportId);
                        c.Add("@Subject", SqlDbType.VarChar, null, ParameterDirection.Output, 500);
                        c.ExecuteNonQueryWithOutput();
                        return prefix + c["@Subject"].ToString();
                    }
                default:
                    return prefix;
            }
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

