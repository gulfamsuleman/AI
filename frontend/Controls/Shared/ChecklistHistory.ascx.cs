using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI.WebControls;
using QProcess.Extensions;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_Shared_ChecklistHistory : System.Web.UI.UserControl
    {
        public Checklist Checklist { get; set; }
        public DateTime LastViewed { get; set; }
        public bool IsMyTasks { get; set; }
        protected bool IsCompletable { get; set; }
        protected int ChecklistId { get; set; }
        protected int UniqueId { get; set; }
        protected TaskStage TaskStage { get; set; }
        protected bool IsDaily { get; set; }
        protected int UserId { get; set; }
        public int? PassedInId { get; set; }
        protected HiddenField HiddenTaskId;

        // Ensure the CommentHistory control is defined
        protected Literal CommentHistory;

        public string CompletionCssClass
        {
            get
            {
                if (Checklist.TaskStage == TaskStage.Future)
                    return "future";
                if (Checklist.IsCompleted)
                    return "completed";
                if (Checklist.DueDate < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow())
                    return "overdue";
                return "normal";
            }
        }

        public string CompletionString
        {
            get
            {
                if (Checklist.TaskStage == TaskStage.Future)
                    return "Due";
                if (Checklist.IsCompleted)
                    return "Completed";
                if (Checklist.DueDate < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow())
                    return "Overdue";
                return "Due";
            }
        }

        public DateTime DisplayDate
        {
            get
            {
                return Checklist.IsCompleted ? Checklist.CompletedOn.Value : Checklist.DueDate;
            }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            var checklistRepo = new ChecklistRepository();

            UniqueId = 0;
            ChecklistId = 0;

            // Check if PassedInId is set
            if (!string.IsNullOrWhiteSpace(Request.QueryString["uniqueId"]))
            {
                UniqueId = Convert.ToInt32(Request.QueryString["uniqueId"]);
            }
            else if (!string.IsNullOrWhiteSpace(Request.Form["uniqueId"]))
            {
                UniqueId = Convert.ToInt32(Request.Form["uniqueId"]);
            }
            else if (!string.IsNullOrWhiteSpace(Request.Form["checklistId"]))
            {
                ChecklistId = Convert.ToInt32(Request.Form["checklistId"]);
            }

            if (UniqueId != 0 || ChecklistId != 0)
            {
                TaskStage = TaskStage.Current; // Assuming default TaskStage, modify as needed
                if (ChecklistId != 0)
                {
                    // Get the checklist by its ID
                    int ActiveChecklistId = checklistRepo.GetActiveChecklistIdByChecklistId(ChecklistId);
                    if (ActiveChecklistId != 0)
                    {
                        Checklist = checklistRepo.GetSingleChecklist(QProcess.Session.CurrentSession.QUser.Id, TaskStage, ActiveChecklistId);
                    }
                }
                else
                {
                    // Get the checklist by its unique ID and task stage
                    Checklist = checklistRepo.GetSingleChecklist(QProcess.Session.CurrentSession.QUser.Id, TaskStage, UniqueId);
                }
                IsMyTasks = true;
            }
            //// Headers - used by JQueryHandler and other dynamic-loading features.
            //else if (Context.Request.Headers["X-UniqueId"] != null && Context.Request.Headers["X-TaskStage"] != null)
            //{
            //    UniqueId = Convert.ToInt32(Context.Request.Headers["X-UniqueId"]);
            //    TaskStage = (Convert.ToString(Context.Request.Headers["X-TaskStage"])).FromString<TaskStage>();
            //    Checklist = checklistRepo.GetSingleChecklist(QProcess.Session.CurrentSession.QUser.Id, TaskStage, UniqueId);
            //    IsMyTasks = true;
            //}
            //// Query Strings - used in "permalinks" i.e. assignment emails.
            //else if (Context.Request.QueryString.AllKeys.Contains("checklistId") && Context.Request.QueryString.AllKeys.Contains("taskStage"))
            //{
            //    if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            //    UniqueId = Convert.ToInt32(Context.Request.QueryString["checklistId"]);
            //    TaskStage = (Convert.ToString(Context.Request.QueryString["taskStage"])).FromString<TaskStage>();
            //    Checklist = checklistRepo.GetSingleChecklist(QProcess.Session.CurrentSession.QUser.Id, TaskStage, UniqueId);
            //    IsMyTasks = false;
            //}
            //else if (Context.Request.QueryString.AllKeys.Contains("id") && Context.Request.QueryString.AllKeys.Contains("type"))
            //{
            //    if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            //    UniqueId = Convert.ToInt32(Context.Request.QueryString["id"]);
            //    TaskStage = (Convert.ToString(Context.Request.QueryString["type"])).FromString<TaskStage>();
            //    Checklist = checklistRepo.GetSingleChecklist(QProcess.Session.CurrentSession.QUser.Id, TaskStage, UniqueId);
            //    IsMyTasks = false;
            //}

            if (Checklist != null)
            {
                IsDaily = Checklist.IsDaily;

                if (Checklist?.Items == null || !Checklist.Items.Any(i => i.ItemTypeString == "Checkbox"))
                    IsCompletable = true;
                else
                {
                    IsCompletable = Checklist.Items.Where(i => i.ItemTypeString == "Checkbox").All(i => i.IsItemComplete);
                    if (!IsCompletable && Checklist.Items.Where(i => i.ItemTypeString == "Checkbox").Count() <= 1)
                        IsCompletable = true;
                }

                List<CommentHistoryList> reportLines = checklistRepo.GetCommentsAllHistory(Checklist.ChecklistId, UniqueId, QProcess.Session.CurrentSession.QUser.Id);
                CommentHistory.Text = GenerateCommentHistoryHtml(reportLines); // Set the Literal control's Text property
            }
            else
            {
                Checklist = new Checklist();
            }
        }

        public string GenerateCommentHistoryHtml(List<CommentHistoryList> comments)
        {
            var sb = new StringBuilder();

            var relatedComments = comments.Where(c => c.IsRelated == true).ToList();
            var mainComments = comments.Where(c => c.IsRelated == false).ToList();

            // Related Comments
            if (relatedComments.Any())
            {
                sb.AppendLine("<span class='bold' style='color:midnightblue; text-decoration:underline;'>Related:</span><br/>");

                foreach (var comment in relatedComments)
                {
                    //var color = GetColor(0); // Add report coloring potentially
                    var tabs = new string('\t', comment.TabIn).Replace("\t", "<span class='tab'></span>");
                    sb.AppendLine($"{tabs}<span style='color:midnightblue'><span class='bold'>[{comment.dt:MM/dd/yyyy}] [{comment.Initials}]</span> {comment.Comments}</span><br/>");
                }

                sb.AppendLine("<div style='margin:4px 0; border-top: 2px solid black;'></div>");
            }

            // Main Comments
            foreach (var comment in mainComments)
            {
                var color = GetColor(0); // Add report coloring potentially
                var tabs = new string('\t', comment.TabIn).Replace("\t", "<span class='tab'></span>");
                sb.AppendLine($"{tabs}<span style='color:{color}'><span class='bold'>[{comment.dt:MM/dd/yyyy}] [{comment.Initials}]</span> {comment.Comments}</span><br/>");
            }

            return $"<pre>{sb}</pre>";
        }


        private string GetColor(int colorNum)
        {
            if (colorNum == 0)
                return "black";
            else if (colorNum == 3)
                return "green";
            else if (colorNum == 50)
                return "purple";
            else
                return "red";
        }




        //public List<StatusReportLine> GetReportLines()
        //{
        //    var report = QProcess.Cache.CurrentCache.GetReport(UserId, ReportId, IsArchive, timeZones: TimeZones);
        //    LinkedList<StatusReportLine> lines = new LinkedList<StatusReportLine>(report.ReportLines);
        //    LinkedListNode<StatusReportLine> line = lines.First;
        //    while (line != null)
        //    {
        //        // Filter down the comments
        //        if (line.Value.Comments != null)
        //        {
        //            line.Value.Comments = (from StatusReportLine.Comment c in line.Value.Comments where c.Date >= CommentsSince select c).ToList();
        //        }

        //        // If this is a task, and it doesn't have visible comments, remove it from the list if we're only showing tasks with comments.
        //        if (OnlyTasksWithComments && line.Value.Description != "General Comments" && line.Value.LineType == ReportLine.Type.Task && (line.Value.Comments == null || (line.Value.Comments != null && line.Value.Comments.Count == 0)))
        //        {
        //            // Get rid of the comments line to go with this task if there is one
        //            if (line.Next.Value.LineType == ReportLine.Type.Comments && line.Next.Value.Description == line.Value.Description)
        //            {
        //                lines.Remove(line.Next);
        //            }

        //            // Back up a line and remove this line
        //            line = line.Previous;
        //            lines.Remove(line.Next);

        //            // We may have just deleted the last task in a section, if so get rid of the section header (this node and the next one) and footer (two nodes forward)
        //            if (line.Value.LineType == ReportLine.Type.Headings && line.Next.Value.LineType == ReportLine.Type.Ender)
        //            {
        //                // Back up two lines, and remove the footer, headings, and header
        //                line = line.Previous.Previous;
        //                lines.Remove(line.Next.Next.Next);
        //                lines.Remove(line.Next.Next);
        //                lines.Remove(line.Next);
        //            }
        //        }
        //        line = line.Next;
        //    }
        //    return lines.ToList();
        //}


    }
}
