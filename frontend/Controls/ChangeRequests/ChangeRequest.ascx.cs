using System;
using QProcess.Repositories;
using QProcess.Extensions;
using DataAccessLayer;
using System.Web.UI.WebControls;
using System.Text;

namespace QProcess.Controls
{
    public partial class Controls_ChangeRequests_ChangeRequest : QProcessControl
    {
        public ChangeRequest ChangeRequest { get; set; }
        public ChangeRequestRepository Repository { get; set; }
        public bool CanApprove { get { return CurrentSession.QUser?.Id != ChangeRequest.RequestingUser; } }
        public Repeater rptHistory { get; set; }
        public string ChangeRequestPanelFont { get; set; }

        public Controls_ChangeRequests_ChangeRequest()
        {
            rptHistory = new Repeater();
        }
        protected void Page_Load(object sender, EventArgs e)
        {
            using (var db = new DBCommand("QCheck_Approval_DeadlineHistory"))
            {
                db.Add("@ChangeID", ChangeRequest.ID);
                rptHistory.DataSource = db.ExecuteDataSet();
                rptHistory.DataBind();
            }

            var userRepo = new UserRepository();
            ChangeRequestPanelFont = userRepo.GetPreference(CurrentSession.QUser.Id, "PriorityFonts");

        }

        protected string ChangRequestFormattedName()
        {
            var returnString = "";
            var tempLegendString = new StringBuilder("");

            if (ChangeRequest.DeadlineExtensionCompleted)
            {
                tempLegendString.Append($"<span style=\"color: darkgreen; font-weight: bold;\" title=\"COMPLETED ON:");
                tempLegendString.Append(ChangeRequest.CompletedDate);
                tempLegendString.Append("\">[TC]</span>");
            }
            if (ChangeRequest.ExtensionDays > 30)
                tempLegendString.Append("<span style=\"color: red; font-weight: bold;\" title=\"EXTENDED OVER 30 DAYS\">[LTE]</span>");
            if (ChangeRequest.ExtensionCount > 3)
                tempLegendString.Append("<span style=\"font-weight: bold; color: darkred;\" title=\"EXTENDED OVER THREE TIMES\">[3XE]</span>");
            if (ChangeRequest.DatePassedMessage.Length > 0)
                tempLegendString.Append("<span style=\"font-weight: bold; color: darkmagenta;\" title=\"REQUESTED DEADLINE PASSED\">[RDP]</span>");

            returnString += tempLegendString;
            returnString += ChangeRequest.ChecklistName;

            return returnString;

        }

        protected string ChangeRequestOverview()
        {
            int totalItems = ChangeRequest.ChangedItems.Count + ChangeRequest.AddedItems.Count + ChangeRequest.RemovedItems.Count;
            string s = "";

            if (totalItems == 1)
            {
                s = ChangeRequest.ChangedItems[0].Requested.ToString();
                /*if (ChangeRequest.ChangedItems.Count == 1)
                {
                    s = "Change " + ChangeRequest.ChangedItems[0].ItemName.ToLower() + " from " + ChangeRequest.ChangedItems[0].Current + " to " + ChangeRequest.ChangedItems[0].Requested;
                }
                if (ChangeRequest.AddedItems.Count == 1)
                {
                    s = "Add " + ChangeRequest.AddedItems[0].ItemName.ToLower() + " " + ChangeRequest.AddedItems[0].Requested;
                }
                if (ChangeRequest.RemovedItems.Count == 1)
                {
                    s = "Remove " + ChangeRequest.RemovedItems[0].ItemName.ToLower() + " " + ChangeRequest.RemovedItems[0].Requested;
                }*/
            }
            else
            {
                if (ChangeRequest.ChangedItems.Count == 0 && ChangeRequest.AddedItems.Count == 1 && ChangeRequest.RemovedItems.Count == 1)
                {
                    if (ChangeRequest.AddedItems[0].ItemName == ChangeRequest.RemovedItems[0].ItemName)
                    {
                        //s = ChangeRequest.ChangedItems[0].Requested.ToString();
                        s = "Change " + ChangeRequest.RemovedItems[0].ItemName.ToLower() + " from " + ChangeRequest.RemovedItems[0].Requested + " to " + ChangeRequest.AddedItems[0].Requested;
                    }
                    else
                    {
                        s = "Multiple changes requested";
                    }
                }
                else
                {
                    s = "Multiple changes requested";
                }

            }

            if (ChangeRequest.Comment.Length > 0)
            {
                s += " - " + ChangeRequest.Comment;
            }

                return s;

        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

