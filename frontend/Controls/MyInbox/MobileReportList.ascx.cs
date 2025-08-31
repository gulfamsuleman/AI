using QProcess.Repositories;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace QProcess.Controls.MyInbox
{
    public partial class MobileReportList : System.Web.UI.UserControl
    {
        public string Title { get; set; }
        public string SortBy { get; set; }
        public string SortOrder { get; set; }
        public List<ReportListItem> ReportList { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            Repeater1.DataSource = ReportList;
            Repeater1.DataBind();
        }

        protected string GetDaysAgo(DateTime date)
        {
            if (date != DateTime.MinValue)
            {
                var timeSpan = (QProcess.Session.CurrentSession?.UserTimeZone?.GetLocalTimeNow().Date
                    ?? DateTime.Today).Subtract(date.Date);
                switch (timeSpan.Days)
                {
                    case 1:
                        return "1 Day Ago";
                    default:
                        return timeSpan.Days + " Days Ago";
                }
            }
            return "";
        }

        protected string FormatReportName(string n)
        {
            if (n.Length > 25)
            {
                n = n.Substring(0, 22) + "...";
            }
            return n;
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

