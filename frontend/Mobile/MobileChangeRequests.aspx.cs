using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Mobile
{
    public partial class MobileChangeRequests : SessionPage, IProvideReportIdForLogging
    {
        public List<ChangeRequest> SupervisorChangeRequests;
        public List<ChangeRequest> UserChangeRequests;
        public int ReportId { get; set; }

        public DateTime NextOfficeDay { get; set; }


        public readonly ChangeRequestRepository ChangeRequestRepo = new ChangeRequestRepository();

        protected void Page_Load(object sender, EventArgs e)
        {

            NextOfficeDay = ChangeRequestRepo.GetNextOfficeDay();
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            ReportId = 0;
            SupervisorChangeRequests = ChangeRequestRepo.GetSupervisorChangeRequests(CurrentSession.QUser.Id, Int32.Parse(ddlSort.SelectedValue)).ToList();
            UserChangeRequests = ChangeRequestRepo.GetUserChangeRequests(CurrentSession.QUser.Id, Int32.Parse(ddlSort.SelectedValue)).ToList();

            foreach (var changeRequest in SupervisorChangeRequests)
            {
                changeRequest.ChangedItems = ChangeRequestRepo.GetAddedItems_NaturalLanguage(changeRequest.ID).ToList();
                changeRequest.ChangedItems.AddRange(ChangeRequestRepo.GetChangedItems_NaturalLanguage(changeRequest.ID));
                changeRequest.ChangedItems.AddRange(ChangeRequestRepo.GetRemovedItems_NaturalLanguage(changeRequest.ID));
                changeRequest.AddedItems = new List<ChangeRequestItem>();
                changeRequest.RemovedItems = new List<ChangeRequestItem>();
                changeRequest.CurrentAssignments = ChangeRequestRepo.GetCurrentAssignments(changeRequest.ID, true).ToList();
                changeRequest.CurrentChecklistItems = ChangeRequestRepo.GetCurrentItems(changeRequest.ID).ToList();
                changeRequest.RequestedAssignments = ChangeRequestRepo.GetRequestedAssignments(changeRequest.ID, true).ToList();
                changeRequest.RequestedChecklistItems = ChangeRequestRepo.GetRequestedItems(changeRequest.ID).ToList();
            }
            foreach (var changeRequest in UserChangeRequests)
            {
                changeRequest.ChangedItems = ChangeRequestRepo.GetAddedItems_NaturalLanguage(changeRequest.ID).ToList();
                changeRequest.ChangedItems.AddRange(ChangeRequestRepo.GetChangedItems_NaturalLanguage(changeRequest.ID));
                changeRequest.ChangedItems.AddRange(ChangeRequestRepo.GetRemovedItems_NaturalLanguage(changeRequest.ID));
                changeRequest.AddedItems = new List<ChangeRequestItem>();
                changeRequest.RemovedItems = new List<ChangeRequestItem>();
                changeRequest.CurrentAssignments = ChangeRequestRepo.GetCurrentAssignments(changeRequest.ID, true).ToList();
                changeRequest.CurrentChecklistItems = ChangeRequestRepo.GetCurrentItems(changeRequest.ID).ToList();
                changeRequest.RequestedAssignments = ChangeRequestRepo.GetRequestedAssignments(changeRequest.ID, true).ToList();
                changeRequest.RequestedChecklistItems = ChangeRequestRepo.GetRequestedItems(changeRequest.ID).ToList();
            }

            supervisorChangeRequestRepeater.DataSource = SupervisorChangeRequests;
            userChangeRequestRepeater.DataSource = UserChangeRequests;

            Page.DataBind();
        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request))
                base.Render(writer);
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

