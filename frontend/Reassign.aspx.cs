using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess
{

    public partial class Reassign : Page
    {
        public int ReassignUser;
        public string ReassignName;

        public Repeater Repeater1 {  get; set; }
        public Repeater Repeater2 { get; set; }
        public Repeater Repeater3 { get; set; }
        public Repeater Repeater4 { get; set; }
        public Repeater Repeater5 { get; set; }
        public Repeater Repeater6 { get; set; }

        public Reassign()
        {
            Repeater1 = new Repeater();
            Repeater2 = new Repeater();
            Repeater3 = new Repeater();
            Repeater4 = new Repeater();
            Repeater5 = new Repeater();
            Repeater6 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Context.Request.QueryString["r"] != null)
            {
                ReassignUser = Convert.ToInt32(Context.Request.QueryString["r"]);
                int reassignCheck1 = Convert.ToInt32(Context.Request.QueryString["q"]);
                int reassignCheck2 = Convert.ToInt32(Context.Request.QueryString["s"]);
                int reassignCheck3 = Convert.ToInt32(Context.Request.QueryString["t"]);

                if (!((reassignCheck1 == ReassignUser - 5) & (reassignCheck2 == ReassignUser + 2) & (reassignCheck3 == ReassignUser * 2 - 4)))
                {
                    Response.Redirect("MyTasks.aspx");
                }
                var userRepo = new UserRepository();
                ReassignName = userRepo.GetUserName(ReassignUser);
                BindControls();
            }
            else
            {
                Response.Redirect("MyTasks.aspx");
            }

        }

        private void BindControls()
        {
            List<NamedEntity> Members;
            List<ReportListing> Controlled;
            List<ReportListing> Supervised;
            List<TaskDetails> Assigned;
            List<TaskDetails> ControlledTasks;
            List<TaskDetails> Alertee;

            var selectListRepo = new SelectListRepository();
            Members = selectListRepo.GetGroups().ToList();
            Members.Insert(0, new NamedEntity { Id = -1, Name = "" });
            var bulkRepo = new BulkAssignmentRepository();
            Controlled = bulkRepo.GetControlledReports(ReassignUser);
            Supervised = bulkRepo.GetSupervisedReports(ReassignUser);
            Assigned = bulkRepo.GetAssignedTaskDetails(ReassignUser);
            ControlledTasks = bulkRepo.GetControlledTaskDetails(ReassignUser);
            Alertee = bulkRepo.GetAlerteeTaskDetails(ReassignUser);

            Repeater1.DataSource = Members;
            Repeater2.DataSource = Controlled;
            Repeater3.DataSource = Supervised;
            Repeater4.DataSource = Assigned;
            Repeater5.DataSource = ControlledTasks;
            Repeater6.DataSource = Alertee;

            Page.DataBind();
        }

    }

}
/* Copyright © 2024 Renegade Swish, LLC */

