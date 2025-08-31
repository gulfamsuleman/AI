using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess
{

    public partial class TestManagement : Page
    {

        public int UserID;
        public string ShortName;

        public SiteMaster MasterPage => Master as SiteMaster;

        public Repeater Repeater1 { get; set; }

        public TestManagement()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(Request)) return;

            BindControls();
        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(Request)) return;

            base.Render(writer);
        }

        private void BindControls()
        {
            List<NamedEntity> Members;
            var user = MasterPage.QUser;

            if (user.IsGradingAdmin)
            {
                var selectListRepo = new SelectListRepository();
                Members = selectListRepo.GetGroups().ToList();
                Members.Insert(0, new NamedEntity { Id = -1, Name = "" });
            }
            else
            {
                Members = new List<NamedEntity> { new NamedEntity { Id = user.GroupId, Name = user.FullName } };
            }

            Repeater1.DataSource = Members;
            Repeater1.DataBind();
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

