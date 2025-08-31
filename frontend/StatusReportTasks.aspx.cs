using QProcess.Extensions;
using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess
{

    public partial class StatusReportTasks : Page
    {
        protected string htmlData = string.Empty;
        protected string reqStartDate = string.Empty;

        string[] users;
        string reqEndDate = string.Empty;
        ChecklistRepository checklistRepo = null;
        UserRepository userRepo = null;

        protected void Page_Load(object sender, EventArgs e)
        {            
            string id = Request["id"];
            if (!(Int32.TryParse(id, out int gID)))
            {
                Response.Redirect("calendar.aspx");
            }
            userRepo = new UserRepository();

            reqStartDate = DateTime.Today.ToString();
            reqEndDate = DateTime.Parse(reqStartDate).AddDays(1).ToString();
            var sb = new StringBuilder();

            checklistRepo = new ChecklistRepository();

            string startDate = reqStartDate;
            string endDate = reqEndDate;
            int totalchecklistsandemployees = 0;
            string gridStyle = "grid1";


            var consoliCheckList = new List<List<Checklist>>();

            List<Checklist> checklists = checklistRepo.GetChecklistsByStatusReportId(id.ToIntEx().Value)
                                                    .Where(c => !(c.IsCompleted))
                                                    .Where(c => !(c.Name.ToLower().StartsWith("confidential:")))
                                                    .OrderBy(x => x.DueDate).ThenBy(x => x.Name)
                                                    .ToList();

            consoliCheckList.Add(checklists);
            totalchecklistsandemployees += checklists.Count;

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
                    sb.Append("<div class='header-item " + "' >" + checkList[0].StatusReportName + "</div><div style='width: 100%; height: 40px;'>&nbsp;</div>");
                    for (int j = 0; j < checkList.Count; j++)
                    {
                        string checklistname = checkList[j].Name;
                        string pendingString = "";
                        string dueDatestring = checkList[j].DueDate == null ? "(Unknown)" : "(" + checkList[j].DueDate.ToString("MM/dd") + ")";
                        string comments = checkList[j].Comments == null ? "" : "<span style='color: #6a6a6a; font-size: 21px;'>" + checkList[j].Comments.Replace("[-]", "<br />&nbsp;&nbsp;&nbsp;&nbsp;- ") + "</span>";

                        //add arrows for tasks that have extensions pending
                        if (checkList[j].PendingChange)
                        {
                            pendingString = "<span><i class=\"fa fa-forward\"></i></span> ";
                        }

                        if (checkList[j].DueDate < DateTime.Now)
                        {
                            sb.Append("<div class='gridoverdue grid-item " + gridStyle + "'>" + pendingString + "OVERDUE -- " + checklistname + " " + dueDatestring + comments + "</div>");
                        }
                        else
                        {
                            sb.Append("<div class='grid-item " + gridStyle + "'>" + pendingString + checklistname + " " + dueDatestring + comments + "</div>");
                        }
                    }
                }
            }
            sb.Append("</div>");

            htmlData = sb.ToString();
        }
    }
}