using System;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_MyStatus_ResizeReport : System.Web.UI.UserControl
    {
        public int SelectedReportId { get; set; }
        public int Width { get; set; }
        protected void Page_Load(object sender, EventArgs e)
        {
            var repo = new StatusReportRepository();
            SelectedReportId = int.Parse(Context.Request.Headers["X-ReportId"]);
            Width = repo.GetColumnWidth(QProcess.Session.CurrentSession.QUser.Id, SelectedReportId);
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

