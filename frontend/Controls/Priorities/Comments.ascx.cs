using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI;
using System.Web.UI.WebControls;
using QProcess.Configuration;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_Priorities_Comments : UserControl
    {
        public List<PriorityComment> Comments { get; set; }
        public DateTime LastViewed { get; set; }
        public Repeater Repeater1 { get; set; }
        public bool IsEmailing { get; set; } = false;

        public Controls_Priorities_Comments()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            // If LastViewed is not set (default value), set it using MyStatus logic
            if (LastViewed == default(DateTime))
            {
                // Try to get from request (header or query string)
                string lastViewedString = Request.Headers["X-LastViewed"] ?? Request.QueryString["LastViewed"];
                var userTz = QProcess.Session.CurrentSession.UserTimeZone;
                var yesterday = userTz.GetLocalTimeNow().AddDays(-1);
                DateTime lastViewed;

                if (!string.IsNullOrEmpty(lastViewedString) && DateTime.TryParse(lastViewedString, out lastViewed))
                {
                    if (lastViewed > yesterday)
                        lastViewed = yesterday;
                }
                else
                {
                    lastViewed = yesterday;
                }

                LastViewed = lastViewed;
            }

            if (IsEmailing)
            {
                Repeater1.DataSource = Comments.Where(x => !x.IsHidden);
            }
            else
            {
                Repeater1.DataSource = Comments;
            }
            Repeater1.DataBind();
        }


        public string ParseLinks(string t)
        {
            string keepEnd;
            string keepStart;
            string linkPart;

            while (t.Contains("[link]") && t.Contains("[/link]"))
            {
                keepEnd = t.Substring(t.IndexOf("[/link]") + 7);
                keepStart = t.Substring(0, t.IndexOf("[link]"));
                linkPart = t.Substring(t.IndexOf("[link]") + 6, (t.IndexOf("[/link]") - (t.IndexOf("[link]") + 6)));

                t = keepStart + "<!--a1--><a href='" + linkPart + "' target='_new' onclick='event.cancelBubble=true;'><!--/a1-->" + linkPart + "<!--a2--></a><!--/a2-->" + keepEnd;
            }
            t.Replace("''", "'");
            return t;
        }
        protected bool ShouldHideComment(object commentDateObj)
        {
            if (QProcess.Session.CurrentSession.GetAllCommentsFlag) return false;
            DateTime commentDate = Convert.ToDateTime(commentDateObj);
            // Use DateTime.Today or LastViewed as appropriate
            return commentDate < DateTime.Today;
            //return commentDate < DateTime.Today.AddDays(-1 * Convert.ToInt32(QProcess.Configuration.AppSettings.VisibleCommentsDays));
        }

        protected bool ShouldMarkOld(object commentDateObj)
        {
            DateTime commentDate = Convert.ToDateTime(commentDateObj);
            return commentDate < DateTime.Today;
            //return commentDate < DateTime.Today.AddDays(-1 * Convert.ToInt32(QProcess.Configuration.AppSettings.VisibleCommentsDays));
        }
        protected string GetCommentColorClass(object colorObj, object commentDateObj)
        {
            int color = 0;
            if (colorObj != null && int.TryParse(colorObj.ToString(), out int parsedColor))
                color = parsedColor;

            DateTime commentDate = Convert.ToDateTime(commentDateObj);
            DateTime lastViewed = LastViewed;

            if (commentDate > lastViewed)
                return "sd" + color;
            else
                return "sd" + color + "HighlightDate";
        }
        protected string GetCommenterDisplay(object fullNameObj, object initialsObj, object commentUserIdObj)
        {
            // Show "System Account" for system comments
            if (commentUserIdObj != null && Convert.ToInt32(commentUserIdObj) == 0)
                return "System Account";

            // Get app name from AppSettings
            string appName = AppSettings.Get("AppName");

            // Use initials if appName contains "Q" (case-insensitive), otherwise use full name
            // Handle q tasks, q process, etc
            if (!string.IsNullOrEmpty(appName) && appName.IndexOf("Q", StringComparison.OrdinalIgnoreCase) >= 0)
                return initialsObj != null && !string.IsNullOrWhiteSpace(initialsObj.ToString()) ? initialsObj.ToString() : fullNameObj?.ToString() ?? "";
            return fullNameObj?.ToString() ?? "";
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

