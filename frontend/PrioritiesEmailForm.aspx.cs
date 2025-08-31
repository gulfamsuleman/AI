using System;
using System.Collections.Generic;
using System.Linq;
using QProcess.Repositories;
using QProcess.Extensions;
using System.Web;
using System.Web.UI.WebControls;
using QProcess.Controls;
using QProcess.Models;

namespace QProcess
{

    public partial class PrioritiesEmailForm : SessionPage
	{
		protected List<PriorityList> PriorityLists { get; set; }
		protected PriorityInfo Info { get; set; }
		protected IUser PriorityUser { get; set; }
		protected int SetId { get; set; }
		protected bool ShowBody { get; set; }
		protected string Body { get; set; }
		protected DateTime CommentsSince { get; set; }
		protected bool SendSideBySide { get; set; }
		protected string PrioritiesAppUrl { get; set; }
		protected bool Everyone = false;
		protected bool Mobile = false;

        public Controls_Priorities_PriorityList PriorityListControl { get; set; }
        public Controls_Priorities_PriorityList BeforePriorityListControl { get; set; }
        public Controls_Priorities_PriorityList AfterPriorityListControl { get; set; }
        
        public PrioritiesEmailForm()
        {
            PriorityListControl = new Controls_Priorities_PriorityList();
            BeforePriorityListControl = new Controls_Priorities_PriorityList();
            AfterPriorityListControl = new Controls_Priorities_PriorityList();
        }
        
		protected void Page_Load(object sender, EventArgs e)
		{
            //if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            var _session = HttpContext.Current.Session;
			_session["CurrentUser"] = new UserRepository().GetUser(Request.Headers["X-Username"]);
			PriorityUser = _session["CurrentUser"] as Models.IUser;
			var prioritiesRepo = new PrioritiesRepository();

			if (Request.Headers["X-SetId"] != null)
				SetId = Convert.ToInt32(Request.Headers["X-SetId"]);
			if (Request.Headers["X-ShowBody"] != null)
				ShowBody = Convert.ToBoolean(Request.Headers["X-ShowBody"]);
			if (Request.Headers["X-Body"] != null)
				Body = Request.Headers["X-Body"];
			if (Request.Headers["X-CommentsSince"] != null)
				CommentsSince = Convert.ToDateTime(Request.Headers["X-CommentsSince"]);

			Everyone = Request.Headers["X-Everyone"] == "true";
			Mobile = Request.Headers["X-SingleCol"].ToBlank() == "1";

			PriorityLists = prioritiesRepo.GetPriorityListSet(PriorityUser.Id, SetId, true, CommentsSince, Everyone).ToList();
			/*
			if (Request.Headers["X-UserId"] != null)
			{
				PriorityLists = prioritiesRepo.GetPriorityListSet(iuser.Id,
					SetId, QProcess.Session.CurrentSession.QUser.ShowComments, CommentsSince, Everyone)
					.Where(l => l.PriorityUser.UserId == Convert.ToInt32(Request.Headers["X-UserId"])).ToList();
			}
			else
			{
				PriorityLists = prioritiesRepo.GetPriorityListSet(iuser.Id,
					SetId, QProcess.Session.CurrentSession.QUser.ShowComments, CommentsSince, Everyone).ToList();	
			}
			*/

			if (QProcess.Cache.CurrentCache.IsPrioritySetLocked(SetId))
			{
				Info = (PriorityInfo)QProcess.Cache.CurrentCache[SetId];
			}

			if (Info == null)
			{
				var PrioritiesRepo = new PrioritiesRepository();
				Info = PrioritiesRepo.GetPriorityInfo(SetId, PriorityUser.Id, PriorityUser.Username, QProcess.Session.CurrentSession.SessionId);
			}

			PrioritiesAppUrl = Configuration.AppSettings.PrioritiesLink + "?setId=" + SetId;

			//2022-12-22 per Ken, just turn off the side-by-side version;
			//it's "correct" behavior, after being "fixed" by a cache change, but it annoys people.
			SendSideBySide = false;
			//SendSideBySide = Info != null && Info.Changed && !Info.IsMyList;
			if (SendSideBySide)
			{
				BeforePriorityListControl.Info = Info;
				BeforePriorityListControl.PriorityLists = Info.PriorityLists;
				AfterPriorityListControl.Info = Info;
				AfterPriorityListControl.PriorityLists = PriorityLists;
			}
			else
			{
				PriorityListControl.Info = Info;
				PriorityListControl.PriorityLists = PriorityLists;
			}
			Response.Headers.Add("X-EmailFrom", PriorityUser.FullName + "<" + PriorityUser.Email + ">");
		}
	}

}
/* Copyright © 2024 Renegade Swish, LLC */

