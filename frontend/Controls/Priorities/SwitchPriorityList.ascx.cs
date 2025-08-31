using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_Priorities_SwitchPriorityList : System.Web.UI.UserControl
    {
        protected PriorityInfo Info { get; set; }
        protected IEnumerable<NamedPriorityEntity> PrioritySets { get; set; }
        public Repeater Repeater1 { get; set; }

        protected Session CurrentSession => QProcess.Session.CurrentSession;

        public Controls_Priorities_SwitchPriorityList()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            var prioritiesRepo = new PrioritiesRepository();
            PrioritySets = prioritiesRepo.GetPrioritySets(CurrentSession.QUser.Id);

            Info = prioritiesRepo.GetPriorityInfo(0,CurrentSession.QUser.Id, 
                CurrentSession.QUser.FullName, CurrentSession.SessionId, false);

            Repeater1.DataSource = PrioritySets;
            Repeater1.DataBind();
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

