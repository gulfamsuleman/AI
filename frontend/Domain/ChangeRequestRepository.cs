using QProcess.Domain.Models;
using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Web.UI.WebControls;

namespace QProcess.Repositories
{
    public class ChangeRequestRepository
	{
		public IEnumerable<ChangeRequest> GetUserChangeRequests(int userId, int sort)
		{
			using (var cmd = new CmdObj("QCheck_Approval_GetUserChangeRequests"))
			{
				cmd.Add("@UserId", userId);
                cmd.Add("@Sort", sort);
                var dataSet = cmd.GetDS();
				return dataSet.Tables[0].AsEnumerable().Select(r => new ChangeRequest(r));
			}
		}

		public IEnumerable<ChangeRequest> GetSupervisorChangeRequests(int userId, int sort)
		{
			using (var cmd = new CmdObj("QCheck_Approval_GetSupervisorChangeRequests"))
			{
				cmd.Add("@UserId", userId);
                cmd.Add("@Sort", sort);
                var dataSet = cmd.GetDS();
				return dataSet.Tables[0].AsEnumerable().Select(r => new ChangeRequest(r));
			}
		}

		public IEnumerable<ChangeRequestItem> GetAddedItems(int changeRequestId)
		{
			using (var cmd = new CmdObj("QCheck_Approval_CRAdded"))
			{
				cmd.Add("@ChangeID", changeRequestId);
				var dataSet = cmd.GetDS();
				return dataSet.Tables[0].AsEnumerable().Select(r => new ChangeRequestItem(r));
			}
		}

		public IEnumerable<ChangeRequestItem> GetChangedItems(int changeRequestId)
		{
			using (var cmd = new CmdObj("QCheck_Approval_CRChanged"))
			{
				cmd.Add("@ChangeID", changeRequestId);
				var dataSet = cmd.GetDS();
				return dataSet.Tables[0].AsEnumerable().Select(r => new ChangeRequestItem(r));
			}
		}

		public IEnumerable<ChangeRequestItem> GetRemovedItems(int changeRequestId)
		{
			using (var cmd = new CmdObj("QCheck_Approval_CRRemoved"))
			{
				cmd.Add("@ChangeID", changeRequestId);
				var dataSet = cmd.GetDS();
				return dataSet.Tables[0].AsEnumerable().Select(r => new ChangeRequestItem(r));
			}
		}

        public IEnumerable<ChangeRequestItem> GetAddedItems_NaturalLanguage(int changeRequestId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_CRAdded_Natural"))
            {
                cmd.Add("@ChangeID", changeRequestId);
                var dataSet = cmd.GetDS();
                return dataSet.Tables[0].AsEnumerable().Select(r => new ChangeRequestItem(r));
            }
        }

        public IEnumerable<ChangeRequestItem> GetChangedItems_NaturalLanguage(int changeRequestId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_CRChanged_Natural"))
            {
                cmd.Add("@ChangeID", changeRequestId);
                var dataSet = cmd.GetDS();
                return dataSet.Tables[0].AsEnumerable().Select(r => new ChangeRequestItem(r));
            }
        }

        public IEnumerable<ChangeRequestItem> GetRemovedItems_NaturalLanguage(int changeRequestId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_CRRemoved_Natural"))
            {
                cmd.Add("@ChangeID", changeRequestId);
                var dataSet = cmd.GetDS();
                return dataSet.Tables[0].AsEnumerable().Select(r => new ChangeRequestItem(r));
            }
        }

        public IEnumerable<ChangeRequestAssignmentItem> GetCurrentAssignments(int changeRequestId, bool all)
        {
            using (var cmd = new CmdObj("QCheck_Approval_CurrentAssignments"))
            {
                cmd.Add("@ChangeID", changeRequestId);
                cmd.Add("@ShowAll", all);
                var dataSet = cmd.GetDS();
                return dataSet.Tables[0].AsEnumerable().Select(r => new ChangeRequestAssignmentItem(r));
            }
        }

        public IEnumerable<ChangeRequestChecklistItem> GetCurrentItems(int changeRequestId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_CurrentItems"))
            {
                cmd.Add("@ChangeID", changeRequestId);
                var dataSet = cmd.GetDS();
                return dataSet.Tables[0].AsEnumerable().Select(r => new ChangeRequestChecklistItem(r));
            }
        }

        public IEnumerable<ChangeRequestAssignmentItem> GetRequestedAssignments(int changeRequestId, bool all)
        {
            using (var cmd = new CmdObj("QCheck_Approval_RequestedAssignments"))
            {
                cmd.Add("@ChangeID", changeRequestId);
                cmd.Add("@ShowAll", all);
                var dataSet = cmd.GetDS();
                return dataSet.Tables[0].AsEnumerable().Select(r => new ChangeRequestAssignmentItem(r));
            }
        }

