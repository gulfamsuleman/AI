using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess
{
    public partial class Outprocessing : Page
    {
        public SiteMaster MasterPage => Master as SiteMaster;

        public string SupervisedEmployee { get; set; }
        public string TargetEmployee { get; set; }
        public Outprocessing()
        {
            SupervisedEmployees = new Repeater();
            AllEmployees = new Repeater();
    }
        protected void Page_Load(object sender, EventArgs e)
        {
            var user = MasterPage.QUser;

            var userRepo = new UserRepository();
            List<User> supervisedEmployees;
            List<User> users;

            SupervisedEmployee = "";
            TargetEmployee = "";

            if (user.IsGradingAdmin) {
                supervisedEmployees = userRepo.GetUsers().ToList();
            } else {
                supervisedEmployees = userRepo.GetUsersBySupervisor(user.Id).ToList();
            }

            users = userRepo.GetUsers().ToList();
            SupervisedEmployees.DataSource = supervisedEmployees; 
            AllEmployees.DataSource = users;

            Page.DataBind();
            
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

