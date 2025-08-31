using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{

    public partial class Controls_Shared_ReportToolbar : QProcessControl
    {
        protected List<ReportHeader> MyReports { get; set; }
        protected List<ReportHeader> InterestedPartyReports { get; set; }
        protected List<ReportHeader> SupervisedReports { get; set; }
        protected List<NamedEntity> TaskTypes { get; set; }
        protected int UserId { get; set; }
        protected string FullName { get; set; }
        public bool IsArchive { get; set; }
        public bool IsMyStatus { get; set; }
        public bool IsMyInbox { get; set; }
        public bool IsMyInboxStatus { get; set; }
        protected bool HasDepartments { get; set; }
        protected bool IsDepartmentAdmin { get; set; }
        public int ReportId { get; set; }
        protected string ReportName { get; set; }

        public Repeater Repeater1 { get; set; }
        public Repeater Repeater2 { get; set; }

        public Controls_Shared_ReportToolbar()
        {
            Repeater1 = new Repeater();
            Repeater2 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            Models.IUser qUser = CurrentSession.QUser;

            if (!Request.IsAuthenticated) return;

            var statusReportRepo = new StatusReportRepository();
            var selectListRepo = new SelectListRepository();
            if (Context.Request.Headers["X-ReportId"] != null)
                ReportId = Convert.ToInt32(Context.Request.Headers["X-ReportId"]);
            if (Context.Request.Headers["X-IsMyInboxStatus"] != null)
                IsMyInboxStatus = Convert.ToBoolean(Context.Request.Headers["X-IsMyInboxStatus"]);
            if (Context.Request.Headers["X-IsMyInbox"] != null)
                IsMyInbox = Convert.ToBoolean(Context.Request.Headers["X-IsMyInbox"]);
            if (Context.Request.QueryString["archive"] != null)
            {
                var a = int.Parse(Context.Request.QueryString["archive"]);
                IsArchive = a == 1;
            }
            UserId = qUser.Id;
            FullName = qUser.FullName;
            IsDepartmentAdmin = qUser.IsDepartmentAdmin;
            HasDepartments = statusReportRepo.CheckForDepartments(UserId);
            MyReports = statusReportRepo.GetMyReportsListHeaders(UserId);
            InterestedPartyReports = statusReportRepo.GetReportListSupervised(UserId, true);
            SupervisedReports = statusReportRepo.GetReportListSupervised(UserId, false);
            ReportName = IsMyInbox && !IsMyInboxStatus ? "Inbox" : statusReportRepo.GetReportName(ReportId, UserId);
            TaskTypes = selectListRepo.GetTaskTypesForReport(ReportId, UserId).ToList();

            Repeater1.DataSource = TaskTypes;
            Repeater1.DataBind();
            Repeater2.DataSource = TaskTypes;
            Repeater2.DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

