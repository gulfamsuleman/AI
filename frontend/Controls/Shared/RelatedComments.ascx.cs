using System;
using System.Collections.Generic;
using System.Web.UI.WebControls;
using QProcess.Repositories;

namespace QProcess.Controls
{
    public partial class Controls_Shared_RelatedComments : System.Web.UI.UserControl
    {

        protected int TaskID { get; set; }
        protected int UserID { get; set; }

        public Repeater Repeater1 { get; set; }

        public Controls_Shared_RelatedComments()
        {
            Repeater1 = new Repeater();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (Context.Request.Headers["X-TaskID"] != null)
            {
                TaskID = int.Parse(Context.Request.Headers["X-TaskID"]);
                UserID = int.Parse(Context.Request.Headers["X-UserID"]);
                List<ReportComment> Comments = null;
                var statusReportRepo = new StatusReportRepository();
                Comments = statusReportRepo.GetRelatedComments(TaskID, UserID);
                if (Comments != null)
                {
                    Repeater1.DataSource = Comments;
                    Repeater1.DataBind();
                }
            }
        }

        public string Str2Html(string s)
        {
            return s.Replace("\n", "<br/>");
        }
    }
}
/* Copyright © 2024 Renegade Swish, LLC */

