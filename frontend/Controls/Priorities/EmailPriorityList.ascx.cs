using System;
using System.Collections.Generic;
using System.Linq;
using QProcess.Repositories;
using QProcess.Extensions;
using System.Web.UI.WebControls;

namespace QProcess.Controls
{
    public partial class Controls_Priorities_EmailPriorityList : System.Web.UI.UserControl
    {
        protected int SetId { get; set; }
        protected List<PriorityList> PriorityLists { get; set; }
        protected List<PriorityEmail> EmailAddresses { get; set; }
        protected List<PriorityEmail> AllEmailAddresses { get; set; }
        protected PriorityInfo Info { get; set; }
        protected DateTime? commentSince = null;
        protected bool includeEveryone = false;

        protected Session CurrentSession => QProcess.Session.CurrentSession;

        public Repeater Repeater1 { get; set; }
        public Repeater Repeater2 { get; set; }
        public Controls_Priorities_PriorityList PriorityListControl { get; set; }

        public Controls_Priorities_EmailPriorityList()
        {
            Repeater1 = new Repeater();
            Repeater2 = new Repeater();
            PriorityListControl = new Controls_Priorities_PriorityList();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            var prioritiesRepo = new PrioritiesRepository();
            SetId = Convert.ToInt32(Context.Request.Headers["X-SetId"]);
            if (Context.Request.Headers["X-Everyone"].ToBlank() == "true") includeEveryone = true;
            if (Context.Request.Headers["X-Since"].ToBlank() != "") 
                commentSince = DateTime.Parse(Context.Request.Headers["X-Since"].ToBlank());
            PriorityLists = prioritiesRepo.GetPriorityListSet(CurrentSession.QUser.Id, SetId, true, commentSince, includeEveryone).ToList();
            EmailAddresses = prioritiesRepo.GetPrioritySetEmailAddresses(SetId, CurrentSession.QUser.Id).ToList();
            AllEmailAddresses = prioritiesRepo.GetPriorityAllUserEmails().ToList();
            Info = prioritiesRepo.GetPriorityInfo(SetId, CurrentSession.QUser.Id,
                CurrentSession.QUser.FullName, CurrentSession.SessionId);

            Repeater1.DataSource = EmailAddresses;
            Repeater1.DataBind();

            Repeater2.DataSource = AllEmailAddresses;
            Repeater2.DataBind();

            PriorityListControl.PriorityLists = PriorityLists;
            PriorityListControl.IsEmailing = true;
            PriorityListControl.Info = Info;
        }

        protected string LoggedInEmailClass(bool loggedInUser)
        {
            if (loggedInUser)
            {
                return "class=loggedInUser";
            }
            else
            {
                return "";
            }
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

