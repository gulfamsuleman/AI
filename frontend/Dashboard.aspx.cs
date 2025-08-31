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


    public partial class Dashboard : Page
    {
        public SiteMaster MasterPage => Master as SiteMaster;

        public List<UserGroup> supervisedGroups { get; set; }
        public List<User> supervisedUsers { get; set; }

        public int SupervisorID { get; set; }

        public string Firm { get; set; }  

        public Dashboard()
        {
            SupervisedGroupsRepeater = new Repeater();
        }
        protected void Page_Load(object sender, EventArgs e)
        {
            var user = MasterPage.QUser;
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;
            SupervisorID = user.Id;
            Firm = ConfigurationManager.AppSettings["Firm"].ToString();
            var groupRepo = new UserRepository();

            if (user.IsSupervisor)
            {
                supervisedUsers = groupRepo.GetUsersBySupervisor(SupervisorID);
                supervisedGroups = groupRepo.GetSupervisedUsersByGroups(SupervisorID).ToList();
            }
            else
            {
                // Only show the current user in the list
                supervisedUsers = new List<User> { groupRepo.GetUsers().FirstOrDefault(u => u.Id == SupervisorID) };
                supervisedGroups = groupRepo.GetMyGroups(user.Id, user.Id).Where(x => x.GroupName == user.FullName).ToList();
            }

            SupervisedGroupsRepeater.DataSource = supervisedGroups;
            SupervisedGroupsRepeater.DataBind();

            Page.DataBind();
        }
    }

    public class AddedWidget
    {
        public string type { get; set; }
    }
}