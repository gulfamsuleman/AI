using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Mobile
{
    public partial class MobileMyTasks : SessionPage
    {
        public string StartDateString { get; private set; }
        public string EndDateString { get; private set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            var checklistRepo = new ChecklistRepository();
            var userRepo = new UserRepository();

            var overdueInfo = checklistRepo.GetOverdueInfo(CurrentSession.QUser.Id);

            Tuple<DateTime, DateTime> dateRange = userRepo.GetPreferredDateRange(CurrentSession.QUser.Id, overdueInfo.MinDueDate);
            DateTime start = dateRange.Item1;
            DateTime end = dateRange.Item2;

            // Setting up some reasonable defaults - window will be 1 week back and 2 weeks forward
            if (start == null || start < QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-90))
            {
                start = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-7);
            }

            if (end == null || end > QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(90))
            {
                end = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(14);
            }

            StartDateString = start.ToShortDateString();
            EndDateString = end.ToShortDateString();
        }

        protected override void Render(HtmlTextWriter writer)
        {
            if (Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request))
                base.Render(writer);
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

