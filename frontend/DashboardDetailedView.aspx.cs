using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess
{
    public partial class DashboardDetailedView : System.Web.UI.Page
    {
        protected int SupervisorID { get; set; }
        protected string UserID { get; set; }
        protected string UserName { get; set; }
        protected string LabelText { get; set; }
        protected string Firm { get; set; }
        protected bool IsOwnDashboard { get; set; }
        protected bool IsSupervisor
        {
            get { return QProcess.Session.CurrentSession.QUser.IsSupervisor; }
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            var userIdParam = Context.Request.QueryString["userId"];

            SupervisorID = QProcess.Session.CurrentSession.QUser.Id;
            Firm = ConfigurationManager.AppSettings["Firm"].ToString();
            var repo = new UserRepository();

            if (!string.IsNullOrEmpty(userIdParam))
            {
                UserID = userIdParam;
                IsOwnDashboard = (userIdParam == SupervisorID.ToString());
            }
            else
            {
                UserID = SupervisorID.ToString();
                IsOwnDashboard = true;
            }

            UserName = repo.GetUsers().Where(u => u.Id.ToString() == UserID).FirstOrDefault()?.FullName ?? "Unknown User";
            LabelText = $"{UserName} Details";
        }
    }
}