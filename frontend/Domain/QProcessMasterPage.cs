using QProcess.Repositories;
using System;
using QProcess.Configuration;
using System.Linq;
using System.Web;
using System.Web.UI;

public class QProcessMasterPage : MasterPage
{
    //private bool isAuthChallengeIssued;
    private bool isInprocessing;

    protected string Firm { get; set; }
    internal bool IsInprocessing { get => isInprocessing;}
    //internal bool IsAuthChallengeIssued { get => isAuthChallengeIssued; }

    protected override void OnInit(EventArgs e)
    {
        
        if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request))
        {
            //isAuthChallengeIssued = true;
            return;
        }
        else
            base.OnInit(e);

        if ((QProcess.Session.CurrentSession.QUser?.Id ?? 0) == 0)
        {
            //Request authed but user doesn't exist; create and inprocess (self-signup)
            var user = QProcess.Session.CurrentSession.QUser;
            var userRepo = new UserRepository();
            userRepo.AddUser(user.Username, user.FullName, user.Email, "", false);

            //Mostly for testing
            user = userRepo.GetUser(user.Username);

            //Force refresh of session user to update
            HttpContext.Current.Session["CurrentUser"] = null;
            var sessionUser = QProcess.Session.CurrentSession.QUser;
        }

        if (Request.IsAuthenticated
                && QProcess.Session.CurrentSession.QUser.AllSupervisors.Any() == false
                && Request.Url.AbsolutePath != "/Inprocess.aspx"
                && QProcess.Session.CurrentSession.QUser.Username.EndsWith("graynor") == false
                && (System.Configuration.ConfigurationManager.AppSettings["BypassInprocess"] != "true"))
        {
            isInprocessing = true;
            Response.Redirect("Inprocess.aspx");
        }
    }

    protected virtual void Page_Load(object sender, EventArgs e)
    {
        if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request))
        {
            //isAuthChallengeIssued = true;
            return;
        }

        Firm = AppSettings.Get("Firm");

    }

    protected override void Render(HtmlTextWriter writer)
    {
        //don't bother if we're just redirecting to the auth provider
        if (Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request) && !IsInprocessing)
            base.Render(writer);
    }
}
/* Copyright � 2024 Renegade Swish, LLC */

