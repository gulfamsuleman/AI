using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess
{

    public partial class PrintTasksTEB : Page
    {
        protected List<String> MasonItems;
        protected List<String> JustinItems;
        protected List<String> TrevorItems;
        protected List<String> JosephItems;
        protected List<String> StephenItems;
        protected string marginTop = "0px";
        protected string marginLeft = "0px";
        protected string htmlData = string.Empty;
        protected string overdueTasksHtmlData = string.Empty;//Added by Venkat on 12/16/2016
        protected string reqStartDate = string.Empty;
        protected string fontSize = "28px";

        string[] users;
        string reqEndDate = string.Empty;
        ChecklistRepository checklistRepo = null;

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
            reqEndDate = DateTime.Parse(reqStartDate).AddDays(1).ToString();
            var sb = new StringBuilder();
            //var checklistRepo = new ChecklistRepository();
            checklistRepo = new ChecklistRepository();
            // var consoliCheckList = new List<List<Checklist>>();
            for (int k = 0; k < 5; k++)
            {
                string startDate = DateTime.Parse(reqStartDate).AddDays(k).ToString();
                string endDate = DateTime.Parse(reqEndDate).AddDays(k).ToString();

                sb.Append("<div style =text-align:center;font-weight:bold;font-size:40px;>" + DateTime.Parse(startDate).DayOfWeek + "(" + DateTime.Parse(startDate).ToShortDateString() + ")" + "</div>");


                var consoliCheckList = new List<List<Checklist>>();
                for (int i = 0; i < users.Length; i++)
                {
                    List<Checklist> checklist = checklistRepo.GetChecklists(Int32.Parse(users[i]), DateTime.Parse(startDate), DateTime.Parse(endDate), 0, null, null)
                                                .OrderBy(c => c.IsCompleted)
                                                .ThenBy(c => c.IsCompleted ? c.CompletedOn : c.DueDate)
                                                .ToList();
                    if (checklist.Count > 0)
                    {
                        checklist[0].Assignees = new UserRepository().GetUserName(Int32.Parse(users[i]));
                        checklist[0].UniqueId = Int32.Parse(users[i]);//using this to store UserId here
                    }
                    consoliCheckList.Add(checklist);


                }

                consoliCheckList = consoliCheckList.OrderByDescending(checkList => checkList.Count()).ToList();

                fontSize = "28px";
                if (consoliCheckList.Count > 0)
                {
                    if (consoliCheckList[0].Count > 40)
                    {
                        fontSize = "18px";
                    }
                    else if (consoliCheckList[0].Count > 30)
                    {
                        fontSize = "23px";
                    }
                }

                sb.Append("<div class='grid break' data-masonry='{ itemSelector:.grid-item, columnWidth: 0 }' style=height:900px;width:2300px;font-size:" + fontSize + ">");

                for (int i = 0; i < consoliCheckList.Count; i++)
                {
                    var checkList = consoliCheckList[i];
                    if (checkList.Count > 0)
                    {
                        //string backgroundColor = "lightblue";
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
            }

            sb.Append(GetOverdueTasks());


            htmlData = sb.ToString();


        }

        public string GetOverdueTasks()
        {

            var sb = new StringBuilder();
            //  sb.Append("<div>Overdue Tasks</div>");
            //  string startDate = DateTime.Parse(reqStartDate).ToString();
            // string endDate = DateTime.Parse(reqEndDate).AddDays(-1).ToString();

            sb.Append("<div style =text-align:center;font-weight:bold;font-size:40px;>Tasks Prior To " + DateTime.Parse(reqStartDate).DayOfWeek + "(" + DateTime.Parse(reqStartDate).ToShortDateString() + ")" + "</div>");


            var consoliCheckList = new List<List<Checklist>>();

            var consolOverDueInfo = new List<Checklist>();
            for (int i = 0; i < users.Length; i++)
            {
                //var overDueInfo = checklistRepo.GetOverdueInfo(Int32.Parse(users[i]));
                //var checkList = new Checklist();
                //checkList.
                // consolOverDueInfo
                List<Checklist> checklist = checklistRepo.GetOverdueChecklists(Int32.Parse(users[i]), DateTime.Parse(reqStartDate))
                                            //.OrderBy(c => c.IsCompleted)
                                            //.ThenBy(c => c.IsCompleted ? c.CompletedOn : c.DueDate)
                                            .ToList();
                if (checklist.Count > 0)
                {
                    checklist[0].Assignees = new UserRepository().GetUserName(Int32.Parse(users[i]));
                    checklist[0].UniqueId = Int32.Parse(users[i]);//using this to store UserId here
                }
                consoliCheckList.Add(checklist);


            }

            consoliCheckList = consoliCheckList.OrderByDescending(checkList => checkList.Count()).ToList();

            fontSize = "28px";
            if (consoliCheckList.Count > 0)
            {
                if (consoliCheckList[0].Count > 40)
                {
                    fontSize = "18px";
                }
                else if (consoliCheckList[0].Count > 30)
                {
                    fontSize = "23px";
                }
            }

            sb.Append("<div class='grid break' data-masonry='{ itemSelector:.grid-item, columnWidth: 0 }' style=height:900px;width:2300px;font-size:" + fontSize + ">");

            for (int i = 0; i < consoliCheckList.Count; i++)
            {
                var checkList = consoliCheckList[i];
                if (checkList.Count > 0)
                {
                    //string backgroundColor = "lightblue";
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

