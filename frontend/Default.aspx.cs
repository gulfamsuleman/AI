using System;
using System.Linq;
using System.Web.UI;
using QProcess.Extensions;
using QProcess.Repositories;

namespace QProcess
{
    public partial class _Default : Page
    {
        protected override void OnLoad(EventArgs e)
        {
            if (!Request.IsAuthenticated && Request.QueryString.AllKeys.Contains("signout"))
            {
                Response.Write("You have been signed out.");
                return;
            }
            else if (!Web_Site.Helpers.Owin.VerifyAuthentication(Request))
            {
                Response.Write("You should be redirected to log in shortly.");
                return;
            }

            if ((Request.IsMobileBrowser() && !QProcess.Session.CurrentSession.ForceDesktop(Request)) 
                || QProcess.Session.CurrentSession.ForceMobile(Request))
            {
                Response.Redirect("Mobile/MobileMyTasks.aspx");
                return;
            }

            if (Request.IsAuthenticated
                && QProcess.Session.CurrentSession.QUser.AllSupervisors.Any() == false
                && Request.Url.AbsolutePath != "/Inprocess.aspx"
                && (System.Configuration.ConfigurationManager.AppSettings["BypassInprocess"] != "true"))
            {
                Response.Redirect("Inprocess.aspx");
                return;
            }

            using (var service = new DataService())
            {
                var userRepo = new UserRepository();
                var lastPage = userRepo.GetPreference(QProcess.Session.CurrentSession.QUser.Id, "StartPage");

                if (lastPage == "" || !lastPage.Contains(".aspx"))
                    lastPage = "MyTasks.aspx";

                service.UpdateLastPage(lastPage);
                Response.Redirect(lastPage);
            }

            base.OnLoad(e);
        }

        protected void Page_Load(object sender, EventArgs e)
        {
        }
    }
}
/* Copyright � 2024 Renegade Swish, LLC */

