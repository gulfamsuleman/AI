using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web.UI.WebControls;

namespace QProcess
{

    public partial class PrintTasks : System.Web.UI.Page
    {
        protected string marginTop = "0px";
        protected string marginLeft = "0px";
        protected string htmlData = string.Empty;
        protected string overdueTasksHtmlData = string.Empty; //Added by Venkat on 12/16/2016
        protected string reqStartDate = string.Empty;
        protected string fontSize = "12px";

        string[] users;
        string reqEndDate = string.Empty;
        ChecklistRepository checklistRepo = null;
        CalendarRepository calRepo = null;

        protected void Page_Load(object sender, EventArgs e)
        {
            // string[] users = Request.QueryString["users"].Split(',');
            var userString = Request.QueryString["users"];
            if (userString == null)
                Response.Write("A user list is required to view this report. ");
            else
                users = userString.Split(',');

            reqStartDate = Request.QueryString["startDate"];
            if (reqStartDate == null)
                Response.Write("A start date is required to view this report. ");

            if (userString == null || reqStartDate == null) return;

            /*if (DateTime.Parse(reqStartDate) < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date)
            {
                reqStartDate = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date.ToString();
            }*/
            reqEndDate = DateTime.Parse(reqStartDate).AddDays(1).ToString();
            var sb = new StringBuilder();
            sb.Append("<div style='display:inline-block;width:50%;vertical-align:top;'>");
            //var checklistRepo = new ChecklistRepository();
            checklistRepo = new ChecklistRepository();
            calRepo = new CalendarRepository();

            string startDate = DateTime.Parse(reqStartDate).ToString();
            string endDate = DateTime.Parse(reqEndDate).ToString();

            var consoliCheckList = new List<List<CalendarChecklist>>();
            var overdueList = new List<List<CalendarChecklist>>();

            for (int i = 0; i < users.Length; i++)
            {
                List<CalendarChecklist> checklist = calRepo.GetChecklists(Int32.Parse(users[i]), new[] { 0 }, false, DateTime.Parse(startDate), DateTime.Parse(endDate))
                  .Where(c => ((c.Active) && (!(c.IsAlert)) && (c.TaskStage == TaskStage.Current)))
                  .GroupBy(c => new
                  {
                      c.ChecklistName,
                      c.PendingChange,
                      c.DueTime
                  })
                  .Select(c => c.FirstOrDefault())
                  .OrderBy(c => c.ChecklistName)
                  .ToList();
                List<CalendarChecklist> overdue = checklist.Where(c => c.DueTime < DateTime.Parse(startDate)).ToList();
                checklist = checklist.Where(c => c.DueTime >= DateTime.Parse(startDate)).GroupBy(c => new { c.ChecklistName }).Select(c => c.FirstOrDefault()).ToList();

                if (checklist.Count > 0)
                {
                    checklist[0].Assignees = new UserRepository().GetUserName(Int32.Parse(users[i]));
                    checklist[0].Id = Int32.Parse(users[i]); //using this to store UserId here
                    consoliCheckList.Add(checklist);
                }

                if (overdue.Count > 0)
                {
                    overdue[0].Assignees = new UserRepository().GetUserName(Int32.Parse(users[i]));
                    overdue[0].Id = Int32.Parse(users[i]); //using this to store UserId here
                    overdueList.Add(overdue);
                }

            }

            consoliCheckList = consoliCheckList.OrderByDescending(checkList => checkList.Count()).ToList();

            fontSize = "12px";

            if (consoliCheckList.Count > 0)
            {
                sb.Append("<div style=text-align:center;font-weight:bold;font-size:25px;>" + DateTime.Parse(startDate).DayOfWeek + "(" + DateTime.Parse(startDate).ToShortDateString() + ")" + "</div>");
            }

            sb.Append("<div class='grid break' data-masonry='{ itemSelector:.grid-item, columnWidth: 0 }' style='width:950px;font-size:" + fontSize + "'>");

            for (int i = 0; i < consoliCheckList.Count; i++)
            {
                var checkList = consoliCheckList[i];
                if (checkList.Count > 0)
                {
                    //string backgroundColor = "lightblue";
                    string backgroundColor = new UserRepository().GetPrintBackgroundColor(checkList[0].Id);

                    sb.Append("<div class='grid-item grid-item--width3' style=font-weight:bold;background-color:" + backgroundColor + ">");
                    sb.Append("<div style='text-align:center; color:white; background-color:black;padding:2px; font-size: 20px; font-weight: bold;' >" + checkList[0].Assignees + "</div>");
                    for (int j = 0; j < checkList.Count; j++)
                    {
                        sb.Append("<div style='border-bottom:1px solid black;padding:2px;'>");
                        sb.Append(checkList[j].ChecklistName);
                        if (checkList[j].PendingChange)
                        {
                            sb.Append("  <i class='fa fa-forward'></i>");
                        }
                        sb.Append("</div>");

                    }
                    sb.Append("</div>");
                }

            }
            sb.Append("</div>");

            sb.Append("</div><div style='display:inline-block;width:50%;vertical-align:top;'>");
            sb.Append(GetOverdueTasks(overdueList));
            sb.Append(GetNATasks());
            sb.Append("</div>");

            htmlData = sb.ToString();

        }

