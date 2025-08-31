using System;
using QProcess.Configuration;
using QProcess.Repositories;
using System.Linq;
using System.Collections.Generic;
using System.Web.UI.WebControls;

namespace QProcess.Controls
{
    public partial class Controls_MyStatus_ReportLineEmail : System.Web.UI.UserControl
    {
        private DateTime _commentsSince = QProcess.Session.CurrentSession.UserTimeZone.GetLocalTimeNow().AddDays(-1 * Convert.ToInt32(AppSettings.Get("VisibleCommentsDays")));
        private bool _onlyTasksWithComments = false;
        private bool _isIncludeDetails = false;

        protected List<StatusReportLine.Comment> VisibleComments = new List<StatusReportLine.Comment>();

        public StatusReportLine Line { get; set; }
        public int ReportId { get; set; }
        public string AppUrl { get; set; }
        public bool IsArchive { get; set; }
        public bool excludeGeneralComments { get; set; }
        public bool IsMobile { get; set; }
        public string ColSpan { get; set; }
        public bool OnlyTasksWithComments { get { return _onlyTasksWithComments; } set { _onlyTasksWithComments = value; } }
        public bool IsIncludeDetails { get { return _isIncludeDetails; } set { _isIncludeDetails = value; } }
        public DateTime CommentsSince { get { return _commentsSince; } set { _commentsSince = value; } }

        public Repeater Repeater2 { get; set; }
        public Repeater Repeater3 { get; set; }

        public Controls_MyStatus_ReportLineEmail()
        {
            Repeater2 = new Repeater();
            Repeater3 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Line.Comments != null)
            {
                VisibleComments = (from StatusReportLine.Comment c in Line.Comments where c.Date >= CommentsSince select c).ToList();
                Repeater2.DataSource = VisibleComments;
                Repeater3.DataSource = VisibleComments;
            }

            if (IsMobile)
            {
                ColSpan = "1";
            }
            else
            {
                ColSpan = "6";
            }
        }

    }
}
/* Copyright © 2024 Renegade Swish, LLC */

