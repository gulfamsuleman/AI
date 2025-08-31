using System;
using System.Web;
using System.Web.UI.WebControls;
using QProcess.Extensions;

namespace QProcess
{

    public partial class UserReport : SessionPage
    {
        public DataGrid Grid { get; set; }

        public UserReport()
        {
            Grid = new DataGrid();
        }

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Web_Site.Helpers.Owin.VerifyAuthentication(HttpContext.Current.Request)) return;

            if (!CurrentSession.QUser.IsGradingAdmin)
            {
                Context.Response.Redirect("MyTasks.aspx");
            }
            else
            {
                var myTz = QProcess.Session.CurrentSession.UserTimeZone;

                var db = new DataAccessLayer.DBCommand("QCheck_UserReport");
                if (Request["startdt"] != null)
                {
                    db.Add("@startdt", myTz.GetSystemTime(DateTime.Parse(Request["startdt"])));
                }
                if (Request["enddt"] != null)
                {
                    db.Add("@enddt", myTz.GetSystemTime(DateTime.Parse(Request["enddt"])));
                }
                Grid.DataSource = db.ExecuteDataSet();
                Grid.DataBind();
            }
        }
    }

}
/* Copyright © 2024 Renegade Swish, LLC */