        public string GetOverdueTasks(List<List<CalendarChecklist>> consoliCheckList)
        {

            var sb = new StringBuilder();
            string daysoverdue = "";
            string origdaysoverdue = "";

            if (consoliCheckList.Count > 0)
            {
                sb.Append("<div style =text-align:center;font-weight:bold;font-size:25px;>Tasks Prior To " + DateTime.Parse(reqStartDate).DayOfWeek + "(" + DateTime.Parse(reqStartDate).ToShortDateString() + ")" + "</div>");
            }

            consoliCheckList = consoliCheckList.OrderByDescending(checkList => checkList.Count()).ToList();

            fontSize = "12px";

            sb.Append("<div class='grid break' data-masonry='{ itemSelector:.grid-item, columnWidth: 0 }' style='width:950px;font-size:" + fontSize + "'>");

            for (int i = 0; i < consoliCheckList.Count; i++)
            {
                var checkList = consoliCheckList[i];
                if (checkList.Count > 0)
                {
                    string backgroundColor = new UserRepository().GetPrintBackgroundColor(checkList[0].Id);

                    sb.Append("<div class='grid-item grid-item--width3' style=font-weight:bold;background-color:" + backgroundColor + ">");
                    sb.Append("<div style='text-align:center; color:white; background-color:black; padding:2px; font-size: 20px; font-weight: bold;' >" + checkList[0].Assignees + "</div>");
                    for (int j = 0; j < checkList.Count; j++)
                    {
                        daysoverdue = (QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date - checkList[j].DueTime.Date).Days.ToString();
                        origdaysoverdue = (QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().Date - checkList[j].OriginalDeadline.Date).Days.ToString();
                        if (daysoverdue != origdaysoverdue)
                        {
                            daysoverdue = daysoverdue + "," + origdaysoverdue;
                        }
                        sb.Append("<div style='border-bottom:1px solid black;padding:2px;'>");
                        sb.Append("(" + daysoverdue + ") ");
                        sb.Append(checkList[j].ChecklistName);
                        if (checkList[j].PendingChange)
                        {
                            sb.Append("  <i class='fa fa-forward'></i>");
                        }
                        sb.Append("</div>");
                    }
                    sb.Append("</div>");
                }

            }
            sb.Append("</div>");

            return sb.ToString();
        }

