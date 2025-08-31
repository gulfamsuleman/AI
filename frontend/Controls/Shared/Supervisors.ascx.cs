using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Providers.Entities;
using System.Web.UI.WebControls;
using DotNetOpenAuth;
using QProcess.Models;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_Shared_Supervisors : System.Web.UI.UserControl
    {
        public static Session CurrentSession { get { return new Session(HttpContext.Current?.Session); } }
        protected List<NamedEntity> Assignees;
        public bool IsSupervisorAdmin { get; set; }
        public bool InProcessingOnly { get; set; }
        public bool IsController { get; set; }
        public int ReportId { get; set; }
        public Repeater Repeater1 { get; set; }

        public Controls_Shared_Supervisors()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            int userID = QProcess.Session.CurrentSession.QUser.Id;

            if (Request.Headers["X-ReportId"] != null)
            {
                ReportId = int.Parse(Request.Headers["X-ReportId"]);
            }

            var statusReportRepo = new StatusReportRepository();
            string userIDs = statusReportRepo.GetControllerUserIDsByReportID(ReportId);

            if (IsSupervisorAdmin)
            {
                IsController = true;
            }
            // Check if userID is in the userIDs string
            else if (!string.IsNullOrEmpty(userIDs))
            {
                IsController = userIDs.Split(',').Select(int.Parse).Contains(userID);
            }
            else
            {
                IsController = false;
            }

            if (IsController)
            {
                var selectListRepo = new SelectListRepository();
                Assignees = selectListRepo.GetGroups().ToList();
                Assignees.Insert(0, new NamedEntity { Id = -1, Name = "" });
                Repeater1.DataBind();
            }
        }
    }
}