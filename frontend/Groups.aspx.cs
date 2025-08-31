using System;
using System.Web;
using System.Collections.Generic;
using System.Linq;
using QProcess.Repositories;
using QProcess.Extensions;
using QProcess.warmup;

namespace QProcess
{

    public partial class Groups : SessionPage
    {
        protected List<NamedEntity> UsersList { get; set; }
        protected List<UserGroup> UserGroups { get; set; }

        protected void Application_Start(object sender, EventArgs e)
        {
            UnityConfig.RegisterTypes(UnityConfig.Container);
        }
        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;
            if ((Request.IsMobileBrowser() && !CurrentSession.ForceDesktop(Request))
                || CurrentSession.ForceMobile(Request))
            {
                Response.RedirectToMobile(Request.Url);
                return;
            }
            var selectListRepo = new SelectListRepository();
            var userRepo = new UserRepository();
            UsersList = selectListRepo.GetUsers(CurrentSession.QUser.Id, CurrentSession.QUser.IsAdmin).ToList();
            UsersList.Insert(0, new NamedEntity { Id = 0, Name = "Any User" });
            UserGroups = userRepo.GetMyGroups(CurrentSession.QUser.Id, 0);
            DataBind();
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

