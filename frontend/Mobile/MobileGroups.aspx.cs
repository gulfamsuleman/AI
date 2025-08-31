using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Mobile
{
    public partial class MobileGroups : SessionPage
    {
        protected List<NamedEntity> UsersList { get; set; }
        protected List<UserGroup> UserGroups { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            var selectListRepo = new SelectListRepository();
            var userRepo = new UserRepository();
            UsersList = selectListRepo.GetUsers(CurrentSession.QUser.Id, CurrentSession.QUser.IsAdmin).ToList();
            UsersList.Insert(0, new NamedEntity { Id = 0, Name = "Any User" });
            UserGroups = userRepo.GetMyGroups(CurrentSession.QUser.Id, 0);
            DataBind();
        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request))
                base.Render(writer);
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

