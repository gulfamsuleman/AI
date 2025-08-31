using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;

namespace QProcess.Controls
{
    public partial class Controls_Grading_GradingVacations : System.Web.UI.UserControl
    {
        public IEnumerable<Repositories.Vacation> Vacations { get; set; }
        public bool IsApproval { get; set; }
        public bool IsAdminDetails { get; set; }
        public Repeater Repeater1 { get; set; }
        public Controls_Grading_GradingUsers GradingUsersControl { get; set; }

        public Controls_Grading_GradingVacations()
        {
            Repeater1 = new Repeater();
            GradingUsersControl = new Controls_Grading_GradingUsers();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            GradingUsersControl.IsFullList = IsApproval;
            GradingUsersControl.IsReportsOnHold = false;
            GradingUsersControl.IsVacations = true;

            Repeater1.DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

