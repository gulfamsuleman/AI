using QProcess.Extensions;
using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Web.UI;
using System.Web.UI.HtmlControls;
using System.Web.UI.WebControls;

namespace QProcess
{

    public partial class DepartmentTasks : Page
    {
        protected List<String> MasonItems;
        protected List<String> JustinItems;
        protected List<String> TrevorItems;
        protected List<String> JosephItems;
        protected List<String> StephenItems;
        protected string marginTop = "0px";
        protected string marginLeft = "0px";
        protected string htmlData = string.Empty;
        protected string reqStartDate = string.Empty;
        protected string fontSize = "24px";

        string[] users;
        string reqEndDate = string.Empty;
        ChecklistRepository checklistRepo = null;
        UserRepository userRepo = null;

        protected void Page_Load(object sender, EventArgs e)
        {
            /* Add firm specific CSS */
            string firmKey = ConfigurationManager.AppSettings["Firm"];
            string cssPath = $"/Content/{firmKey}/ColorScheme.css";

            // Add the CSS link dynamically
            Literal cssLink = new Literal
            {
                Text = $"<link rel='stylesheet' type='text/css' href='{cssPath}' />"
            };
            Page.Header.Controls.Add(cssLink);

            string groupID = Request["group"];
            if (!(Int32.TryParse(groupID, out int gID)))
            {
                Response.Redirect("calendar.aspx");
            }
            userRepo = new UserRepository();

            int supervisorGroupID = userRepo.GetGroupIDFromName("ExcludeDisplay");
            List<User> supervisorList = userRepo.GetGroupUsers(supervisorGroupID);

            List<User> userList = userRepo.GetGroupUsers(groupID.ToIntEx().Value);
            List<string> userString = new List<String>();
            foreach (User u in userList)
            {
                userString.Add(u.Id.ToString());
            }
            users = userString.ToArray();
            reqStartDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date.ToString();
            reqEndDate = DateTime.Parse(reqStartDate).AddDays(1).ToString();
            var sb = new StringBuilder();
            checklistRepo = new ChecklistRepository();

            string startDate = reqStartDate;
            string endDate = reqEndDate;
            int totalchecklistsandemployees = 0;
            string gridStyle = "grid1";

            var consoliCheckList = new List<List<Checklist>>();
            for (int i = 0; i < users.Length; i++)
            {
                int userID = Int32.Parse(users[i]);
                int supervisorIndex = supervisorList.FindIndex(s => s.Id == userID);

                if (supervisorIndex == -1)//not a supervisor
                {
                    List<Checklist> checklist = checklistRepo.GetChecklists(userID, DateTime.Parse(startDate), DateTime.Parse(endDate), 0, null, null)
                                                           .Where(c => !(c.IsCompleted))
                                                           .Where(c => !(c.Name.ToLower().StartsWith("confidential:")))
                                                           .ToList();

                    List<Checklist> overduechecklist = checklistRepo.GetOverdueChecklists(userID, DateTime.Parse(reqStartDate))
                                                            .Where(c => !(c.Name.ToLower().StartsWith("confidential:")))
                                                            .ToList();

                    //combine the checklist and overduechecklist lists into a list called allChecklists, order by assignee count then by due date
                    List<Checklist> allChecklists = checklist.Concat(overduechecklist).OrderBy(c => (c.AssigneeCount > 1)).ThenBy(c => c.DueDate).ToList();

                    if (allChecklists.Count > 0)
                    {
                        allChecklists[0].Assignees = new UserRepository().GetUserName(userID);
                        allChecklists[0].UniqueId = userID;//using this to store UserId here
                    }
                    consoliCheckList.Add(allChecklists);
                    totalchecklistsandemployees += allChecklists.Count;
                }
            }

            consoliCheckList = consoliCheckList.OrderByDescending(checkList => checkList.Count()).ToList();
            totalchecklistsandemployees += consoliCheckList.Count;
            totalchecklistsandemployees += consoliCheckList.Count - 1; // for spacers

            sb.Append("<div class='grid' style='font-weight:bold;font-size:32px;'>");

            for (int i = 0; i < consoliCheckList.Count; i++)
            {
                var checkList = consoliCheckList[i];
                if (checkList.Count > 0)
                {
                    if (i > 0)
                    {
                        sb.Append("<div>&nbsp;</div>");
                    }
                    sb.Append("<div class='header-item " + gridStyle + "' >" + checkList[0].Assignees + "</div>");
                    for (int j = 0; j < checkList.Count; j++)
                    {
                        string checklistname = checkList[j].Name;
                        string assigneesCountString = "";
                        string pendingString = "";

                        bool isOverdue = checkList[j].DueDate < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow();
                        bool isReview = checklistname.Trim().EndsWith("review", StringComparison.OrdinalIgnoreCase);

                        //add arrows for tasks that have extensions pending
                        if (checkList[j].PendingChange)
                        {
                            pendingString = "<span><i class=\"fa fa-forward\"></i></span> ";
                        }
                        if (checkList[j].AssigneeCount > 1) { assigneesCountString = "multi"; }

                        /* Marlen: Checklists ending in review = green, if also overdue then = brown */
                        if (isOverdue && isReview)
                        {
                            sb.Append("<div class='grid-item gridReviewOverdue " + gridStyle + " " + assigneesCountString + "'>" + pendingString + "OVERDUE -- " + checklistname + "</div>");
                        }
                        else if (isOverdue)
                        {
                            sb.Append("<div class='grid-item gridoverdue " + gridStyle + " " + assigneesCountString + "'>" + pendingString + "OVERDUE -- " + checklistname + "</div>");
                        }
                        else if (isReview)
                        {
                            sb.Append("<div class='gridReview grid-item " + gridStyle + " " + assigneesCountString + "'>" + pendingString + checklistname + "</div>");
                        }
                        else
                        {
                            sb.Append("<div class='grid-item " + gridStyle + " " + assigneesCountString + "'>" + pendingString + checklistname + "</div>");
                        }
                    }
                }
            }
            sb.Append("</div>");

            htmlData = sb.ToString();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

