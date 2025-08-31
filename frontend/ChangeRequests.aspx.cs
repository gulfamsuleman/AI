using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Providers.Entities;
using System.Web.UI.WebControls;
using QProcess.Extensions;
using QProcess.Repositories;

namespace QProcess
{

    public partial class ChangeRequests : SessionPage, IProvideReportIdForLogging
    {
        public List<ChangeRequest> SupervisorChangeRequests;
        public List<ChangeRequest> UserChangeRequests;
        public int ReportId { get; set; }

        public readonly ChangeRequestRepository ChangeRequestRepo = new ChangeRequestRepository();
        public Repeater userChangeRequestRepeater { get; set; }
        public Repeater supervisorChangeRequestRepeater { get; set; }
        public DropDownList ddlSort { get; set; }
        protected string ChangeRequestFont { get; set; }
        protected string ChangeRequestColumns { get; set; }
        protected string ChangeRequestRowHeight { get; set; }

        public DateTime NextOfficeDay { get; set; }

        public ChangeRequests()
        {
            userChangeRequestRepeater = new Repeater();
            supervisorChangeRequestRepeater = new Repeater();
            ddlSort = new DropDownList();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            NextOfficeDay = ChangeRequestRepo.GetNextOfficeDay();

            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;
            if ((Request.IsMobileBrowser() && !CurrentSession.ForceDesktop(Request)) || CurrentSession.ForceMobile(Request))
            {
                Response.RedirectToMobile(Request.Url);
                return;
            }
            ReportId = 0;
            SupervisorChangeRequests = ChangeRequestRepo.GetSupervisorChangeRequests(CurrentSession.QUser.Id, Int32.Parse(ddlSort.SelectedValue)).ToList();
            UserChangeRequests = ChangeRequestRepo.GetUserChangeRequests(CurrentSession.QUser.Id, Int32.Parse(ddlSort.SelectedValue)).ToList();
            var userRepo = new UserRepository();

            ChangeRequestFont = userRepo.GetPreference(CurrentSession.QUser.Id, "ChangeRequestFonts");
            ChangeRequestColumns = userRepo.GetPreference(CurrentSession.QUser.Id, "ChangeRequestColumns");
            ChangeRequestRowHeight = userRepo.GetPreference(CurrentSession.QUser.Id, "ChangeRequestRowHeight");

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
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

