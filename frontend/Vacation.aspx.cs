using System;

namespace QProcess
{

    public partial class Vacation : System.Web.UI.Page
    {
        public int CurrentUserId => QProcess.Session.CurrentSession.QUser.Id;
        public string StartDateString { get; private set; }
        public string EndDateString { get; private set; }
        protected void Page_Load(object sender, EventArgs e)
        {
            DateTime start = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(1);
            DateTime end = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(2);
            StartDateString = start.ToShortDateString();
            EndDateString = end.ToShortDateString();
        }
    }  
}
/* Copyright © 2024 Renegade Swish, LLC */

