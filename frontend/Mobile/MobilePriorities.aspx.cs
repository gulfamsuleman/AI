using QProcess.Controls;
using QProcess.Extensions;
using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Mobile
{
    public partial class MobilePriorities : SessionPage
    {
        protected PriorityInfo Info { get; set; }
        protected List<NamedPriorityEntity> PrioritySets { get; set; }
        protected List<PriorityComment> PriorityComments { get; set; }
        protected List<PriorityList> PriorityLists { get; set; }
        protected int SetId { get; set; }
        protected string PriorityFont { get; set; }
        protected bool SetLocked { get; set; }
        protected bool SetLockedByMe { get; set; }
        protected bool ShowComments { get; set; }
        protected bool AllUsers { get; set; }
        protected bool UsesPriorities { get; set; }
        protected int UserId { get; set; }
        protected string Initials { get; set; }
        //public Controls_Priorities_PriorityList PriorityListControl { get; set; }

        public MobilePriorities()
        {
            PriorityListControl = new Controls_Priorities_PriorityList();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            UsesPriorities = CurrentSession.QUser.UsesPriorities;
            if (!UsesPriorities) return;
            var prioritiesRepo = new PrioritiesRepository();
            var userRepo = new UserRepository();
            int setId;
            UserId = CurrentSession.QUser.Id;
            Initials = CurrentSession.QUser.Email.ToBlank().Left(2).ToUpper();

            ShowComments = CurrentSession.QUser.ShowComments;
            AllUsers = true;
            PriorityFont = userRepo.GetPreference(UserId, "PriorityFonts");
            PrioritySets = prioritiesRepo.GetPrioritySets(UserId).ToList();

            if (Context.Request.Params["redirect"] != null)
            {
                Redirect();
            }
            else
            {
                if (Context.Request.Params["setId"] != null)
                {
                    SetId = Convert.ToInt32(Context.Request.Params["setId"]);
                }
                else
                {
                    if (int.TryParse(userRepo.GetPreference(UserId, "LastPrioritySet"), out setId))
                    {
                        SetId = setId;
                    }
                    else
                    {
                        SetId = PrioritySets.FirstOrDefault(pg => pg.LastPrioritySet == 1) != null ? PrioritySets.First(pg => pg.LastPrioritySet == 1).Id : PrioritySets.First().Id;
                    }
                }
                Info = prioritiesRepo.GetPriorityInfo(SetId, UserId, CurrentSession.QUser.FullName, CurrentSession.SessionId);
                PriorityLists = prioritiesRepo.GetPriorityListSet(UserId, SetId, ShowComments, null, AllUsers).ToList();
                Info.PriorityLists = PriorityLists;
                Info.LockedByUserId = UserId;
                Info.LockedByUserName = CurrentSession.QUser.FullName;

                QProcess.Cache.CurrentCache.LockPrioritySet(SetId, Info, CurrentSession);

                PriorityListControl.Info = Info;
                PriorityListControl.PriorityLists = PriorityLists;
                //}

                userRepo.AddPreference(UserId, "LastPrioritySet", SetId.ToString());
            }
        }

        protected void Redirect()
        {
            using (var cmd = new CmdObj("PriorityListSet_Redirect"))
            {
                cmd.Add("@UserID", CurrentSession.QUser.Id);
                cmd.Add("@ReportUserID", Context.Request.Params["ReportUserID"]);
                if (Context.Request.Params["TaskID"].Length > 0)
                {
                    cmd.Add("@TaskID", Context.Request.Params["TaskID"]);
                }

                bool controller;
                int reportID;
                string url;

                var ds = cmd.GetDS();

                reportID = int.Parse(ds.Tables[0].Rows[0]["ReportID"].ToString());
                controller = bool.Parse(ds.Tables[0].Rows[0]["Controller"].ToString());

                if (reportID == 0)
                {
                    Response.Write("<title>" + Configuration.AppSettings.AppName + "</title><h1>Task not found on a status report you have access to.</h1>");
                    Response.End();
                }
                else
                {
                    if (controller)
                    {
                        url = "MobileMyStatus.aspx?reportID=" + reportID.ToString();
                    }
                    else
                    {
                        url = "MobileMyInbox.aspx?reportID=" + reportID.ToString();
                    }
                    Response.Redirect(url);
                }
            }
        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request))
                base.Render(writer);
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

