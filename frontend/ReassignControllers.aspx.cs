using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using QProcess.Repositories;
using QProcess.Configuration;

namespace QProcess
{

    public partial class ReassignControllers : SessionPage
    {
        public string username;

        public Repeater Repeater1 { get; set; }
        public Repeater Repeater2 { get; set; }

        public ReassignControllers()
        {
            Repeater1 = new Repeater();
            Repeater2 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            if (!Page.IsPostBack)
            {
                username = CurrentSession.QUser.Username.ToLowerInvariant();
                InitPage();
            }
        }

        private void InitPage()
        {
            PopulateGroups();
            PopulateSupervisedGroups();

            Page.DataBind();
        }

        private void PopulateSupervisedGroups()
        {
            List<NamedEntity> Groups;
            var selectListRepo = new SelectListRepository();
            Groups = selectListRepo.GetSupervisedGroups(username, true).ToList();
            Groups.Insert(0, new NamedEntity { Id = -1, Name = "" });
            Repeater1.DataSource = Groups;
        }

        private void PopulateGroups()
        {

            List<NamedEntity> Groups;
            var selectListRepo = new SelectListRepository();
            Groups = selectListRepo.GetGroups().ToList();
            Repeater2.DataSource = Groups;
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

