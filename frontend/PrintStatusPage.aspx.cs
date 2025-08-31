using System;
using System.Web;
using QProcess.Repositories;
using DataAccessLayer;
using QProcess.Extensions;
using System.Data;

namespace QProcess
{

    public partial class PrintStatusPage : SessionPage
    {
        protected string data = "";
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            var userRepo = new UserRepository();
            var statusRepo = new StatusReportRepository();
            int userId = CurrentSession.QUser.Id;
            var lastReportPreferenceString = userRepo.GetPreference(userId, "LastPrintableReport");

            int lastReport;
            int reportId = Int32.TryParse(lastReportPreferenceString, out lastReport) ? lastReport : statusRepo.GetDefaultReport(userId);

            DataSet ds;
            var sb = new System.Text.StringBuilder();

            using (var db = new DBCommand("QStatus_GetStatusReportSummary"))
                ds = db.Add("@UserID", userId).Add("@ReportID", reportId).ExecuteDataSet();

            if (ds.Tables.Count == 0) return;
            if (ds.Tables[0].Rows.Count == 0) return;

            foreach (DataRow row in ds.Tables[0].Rows)
            {
                switch (row["Type"].ToBlank())
                {
                    case "Header Row":
                        sb.Append("<h1>" + row["Description"].ToBlank() + "</h1>");
                        break;
                    case "Sub Header Row":
                        if (row["Description"].ToBlank() != "General Comments")
                            if (row["ID"].ToIntEx() != null)
                                sb.Append("<h2 v='" + row["ID"] + "'>" + row["Description"].ToBlank() + " <span class='no-print'>Remove</span></h2>");
                        break;
                    case "General Comments":
                    case "Completed":
                        break; // ignore for now
                    default:
                        using (var db = new DBCommand("QCheck_GetSingleChecklist"))
                        {
                            var dt = db.Add("@loginID", userId)
                                       .Add("@type", 1)
                                       .Add("@id", row["ID"].ToIntEx().Value)
                                       .ExecuteDataSet().Tables[0];

                            if (dt.Rows.Count > 0)
                            {
                                sb.Append("<div class='task id" + row["TaskType"] + "'>");
                                sb.Append("<span class='taskName' style='font-weight:bold;'><h3>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" + row["Description"].ToBlank() + "</h3></span>");
                                sb.Append("<div><hr><span class='name'>Controllers</span>");
                                sb.Append("<span class='value'>&nbsp;&nbsp;&nbsp;" + dt.Rows[0]["Controllers"].ToBlank() + "</span></div>");
                                sb.Append("<div><span class='name'>Status Reports</span>");
                                sb.Append("<span class='value'>&nbsp;&nbsp;&nbsp;" + StripTagsCharArray(dt.Rows[0]["StatusReportString"].ToBlank().Replace("Status Reports:", "")) + "</span></div>");
                                sb.Append("<div><span class='name'>Assigned To</span>");
                                sb.Append("<span class='value'>&nbsp;&nbsp;&nbsp;" + dt.Rows[0]["Assignees"].ToBlank() + "</span></div>");
                                sb.Append("<div><span class='name'>Created</span>");
                                sb.Append("<span class='value'>&nbsp;&nbsp;&nbsp;" + dt.Rows[0]["CreateDate"].ToDateTimeEx().Value.ToString("MM/dd/yyyy") + "</span><hr></div>");

                                if (dt.Rows[0]["ScheduleString"].ToBlank() != "One Time")
                                {
                                    sb.Append("<div><span class='name'>Schedule</span>");
                                    sb.Append("<span class='value'>" + dt.Rows[0]["ScheduleString"].ToBlank() + "</span></div>");
                                }

                                sb.Append("<div>");
                                foreach (DataRow iRow in dt.Rows)
                                {
                                    if (iRow["ItemType"].ToBlank().ToUpper() == "HEADING")
                                    {
                                        sb.Append("<span class='itm bold'>" + iRow["Text"].ToBlank() + "</span><br>");
                                    }
                                    if (iRow["ItemType"].ToBlank().ToUpper() == "SUB HEADING")
                                    {
                                        sb.Append("<span class='itm'>" + iRow["Text"].ToBlank() + "</span><br>");
                                    }
                                    if (iRow["ItemType"].ToBlank().ToUpper() == "NOTES")
                                    {
                                        sb.Append("<span class='itm' style='font-style:italic;'>" + iRow["Text"].ToBlank() + "</span><br>");
                                    }
                                    if (iRow["ItemType"].ToBlank().ToUpper() == "SPACER")
                                    {
                                        sb.Append("<span class='itm'><BR></span><br>");
                                    }
                                    if (iRow["ItemType"].ToBlank().ToUpper() == "CHECKBOX")
                                    {
                                        sb.Append("<span class='itm'>&#9633; " + iRow["Text"].ToBlank() + "</span><br>");
                                    }
                                }
                                sb.Append("</div></div>");
                            }
                        }
                        break;
                }
            }

            data = sb.ToString();
        }

        public static string StripTagsCharArray(string source)
        {
            char[] array = new char[source.Length];
            int arrayIndex = 0;
            bool inside = false;

            for (int i = 0; i < source.Length; i++)
            {
                char let = source[i];
                if (let == '<')
                {
                    inside = true;
                    continue;
                }
                if (let == '>')
                {
                    inside = false;
                    continue;
                }
                if (!inside)
                {
                    array[arrayIndex] = let;
                    arrayIndex++;
                }
            }
            return new string(array, 0, arrayIndex);
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