        public string GetNATasks()
        {

            var sb = new StringBuilder();


            var consoliCheckList = new List<List<Checklist>>();

            var consolOverDueInfo = new List<Checklist>();
            for (int i = 0; i < users.Length; i++)
            {

                List<Checklist> checklist = checklistRepo.GetNAChecklists(Int32.Parse(users[i]), DateTime.Parse(reqStartDate))
                  .GroupBy(c => new
                  {
                      c.Name
                  })
                  .Select(c => c.FirstOrDefault())
                  .OrderBy(c => c.Name)
                  .ToList();
                if (checklist.Count > 0)
                {
                    checklist[0].Assignees = new UserRepository().GetUserName(Int32.Parse(users[i]));
                    checklist[0].UniqueId = Int32.Parse(users[i]); //using this to store UserId here
                }
                consoliCheckList.Add(checklist);

            }

            consoliCheckList = consoliCheckList.OrderByDescending(checkList => checkList.Count()).ToList();

            fontSize = "12px";

            if (consoliCheckList.Count > 0)
            {
                sb.Append("<div style =text-align:center;font-weight:bold;font-size:25px;>Tasks Marked N/A</div>");
            }

            sb.Append("<div class='grid break' data-masonry='{ itemSelector:.grid-item, columnWidth: 0 }' style='width:950px;font-size:" + fontSize + "'>");

            for (int i = 0; i < consoliCheckList.Count; i++)
            {
                var checkList = consoliCheckList[i];
                if (checkList.Count > 0)
                {
                    string backgroundColor = new UserRepository().GetPrintBackgroundColor(checkList[0].UniqueId);

                    sb.Append("<div class='grid-item grid-item--width3' style=font-weight:bold;background-color:" + backgroundColor + ">");
                    sb.Append("<div style='text-align:center; color:white; background-color:black;padding:2px; font-size: 20px; font-weight: bold;' >" + checkList[0].Assignees + "</div>");
                    for (int j = 0; j < checkList.Count; j++)
                    {
                        sb.Append("<div style='border-bottom:1px solid black;padding:2px;'>" + checkList[j].Name + "</div>");

                    }
                    sb.Append("</div>");
                }

            }
            sb.Append("</div>");

            return sb.ToString();
        }

        public string GetExtendedTasks()
        {

            var sb = new StringBuilder();

            sb.Append("<div style =text-align:center;font-weight:bold;font-size:25px;>Extended Tasks</div>");

            var consoliCheckList = new List<List<Checklist>>();

            var consolOverDueInfo = new List<Checklist>();
            for (int i = 0; i < users.Length; i++)
            {

                List<Checklist> checklist = checklistRepo.GetExtendedChecklists(Int32.Parse(users[i]), DateTime.Parse(reqStartDate))
                  .GroupBy(c => new
                  {
                      c.Name
                  })
                  .Select(c => c.FirstOrDefault())
                  .OrderBy(c => c.Name)
                  .ToList();
                if (checklist.Count > 0)
                {
                    checklist[0].Assignees = new UserRepository().GetUserName(Int32.Parse(users[i]));
                    checklist[0].UniqueId = Int32.Parse(users[i]); //using this to store UserId here
                }
                consoliCheckList.Add(checklist);

            }

            consoliCheckList = consoliCheckList.OrderByDescending(checkList => checkList.Count()).ToList();

            fontSize = "12px";

            sb.Append("<div class='grid break' data-masonry='{ itemSelector:.grid-item, columnWidth: 0 }' style='width:950px;font-size:" + fontSize + "'>");

            for (int i = 0; i < consoliCheckList.Count; i++)
            {
                var checkList = consoliCheckList[i];
                if (checkList.Count > 0)
                {
                    string backgroundColor = new UserRepository().GetPrintBackgroundColor(checkList[0].UniqueId);

                    sb.Append("<div class='grid-item grid-item--width3' style=font-weight:bold;background-color:" + backgroundColor + ">");
                    sb.Append("<div style='text-align:center; color:white; background-color:black;padding:2px;' >" + checkList[0].Assignees + "</div>");
                    for (int j = 0; j < checkList.Count; j++)
                    {
                        sb.Append("<div style='border-bottom:1px solid black;padding:2px;'>" + checkList[j].Name + "</div>");

                    }
                    sb.Append("</div>");
                }

            }
            sb.Append("</div>");

            return sb.ToString();
        }

    }

}
/* Copyright © 2024 Renegade Swish, LLC */