        public IEnumerable<ChangeRequestChecklistItem> GetRequestedItems(int changeRequestId)
        {
            using (var cmd = new CmdObj("QCheck_Approval_RequestedItems"))
            {
                cmd.Add("@ChangeID", changeRequestId);
                var dataSet = cmd.GetDS();
                return dataSet.Tables[0].AsEnumerable().Select(r => new ChangeRequestChecklistItem(r));
            }
        }

        public void ApproveRequest(int changeRequestId, int userId)
		{
			using(var cmd = new CmdObj("QCheck_Approval_ApproveChange"))
			{
				cmd.Add("@ChangeID", changeRequestId);
				cmd.Add("@UserID", userId);
				cmd.ExecuteNonQueryWithOutput();
			}
			
		}

		public void DenyRequest(int changeRequestId, int userId)
		{
			using (var cmd = new CmdObj("QCheck_Approval_RejectChange"))
			{
				cmd.Add("@ChangeID", changeRequestId);
				cmd.Add("@UserID", userId);
				cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void ApproveItem(int changeRequestItemId)
		{
			using (var cmd = new CmdObj("QCheck_Approval_ApproveChangeRequestItem"))
			{
                cmd.Add("@ID", changeRequestItemId);
                cmd.ExecuteNonQueryWithOutput();
			}
		}

		public void DenyItem(int changeRequestItemId)
		{
			using (var cmd = new CmdObj("QCheck_Approval_DenyChangeRequestItem"))
			{
                cmd.Add("@ID", changeRequestItemId);
                cmd.ExecuteNonQueryWithOutput();
			}
		}
		
		 public IEnumerable<ChangeRequest> GetSupervisorChangeRequestsForUniversalExtension(int userId)//added by venkat 11/15/2017
        {
            using (var cmd = new CmdObj("QCheck_Approval_GetSupervisorChangeRequests_UniversalExtensions"))
            {
                cmd.Add("@UserId", userId);
                var dataSet = cmd.GetDS();
                return dataSet.Tables[0].AsEnumerable().Select(r => new ChangeRequest(r));
            }
        }
        public DateTime GetNextOfficeDay()
        {
            using (var cmd = new CmdObj("Util_GetNextOfficeDay"))
            {
                var result =  cmd.GetDS();

                var test = (DateTime) result.Tables[0].Rows[0].ItemArray[0];

                return test;
            }
        }
	}

	public class ChangeRequest
    {
        private readonly UserTimeZone myTz = QProcess.Session.CurrentSession.UserTimeZone;

        public int ID;
		public int RequestingUser;
		public string FullName;
		public string Email;
		public DateTime RequestDate;
		public string Comment;
		public int ChecklistId;
		public string ChecklistName;
        public string Controllers;
        public string Assignees;
		public int ExtensionDays;
		public int ExtensionCount;
        public bool DeadlineExtensionCompleted;
        public string CompletedDate;
        public string DatePassedMessage;
        public List<ChangeRequestItem> ChangedItems;
        public List<ChangeRequestItem> AddedItems;
        public List<ChangeRequestItem> RemovedItems;
        public List<ChangeRequestAssignmentItem> CurrentAssignments;
        public List<ChangeRequestAssignmentItem> RequestedAssignments;
        public List<ChangeRequestChecklistItem> CurrentChecklistItems;
        public List<ChangeRequestChecklistItem> RequestedChecklistItems;


        public ChangeRequest() { }

		public ChangeRequest(DataRow dataRow)
		{
			if (!Convert.IsDBNull(dataRow["ID"]))
				ID = (int)dataRow["ID"];
			if (!Convert.IsDBNull(dataRow["RequestingUser"]))
				RequestingUser = (int)dataRow["RequestingUser"];
			if (!Convert.IsDBNull(dataRow["FullName"]))
				FullName = (string)dataRow["FullName"];
			if (!Convert.IsDBNull(dataRow["RequestDate"]))
				RequestDate = myTz.GetLocalTime((DateTime)dataRow["RequestDate"]);
			if (!Convert.IsDBNull(dataRow["Comment"]))
				Comment = (string)dataRow["Comment"];
			if (!Convert.IsDBNull(dataRow["ChecklistId"]))
				ChecklistId = (int)dataRow["ChecklistId"];
			if (!Convert.IsDBNull(dataRow["ChecklistName"]))
                ChecklistName = (string)dataRow["ChecklistName"];
            if (!Convert.IsDBNull(dataRow["Controllers"]))
                Controllers = (string)dataRow["Controllers"];
            if (!Convert.IsDBNull(dataRow["Assignees"]))
                Assignees = (string)dataRow["Assignees"];
            if (!Convert.IsDBNull(dataRow["Email"]))
                Email = (string)dataRow["Email"];
			if (dataRow.Table.Columns.Contains("ExtensionDays") && !Convert.IsDBNull(dataRow["ExtensionDays"]))
				ExtensionDays = (int)dataRow["ExtensionDays"];
			if (dataRow.Table.Columns.Contains("ExtensionCount") && !Convert.IsDBNull(dataRow["ExtensionCount"]))
				ExtensionCount = (int)dataRow["ExtensionCount"];
            if (!Convert.IsDBNull(dataRow["completeddate"]))
            {
                DeadlineExtensionCompleted = true;
                CompletedDate = (myTz.GetLocalTime((DateTime)dataRow["completeddate"])).ToShortDateString();
            }
            else
            {
                CompletedDate = "";
            }
            if (!Convert.IsDBNull(dataRow["DatePassedMessage"]))
                DatePassedMessage = (string)dataRow["DatePassedMessage"];
        }
	}

	public class ChangeRequestItem
	{
		public string ItemName;
		public int SequenceNum;
		public object Current;
		public object Requested;
		public int CRItemID;
		public bool Approved;

		public ChangeRequestItem() { }

		public ChangeRequestItem(DataRow dataRow)
		{
			if (!Convert.IsDBNull(dataRow["Seq"]))
				SequenceNum = (int)dataRow["Seq"];
			if (!Convert.IsDBNull(dataRow["Item"]))
				ItemName = (string)dataRow["Item"];
            if(dataRow.Table.Columns.Contains("Current"))
			    Current = dataRow.GetValue("Current");
			if (!Convert.IsDBNull(dataRow["Requested"]))
				Requested = dataRow["Requested"];
			if (!Convert.IsDBNull(dataRow["CRItemID"]))
				CRItemID = (int)dataRow["CRItemID"];
			if (!Convert.IsDBNull(dataRow["Approved"]))
				Approved = (bool)dataRow["Approved"];
		}
	}

    public class ChangeRequestChecklistItem
    {
        public int ChecklistID { get; set; }
		public int ItemID { get; set; }
        public int SequenceNum { get; set; }
        public int ItemTypeID { get; set; }
        public string ItemTypeName { get; set; }
        public string Text { get; set; }
        public string Url { get; set; }

        public ChangeRequestChecklistItem() { }

        public ChangeRequestChecklistItem(DataRow dataRow)
        {
            if (!Convert.IsDBNull(dataRow["ChecklistID"]))
                ChecklistID = (int)dataRow["ChecklistID"];
            if (!Convert.IsDBNull(dataRow["ItemID"]))
                ItemID = (int)dataRow["ItemID"];
            if (!Convert.IsDBNull(dataRow["SequenceNum"]))
                SequenceNum = (int)dataRow["SequenceNum"];
            if (!Convert.IsDBNull(dataRow["ItemTypeID"]))
                ItemTypeID = (int)dataRow["ItemTypeID"];
            if (!Convert.IsDBNull(dataRow["ItemTypeName"]))
                ItemTypeName = (string)dataRow["ItemTypeName"];
            if (!Convert.IsDBNull(dataRow["Text"]))
                Text = (string)dataRow["Text"];
            if (!Convert.IsDBNull(dataRow["URL"]))
                Url = (string)dataRow["URL"];
        }
    }

    public class ChangeRequestAssignmentItem
    {
        public int ChecklistID { get; set; }
        public string ChecklistName { get; set; }
        public string Controllers { get; set; }
        public int InstanceID { get; set; }
        public string AssigneeList { get; set; }
        public string ScheduleString { get; set; }

        public ChangeRequestAssignmentItem() { }

        public ChangeRequestAssignmentItem(DataRow dataRow)
        {
            if (!Convert.IsDBNull(dataRow["ChecklistID"]))
                ChecklistID = (int)dataRow["ChecklistID"];
            if (!Convert.IsDBNull(dataRow["ChecklistName"]))
                ChecklistName = (string)dataRow["ChecklistName"];
            if (!Convert.IsDBNull(dataRow["Controllers"]))
                Controllers = (string)dataRow["Controllers"];
            if (!Convert.IsDBNull(dataRow["InstanceID"]))
                InstanceID = (int)dataRow["InstanceID"];
            if (!Convert.IsDBNull(dataRow["AssigneeList"]))
                AssigneeList = (string)dataRow["AssigneeList"];
            if (!Convert.IsDBNull(dataRow["ScheduleString"]))
                ScheduleString = (string)dataRow["ScheduleString"];
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

